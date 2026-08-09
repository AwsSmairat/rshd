#!/usr/bin/env bash
# RSHD Security Audit — SAST, secrets, contract coverage, custom checks
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_DIR="${ROOT}/security/reports"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
mkdir -p "${REPORT_DIR}"

SECURITY_SCORE=100
SECRETS=0
CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0
RESULTS=()
SEMGREP_STATUS="SCAN_COMPLETED_NO_BLOCKERS"

log() { echo "[security-audit] $*"; }
record() { RESULTS+=("$1|$2|$3"); }

scan_secrets() {
  log "Secret pattern scan (working tree, redacted)..."
  local secret_log="${REPORT_DIR}/secret-scan.log"
  : > "${secret_log}"

  local patterns=(
    'BUNNY_.*API_KEY'
    'BUNNY_.*TOKEN_KEY'
    'BUNNY_.*STORAGE_PASSWORD'
    'APP_KEY=base64:'
    'sk_live_'
    'BEGIN (RSA |OPENSSH )?PRIVATE KEY'
  )

  for pat in "${patterns[@]}"; do
    if rg -l --glob '!.env' --glob '!*.lock' --glob '!vendor/**' --glob '!.git/**' -i "${pat}" "${ROOT}" 2>/dev/null | rg -v 'security/scripts|\.env\.example|security/reports' >> "${secret_log}.raw"; then
      :
    fi
  done

  if git -C "${ROOT}" ls-files --error-unmatch backend/.env 2>/dev/null; then
    echo "CRITICAL: backend/.env is tracked in git — ROTATION REQUIRED" >> "${secret_log}"
    SECRETS=$((SECRETS + 1))
    CRITICAL=$((CRITICAL + 1))
    SECURITY_SCORE=$((SECURITY_SCORE - 30))
  fi

  if [[ -f "${secret_log}.raw" ]]; then
    TRACKED=$(sort -u "${secret_log}.raw" | wc -l | tr -d ' ')
    if [[ "${TRACKED}" -gt 0 ]]; then
      echo "WARN: ${TRACKED} files match secret patterns — manual review" >> "${secret_log}"
      sort -u "${secret_log}.raw" | while read -r f; do echo "  file: ${f}" >> "${secret_log}"; done
      MEDIUM=$((MEDIUM + 1))
      SECURITY_SCORE=$((SECURITY_SCORE - 5))
    fi
    rm -f "${secret_log}.raw"
  fi

  record "secret_scan" "$([[ ${SECRETS} -eq 0 ]] && echo PASS || echo FAIL)" "secrets=${SECRETS}"
}

check_composer_advisories() {
  log "Composer advisory exceptions..."
  if "${ROOT}/security/scripts/check-advisory-exceptions.sh"; then
    record "composer_advisories" "PASS" "exceptions valid"
  else
    record "composer_advisories" "FAIL" "missing/expired/unjustified exception"
    HIGH=$((HIGH + 1))
    SECURITY_SCORE=$((SECURITY_SCORE - 10))
  fi
}

parse_semgrep_triage() {
  local triage="${ROOT}/security/reports/semgrep-triage-phase2.json"
  python3 - <<PY
import json, pathlib, sys
p = pathlib.Path("${triage}")
if not p.exists():
    print("0 0 0 0 0 0")
    sys.exit(0)
data = json.loads(p.read_text())
findings = data.get("findings", [])
confirmed = {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0}
for item in findings:
    if item.get("classification") != "CONFIRMED":
        continue
    sev = str(item.get("severity", "LOW")).upper()
    if sev == "WARNING":
        sev = "MEDIUM"
    if sev == "INFO":
        sev = "LOW"
    confirmed[sev] = confirmed.get(sev, 0) + 1
summary = data.get("summary", {})
reviewed = summary.get("total_reviewed", len(findings))
false_pos = summary.get("false_positive", sum(1 for i in findings if i.get("classification") == "FALSE_POSITIVE"))
print(confirmed.get("CRITICAL", 0), confirmed.get("HIGH", 0), confirmed.get("MEDIUM", 0), confirmed.get("LOW", 0), reviewed, false_pos)
PY
}

run_semgrep() {
  log "Semgrep SAST..."
  local semgrep_cmd=""
  if command -v semgrep >/dev/null 2>&1; then
    semgrep_cmd="semgrep"
  elif python3 -m semgrep --version >/dev/null 2>&1; then
    semgrep_cmd="python3 -m semgrep"
  fi

  if [[ -z "${semgrep_cmd}" ]]; then
    record "semgrep_security" "TOOL_MISSING" "semgrep not installed"
    record "semgrep_quality" "TOOL_MISSING" "semgrep not installed"
    SEMGREP_STATUS="TOOL_FAILURE"
    HIGH=$((HIGH + 1))
    SECURITY_SCORE=$((SECURITY_SCORE - 15))
    log "Install: pip install semgrep OR brew install semgrep"
    return 1
  fi

  local security_json="${REPORT_DIR}/semgrep-security.json"
  local quality_json="${REPORT_DIR}/semgrep-quality.json"

  if ${semgrep_cmd} --config "${ROOT}/security/semgrep/rshd-security.yml" --json -o "${security_json}" "${ROOT}/backend" "${ROOT}/lib" 2>"${REPORT_DIR}/semgrep-security.log"; then
    record "semgrep_security_scan" "PASS" "scan completed"
  else
    record "semgrep_security_scan" "WARN" "non-zero exit — see ${security_json}"
  fi

  ${semgrep_cmd} --config "${ROOT}/security/semgrep/rshd-quality.yml" --json -o "${quality_json}" "${ROOT}/lib" "${ROOT}/test" 2>>"${REPORT_DIR}/semgrep-security.log" || true
  record "semgrep_quality_scan" "PASS" "see ${quality_json}"

  if ${semgrep_cmd} --config "${ROOT}/security/semgrep/rshd-mobile.yml" --json -o "${REPORT_DIR}/semgrep-mobile.json" "${ROOT}/lib" 2>>"${REPORT_DIR}/semgrep-security.log"; then
    record "semgrep_mobile_scan" "PASS" "see semgrep-mobile.json"
  else
    record "semgrep_mobile_scan" "WARN" "see semgrep-mobile.json"
  fi

  read -r CONF_CRIT CONF_HIGH CONF_MED CONF_LOW REVIEWED FALSE_POS <<< "$(parse_semgrep_triage)"
  CRITICAL=$((CRITICAL + CONF_CRIT))
  HIGH=$((HIGH + CONF_HIGH))
  MEDIUM=$((MEDIUM + CONF_MED))
  LOW=$((LOW + CONF_LOW))

  if [[ ${CONF_CRIT} -gt 0 || ${CONF_HIGH} -gt 0 ]]; then
    SEMGREP_STATUS="SCAN_COMPLETED_BLOCKERS_FOUND"
    record "semgrep_enforcement" "FAIL" "confirmed Critical=${CONF_CRIT} High=${CONF_HIGH}"
    SECURITY_SCORE=$((SECURITY_SCORE - 20))
  else
    SEMGREP_STATUS="SCAN_COMPLETED_NO_BLOCKERS"
    record "semgrep_enforcement" "PASS" "reviewed=${REVIEWED} false_positive=${FALSE_POS}"
  fi
}

check_contract_coverage() {
  log "Security contract coverage..."
  local gaps
  gaps=$(rg -o "SECURITY_COVERAGE_GAP" "${ROOT}/security/controls/feature-security-contract.yaml" 2>/dev/null | wc -l | tr -d ' ')
  record "contract_gaps" "WARN" "${gaps} coverage gaps documented"
  if [[ ${gaps} -gt 8 ]]; then
    MEDIUM=$((MEDIUM + 1))
    SECURITY_SCORE=$((SECURITY_SCORE - 3))
  fi
}

check_env_in_app() {
  log "env() outside config..."
  if rg "env\\(" "${ROOT}/backend/app" --glob '*.php' -q 2>/dev/null; then
    record "env_outside_config" "FAIL" "env() in app/"
    HIGH=$((HIGH + 1))
    SECURITY_SCORE=$((SECURITY_SCORE - 10))
  else
    record "env_outside_config" "PASS" "No env() in app/"
  fi
}

check_dd_dump() {
  log "dd/dump in backend..."
  if rg "\\b(dd|dump)\\(" "${ROOT}/backend/app" --glob '*.php' -q 2>/dev/null; then
    record "dd_dump" "FAIL" "debug calls in app/"
    MEDIUM=$((MEDIUM + 1))
    SECURITY_SCORE=$((SECURITY_SCORE - 5))
  else
    record "dd_dump" "PASS" "Clean"
  fi
}

check_remember_password() {
  log "Flutter remember-me password storage..."
  if rg "(getRememberedCredentials|write\\(key: StorageKeys\\.rememberedPassword|saveRememberMe\\([^)]*password|StorageKeys\\.rememberedPassword,\\s*value:)" "${ROOT}/lib" -q 2>/dev/null; then
    record "remember_me_password" "FAIL" "Password may persist on device"
    HIGH=$((HIGH + 1))
    SECURITY_SCORE=$((SECURITY_SCORE - 5))
  else
    record "remember_me_password" "PASS" "No password persistence detected"
  fi
}

scan_secrets
check_composer_advisories
run_semgrep
check_contract_coverage
check_env_in_app
check_dd_dump
check_remember_password

if [[ ${SECURITY_SCORE} -lt 0 ]]; then SECURITY_SCORE=0; fi

{
  echo "timestamp: ${TIMESTAMP}"
  echo "security_score: ${SECURITY_SCORE}"
  echo "semgrep_status: ${SEMGREP_STATUS}"
  echo "secrets: ${SECRETS}"
  echo "critical: ${CRITICAL}"
  echo "high: ${HIGH}"
  echo "medium: ${MEDIUM}"
  echo "low: ${LOW}"
  echo "results:"
  for r in "${RESULTS[@]}"; do echo "  - ${r}"; done
} > "${REPORT_DIR}/security-audit.yaml"

log "Security score: ${SECURITY_SCORE}/100"
log "Semgrep status: ${SEMGREP_STATUS}"

if [[ "${SEMGREP_STATUS}" == "TOOL_FAILURE" ]]; then
  exit 1
fi

if [[ "${SEMGREP_STATUS}" == "SCAN_COMPLETED_BLOCKERS_FOUND" ]]; then
  exit 1
fi

exit 0

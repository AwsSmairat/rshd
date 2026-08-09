#!/usr/bin/env bash
# RSHD Quality Audit — Laravel + Flutter static quality gates
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_DIR="${ROOT}/security/reports"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
mkdir -p "${REPORT_DIR}"

QUALITY_SCORE=100
RESULTS=()

log() { echo "[quality-audit] $*"; }
record() { RESULTS+=("$1|$2|$3"); }

run_laravel_tests() {
  log "Running Laravel tests..."
  if (cd "${ROOT}/backend" && php artisan test > "${REPORT_DIR}/laravel-test.log" 2>&1); then
    record "laravel_tests" "PASS" "See laravel-test.log"
  else
    record "laravel_tests" "FAIL" "See laravel-test.log"
    QUALITY_SCORE=$((QUALITY_SCORE - 25))
  fi
}

run_pint() {
  log "Running Pint..."
  if (cd "${ROOT}/backend" && vendor/bin/pint --test > "${REPORT_DIR}/pint.log" 2>&1); then
    record "pint" "PASS" "Clean"
  else
    record "pint" "FAIL" "Style drift — see pint.log"
    QUALITY_SCORE=$((QUALITY_SCORE - 10))
  fi
}

run_composer() {
  log "Composer validate + audit..."
  if (cd "${ROOT}/backend" && composer validate --quiet && composer audit > "${REPORT_DIR}/composer-audit.log" 2>&1); then
    record "composer_audit" "PASS" "No known vulnerabilities"
  else
    record "composer_audit" "FAIL" "See composer-audit.log"
    QUALITY_SCORE=$((QUALITY_SCORE - 15))
  fi
}

run_flutter_analyze() {
  log "Flutter analyze..."
  if (cd "${ROOT}" && flutter analyze > "${REPORT_DIR}/flutter-analyze.log" 2>&1); then
    record "flutter_analyze" "PASS" "Clean"
  else
    WARN_COUNT=$(rg -c "warning •|error •" "${REPORT_DIR}/flutter-analyze.log" 2>/dev/null || echo 0)
    record "flutter_analyze" "FAIL" "${WARN_COUNT} issues — see flutter-analyze.log"
    QUALITY_SCORE=$((QUALITY_SCORE - 10))
  fi
}

run_flutter_tests() {
  log "Flutter tests..."
  if (cd "${ROOT}" && flutter test > "${REPORT_DIR}/flutter-test.log" 2>&1); then
    record "flutter_tests" "PASS" "See flutter-test.log"
  else
    record "flutter_tests" "FAIL" "See flutter-test.log"
    QUALITY_SCORE=$((QUALITY_SCORE - 25))
  fi
}

run_laravel_tests
run_pint
run_composer
run_flutter_analyze
run_flutter_tests

if [[ ${QUALITY_SCORE} -lt 0 ]]; then QUALITY_SCORE=0; fi

{
  echo "timestamp: ${TIMESTAMP}"
  echo "quality_score: ${QUALITY_SCORE}"
  echo "results:"
  for r in "${RESULTS[@]}"; do echo "  - ${r}"; done
} > "${REPORT_DIR}/quality-audit.yaml"

log "Quality score: ${QUALITY_SCORE}/100"
exit 0

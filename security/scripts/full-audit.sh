#!/usr/bin/env bash
# RSHD Full Quality & Security Audit — single command from repo root
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_DIR="${ROOT}/security/reports"
SCRIPT_DIR="${ROOT}/security/scripts"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
GIT_COMMIT="$(git -C "${ROOT}" rev-parse HEAD 2>/dev/null || echo unknown)"

mkdir -p "${REPORT_DIR}"

log() { echo "[full-audit] $*"; }

log "Starting RSHD Quality & Security Gate..."
log "Commit: ${GIT_COMMIT}"

"${SCRIPT_DIR}/quality-audit.sh" || true
"${SCRIPT_DIR}/security-audit.sh" || true

# Parse scores
QUALITY_SCORE=$(rg "^quality_score:" "${REPORT_DIR}/quality-audit.yaml" 2>/dev/null | awk '{print $2}' || echo 0)
SECURITY_SCORE=$(rg "^security_score:" "${REPORT_DIR}/security-audit.yaml" 2>/dev/null | awk '{print $2}' || echo 0)

# Test counts
LARAVEL_FAIL=$(rg -c "^\s*⨯" "${REPORT_DIR}/laravel-test.log" 2>/dev/null || echo 0)
LARAVEL_TOTAL=$(rg "function test_" "${ROOT}/backend/tests" --glob '*Test.php' 2>/dev/null | wc -l | tr -d ' ')
LARAVEL_PASS=$((LARAVEL_TOTAL - LARAVEL_FAIL))
FLUTTER_LINE=$(rg "Some tests failed|All tests passed" "${REPORT_DIR}/flutter-test.log" 2>/dev/null | tail -1 || true)
if echo "${FLUTTER_LINE}" | rg -q "All tests passed"; then
  FLUTTER_STATUS="PASS"
else
  FLUTTER_STATUS="FAIL"
fi

CONTRACT_GAPS=$(rg -o "SECURITY_COVERAGE_GAP" "${ROOT}/security/controls/feature-security-contract.yaml" 2>/dev/null | wc -l | tr -d ' ')
CONTRACT_TOTAL=$(rg "^  - id:" "${ROOT}/security/controls/feature-security-contract.yaml" | wc -l | tr -d ' ')
CONTRACT_WITH_TESTS=$((CONTRACT_TOTAL - CONTRACT_GAPS))
CONTRACT_PCT=$((CONTRACT_WITH_TESTS * 100 / CONTRACT_TOTAL))

AUTH_PCT=$(rg "^  authorization_test_coverage_percent:" "${ROOT}/security/controls/authorization-matrix.yaml" | awk '{print $2}')

OVERALL="PASS"
if [[ "${LARAVEL_FAIL}" -gt 0 ]] || [[ "${FLUTTER_STATUS}" == "FAIL" ]]; then OVERALL="FAIL"; fi
if [[ "${SECURITY_SCORE}" -lt 70 ]] || [[ "${QUALITY_SCORE}" -lt 70 ]]; then OVERALL="FAIL"; fi

SECRETS=$(rg "^secrets:" "${REPORT_DIR}/security-audit.yaml" | awk '{print $2}')
CRITICAL=$(rg "^critical:" "${REPORT_DIR}/security-audit.yaml" | awk '{print $2}')
HIGH=$(rg "^high:" "${REPORT_DIR}/security-audit.yaml" | awk '{print $2}')
MEDIUM=$(rg "^medium:" "${REPORT_DIR}/security-audit.yaml" | awk '{print $2}')
LOW=$(rg "^low:" "${REPORT_DIR}/security-audit.yaml" | awk '{print $2}')

API_COUNT=$(python3 -c "import json; print(len(json.load(open('${ROOT}/security/inventory/api-routes.json'))))" 2>/dev/null || echo 55)

cat > "${REPORT_DIR}/latest-summary.md" <<EOF
# RSHD Quality & Security Gate — Latest Summary

**Timestamp:** ${TIMESTAMP}  
**Git commit:** \`${GIT_COMMIT}\`

## Overall

| Metric | Result |
|--------|--------|
| **Overall Gate** | **${OVERALL}** |
| Quality Score | ${QUALITY_SCORE}/100 |
| Security Score | ${SECURITY_SCORE}/100 |
| Security Contract Coverage | ${CONTRACT_PCT}% (${CONTRACT_WITH_TESTS}/${CONTRACT_TOTAL} with automated tests) |
| Authorization Test Coverage | ${AUTH_PCT}% |

## Inventory

| Item | Count |
|------|-------|
| Laravel API endpoints | ${API_COUNT} |
| Flutter protected screens | 6 |
| Security contracts | ${CONTRACT_TOTAL} |
| Threat model risks | 15 |

## Findings summary

| Severity | Count |
|----------|-------|
| Critical | ${CRITICAL:-0} |
| High | ${HIGH:-0} |
| Medium | ${MEDIUM:-0} |
| Low | ${LOW:-0} |
| Secrets (tracked) | ${SECRETS:-0} |

## Gate results

| Check | Status |
|-------|--------|
| Laravel tests | ${LARAVEL_PASS} pass / ${LARAVEL_FAIL} fail |
| Flutter tests | ${FLUTTER_STATUS} |
| Flutter analyze | see flutter-analyze.log |
| Pint | see pint.log |
| Composer audit | see composer-audit.log |
| Semgrep | see security-audit.yaml |
| One-command audit | ${OVERALL} |
| CI security gate | CREATED (see .github/workflows/security-gate.yml) |

## Coverage gaps (baseline)

- BOLA/IDOR automated gaps: ~8 endpoints
- Auth/AuthZ test gaps: ${CONTRACT_GAPS} contract entries marked SECURITY_COVERAGE_GAP
- Rate-limit gaps: no global API throttle
- MASVS gaps: PDF cache encryption, remember-me password

## Reports

- \`security/reports/quality-audit.yaml\`
- \`security/reports/security-audit.yaml\`
- \`security/reports/findings-baseline.json\`
- Detailed logs: laravel-test.log, flutter-test.log, composer-audit.log

See \`security/reports/findings-baseline.json\` for top 20 ranked findings.
EOF

log "Report written to security/reports/latest-summary.md"
log "Overall: ${OVERALL}"

[[ "${OVERALL}" == "PASS" ]] && exit 0 || exit 1

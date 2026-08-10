# RSHD Quality & Security Gate — Latest Summary

**Timestamp:** 2026-08-10T14:12:54Z  
**Git commit:** `25d44bdfc3a8e17b299ced07dd7e8a0a8cda5d77`

## Overall

| Metric | Result |
|--------|--------|
| **Overall Gate** | **FAIL** |
| Quality Score | 75/100 |
| Security Score | 80/100 |
| Security Contract Coverage | 100% (30/30 with automated tests) |
| Authorization Test Coverage | 100% |

## Inventory

| Item | Count |
|------|-------|
| Laravel API endpoints | 55 |
| Flutter protected screens | 6 |
| Security contracts | 30 |
| Threat model risks | 15 |

## Findings summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 1 |
| Medium | 1 |
| Low | 0 |
| Secrets (tracked) | 0 |

## Gate results

| Check | Status |
|-------|--------|
| Laravel tests | 205 pass / 1 fail |
| Flutter tests | PASS |
| Flutter analyze | see flutter-analyze.log |
| Pint | see pint.log |
| Composer audit | see composer-audit.log |
| Semgrep | see security-audit.yaml |
| One-command audit | FAIL |
| CI security gate | CREATED (see .github/workflows/security-gate.yml) |

## Coverage gaps (baseline)

- BOLA/IDOR automated gaps: ~8 endpoints
- Auth/AuthZ test gaps: 0 contract entries marked SECURITY_COVERAGE_GAP
- Rate-limit gaps: no global API throttle
- MASVS gaps: PDF cache encryption, remember-me password

## Reports

- `security/reports/quality-audit.yaml`
- `security/reports/security-audit.yaml`
- `security/reports/findings-baseline.json`
- Detailed logs: laravel-test.log, flutter-test.log, composer-audit.log

See `security/reports/findings-baseline.json` for top 20 ranked findings.

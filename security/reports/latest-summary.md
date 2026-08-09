# RSHD Quality & Security Gate — Latest Summary

**Timestamp:** 2026-08-09T22:15:14Z  
**Git commit:** `5d71935296fd785183f148a6e9d78fbb2ab29a5a`

## Overall

| Metric | Result |
|--------|--------|
| **Overall Gate** | **PASS** |
| Quality Score | 100/100 |
| Security Score | 95/100 |
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
| High | 0 |
| Medium | 1 |
| Low | 0 |
| Secrets (tracked) | 0 |

## Gate results

| Check | Status |
|-------|--------|
| Laravel tests | 203 pass / 0 fail |
| Flutter tests | PASS |
| Flutter analyze | see flutter-analyze.log |
| Pint | see pint.log |
| Composer audit | see composer-audit.log |
| Semgrep | see security-audit.yaml |
| One-command audit | PASS |
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

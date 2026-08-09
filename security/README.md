# RSHD Quality & Security Gate

Permanent quality and security baseline for the RSHD monorepo:

- **Laravel API** (`backend/`)
- **Filament admin/teacher panel**
- **Flutter student app** (`lib/`)

## Principles

- Threat modeling over zero-day claims
- Attack-surface mapping + abuse-case analysis
- Dependency monitoring + secure coding rules
- Regression security tests + risk forecasting
- **Baseline first** — findings are triaged, not mass-fixed in gate setup phase

References: OWASP ASVS 5.x, OWASP Top 10 2025, OWASP API Security Top 10, OWASP MASVS/MASTG.

## Quick start

```bash
# Full audit from repo root
./security/scripts/full-audit.sh

# Individual gates
./security/scripts/quality-audit.sh
./security/scripts/security-audit.sh
```

Reports land in `security/reports/` (never commit secrets or signed Bunny URLs).

## Structure

| Path | Purpose |
|------|---------|
| `baseline/` | Quality & security baselines |
| `inventory/` | Machine-readable project inventory |
| `threat-model/` | Architecture, trust boundaries, risk register |
| `controls/` | Security contracts, authorization matrix |
| `semgrep/` | SAST rules (PHP, Dart, config) |
| `scripts/` | One-command audit runners |
| `reports/` | Generated audit output |

## CI

- **PR (fast gate):** `.github/workflows/security-gate.yml`
- **Nightly (full audit):** same workflow, `schedule` trigger
- **Dynamic ZAP:** staging only — see `threat-model/staging-dynamic-scan.md`

## Finding format

Every finding includes: ID, severity, category, location, description, exploit scenario, impact, recommendation, evidence, false-positive status.

## Merge policy

**BLOCK:** failing tests, analyzer errors, confirmed CRITICAL/HIGH auth flaws, secrets in repo, protected-content public regression.

**WARN:** medium/low findings, outdated deps, coverage gaps — triage via `security/reports/`.

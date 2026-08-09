# RSHD Security Baseline

Established: 2026-08-10 (gate system bootstrap)

## Scope

- Laravel API v1 (`/api/v1/*`)
- Filament `/admin` panel
- Flutter student app (iOS/Android)
- Bunny Stream (video) + Bunny Storage/CDN (files)
- Sanctum token auth + enrollment access control

## Non-goals (this phase)

- No mass remediation of findings
- No API contract changes
- No Bunny architecture changes
- No dependency major upgrades

## Required controls (target state)

| Control | Laravel | Flutter |
|---------|---------|---------|
| Auth on sensitive routes | Sanctum | Secure storage token |
| Object-level authorization | Policies + EnrollmentService | Server-enforced only |
| Signed media URLs | Bunny CDN tokens, TTL | Refresh before expiry |
| No permanent protected URLs in API | Resource allowlisting | No long-term signed URL cache |
| Rate limits on auth flows | Service-level throttles | N/A |
| Fail-secure Bunny config | AppServiceProvider boot checks | Error states, no fallback URLs |
| Screen protection | N/A | ProtectedContentScope on paid routes |
| Secret hygiene | `.env` gitignored | No hardcoded secrets |

## Severity definitions

| Level | Definition |
|-------|------------|
| CRITICAL | Unauthenticated/cross-tenant access to paid content, secret exposure, auth bypass |
| HIGH | IDOR/BOLA on protected objects, missing enrollment check, token/session flaws |
| MEDIUM | Missing rate limit, data overexposure, weak config default |
| LOW | Hardening, logging hygiene, maintainability security debt |

## Baseline metrics (first scan)

See `security/reports/latest-summary.md` for current numbers.

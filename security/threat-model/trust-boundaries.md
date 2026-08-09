# Trust Boundaries

| ID | Boundary | Trust level (in) | Trust level (out) | Controls |
|----|----------|------------------|-------------------|----------|
| TB-01 | Client ↔ API | semi-trusted (authenticated user) | untrusted | TLS, Sanctum, validation, policies |
| TB-02 | API ↔ Database | trusted process | trusted storage | parameterized queries, transactions |
| TB-03 | API ↔ Bunny | trusted server | third-party | API keys server-only, signed URLs |
| TB-04 | Client ↔ CDN | untrusted replay window | CDN edge | short TTL tokens |
| TB-05 | Client local FS | device user | OS sandbox | screen protection, no plaintext secrets |
| TB-06 | Admin ↔ Filament | staff roles | untrusted internet | session, CSRF, maintenance gate |
| TB-07 | Bunny ↔ Webhook | Bunny IP/signature | API endpoint | HMAC validation |

## Fail-secure expectations

- Missing Bunny video config → no playback URL issued
- Missing Bunny files config → download fails closed
- Unauthenticated → 401 on protected routes
- Unenrolled student → 403 on content routes

# RSHD Risk Register

Scoring: CRITICAL / HIGH / MEDIUM / LOW based on exposure × impact × complexity × test coverage.

| ID | Feature | Risk | Score | Likely future regression | Prevent | Detect | Respond |
|----|---------|------|-------|--------------------------|---------|--------|---------|
| R-001 | Signed video playback | Permanent URL restored in API resource | HIGH | Developer adds `url` field to VideoResource | Semgrep, contract | Integration test | Audit |
| R-002 | Signed file download | `file_url` leaked in JSON | HIGH | New serializer exposes model accessor | Semgrep RSHD-LARAVEL-002 | LessonFileDownloadTest | Storage audit |
| R-003 | Enrollment expiry | Policy forgets expiry check | HIGH | New endpoint skips EnrollmentService | Policy trait, matrix test | VideoPlaybackTest | 403 |
| R-004 | IDOR video/file | New controller skips authorize() | CRITICAL | Copy-paste controller without policy | Semgrep 001, code review | Feature Security tests | Block merge |
| R-005 | Bunny config missing | Fail-open public fallback | CRITICAL | Local storage fallback re-enabled | Boot validator | Config test | 503 |
| R-006 | Auth brute force | No global API throttle | MEDIUM | New auth endpoint without throttle | Contract checklist | LoginThrottle tests | Lockout |
| R-007 | OTP abuse | SMS/email flooding | MEDIUM | Resend endpoint rate gap | Rate limit service | PasswordResetTest | Cooldown |
| R-008 | Flutter remember-me | Password on device | MEDIUM | Feature expansion | MASVS review | SECURITY_COVERAGE_GAP | User education |
| R-009 | PDF cache at rest | Unencrypted offline PDF | MEDIUM | Cache on shared device | Screen protection | MASVS STORAGE | Clear cache on logout |
| R-010 | Annotation race | Lost updates concurrent save | LOW | High autosave frequency | Transaction/unique | SECURITY_COVERAGE_GAP | Last-write-wins audit |
| R-011 | Webhook spoof | Weak HMAC check | HIGH | Refactor removes signature verify | BunnyStreamTest | Alert on failures | Reject |
| R-012 | Filament IDOR | Instructor views other instructor data | HIGH | Missing HasInstructorScope | Filament policy review | SECURITY_COVERAGE_GAP | Audit log |
| R-013 | Dependency CVE | league/commonmark bypass | MEDIUM | Transitive update | composer audit CI | composer audit | Patch |
| R-014 | iOS screenshot | Content captured manually | LOW | N/A — platform limit | Overlay on recording | Capture detection | Policy |
| R-015 | Assignment upload | Malicious file upload | HIGH | New mime type allowed | Validation rules | SECURITY_COVERAGE_GAP | Quarantine |

**Threat models created:** 15 entries  
**Future regression risks identified:** 15+

Feature-specific notes: see `feature-threats/*.md`

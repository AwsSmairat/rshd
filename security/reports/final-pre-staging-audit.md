# RSHD Final Pre-Staging Audit

**Timestamp:** 2026-08-24T16:20:00Z  
**Scope:** Current repository only. No staging deploy, DNS, device, ZAP, load, or Bunny production E2E was executed.  
**Secrets:** Pattern scan only. No secret values are recorded in this report.

## Gate results

| Check | Result | Evidence |
|-------|--------|----------|
| Laravel tests | PASS | `php artisan test --exclude-group=manual` → 228 tests, 775 assertions, exit 0 |
| Flutter tests | PASS | `flutter test` → 158/158 |
| Flutter analyze | PASS | `flutter analyze` → No issues found |
| Pint | PASS | `vendor/bin/pint --test` → passed |
| Dart format | PASS | `dart format --output=none --set-exit-if-changed .` → exit 0 |
| Composer audit | PASS | Exit 0; 3 Laravel 11 advisories ignored with documented exceptions until 2026-12-31 |
| Semgrep | PASS | Security rules scanned; 26 hits previously triaged as false positive / accepted risk / needs review. No new confirmed Critical/High. Two PHP rule patterns failed to parse (pre-existing). Mobile YAML has a parse error (not used by CI Fast Gate). |
| Secret scan | PASS | `backend/.env` is not tracked. Pattern hits are config/test key *names*, not live credentials. |
| Advisory exceptions | PASS | `./security/scripts/check-advisory-exceptions.sh` |
| CI Security Gate | PASS | `.github/workflows/security-gate.yml`: PHP 8.5, SQLite bootstrap, ephemeral `APP_KEY`, Laravel tests, Flutter `--exclude-tags golden` |

## Authorization / contracts

| Control | Coverage |
|---------|----------|
| Authorization matrix | 11/11 (100%) — `security/controls/authorization-matrix.yaml` |
| Security contracts | 30/30 (100%) — no `SECURITY_COVERAGE_GAP` markers |

Cross-user isolation (User A ↛ User B) is covered by policies + tests for grades, quizzes, assignments, annotations, notifications, devices, videos, files, progress, and profile.

## Confirmed vulnerabilities fixed in this audit

1. **Critical — account takeover via `POST /api/v1/email/verify`.** Already-verified students received a Sanctum token for any 6-digit code. Now returns 422 and does not mint a token.
2. **High — blocked students kept API access.** `RejectBlockedApiUser` now wraps authenticated API routes (logout excluded so a leftover session can still be cleared).
3. **High — blocking a student did not revoke tokens.** `User::updated` deletes Sanctum tokens when status becomes `blocked`.
4. **High — onboarding never shown on first launch.** Unauthenticated first-run now resolves to `/onboarding`; completed flag `rshd_onboarding_completed_v1` sends returning users to login; authenticated users still skip to home.
5. **Medium — local file stream URLs were file-id-only.** Signed local stream URLs now include `uid` and re-check `LessonFileAccessService::canDownload` (blocked / unenrolled users fail even with a leaked URL).
6. **Medium — foreign quiz `question_id` could inflate score.** Submit now scores only questions belonging to the current quiz (eager-loaded answers; no per-answer `find()`).

## Residual findings (not blockers for a carefully configured staging deploy)

### Medium

- Sanctum `expiration` is `null` (`backend/config/sanctum.php:53`) — stolen tokens last until revoked.
- Email verify/resend still returns 404 for unknown users (enumeration). Password forgot already uses a generic response.
- Bunny embed playback is unsigned when `BUNNY_STREAM_EMBED_TOKEN_KEY` is empty (`BunnyStreamVideoProvider`). Staging must set the embed token key.
- Local video stream URLs remain capability URLs within TTL; enrollment is re-checked. Do not treat them as non-shareable.
- Laravel 11 CRLF email-rule advisories have no 11.x patch (documented exception; upgrade to Laravel 12 required for a vendor fix).
- Subject catalog calls `enrollmentStatusFor()` per subject (`SubjectController` + `EnrollmentService`) — N+1 under load. Evidence only; no index change made.
- Unverified-student enforcement is on login and `GET /me`, not a global API middleware. Register does **not** mint a token when verification is required.

### Low

- PDF cache is app-private and user-scoped but not encrypted at rest.
- iOS `NSAllowsLocalNetworking=true`; release Dart still requires HTTPS `API_BASE_URL`.
- Register screen has no Privacy/Terms links; post-login terms gate exists.
- `email/verify` throttle is IP-only (not per-email).
- Semgrep mobile ruleset YAML is invalid (`metavariable-regex` placement); Fast Gate does not use it.
- `actions/checkout@v4` Node 20 deprecation warning — not a functional CI failure.

## Production / staging configuration (code)

Fail-secure assertions exist in `AppServiceProvider` for video/file signing. Staging template (`backend/.env.staging.example`) sets `APP_ENV=staging`, `APP_DEBUG=false`, HTTPS `APP_URL`. Flutter release refuses empty/cleartext `API_BASE_URL`.

**Do not copy `backend/.env.example` onto staging** (`APP_DEBUG=true`, local HTTP, Bunny local fallback true).

Actual server `APP_KEY` / Bunny / SMTP / Redis / proxy values were **not** inspected on a live host.

## Tests added

- `EmailVerificationSecurityTest`: already-verified users cannot mint a session; blocked users cannot verify.
- `BlockedStudentSessionTest`: token revoke on block; blocked users denied grades/quizzes/assignments/notifications; logout still allowed.
- `LessonFileDownloadTest`: local stream rejected after the owning student is blocked.
- `QuizSubmitAuthorizationTest`: foreign question IDs do not inflate score.
- Flutter `resolveStartupRoute`: first launch → onboarding; completed → login.

## Files

Created:

- `backend/app/Http/Middleware/RejectBlockedApiUser.php`
- `backend/tests/Feature/Security/Auth/BlockedStudentSessionTest.php`
- `security/reports/final-pre-staging-audit.md`

Modified: EmailVerificationController, LessonFileController, QuizController, User model, LessonFileDownloadService, `routes/api.php`, related security tests, startup coordinator/resolver, plus Dart format of onboarding/auth files already in the tree.

## Explicitly not run

Real HTTPS staging, real iPhone, real Android, Bunny production E2E, OWASP ZAP, 500–650 user load, backup/restore drill.

## Verdict

Repository is **ready for a private staging deploy** after operators fill staging secrets and Bunny keys from the staging template. It is **not production-ready** until live HTTPS, device, Bunny E2E, ZAP, load, and backup drills pass, and Laravel 11 advisories are retired via upgrade.

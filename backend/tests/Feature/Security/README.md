# Laravel Security Regression Tests

Dedicated test groups for the RSHD Quality & Security Gate.

## Structure

```
tests/Feature/Security/
  Auth/           — login abuse, registration, session revocation
  Authorization/  — IDOR/BOLA matrix cases
  Files/          — signed download, annotation ownership
  Videos/         — playback IDOR, expired enrollment
  RateLimits/     — throttle verification
  DataExposure/   — API resource field allowlists
  Configuration/  — fail-secure Bunny config
  BusinessLogic/  — enrollment expiry, progress abuse
```

## Running

```bash
cd backend
php artisan test --filter=Security
```

## Baseline status (2026-08-10)

Existing security coverage lives in Feature tests (not yet migrated):

- `VideoPlaybackTest.php` (25 tests)
- `LessonFileDownloadTest.php` (10 tests)
- `BunnyStreamTest.php` (23 tests)
- `PasswordResetTest.php` (17 tests)
- `AuthOAuthTest.php` (7 tests)

**Next step:** Add new tests here without moving existing ones until triaged.

## Tags

Use PHPUnit `@group security` on new tests for CI filtering.

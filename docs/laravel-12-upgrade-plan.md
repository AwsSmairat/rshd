# Laravel 11 → Laravel 12 Upgrade Plan

**Status:** Plan only. Do **not** upgrade in this branch.  
**Reason:** Current Laravel 11.x has no vendor patch for the documented CRLF email-rule advisories (`PKSA-m5cs-t1y6-qpcs`, `PKSA-3r5d-mb8f-1qw9`, `PKSA-mdq4-51ck-6kdq`). Those exceptions expire 2026-12-31. Laravel 12 is the supported path to retire them.

Inspected from `backend/composer.json` and `backend/composer.lock` (2026-08-24):

| Package | Constraint / locked |
|---------|---------------------|
| PHP | `^8.2` (CI uses 8.5) |
| `laravel/framework` | `^11.31` / **v11.54.0** |
| `filament/filament` | `^3.2` / **v3.3.54** |
| `laravel/sanctum` | `^4.3` / **v4.3.2** |
| `spatie/laravel-permission` | `^6.25` / **6.25.0** |
| `laravel/tinker` | `^2.9` / **v2.11.1** |
| `nunomaduro/collision` | `^8.1` / **v8.9.4** |
| `phpunit/phpunit` | `^11.0.1` |

## Compatibility snapshot

- **PHP:** Laravel 12 requires PHP 8.2+. Current constraint and CI already match. No PHP bump required.
- **Filament:** Locked Filament 3.3.54 already requires `illuminate/*: ^10.45\|^11.0\|^12.0\|^13.0`. **Not a blocker.** Stay on Filament 3.3.x unless a 3.3 patch is needed after the upgrade. Do not jump to Filament 4 in the same change.
- **Sanctum:** Locked Sanctum 4.3.2 already requires `illuminate/*: ^11.0\|^12.0\|^13.0`. **Not a blocker.** Keep Sanctum 4.x. Token `expiration` remains an application decision (Flutter has no refresh-token flow).
- **spatie/laravel-permission:** 6.25.0 already supports Laravel 12.
- **laravel/tinker:** 2.11.1 already supports Laravel 12.
- **Hard constraint:** only `laravel/framework: ^11.31` in `composer.json` pins the app to 11.x. That is the package that must change.
- **Dev tools:** collision 8.9, pint, pail, phpunit 11 are expected to resolve with Laravel 12. Confirm with `composer why-not laravel/framework 12.*` on the upgrade branch before changing constraints.

No first-party packages in `composer.json` are known Laravel-12-incompatible. Expected risk is **medium**: framework + Symfony 7 mailer/validation behavior, config defaults, and Filament Livewire 3 regression — not a greenfield rewrite.

## Expected migration / config impact

Laravel 12 is a maintenance-style major. Typical repo work:

1. Bump `laravel/framework` to `^12.0` and run `composer update laravel/framework -W`.
2. Compare published config/stubs (`php artisan config:publish --all` is **not** required). Diff `config/auth.php`, `config/mail.php`, `config/sanctum.php`, `bootstrap/app.php`.
3. Re-check mail validation / email-rule behavior that the 11.x advisories cover. Keep existing Arabic validation messages.
4. Do **not** enable Sanctum token expiration in the same PR unless a refresh-token flow lands first.
5. Re-run `php artisan filament:upgrade` after composer dump (already in `post-autoload-dump`).
6. SQLite test bootstrap and `RefreshDatabase` should keep working. Watch for query-grammar or enum casting diffs.
7. Staging `.env` stays `APP_ENV=staging`, `APP_DEBUG=false`. Do not copy `.env.example`.

## Risk

| Area | Risk | Notes |
|------|------|--------|
| Auth / Sanctum | Low | 4.x already L12-ready; no expiration change in this upgrade |
| Filament admin | Medium | Re-test every resource, login, file/video upload, enrollment actions |
| Mail / OTP | Medium | This upgrade exists to pick up the email-rule fix; verify verify/reset/resend mail |
| API JSON shape | Low | Keep existing success/error envelopes |
| Tests | Medium | Full PHPUnit + Flutter contract tests after composer update |
| Production | High until staging sign-off | Do not ship Laravel 12 straight to production |

---

## Gated sequence

### 1. Upgrade branch

- Create `chore/laravel-12` from the current release/staging branch.
- Do not mix store-signing, DNS, or mobile package-id changes on this branch.
- Keep the three Composer audit ignores until Laravel 12 is installed and `composer audit` is clean, then **remove** them.

### 2. Dependency changes

On the upgrade branch only:

```bash
cd backend
composer why-not laravel/framework 12.0.0
# then, after review:
# composer require laravel/framework:^12.0 --with-all-dependencies
```

- Change `"laravel/framework": "^11.31"` → `"^12.0"`.
- Let Composer raise transitive packages. Do not pin Filament 4.
- If `composer why-not` reports a blocker, stop and document it. Do not `--ignore-platform-reqs`.
- Commit `composer.json` + `composer.lock` together.

### 3. Laravel upgrade

- Follow https://laravel.com/docs/12.x/upgrade for the locked 12.x version.
- Run `php artisan about` and confirm framework 12.x.
- Smoke: `php artisan route:list`, `php artisan config:clear`, Filament admin boot.
- Confirm `AppServiceProvider` production/staging video+file assertions still run.
- Confirm email verification, password reset, and Filament mail still send.

### 4. Test suite

```bash
cd backend
php artisan test --exclude-group=manual
./vendor/bin/pint --test
composer audit
```

Also run Flutter `flutter test` if API contracts change. Add or update tests for any mail/validation behavior that shifted.

**Exit criterion:** PHPUnit green, Pint green, `composer audit` green **without** the three Laravel 11 ignores.

### 5. Security audit

- Re-run Fast Gate / `security-gate.yml`.
- Re-run `./security/scripts/check-advisory-exceptions.sh`.
- Targeted re-test: email verify/resend enumeration, login throttle, Sanctum logout, blocked/unverified middleware, signed video/file URLs, Filament authorization.
- Confirm CRLF email-rule advisories are gone from `composer audit`.

### 6. Staging regression

- Deploy **only** to staging.
- Run `docs/staging-e2e-matrix.md`.
- Bunny embed must still require `BUNNY_STREAM_EMBED_TOKEN_KEY`.
- OTP mail, password reset, Google/Apple OAuth, Filament enrollment, video playback.

### 7. Production approval

Required sign-off before production:

- [ ] `composer audit` clean (Laravel 11 ignores removed)
- [ ] Staging E2E passed
- [ ] Security gate passed
- [ ] Filament admin smoke passed
- [ ] Rollback plan: previous 11.x artifact + DB backup
- [ ] Explicit production owner approval

**Do not perform this upgrade until the sequence above is scheduled. This document does not authorize a framework bump.**

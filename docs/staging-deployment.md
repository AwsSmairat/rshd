# RSHD Staging / Pre-Production Deployment

**Purpose:** Document staging architecture and runbooks. **No secrets in this file.**

Staging validates production-like behavior without public launch, search indexing, or real user data.

---

## 1. Environment separation

| Environment | Purpose | Data | API URL |
|-------------|---------|------|---------|
| **LOCAL** | Developer machines | SQLite/MySQL local, optional demo seed | `http://127.0.0.1:8765/api/v1` |
| **STAGING** | Pre-production validation | Dedicated empty DB + `StagingDataSeeder` | `https://staging-api.example.com/api/v1` |
| **PRODUCTION** | Public launch (future) | Separate DB, real users | `https://api.example.com/api/v1` |

Each environment must have:

- Independent `APP_KEY`, database, Bunny libraries/zones (or clearly separated paths)
- Independent mail sender / inbox
- Independent cache prefix (`CACHE_PREFIX=rshd_staging_`)
- Independent queue tables / Redis DB index
- Independent log paths

**Never copy production secrets into staging.** Never commit `.env` files.

---

## 2. Server requirements (from codebase)

Verified from `backend/composer.json` and `composer.lock`:

| Component | Required version |
|-----------|------------------|
| **PHP** | `^8.2` (lock tested with 8.5.x locally) |
| **Laravel** | `11.54.0` |
| **Filament** | `3.3.54` |
| **Database** | MySQL 8+ or MariaDB 10.6+ (recommended for staging) |
| **Composer** | 2.x, deploy from `composer.lock` only |

### PHP extensions (minimum)

From Laravel 11 + Filament + app usage:

- `ctype`, `curl`, `dom`, `fileinfo`, `filter`, `hash`, `json`, `mbstring`, `openssl`, `pdo`, `pdo_mysql`, `session`, `tokenizer`, `xml`, `zip`
- **Recommended:** `intl`, `bcmath`, `redis` (if using Redis cache/queue)
- **Optional but useful:** `pcntl`, `posix` (queue workers)
- **Video metadata:** `ffprobe` binary on PATH (not a PHP extension)

### Process services

| Service | Staging requirement |
|---------|---------------------|
| Web server | Nginx (recommended) or Apache |
| PHP-FPM | 8.2+ matching CLI |
| Queue worker | `database` or `redis` driver + systemd/supervisor |
| Scheduler | Cron: `* * * * * php /path/to/artisan schedule:run` |
| TLS | Valid certificate (Let's Encrypt). Avoid self-signed for Flutter release builds |

### PHP-FPM staging tuning

Validated staging pool settings for the current 2-vCPU server:

```ini
pm = dynamic
pm.max_children = 8
pm.start_servers = 4
pm.min_spare_servers = 4
pm.max_spare_servers = 8
```

Load validation on 2026-09-06 at 250 VUs for 5 minutes: p95 1.144s, average 1.001s, 124.14 req/s, and 0% HTTP failures.

### Redis (optional)

Not required by default. `.env.staging.example` uses `database` queue + `database` cache.
Use Redis when load testing or mirroring production topology.

---

## 3. Staging Laravel configuration

```dotenv
APP_ENV=staging
APP_DEBUG=false
APP_URL=https://staging-api.example.com

QUEUE_CONNECTION=database
CACHE_STORE=database
SESSION_DRIVER=database

VIDEO_PROVIDER=bunny
VIDEO_SIGNED_PLAYBACK=true
BUNNY_STREAM_LOCAL_FALLBACK=false
FILES_SIGNED_DOWNLOAD=true
```

### Fail-secure rules

- Missing Bunny signing keys → **403**, not public URL fallback
- `BUNNY_STREAM_LOCAL_FALLBACK=false` on staging (only `local` env defaults to true)
- All secrets via server env / secrets manager — not Git

### Config caching (after deploy)

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

Clear before migrations:

```bash
php artisan config:clear && php artisan route:clear && php artisan view:clear
```

---

## 4. Database bootstrap

```bash
php artisan migrate --force
php artisan db:seed --class=StagingDataSeeder --force
```

`StagingDataSeeder` creates validation actors at `@staging.rshd.test` (see `docs/staging-e2e-matrix.md`).

Password: `STAGING_SEED_PASSWORD` on server only.

---

## 5. Web server (Nginx example)

Document root **must** be `backend/public`. See full example in repo history / deploy notes.

- HTTPS redirect from HTTP
- Deny `.env`, `vendor`, private `storage`
- HSTS, `X-Content-Type-Options`, `X-Frame-Options`, Referrer-Policy
- `robots.txt` Disallow all for staging

---

## 6. Protected content verification

```bash
curl -I "https://{bunny-cdn}/lesson-files/..."   # unsigned → 403
curl -I "https://staging-api.example.com/storage/lesson-files/..."  # → 404/deny
php artisan files:audit-storage
php artisan files:audit-bunny-storage
```

---

## 7. Queue workers

Jobs: `UploadVideoToBunnyJob`, `SyncBunnyVideoStatusJob`, `UploadLessonFileToBunnyJob`.

Use systemd/supervisor — not a manual terminal `queue:work`.

---

## 8. Scheduler

| Command | Schedule |
|---------|----------|
| `platform:backup` | Daily 02:00 |
| `platform:prune-audit-logs` | Daily 03:00 |

---

## 9. Health checks

| Endpoint | Purpose |
|----------|---------|
| `GET /up` | Laravel liveness |
| `GET /health` | DB + cache + queue driver (no secrets) |

---

## 10. Flutter staging builds

```bash
cp tool/staging_defines.json.example tool/staging_defines.json
./tool/build_staging_android.sh
./tool/build_staging_ios.sh
```

Release builds require HTTPS `API_BASE_URL` (see `ReleaseEnvironmentGuard`).

---

## 11. Deployment runbook

1. Backup DB
2. `php artisan down` (optional)
3. Pull artifact / tag
4. `composer install --no-dev --optimize-autoloader`
5. `php artisan migrate --force`
6. Cache config/routes/views
7. Restart queue + PHP-FPM
8. `curl -f https://staging-api.example.com/health`
9. Smoke tests
10. `php artisan up`

Never `composer update` on deploy.

---

## 12. Backup & restore drill

- Daily scheduler backup + manual pre-deploy
- Retention: 14 days
- **Restore drill required:** restore to temp DB, verify Laravel reads it, then drop temp DB

---

## 13. Rollback

- Code: redeploy previous tag
- Migration: rollback if reversible; else DB restore
- Always backup before migrate

---

## 14. PHPStan decision

**DEFER POST-STAGING** — add gradual Larastan baseline after E2E PASS.

---

## 15. Composer advisories

See `security/controls/advisory-exceptions.yaml`. All 3 valid until **2026-12-31**.

Run: `./security/scripts/check-advisory-exceptions.sh`

---

## Related

- [staging-e2e-matrix.md](./staging-e2e-matrix.md)
- [../backend/.env.staging.example](../backend/.env.staging.example)
- [../security/threat-model/staging-dynamic-scan.md](../security/threat-model/staging-dynamic-scan.md)

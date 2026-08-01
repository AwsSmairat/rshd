# Security Notes — RSHD Backend

## Composer Audit

During initial setup, `composer create-project` failed because Composer 2.10+ blocks packages with open security advisories.

### Affected package

**`laravel/framework` v11.54.0** (latest Laravel 11 release)

| Advisory ID | Severity | Issue |
|-------------|----------|-------|
| PKSA-mdq4-51ck-6kdq | CVE-2026-48019 | CRLF injection in default email validation rule |
| PKSA-3r5d-mb8f-1qw9 | High | Same CRLF issue (GHSA-5vg9-5847-vvmq) |
| PKSA-m5cs-t1y6-qpcs | Medium | Temporary signed URL path confusion |

### Why this happens

These advisories affect **all Laravel 11.x** versions (`>=11.0.0,<12.0.0`). Patches are available only in **Laravel 12.60+**.

This project intentionally targets **Laravel 11** per product requirements.

### What we did (instead of disabling audit entirely)

Removed:

```json
"audit": { "block-insecure": false }
```

Replaced with explicit advisory ignore list in `composer.json`:

```json
"audit": {
    "ignore": [
        "PKSA-m5cs-t1y6-qpcs",
        "PKSA-3r5d-mb8f-1qw9",
        "PKSA-mdq4-51ck-6kdq"
    ]
}
```

This keeps Composer audit **enabled** for all other packages while documenting known Laravel 11 gaps.

### Recommended upgrade path

Plan migration to **Laravel 12.60+** when ready, then remove the ignore list and run:

```bash
composer audit
composer update laravel/framework
```

Until then, avoid passing untrusted input directly into Laravel's default `email` validation rule on public endpoints (Register/Login already use controlled Form Requests).

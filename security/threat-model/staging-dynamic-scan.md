# Staging Dynamic Security Scan (OWASP ZAP)

**STAGING ONLY — never run against production or real user data.**

## Prerequisites

- Staging API base URL (env `RSHD_STAGING_API_URL`)
- Test student account credentials (env, not committed)
- OpenAPI spec if available (`storage/api-docs/openapi.yaml` — generate if missing)

## Passive scan (CI-safe)

```bash
docker run -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
  -t "${RSHD_STAGING_API_URL}/up" \
  -r security/reports/zap-baseline.html
```

## API scan (staging, authenticated)

1. Import OpenAPI into ZAP
2. Configure Bearer token from test login
3. Run **passive** scan on authenticated traffic first
4. Active scan only on staging with test data; exclude destructive routes (`DELETE`, webhooks)

## Exclusions

- Production Bunny CDN/stream
- Real student PII
- File upload fuzzing against production storage

## Schedule

- Weekly on staging (see `.github/workflows/security-gate.yml` manual workflow)

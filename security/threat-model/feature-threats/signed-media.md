# Signed Files / Video — Feature Threats

## Assets
- Paid PDFs, videos, annotations, progress

## Threats (STRIDE)

| Threat | Scenario | Current control | Gap |
|--------|----------|-----------------|-----|
| Spoofing | Attacker replays old signed URL after expiry | TTL + token expiry | Client must not cache URL past TTL |
| Tampering | Change `fileId` in annotation POST | LessonFilePolicy | No dedicated annotation IDOR test |
| Repudiation | Deny submitting assignment | Submission timestamps | Audit logging partial |
| Info disclosure | Permanent CDN URL in API | Resource filtering | Model accessor still builds public URL |
| DoS | Request thousands of signed URLs | Partial rate limits | No per-user download rate limit |
| Elevation | Access course B with course A enrollment | EnrollmentService | Matrix tests incomplete |

## Preventive controls
- Semgrep RSHD-LARAVEL-002, RSHD-LARAVEL-004
- VideoPlaybackTest, LessonFileDownloadTest
- feature-security-contract.yaml entries VIDEO-*, FILE-*

## Detect
- LessonFileStorageAuditService, VideoStorageAuditService
- full-audit.sh contract coverage check

## Respond
- Revoke enrollment, invalidate tokens on account block

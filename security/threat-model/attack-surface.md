# Attack Surface Map

## External (Internet-facing)

| Surface | Endpoints | Auth | Priority |
|---------|-----------|------|----------|
| Public API | `/api/v1/settings/public`, `/legal/*` | None | LOW |
| Auth API | login, register, OAuth, password, email verify | None | CRITICAL |
| Protected API | 40+ sanctum routes | Bearer token | CRITICAL |
| Media stream | `/videos/{id}/stream`, `/files/{id}/stream` | Token/signed | CRITICAL |
| Webhook | `/webhooks/bunny/stream` | HMAC | HIGH |
| Filament | `/admin/*` | Session | CRITICAL |
| Health | `/up` | None | LOW |

## Client attack surface (Flutter)

| Surface | Risk |
|---------|------|
| Secure storage | Token extraction on rooted device |
| PDF offline cache | Physical device access |
| Screen capture | iOS screenshot not blockable |
| WebView embed player | JS bridge, URL injection if misconfigured |
| Deep links / GoRouter | Open redirect if added later |
| Share sheet (PDF export) | User-initiated data exfiltration (intended) |
| Remember-me password | Local credential storage |

## Admin / Filament

- 19 Filament resources with CRUD
- Bulk actions, file uploads (LessonFile, Video)
- Instructor scope vs admin scope

## Background / async

- `UploadVideoToBunnyJob`
- Queue workers with storage access
- Scheduled audit/repair commands

## Third-party

- Bunny Stream API
- Bunny Storage API
- Google/Apple OAuth token verification
- SMTP (password reset emails)

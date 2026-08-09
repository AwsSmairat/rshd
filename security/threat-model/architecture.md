# RSHD Architecture Overview (Threat Model Input)

## Components

```
[Flutter Student App] --HTTPS/Sanctum--> [Laravel API]
                                              |
                    +-------------------------+-------------------------+
                    |                         |                         |
              [MySQL DB]              [Bunny Stream]            [Bunny Storage/CDN]
                    |
              [Filament Admin] --session--> [Laravel Web]
```

## Trust boundaries

1. **Internet → API**: Untrusted input; Sanctum auth after login
2. **API → Bunny**: Server-side secrets; signed URLs to client
3. **Client → CDN**: Short-lived signed URLs only for media
4. **Client local storage**: OS sandbox; PDF cache unencrypted
5. **Filament → Admin**: Session + role; CSRF protected
6. **Bunny → Webhook**: HMAC verified

## Data classification

| Class | Examples | Controls |
|-------|----------|----------|
| Secret | Bunny keys, APP_KEY | env only, never client/logs |
| Auth | Sanctum tokens | secure storage, HTTPS |
| Paid content | Video, PDF | enrollment + signed URL + screen protection |
| PII | email, phone, name | minimize API output |
| Operational | progress, annotations | ownership checks |

## Key flows

- **Video**: auth → policy → signed playback URL → CDN → player (TTL refresh)
- **PDF**: auth → policy → signed download → cache → viewer (protected route)
- **Enrollment**: SubjectStudent status gates policy checks

See `trust-boundaries.md`, `attack-surface.md`, `risk-register.md`.

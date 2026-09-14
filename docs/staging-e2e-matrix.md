# RSHD Staging E2E Validation Matrix

Mark each cell **PASS / FAIL / NOT RUN** during staging validation.

| Feature | BT | FT | SM | RD | SEC |
|---------|----|----|----|----|-----|
| Auth — login | PASS | PASS | PASS | | |
| Auth — register + verify | | | | | |
| Auth — forgot/reset password | | | | | |
| Auth — logout | | | | | |
| Subjects — catalog / enroll | | | | | |
| Lessons — list / locked preview | | | | | |
| Videos — signed playback | | | | | |
| Videos — screen protection | | | | | |
| PDF — signed download / cache | | | | | |
| PDF — annotations / export | | | | | |
| Quiz / Assignments / Grades | | | | | |
| Notifications / navigation | | | | | |
| Filament — admin / instructor scope | | | | | |
| Filament — Bunny upload jobs | | | | | |
| Startup splash → home | | | | | |

**BT** = backend test, **FT** = Flutter test, **SM** = staging manual HTTPS, **RD** = real device, **SEC** = security curl/audit.

## Actors (`StagingDataSeeder`)

| Role | Email |
|------|-------|
| Admin | `admin@staging.rshd.test` |
| Instructor | `instructor@staging.rshd.test` |
| Other instructor | `instructor-other@staging.rshd.test` |
| Active student | `student-active@staging.rshd.test` |
| Pending | `student-pending@staging.rshd.test` |
| Expired | `student-expired@staging.rshd.test` |
| Blocked | `student-blocked@staging.rshd.test` |
| Non-enrolled | `student-guest@staging.rshd.test` |

Password: `STAGING_SEED_PASSWORD` on server only.

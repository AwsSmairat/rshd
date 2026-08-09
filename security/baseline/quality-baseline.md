# RSHD Quality Baseline

Established: 2026-08-10 (gate system bootstrap)

## Laravel

| Gate | Tool | Baseline expectation |
|------|------|---------------------|
| Tests | `php artisan test` | All non-smoke tests pass |
| Style | `vendor/bin/pint --test` | Clean (may WARN during transition) |
| Composer | `composer validate` + `composer audit` | Valid; track advisories |
| Static analysis | PHPStan/Larastan | Not yet configured |

## Flutter

| Gate | Tool | Baseline expectation |
|------|------|---------------------|
| Analyze | `flutter analyze` | Zero errors; warnings tracked |
| Tests | `flutter test` | All unit/widget tests pass |
| Integration | `integration_test/` | Not present — device smoke manual |

## Known baseline failures (2026-08-10)

1. `Tests\Feature\ExampleTest` — expects 200 on `/`, app redirects to `/admin` (302)
2. `test/widget_test.dart` — expects "RSHD" text not present in current UI
3. Pint — style drift across ~45 backend files
4. `flutter analyze` — 24 info/warning issues (non-blocking WARN)

## Quality score formula (gate script)

- Start at 100
- −25 per failing test suite (Laravel or Flutter)
- −10 Pint fail
- −5 flutter analyze errors
- −1 per 5 analyzer warnings (cap −10)

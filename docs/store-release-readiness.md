# Store Release Readiness Inventory

**Date:** 2026-08-24  
**Scope:** Checklist only. Do **not** submit to Apple or Google. Do **not** create signing keys, certificates, or provisioning profiles in this repository.

Current app identity in the repo:

| Item | Value | Note |
|------|-------|------|
| Flutter version | `1.0.0+1` | Recommended first store version unless stores reject `com.example.*` |
| Android `applicationId` | `com.example.rshd` | Must change before Play production |
| iOS bundle ID | `com.example.rshd` | Must change before App Store; keep in sync with Android |
| Display name | `RSHD` | Android label + iOS `CFBundleDisplayName` / `CFBundleName` |
| Release signing (Android) | Debug keys in `android/app/build.gradle.kts` | Intentional local/dev path. `key.properties` is gitignored. No production keystore is committed. |

Legend:

- **READY** — present in the repo or already configured for a private staging build
- **NEEDS ACCOUNT** — requires an Apple / Google operator account action
- **NEEDS STAGING URL** — needs the real HTTPS staging (or production) host
- **NEEDS MANUAL ACTION** — human/content/console work, not a code blocker for staging
- **BLOCKED** — cannot ship to that store as-is

---

## Apple App Store / TestFlight

| Item | Status | Notes |
|------|--------|-------|
| Developer account | NEEDS ACCOUNT | Apple Developer Program membership is outside this repo |
| Bundle ID | BLOCKED | Still `com.example.rshd`. Register a real ID (example: `com.rshd.academy`) in Apple Developer + Xcode before store submit. Do not change it casually: Google OAuth iOS client and URL scheme must match |
| Signing certificate | NEEDS ACCOUNT | Do not create or commit certificates here |
| Provisioning | NEEDS ACCOUNT | Development / App Store / TestFlight profiles |
| TestFlight | NEEDS ACCOUNT | After a signed archive, not `--no-codesign` |
| Privacy policy URL | NEEDS STAGING URL | In-app privacy exists (`/privacy-policy` + `GET /api/v1/legal/privacy-policy`). Stores need a public HTTPS URL |
| Support URL | NEEDS MANUAL ACTION | No store-facing support URL is published yet |
| Screenshots | NEEDS MANUAL ACTION | Capture on real iPhone / iPad after staging API |
| App description | NEEDS MANUAL ACTION | Marketing copy not in this repo |
| Age rating | NEEDS MANUAL ACTION | Education / medical-training content; complete App Store questionnaire |
| App Privacy answers | NEEDS MANUAL ACTION | Account, contact, identifiers, photos (avatar). `ios/Runner/PrivacyInfo.xcprivacy` covers UserDefaults + file timestamp APIs used by the app/plugins |
| Display name | READY | `RSHD` |
| Version / build | READY | `CFBundleShortVersionString` / `CFBundleVersion` from Flutter `1.0.0+1` |
| Deployment target | READY | iOS 13.0 |
| ATS | READY | No arbitrary cleartext exceptions. `NSAllowsLocalNetworking=true` is for local debug; release Dart still requires HTTPS `API_BASE_URL` |
| Usage strings | READY | Camera + photo library descriptions added for avatar picker |
| URL schemes / OAuth | NEEDS MANUAL ACTION | `CFBundleURLTypes` uses `$(GOOGLE_IOS_REVERSED_CLIENT_ID)` from gitignored `OAuth.xcconfig`. Fill staging/production clients via `./tool/sync_oauth_config.sh` |
| Launch screen | READY | `LaunchScreen.storyboard` + `LaunchImage` |
| App icon | READY | `AppIcon.appiconset` including 1024 marketing icon |
| Screen capture privacy | READY | `ScreenProtectionPlugin` remains in the iOS target |
| Production API guard | READY | Release builds refuse empty/cleartext/localhost/emulator hosts. Staging HTTPS URLs are allowed for internal QA. Store production binaries must use the production host, not a hostname containing `staging` |

**Apple overall:** PARTIAL (repo/app config is close; account, bundle ID, signing, hosted legal URL, and store listing block submission).

---

## Google Play

| Item | Status | Notes |
|------|--------|-------|
| Play Console | NEEDS ACCOUNT | Organization Play account |
| Package name | BLOCKED | `com.example.rshd` is not acceptable for production Play listing. Change with iOS in one coordinated release |
| Signing | NEEDS MANUAL ACTION | Release builds currently use the debug signing config so `flutter build apk --release` works locally. Production must use Play App Signing + an upload keystore **not** committed to git |
| AAB | NEEDS MANUAL ACTION | Build with production signing + `--dart-define=API_BASE_URL=https://…`. Unsigned/debug-signed AAB must not be shipped to production |
| Internal Testing | NEEDS ACCOUNT | After a signed AAB |
| Screenshots | NEEDS MANUAL ACTION | Phone (and tablet if serving tablets) |
| Descriptions | NEEDS MANUAL ACTION | Short/full listing, Arabic + optional English |
| Privacy policy | NEEDS STAGING URL | Same public HTTPS URL as Apple |
| Data Safety | NEEDS MANUAL ACTION | Account info, email, photos (avatar), device ID, crash/network. PDF cache is on-device, not Play backup (backup rules exclude it) |
| Content rating | NEEDS MANUAL ACTION | IARC questionnaire |
| INTERNET permission | READY | Only app permission in main manifest |
| Cleartext | READY | `usesCleartextTraffic` is debug-only |
| Exported components | READY | Launcher `MainActivity` exported; no extra exported services/receivers in app manifest |
| FLAG_SECURE | READY | `MainActivity` still applies it for protected content |
| Adaptive icon | READY | `mipmap-anydpi-v26/ic_launcher.xml` + launcher icons config |
| ProGuard/R8 | READY | Not enabled (`minify` unset). Acceptable for first staging; enable later with a keep-rules pass |
| App display name | READY | `RSHD` |

**Google overall:** PARTIAL (same blockers: example package name, production signing, Play account, listing assets).

---

## Shared store blockers (not staging code blockers)

1. Replace `com.example.rshd` on Android **and** iOS together, then update Google/Apple OAuth clients.
2. Host a public privacy policy + support URL on the staging/production domain.
3. Create upload keystore / Apple signing **outside** git.
4. Build release with `--dart-define=API_BASE_URL=https://<real-host>/api/v1` (never localhost / `10.0.2.2`). Production store binaries must not use a staging hostname.
5. Capture screenshots and complete store questionnaires.

Staging device installs may keep `com.example.rshd` and debug-compatible signing. Store submission may not.

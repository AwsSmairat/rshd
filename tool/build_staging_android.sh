#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFINES="${ROOT}/tool/staging_defines.json"

if [[ ! -f "${DEFINES}" ]]; then
  echo "Missing ${DEFINES}. Copy from tool/staging_defines.json.example and set HTTPS API_BASE_URL."
  exit 1
fi

cd "${ROOT}"
flutter build apk --release --dart-define-from-file="${DEFINES}"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"

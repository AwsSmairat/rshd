#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFINES="${ROOT}/tool/staging_defines.json"

if [[ ! -f "${DEFINES}" ]]; then
  echo "Missing ${DEFINES}. Copy from tool/staging_defines.json.example and set HTTPS API_BASE_URL."
  exit 1
fi

cd "${ROOT}"
flutter build ios --release --dart-define-from-file="${DEFINES}"
echo "iOS release build complete. Install via Xcode or TestFlight internal testing."

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEFINES=()
if [[ -f oauth_defines.json ]]; then
  if ./tool/sync_oauth_config.sh; then
    DEFINES=(--dart-define-from-file=oauth_defines.json)
    echo "Using oauth_defines.json for Google Sign-In."
  else
    echo "Google Sign-In disabled until oauth_defines.json has real client IDs." >&2
  fi
else
  echo "Tip: copy oauth_defines.json.example to oauth_defines.json for Google Sign-In."
fi

exec flutter run "${DEFINES[@]}" "$@"

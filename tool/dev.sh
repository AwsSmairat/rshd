#!/usr/bin/env bash
# Runs the redesigned app on the booted iOS simulator, with hot reload, against
# the backend of your choice.
#
#   ./tool/dev.sh                          # local backend (default)
#   ./tool/dev.sh --target=staging         # staging.rshdacademy.com
#   ./tool/dev.sh --target=production      # api.rshdacademy.com — REAL DATA
#   ./tool/dev.sh --route=/register        # open straight on a given screen
#
# Targets:
#   local       http://127.0.0.1:8765 — Laravel from the main checkout. Start it
#               first in its own terminal and leave it running:
#                 bash /Users/dollar/Dev/rshd/backend/serve.sh
#               Mail is written to the log; read codes with ./tool/last_code.sh.
#   staging     Separate server (62.238.115.76). Safe for destructive testing.
#   production  rshd-production on Hetzner (157.180.124.11), shared with the
#               website. Real users, real email, real device binding.
#
# While it runs: r = hot reload, R = hot restart, q = quit.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TARGET="local"
PASSTHROUGH=()
for arg in "$@"; do
  case "$arg" in
    --target=*) TARGET="${arg#--target=}" ;;
    *) PASSTHROUGH+=("$arg") ;;
  esac
done

DEFINES=()
case "$TARGET" in
  local)
    API="http://127.0.0.1:8765"
    # Debug builds already default to this host, so no define is needed.
    ;;
  staging)
    API="https://staging.rshdacademy.com"
    DEFINES=(--dart-define=API_BASE_URL="$API/api/v1")
    ;;
  production)
    API="https://api.rshdacademy.com"
    DEFINES=(--dart-define=API_BASE_URL="$API/api/v1")
    ;;
  *)
    echo "Unknown --target=$TARGET (use local, staging or production)." >&2
    exit 2
    ;;
esac

if ! curl -s -o /dev/null -m 8 "$API/api/v1/settings/public"; then
  if [[ "$TARGET" == local ]]; then
    cat >&2 <<EOF
The local backend is not answering on $API.
Start it in another terminal and keep it running:

  bash /Users/dollar/Dev/rshd/backend/serve.sh
EOF
  else
    echo "$TARGET backend is not answering on $API." >&2
  fi
  exit 1
fi
echo "Backend ($TARGET) is up on $API."

if [[ "$TARGET" == production ]]; then
  cat <<'EOF'

  ┌─────────────────────────────────────────────────────────────────┐
  │  PRODUCTION — everything you do here is real:                   │
  │   • accounts you create are real users on rshdacademy.com       │
  │   • verification / reset codes go to the real inbox            │
  │   • signing in binds that account to this simulator's device    │
  │  Use a dedicated test account, never a real student's.          │
  └─────────────────────────────────────────────────────────────────┘

EOF
fi

DEVICE="$(xcrun simctl list devices booted 2>/dev/null \
  | grep -oE '\(([0-9A-F-]{36})\) \(Booted\)' | head -1 | grep -oE '[0-9A-F-]{36}' || true)"
if [[ -z "$DEVICE" ]]; then
  echo "No booted iOS simulator. Boot one, e.g.: xcrun simctl boot 'iPhone 17 Pro Max'" >&2
  exit 1
fi

# The debug app opens on onboarding until it has been completed once; default
# to the sign-in screen so a fresh simulator is immediately testable.
ROUTE_ARGS=(--route=/login)
for arg in ${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}; do
  [[ "$arg" == --route=* ]] && ROUTE_ARGS=()
done

# CocoaPods 1.16 crashes under Ruby 4 unless the locale is UTF-8.
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# The ${a[@]+...} form keeps bash 3.2 (macOS /bin/bash) happy under `set -u`
# when an array is empty.
exec flutter run -d "$DEVICE" \
  ${DEFINES[@]+"${DEFINES[@]}"} \
  ${ROUTE_ARGS[@]+"${ROUTE_ARGS[@]}"} \
  ${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}

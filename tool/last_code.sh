#!/usr/bin/env bash
# Prints the most recent email-verification or password-reset code.
#
# Locally the backend runs with MAIL_MAILER=log, so no email is actually sent:
# the rendered message lands in storage/logs/laravel.log instead. The codes are
# stored hashed in the database, so the log is the only place to read them.
#
# Usage:
#   ./tool/last_code.sh            # latest code of either kind
#   ./tool/last_code.sh verify     # latest email-verification code
#   ./tool/last_code.sh reset      # latest password-reset code
#
# Override the backend location with RSHD_BACKEND=/path/to/backend.
set -euo pipefail

BACKEND="${RSHD_BACKEND:-/Users/dollar/Dev/rshd/backend}"
LOG="$BACKEND/storage/logs/laravel.log"

if [[ ! -f "$LOG" ]]; then
  echo "No mail log at $LOG — is the backend running with MAIL_MAILER=log?" >&2
  exit 1
fi

case "${1:-any}" in
  verify) MARKER='رمز تأكيد البريد' ;;
  reset)  MARKER='رمز استعادة كلمة المرور' ;;
  any)    MARKER='رمز تأكيد البريد|رمز استعادة كلمة المرور' ;;
  *) echo "Usage: $0 [verify|reset]" >&2; exit 2 ;;
esac

# Line number of the last matching message's subject.
START="$(grep -nE "$MARKER" "$LOG" | tail -1 | cut -d: -f1 || true)"
if [[ -z "$START" ]]; then
  echo "No ${1:-verification or reset} email found in the log yet." >&2
  exit 1
fi

# The template renders the code on a line of its own; take the first one after
# the subject.
CODE="$(tail -n "+$START" "$LOG" | grep -oE '^[[:space:]]*[0-9]{6}[[:space:]]*$' | head -1 | tr -d '[:space:]')"
if [[ -z "$CODE" ]]; then
  echo "Found the email but could not read a 6-digit code from it." >&2
  exit 1
fi

echo "$CODE"

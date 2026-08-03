#!/usr/bin/env bash
# Keeps rolling SQLite backups before server start (last 5).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DB="${ROOT}/database/database.sqlite"
BACKUP_DIR="${ROOT}/database/backups"

if [[ ! -f "$DB" ]]; then
  exit 0
fi

mkdir -p "$BACKUP_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
cp "$DB" "${BACKUP_DIR}/database-${STAMP}.sqlite"

# Drop oldest backups beyond 5.
ls -1t "${BACKUP_DIR}"/database-*.sqlite 2>/dev/null | tail -n +6 | xargs -r rm -f

echo "SQLite backup saved: database/backups/database-${STAMP}.sqlite"

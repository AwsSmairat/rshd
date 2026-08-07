#!/usr/bin/env bash
# Restart Laravel with upload limits suitable for large lesson videos (up to ~10GB).
# Use a single worker with SQLite so edits/deletes persist reliably.
cd "$(dirname "$0")"
export PHP_CLI_SERVER_WORKERS=1

DB_FILE="database/database.sqlite"
if [[ -f "$DB_FILE" ]]; then
  bash scripts/backup-sqlite.sh 2>/dev/null || true
  sqlite3 "$DB_FILE" "PRAGMA wal_checkpoint(TRUNCATE);" 2>/dev/null || true
fi

PORT="${1:-8765}"
EXISTING_PID="$(lsof -ti "tcp:${PORT}" -sTCP:LISTEN 2>/dev/null || true)"
if [[ -n "$EXISTING_PID" ]]; then
  echo "Stopping existing server on port ${PORT} (PID ${EXISTING_PID})..."
  kill "$EXISTING_PID" 2>/dev/null || true
  sleep 1
fi

QUEUE_PID_FILE="storage/framework/queue-worker.pid"
QUEUE_LOG="storage/logs/queue-worker.log"
mkdir -p storage/logs storage/framework

if [[ -f "$QUEUE_PID_FILE" ]]; then
  OLD_QUEUE_PID="$(cat "$QUEUE_PID_FILE" 2>/dev/null || true)"
  if [[ -n "$OLD_QUEUE_PID" ]]; then
    kill "$OLD_QUEUE_PID" 2>/dev/null || true
  fi
fi

nohup php artisan queue:work database --sleep=3 --timeout=7200 --tries=3 >> "$QUEUE_LOG" 2>&1 &
echo "$!" > "$QUEUE_PID_FILE"
echo "Queue worker started (PID $(cat "$QUEUE_PID_FILE")). Logs: ${QUEUE_LOG}"

exec php \
  -c "$(dirname "$0")/php-upload.ini" \
  -d upload_max_filesize=10G \
  -d post_max_size=10G \
  -d memory_limit=1024M \
  -d max_execution_time=0 \
  -d max_input_time=0 \
  artisan serve --port="${PORT}" --host=127.0.0.1

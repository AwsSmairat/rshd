#!/usr/bin/env bash
# Restart Laravel with upload limits suitable for large lesson videos (up to ~10GB).
cd "$(dirname "$0")"
exec php \
  -d upload_max_filesize=10G \
  -d post_max_size=10G \
  -d memory_limit=1024M \
  -d max_execution_time=0 \
  -d max_input_time=0 \
  artisan serve --port="${1:-8765}" --host=127.0.0.1

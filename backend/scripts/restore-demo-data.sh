#!/usr/bin/env bash
# Rebuild local SQLite schema and restore demo content (subjects, lessons, etc.).
# Use when data disappeared after SQLite corruption/recovery.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Creating safety backup..."
bash scripts/backup-sqlite.sh

echo "Rebuilding database schema..."
php artisan migrate:fresh --force

echo "Seeding base accounts..."
php artisan db:seed --force

echo "Seeding demo content..."
php artisan db:seed --class=DemoDataSeeder --force

echo "Done. Demo logins:"
echo "  admin@rshdacademy.com / password"
echo "  student@rshdacademy.com / password"

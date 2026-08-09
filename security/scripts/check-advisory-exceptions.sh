#!/usr/bin/env bash
# Validates composer audit ignore list against advisory-exceptions.yaml
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXCEPTIONS="${ROOT}/security/controls/advisory-exceptions.yaml"
COMPOSER_JSON="${ROOT}/backend/composer.json"
TODAY=$(date -u +%Y-%m-%d)

if [[ ! -f "${EXCEPTIONS}" ]]; then
  echo "FAIL: missing ${EXCEPTIONS}"
  exit 1
fi

python3 - <<PY
import json, pathlib, re, sys
from datetime import date

root = pathlib.Path("${ROOT}")
exceptions_path = root / "security/controls/advisory-exceptions.yaml"
composer_path = root / "backend/composer.json"
today = date.fromisoformat("${TODAY}")

composer = json.loads(composer_path.read_text())
ignored = composer.get("config", {}).get("audit", {}).get("ignore", [])

text = exceptions_path.read_text()
blocks = re.split(r"\n\s*-\s+advisory_id:\s*", text)[1:]
documented = {}
for block in blocks:
    advisory_id = block.splitlines()[0].strip()
    until_match = re.search(r"approved_until:\s*(\S+)", block)
    reason_match = re.search(r"reason:\s*\|?\n", block)
    mitigation_match = re.search(r"mitigation:\s*\|?\n", block)
    documented[advisory_id] = {
        "approved_until": until_match.group(1) if until_match else None,
        "has_reason": bool(reason_match),
        "has_mitigation": bool(mitigation_match),
    }

errors = []
for item in ignored:
    if item not in documented:
        errors.append(f"composer ignore {item} has no advisory-exceptions.yaml entry")

for advisory_id, meta in documented.items():
    if advisory_id not in ignored:
        errors.append(f"documented exception {advisory_id} not in composer.json audit.ignore")
        continue
    if not meta["approved_until"]:
        errors.append(f"{advisory_id} missing approved_until")
        continue
    if not meta["has_reason"] or not meta["has_mitigation"]:
        errors.append(f"{advisory_id} missing reason or mitigation")
        continue
    if date.fromisoformat(meta["approved_until"]) < today:
        errors.append(f"{advisory_id} exception expired ({meta['approved_until']})")

if errors:
    for err in errors:
        print(f"FAIL: {err}")
    sys.exit(1)

print(f"PASS: composer advisory exceptions valid ({today.isoformat()})")
PY

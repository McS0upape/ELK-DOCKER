#!/usr/bin/env bash
set -euo pipefail

KIBANA_URL="${KIBANA_URL:-http://localhost:5601}"
NDJSON_PATH="${NDJSON_PATH:-$(cd "$(dirname "$0")/.." && pwd)/kibana/siem_security_dashboard.ndjson}"

curl -s -H "kbn-xsrf: true" \
  -F "file=@${NDJSON_PATH}" \
  "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" | cat

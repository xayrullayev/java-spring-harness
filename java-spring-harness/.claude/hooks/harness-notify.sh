#!/usr/bin/env bash
# Sends a hook status event to the local dashboard. Never fails the calling hook.
#   harness-notify.sh <task> <status>      status: working | done | error | blocked
# Endpoint override: HARNESS_NOTIFY_URL (default http://localhost:4477/api/hook); disable with HARNESS_NOTIFY=0
[ "${HARNESS_NOTIFY:-1}" = "1" ] || exit 0
url="${HARNESS_NOTIFY_URL:-http://localhost:4477/api/hook}"
agent="${HARNESS_AGENT_NAME:-java-harness}"
task="${1:-hook}"; status="${2:-working}"
payload="$(python3 -c 'import json,sys; print(json.dumps({"agent":sys.argv[1],"task":sys.argv[2],"status":sys.argv[3]}, ensure_ascii=False))' "$agent" "$task" "$status" 2>/dev/null)" || exit 0
command -v curl >/dev/null 2>&1 || exit 0
curl -s -o /dev/null --max-time 2 -X POST "$url" -H 'Content-Type: application/json' -d "$payload" >/dev/null 2>&1 || true
exit 0

#!/bin/bash
# Prints Claude quota windows as JSON (the same endpoint and credential Nibble
# uses). Output: {"limits":[{"kind":...,"percent":...,"resets_at":...},...]}
# Exit 3 = no credentials, 4 = fetch failed. Callers must treat any failure as
# "usage unknown" and fall back to time-based pacing - never retry in a loop.
set -uo pipefail

token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['claudeAiOauth']['accessToken'])" 2>/dev/null)
if [ -z "${token:-}" ]; then
  token=$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.claude/.credentials.json')))['claudeAiOauth']['accessToken'])" 2>/dev/null)
fi
if [ -z "${token:-}" ]; then
  echo '{"error":"no-credentials"}'
  exit 3
fi

curl -sf -m 15 https://api.anthropic.com/api/oauth/usage \
  -H "Authorization: Bearer $token" \
  -H "anthropic-beta: oauth-2025-04-20" \
  || { echo '{"error":"fetch-failed"}'; exit 4; }

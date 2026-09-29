#!/usr/bin/env bash
# Rep signal relay runner. Usage: bin/run.sh [--dry-run|--preview|--live]
# Locates today's inputs, renders the prompt, runs Claude Code headless, logs the result.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$HERE"

# shellcheck disable=SC1091
[ -f "$HERE/.env.local" ] && set -a && . "$HERE/.env.local" && set +a

MODE="${1:-${MODE:-live}}"
MODE="${MODE#--}"
case "$MODE" in dry-run|preview|live) ;; *) echo "mode must be dry-run, preview, or live (got: $MODE)"; exit 2;; esac

DATE="$(date +%Y-%m-%d)"
LOG="$HERE/logs/$DATE.log"
OUT="$HERE/out/$DATE.json"
STATE="$HERE/state/posted.jsonl"
UNIVERSE="$HERE/config/universe.local.json"
RULES="$HERE/config/rules.md"
mkdir -p "$HERE/logs" "$HERE/out" "$HERE/state"

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOG"; }

if [ -f "$HERE/state/PAUSE" ]; then log "paused (state/PAUSE exists), skipping"; exit 0; fi
if [ "$(date +%u)" -gt 5 ] && [ "$MODE" = "live" ]; then log "weekend, skipping"; exit 0; fi
if [ ! -f "$UNIVERSE" ]; then log "missing $UNIVERSE (copy config/universe.example.json and fill it in)"; exit 2; fi
if ! command -v claude >/dev/null 2>&1; then log "claude CLI not on PATH"; exit 2; fi
if [ "$MODE" != "dry-run" ]; then
  : "${SLACK_MCP_SERVER:?set SLACK_MCP_SERVER in .env.local (name from: claude mcp list)}"
  : "${CHANNEL_ID:?set CHANNEL_ID in .env.local}"
  : "${PREVIEW_CHANNEL_ID:?set PREVIEW_CHANNEL_ID in .env.local}"
fi
: "${LOOKUP_URL:=https://example.invalid/lookup/}"
: "${SEARCH_ROOTS:=$HOME/coordinator $HOME/Claude}"
: "${CLAUDE_MODEL:=}"
: "${MAX_TURNS:=80}"

# Find today's war room file and heat-list preview if the coordinator wrote them.
find_newest() {  # $1 = name pattern, $2 = iname (1/0)
  local pat="$1" flag="-name"; [ "${2:-0}" = "1" ] && flag="-iname"
  # shellcheck disable=SC2086
  { find $SEARCH_ROOTS $flag "$pat" -type f -mtime -1 2>/dev/null || true; } | sort | tail -1
}
WAR_ROOM="$(find_newest 'Daily_War_Room_*.md' 0)"; WAR_ROOM="${WAR_ROOM:-none}"
HEAT="$(find_newest '*heat*list*.json' 1)"; HEAT="${HEAT:-none}"
log "mode=$MODE war_room=$WAR_ROOM heat=$HEAT"

# Render the prompt (python so paths with odd characters survive).
PROMPT="$(python3 - "$HERE/prompts/relay.md" <<PY
import sys
t = open(sys.argv[1], encoding="utf-8").read()
subs = {
  "DATE": "$DATE", "MODE": "$MODE", "RULES_PATH": "$RULES", "UNIVERSE_PATH": "$UNIVERSE",
  "WAR_ROOM_PATH": "$WAR_ROOM", "HEAT_PATH": "$HEAT", "STATE_FILE": "$STATE", "OUT_FILE": "$OUT",
  "LOOKUP_URL": "$LOOKUP_URL", "CHANNEL_ID": "${CHANNEL_ID:-}", "PREVIEW_CHANNEL_ID": "${PREVIEW_CHANNEL_ID:-}",
  "SLACK_MCP_SERVER": "${SLACK_MCP_SERVER:-slack}",
}
for k, v in subs.items():
    t = t.replace("{{" + k + "}}", v)
print(t)
PY
)"

# File writes are auto-accepted only inside this folder (acceptEdits + cwd=$HERE); nothing else is writable.
ALLOWED="Read,Glob,Grep,WebSearch,WebFetch"
if [ -n "${SLACK_MCP_SERVER:-}" ]; then ALLOWED="$ALLOWED,mcp__${SLACK_MCP_SERVER}__slack_read_channel"; fi
if [ "$MODE" != "dry-run" ]; then ALLOWED="$ALLOWED,mcp__${SLACK_MCP_SERVER}__slack_send_message"; fi
MODEL_ARGS=(); [ -n "$CLAUDE_MODEL" ] && MODEL_ARGS=(--model "$CLAUDE_MODEL")

log "running claude (allowed: $ALLOWED)"
set +e
RESULT="$(claude -p "$PROMPT" --permission-mode acceptEdits --allowedTools "$ALLOWED" --max-turns "$MAX_TURNS" "${MODEL_ARGS[@]}" 2>>"$LOG")"
RC=$?
set -e
printf '%s\n' "$RESULT" >> "$LOG"
LAST="$(printf '%s\n' "$RESULT" | grep -E '^(POSTED|NO_POST|HELD|ERROR) ' | tail -1 || true)"
log "exit=$RC result=${LAST:-<no status line>}"
[ "$MODE" = "dry-run" ] && printf '\n----- dry-run output -----\n%s\n' "$RESULT"
[ -n "$LAST" ] || exit 1
exit "$RC"

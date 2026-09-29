#!/usr/bin/env bash
# One-time install on the owner's Mac: validates prerequisites, writes the launchd job.
# Usage: bin/install.sh [HH:MM]   (local time, weekdays; default 07:20)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$HERE"
AT="${1:-07:20}"; HOUR="${AT%%:*}"; MIN="${AT##*:}"
LABEL="com.dallasandrews.rep-signal-relay"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

ok(){ printf '  ok   %s\n' "$*"; }; warn(){ printf '  WARN %s\n' "$*"; }; fail(){ printf '  FAIL %s\n' "$*"; FAILED=1; }
FAILED=0
echo "Checking prerequisites"
command -v claude >/dev/null 2>&1 && ok "claude CLI: $(claude --version 2>/dev/null | head -1)" || fail "claude CLI not on PATH (npm i -g @anthropic-ai/claude-code)"
command -v python3 >/dev/null 2>&1 && ok "python3" || fail "python3 missing"
[ -f .env.local ] && ok ".env.local present" || fail ".env.local missing"
[ -f config/universe.local.json ] && python3 -c 'import json,sys; json.load(open("config/universe.local.json"))' && ok "config/universe.local.json parses" || fail "config/universe.local.json missing or invalid JSON"
# shellcheck disable=SC1091
[ -f .env.local ] && set -a && . ./.env.local && set +a
if command -v claude >/dev/null 2>&1; then
  if claude mcp list 2>/dev/null | grep -qi "^${SLACK_MCP_SERVER:-slack}[[:space:]:]"; then ok "Slack MCP server '${SLACK_MCP_SERVER:-slack}' registered"
  else warn "no MCP server named '${SLACK_MCP_SERVER:-slack}' in 'claude mcp list'. Register it (claude mcp add --transport http slack https://mcp.slack.com/mcp) or set SLACK_MCP_SERVER in .env.local to the name shown there."; fi
fi
mkdir -p state out logs
[ "$FAILED" = 0 ] || { echo "Fix the FAIL lines above, then rerun."; exit 1; }

echo "Writing $PLIST (weekdays $AT local time)"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$HERE/bin/run.sh</string><string>--live</string></array>
  <key>WorkingDirectory</key><string>$HERE</string>
  <key>EnvironmentVariables</key><dict><key>PATH</key><string>$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string><key>HOME</key><string>$HOME</string></dict>
  <key>StartCalendarInterval</key><array>
    <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>$MIN</integer></dict>
    <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>$MIN</integer></dict>
    <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>$MIN</integer></dict>
    <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>$MIN</integer></dict>
    <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>$MIN</integer></dict>
  </array>
  <key>StandardOutPath</key><string>$HERE/logs/launchd.out</string>
  <key>StandardErrorPath</key><string>$HERE/logs/launchd.err</string>
  <key>RunAtLoad</key><false/>
</dict></plist>
PL
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1 && ok "launchd job loaded: $LABEL" || fail "launchd job did not load; try: launchctl load $PLIST"
echo "Done. Pause any time with: touch $HERE/state/PAUSE   (rm it to resume)"

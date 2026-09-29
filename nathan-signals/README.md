# Rep signal relay

Posts at most one verified account signal per business day into a rep's outbound Slack
channel, in the same shape as the partner-channel signal posts (what happened, source and
date, why it matters, what to do today, a paste-ready line, links). Most days it posts
nothing. It runs headless through Claude Code on the owner's Mac via launchd.

```
nathan-signals/
  bin/run.sh                 run once: --dry-run | --preview | --live
  bin/install.sh             validate prerequisites, install the weekday launchd job
  prompts/relay.md           the headless prompt (placeholders filled by run.sh)
  config/rules.md            what qualifies, freshness, customer gate, format, volume
  config/universe.example.json   schema example; the real one is universe.local.json (gitignored)
  state/posted.jsonl         dedupe log (21-day window); touch state/PAUSE to stop
  out/YYYY-MM-DD.json        the day's decision, message, skipped and held lists
  logs/                      run logs
```

## How a run works

1. `run.sh` finds today's war room file and heat-list preview under `SEARCH_ROOTS` if the
   coordinator wrote them, renders the prompt, and calls `claude -p` with a tight tool
   allowlist (read, web search and fetch, write to `out/` and `state/`, Slack read, and
   Slack send only outside dry-run).
2. The prompt reads the universe, the rules, the state log, and the channel's last 7 days,
   takes war room and heat-list items as candidates, sweeps the web itself only if those
   produce nothing, verifies the primary source, applies the gates, and picks one or none.
3. It writes `out/<date>.json`, appends the fingerprint to `state/posted.jsonl`, and then:
   dry-run prints; preview sends to the owner's DM; live sends to the rep channel.
4. Customer accounts without `ae_cleared: true` never reach the rep channel. The message is
   still written and goes to the owner's DM as held, so nothing worth knowing is lost.
5. Fridays: a two-line tally to the owner (posted, no-post days, held).

## Modes

- `bin/run.sh --dry-run` prints the decision and message, sends nothing. Safe anywhere.
- `bin/run.sh --preview` sends to the owner's DM only. Use for the first week.
- `bin/run.sh --live` sends to the rep channel. What launchd runs.

## Configuration (`.env.local`, gitignored)

```
SLACK_MCP_SERVER=slack            # name from `claude mcp list`
CHANNEL_ID=C...                   # rep channel
PREVIEW_CHANNEL_ID=U...           # owner's own user id (DM)
LOOKUP_URL=https://.../lookup/    # account lookup page linked in every post
SEARCH_ROOTS="$HOME/coordinator $HOME/Claude"   # where war room / heat-list files live
CLAUDE_MODEL=                     # blank = CLI default
MAX_TURNS=80
```

## Guardrails that are structural, not advisory

- Only accounts in `universe.local.json` can post. Everything else is held and logged.
- Freshness is on the event date, not the article date.
- No fetchable primary source, no post.
- Customer accounts need `ae_cleared: true` on an install-base lane to reach the rep.
- One post a day, 21-day dedupe, channel history checked so it never re-raises what people
  already discussed.
- `touch state/PAUSE` stops it; `rm state/PAUSE` resumes.

The universe file and `.env.local` hold account and customer names and stay off git.

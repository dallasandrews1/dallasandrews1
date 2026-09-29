# Pre-mortem: rep signal relay, 6 weeks out

Written before the first live post, against the design as shipped. The fixes listed under
each failure are already in the prompt, rules, and runner.

## Failure #1 (highest probability): the post became wallpaper

The rep channel already carries five to ten relay messages a day: bounces, LinkedIn accepts,
ride-along counts, the morning call list. The signal post landed between a bounce and a
ride-along, in the same "Sent using Claude" voice, and asked the rep to go do something on
top of a task backlog already past a hundred items. By week three not one post had a reply,
and the owner couldn't tell whether the signals were bad or just unread.

Defense in the original plan: one post a day, a distinct header, a "not a fit" reply line.
Why it wouldn't hold: the cap doesn't fix placement, and a reply line that only asks for
negative feedback makes silence uninformative.
Fixes shipped: a paste-ready sentence in every post so the signal hands over the work
instead of creating it; a one-tap check-mark ask so there's a positive count; a Friday tally
to the owner so two silent posts in a row is visible as the tell.

## Failure #2: a customer got cold-touched

The universe file's `status` flags were seeded from campaign names on day one and never
checked against the rep's exclusion list. A customer signal posted through an install-base
lane with an advisory "loop in the AE" line, the rep skimmed past the line, and the account
executive heard about it from the customer.

Defense in the original plan: the customer gate, as text in the post.
Why it wouldn't hold: a warning line in a busy channel isn't a gate.
Fixes shipped: customer accounts reach the rep channel only with `ae_cleared: true` set by
the owner per account. Anything else routes to the owner's DM as held, message included.
The seed file ships with every install-base account uncleared.

## Failure #3: a two-week-old story posted as news

The relay treated the war room's items as pre-verified. One of them was stale (the upstream
pipeline has served stale data before). A fresh article re-reporting the old event passed a
freshness check measured on article date, and the rep answered "we talked about this two
weeks ago."

Defense in the original plan: freshness plus source fetch.
Why it wouldn't hold: re-reporting defeats article-date freshness, and trusting upstream
skips the fetch.
Fixes shipped: freshness on the event date; war room and heat-list items get the same
verification as the relay's own sweep; the relay reads the channel's last 7 days and skips
anything already discussed; fingerprints use the event date.

## Red team, the one the owner is closest to and least likely to see

There are now three paths that can put an account signal in front of this rep: the heat
list's rep alerts (built, sitting in dry-run), the war room's Priority 1 hand-offs through
the copy skills, and this relay. If the heat list flips live without a routing decision, the
rep gets two touches on the same account in one morning. This relay should be the single
Slack egress for signals to this rep. Either keep the heat list's rep alerts in dry-run, or
point its preview file at this relay's `HEAT_PATH` so it becomes an input, not a poster.
The tell: the same account named in two bot posts on the same day.

## Verdict

Outside the owner's control: the rep's send capacity and task backlog. A signal competes
with a queue the rep can't clear. The adaptation is already in the format: the post carries
the sentence, not a to-do.

If you do nothing else: before flipping to live, spend ten minutes checking the `status`
and `ae_cleared` flags in `universe.local.json` against the rep's exclusion list. Every
other gate depends on those flags being right.

Confidence: moderate. The gates are structural and the format hands over work instead of
creating it, but whether the rep acts on a post is a habit that takes a few clean weeks to
form, and the first stale or off-limits post would reset it.

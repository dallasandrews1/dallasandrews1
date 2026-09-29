# Signal rules for the rep channel relay

The relay posts at most one account signal per business day to a rep's outbound channel.
Most days it posts nothing. Silence is the expected outcome, not a failure.

## 1. Eligibility

An account is eligible only if it appears in `config/universe.local.json`. Nothing else is
ever posted, however good the news. Accounts marked `owned_elsewhere` or `suppressed` are
never posted; log them as HELD so the owner can see what was skipped.

## 2. Signal types that qualify

Post-worthy (Priority 1 or 2 in the war room taxonomy):

- Executive change in operations, customer care, claims, shared services, quality, Stars,
  Medicare, or finance: CEO, COO, CFO, CAO, CIO, or a new SVP/VP in those functions.
- Earnings or guidance language about MA margins, Star Ratings or QBP revenue, admin cost,
  service cost, or an explicit expense mandate.
- Layoffs or a WARN notice touching service, claims, or back-office functions.
- M&A, affiliation, or a large contract award with obvious integration or surge burden.
- BPO award, renewal, or repatriation.
- Public outage, complaint spike, regulator action, or audit finding tied to service.
- A dated event inside 30 days: member letters, system cutover, open enrollment surge,
  plan exit, benefit change.
- WFM, ACD, or CCaaS platform move (Verint, NICE, Calabrio, Genesys, Amazon Connect, Five9).
  Frame as "we act on top of the stack they just bought", never as a blocker.

Never post: analyst chatter, generic AI announcements, brand or marketing news, hiring of a
single IC, anything with no operational consequence for a contact center or back office.

## 3. Freshness

Freshness is measured on the event date (when it happened or was announced), never on the
article date. Re-reporting of a two-week-old event is not fresh. The event must sit within
the last 5 business days, or be a dated future event within 30 days. Older items do not
post, even if nobody has mentioned them yet. The post always shows the source name and date
so the rep can judge for themselves. War room and heat-list items get the same check as
everything else; they are candidates, not verified facts.

## 4. Verification

Fetch the primary source URL and confirm the claim before writing a word. A signal without
a fetchable primary source does not post. Never quote what you did not read. Never invent a
contact, a title, a date, or a number.

## 5. Customer gate

- `status: customer` accounts post to the rep channel only when the account carries
  `"ae_cleared": true` AND the lane is marked `install_base: true`. The post then carries the
  line "Install-base account. Loop in the AE before any touch outside the running sequence."
  A customer account without `ae_cleared` is held: the message is still written, but it goes
  to the owner's DM so the owner can clear the account or forward it. A warning line in a
  busy channel is not a gate; the flag is.
  Never a cold angle on a customer.
- `status: unknown`: hold and log. The owner decides.
- Any account not in the file: hold and log.
- Names listed under `never_name` in the universe file never appear in copy.

## 6. Picking the one

When more than one signal qualifies, rank by:
1. A named contact already in the rep's sequence at that account (a smaller signal with a
   live contact beats a bigger signal with nobody to act on).
2. Freshness.
3. Size and specificity of the forcing function.
Post the top one. Log the rest as SKIPPED with a one-line reason so tomorrow's run can
reconsider them if still fresh.

## 7. Dedupe

A fingerprint is `{account_slug}-{signal_type}-{event_date}`. Never repost a fingerprint
logged in the last 21 days. Also read the last 7 days of the rep channel when the Slack read
tool is available and skip anything people already discussed there. A materially new
development on the same account gets a new signal type or date and is fair game.

## 8. Format contract (Slack mrkdwn, under 130 words)

```
:satellite: *Signal · {Account} · {Lane}*
{What happened, one sentence, ending with (Source, Mon DD YYYY).} <{source_url}|source>
*Why it matters:* {one sentence tying it to the lane's operational angle.}
*Do today:* {one concrete move naming the in-sequence contact and step, or the persona worth pulling if nobody is in sequence.}
*Paste-ready:* "{one sentence, under 35 words, lane voice, no product name, usable as the opener of the next email or DM}"
{customer line, only when status is customer}
<{lookup_url}|account lookup>{ · account-level links from the universe file} · Checked: {inputs checked}, {run date}
_React :white_check_mark: once it's in the sequence. Not a fit? Reply here and Dallas pulls it from the list._
```

The paste-ready line is the part that earns the post. The rep has a task backlog; a signal
that creates a writing task gets skipped, a signal that hands over the sentence gets used.
The check-mark ask gives the owner a positive signal to count; silence alone says nothing.

## 10. Weekly tally

On Fridays the relay sends the owner a two-line count: posted, no-post days, held, and the
accounts posted. Two consecutive posts with no reaction or reply is the tell that the
channel has gone to wallpaper; tighten the bar or change the format before posting again.

Voice: Dallas's. Short sentences, contractions, peer tone. No em dashes anywhere. No
"leverage", "robust", "seamless", "streamline", "reach out", "circle back", "excited".
The rep is the hero; the post hands them a move, it does not sell them the product.

## 9. Volume

One post per business day, maximum. If the best candidate is marginal, no post. The channel
already carries bounce, connect, and call-list relays; this post has to be the one worth
reading, or it trains the rep to skip all of them.

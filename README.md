# Belle Ops — Visit Day Tool

An internal tool for the ops coordinator running a region's day of in-home visits.

## Run it

```bash
bin/setup
```

Installs gems and npm packages, creates and seeds the database, and starts Rails +
Vite at http://localhost:3000. Already set up? `bin/dev`.

Reset the demo data (including anything the simulator did): `bin/rails db:seed`
Tests: `bin/rails test`

"Today" is pinned to **2026-06-29** and "now" to **12:00 ET** — the dataset's day —
so the app behaves the same whenever you run it (`config/initializers/belle.rb`).

## What I built, and why

The coordinator's job isn't to look at a schedule; it's to notice the visits about
to go wrong and do something before the CHW wastes the trip. So the whole tool is
built around one loop: **see the day → spot the hole → fill it.**

**The day board** (`/`) is CHWs down the side, hours across the top. Colour is
confirmation status, because "has this member actually said yes?" is the question
that predicts a wasted trip. Struck-through blocks already fell through, ⚠️ marks
members with a history of no-shows, and a line marks the current time. Clicking any
visit opens the detail — including, for a failed one, whether the drive was spent.

**Drive minutes under each CHW.** Drive time is the actual cost of a failed visit,
so each CHW's row shows minutes driving, minutes *wasted* (drove out, visit didn't
happen) and minutes *saved*. The rule that separates them is the one piece of logic
I'd defend hardest:

> A drive is only saved if word came in remotely (text/voice) **and** it arrived
> before the CHW would have set off — `scheduled_start - drive_minutes_from_prev`.
> A text that lands while they're already in the car costs the same as no text.

That's what turns "12 cancellations" into "52 minutes wasted, 55 saved" — a number
that tells you whether chasing confirmations is worth doing.

**Open slots and the waitlist.** When a visit falls through, the vacated window
becomes an open slot on that CHW's row, drawn as a dashed block *beneath the
cancelled visit* rather than over it — the original stays on the board, because a
row that silently drops the visit reads as though it was never scheduled. The
shared waitlist panel sits alongside; where a waiting member fits, the slot names
them.

Clicking a slot opens the full waitlist, ranked, in two groups: **fits this slot**,
and **everyone else**. Nobody is filtered out. Ranking is:

1. People whose stated timeframe fits the window.
2. **Reachable people.** Urgency can't beat geography — if the drive is longer than
   the gap the CHW has (plus 10 minutes' grace), booking it wrecks the rest of the
   route.
3. Then clinically urgent, then nearest, then longest-waiting.

Anyone who doesn't fit cleanly is still one click away, labelled "needs an
override" with the specific reasons ("asked for morning — this slot is afternoon",
"roughly 38 min drive, and the CHW only has 25 min"). The coordinator knows things
the data doesn't; the tool's job is to order and explain, not to withhold. Every
suggestion shows its reasons, so nobody is asked to trust a black box.

**Members** (`/patients`) is sorted by no-show history — the people most likely to
cost a trip, first — with today's outcome per member. Above it, a **CHW watch**
section: most failures are the member's doing, but a run concentrated on one CHW is
worth a conversation. Today nobody trips the threshold, and the page says so rather
than manufacturing a badge.

**Live updates.** The board polls every five seconds (partial Inertia reload, so an
open modal survives). "Simulate an incoming update" stands in for the SMS gateway,
IVR and CHW app: a member confirms, a text cancellation arrives, a CHW finds nobody
home, someone calls in. Events are state-aware — the simulator never invents a
cancellation for a visit that already happened.

## What I deliberately left out

- **Auth, roles, multi-region, multi-day.** One coordinator, one region, one day.
- **Real routing.** Distances are haversine at an assumed 20 km/h. Anything more
  needs a routing API, and the ranking only has to be *good enough to order
  candidates*, not to publish an ETA.
- **Actually contacting anyone.** The highest-value real feature is a "call/text
  this member" button on unconfirmed visits. It's the obvious next thing; it needs
  a comms integration, which is a different afternoon.
- **Drag-and-drop rescheduling.** A backfill into an existing window covers the
  common case; arbitrary rescheduling is a much bigger interaction.
- **Cost in dollars.** Minutes are what the data supports; a dollar figure would be
  an invented hourly rate wearing a suit.
- **Heavy test coverage.** Tests cover the judgment calls — the drive-cost rule,
  matching, booking, the simulator — not React rendering.

## Assumptions

- One CHW per visit; the vacated window keeps its CHW when backfilled.
- The cancelled visit's address is a fair proxy for where the CHW's route has them
  at that hour, so it's the anchor for measuring candidates.
- Household members at one address are a single stop; overlapping visits stack in
  lanes rather than hiding each other.
- A backfilled visit starts **unconfirmed** — nobody has spoken to that member about
  *this* window yet, so it belongs on the chase list like any other.
- Slots already in the past aren't offered for filling. They're lost trips, not
  opportunities.
- `prior_no_shows >= 2` is "worth a call first". Arbitrary, and one constant to change.
- One day of data can't support judging a CHW, so the watch threshold (≥30% of ≥4
  visits) is conservative on purpose.

## Structure

```
app/services/     drive_cost, open_slots, waitlist_matcher, scheduling,
                  reliability_stats, simulation
app/presenters/   calendar_day, visit, waitlist, members — shape props for Inertia
app/models/concerns/  cancellable (fell-through + drive rules), geo_locatable
app/frontend/     React pages and components
```

Controllers stay thin: find, delegate to a service, render a presenter's props.
Business rules live in services and concerns so they're testable without a browser.

## How I used AI

Claude Code did essentially all the typing, working from a plan I set up front:
scaffold, data model, calendar, cost, waitlist, members, simulation, polish — each
step reviewed and committed as its own patch before starting the next.

Where it earned its keep: scaffolding and boilerplate, and grinding through the
dataset to check my rules against reality rather than against my assumptions.

Where I had to steer it, and the more interesting half:

- Its first waitlist ranking put clinical urgency above everything, which cheerfully
  suggested sending a CHW on a 44-minute drive into a 15-minute gap — directly
  contradicting the drive-cost thesis of the rest of the app. Reachability became a
  filter ahead of urgency.
- That filter was then too strict (a member 6 minutes too far got ruled out of a slot
  that would have been fine), hence the explicit 10-minute grace allowance.
- It initially let overlapping household visits render on top of each other; the real
  data has a CHW seeing two members at one address, so blocks stack in lanes.
- It wanted to lower the CHW-watch threshold so a flag would show up in the demo. I
  kept the threshold and made the empty state say so — tuning a number to make a
  badge appear is how you build a dashboard nobody trusts.

The pattern: it's fast and good at the mechanical work, and it will confidently
produce something that looks right but quietly contradicts the point of the feature.
The judgment calls above are the actual work.

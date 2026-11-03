# 0013 — Reading days, streaks and freezes

- **Status:** Accepted
- **Date:** 2026-11-03
- **Relates to:** SPEC F04 (the "read" rule), F08 (streaks & reading stats), §16.2 (`UserStats`, `ReadingDays`)

## Context

F08 counts a streak in days, but "a day" changes with the user's time zone, daylight saving and travel. This is where
streak features usually break: a read at 00:30 in Cairo is still "yesterday" in UTC, and a user who flies from Cairo to
New York gets the same calendar date twice. The SPEC also gives one free freeze "per week" without saying what a week
is, and the reader needs a "read" rule that the server can trust.

## Decision

**A read.** An article is read when the reader has scrolled ≥ 70% **and** spent ≥ 30 active seconds on it (SPEC F04). The
reader sends `PUT /articles/{id}/progress` with its scroll percent and the active seconds since its previous report.
The server credits at most the time that really passed between two reports (+10 s of jitter, ≤ 600 s per report), and the
first report of an article credits nothing, so a client can't claim 30 seconds in one request. Readers send a report when
they open an article, then every 15 s while it is visible, and when they leave. `ReadingProgress.CompletedAt` is set once
and is the single "read" marker (also used by the daily article's "not read before", F07).

**A day.** A reading day is the calendar date in the user's **profile time zone** (`Users.TimeZone`, an IANA id, default
`Africa/Cairo`, set from the device at sign up and in preferences) at the moment the **server** records the report. It is
stored in `ReadingDays.Date` and never moved afterwards: changing the time zone later doesn't re-date past days. The
device's clock and time zone are never trusted for this. Daylight-saving changes don't matter because only the local
*date* is kept.

**A streak** is a run of local dates with at least one completed article (`ReadingDays.ArticlesRead > 0`). A frozen day
keeps the run going but doesn't add to it.

**A freeze** covers one missed day when no freeze was used in the 7 days before it (a rolling week, chosen by the product
owner over a calendar week so there's no week-start day to pick and no two freezes back to back across a week
boundary). Two missed days in a row always end the streak. Freezes are used lazily: when the user reads after a single
missed day, that day becomes a freeze. Until then the API reports `freezePending: true` and keeps showing the streak.

**Computed, not incremented.** The streak, longest streak and freeze days are recomputed from `ReadingDays` whenever a
read completes (`Streaks.Compute`). `UserStats` caches the result for cheap reads, and whether the cached streak is still
alive is decided at read time against the user's local today (`Streaks.StatusOn`). Recomputing is always safe, so
backfills and seeding use the same code.

**Stats.** "This week" means the last 7 local days and "this month" the last 30 (rolling, like freezes). Minutes read count
all active reading time, finished or not. Stats, the heatmap and the streak are visible to their owner only, until the
F18 "public reading stats" privacy setting exists.

**Milestones.** The report that extends the streak to 7, 30, 100 or 365 days returns `milestone`, and the clients
celebrate it with a shareable card.

## Consequences

- A user who travels west can see a "today" that is earlier than their last reading day. That counts as read today; no
  streak is lost or gained.
- A user who changes their time zone across midnight can skip or repeat a calendar date once. Skipping one date is
  covered by a freeze when one is available.
- The evening "keep your streak" reminder push belongs to F17 Notifications and isn't part of this decision.

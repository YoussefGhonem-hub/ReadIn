# 0020 — For you ranks by an effective time, against a snapshot carried in the cursor

- **Status:** Accepted
- **Date:** 2026-11-06
- **Relates to:** SPEC F03 (For you: "interests + popularity + freshness"), §10.1 (the Verified badge "gives priority in
  feeds"), F07 (Today's article), F28 (lowered tier), F27 ("مقالات جديدة ↑" banner); contract-v1 "For you ranking".

## Context

Until now For you put your interests first, then everything else, then what you marked "show less", **newest first**
inside each group, with a keyset cursor over (tier, `publishedAt`, id). SPEC F03 asks for popularity and freshness, and
§10.1 says the Verified badge gives priority in feeds. Three things make that hard:

1. **Pages must stay stable.** Popularity changes all the time (reactions, saves, comments). A keyset over a score that
   moves between two pages skips the articles that rose past the cursor and repeats the ones that fell behind it. An
   offset over a moving ranking has the same problem.
2. **Freshness changes with time.** A score with a decay term (like `Articles.QualityScore`, recomputed hourly with a
   30-day half-life, ADR 0015) is different every hour, so it can't be the key of a cursor either.
3. **Old popular articles shouldn't stay on top forever**, and a verified writer's article should come earlier
   without drowning everyone else.

## Decision

- **An effective time.** Inside each tier the articles are ordered by
  `rank = publishedAt + 4 days × popularity + 1 day × verified` (whole seconds), then `publishedAt`, then the id, all
  descending. `popularity = 1 − 1 / (1 + E / 20)` saturates below 1, with `E` = completed reads × 1 + reactions × 2 +
  comments × 4 + saves × 6 + reposts × 6 (Explore's weights, reposts as saves), other people's only, hidden comments
  left out. This is a freshness decay written as a time shift: engagement buys an article at most 4 days, the badge
  1 day, and anything older sinks however popular it was. Because the decay is linear in time, the ranking needs no
  "now": two articles keep their order as time passes.
- **A snapshot per scroll.** The first page takes the current time as the snapshot `T`. Engagement is counted only for
  events in `[T − 30 days, T]`, the badge only when `verifiedAt ≤ T`, and only articles with `publishedAt ≤ T` are
  listed. The cursor carries `T` with the last card's (tier, rank, `publishedAt`, id), so every page of a scroll ranks
  against the same `T`: new activity can't raise a rank, nothing rises past the cursor, and nothing is skipped. What can
  still lower a rank (a reaction or save taken back, a comment deleted or hidden, a badge removed) only moves an article
  further down, where a client drops an id it already shows (as with the F28 Undo). New articles reach the user through
  the F27 banner and the next first page. **One exception: a moderator un-hiding something mid-scroll.** Visibility is
  read when each page is queried (`HiddenAt` keeps no history), so a comment written before `T` that a moderator
  un-hides between two pages raises its article's `E`, and an un-hidden article comes back into the list. Either can
  then rank above the cursor and be missed for the rest of that scroll (newest first had the same gap for an un-hidden
  article). It is rare and harmless: the article is there again on the next first page.
- **Computed in SQL, one query per tier.** The engagement counts are correlated subqueries over the (ArticleId, time)
  indexes (ReadingProgress and SavedArticles got theirs with this change, migration `RankingEngagementIndexes`;
  Comments use (ArticleId, ParentId, CreatedAt)); the boost is `DATEADD(second, …)` on `PublishedAt`, so the rank is an exact `datetime2`
  and equal inputs give equal keys on every page. The cards are projected afterwards for the page's ids.
- **Old cursors still work.** A cursor from before this change (tier + `publishedAt` + id) finishes its scroll in the
  old newest-first order with old-style cursors; the next first page is ranked. The new cursor starts with `r`, so the
  two never mix.
- **Today's article** keeps the quality score; between equal scores a verified writer's article wins, then the newest.
  The Following feed stays chronological: it is the people you chose.

## Consequences

- One scroll shows a consistent order, also across the tiers, and clients change nothing (cursors are opaque).
- The 30-day window and the saturation keep the cost bounded per article; each page counts engagement for the
  candidates of the tiers it reads. At a much larger scale, a stored per-article popularity snapshot (written hourly,
  versioned by time) can replace the subqueries without changing the contract.
- The weights and boosts are constants in `FeedRanking`; changing them changes only future first pages.

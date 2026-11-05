# 0017 — Search: SQL Server Full-Text Search, with a LIKE fallback

- **Status:** Accepted
- **Date:** 2026-11-05
- **Relates to:** SPEC F16 (search), §16.1 (collation), §16.3 (indexes), §22 (search), §27 (testing), §28.2 (local setup);
  contract-v1 "Search".

## Context

Search (F16) looks for articles, writers, topics and tags in Arabic and English, and inside attached PDFs. The text it
searches is already stored normalized (§22: diacritics and tatweel removed, `أ إ آ → ا`, `ى → ي`, `ة → ه`, lower case):
`ArticleTranslations.SearchText` and `MediaAssets.ExtractedText`. SPEC §22 asks for SQL Server Full-Text Search.

Two facts shape the design:

1. The official `mcr.microsoft.com/mssql/server` image has **no** full-text component, so a plain Docker SQL Server (and
   any server installed without the feature) can't run `CONTAINS`. Production may or may not have it.
2. A full-text index has **one word breaker per column**, while `SearchText` holds both Arabic and English versions.

## Decision

- **One interface, two engines.** `ISearchEngine` (Application) returns composable queries of hits (`Key`, `Rank`) for
  article versions and for PDFs. `FullTextSearchEngine` uses `CONTAINSTABLE` with every query word as a quoted prefix
  term, sent as a parameter (no syntax injection); `LikeSearchEngine` uses escaped `LIKE '%word%'` over the same
  normalized columns. The handlers add visibility, mutes (the F28 seam), filters and ranking on top in SQL and C#, so
  both engines give the same rules; only `rank` and word boundaries differ (contract-v1 "Search", "Engines").
- **Chosen once at startup** (`SearchEngineSetup`, after the migrations or the data upgrades): full-text when
  `SERVERPROPERTY('IsFullTextInstalled') = 1` and both indexes exist, otherwise the fallback. `Search:Engine = like`
  forces the fallback.
- **Schema:** the `SearchFullText` migration creates the catalog `ReadInSearch` and the indexes on
  `ArticleTranslations(SearchText)` and `MediaAssets(ExtractedText)` only on a server with full-text (outside a
  transaction, as full-text DDL requires). Startup runs the same idempotent DDL, so a database migrated before its
  server had full-text gets the indexes at the next start.
- **Arabic word breaker (LCID 1025)** for both columns, `STOPLIST = OFF`, `CHANGE_TRACKING = AUTO`. It breaks English
  words too, and it finds Arabic words behind prefixes (`ذكاء` finds `الذكاء`, `سهوله` finds `بسهوله`). Query words are
  prefix terms, so English needs no stemming. An Arabic word also gets an explicit `ال` variant.
- **Names are not full-text indexed.** Display names, field and topic names and tag names are short, aren't stored
  normalized, and live in small tables. Both engines match them with §22 normalization in SQL (`ArabicNormalizer.InSql`)
  and escaped `LIKE` patterns at word starts (taxonomy in memory). A full-text index on raw `Users(DisplayName,
  Username)` would miss `احمد` for `أحمد`.
- **Ranking** is computed in C# from the engine's rank, the place it matched, `Articles.QualityScore` and freshness
  (formula in contract-v1). At most 1000 hits per place are read, best rank first, and a query pages through at most
  200 results with an opaque offset cursor. Guests' article rankings are cached for 2 minutes and dropped by publish,
  Update, hide/unhide and delete.
- **Local and CI SQL Server has full-text:** `docker/sqlserver/Dockerfile` adds `mssql-server-fts` to the 2022 image.
  `docker-compose.yml` builds it (host port 14333 unchanged), and the integration tests build it through
  Testcontainers (kept after the run, so Docker's layer cache makes later builds instant). On CI the backend workflow
  frees the runner's disk (the image is about 5 GB) and builds it with plain `docker build` on every run (about
  80 s for the apt layer). A Buildx cache was tried first: loading its result needed a second copy of the image and
  ran the runner out of disk. The integration tests run the article cases on both engines.

## Consequences

- Full-text indexing is asynchronous: a published article is found a few seconds later. Tests wait for the index
  before searching.
- A full-text indexed column can't be altered. A migration that changes `SearchText` or `ExtractedText` must drop the
  index first and recreate it (`SearchEngineSetup.CreateSql`).
- The full-text image is about 5 GB, and building it the first time takes a few minutes, locally and on CI.
- Production without full-text still searches correctly, but the fallback scans the normalized text. That is fine for
  thousands of articles. Larger corpora need full-text (or Azure AI Search / Elasticsearch, §22 Phase 3).
- `SearchText` keeps one word breaker. If English stemming becomes important, a second, English-indexed column would
  be needed.

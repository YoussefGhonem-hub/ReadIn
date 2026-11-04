# 0015 — Open publishing, the editor's working copy, and the quality score

- **Status:** Accepted
- **Date:** 2026-11-04
- **Relates to:** SPEC F05 (editor), F06 (lifecycle), F07 (Today's article), F20 (removed), §10.2 (roles), §16.2, §17.2. Supersedes the "optional review" part of [ADR 0014](0014-open-topics-and-optional-review.md).

## Context

The SPEC had two axes for an article: its lifecycle (draft → published) and a human review. Review was optional for most
fields, mandatory for Medicine and Public Health, gave a "✓ Reviewed by" badge and a "Last reviewed" date, and Today's
article preferred reviewed articles. The editor (F05) also offered "schedule" and "submit for review".

On 2026-11-03 the product owner decided:

1. **No review at all.** Anyone publishes in any field. No Reviewer role, no "Reviewed" badge, no "Last reviewed" date,
   no review queue (F20 is removed from the roadmap). Health articles keep their "doesn't replace seeing a doctor"
   disclaimer.
2. **No scheduling.** Publishing is "now" only.
3. **Today's article may be any published article**, written by anyone, ranked by a quality score (reactions, read
   completion, freshness).
4. **Editing a published article** must not change what readers see until the writer presses **Update**.
5. Drafts and published articles are found on a **"My articles"** page.

## Decision

**Lifecycle.** `ArticleStatus` is `Draft → Published → Archived`. The review states, `ReviewStatus`, `ReviewedById`,
`LastReviewedAt`, `ScheduledAt`, the `ReviewerFields` table, the `Reviewer` role and the `articles.review` /
`articles.publish.sensitive` permissions are removed. Every Member has `articles.create`, so anyone may publish.
`VerifiedWriter` stays as an identity badge only (F19). The scheduled-publishing job is removed.

**The working copy.** The editor edits one JSON document per article, `ArticleDrafts.DocumentJson`. It holds everything:
both language versions (RDoc), field and topic, tags, sources, cover, version badge, AI-assisted, and attachments. Autosave
replaces it whole (`PUT /articles/{id}/draft`).
- **Concurrency:** `Version` is a concurrency token, and saves must name the version they were based on. So a second
  device gets `409 article.draft_conflict` instead of silently overwriting the first.
- **Lenient saving:** saving never fails because the article is unfinished. Empty titles, no field, image blocks without
  alt text, attachments still processing and schema-invalid blocks are reported as live checks (`checks.problems`).
- **Strict publishing:** publishing re-runs the checks and refuses while any problem remains.

**Publish = apply the working copy.** The working copy replaces the live translations (sanitized RDoc, SPEC §13.5),
taxonomy, tags, sources, metadata and attachments.
- **Slug:** a first publish assigns the slug from the source title. It never changes afterwards; until then the slug is
  a private placeholder.
- **Updates:** a later publish is an Update. The first publish date stays and no "new article" signal fires; feeds and
  the article's cache are invalidated.
- **Revisions:** every publish stores the published document as a revision (`ArticleRevisions`, one row per publish, the
  whole document). Restoring a revision copies it into the working copy, and it goes live with the next publish.
- **Discard:** "Discard changes" resets the working copy to what readers see.

**Uploads** that a working copy or a revision names are kept by the orphan cleanup, so drafts can still publish them and
revisions can be restored. An upload named in a working copy cannot be deleted (`media.in_use`). Deleting an article
deletes its working copy, its revisions and the uploads only they used.

**Quality score** (`Articles.QualityScore`, in [0, 1]), recomputed for every published article by an hourly job and once
at startup. A first publish starts at the score of a new article.

```text
engagement = 1 − 1 / (1 + (reactions + 2·comments + 3·saves) / 10)        0.5 at 10 weighted interactions
completion = (completedReads + 1) / (max(startedReads, completedReads) + 2)   smoothed: a new article starts at 0.5
freshness  = 0.5 ^ (hoursSincePublish / 720)                               halves every 30 days
score      = 0.45·engagement + 0.35·completion + 0.20·freshness
```

Completed reads are `ReadingProgress.CompletedAt != null` (F04, ADR 0013); started reads are progress rows.
`ArticleQuality.Score` is the reference implementation; the job runs the same formula in SQL.

**Today's article** (F07) picks from all published articles with the existing rules:
- in the reader's interests;
- not read before;
- 4–10 minutes;
- the preferred language first;
- not the same field 3 days in a row.

It ranks by the quality score and relaxes length, then interests. A writer never gets their own article. Guests rotate
over the 30 best. `AutoCheckedAt` (content pipeline) is kept but no longer used for the pick.

## Consequences

- Anyone can reach every reader's daily push with a new article, as the product owner accepted. Freshness gives a new
  article a fair start, and engagement and completion have to keep it on top. The weights are a first guess that can be
  tuned without a migration.
- Trust now rests on verified writers, mandatory sources, version badges and moderation (reports, F22), not on review.
- The migration turns review-era states back into drafts, removes the Reviewer role and permissions, and deletes the old
  per-language revision rows. Only content re-imports created those rows, and git already versions that content.
- Each autosave writes the whole document. Articles are small (≤ 2000 blocks, ≤ 500 000 characters per language), so
  this is simpler than diffs and keeps restore and conflict handling trivial.
- The content pipeline's 300 seeded meta.json files keep `"reviewStatus": "pending"`, because editing them would re-import
  every article. The importer ignores it, and ContentStudio no longer asks for it: new files leave it out, and any
  claimed review (another `reviewStatus`, a `reviewer`, a `reviewedAt`) fails validation. `lastReviewedAt` is the
  generation date, stored as `AutoCheckedAt`.

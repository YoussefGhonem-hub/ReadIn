# 0014 — Open topics, and review is always optional

- **Status:** Accepted; the "optional review" part is superseded by [ADR 0015](0015-open-publishing-and-the-editor.md) (review removed)
- **Date:** 2026-11-04
- **Relates to:** SPEC §1.4 (fields), §10 (permissions), F06 (lifecycle), F20 (review), §19 (seed plan), §20 (trust)

## Context

The first SPEC treated ReadIn as a software platform that would later add Medicine, Engineering and Public Health, behind
extra gates: those fields were disabled, publishing in Medicine or Public Health needed the `articles.publish.sensitive`
permission (Verified Writers and Reviewers only), and each article also needed a Reviewer's approval.

The product owner decided otherwise: ReadIn is for anyone publishing about anything, and no field needs approval.

## Decision

**Open topics.** Every field is enabled from launch: software, health, engineering, the broad fields (Science, Business,
Education, Self-growth, History & Culture, Arts & Literature, Law, Sports, Lifestyle) and a catch-all `general` field. Any
member can publish in any of them. Admins can add more, and tags cover anything more specific.

**Optional review.** `Article.Publish` no longer checks the review status, the publish handler no longer checks a
permission, and `articles.publish.sensitive` and `article.review_required` are gone. Review still exists: it gives the
"Reviewed" badge and priority for Today's article.

**`Fields.IsSensitive` stays, with a new meaning.** It now only marks fields whose articles show a health disclaimer. It
never blocks publishing. Keeping the name avoids a migration and a contract change for web and mobile.

**Sources stay per field.** `RequiresSources` stays on for software, Medicine, Public Health and Engineering, and is off
for the broad fields and `general`, where a personal essay may have no sources.

## Consequences

- Health misinformation can be published without anyone checking it first. The remaining safeguards are the disclaimer,
  required sources, the absence of a "Reviewed" badge, and after-the-fact reports and moderation (F22).
- App Store Guideline 1.2 requires apps with user-generated content to offer reporting, blocking of abusive users and a
  way to filter objectionable content. Open publishing makes this a hard requirement before submitting to the App Store.
- The stale `articles.publish.sensitive` row stays in the `Permissions` table on existing databases: it is no longer
  granted to any role, so it has no effect.
- More fields mean more onboarding chips and filter chips, so those lists must stay comfortable with 24 fields.

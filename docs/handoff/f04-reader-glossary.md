# Handoff: F04 reader leftovers + F21 glossary taps

Branch `f04-reader` (worktree `D:/r8`). It holds the feature work (e54fa9b api, 46f9b7d web, 784ab1e mobile) and a
merge of `origin/dev` at 2c8ada6 (F05 editor + account deletion) on top of it. It is pushed as a branch only and is
**not on `dev`**.

## What's done

- **Related articles (F04):** `GET /articles/{id}/related?lang=&limit=` (1–10, default 4).
  - Ranking: same topic, then same field, then shared tags and glossary terms (each capped). Ties go to quality score,
    then the newest.
  - Never shown: the article itself, its neighbours in a learning path (that's "Next in path"), and the viewer's own
    articles. Articles the viewer has already read come last.
  - Web: `features/article/related-articles.ts`, loaded when the section nears the viewport.
  - Mobile: `RelatedArticlesSection`, passed through the new `ReaderBody.trailing` slivers. The editor preview reuses
    `ReaderBody` and passes none.
- **Resume (F04):** `ArticleDetailsDto.myProgress` (language, percent, lastPosition, completedAt), loaded for signed-in
  viewers by `ArticleDetailsPersonalizer`.
  - Web `resume-position.ts` and mobile `ReaderResume` scroll back and show a "Start over" toast. The rules are in
    `docs/api/contract-v1.md`, "Resume (F04)".
  - The web tracker holds its first report until the reader is placed.
  - Mobile `RDocSliver` now remembers measured block heights, so the scroll extent is stable.
- **Glossary (F21):**
  - Tables `GlossaryTerms` + `ArticleTerms`, migration **`20261104102442_Glossary`**, regenerated after
    `AccountHardDelete`. The body is unchanged, and `has-pending-model-changes` is clean.
  - `GlossarySeeder` (order 8): loads 542 terms from `content/glossary/*.yaml` and rebuilds the article-term index.
  - `ArticleTermsIndex` rebuilds an article's terms on first publish (`ArticlePublishedDomainEvent`) and on an update
    (F05 `PublishArticleDraftCommandHandler`, "already published" branch). That update hook was added in this merge.
  - `GET /glossary/{slug}?lang=` (cached; tags glossary + feed) and `GET /glossary?q=&limit=`.
  - Web and mobile: tapping a term opens a sheet with the English term, the Arabic explanation and/or the English
    definition, and up to 5 other articles that use the term.
- **Docs:**
  - Contract sections "Related articles (F04)", "Resume (F04)" and "Glossary (F21)".
  - SPEC F04, F21, §16.2 and §18.2.
  - README rows.

## What's left

- **Merge into `dev`.** The branch already contains `dev` at 2c8ada6, so it should merge cleanly unless `dev` moved.
  If another migration landed on `dev` first, regenerate `Glossary` after it: take dev's snapshot, delete the two
  `*_Glossary*.cs` files, then run `dotnet ef migrations add Glossary`.
- **"Next in path"** (F09, readin-c2's branch). Add it as a sliver in `ReaderBody.trailing` before
  `RelatedArticlesSection` on mobile, and before `<rd-related-articles>` on web.
- **"Report article"** belongs to F22 (readin-8e's branch).
- **Writers marking terms in the editor (F21).** `GET /glossary?q=` is ready for a term picker. The editor files are
  `web/src/app/features/editor/rdoc-editor/` and the mobile AppFlowy surface.
- **Small inconsistencies:**
  - Web related cards show attachments, while mobile uses `ArticleCardTile(showAttachments: false)`.
  - Both clients measure the resume fraction over the whole scroll range, including late sections, so resuming on the
    other device is approximate.

## Known errors

None in the final tree. During the merge:
- the mobile editor preview crashed because related articles needed a cubit there; fixed with `ReaderBody.trailing`;
- 4 related-articles goldens still showed the removed "Reviewed" badge; regenerated.

## Tests run (on the merged tree)

| Area | Command | Result |
|---|---|---|
| Backend | `dotnet build ReadIn.slnx`, then `dotnet test --solution ReadIn.slnx --no-build` | 1360 / 1360 passed (12 new in `GlossaryTests` + `ReaderTests`, incl. the update hook) |
| Migrations | `dotnet ef migrations has-pending-model-changes` | no changes |
| Web | `npm ci`, `npm run lint`, `npm test`, `npm run build` | lint clean; 628 / 628 unit; build OK, initial 511.70 kB (the existing 500 kB warning) |
| Web e2e | `E2E_APP_PORT=4310 E2E_MOCK_PORT=5310 npx playwright test e2e/reader.e2e.ts e2e/social.e2e.ts --workers=2` | 24 / 24 and 40 / 40 |
| Mobile | `dart run build_runner build --delete-conflicting-outputs` + `git diff --exit-code -- lib` (CI check) | 0 outputs written, no diff |
| Mobile | `flutter analyze` | no issues |
| Mobile | `flutter test` | 1068 passed, 4 failed. The 4 were the related-articles goldens; they were regenerated, and `glossary_golden_test.dart` + `editor_golden_test.dart` + `test/features/article` were rerun green (8 + 102). The full suite was not rerun after that. |

A real-data check before the merge used a fresh `ReadInF04` database (since dropped) with all 300 articles:
- 542 terms and 790 article-term rows;
- `/related` and `/glossary` results looked right;
- `/related` took about 0.3–0.5 s on a loaded machine, from about 7 SQL round trips of 20–45 ms each.

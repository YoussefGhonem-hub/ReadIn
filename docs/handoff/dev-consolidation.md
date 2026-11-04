# Handoff: merging every branch into `dev` (readin-8e, formerly readin-f4)

Written 2026-11-04 when the user moved the remaining merges to the main session. Branch with this file:
`merge-f09-paths`. The F22 feature branch is `f22-moderation`, described in its own section below.

## Done and on `dev`
- **Backup:** `D:\readin-backup.bundle`, created 11:53 with `git bundle create --all`: 46 refs, `git bundle verify` OK.
  Every branch and tag that existed then is in it. Take a fresh one before deleting branches, because `f22-moderation` and
  `merge-f09-paths` were committed after it.
- **F05** `f05-rebase` → `dev` 30b1867. The main session pushed it, not me.
- **account-deletion** → `dev` **2c8ada6**, a `git merge --no-ff account-deletion` on top of 30b1867.
  - The ADR is renumbered 0014 → **0016** (0014 is open topics, 0015 is F05). References are updated in SPEC, ADR 0007/0012,
    `docs/setup/ios.md` and `web/README.md`.
  - Review is removed (ADR 0015):
    - the eraser no longer touches `Articles.ReviewedById`;
    - the SPEC §9.6 data map loses the `ReviewerFields` and "reviews" rows;
    - the deletion text (web i18n `…reviews`, mobile `deleteAccountKeptReviews`, `public/delete-account.html`,
      `public/privacy.html`) now only says "edits you made on other writers' articles".
  - F05's private working copy (`ArticleDrafts`) of a kept published article is deleted with the account, and asserted in
    `AccountDeletionTests`. Images are collected from `ArticleRevisions.DocumentJson`.
  - The migration is regenerated after `OpenPublishingAndEditor` as `20261104100057_AccountHardDelete`. Its body is
    identical to the old one minus the `ArticleRevisions.CreatedBy` change, which F05 already made.
  - `AccountDeletionTests` write articles through F05's `ArticleTestKit`.
  - 12 mobile goldens were regenerated and viewed: `account_delete_review_end_*`, `reader_deleted_author_*`,
    `feed_cards_deleted_author_*`.
  - Gates on the merge: backend **1348/1348**; web lint, **586/586** unit, build; mobile analyze clean, **1016/1016**
    including goldens. Web e2e was **not** run on this merge.
- The shared tree `D:\freelancer\ReadIn` was fast-forwarded to 2c8ada6. Its unowned `.gitignore` / `README.md` edits are
  still uncommitted, as the user chose.

## Known error on `dev` right now
- **Mobile CI fails on 2c8ada6** (run 41812694865) at "Generated code is up to date".
  - Only `mobile/lib/core/di/injection.config.dart` differs. Git's text merge produced a valid file, but in a different
    order than `injectable` writes it. Tests pass.
  - Fix: run the full `dart run build_runner build` in `mobile/` and commit the file. Under today's load this took more
    than 20 minutes, and I stopped my run when told to stop.
  - readin-bd (formerly readin-08) was asked to do this inside its F04 merge.

## Merged locally, NOT pushed
- **`merge-f09-paths`** (this branch) = 2c8ada6 + `git merge --no-ff f09-paths` (2972b56), commit 87cf8b2, plus this
  handoff commit.
  - The migration is regenerated as `20261104101556_LearningPathEnrollments` after AccountHardDelete. The hand-written
    `UPDATE LearningPaths SET IsEditorial = 1` is carried over, so the body is identical to the branch's.
    `has-pending-model-changes` reports none.
  - **If F04's `Glossary` migration lands on dev first**, regenerate this one again after it: delete it, take dev's
    snapshot, run `dotnet ef migrations add LearningPathEnrollments`, and re-add the `Sql(...)` line before `CreateTable`.
  - Conflicts resolved:
    - `DailyArticlePicker` doc comment: F05's "any published article by QualityScore", plus F09's "active path first";
    - README rows;
    - SPEC F03 (dev's Today line + F09's Continue reading / Learning path lines);
    - contract-v1 error-code line ("profile, path, editor and media codes").
  - `PathCards.ArticleLanguageOfAsync` now uses `ArticleLanguages.ForUi`, as readin-c2 asked.
  - Gate: backend **1375/1375**. There are no web or mobile changes in f09-paths.
- **Obsolete, don't use:** the detached commits 5435a06 and 554b8db, which merged account-deletion and F04 onto the old
  dev 3d466a8. 2c8ada6 replaces them.

## Not merged yet
1. **F04 `f04-reader`**: readin-bd merged dev 2c8ada6 into it and pushed **`origin/f04-reader` 291c566**, not dev.
   - Glossary is regenerated as `20261104102442_Glossary`, the F05 hook is in, and its tests use ArticleTestKit.
   - Its gates: backend 1360, web 628 + e2e reader/social, mobile analyze + codegen clean.
   - Its handoff is `docs/handoff/f04-reader-glossary.md` on that branch. It fast-forwards dev if dev hasn't moved.
   - **Migration order:** this branch's `20261104101556_LearningPathEnrollments` and F04's `20261104102442_Glossary`
     were each generated without the other. Whichever lands second must be regenerated after the first.
2. **F09 `f09-mobile`** (82e2a4e, analyze clean, 916/916 on its base). I attempted the merge on 87cf8b2 and **aborted** it
   on your instruction. Its conflicts and how I was resolving them:
   - `mobile/lib/app/router.dart`: keep F09's `/a/:slug` with `language: AppRoutes.articleLanguage(state.uri)`, the
     `/paths` routes, **and** F05's two editor routes.
   - `app_en.arb` / `app_ar.arb`: both sides append keys at the end. Keep both, then run `flutter gen-l10n`.
   - `injection.config.dart`: regenerate with build_runner. A `--build-filter` run on it didn't finish in 20 minutes.
   - `home_*` and `home_live_*` goldens (8): regenerate with `--update-goldens` after the merge and look at them. F09 adds
     a paths prompt row.
3. **F09 `f09-web`** (28f275e; lint, 526/526 unit, e2e 226/226 on its base). Not started. readin-c2's list of shared
   hunks: `models.ts`, `error-messages.ts`, i18n, `app.routes.ts`, `placeholders.routes.ts`, `home.page.ts` /
   `home.store.ts`, `article.page.ts` (3 lines after Sources), profile tabs, e2e mock-api `server.mjs` / `profiles.mjs`.
4. **F22 `f22-moderation`**: see the section below.
5. **Cleanup** (user's step 5) and the **rules** (step 6) aren't done.
   - Drafts, all tested: `tools/locks/lock.mjs` (on this branch), `docs/handoff/drafts/CLAUDE.md`,
     `docs/handoff/drafts/claude-settings.json` (the hooks for `.claude/settings.json`),
     `docs/handoff/drafts/spec-29-rules.md`.
   - **Don't commit the existing untracked `.claude/settings.json`.** It holds about 250 permission rules from another
     project (user ymg12, iHop). My plan was to move them into the git-ignored `.claude/settings.local.json`, so nothing
     changes, and commit a hooks-only `settings.json` from the draft.

## F22 Reporting & Moderation: branch `f22-moderation` (93f098b, pushed)
- One commit on old dev 8e60f73, covering backend, web and mobile. The contract and design decisions are in the commit
  message and in SPEC F22 / `contract-v1` on the branch.
- Gates on the branch:
  - backend 1320/1320, `-warnaserror` clean;
  - web lint, 536/536 unit, build, e2e 210/210 (4280/5180 confirmed as its own servers);
  - mobile analyze clean, 924/924 including 16 new goldens.
- Migration `20261104075626_Moderation`: `Articles.HiddenAt`/`HiddenById`, plus the `ModerationActions` table with 4
  indexes and no FKs. Regenerate it after everything that lands before it.
- Merge notes:
  - Hidden articles are filtered in `ArticleVisibility.Visible()` (strict). The reader uses `VisibleTo(viewer)`, and
    `Published()` includes hidden ones, for GET-by-slug only. F04's related/glossary lists and F09's path cards and
    `ActivePathNext` should go through `Visible()`; check that after the merge. F05's editor and "My articles" must still
    show a hidden article to its author.
  - `AccountEraser` (from account-deletion) must null `ModerationActions.ModeratorId` / `TargetUserId` for the deleted
    account. I didn't add this yet, and there's no test.
  - readin-5e (F17) will hook `ModerationNoticeIssuedDomainEvent(NoticeId)` → `ModerationNoticePush` and add
    NotificationActors to the eraser.
  - Expect conflicts in:
    - web `article.page.ts` (F05 headline/trust row, F04 resume, F09 Next in path, F22 menu + banner);
    - mobile `article_page.dart` (F05 `authorAction`, F04 resume, F09 `NextInPathSliver` + `language`, F22 menu + banner);
    - `ArticleDtos.cs`, `ErrorMessages.cs`, the ARB files, i18n, `injection.config.dart`, comments code, `DailyArticlePicker`.

## Branches
- **Old duplicates to delete without merging** (every commit subject is already on dev; readin-e7 confirmed):
  `f07-daily`, `f14`, `f14-backend`, `f14-mobile`, `f14-pre-f11`, `f14-web`, `live-base`, `social-backend`,
  `social-mobile`, `social-web`, `account-deletion-pre-squash`, `f05-editor`.
- **Already contained in dev:** `auth-v1.1-all`, `f08-streaks`, `f11-comments`, `f27-realtime`, `wave1`, `f05-rebase`,
  `account-deletion` (+ `origin/account-deletion`).

## Worktrees (none removed yet)
- `Temp/rad`: this branch, clean. A `dart` process from my stopped build_runner may still hold
  `mobile/.dart_tool/build/lock/build_runner.lock`, so `git worktree remove` can fail until it exits.
- `Temp/rf22`: `f22-moderation`, clean.
- `Temp/rs1`: detached at 51ad96c, clean (the old content-batch worktree).
- The others (D:/r8, D:/m9, D:/p9, D:/w9, D:/re, D:/re2, D:/raa, D:/rc, D:/rf) belong to other sessions.

## Gotchas
- `build_runner --build-filter=…` **deletes every other generated file** in the worktree. Restore them from the index
  (`git status` shows ` D`).
- A fresh worktree needs `npm ci` in `web/`, for F05's tiptap packages.
- Docker Desktop must be running for the backend integration tests (Testcontainers). It was down after the restart and
  I started it at about 11:40.
- The unowned shared-tree edits are kept as a patch in readin-8e's scratchpad
  `C:\Users\YOUSSE~1\AppData\Local\Temp\claude\f487b025b3d41328\12d13fe5-ddc9-4dcd-942a-e48f61711d49\scratchpad\merge\stray-edits.patch`.

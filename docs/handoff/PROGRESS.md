# Progress: consolidation and remaining Phase 1 work

The user's plan of 2026-11-04. The main session is the only session working on ReadIn. Update this file after every step,
so a new session can continue from it.

Rules: never force-push, never touch `main`, never push `ios-*` tags, never commit secrets. Before every push:
- backend: `dotnet build ReadIn.slnx`, then `dotnet test --solution ReadIn.slnx --no-build` (from `backend/`);
- web: lint, unit, build, and Playwright for what changed;
- mobile: `flutter analyze` and all tests, goldens included.

## Step 1: stop the other sessions ✅
Every ReadIn session committed and pushed its own branch and wrote a handoff:

| Session | Branch | Handoff |
|---|---|---|
| readin-8e (formerly readin-f4) | `merge-f09-paths` 4a81208, `f22-moderation` 93f098b | `docs/handoff/dev-consolidation.md` (on `merge-f09-paths`) |
| merg (formerly readin-bd / readin-08) | `f04-reader` 291c566 | `docs/handoff/f04-reader-glossary.md` |
| readin-29 (formerly readin-c2) | `f09-paths` 000912d, `f09-web` 28f275e, `f09-mobile` 82e2a4e | `docs/handoff/f09-learning-paths.md` (on `f09-paths`) |
| readin-5e (formerly readin-4f) | `f17-notifications-handoff` 818414b | `docs/handoff/f17-notifications.md` (F17 design, no code) |
| Desktop session (SPEC and prompts) | none, everything already on dev | F28–F30 are SPEC only: ask the user before building them |

The main session's own branch: `f05-rebase` 8d65cb4 (mobile editor follow-up: atomic mentions, inline structured
blocks, undo/redo).

## Step 2: backup ✅
`D:\readin-backup-2.bundle`, created with `git bundle create --all` after a fetch of every branch. `git bundle verify`
reports a complete history and the bundle holds 56 refs. The older `D:\readin-backup.bundle` is kept.

## Step 3: merge into dev ✅
Order:
1. f04-reader
2. f05-rebase follow-up
3. merge-f09-paths (regenerate LearningPathEnrollments after Glossary)
4. f09-web
5. f09-mobile
6. f22-moderation (regenerate Moderation last; `Visible()` checks; eraser nulls ModerationActions ids)
7. f17 handoff doc

- [x] Shared-tree leftovers. README Firebase lines and the `.gitignore` `docs/design/app-store` line committed in
  670deb1; the README's wrong "Storage rules, CORS" claim was dropped. The temporary `zz_seed_reader_screens_test.dart`
  harness was moved out of the repo. `.claude/` is left alone.
- [x] **f04-reader** merged as 46584b9, cleanly; it already contained dev 2c8ada6 and regenerated the codegen.
  - The merge exposed a real F07 bug: the picker only sorted by language within each relax level, so an English-only
    strict match beat Arabic articles. Fixed in 88d18e6 (language first, then length, then interests, then any
    language), with a test that fails on the old code. Also renamed the stale "wait for a human review" test and fixed
    the SPEC seed-set line.
  - Gates:
    - backend build + 1361/1361;
    - web lint, 628/628 unit, build (initial 511.70 kB, over the existing 500 kB warning), Playwright reader + social
      64/64;
    - mobile build_runner (no diff, so the CI codegen check passes), analyze clean, 1072/1072 including goldens.
  - Pushed as 6bdd666.
- [x] **f05-rebase** follow-up merged as e8051c8: mobile only (editor + l10n); gen-l10n and codegen rerun with no
  diff, analyze clean, 1094/1094.
- [x] **merge-f09-paths** merged as 9140d73. Backend 1388/1388 after c7a4b90 (the F04 neighbour test now publishes its
  path, because F09 made publishing explicit).
  - LearningPathEnrollments regenerated after Glossary as `20261104114414`; the body is identical and the hand-written
    `UPDATE LearningPaths SET IsEditorial = 1` is kept. No pending model changes.
  - Picker: the F09 active path first, then the F07 language-first rule.
  - Backend gate running.
- [x] **f09-web** merged as eddc036, with e2e fixes in 395033e.
  - Reader order: sources → Next in path → related.
  - Unused `ReadingTimePipe` import dropped.
  - Gates:
    - lint, 668/668 unit, build;
    - home screenshots unchanged;
    - full e2e 263/286. The failures were the paths order check and the guest test (fixed for the merged DOM) and
      the related screenshots (1 px, re-rendered). The other 2 were flakes, and their specs passed 44/44 on rerun.
- [x] **f09-mobile** merged as c416417.
  - The router and article page combine F04, F05 and F09.
  - The ARB files keep both sides.
  - build_runner hung twice with no CPU, and its old cache (`.dart_tool/build`, `.dart_tool/build_resolvers`) was the
    cause. Delete both and it builds in about 2 minutes. This build_runner version ignores `--delete-conflicting-outputs`.
  - Gates:
    - analyze clean;
    - 1182/1182, after the 16 home and path goldens were regenerated and viewed in 7a93da7. They predated F05: the review
      badge, and dev's Home.
  - Pushed as 7a93da7, together with the Desktop session's SPEC commit 6d71dc7.
- [x] **f22-moderation** merged as eade767. It was built on dev 8e60f73, before F05, F04, F09 and account deletion.
  - Review stays removed. MarkReviewed, the review pools, the ReviewedBy mapping, `/reviews` and the review endpoints
    were all dropped.
  - Moderation regenerated as `20261104125936`, with an identical body.
  - Deleted authors (`AuthorId` null):
    - no notice is sent;
    - only moderators see their hidden article;
    - the web and mobile menus are null-safe.
  - The eraser anonymizes `Articles.HiddenById` and both `ModerationActions` ids. The deletion test covers this, and
    the §9.6 row is updated.
  - Tag counts skip hidden articles.
  - Gates:
    - backend 1409/1409;
    - web lint, 718/718 unit, build (initial 518.02 kB, still over the 500 kB warning);
    - mobile analyze clean, 1278/1278 including goldens (the merged reader and profile goldens in e26714b, viewed);
    - full Playwright 332/334. Two flakes:
      - The image flow failed with `ECONNRESET`: the mock API closed idle keep-alive sockets after Node's 5 s default.
        It now keeps them 180 s.
      - The PDF flow failed with `attachments.asset_not_ready`: the 8 parallel runs shared one asset id in the mock's
        registry, and a run registering "processing" turned another run's ready asset back. Each run now has its own
        asset id (the same pictures).
      - Both specs passed 72/72 after the fixes (4 repeats).
      - The guest who-reacted test failed once under full-suite load (0 rows within 5 s). It passed 8/8 in isolation and
        its mock is deterministic for guests. To watch in the next full run.
- [x] **f17-notifications-handoff** merged as 8218128 (docs only: `docs/handoff/f17-notifications.md`, the F17 design).
- [x] **f09-paths** handoff doc merged as 58ee834 (`docs/handoff/f09-learning-paths.md`, the only commit not on dev).
- [x] Every other branch checked: its commits are on dev, or are older copies of commits that are (same subject, rebased
  or squashed): f07-daily, f14, f14-backend, f14-web, f14-mobile, f14-pre-f11, live-base, social-backend, social-web,
  social-mobile, f05-editor, account-deletion-pre-squash.
- [x] Not ours, left uncommitted in the shared tree:
  - `docs/SPEC.md` F31/F32: committed by the Desktop session as 6d71dc7;
  - a `.gitignore` line `mobile/test/goldens`, whose author is unknown. It must not be committed: it would hide the
    baselines.

## Step 4: clean up ✅
- All 12 worktrees removed with `git worktree remove` (no `--force`), all of them clean. Git could not delete three
  folders (D:/raa, D:/re, D:/rf) because of Windows' long paths in `mobile/build` and `node_modules`. It had already
  unregistered them, and the leftover files were deleted with `rm -rf`. D:/raa had been kept for the Google sign-in
  device test, which now runs from dev.
- Branches deleted locally and on origin; only `dev` and `main` are left.
  - Merged: account-deletion, auth-v1.1-all, f04-reader, f05-rebase, f08-streaks, f09-paths, f09-web, f09-mobile,
    f11-comments, f14, f17-notifications-handoff, f22-moderation, f27-realtime, merge-f09-paths, wave1.
  - Superseded (older copies of commits that are on dev): f07-daily, f14-backend, f14-web, f14-mobile, f14-pre-f11,
    live-base, social-backend, social-web, social-mobile, f05-editor, account-deletion-pre-squash. Every one of them is
    in `D:\readin-backup-2.bundle`.
  - No branch had to be kept.
- `CLAUDE.md` (new) and SPEC §29: all work happens directly on `dev` in `D:\freelancer\ReadIn`, with no new branches or
  worktrees (agents too). Commit only your own files, by path.
- `tools/locks/lock.mjs` exists but no hook enforces it. Installing a hook needs `.claude/settings.json`, which is left
  alone.

## Step 5: screenshots only in ar/light and en/dark ✅
- Web: `hasScreenshot(variant)` in `e2e/support/mock-api.ts` guards every `toHaveScreenshot`. The specs still run all
  four variants with every assertion; ar/dark and en/light just take no screenshot. 196 baselines deleted, 196 kept.
- Mobile: `matchesVariantGolden(variant, path)` in `test/helpers/test_app.dart` compares the image for ar/light and
  en/dark. The other two variants still build and lay out each screen, so an exception or an overflow fails them.
  170 baselines deleted, 170 kept.
- SPEC §8.2, §15.5 rule 9, §27, the CI table and the done checklist say so.
- Gates:
  - mobile analyze clean, 1278/1278;
  - web lint clean, e2e type-check clean;
  - full Playwright 304/334. The 30 failures were all in the Pixel 7 project at the end of a run that overlapped a
    heavy repo-wide file search: 1 px full-page height differences and a few timeouts. The same specs (paths, profile,
    reader, social) passed 82/82 when rerun on their own. The next full run is at the Step 6 gate.

## Step 6: remaining work (in progress)

### 6.1 Handoff leftovers ✅
- **F22 merge notes checked:** related, glossary terms, path cards, `ActivePathNext`, continue reading, the feeds and the
  picker all go through `Visible()` or `VisibleTo(viewer)`, so hidden articles stay out.
- **ContentStudio `reviewStatus`** (abb2873):
  - New meta.json files leave it out. The 300 seeded files keep `"pending"`, because editing them would re-import
    every article. The importer ignores it, and any claimed review still fails validation.
  - The seeder no longer reads `reviewedAt` as a publish date.
  - The content README and authoring guide no longer describe a reviewer queue or scheduling.
- **F21: writers mark terms in the editor** (SPEC F21, the F04 handoff):
  - web ff5dddb;
  - mobile ff4a0c1, with a toolbar button and a picker searching `GET /glossary?q=`;
  - selecting a term changes or removes it;
  - mobile works in the main text and in structured-block fields;
  - e2e in all four variants, with screenshots and goldens in ar/light and en/dark.
- **Found and fixed while testing the mobile picker:** the mobile link dialog never applied the link, because AppFlowy
  drops its selection when a dialog takes the focus (ff4a0c1, with a test of the real dialog flow).
- **Related cards stay compact on web**, without attachments, as on mobile (fa3169d).
- **Who reacted (mobile):** a slow answer to an older load can no longer replace the newer list or append a page to it
  (6a9d250). The web sheet already guarded this.
- **Left as they are, by design:**
  - `ArticlePathDto.previous` isn't shown; SPEC F09 has only "Next in path".
  - Resume is approximate across devices; both clients measure the whole scroll range.
  - The admin path screens wait for F23.
- **For the user (not code):**
  - production FCM/RTDB setup: service account, rules deploy, VAPID, Apple Services ID, release SHA-1s;
  - whether to install the lock hook in `.claude/settings.json`.
- **Still open, to look at under "other gaps":**
  - the web initial bundle (518 kB, over the 500 kB warning);
  - two mobile editor limits noted during F05: bidi marks while editing, and list item direction.

### 6.2 F17 Notifications ✅
Built from the contract in `docs/handoff/f17-notifications.md` by three helpers (backend, web, mobile), then reviewed,
re-gated and committed by the main session.
- **Backend** (f6c28dd):
  - tables `Notifications`, `NotificationActors`, `UserNotificationSettings`, and quiet hours on `Users` (migration
    `Notifications`);
  - `NotificationWriter`: never about your own action; `off` / `inApp` / `all`; aggregation per group within 24 h;
    dedupe keys; safe under outbox retries;
  - producers: new follower, comments, replies, comment mentions, reaction milestones, new articles from followed
    writers, security alerts, moderation notices (F22's push now goes through it), daily article, the 20:00 streak
    reminder;
  - `NotificationPushJob`: quiet hours, re-checks before sending, 24 h cutoff, retries, invalid tokens removed;
  - 7 endpoints, the live badge, account deletion, demo notifications (Development only), docs.
- **Mobile** (a111b37):
  - the center, Settings → Notifications and the badge with a REST fallback;
  - push taps mark read;
  - the device-only daily switch moves to the server's `daily_article` mode;
  - new links `/u/{username}/followers`, `/me/stats` (a reading stats page), `/settings?section=account`.
- **Web** (30eb301):
  - `/notifications`, with a "New notifications" button while the page is open;
  - `/settings/notifications`, the badge (live, else REST every 60 s) and the side-nav count;
  - push and toast taps mark read; a new tab gets `?notification={id}`, which is removed before routing;
  - mock API fixtures for `u-notified-*` viewers.
- **Gates:**
  - backend build clean, 1488/1488;
  - web lint clean, 777/777 unit, SSR build OK (initial bundle 524.9 kB, was 518 kB; warning only), full Playwright 366/366 (14.2 min, `--workers=2`), the first fully green run since Step 5;
  - mobile build_runner no diff, analyze clean, 1401/1401 with goldens.
  - New baselines checked by eye: web `notifications-center-*` / `notification-settings-*` (ar-light, en-dark, desktop
    and mobile); mobile `notifications_center_*`, `notification_settings_*`, and the 4 `settings_account*` goldens
    (the daily switch became the "Notification settings" entry).
- **Decisions beyond the contract:**
  - a moderation warning links to `readin://notifications`;
  - `moderation_notice` has no actor;
  - entries whose comment or article is gone drop out of the list and the count;
  - daily-article entries are written only for users with a device (as the F07 job);
  - `readin://me/stats` opens the user's own profile on the web.
- **Open, for "other gaps" or the user:**
  - every new article of the official @readin account notifies its followers, so a content deploy with many articles
    writes one entry per article per follower (pushes collapse per type);
  - mobile's open center doesn't refresh by itself when a notification arrives (pull to refresh does; the web shows a
    button);
  - in Arabic titles a leading-dot word such as ".NET" shows as "NET." on mobile (the shared BiDi helper; it was
    already in the comment goldens);
  - the web bundle is now 524.9 kB.

### 6.3 Mentions in articles, mention notifications, "who can mention me" ✅
Built by three helpers from one contract, then reviewed, re-gated and committed by the main session.
- **The setting** (SPEC F18): `whoCanMention` = everyone (default) / people I follow / nobody, in Settings → Privacy on
  web and mobile. `GET /me` returns it; `PUT /me/privacy` takes either field.
- **One rule everywhere:** A may mention B when B is A, B allows everyone, or B allows people B follows and B follows A.
  B must also be an active account. It applies to:
  - mention suggestions (comments and the editor);
  - comment mentions (create, reply, edit): a handle you may not mention stays plain text, with no link and no
    notification;
  - article publish and Update, in every language version: allowed mentions keep the link, with the user's current
    `@username` (the reader links by that text, so it can't be forged or go stale); the rest become plain text. At most
    20 people per article, as comments have 10 (the lead added this cap).
- **Notifications:** an article mention is a `mention` entry with no comment, once per user per article
  (`mention:article:{articleId}`), so an Update tells only newly mentioned users. Push "X mentioned you in an article"
  with the article title; the clients show the same text. The notification setting is now "Mentions" (comments and
  articles).
- **Commits:**
  - backend fc99162 (migration `MentionPrivacy`);
  - mobile 0fba479;
  - web after it.
- **Gates:**
  - backend 1520/1520;
  - mobile build_runner no diff, analyze clean, 1436/1436 with goldens;
  - web lint clean, 786/786 unit, SSR build OK (524.94 kB), Playwright for profile, notifications, auth, external and
    media-pdf.
  - New and changed baselines checked by eye:
    - web `settings-privacy-*`, `notifications-center-*` and `notification-settings-*`;
    - mobile `settings_privacy_*`, `notifications_center_*`, `notification_settings_*` and `settings_account*` (those
      scroll to the end again).
- **Small differences left on purpose:**
  - the web shows a hint under "Who can mention me"; mobile has none;
  - the web's Arabic comment-mention text now says "عمل لك", as mobile does.

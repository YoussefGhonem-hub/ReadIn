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

### 6.4 F19 Writer verification ✅
Built by three helpers from one contract, then reviewed, re-gated and committed by the main session.
- **Request** (web `/verification`, mobile Settings → Writing → Writer verification): field, job title, proof (an
  https link and/or a PDF/JPEG/PNG/WebP file up to 10 MB, checked by magic bytes on the server) and a note. One pending
  request at a time; withdraw; "Request again" after a rejection (the file must be attached again).
- **Proof files are private:** `IPrivateFileStorage` at `Storage:PrivatePath` (default `App_Data/private`), never in
  `wwwroot`. The API refuses to start when that folder overlaps the web root or the uploads folder. Only the admin
  proof endpoint reads a file (attachment, `no-store`, `nosniff`). The file is deleted once the request is decided,
  withdrawn or the account is deleted; a daily job (`verification-proofs-cleanup`, 03:15 UTC) deletes orphans.
- **Admin queue** (web only, `verification.manage`): `/admin/verification` with Pending / Approved / Rejected, the proof
  shown in the page (images) or a new tab (PDF), approve (grants `VerifiedWriter`, confirmed in a dialog) and reject with
  a reason (5–500). Both go to the audit log.
- **Notification** `verification_result` (`data.approved`, `readin://verification`), with the texts in contract-v1.
- **Lead changes on top:**
  - `backend/src/ReadIn.Api/.gitignore` ignores `App_Data/` (local demo proofs);
  - `docker-compose.yml` has an `api-private` volume, owned by UID 1654;
  - `public/privacy.html` and `public/delete-account.html` list verification requests, proofs and notifications;
  - the web shows short values (job title, link, file name) next to their label in Arabic, isolated in their own
    direction; the note and the reason keep their own direction, as comments do.
- **Commits:** backend 7d21f49 (migration `WriterVerification`), mobile 8eb946d, web 0525054.
- **Gates:**
  - backend 1614/1614;
  - mobile build_runner no diff, analyze clean, 1518/1518 with goldens;
  - web lint clean, 90 unit files passed, SSR build OK (initial 526.15 kB, was 524.94 kB), Playwright 166/166
    (verification, auth, external, profile, notifications).
  - Baselines checked by eye: web `verification-*` and `admin-verification-*` (rewritten with
    `--update-snapshots=all`: the 1% tolerance hides a moved line), mobile `verification_*` and the six Settings goldens
    (a new "Writing" card).
- **Not verified:** a PDF proof opening in a new tab (headless Chromium shows no PDF; the e2e checks the tab opens); the
  API container with the new volume (`docker compose --profile api`).
- **For the user:** set `Storage__PrivatePath` on the server (outside the app folder is safest), back that folder up with
  the database (deployment.md §8), and redeploy `public/` to Firebase Hosting so the updated privacy pages go live.
- **Left for 6.6:** in Arabic, mobile shows ".NET" as "NET." and a mixed Arabic/Latin file name in the wrong order.

### 6.5 F24 Share links and app links ✅ (setup by hand pending)
Built by the main session.
- **Sharing:** the web (already) and now the mobile reader share the article's web URL in the version being read,
  `https://{domain}/{ar|en}/a/{slug}`. The mobile attachment viewer shared `/a/{slug}`, which the web doesn't serve;
  it now shares the same URL.
- **The domain is configuration:** web `siteUrl` (environment.ts), mobile `WEB_ORIGIN` (config/prod.json and dev.json,
  default `https://readin.app`). Android's App Links host is read from the same dart-define by
  `android/app/build.gradle.kts`; a value that isn't an https origin fails the build.
- **Opening links:**
  - Android: the intent filter covers `/ar/a/` and `/en/a/` on that host;
  - the router and push links map `/ar/a/{slug}` and `/en/a/{slug}` to `/a/{slug}?lang=ar-EG|en`, and accept only the
    configured host;
  - the web's SSR server serves `/.well-known/assetlinks.json` (404 until `ANDROID_CERT_SHA256` is set) and
    `/.well-known/apple-app-site-association` (default app id `7A25UFD8VC.app.readin.readin`).
- **iOS:** no code change. The Associated Domains entitlement names the domain and needs the capability on the App ID;
  the steps are in docs/setup/app-links.md.
- **Commits:** mobile 16074e6, web c4abcdf, docs after them.
- **Gates:**
  - mobile build_runner no diff, analyze clean, 1537/1537 with goldens;
  - web lint clean, 834/834 unit (91 files), SSR build OK (initial 526.15 kB, unchanged), full Playwright 420/420
    (15.4 min, `--workers=2`), which also covers 6.4;
  - checked by hand: a debug APK built with a test `WEB_ORIGIN` has that host in the merged manifest, a bad value stops
    the build, and the production SSR build serves both files (JSON, no redirect; a bad fingerprint is logged and
    skipped).
- **Not verified:** a real App Link or Universal Link opening the app (needs the domain, the signing fingerprints and
  the iOS entitlement); no iOS build was run.
- **For the user:** the checklist in docs/setup/app-links.md (domain, `siteUrl`, `WEB_ORIGIN`, `ANDROID_CERT_SHA256`,
  Associated Domains, no redirect on `/.well-known/*`). Release builds are still signed with the debug key.
- **Not built:** the F24 quote card (share a selected quote as an image). It needs your go-ahead.
- **Checked and dropped from 6.6:** mobile's verification screen does show ".NET" and Arabic file names correctly;
  the small screenshots misled me (checked at 4×).

### 6.6 Other gaps ✅ (final gates run together with F34)
Four read-only audits (account/settings/profile/follow; home/reader/editor/lifecycle/daily; reactions/comments/saved/
realtime/offline; attachments and ar/en text) compared the SPEC with the three clients. Built from them:
- **Backend** bb1a0cd:
  - `FieldRefDto.isSensitive` (Medicine, Public Health; a topic carries its field's flag) for the health disclaimer;
  - For you no longer hides articles outside your interests: your interests first, then the rest, newest first within
    each, with a cursor that carries the group (older cursors still work);
  - Arabic and English titles for six `article.*` error codes.
- **Mobile** 942968a and fc66dd8:
  - "New notifications" button while the center is open, as on the web;
  - reader: health disclaimer (also in the editor preview), table of contents from 3 headings, tappable @mentions,
    tags as chips;
  - Settings → Your interests (follow fields and topics after onboarding);
  - preference saves that report failures;
  - guests can't change article language or reminder time (their reader opens the version for the app language);
  - guests see Report in the comment menu;
  - the editor can add or remove a dark-mode image;
  - messages for the missing error codes, plural streak texts, the web's "مصري + EN" label and greeting hours.
- **Web** 5e85997 (committed locally; pushed with F34 after the final gates):
  - reader and editor preview: health disclaimer;
  - Settings → Your interests (chips shared with onboarding);
  - Arabic reading time as a plural;
  - messages for the missing error codes;
  - route titles as i18n keys ("… — ReadIn", following the UI language);
  - plural aria labels, localized file sizes and carousel role descriptions;
  - the reader's Back returns to the previous app page, else Home;
  - 32 baselines refreshed for the reading time, file size and the Settings row.
- **Gates so far:**
  - backend 1645/1645;
  - mobile 1593/1593 with goldens, analyze clean, generated code unchanged;
  - web lint clean, 854/854 unit, SSR build OK (initial 527.65 kB, budget warning only);
  - Playwright: the helper's full run passed 460/460. The lead's run was stopped at 105/460 (no failures so far) to
    start F34; the full suite runs once at the end.
- **Left (small, not done):**
  - the verification form and the admin proof preview still say "KB/MB";
  - seven error codes (`article.translation_*`, `reading.conflict`, `user.*_invalid`) have no server title;
  - mobile onboarding opens at "Step 2 of 3";
  - reading stats sit above the tabs on the web but in About on mobile;
  - mobile doesn't keep saved articles' images for offline use.
- **Needs your decision:**
  - SPEC features that aren't built:
    - F28 mute and "show less" (+ Settings → Muted);
    - F29 repost (+ profile tab);
    - F30 highlights;
    - F31 writer categories;
    - F32 tag pages;
    - F33 article PDF;
    - F24 quote card;
    - F25 offline (cached Today's article, offline queue for reactions and saves, web PWA);
    - F15 Explore and F16 Search (both "coming soon");
    - F23 admin console beyond verification;
  - what the F04 "reading mode toggle" should be;
  - one Arabic term: mobile says "الـ streak / الـ freeze / الـ Tags", the web "السلسلة / التجميد / التاجز";
  - the official @readin account writes one notification per new article per follower: keep it, group it per day,
    or skip it for that account;
  - For you popularity: SPEC F03 says interests + popularity + freshness; today it is interests first, then newest;
  - live PDF status: both clients poll every 2 s (contract-v1 says polling stays), while the SPEC also mentions the
    live signal;
  - the daily upload quota counts only uploads that still exist, so deleting frees the allowance (on purpose in the
    code).
- **Checked and not bugs:** ".NET" in Arabic titles and notification texts on mobile renders correctly (6× crops); the
  "📚" before "المصادر" is an empty box only in goldens (the test emoji font isn't on that text style).

## F34 Post-style feed card ✅
The user approved it on 2026-11-04 (SPEC 2edf779, written by the SPEC session). Built by three helpers in parallel
(backend, web, mobile; no shared files), reviewed and committed by the main session.
- **Backend** 679f348:
  - migration `PostCardExcerpts`: `ArticleTranslations.Excerpt` (≤ 400 chars, cut at a word) and `ExcerptHasMore`,
    computed by `RDocProcessor` on every write;
  - existing rows filled by the `article-excerpts-backfill` Hangfire job, triggered at startup;
  - `ArticleCardDto` adds `excerpt`, `hasMore`, `isFollowingAuthor`, up to 3 `tags` and `tagCount`;
  - `GET /articles/{id}/preview?lang=`: whole blocks up to ~300 words, `isComplete`, the details' visibility, cached
    per article and language.
- **Mobile** 1d3c717 and **web** cc0cc5e:
  - the post card on Home (Today's article labeled, replacing the hero), For you, Following, profile Articles and
    Related articles (this reverses fa3169d);
  - Read more expands in place with the reader's renderer;
  - React, Comment and Share from the card: inline comments on wide web screens, a sheet on phones;
  - state kept on Back (web: Home only; mobile: Home and profile);
  - unsent comments kept;
  - a whole article read in the card counts under the F04 rule.
  The compact row stays in Saved, paths, Next in path and Continue reading. The web's unused Today hero and its spec
  were removed (the post card spec covers the same checks).
- **Not built (other features):** Repost, the repost label and count (F29), mute (F28), tag links (F32). Field pages,
  Explore and Search don't exist yet, so they have no cards.
- **Decisions to know:**
  - Follow stays visible after a tap, showing "Following" so it can be undone;
  - the excerpt follows the article language's direction, and the title its first strong character (SPEC §14.2);
  - the web's whole Home column is now 640 px wide;
  - initial web bundle 533.49 kB (was 527.65 kB): the card's `@defer` parts.
- **Final gates (run once for 6.6 + F34, as the user asked):**
  - backend 1670/1670, no pending model changes;
  - web lint clean, 888/888 unit, SSR build OK (533.49 kB), full Playwright 264/264;
  - mobile build_runner no diff, analyze clean, 1446/1446 with goldens.

## Faster tests (user request, 2026-11-04)
- Playwright runs its flows and screenshots in `ar/light` and `en/dark` only, with 4 workers when the machine is free.
  Mobile goldens likewise; mobile widget and logic tests keep all four combinations, and backend tests are never cut.
- While working: only the tests for what changed (mobile without goldens). The full gates run once per feature before
  pushing (CLAUDE.md "Tests: what to run when"; SPEC §15.5 rule 9 and §27).
- **Times:**

  | Suite | Before | After |
  |---|---|---|
  | Playwright, full | 15.4 min: 420 tests, 4 combinations, 2 workers (last full run, step 6.5). With F34 that suite had 500 tests | 6.0 min: 264 tests, 2 combinations, 4 workers |
  | Mobile `flutter test`, full | 124 s: 1646 tests | 84 s: 1446 tests (all 200 golden images still compared) |
  | Mobile goldens only | 58 s: 400 runs | 32 s: 200 runs |
  | Mobile while working (no goldens) | n/a | 58 s: 1246 tests |

## Completing the SPEC (user request, 2026-11-05)
The user approved the whole remaining list in order: F32, F16, F15, F31, F28, F29, F30, F33, the F24 quote card, F23,
F25, the 6.6 leftovers + the F04 reading mode, the content check's 429, and a final SPEC review. Per feature: backend,
web and mobile helpers (the backend writes the shared contract first, no shared files), then a test agent that only
lists bugs, a fix agent, then the lead reviews, runs the full gates, commits and pushes.

Decisions the user made for this list (2026-11-05):
- reading mode hides the app bar and the action bar, and keeps the text and the progress bar;
- Arabic terms on both clients: "السلسلة", "التجميد", "التاجات";
- the official @readin account: one grouped notification a day per follower;
- For you: your interests first; inside each group, popularity and freshness as in the SPEC, with pages that never
  repeat or skip articles;
- PDF status: polling every 2 s stays (the SPEC follows);
- the daily upload quota counts every upload, deleted ones too;
- the web's initial bundle under 500 kB without removing features.

Later decisions (user, 2026-11-05):
- **Two tracks after F31**, each one feature after the other: track A F28 → F29 → F30 → the F24 quote card; track B
  F33 → F23 → F25. The small leftovers (6.6 + reading mode) come after both tracks, then the final review.
- **Playwright per feature:** only the specs for the screens the feature touched; the full suite only when the user
  asks (CI still runs it). Backend tests are never cut down.
- **Temporary test rule (until the user says otherwise):** per feature the tests run once, after the implementation.
  After the bugs are fixed, no tests run again; only `dotnet build`, `npm run lint`, `npm run build` and
  `flutter analyze` (plus new baselines for the screens a fix changed), then commit and push. A failing GitHub check
  after a push is fixed before the next feature. No test is deleted. So for every feature from F31 on, **the fixes
  were not tried with the tests**.
- **Roles change** (after F28 + F33, before any new feature): Member + SuperAdmin only, Verified is a badge.
- **Pre-production step** (after the roles change, before F30 and the rest of both tracks): profile links + headline,
  the post bar and comments, F29 repost, real seed data, PDF download and the viewer fixes (details below). F29 moves
  from track A into this step; track A continues with F30 → the F24 quote card, track B with F23 → F25.
- **Order after the pre-production step (user, 2026-11-05, one after another):** F30 highlights → the F24 quote
  card → F23 admin console (with the paths and tag management screens, no role management) → the small leftovers
  (incl. the reading-mode button and the web initial bundle under 500 kB) → the final SPEC review. **F25 (offline) is
  postponed by the user:** not built now, and the final review doesn't count it as a gap.

### Content check: HTTP 429 is a warning ✅ (c416c55)
A source whose host still answers 429 after the retries (rfc-editor.org in CI) is a warning, never cached and checked
again next run; `Retry-After` is honoured up to 30 s. Dead links still fail. SPEC §19.3 says so.

### F32 Tags ✅
- **Backend:**
  - migration `Tags`: `NormalizedName` (unique), `IsSystem`, `CreatedById`, `CreatedAt`, `IsHidden`,
    `EmptySince`, `ArticleTags.Position`;
  - `LegacyTagsUpgrade` cleans, re-slugs and merges the old tags once, right after the migrations, on every start
    (seed content's tags become system tags: `taxonomy.yaml` has no tag list, so the SPEC now says so);
  - name rules and limits on save and publish (`tag.invalid`, `article.too_many_tags`, `tag.hidden`,
    `tag.limit`); a publish racing another one on the same new tag retries once instead of failing;
  - `GET /tags?q=`, `/tags/{slug}`, `/tags/{slug}/articles`; cards and details carry `TagRefDto { slug, name }`;
  - `TagCleanupJob` daily (user tags with no articles for 30 days); account deletion nulls `CreatedById` (§9.6).
- **Web and mobile:** tag links on cards and in the reader; the tag page (post cards, paging, empty, 404; web SSR +
  `noindex`, mobile deep links `readin://tags/{slug}` and `https://{host}/tags/{slug}`); the editor tag field
  (chips, suggestions, "Create new tag", max 5, the same rules as the server, server errors on the chip); Arabic says
  "التاجات" / "تاج".
- **Not in this round:** admin rename / merge / hide (F23; hiding must also refresh the cached tag pages and article
  details). Muting (F28) has its seam (`ArticleVisibility.WithoutMutedFor`).
- **Test round:** 8 bugs found and fixed (a query per bad tag name on save, the duplicate-tag race, tatweel-only
  names, web error texts, Arabic symbol lists without isolates, three small mobile ones), plus the legacy upgrade
  running in every deployment path (deployment.md §9).

### F16 Search ✅
- **Backend:** `GET /search` (articles, users, topics, tags) and `/search/suggest`, rate limit `search` (60 a
  minute). Two engines behind one interface, picked at startup: SQL Server Full-Text Search (`CONTAINSTABLE`, every
  word a quoted prefix term) when installed, otherwise an escaped `LIKE`. Migration `SearchFullText` creates the
  catalog and indexes only on a server with full-text. Names, topics and tags use normalized `LIKE` in both engines
  (names aren't stored normalized). Ranking: place (title 1, text 0.6, PDF 0.4) × rank × quality × freshness.
- **SQL image:** `docker/sqlserver/Dockerfile` (2022 + `mssql-server-fts`, ADR 0017): docker-compose builds it
  (port 14333), Testcontainers builds it when missing, and backend CI caches it in the GitHub Actions cache.
- **Web:** `/search` (server-rendered without results, `noindex`), tabs, filters, compact rows ("found in the
  attached PDF"), recent searches, a lazy header combobox with suggestions; Back keeps the list.
- **Mobile:** `/search` from the Explore tab's search bar, the same tabs, filters, states and recent searches.
- **Test round:** 9 bugs fixed (an icon that pulled 24 editor icons into the initial bundle, error texts and labels
  that differed between server, web and mobile, the PDF carousel in mobile search rows, an English tag pushed to the
  wrong side in Arabic, the title-match rule, the CI image rebuild, docs, a missing golden). The reported ".NET" → "NET."
  problem was checked pixel by pixel and isn't real.
- **To know:** the full-text image is ~5 GB and takes ~5 minutes to build the first time; your local SQL container
  needs `docker compose build sqlserver` then `docker compose up -d` (the data volume stays).

### F15 Explore and field pages ✅
- **Backend:** `GET /explore`, `/explore/trending`, `/explore/most-saved`, `/fields/{slug}`,
  `/fields/{slug}/articles?topic=`, `/fields/{slug}/writers`. Trending = 7-day engagement (reads 1, reactions 2,
  comments 4, saves 6, the author's own activity excluded), falling back to quality; Most saved = 30 days then all
  time; Top writers = 90 days of reads and reactions in the field; New writers = first article in the last 30 days.
  Shared parts cached 5 minutes, each caller's state (and suspended/deleted writers) applied after the cache.
  Migration `ExploreFeaturedPaths` (`IsFeatured`, `FeaturedOrder`; editorial paths featured). Development only:
  `DemoWritersSeeder` (six short articles by demo writers so Explore isn't empty), and `DemoUsersSeeder` v5 marks
  the demo users' profiles complete (they were missing from writer lists and people search in the local DB).
- **Web and mobile:** Explore (search bar, every field, the four sections with 3 compact rows + "See all" as post
  cards, empty sections hidden), the field page (Follow field and topic with "keep at least 3 interests", sensitive
  note, topic chips with a ✓ for followed topics, Top writers rail, post cards), 404 and unknown-topic states; web SSR
  with `noindex` / HTTP 404 rules and Back keeping the page; mobile deep links `readin://f/{slug}` and
  `https://{host}/f/{slug}`; `/f/*` in the app links.
- **Test round:** 8 bugs fixed, all web/mobile differences (section names, counts, empty paths row, names not
  following the UI language, the followed-topic mark, copy) plus the contract wording and suspended writers staying in
  cached lists.
- **For the final review:** the writer Follow button says "متابعة" on the web and "تابع" on mobile (F12); Lucide hides
  icons that use `role="img"` + `aria-label` (e.g. the verified badge) from screen readers on the web.

### F31 Writer categories ✅
- **Backend:** migration `WriterCategories` (`WriterCategories` table cascading with the user,
  `Articles.WriterCategoryId` set to null when a category goes, unique slug and normalized name per writer). Routes:
  `GET /users/{username}/categories`, `/users/{username}/categories/{slug}` (+ `_other` for articles without a
  category), `GET/POST /me/categories`, rename, reorder and delete, `PUT /articles/{id}/category` (outside the
  article's version, so it never clashes with autosave). At most 50 per writer, held under a per-user lock so two
  creates at once can't pass it. Counts only count visible articles. Caches carry the writer's tag plus `Feed` and
  `Taxonomy`. Moderation action `clear_category` (the name becomes "قسم n" / "Category n" with a new slug) and
  `ModerationCaseDto.categories`. Account deletion removes the categories, and kept articles lose their category.
  Development only: `DemoCategoriesSeeder`.
- **Web and mobile:** the Categories tab after Articles (visitors see non-empty categories, then "مقالات تانية"; a
  writer with no categories gets the empty state), the owner's manage view (create, rename, reorder by drag or
  move up/down, delete with the article count, empty rows marked "فاضي، والزوار مش شايفينه"), the category page (SSR
  with `noindex` when empty, 404 when missing), the editor picker with "＋ قسم جديد", "في قسم {name}" in the reader,
  moderation "امسح الاسم" with an optional note; deep links `readin://u/{u}/c/{slug}` and `https://{host}/@{u}/c/{slug}`.
  The in-app account-deletion text and `public/delete-account.html` / `public/privacy.html` list writer categories
  (the public pages need redeploying to Firebase Hosting).
- **Category pages don't apply mutes** (like the profile's Articles tab: you open a writer's own pages on purpose).
- **Test round:** the tests ran once (backend 1907/1907, web unit 993/996 with 3 load timeouts that pass alone,
  Playwright for the touched screens 144/144, mobile 1745/1745). 10 bugs fixed, mostly web/mobile differences (error
  texts, the empty tab, the empty-row mark, copy and plurals, moderation), plus the deletion screens, the limit race
  and the unit-test warm-up. **The fixes were not tried with the tests** (user rule); only the builds, lint and
  analyze ran after them.

### F28 Article menu, mute and "show less" ✅ (track A)
- **Backend:** migration `MutesAndFeedback` (`UserMutes`, `ContentMutes`, `ArticleFeedback`). `PUT/DELETE
  /users/{id}/mute` (ends your follow; Undo sends `restoreFollow=true`), `/me/mutes/fields|topics/{id}`, `GET
  /me/mutes`, `PUT/DELETE /articles/{id}/show-less`; writes need `follows.manage`, at most 500 muted writers (held
  under the per-user lock). `ArticleVisibility.WithoutMutedFor` is real now: For you, Following, Today (a muted pick is
  replaced for the rest of the day), Related, Explore, Search (mutes only), field pages (their own field and the picked
  topic stay), tag pages and suggested writers. "Show less" puts the topic (or field) in a last For you tier for 90
  days; a cursor whose tier is gone restarts the last tier. No notifications from muted actors; comments carry
  `isAuthorMuted`; cards and details carry `topic` and the three mute flags; `ProfileDto.isMuted` and
  `isSystemAccount`. Account deletion removes mutes both ways. The writer's own pages (profile tabs, category pages)
  don't hide a muted writer.
- **Web and mobile:** the one "⋯" menu (Show less, Follow, Mute author, Mute topics, Report, then moderator items),
  Mute also on the profile "⋯" and a comment's "⋯", Undo toasts, cards fold away (reduce motion respected) and come
  back on Undo, the topics sheet, the banner (reader and under the profile header), collapsed comments with "عرض",
  Settings → Muted at `/settings/muted` on both, empty states when mutes empty a list. Search rows and writer rails
  don't fold during the session (the next load leaves them out).
- **Test round:** the tests ran once (backend 2069/2076 with the 7 failures in track B's PDF work at the time, web unit
  1063/1063, Playwright for the touched screens 270/270, mobile 1860/1860). 14 bugs fixed (the topics sheet closing
  under a folding card, mobile paging repeats, suggestions, follow vs old mutes, empty states, error texts, deletion
  texts, mute from profile/comments, one route, one menu order, Explore rows, one wording, the For you tier cursor,
  14 more backend tests). **The fixes were not tried with the tests** (user rule).

### F33 Download article PDF ✅ (track B)
- **Backend:** `GET /articles/{id}/pdf?lang=` (permission `articles.export_pdf`, owner only, the published version
  even with a working copy; 404 for anyone else, 409 hidden, 503 busy after 30 s, 500 after 60 s, 429 at 10 an hour per
  API instance). RDoc → fully encoded print HTML with the web's BiDi rules (shared fixtures), embedded IBM Plex Sans
  Arabic / Plex Sans / JetBrains Mono / Noto Sans / Noto Color Emoji (COLRv1) / Noto Sans Symbols 2 / Noto Sans Math
  (OFL, licenses shipped), the logo, images from the uploads folder by stored path (external images print as link
  cards). PuppeteerSharp drives an installed Chromium (never downloaded): JavaScript off, sandbox on, every request
  aborted, at most 2 builds; a timed-out build closes only its own page, Chromium restarts only when it crashed.
  Tagged PDF, H2/H3 bookmarks, metadata (an appended update adds the author and fixes mixed bookmark titles), Western
  digits, the AI-assisted label, page-break CSS for rule 4, tables measured with the real fonts so words never split.
  Tests for every No-bug rule (PdfPig: fonts embedded, text order, links, metadata, bookmarks, no blank pages, size;
  two page baselines, one Arabic and one English).
- **Web and mobile:** "تحميل PDF" in the reader's "⋯" (own article only, before Report) and on every published row in
  My articles (two languages ask which first); "بنجهز الـ PDF…" while building; errors per the contract with "حاول
  تاني" where it helps; web downloads with the server's file name, mobile saves to a temp file and opens the share
  sheet. The item is on the reader's menu only, not on feed post cards.
- **Deployment (user to do before production):** the API image needs Chromium (docs/setup/deployment.md §10: a Debian
  aspnet base image with `apt install chromium`, `ContainerBaseImage` on publish, proxies allowing 100 s), and the
  `seed` command must run once so Members get `articles.export_pdf` (until the roles change makes the sync run on
  every start).
- **Not verified here:** the backend tests on CI's Linux runner use its preinstalled Chrome; the two PDF page
  baselines were approved on Windows with Chrome 156 (re-approve with `READIN_PDF_BASELINES_DIR` if CI differs).
- **Test round:** the tests ran once (backend 2077/2077, web unit 1063/1063, Playwright article-pdf + editor 40/40,
  mobile 1860/1860). 9 bugs fixed (emoji font left out, one failed build killing the other, split words in wide
  tables, the AI label, the iPad share anchor on retry, wording, symbol fallback, code indentation, the permission
  note), then the reader menu item. **The fixes and the menu item were not tried with the tests** (user rule).

### CI repairs before the roles change ✅ (8ffc853, e0e5337, a1e4cfb)
- Backend: PDFs on CI's Ubuntu 24.04 need a user namespace for Chrome's sandbox; CI pins Chrome for Testing and gives
  only that binary an AppArmor `userns` profile (deployment.md §10 has the production side).
- Mobile: a mute widget test awaited a cubit's `close()` inside `testWidgets`; that close finished outside the fake
  clock, so the test hung forever (no timeout) and stalled the whole CI job. The old cubit now closes in a tear-down.
- Mobile goldens: the Explore and tag page goldens printed "N days ago" from the real clock; they pin it now.

### Roles change: Member + SuperAdmin, Verified is a badge ✅ (user decision, 2026-11-05)
- **Roles:** only `Member` and `SuperAdmin` (`Guest` = not signed in). Admin, Moderator, VerifiedWriter and
  `roles.manage` are gone; endpoints and both clients check permissions, never role names (ADR 0018). The SuperAdmin
  does what Admin and Moderator did. The startup role seeder brings any database to this state.
- **Badge:** `Users.IsVerified` + `VerifiedAt`. Approving a request sets them only (the user stays a Member);
  `DELETE /admin/users/{id}/verification` removes a badge (`409 verification.not_verified`, `409
  verification.system_account` for @readin, audit `admin.verification_removed`, no notification); the web's admin
  queue has "شيل التوثيق" on approved requests. `isVerified` everywhere reads the column; suggestions and people search
  still rank verified writers first.
- **Migration** `VerifiedBadgeAndTwoRoles`: VerifiedWriter holders get the badge (dated by their latest approval),
  the three roles go, accounts left with no role become Members, @readin keeps the badge. It also works as a SQL
  script (data steps through `EXEC`), checked with sqlcmd up, up again, down, down again.
- **Admin reset:** refused when the target holds a permission the caller lacks, so only a SuperAdmin resets a
  SuperAdmin.
- **Demo:** the demo admin (+12025550102) and moderator (+12025550103) are gone from the seed and both sign-in panels;
  their demo data belongs to the SuperAdmin. On an existing local database they become plain Members.
- **Not done here:** SPEC §10.1 says the badge gives priority in feeds, but no feed has ever ranked by it (only
  suggestions and search). It goes with the For you ranking work (leftovers).
- **Test round:** the tests ran once (backend 2125/2125, web unit 1086/1086, Playwright verification + moderation +
  categories 74/74, mobile 1907/1907 with goldens). 7 bugs fixed (the migration failing as a SQL script, @readin's
  badge removable, the web keeping a removed badge until reload, wording, the SPEC endpoint list, a demo panel label).
  **The fixes were not tried with the tests** (user rule).

### Pre-production step ✅ (user decisions, 2026-11-05)
Before F30 and the rest of both tracks, in one step on web, mobile and backend (six builders, then one test round,
then two fixers). Per part, what was built and **what was actually tried**:
- **Profile title and social links (F14, F34):** `Users.Headline` (≤ 120, one line) under the name on cards, the
  reader, comments and the profile; `links` is an ordered list of `{ platform, url, label }` (14 platforms + Other,
  ≤ 8, one per platform, https on the platform's own hosts), old links migrated; the SuperAdmin clears either from a
  user's case (`clear_links` / `clear_headline`, audited). One bundled icon set on both clients (Simple Icons, CC0;
  LinkedIn from 10.4.0). Tried: the links migration as a SQL script on old-shape rows (up, up again, down, up); the
  editor flows clicked through on web; the mobile edit screen's accessibility tree (a merged control found and fixed);
  a title in the other script keeps its start (Chromium repro before/after).
- **Post bar and reactions (F34, F10):** icons only, counts beside them (none at 0), accessible names with the count;
  the floating reactions bar on hover/keyboard (web, CSS only) and long press + slide (mobile, an overlay), staggered,
  the one under the pointer grows, a short pick animation, instant under reduce motion. Tried: hover, keyboard, pick
  and reduced motion in Playwright (32 tests); long press, slide and lift in widget tests and goldens.
- **Comments (F11):** the box (avatar, rounded field, emoji picker — a 7 kB lazy chunk on web, `emoji_picker_flutter`
  on mobile — and a send icon disabled until there is text), the reply box with ✕, rows with the title, Follow
  (`isFollowingAuthor`) and ⋯; Reply inserts a real `@username` with the caret after it, none on yourself; a mention
  the target doesn't allow is dropped silently and the reply notification still goes out. Tried: emoji insert at the
  caret, reply mention and caret, follow from a row (Playwright and widget tests).
- **F29 Repost in full:** `PUT`/`DELETE /articles/{id}/repost`, `reposts.create`, the live counter, the Following feed
  (once per article at the later of publish and the newest followed repost, labeled, stable cursor, one `UNION ALL`
  with no per-article subquery, covering index on reposts), the Reposts tab, `article_reposted` grouped per article,
  mutes, account deletion, counter rebuild. Tried: the handler's SQL against a scratch DB with and without a cursor.
- **No demo articles, real seed (§18):** every article is @readin's from `content/articles`; DemoWriters/Media/
  Editor/Categories seeders removed; "Verified Writer" (+12025550106) removed, also from existing local databases
  (through the account eraser); a Development-only cleanup deletes exactly the 11 old demo articles. Tried for real: a
  **Production seed on an empty database**: 300 articles = 300 published in content, all by @readin, 0 attachments /
  documents / PDF pages, 2 users (readin, superadmin), 0 reactions, comments, saves, reads, reports, follows, reposts,
  notifications, @readin verified with its title; and the Development seed on a copy of the local database (exactly the
  11 demo articles removed, the 302 @readin article ids unchanged).
- **PDF download (F26):** Allow download on by default (API default and both composers); a download icon in the PDF
  strip on the card and in the viewer. Tried: real downloads on web (`%PDF-` checked in Playwright) and on mobile (Dio
  with a fake server, a real temp file, then the share sheet).
- **Viewer return (F26):** web's cause found: closing the viewer's history entry fired a popstate that the router
  treated as a same-URL navigation and scrolled to the top (8492 → 0). `ViewerAwarePlatformLocation` keeps those moves
  away from the router; a Playwright test closes with ✕, Esc and Back far down the feed. Mobile had no bug (the viewer is
  a see-through page over the feed); a widget test closes four ways about 2000 px down and checks position and focus.
- **Migrations as SQL scripts:** the new migrations and four older ones (ReadingStats, LearningPathEnrollments, Tags,
  ExploreFeaturedPaths) now work in a full idempotent script; tried on an empty database with `sqlcmd -I -b` (27
  migrations, run twice). deployment.md says to run scripts with `sqlcmd -I`.
- **Test round:** the tests ran once (backend 2224/2224, web unit 1226/1226, Playwright 26 specs 339/368 with 21
  baselines to regenerate and 8 stale feed-card checks, mobile 2062/2064 with 2 goldens for the new default). 11 bugs
  fixed (title cut at the wrong end on web, script-unsafe old migrations, deletion and privacy texts, two icon sets, an
  e2e mock that hid the owner's Download, stale feed-card checks, a reposter text, the Following query, the old
  account in local databases, wording); 60 web baselines and 9 mobile goldens rewritten and looked at.
  **The fixes were not tried with the tests** (user rule).
- **For the user:** redeploy `public/` (delete-account and privacy pages changed). The two SPEC nits found here (§18.2 row 10, the
  F29 notification name) were fixed by the SPEC session (6f42aa1). The web initial bundle is 554 kB
  (target < 500 kB, leftovers).

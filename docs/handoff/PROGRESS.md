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

## Step 3: merge into dev (in progress)
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
- [ ] Not ours, left uncommitted in the shared tree:
  - `docs/SPEC.md` F31/F32: committed by the Desktop session as 6d71dc7;
  - a `.gitignore` line `mobile/test/goldens`, whose author is unknown. It must not be committed: it would hide the
    baselines.

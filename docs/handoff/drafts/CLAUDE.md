# ReadIn: rules for Claude Code sessions

Several Claude Code sessions work in this repo at the same time, in the same folder. These rules keep them from
overwriting each other. The product and technical spec is [docs/SPEC.md](docs/SPEC.md); §29 holds the same Git rules.

## One branch, one folder
- Every session works directly on `dev` in `D:\freelancer\ReadIn`. Don't create branches or worktrees, and don't start
  agents with worktree isolation.
- `main` is production: never commit or push to it. Never push `ios-*` tags.
- The folder is shared, so never run `git stash`, `git reset`, `git rebase`, `git checkout <branch>`, `git switch` or
  `git clean`. They change or discard other sessions' work.

## Lock a file before you edit it
- Edit and Write lock the file for your session automatically: a PreToolUse hook in `.claude/settings.json` runs
  [`tools/locks/lock.mjs`](tools/locks/lock.mjs).
- If another session holds the lock, the hook waits up to 2 minutes for that session to commit the file. If it is still
  locked after that, the edit is refused: wait until that session commits it, then retry. Don't work around a lock, for
  example by editing through the shell or by copying the file.
- Your locks are released when you commit those files (a PostToolUse hook after `git commit`). A lock on a file that has
  no uncommitted changes expires after 2 minutes.
- Edit tracked files with Edit or Write, not through the shell. Before a generator rewrites tracked files (an EF
  migration, `build_runner`, `flutter gen-l10n`, `npm install`), lock them first:
  `node tools/locks/lock.mjs lock <paths> --session <your session id>`. The id is in the note shown when the session starts.
- One EF migration at a time: lock `backend/src/ReadIn.Infrastructure/Persistence/Migrations/AppDbContextModelSnapshot.cs`
  before `dotnet ef migrations add`, and keep it locked until the migration is committed.
- `node tools/locks/lock.mjs status` lists the locks. Only the user frees a lock left by a session that is gone:
  `node tools/locks/lock.mjs release <path> --force`.

## Commits
- Commit only your own files, by path: `git commit -m "feat(web): ..." -- <path> <path>`. Never `git add -A`,
  `git add .` or `git commit -a`.
- Conventional Commits with a scope (SPEC §29). Push `dev` after the feature passes its quality gates. Never force-push.
- If a push is rejected, stop and tell the user. Don't rebase, reset or merge to get past it.
- Never commit secrets: `google-services.json`, `GoogleService-Info.plist`, service-account keys, `SIWA_KEY_BASE64`,
  anything under `_Docs/`.

## Shared build outputs
- Builds and tests share `bin/`, `obj/`, `node_modules/` and `.dart_tool/`. A "file in use" or locked-output error
  usually means another session is building: wait and retry.
- Web e2e tests use the fixed ports 4280 and 5180. Run them only when no other session's e2e run is active.

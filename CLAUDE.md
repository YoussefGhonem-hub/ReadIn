# ReadIn: rules for Claude Code sessions

The product and technical spec is [docs/SPEC.md](docs/SPEC.md). Its §29 holds the same Git rules. What is in progress
and what is next is in [docs/handoff/PROGRESS.md](docs/handoff/PROGRESS.md).

## One branch, one folder
- All work happens directly on `dev` in `D:\freelancer\ReadIn`. Don't create branches or worktrees. Agents work there
  too: never start an agent with worktree isolation.
- `main` is production: never commit or push to it. Never push `ios-*` tags. Never force-push.
- Another session may be working in the same folder, so never run `git stash`, `git reset`, `git rebase`,
  `git checkout <branch>`, `git switch` or `git clean`. They change or discard other people's work.

## Commits
- Commit only your own files, by path: `git commit -m "feat(web): ..." -- <path> <path>`. Never `git add -A`,
  `git add .` or `git commit -a`. Leave other people's uncommitted changes as they are, and leave `.claude/` alone.
- Conventional Commits with a scope (SPEC §29). Push `dev` once the work passes its gates. If a push is rejected because
  `dev` moved, `git pull --no-rebase` (a merge), run the gates again and push.
- Never commit secrets: Firebase Admin keys, `google-services.json`, `GoogleService-Info.plist`, `SIWA_KEY_BASE64`,
  passwords and PINs, anything under `_Docs/`. `_Docs/BRD.md` and the root `index.html` stay out of git.
- Demo users and demo data are seeded only into the emulators and the local database, never into the real Firebase
  project.

## Gates before every push
- **Backend**, from `backend/`: `dotnet build ReadIn.slnx`, then `dotnet test --solution ReadIn.slnx --no-build`.
  `dotnet test tests/X` runs zero tests here. Docker must be running (Testcontainers SQL Server). Keep SQL Server on host
  port 14333.
- **Web**: `npm run lint`, `npm test`, `npm run build` (SSR), and Playwright for what changed. When another e2e run is
  active, use other ports: `E2E_APP_PORT=4310 E2E_MOCK_PORT=5310 npx playwright test …`. Under load, use `--workers=2`.
- **Mobile**: `flutter analyze` and `flutter test`, goldens included. Generated code must match
  `dart run build_runner build` (CI checks it).
- Fix failures. Never skip, delete or weaken a test to make it pass.

## Generated code and migrations
- EF migrations: one at a time. Generate on top of `dev`'s latest snapshot (`dotnet ef migrations add <Name> --project
  src/ReadIn.Infrastructure --startup-project src/ReadIn.Api --output-dir Persistence/Migrations`), and never hand-merge
  `AppDbContextModelSnapshot.cs`. Carry hand-written `migrationBuilder.Sql(...)` lines over by hand.
- `build_runner` can hang with no CPU on a stale cache. Delete `mobile/.dart_tool/build` and
  `mobile/.dart_tool/build_resolvers`, then run it again; a full build takes about 2 minutes.
- After editing `.arb` files, run `flutter gen-l10n`.

## Shared build outputs
- Builds and tests share `bin/`, `obj/`, `node_modules/` and `.dart_tool/`. A "file in use" error usually means another
  build is running: wait and retry.
- If several sessions ever work at once, `tools/locks/lock.mjs` can lock files (`lock <paths> --session <id>`,
  `status`, `release`). It is not enforced by a hook.

# ReadIn

> **ReadIn — مقال كل يوم يفرق معاك**
> *Read daily. Grow daily.*

ReadIn منصة لنشر وقراءة المقالات المعرفية بالعربي والإنجليزي، بتساعدك تقرا كل يوم مقال في المجال اللي بتحبه وتزود معلوماتك.

ReadIn is a bilingual (Arabic + English) knowledge platform that helps you read one valuable article every day in the field you love.

## Highlights
- Mixed Arabic/English articles that never break the layout (per-block direction, code always LTR).
- Daily article at your chosen time, streaks and learning paths.
- Verified writers, reviewed articles, sources and tested code.
- Every article in two versions: Egyptian Arabic + English terms, and English only.
- Every feature on **Web and Mobile**, in **Arabic and English**, in **Light and Dark** mode.

## Tech Stack
| Part | Stack |
|---|---|
| Backend | .NET 10 · ASP.NET Core · Clean Architecture · CQRS (Mediator) · Mapster · EF Core · SQL Server · Hangfire |
| Web | Angular 22 (SSR) · Signals · Tailwind CSS v4 · Transloco · Shiki |
| Mobile | Flutter · flutter_bloc · get_it/injectable · go_router · dio/retrofit |
| Platform | Phone + password, Google or Apple sign in with the API's own JWT ([ADR 0007](docs/adr/0007-phone-password-authentication.md), [ADR 0012](docs/adr/0012-google-and-apple-sign-in.md)) · Firebase Cloud Messaging + Realtime Database ([ADR 0008](docs/adr/0008-firebase-scope-fcm-and-rtdb.md)) |

## Repository Structure
| Folder | Content |
|---|---|
| [`docs/`](docs) | [Product & Technical Specification](docs/SPEC.md), [API contract](docs/api/contract-v1.md), [ADRs](docs/adr), [approved designs](docs/design) |
| [`design/`](design) | Design tokens (light + dark) shared by web and mobile |
| [`tools/`](tools) | `tokens/build.mjs`: generates web CSS variables and the Flutter `ThemeExtension` from the tokens |
| [`shared/`](shared) | RDoc article format schema and examples, BiDi test fixtures |
| [`backend/`](backend) | ASP.NET Core API (Clean Architecture) + ContentStudio CLI |
| [`web/`](web) | Angular web app |
| [`mobile/`](mobile) | Flutter mobile app |
| [`content/`](content) | Taxonomy, glossary, learning paths and seeded articles |
| [`firebase/`](firebase) | Realtime Database rules (emulator config and the `live` database target in `firebase.json` / `.firebaserc`) |
| [`.github/`](.github/workflows) | CI: backend, web, mobile, content |

📄 **Start here:** [docs/SPEC.md](docs/SPEC.md). Section numbers (§) in the code and docs refer to it.

## Local setup

**Prerequisites:** .NET SDK 10, Node 24, Flutter 3.44+, Docker, Firebase CLI (+ Java 21 for the Realtime Database emulator).

```bash
# 1. SQL Server 2022 (host port 14333) + Seq (http://localhost:5341)
docker compose up -d

# 2. Optional: Firebase emulators for live updates (project "demo-readin", UI at http://127.0.0.1:4000; docs/setup/firebase.md §9).
#    Sign in works without them.
firebase emulators:start --only auth,database

# 3. Demo user password (never committed, SPEC §18.1). Without it demo users can't sign in.
dotnet user-secrets set "Seed:DemoPassword" "<choose-a-password>" --project backend/src/ReadIn.Api
#    Demo recovery PIN: 4 digits, not weak (no 1234, 1111, years…). Without it demo users must set a PIN after signing in.
dotnet user-secrets set "Seed:DemoPin" "<4-digit-pin>" --project backend/src/ReadIn.Api

# 4. API on http://localhost:5080. Applies migrations and runs all seeders in Development.
#    API docs: http://localhost:5080/docs · Hangfire: http://localhost:5080/hangfire
dotnet run --project backend/src/ReadIn.Api

# 5. Web on http://localhost:4200
cd web && npm ci && npm start

# 6. Mobile (flavors and defines: mobile/README.md)
cd mobile && flutter pub get && flutter run --dart-define-from-file=config/dev.json
```

Sign in with any seeded account (SPEC §18.3) and the demo password, e.g. `+12025550110` (reader1), `+12025550106` (verified writer), `+12025550104` (.NET reviewer), `+12025550102` (admin) or `+12025550101` (SuperAdmin). These are fictional 555-01XX numbers. `+12025550119` (reader10) has no PIN and shows the mandatory "set PIN" screen.

> Port 1433 is often taken by a locally installed SQL Server, so the container is published on **14333**.

## Common tasks

| Task | Command |
|---|---|
| Backend tests (unit + architecture + integration via Testcontainers) | `cd backend && dotnet test --solution ReadIn.slnx` |
| New EF migration | `cd backend && dotnet ef migrations add <Name> --project src/ReadIn.Infrastructure --output-dir Persistence/Migrations` |
| Seed in production | `dotnet run --project backend/src/ReadIn.Api -- seed` (`--force` re-runs every seeder) |
| Validate content (SPEC §19.3) | `cd backend && dotnet run --project src/ReadIn.ContentStudio -- validate --all` |
| Import content into the database | `cd backend && dotnet run --project src/ReadIn.ContentStudio -- import` |
| Regenerate design tokens | `node tools/tokens/build.mjs` (CI fails when the generated files are stale) |
| Web tests / build | `cd web && npm test && npm run build` |
| Mobile analyze / tests | `cd mobile && flutter analyze && flutter test` |

## Status

**Phase 0 (Foundation) is done,** and the first Phase 1 slice runs end to end on all three platforms.

| Area | State |
|---|---|
| Design tokens → CSS variables + Flutter `ThemeExtension` | ✅ generated from `design/tokens.json` |
| RDoc schema + examples + BiDi fixtures | ✅ shared by backend, web and mobile tests |
| Backend skeleton (Domain / Application / Infrastructure / Api / ContentStudio) | ✅ |
| Phone + password / Google / Apple auth (JWT, rotating refresh tokens, recovery PIN, account linking), SQL-backed roles & permissions | ✅ backend |
| Seeders: roles & permissions, taxonomy, system accounts, demo users, articles | ✅ |
| Seeders: glossary, learning paths, demo interactions | ⏳ arrive with F21 / F09 / F10–F13 |
| Outbox + Hangfire (immediate trigger + per-minute safety net), scheduled publishing | ✅ |
| F27 Real-time: `POST /realtime/token` (Firebase custom tokens), RTDB publisher with retry + circuit breaker (article counters, comment events, feed, unread badge, PDF status), "new articles" signal on publish | ✅ backend · web + mobile listeners in place; counters, comment events and the badge go live as F10–F13 and F17 publish them |
| Endpoints: auth sync, me, preferences, interests, devices, fields/topics, article by slug, create/publish, for-you feed, today's article | ✅ |
| F01 Auth, F02 Onboarding, F03 Home, F04 Reader (subset), F18 Settings: web + mobile | ✅ first slice |
| F08 Streaks & reading stats + the F04 "read" rule (≥ 70% and ≥ 30 s, [ADR 0013](docs/adr/0013-reading-days-and-streaks.md)): web + mobile + backend, demo reading history | ✅ |
| F05 Editor, F10 Reactions, F11 Comments, F12 Follow, F13 Saved, F14 Profile | ⏳ next |
| ContentStudio `generate` (Claude), code-compile and live-link checks | ⏳ |
| Full-text search index (needs FTS in the SQL image), SignalR, FCM sending | ⏳ Phase 2 |

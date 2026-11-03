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
| Platform | Firebase Auth · Cloud Messaging · Storage |

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
| [`firebase/`](firebase) | Storage rules (emulator config in `firebase.json` / `.firebaserc`) |
| [`.github/`](.github/workflows) | CI: backend, web, mobile, content |

📄 **Start here:** [docs/SPEC.md](docs/SPEC.md). Section numbers (§) in the code and docs refer to it.

## Local setup

**Prerequisites:** .NET SDK 10, Node 24, Flutter 3.44+, Docker, Firebase CLI (+ Java 17 for the emulators).

```bash
# 1. SQL Server 2022 (host port 14333) + Seq (http://localhost:5341)
docker compose up -d

# 2. Firebase Auth + Storage emulators (project "demo-readin", UI at http://127.0.0.1:4000)
firebase emulators:start

# 3. Demo user password (never committed, SPEC §18.1). Without it demo users can't sign in.
dotnet user-secrets set "Seed:DemoPassword" "<choose-a-password>" --project backend/src/ReadIn.Api

# 4. API on http://localhost:5080. Applies migrations and runs all seeders in Development.
#    API docs: http://localhost:5080/docs · Hangfire: http://localhost:5080/hangfire
dotnet run --project backend/src/ReadIn.Api

# 5. Web on http://localhost:4200
cd web && npm ci && npm start

# 6. Mobile (flavors and defines: mobile/README.md)
cd mobile && flutter pub get && flutter run --dart-define-from-file=config/dev.json
```

Sign in with any seeded account (SPEC §18.3), e.g. `reader1@readin.test`, `writer.verified@readin.test`, `reviewer.dotnet@readin.test` or `admin@readin.test`, using the demo password.

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
| Firebase auth (emulator in dev), SQL-backed roles & permissions | ✅ |
| Seeders: roles & permissions, taxonomy, system accounts, demo users, articles | ✅ |
| Seeders: glossary, learning paths, demo interactions | ⏳ arrive with F21 / F09 / F10–F13 |
| Outbox + Hangfire (immediate trigger + per-minute safety net), scheduled publishing | ✅ |
| Endpoints: auth sync, me, preferences, interests, devices, fields/topics, article by slug, create/publish, for-you feed, today's article | ✅ |
| F01 Auth, F02 Onboarding, F03 Home, F04 Reader (subset), F18 Settings: web + mobile | ✅ first slice |
| F05 Editor, F10 Reactions, F11 Comments, F12 Follow, F13 Saved, F14 Profile | ⏳ next |
| ContentStudio `generate` (Claude), code-compile and live-link checks | ⏳ |
| Full-text search index (needs FTS in the SQL image), SignalR, FCM sending | ⏳ Phase 2 |

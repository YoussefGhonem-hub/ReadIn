# ReadIn

> **ReadIn — مقال كل يوم يفرق معاك**
> *Read daily. Grow daily.*

ReadIn منصة لنشر وقراءة المقالات المعرفية بالعربي والإنجليزي، بتساعدك تقرا كل يوم مقال في المجال اللي بتحبه وتزود معلوماتك.

ReadIn is a bilingual (Arabic + English) knowledge platform that helps you read one valuable article every day in the field you love.

## Highlights
- Mixed Arabic/English articles that never break the layout (per-block direction, code always LTR).
- Daily article at your chosen time, streaks and learning paths.
- Verified writers, mandatory sources and tested code; anyone can publish (no review, [ADR 0015](docs/adr/0015-open-publishing-and-the-editor.md)).
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
| [`firebase/`](firebase) | Realtime Database rules (emulator config and the `live` database target in `firebase.json`; `.firebaserc` aliases: `default` = emulator, `prod` = the real project) |
| [`.github/`](.github/workflows) | CI: backend, web, mobile, content |

📄 **Start here:** [docs/SPEC.md](docs/SPEC.md). Section numbers (§) in the code and docs refer to it.

## Local setup

**Prerequisites:** .NET SDK 10, Node 24, Flutter 3.44+, Docker, Firebase CLI (+ Java 21 for the Realtime Database emulator).

Local development and all tests run against the **Firebase Emulator Suite**; the one real Firebase project is only for the deployed app. To create and connect it, follow [docs/setup/firebase.md](docs/setup/firebase.md).

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

Sign in with any seeded account (SPEC §18.3) and the demo password, e.g. `+12025550110` (reader1), `+12025550106` (verified writer), `+12025550104` (.NET writer), `+12025550102` (admin) or `+12025550101` (SuperAdmin). These are fictional 555-01XX numbers. `+12025550119` (reader10) has no PIN and shows the mandatory "set PIN" screen.

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
| Seeders: demo interactions (reactions, saves, follows, a collection), demo comment threads (F11) and demo editor drafts + revision history (F05); deterministic, local only | ✅ |
| Seeders: glossary (F21: 500+ terms from `content/glossary/*.yaml`, plus the index of which articles use each term) | ✅ |
| Seeders: learning paths (editorial, from `content/taxonomy.yaml`) and demo path enrollments (local only) | ✅ |
| Outbox + Hangfire (immediate trigger + per-minute safety net), hourly article quality score (ranks Today's article) | ✅ |
| F27 Real-time: `POST /realtime/token` (Firebase custom tokens), RTDB publisher with retry + circuit breaker (article counters, comment events, feed, unread badge, PDF status), "new articles" signal on publish | ✅ backend · web + mobile listeners in place; article counters are live with F10/F13, comment events with F11, the unread badge with F17 |
| F07 Daily article: Hangfire job picks 30 min before each user's reminder time and sends one FCM push at it (ar/en); the tap opens the reader on web + mobile | ✅ |
| Endpoints: auth sync, me, preferences, interests, devices, fields/topics, article by slug, editor (drafts, autosave, publish/update, revisions), for-you feed, today's article | ✅ |
| F01 Auth, F02 Onboarding, F03 Home, F04 Reader (subset), F18 Settings: web + mobile | ✅ first slice |
| F08 Streaks & reading stats + the F04 "read" rule (≥ 70% and ≥ 30 s, [ADR 0013](docs/adr/0013-reading-days-and-streaks.md)): web + mobile + backend, demo reading history | ✅ |
| F10 Reactions, F12 Follow, F13 Saved: reactions/saves on every card, reader action bar, who reacted, Following feed + suggested writers, Saved page with collections (offline copies on mobile), counters recomputed by the outbox and live (F27), admin counter rebuild, demo interactions | ✅ web + mobile + backend |
| F14 Profile: `/@{username}` (web, server-rendered) and the Profile tab + `/u/{username}` (mobile) with Articles / Saved / Paths / About tabs, stats (articles, followers, following, total reads), reading stats card + heatmap when public, edit profile (square avatar upload 64–512, up to 5 fields of expertise), followers / following lists with search, Settings → Privacy, demo profiles | ✅ web + mobile + backend |
| F11 Comments & replies: threads (one reply level), likes, @mentions, author pin, live updates, report + moderator hide/unhide/delete, flood limits, "Deleted user": web + mobile + backend, demo threads | ✅ |
| F26 Post attachments & media: 1–10 images or one PDF per post, responsive image variants, PDF page previews, carousel + full-screen viewer, composer attachment bar: web + mobile + backend | ✅ |
| F04 Reader, the rest: related articles at the end (topic → field → shared tags and terms; your own skipped, read ones last), resume where you left off with "Start over", glossary taps open a definition sheet (F21: Arabic + English, articles that use the term), `GET /glossary?q=` for the editor: web + mobile + backend | ✅ · "Next in path" comes with F09, "Report article" with F22, marking terms in the editor after F05 |
| F05 Editor: block editor (every RDoc block, slash menu, markdown shortcuts, per-block direction; Tiptap on web, AppFlowy on mobile), language versions, cover, tags, sources, attachments, autosave every 10 s + device backup + conflict handling, live checks, preview, publish/Update, private working copy of published articles, revision history with restore, "My articles" (drafts / published), demo drafts. No review and no scheduling ([ADR 0015](docs/adr/0015-open-publishing-and-the-editor.md)); Today's article ranks any published article by quality score | ✅ web + mobile + backend |
| F20 Review workflow | ✖ removed (ADR 0015) |
| F09 Learning paths + F03 Home cards: paths list (All / My paths) and path page (enroll, progress, next article, completion badge), "Next in path" at the end of the reader, profile Paths tab, Home "continue reading" + active-path cards, today's article prefers the active path's next article (F07), admin path API (`paths.manage`; screens with F23) | ✅ web + mobile + backend |
| F17 Notifications: center API (cursor list, unread count, seen / read / read-all), settings (per-type all / in-app / off, quiet hours), entries for new followers, comments, replies, mentions, reaction milestones, new articles from followed writers, today's article, the 20:00 streak reminder, security alerts and moderation notices (aggregated per group, idempotent), FCM push job (quiet hours, retries, invalid tokens, 24 h cutoff), live unread badge, demo notifications; web + mobile: notification center (Today / Earlier, mark all read, tap marks read), live badge with REST fallback, Settings → Notifications (modes, quiet hours), push taps mark read | ✅ web + mobile + backend |
| Mentions + "who can mention me" (F18 privacy: everyone / people I follow / nobody): the suggestions, comment mentions and published articles respect it (every language version is checked at each publish and Update: allowed mentions link with the current `@username`, the rest become plain text), and a mentioned user hears about an article once (`mention` with no comment; at most 20 people per article); web + mobile: the setting in Settings → Privacy and the article-mention text | ✅ web + mobile + backend |
| F19 Writer verification: request with a field, job title and proof (an https URL and/or a PDF/JPEG/PNG/WebP ≤ 10 MB checked by magic bytes), one pending at a time, withdraw, status page; proofs in a private store (never under `wwwroot`, never at a public URL; the API won't start otherwise), deleted once decided; admin queue (`verification.manage`: pending / approved / rejected, proof download, approve → `VerifiedWriter` role, reject with a reason), `verification_result` notification (`readin://verification`), audit log, account deletion, demo requests | ✅ web + mobile + backend |
| F24 Share links: the web and the reader share the article's web URL (`{domain}/{ar|en}/a/{slug}`, the version being read); Android App Links and iOS Universal Links open it in the app in that version; the SSR server serves `assetlinks.json` and `apple-app-site-association` from its environment; the domain is configuration (`siteUrl`, `WEB_ORIGIN`). Setup by hand: [docs/setup/app-links.md](docs/setup/app-links.md). The quote card isn't built | ✅ web + mobile (setup pending) |
| ContentStudio `generate` (Claude), code-compile and live-link checks | ⏳ |
| Full-text search index (needs FTS in the SQL image) | ⏳ Phase 2 |

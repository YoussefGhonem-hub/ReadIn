# Handoff: F09 Learning Paths + F03 Home cards

Owner session: readin-29 (formerly readin-c2). Stopped on 2026-11-04 at the user's request. Nothing is on `dev` yet.
readin-8e had agreed to merge these branches into `dev`.

## Branches (all from `origin/dev` 0ecf346, pushed as-is)

| Branch | Last commit | Contents |
|---|---|---|
| `f09-paths` | this handoff commit (code at `2972b56`) | Backend + docs: domain, migration, API, seeders, tests; contract, SPEC, README |
| `f09-web` | `28f275e` | Angular: API layer, `/paths` + `/paths/:slug`, Home cards, reader "Next in path", profile Paths tab, mock API + e2e |
| `f09-mobile` | `82e2a4e` | Flutter: `features/paths`, Home cards, reader "Next in path" sliver, profile Paths tab, goldens |

Merge order: `f09-paths`, then `f09-web` and `f09-mobile` (either order). The client branches only need the API.

## What's done

- **F03 Home**:
  - "Continue reading" card (`GET /me/continue-reading`: unfinished, ≥ 5%, last 30 days, deduped against today's hero);
  - learning-path card (`GET /me/paths/active`; on 204 / for guests, a slim "browse paths" prompt).
- **F09 Learning paths**:
  - list (All / My paths, field chips) and path page (items in order with read ticks, start / continue / leave, completion badge);
  - `GET /articles/{id}/path` and the reader's "Next in path" block (after Sources, before Related);
  - the profile Paths tab (`GET /users/{username}/paths`, same privacy rule as reading stats).
- **Enrollment**: `PUT/DELETE /me/paths/{id}`. Completion is set by an outbox handler on `ArticleReadCompletedDomainEvent` (`PathProgressEventHandler`). Enrolling after reading everything completes the path at once. The badge stays if the path grows.
- **F07**: today's article prefers the active path's next unread article, except on a third day in a row in one field (`ActivePathNext` + a hunk in `DailyArticlePicker`).
- **Admin API** (`paths.manage`): `GET/POST /admin/paths`, `PUT /admin/paths/{id}`, `PUT /admin/paths/{id}/items`, `DELETE /admin/paths/{id}`. Editorial paths (from `content/taxonomy.yaml`) answer `409 path.editorial`.
- **Data**:
  - migration `20261104073046_LearningPathEnrollments`: the `PathEnrollments` table, `LearningPaths.IsEditorial`, and `UPDATE LearningPaths SET IsEditorial = 1`;
  - `LearningPathsSeeder` v2 marks paths editorial;
  - `DemoReadingSeeder` v2 enrolls reader1/2/3 and has reader6 complete `secure-by-default`.
- **Docs**: `docs/api/contract-v1.md` (Continue reading, Learning paths, My paths, Path admin, DTOs), SPEC (F03, F09, §16.2 Learning row), README rows.

## What's left

- **Merging onto current `dev`**. `dev` already has F05 (`20261104063851_OpenPublishingAndEditor`), and probably the Glossary and account-deletion migrations.
  - Regenerate `LearningPathEnrollments` on top of them, and carry the `UPDATE LearningPaths SET IsEditorial = 1;` line over by hand.
  - `DailyArticlePicker`: my hunks are the `ActivePathNext.LoadAsync` call in `LoadProfilesAsync`, the first lines of `PickAsync` and the `PathNext` init property on `PickerProfile`. F05 rewrote the review pools around them.
  - `PathCards.ArticleLanguageOfAsync` inlines the guest rule `ar → ar-EG, en → en`. On `dev`, swap it for `ArticleLanguages.ForUi(uiLanguage)`.
  - Expected small conflicts:
    - mobile `article_page.dart`: 1 sliver line + 3 lines for an optional `language` used by continue reading's `?lang=`;
    - web `article.page.ts`: 3 lines;
    - both also edited by the F04 reader work;
    - `README.md` (the "Seeders: glossary" row), `IAppDbContext` / `AppDbContext` (2 DbSets) and Application `DependencyInjection.cs` (`PathCards`).
- **Account hard delete**: `PathEnrollments` cascade from `Users`, so nothing is needed unless the eraser deletes rows by hand.
- **Not built (by decision)**: admin path screens, which wait for F23 Admin Console. No "path completed" domain event or notification (F17 would need one).
- **Not shown on clients**: `ArticlePathDto.previous`.

## Known errors

None known on these branches. Notes:
- The web initial bundle is 509.97 kB. It was 509.87 kB at the base, already over the 500 kB *warning* budget. The +0.10 kB is a chunk split, not F09 code.
- Docker Desktop must be running for the backend integration tests (Testcontainers SQL Server).

## Tests that ran

- **Backend** (`f09-paths`):
  - full `dotnet test --solution ReadIn.slnx` at `46a753d`: 1325/1326. The 1 failure was an architecture naming rule, fixed before commit; the arch tests then passed 9/9.
  - after the last code commit `2972b56`: `LearningPathTests` (21 integration) and `ArchitectureTests` (9), all green. Domain `LearningPathTests`: 8 green.
- **Web** (`f09-web` at `28f275e`):
  - `npm run lint`: clean; `npm test`: 56 files / 526 tests green (both re-run by me);
  - production build: OK;
  - full Playwright e2e: 226/226, run by the agent on isolated ports 4391/5391.
- **Mobile** (`f09-mobile` at `82e2a4e`): `flutter analyze`: no issues; `flutter test`: 916/916 including goldens (re-run by me).

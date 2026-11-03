# ReadIn — Backend

ASP.NET Core (.NET 10) API built with **Clean Architecture**, **CQRS** (Mediator) and **Mapster**.

```text
backend/
├── ReadIn.slnx · Directory.Build.props · Directory.Packages.props (central versions) · global.json
├── src/
│   ├── ReadIn.Domain/          # aggregates (User, Article, Field…), value objects, domain events, Result/Error
│   ├── ReadIn.Application/     # commands, queries, validators, DTOs, Mapster configs, pipeline behaviors, RDoc processor
│   ├── ReadIn.Infrastructure/  # EF Core + migrations, outbox, Hangfire jobs, Firebase Admin, seeders, content repository,
│   │                           #   upload storage (wwwroot/uploads) + SkiaSharp image processing
│   ├── ReadIn.Api/             # minimal-API endpoints (/api/v1), Firebase JWT auth, ProblemDetails, OpenAPI + Scalar
│   └── ReadIn.ContentStudio/   # content pipeline CLI: compose drafts, validate (schema, structure, parity, compile
│                               #   and link checks), plan-status, import (content/AUTHORING.md)
└── tests/
    ├── ReadIn.Domain.UnitTests/
    ├── ReadIn.Application.UnitTests/   # incl. Mapster config.Compile(), RDoc schema over all content
    ├── ReadIn.Infrastructure.UnitTests/ # image processing (magic bytes, limits, EXIF) and upload storage (path traversal)
    ├── ReadIn.Api.IntegrationTests/    # real SQL Server via Testcontainers, emulator-style tokens, temp uploads folder,
    │                                   #   seeders over fixture content (tests/fixtures/content)
    ├── ReadIn.ContentStudio.Tests/     # draft composer, editorial rules, Roslyn snippet checks
    └── ReadIn.ArchitectureTests/       # NetArchTest layer + naming rules
```

See [SPEC §6](../docs/SPEC.md#6-backend-clean-architecture--cqrs--mapster) and the [ADRs](../docs/adr).

## Run

```bash
docker compose up -d                       # repo root: SQL Server on :14333 + Seq
firebase emulators:start                   # repo root: Auth emulator on :9099
dotnet run --project src/ReadIn.Api        # http://localhost:5080 — migrates + seeds in Development
```

- API reference: `http://localhost:5080/docs` (Scalar) · OpenAPI: `/openapi/v1.json` · Hangfire: `/hangfire` · Health: `/health`
- Uploaded images are stored in `src/ReadIn.Api/wwwroot/uploads` (git-ignored, never published) and served at `/uploads`.
  Deploying and backing them up: [docs/setup/deployment.md](../docs/setup/deployment.md) ([ADR 0010](../docs/adr/0010-uploads-in-wwwroot.md)).
- Secrets come from user-secrets locally: `dotnet user-secrets set "Seed:DemoPassword" "<password>" --project src/ReadIn.Api`

## Conventions

- Handlers are `internal sealed` and return `Result`/`Result<T>`. Errors carry a stable `code` (e.g. `article.not_found`) that clients translate.
- Authorization: `[RequirePermission(...)]` / `[Authenticated]` on the message, enforced by `AuthorizationBehavior`. Permissions come from SQL Server, never from Firebase claims.
- Pipeline: Logging → Authorization → Validation → Caching (`ICachedQuery` + tags).
- Queries use `AsNoTracking()` + `ProjectToType<T>()`. Language-aware mapping reads `LocalizedProjection.Ui` / `.Lang`.
- Entities change only through domain methods. Domain events go to the outbox in the same transaction and are dispatched to `IDomainEventHandler<T>`.
- Seeders are idempotent and checksum-versioned (`SeedHistory`; articles per article); demo users are never seeded in Production. The official ReadIn account, its avatar, the pipeline articles (with covers) and the learning paths are seeded everywhere.

## Test

```bash
dotnet test --solution ReadIn.slnx         # needs Docker for the integration tests
```

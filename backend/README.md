# ReadIn — Backend

ASP.NET Core (.NET 10) API built with **Clean Architecture**, **CQRS** (Mediator) and **Mapster**.

```text
backend/
├── ReadIn.slnx
├── src/
│   ├── ReadIn.Domain/          # entities, aggregates, value objects, domain events
│   ├── ReadIn.Application/     # commands, queries, validators, DTOs, Mapster configs
│   ├── ReadIn.Infrastructure/  # EF Core, Dapper, Firebase, Hangfire, seeders
│   ├── ReadIn.Api/             # endpoints, middleware, SignalR, auth
│   └── ReadIn.ContentStudio/   # content pipeline CLI
└── tests/
    ├── ReadIn.Domain.UnitTests/
    ├── ReadIn.Application.UnitTests/
    ├── ReadIn.Api.IntegrationTests/
    └── ReadIn.ArchitectureTests/
```

See [SPEC §6](../docs/SPEC.md#6-backend-clean-architecture--cqrs--mapster).

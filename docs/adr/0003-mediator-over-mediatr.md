# 0003 — Mediator (source-generated) instead of MediatR

- **Status:** Accepted
- **Date:** 2026-11-02

## Context

The backend uses CQRS with pipeline behaviors (SPEC §6.3). MediatR moved to a commercial license from v13.

## Decision

Use [`martinothamar/Mediator`](https://github.com/martinothamar/Mediator) 3.x (MIT, source-generated):

- `ICommand<TResponse>` / `IQuery<TResponse>` with `internal sealed` handlers, enforced by NetArchTest.
- The source generator runs in `ReadIn.Application` (`GenerateTypesAsInternal = true`), so internal handlers are fine and the Api only sees `ISender`.
- Pipeline order is registered explicitly: Logging → Authorization → Validation → Caching.
- Handlers return `Result`/`Result<T>`. Behaviors short-circuit with typed errors through a small reflection-cached factory instead of throwing.
- Domain events do **not** go through Mediator notifications. They go to the outbox and are dispatched to `IDomainEventHandler<T>` (SPEC §6.3), because they are processed after commit, possibly on another node.

## Consequences

- No runtime reflection for dispatch, and missing handlers become compile-time diagnostics.
- The API differs slightly from MediatR (`ValueTask`, and `next(message, ct)` in behaviors).
- A transaction behavior isn't needed yet: each command does a single `SaveChanges`, which already writes the aggregate and its outbox rows atomically.

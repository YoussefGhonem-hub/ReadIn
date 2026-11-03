# 0006 — EF Core sequential GUIDs for primary keys (instead of `Guid.CreateVersion7()`)

- **Status:** Accepted
- **Date:** 2026-11-03
- **Supersedes:** "sequential GUIDs via `Guid.CreateVersion7()`" in SPEC §16.1 (v1.0)

## Context

SPEC v1.0 generated primary keys in the domain with `Guid.CreateVersion7()`, expecting append-friendly
inserts. SQL Server does not compare `uniqueidentifier` values byte by byte from the left: it compares the
**last six bytes first** (then bytes 8–9, 6–7, 4–5, 0–3). A v7 GUID puts its timestamp in the first six
bytes and random data at the end, so under SQL Server's ordering consecutive v7 keys land at random
positions in the clustered index. That causes page splits and fragmentation as tables grow.

EF Core's SQL Server provider already ships a generator built for this: when a `Guid` key is
`ValueGeneratedOnAdd` (the default convention), EF Core uses `SequentialGuidValueGenerator`, which writes
its increasing part into the bytes SQL Server compares first. Keys are generated on the client when the
entity is added to the `DbContext`, so no database round-trip is needed.

## Decision

- Every entity key uses EF Core's default Guid generation (`ValueGeneratedOnAdd`). The domain no longer
  generates keys; `Entity.Id` is `Guid.Empty` until the entity is added to the context.
- Children added to a tracked aggregate (translations, sources, interests, devices, ...) get their key and
  foreign key from EF Core when it discovers them (key generation + navigation fix-up).
- **Domain events are materialized at `SaveChanges`.** Aggregates raise events as factories
  (`Raise(() => new ArticlePublishedDomainEvent(Id, ...))`); the outbox interceptor builds them after keys
  have been assigned, so an event never carries `Guid.Empty`. Events therefore describe the aggregate as it
  is when the unit of work is saved.
- Fixed reference keys stay explicit constants (`RoleIds`, system accounts). EF Core keeps an explicitly set,
  non-default key. Every other seeded row is upserted by its natural key (role name, permission code, field
  slug, email, article slug).
- An integration test inserts rows one after another and asserts that SQL Server returns them in insertion
  order when sorted by `Id`.

## Consequences

- Code must not read an entity's `Id` before adding it to the context (e.g. to build a URL). Handlers return
  `entity.Id` after `SaveChangesAsync`.
- Domain unit tests see `Guid.Empty` ids for new aggregates. Tests that need distinct ids add the entities
  to a context or compare by other properties.
- Keys are only roughly time-ordered across application instances (each process has its own counter),
  which is enough to keep inserts near the end of the index.

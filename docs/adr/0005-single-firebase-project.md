# 0005 — One real Firebase project; the Emulator Suite for everything else

- **Status:** Accepted
- **Date:** 2026-11-03
- **Supersedes:** the separate staging Firebase project in SPEC §28.1 (v1.0)

## Context

SPEC v1.0 planned two real Firebase projects: staging (with demo data) and production. In practice the
team develops and tests entirely against the Firebase Emulator Suite (Auth + Storage), and a second real
project means a second set of OAuth clients, Apple/Google provider settings, `google-services.json` /
`GoogleService-Info.plist` files and service-account keys to manage. It also creates a place where demo
users with known passwords could live in a real, internet-facing identity system.

## Decision

- There is **one** real Firebase project. It serves the deployed app only.
- Local development, CI and all automated tests use the **Firebase Emulator Suite** (project `demo-readin`).
  This stays the default on every platform.
- Each platform switches between the two with configuration only:
  - **Backend:** `Firebase:UseEmulator` (`true` in `appsettings.Development.json`, `false` in `appsettings.json`)
    plus `Firebase:ProjectId`. `UseEmulator` is rejected outside `Development` and `Testing`.
  - **Web:** `environment.development.ts` (emulator) vs `environment.ts` (production build, real project).
  - **Mobile:** `dev` flavor = emulator (`config/dev.json`), `prod` flavor = real project (`config/prod.json`).
- **Demo users and demo interactions are seeded only into the emulator and the local database.** The demo
  seeders require `Firebase:UseEmulator = true` in addition to a Development/Testing environment, so they
  cannot reach the real project even if someone runs the API with `ASPNETCORE_ENVIRONMENT=Development`
  against it.
- System accounts (`ReadIn Editorial`, `SuperAdmin`) and editorial content are the only seeded data in the real project.

Setup steps for the real project: [`docs/setup/firebase.md`](../setup/firebase.md).

## Consequences

- QA happens locally (or on any machine) against the emulators with the full demo seed. There is no shared
  pre-production environment with real Firebase; if one is needed later it gets its own project and a new ADR.
- Real-provider behaviour (Google / Apple sign-in, FCM delivery) can only be checked against the production
  project, using real accounts, never the seeded demo accounts.
- The `staging` alias is removed from `.firebaserc` and the `staging` mobile flavor is removed.

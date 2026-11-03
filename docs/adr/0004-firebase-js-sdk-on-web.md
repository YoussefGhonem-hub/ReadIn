# 0004 — Firebase JS SDK directly on web (instead of `@angular/fire`)

- **Status:** Accepted
- **Date:** 2026-11-02

## Context

SPEC §3.2 lists `@angular/fire` for web auth and messaging. The web app is on Angular 22 / TypeScript 6. The current `@angular/fire` release (21.x) does not support either.

## Decision

Use the modular `firebase` JS SDK (v13) directly behind a small `core/auth` service. It loads only in the browser, so SSR never touches it. In development it connects to the Auth emulator (`demo-readin`).

Firestore isn't used (SPEC §4), but the `firebase` umbrella package still brings it in, together with a vulnerable `@grpc/grpc-js`. `web/package.json` therefore pins `@grpc/grpc-js` to a patched version through `overrides`, and CI runs `npm audit --audit-level=high`.

## Consequences

- Less Angular-specific sugar (no injectable `Auth` token from the library); our service exposes Signals instead.
- Revisit when `@angular/fire` supports Angular 22. The switch is local to `core/auth`.

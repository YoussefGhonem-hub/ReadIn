# 0001 — Firebase Authentication for identity, SQL Server for roles

- **Status:** Superseded by [0007](0007-phone-password-authentication.md) (2026-11-03). Roles and permissions still come from SQL Server as described here.
- **Date:** 2026-11-02

## Context

ReadIn needs email/password, Google and Apple sign-in on web, Android and iOS, plus a permission model with seven roles (SPEC §9, §10). Roles change often (verification, reviewer assignment, suspension) and must take effect quickly.

## Decision

- **Firebase Auth owns identity only.** Clients sign in with the Firebase SDK and send the ID token as `Authorization: Bearer`. The API validates it as a JWT (`https://securetoken.google.com/{projectId}`, audience = project id).
- **SQL Server owns everything else.** `POST /auth/sync` creates the `Users` row (role `Member`) on first sign-in. An `IClaimsTransformation` loads roles and permissions from SQL Server (cached for 5 minutes in `HybridCache` and invalidated by the `UserRolesChanged` domain event) and adds them as `readin:*` claims.
- **Endpoints require permissions, not roles.** `[RequirePermission]` on commands/queries is enforced by the Mediator `AuthorizationBehavior`. Guests get the `Guest` role's permissions.
- **Firebase custom claims are not used.** They need a token refresh before they take effect and would duplicate the source of truth.
- **Local development uses the Firebase Auth emulator.** Its tokens are unsigned, so `Firebase:UseEmulator` disables signature validation; issuer, audience and lifetime are still checked. The API refuses to start with this flag outside Development/Testing.

## Consequences

- One extra call (`/auth/sync`) after sign-in; clients must make it.
- A role change can take up to 5 minutes to apply if the invalidation event is delayed. Suspension is checked on every request from the same cache.
- Integration tests mint emulator-style tokens and need no Firebase project.

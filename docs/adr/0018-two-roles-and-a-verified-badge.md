# 0018 — Two roles (Member, SuperAdmin), and Verified is a badge

- **Status:** Accepted
- **Date:** 2026-11-05
- **Relates to:** SPEC §10 (roles and permissions), F19 (verification), F22 (moderation), F23 (admin console), §18
  (seeding); contract-v1 "Roles and permissions", "Writer verification". Amends [0009](0009-recovery-pin.md) (who resets
  whom) and the role list of [0001](0001-firebase-auth-sql-server-roles.md).

## Context

ReadIn had six roles: Guest, Member, VerifiedWriter, Moderator, Admin and SuperAdmin, plus `roles.manage` to grant
them. In practice one person runs the app, so Admin and Moderator had nobody but the owner, and role management was a
screen nobody needed. VerifiedWriter was a role only to carry a badge: it added no permission, yet every read model
found "is verified" by joining `UserRoles`.

## Decision

- **Roles:** `Member` (every account that signs up) and `SuperAdmin` (the owner, from `Seed:SuperAdminPhone`).
  `Guest` stays a caller without a token. The SuperAdmin holds every permission, so it does what Admin and Moderator
  did. `roles.manage`, role management and the demo admin/moderator accounts are gone.
- **Endpoints keep checking permissions, never roles.** A staff role can be added later as one more row of
  `RoleMatrix` (and the database follows on the next start). Two rules that used role names now use permissions:
  "staff" (nobody warns or suspends them, F22) is whoever holds `moderation.manage`, and an admin password reset is
  refused when the target holds a permission the caller doesn't (so only a SuperAdmin resets a SuperAdmin).
- **Verified is a badge:** `Users.IsVerified` and `Users.VerifiedAt`. Approving a request sets them (a user who already
  has the badge keeps the first date); the SuperAdmin can remove the badge (`DELETE /admin/users/{id}/verification`,
  audited, nobody notified). Roles and permissions never change with it, and every read model reads the column, with
  no join.
- **The database follows the code on every start.** The `VerifiedBadgeAndTwoRoles` migration moves existing data once:
  VerifiedWriter holders get the badge (dated by their latest approved request, or now), the three roles go with their
  `UserRoles` and `RolePermissions`, `roles.manage` goes, every account left without a role becomes a Member, and
  `@readin` stays a Member with the badge. Then the role seeder makes the tables match `RoleMatrix` exactly (stray roles
  and unknown permissions deleted, accounts without a role made Members). Its checksum covers the database as well as
  the matrix, so a database that drifted is fixed on the next start.

## Consequences

- Clients gate screens on permissions and show the badge from `isVerified`; `roles` is only ever `["Member"]` or
  `["SuperAdmin"]`, and clients never test role names.
- Granting the badge doesn't touch the cached permissions, so nothing needs invalidating; cached public pages (article
  details, ≤ 10 minutes) show a new or removed badge when they expire, as they did for the role.
- Who was an Admin or a Moderator is not kept: those accounts are Members now. The migration's `Down` brings the badge
  back as the VerifiedWriter role only.
- After the first start on a database that drifted, the role seeder runs once more on the following start (its
  checksum then reflects the fixed state); it changes nothing that time.

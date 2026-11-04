# 0007 — Phone number + password, with the API's own JWT sessions

- **Status:** Accepted
- **Date:** 2026-11-03
- **Supersedes:** [0001](0001-firebase-auth-sql-server-roles.md) and the auth part of [0004](0004-firebase-js-sdk-on-web.md)
- **Amended by:** [0012](0012-google-and-apple-sign-in.md): Google and Apple sign in were added on the same accounts and sessions;
  [0016](0016-immediate-account-deletion.md): account deletion is immediate and for good

## Context

SPEC v1.1 (§9) changes sign-in to **phone number + password only**: no email login, no Google/Apple, and no SMS or OTP.
Firebase Auth (ADR 0001) was built around email and social providers, and its phone sign-in is SMS-only. Keeping
it would mean storing passwords in Firebase while the recovery PIN, lockouts and "sign out of all devices" live in SQL
Server, with two sources of truth for one account.

## Decision

- **The API owns sign-in.** Users, password hashes (ASP.NET Core Identity's `PasswordHasher`, PBKDF2), lockouts and
  sessions live in SQL Server. Phone numbers are validated with libphonenumber (mobile numbers only) and stored as
  E.164. `POST /auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`, `/auth/logout-all`; `/auth/sync` is
  removed.
- **Access token:** HS256 JWT signed with `Jwt:SigningKey`, valid **15 minutes**, claims `sub` (user id),
  `security_stamp` and `jti`. On every request the API compares `security_stamp` with SQL Server (cached for 5 minutes and
  dropped on every change) and adds roles, permissions and the suspended flag. Changing the password or phone, a reset
  or "sign out of all devices" rotates the stamp, which ends every other session at once.
- **Refresh token:** random 256-bit, **30 days**, stored as SHA-256 only (`RefreshTokens`), **rotated** on every refresh.
  Each sign in starts a token *family*. Presenting a token that was already rotated revokes the whole family (theft
  detection), except within a 30-second grace window, so two browser tabs refreshing at once don't sign the user out.
- **Transport:** mobile keeps the refresh token in `flutter_secure_storage` and sends it in the body. The web never
  sees it: it gets an `HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth` cookie, and the API reads the cookie only
  when the request carries `X-ReadIn-Client: web`, a header a cross-site form can't add. Access tokens stay in memory on
  both.
- **Anti-enumeration:** one generic error for a wrong number or password (`auth.invalid_credentials`), and a dummy
  hash check for unknown numbers so timing matches.
- **Limits** (SPEC §9.5): 5 wrong passwords lock the account for 15 minutes. Per IP: 20 sign-ins a minute, 3 sign-ups
  an hour, 10 recovery calls an hour (ASP.NET Core rate limiter, `RateLimits:Auth`). Per number: 5 sign-ins a minute
  (in-memory, `IAttemptThrottle`) and 5 recovery attempts an hour (`RecoveryAttempts`).
- **Account deletion:** confirmed with the password; immediate and for good since [0016](0016-immediate-account-deletion.md)
  (it was a soft delete anonymized after 30 days). The number can sign up again right away.
- **Seeding:** demo users and the local SuperAdmin get `Seed:DemoPassword` and `Seed:DemoPin` (local only). The
  production SuperAdmin gets `Seed:SuperAdminPhone` + `Seed:SuperAdminPassword` and must change the password and set a
  PIN on first sign in.

## Consequences

- No SMS means the app can't prove a user owns the number. Mitigated by the "confirm your number" step, the recovery
  PIN ([0009](0009-recovery-pin.md)) and owner notifications for security changes.
- `Jwt:SigningKey` and `Security:RecoveryPinPepper` are required secrets; the API refuses to start without them, or with
  the Development values outside Development. Rotating the signing key signs every access token out; refresh tokens
  keep working.
- The per-number sign-in counter and the attempt throttle are in memory, like the uploads folder
  ([0010](0010-uploads-in-wwwroot.md)): one API instance. Scaling out moves them to a shared cache.
- Firebase stays for Cloud Messaging and the Realtime Database only ([0008](0008-firebase-scope-fcm-and-rtdb.md)).
- Owner notifications (password, PIN or phone changed; recovery locked) are raised as `UserSecurityChangedDomainEvent`
  and delivered once F17 Notifications and FCM sending ship.

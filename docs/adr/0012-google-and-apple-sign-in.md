# 0012 — Google and Apple sign in, verified by the API

- **Status:** Accepted
- **Date:** 2026-11-03
- **Amends:** [0007](0007-phone-password-authentication.md) (which ruled out Google/Apple)
- **Amended by:** [0014](0014-immediate-account-deletion.md): immediate deletion with Apple token revocation

## Context

ADR 0007 made phone number + password the only way in. The product now also wants **Continue with Google** and
**Continue with Apple** on the same accounts, with the same sessions. On iOS, App Store guideline 4.8 requires Sign in with
Apple whenever an app offers Google sign in for the main account.

Two shapes were possible:

1. Bring Firebase Auth back for Google/Apple and exchange a Firebase ID token for a ReadIn session.
2. Have the apps get an ID token straight from Google Sign-In / Sign in with Apple, and let the API verify it.

Option 1 would make Firebase a second identity store next to SQL Server, which is what ADR 0007 removed, and adds a hop
that doesn't verify anything Google or Apple don't already sign.

## Decision

- Clients use the provider SDKs (`google_sign_in` / `sign_in_with_apple` on Flutter, Google Identity Services / Sign in with
  Apple JS on the web) and send the **ID token** to `POST /auth/external`. The API answers with the same `SessionDto` as
  `/auth/login`, so refresh tokens, the security stamp, suspension and the client guards stay identical.
- The API verifies tokens itself with OpenID Connect discovery (`Microsoft.IdentityModel.Protocols.OpenIdConnect`): keys from
  Google's and Apple's `jwks_uri`, cached and refreshed on rotation; **RS256** only; issuer (`accounts.google.com` /
  `https://accounts.google.com`, `https://appleid.apple.com`); audience in `ExternalAuth:{Google,Apple}:ClientIds`; expiry.
  A provider without client ids is turned off and isn't listed in `GET /auth/config` → `externalProviders`.
- **Apple nonce:** the app makes a random nonce, gives Apple its SHA-256 (hex) and sends us the raw value. We accept the
  token only if its `nonce` is the SHA-256 of what we received. Accepting the raw value would let anyone holding a leaked
  token copy the nonce out of its readable payload. Google tokens are checked the same way when they carry a nonce.
- Audiences: Google = the web client id (also the audience on Android, where the app passes it as `serverClientId`) and the
  iOS client id; Apple = the bundle id `app.readin.readin` (native iOS) and, once created, the web Services ID. Client ids are
  public identifiers and live in `appsettings.json`.
- Identities are stored in `UserExternalLogins` (`Provider`, `Subject` = the provider's `sub`, the email it reported,
  `LinkedAt`, `LastUsedAt`): unique per (Provider, Subject) and per (UserId, Provider). Provider tokens are never stored.
- **Linking, one account for every way in:**
  - An identity that is already linked signs in.
  - Otherwise, if the provider says the email is **verified** and an account has that email, it is linked and signed in.
    `Users.Email` is only ever written from a provider-verified address (or by seeding), never from user input, so an
    email match can't be planted by someone else.
  - Otherwise the API answers `404 auth.external_not_linked`, and the app asks: create a new account (`createAccount:
    true`), or "I already have an account" with phone + password (`link`), which goes through the same throttle and
    lockout as sign in.
  - Settings links and unlinks providers. Linking needs the password, or a fresh token of an already-linked provider, so a
    stolen access token can't add a way back in. The last way to sign in can't be removed.
- Google/Apple-only accounts have no phone, password or PIN, so `mustSetRecoveryPin` is false; recovery goes through the
  provider. They can add phone + password + PIN later (`POST /me/phone-sign-in`, confirmed with the provider). Sensitive
  actions that need the password accept a fresh provider token instead (`DELETE /me` with `external`).
- Deleting an account removes its Google/Apple identities with it, after revoking its Apple tokens, so they can sign up
  again at once ([0014](0014-immediate-account-deletion.md); this first said the phone number stayed reserved for 30 days).
  Apple sign in and link also send the `authorizationCode`, exchanged for a refresh token that is kept encrypted for that.

## Consequences

- One session system and one source of truth (SQL Server) for every sign-in method; Firebase stays limited to FCM and the
  Realtime Database (ADR 0008).
- The API depends on Google and Apple key endpoints being reachable; keys are cached, and a failed fetch rejects the sign in
  (`401 auth.external_invalid`) without affecting phone sign in.
- Apple on Android needs a web-flow callback endpoint; until it exists, Apple is offered on iOS and the web only. The Apple
  REST "revoke tokens on account deletion" call (needs an Apple key and the authorization code) is a follow-up before
  App Store submission.
- Tests: the real verifier is unit-tested with a local signing key; integration tests replace it with a fake that accepts
  `subject|email` tokens.

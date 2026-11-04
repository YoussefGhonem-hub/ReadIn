# 0016 — Immediate account deletion, with Apple token revocation

- **Status:** Accepted
- **Date:** 2026-11-03
- **Amends:** [0007](0007-phone-password-authentication.md) and [0012](0012-google-and-apple-sign-in.md) (both described a
  soft delete with anonymization after 30 days)

## Context

App Store guideline 5.1.1(v) and Google Play require in-app account deletion, and apps that offer Sign in with Apple must
revoke the user's Apple tokens through the Sign in with Apple REST API when the account is deleted. ADR 0007 and 0012 had
deletion as a soft delete: signed out at once, personal data anonymized by a daily job after 30 days, articles and comments
kept as "Deleted user", the phone number reserved until then. There was no way to restore an account in that window, so it
only delayed erasure, kept the number from signing up again, and the API never had an Apple token to revoke (it only
verified ID tokens).

Two options were weighed: (a) delete immediately and for good, or (b) a soft delete with a short recovery window, then a
hard delete. (b) needs a restore flow, keeps the phone, email and Google/Apple identity reserved during the window, and the
privacy policy has to say so. The confirmation steps (the password or a fresh provider sign in, a checkbox and a final
dialog) already guard against accidents. The product owner chose (a).

## Decision

- `DELETE /me` deletes the account **immediately and for good**, in one transaction (`AccountEraser`), following the data
  map in SPEC §9.6: the account row and everything tied to it (roles, interests, devices and push tokens, Google/Apple
  links, sessions, reset tokens, recovery attempts, reading progress and stats, reactions, saves, collections and follows,
  the account's drafts and unpublished articles, its avatar and every upload no published article shows, its own security
  log entries), plus its Firebase Auth record and Realtime Database node. Other people's articles keep their revisions
  without the deleted editor; audit entries of actions the account took on other accounts stay without its IP address. Only an `account.deleted` audit record (the account id and the time) remains.
- **Published articles and comments stay, without an author.** `Articles.AuthorId`, `Comments.AuthorId` and the owner of
  the images and PDFs a kept article shows become null, audit stamps (`CreatedBy`, `UpdatedBy`) on kept rows are cleared,
  and readers see "Deleted user" with no name, @username, photo or profile link (`author: null` in the API). The product
  owner chose this so links, learning paths and discussions other readers rely on keep working; the deletion screen tells
  writers to delete an article first if they want it gone.
- **Apple:** the authorization code that comes with Apple sign in or link (`authorizationCode` on `ExternalCredential`) is
  exchanged at `POST https://appleid.apple.com/auth/token` for a refresh token, kept AES-256-GCM encrypted
  (`UserExternalLogins.ProviderRefreshToken`, key derived from the recovery PIN pepper). Before anything is deleted, every
  Apple token of the account is revoked at `/auth/revoke`: the stored one, and the one from a fresh code when the person
  confirmed with Apple. Both calls authenticate with a client secret JWT (ES256, `kid` = key id, `iss` = Team ID,
  `sub` = the client id the token was issued to) signed with the Sign in with Apple key (`SIWA_KEY_BASE64`).
- Revocation is never skipped: transient failures are retried three times; if Apple stays unreachable, or the key isn't
  configured, the request answers `503 account.deletion_unavailable` and nothing is deleted. An Apple-linked account with no
  usable token answers `400 auth.apple_confirmation_required`, and the client confirms with Apple to get a fresh code.
- **Idempotent:** a retried `DELETE /me` whose (still valid) token outlived the account answers `204` too; every other
  endpoint answers `401` to that token, because its user no longer exists.
- The phone number, email and Google/Apple identities can **sign up again right away**, as a new, empty account.

## Consequences

- No grace period and no restore: support can't bring an account back. Database backups still hold deleted accounts for up
  to 14 days, until they're overwritten, and the privacy policy says so.
- `User.Anonymize` and `Users.AnonymizedAt` are gone: "Deleted user" is now an article or comment whose author is null, not
  an anonymized account row. The daily identity cleanup job erases any account left soft-deleted by the earlier model.
- `Articles.AuthorId` and `MediaAssets.OwnerId` are nullable, and every reader of an article's author handles null. The
  foreign keys stay `NO ACTION` (SQL Server allows one cascade path from `Articles` to `Users`), so `AccountEraser`
  unlinks the rows itself before deleting the account.
- Deleting an Apple-linked account depends on Apple's token service being reachable; the client shows a Retry.
- Any new table keyed by a user must be covered by `AccountEraser` (cascade from `Users`, or an explicit delete) and listed
  in the data map. Reactions, saved articles, collections and follows cascade; follows *of* the account are deleted
  explicitly, and the counters of the articles it reacted to or saved are recomputed right after the commit.
- The Firebase Auth record that signing in with a `POST /realtime/token` custom token creates is deleted before the
  transaction; if Firebase can't be reached, the request answers `503 account.deletion_unavailable` and nothing is deleted.

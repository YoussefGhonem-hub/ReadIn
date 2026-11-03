# 0008 — Firebase only for Cloud Messaging and the Realtime Database

- **Status:** Accepted
- **Date:** 2026-11-03
- **Related:** [0005](0005-single-firebase-project.md) (one real project), [0007](0007-phone-password-authentication.md) (sign in)

## Context

SPEC v1.0 used Firebase for sign-in, Storage and messaging. In v1.1 sign-in moved to the API (ADR 0007) and uploads
moved to the API server's disk (ADR 0010). What is left that only Firebase does well is push delivery to Android, iOS
and the web, and cheap live signals (counters, new comments, unread badge) that Firestore would bill per read.

## Decision

- **Cloud Messaging (FCM)** sends every push: daily article, replies, mentions and security notices. Devices register
  with `POST /me/devices` and are removed with `DELETE /me/devices/{token}` on sign out.
- **Realtime Database (RTDB)** carries signals, not content (SPEC §21.2). Only the backend writes, with the Admin SDK,
  after the SQL commit. Public paths (`/live/articles`, `/live/feed`) need no token.
- **Firebase Auth is not a sign-in method.** It is enabled with no providers, only so that `POST /realtime/token` can
  mint a **custom token** (`uid` = ReadIn user id) that lets a signed-in client read `/live/users/{uid}`. Signing out of
  ReadIn also signs out of Firebase.
- **No Storage, no Firestore, no Firebase Auth providers.** Local development and tests use the Emulator Suite (RTDB and
  Auth for custom tokens).

## Consequences

- One Admin SDK service-account key on the server (`Firebase:ServiceAccountJson`) covers FCM, RTDB writes and custom
  tokens.
- If Firebase is down, the app still works through REST: pushes and live updates are missing, nothing else.
- Moving off Firebase later only touches push delivery and the live-signal publisher and listeners; accounts and content
  never lived there.

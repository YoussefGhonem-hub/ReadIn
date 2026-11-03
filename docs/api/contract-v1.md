# ReadIn API v1 — Foundation Contract

This is the hand-written contract for the endpoints built in **Phase 0 / early Phase 1**. The OpenAPI document served by the API (`/openapi/v1.json`, Scalar UI at `/docs` in non-production) is the authoritative version. When they disagree, OpenAPI wins and this file gets fixed.

## Conventions

| Item | Value |
|---|---|
| Base URL (local) | `http://localhost:5080/api/v1` |
| Auth | `Authorization: Bearer <access token>` from `/auth/login` or `/auth/register` (JWT, 15 minutes; ADR 0007). Anonymous calls are allowed where marked 🌐 |
| UI language | `Accept-Language: ar` or `en`. Controls error `title`/`detail` and localized `name` fields |
| Article language | `?lang=ar-EG` or `?lang=en` on article endpoints (falls back to the article's source language) |
| JSON | camelCase, enums as camelCase strings, dates ISO-8601 UTC (`2026-11-02T08:00:00Z`), times `HH:mm` |
| Ids | UUID strings (v7) |
| Cursor pages | `?cursor=<opaque>&limit=20` → `{ "items": [...], "nextCursor": "..." \| null }` |

### Errors (RFC 9457 ProblemDetails)

```json
{
  "type": "https://readin.app/errors/validation",
  "title": "Validation failed",
  "status": 400,
  "code": "validation.failed",
  "traceId": "00-...",
  "errors": { "interests": ["user.interests.min_three"] }
}
```

Clients translate `code` (and each validation error code) with their own `ar`/`en` strings, and use `title` only as a fallback. Stable codes: `validation.failed`, `auth.unauthorized`, `auth.forbidden`, `user.suspended`, `user.not_found`, `user.username_taken`, `user.interests.min_three`, `field.not_found`, `topic.not_found`, `article.not_found`, `rate_limited`, `server.error`, plus the auth, social and media codes below.

## Endpoints

### Auth 🌐 (SPEC §9, ADR 0007, ADR 0009, ADR 0012)

| Method | Path | Body → Response |
|---|---|---|
| GET | `/auth/config` | → `200 AuthConfigDto` (PIN length, password rules, and the Google/Apple providers this server accepts) |
| POST | `/auth/register` | `RegisterRequest` → `200 SessionDto`. `409 auth.phone_taken`. The profile starts incomplete (`isProfileComplete: false`, placeholder `@reader_xxxxxxxxxx`) |
| POST | `/auth/login` | `LoginRequest` → `200 SessionDto`. `401 auth.invalid_credentials` (wrong number or password, same error), `429 auth.locked_out` (5 wrong → 15 minutes), `403 user.suspended`, `429 rate_limited` (5 a minute per number) |
| POST | `/auth/external` | `ExternalSignInRequest` → `200 SessionDto`. Signs in a linked identity, or links one whose **verified** email matches an account. Otherwise `404 auth.external_not_linked`: ask again with `createAccount: true` or with `link: { phoneNumber, password }`. `401 auth.external_invalid` (bad, expired or wrong-audience token, nonce mismatch), `400 auth.provider_disabled`, `409 auth.external_conflict` (that account already has another identity of this provider), `409 auth.external_in_use` (`link` to an account other than the one this identity belongs to), `401 auth.invalid_credentials` / `429 auth.locked_out` for `link`, `403 user.suspended`. New accounts have no phone, password or PIN (`hasPassword: false`, `mustSetRecoveryPin: false`) and an incomplete profile |
| POST | `/auth/refresh` | `RefreshRequest` (mobile) or no body + cookie (web) → `200 SessionDto` with a **new** refresh token. `401 auth.refresh_invalid` → sign out |
| POST | `/auth/logout` | `RefreshRequest` or cookie → `204` (always); ends this device's session |
| POST | `/auth/logout-all` | Bearer → `200 SessionDto`: every other session ends, this device gets fresh tokens |
| POST | `/auth/recovery/verify-pin` | `VerifyPinRequest` → `200 { resetToken, expiresAt }` (10 minutes, single use). `401 auth.recovery_invalid` (wrong number or PIN), `429 auth.recovery_locked` (5 wrong → 1 hour), `403 auth.recovery_disabled` (3 lockouts in 7 days → contact support) |
| POST | `/auth/recovery/reset-password` | `{ resetToken, newPassword }` → `204`; every session is signed out. `400 auth.reset_token_invalid` → start again |

**Web sessions:** send `X-ReadIn-Client: web` with `credentials: "include"` on every `/auth/*` call and on `PUT /me/password`,
`PUT /me/phone`, `POST /me/phone-sign-in` and `DELETE /me`. The refresh token then comes as an `HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth`
cookie named `readin_refresh`, and `SessionDto.refreshToken` is `null`. Without the header the cookie is ignored.
**Mobile** keeps `refreshToken` in secure storage and may send `X-Device-Name` (e.g. "Pixel 8"). Tokens rotate: presenting a
refresh token that was already used ends the whole session (a 30-second grace covers parallel tabs), so refresh one call
at a time (single-flight) and always keep the newest token.

**After sign in**, route by `SessionDto.user` in this order (SPEC §9.2): `mustChangePassword` → change password,
`mustSetRecoveryPin` → set PIN, `!isProfileComplete` → complete profile, `!onboardingCompleted` → onboarding, else home.

### Me (Bearer)

| Method | Path | Body → Response |
|---|---|---|
| GET | `/me` | → `200 MeDto` |
| PATCH | `/me` | `UpdateProfileRequest` → `204` |
| DELETE | `/me` | `{ password? , external?: ExternalCredential }` → `204`. Confirm with the password, or (accounts without one) a fresh Google/Apple token. Signed out everywhere, Google/Apple identities released at once, personal data removed after 30 days. `400 auth.wrong_password`, `400 auth.confirmation_required`, `400 auth.external_mismatch` |
| PUT | `/me/profile/complete` | `{ displayName, username, avatarUrl? }` → `200 MeDto`. `409 user.username_taken` |
| PUT | `/me/password` | `{ currentPassword, newPassword }` → `200 SessionDto`; other sessions end. `400 auth.wrong_password` |
| PUT | `/me/phone` | `{ newPhoneNumber, currentPassword }` → `200 SessionDto`; other sessions end. `409 auth.phone_taken`, `400 auth.phone_unchanged` |
| POST | `/me/recovery-pin` | `{ pin }` → `200 MeDto`. Only while `mustSetRecoveryPin` (or without a PIN); `409 auth.pin_already_set` otherwise |
| PUT | `/me/recovery-pin` | `{ currentPassword, newPin }` → `204` |
| POST | `/me/phone-sign-in` | `{ phoneNumber, password, recoveryPin, external: ExternalCredential }` → `200 SessionDto`; other sessions end. Google/Apple-only accounts add phone + password + PIN, confirmed with a linked provider. Same validation codes as `/auth/register`; `409 auth.phone_taken`, `409 auth.phone_sign_in_exists`, `400 auth.external_mismatch` |
| POST | `/me/external-logins` | `{ credential: ExternalCredential, password?, external?: ExternalCredential }` → `200 MeDto`. Links Google/Apple; confirm with the password or a fresh token of an already linked provider. `409 auth.external_in_use` (belongs to another account), `409 auth.external_conflict`, `400 auth.wrong_password`, `400 auth.confirmation_required`, `400 auth.external_mismatch` |
| DELETE | `/me/external-logins/{provider}` | → `200 MeDto`. `400 auth.last_sign_in_method` (it's the only way to sign in), `404 auth.external_login_not_found` |
| PUT | `/me/preferences` | `UpdatePreferencesRequest` → `204` |
| PUT | `/me/interests` | `UpdateInterestsRequest` → `204` (at least 3 field ids + topic ids combined) |
| POST | `/me/devices` | `RegisterDeviceRequest` → `204` (FCM token upsert) |
| DELETE | `/me/devices/{token}` | → `204` (idempotent; call on sign out, URL-encode the token) |

A wrong `currentPassword` counts toward the same 15-minute lockout as sign in (`429 auth.locked_out`).

| Method | Path | Auth | Body → Response |
|---|---|---|---|
| GET | `/users/username-available?u=` | 🌐 | → `200 { username, valid, available }` (your own handle counts as available) |
| POST | `/admin/users/{id}/reset-password` | Bearer, `users.reset_password` | → `200 { temporaryPassword }`. "Forgot the PIN too" (ADR 0009): the user must change the password and set a PIN on the next sign in. Only a SuperAdmin can reset an Admin or SuperAdmin |

### Taxonomy 🌐

| Method | Path | Response |
|---|---|---|
| GET | `/fields` | `FieldDto[]` (enabled fields, ordered) |
| GET | `/fields/{slug}/topics` | `TopicDto[]` |

### Articles & Feed 🌐 (Bearer optional)

| Method | Path | Response |
|---|---|---|
| GET | `/articles/{slug}?lang=` | `ArticleDetailsDto` |
| GET | `/feed/for-you?field=&cursor=&limit=` | `CursorPage<ArticleCardDto>`. Signed in: user's interests first. Guest: latest published. `field` is a field slug. |
| GET | `/feed/today` | `ArticleCardDto` or `204` when no pick is available yet |
| GET | `/feed/following?cursor=&limit=` | Bearer → `CursorPage<ArticleCardDto>`: published articles by the writers you follow, newest first (the Home "Following" tab) |

Every card (for you, today, following, saved) carries the article's counters and, for a signed-in caller, their own
`myReaction` / `isSaved` (`null` / `false` for guests). `ArticleDetailsDto` adds `isFollowingAuthor` (`false` for guests
and on your own articles) and `collectionIds`, your collections that hold the article (`[]` for guests and unsaved
articles), so "add to collection" can show its ticks.

### Reactions (F10; writes: Bearer, permission `reactions.create`, rate limit `writes`)

| Method | Path | Body → Response |
|---|---|---|
| PUT | `/articles/{id}/reaction` | `{ type: ReactionType }` → `200 ArticleReactionsDto`. Sets or changes your one reaction per article. `400` validation code `reaction.invalid` (in `errors.type`), `404 article.not_found` (also for drafts, archived, deleted or other unpublished articles) |
| DELETE | `/articles/{id}/reaction` | → `200 ArticleReactionsDto` (idempotent) |
| GET | `/articles/{id}/reactions?type=&cursor=&limit=` | 🌐 → `CursorPage<ReactorDto>` ("who reacted"), newest first; `type` keeps one reaction (`reaction.invalid` otherwise) |

The `ArticleReactionsDto` of a write is counted from the rows right after your change. Counters on cards and details
come from the article's denormalized columns, which the outbox updates right after the commit (see Live counters).

### Saved (F13; Bearer, permission `saved.manage`, rate limit `writes` on writes)

| Method | Path | Body → Response |
|---|---|---|
| PUT | `/me/saved/{articleId}` | → `200 SaveStateDto` (idempotent). `404 article.not_found` |
| DELETE | `/me/saved/{articleId}` | → `200 SaveStateDto` (idempotent); also removes it from every collection |
| GET | `/me/saved?field=&q=&collection=&cursor=&limit=` | → `CursorPage<SavedArticleDto>`, newest saved first. `field` = field slug, `q` = title search in any language version (≤ 100 characters; case, Arabic diacritics and letter forms ignored, SPEC §22), `collection` = one of your collection ids. Articles that can no longer be opened are left out |
| GET | `/me/collections` | → `CollectionDto[]` (name order) |
| POST | `/me/collections` | `{ name }` (1–60 characters, trimmed) → `201 CollectionDto` with `Location`. `409 collection.name_taken` (per user, ignoring case), `400 collection.limit` (50 per user), validation codes `validation.required` / `validation.max_length` on `name` |
| PATCH | `/me/collections/{id}` | `{ name }` → `200 CollectionDto`. Same name rules |
| DELETE | `/me/collections/{id}` | → `204`; the articles stay saved |
| PUT | `/me/collections/{id}/articles/{articleId}` | → `204` (idempotent); saves the article first if needed |
| DELETE | `/me/collections/{id}/articles/{articleId}` | → `204` (idempotent); the article stays saved |

`404 collection.not_found` for a collection that isn't yours; `404 article.not_found` for an article that can't be opened.

### Follow (F12; writes: Bearer, permission `follows.manage`, rate limit `writes`)

| Method | Path | Body → Response |
|---|---|---|
| PUT | `/users/{id}/follow` | → `200 FollowStateDto` (idempotent). `400 follow.self`, `404 user.not_found`. The official ReadIn account can be followed |
| DELETE | `/users/{id}/follow` | → `200 FollowStateDto` (idempotent). `400 follow.self`, `404 user.not_found` |
| GET | `/users/{id}/followers?q=&cursor=&limit=` | 🌐 → `CursorPage<UserSummaryDto>`, newest first; `q` (≤ 100 characters) matches the display name or `@username`. `404 user.not_found` |
| GET | `/users/{id}/following?q=&cursor=&limit=` | 🌐 → same |
| GET | `/users/suggested?limit=10` | Bearer → `UserSummaryDto[]` (limit ≤ 50): writers with published articles in fields that overlap your interests (a followed topic counts for its field), not followed, not you, not suspended. Verified writers first, then by follower count. When no writer overlaps your interests yet, any writer with published articles |
| PUT | `/me/interests/fields/{fieldId}` | → `200 InterestsDto` (follow a field = an interest, F02; idempotent). `404 field.not_found` |
| PUT | `/me/interests/topics/{topicId}` | → `200 InterestsDto` (idempotent). `404 topic.not_found` |
| DELETE | `/me/interests/fields/{fieldId}`, `/me/interests/topics/{topicId}` | → `200 InterestsDto` (idempotent). `400 user.interests.min_three` when fewer than 3 interests would remain |

### Comments (F11; writes: Bearer)

| Method | Path | Body → Response |
|---|---|---|
| GET | `/articles/{id}/comments?sort=top\|new&cursor=&limit=` | 🌐 → `CommentPageDto`. Top-level comments, each with its first 2 replies (`replies`, oldest first). The pinned comment comes first on the first page. `top` (default) = likes + 2 × replies, then newest; `new` = newest first. `404 article.not_found` |
| GET | `/comments/{id}/replies?cursor=&limit=` | 🌐 → `CursorPage<CommentDto>`, oldest first |
| GET | `/comments/{id}` | 🌐 → `CommentDto` as you see it; deleted/hidden ones come back as placeholders. Refetch it after a live event |
| POST | `/articles/{id}/comments` | `{ body }` → `201 CommentDto`. Permission `comments.create`, rate limit `comments` (10 a minute per user, `429`) |
| POST | `/comments/{id}/replies` | `{ body }` → `201 CommentDto`. Replying to a reply joins the same thread (`parentId` is always the top-level comment). `409 comment.not_available` (deleted or hidden). Same permission and limit |
| PATCH | `/comments/{id}` | `{ body }` → `200 CommentDto` with `editedAt`. Own comments only (`403 comment.not_owner`) |
| DELETE | `/comments/{id}` | → `204` (idempotent). Own comments only. Soft: a top-level comment with replies becomes a placeholder |
| PUT / DELETE | `/comments/{id}/like` | → `200 CommentLikeDto` (idempotent). Permission `reactions.create`. `409 comment.not_available` |
| POST / DELETE | `/comments/{id}/pin` | → `200 CommentDto`. The article's author only (`403 comment.pin_not_author`); top-level and visible only (`400 comment.pin_reply`). Pinning unpins the article's previous pinned comment |
| GET | `/users/mention-suggestions?q=&limit=8` | Bearer → `MentionCandidateDto[]`: `@username` prefix (with or without `@`) or display name, not you |

Text rules: trimmed, line ends trimmed, at most one empty line in a row, 1–2000 characters (`400 comment.empty`,
`comment.too_long`). `@username` (3–30 of a–z 0–9 _, not right after a Latin letter or digit, so emails aren't mentions;
fine after an Arabic letter, "و@writer1") resolves to real users, at most 10, never yourself; they come back in
`mentions`, and clients link exactly those handles. Mention notifications arrive with F17. Flood limits on top of the
rate limit: at most 20 comments per user on one article per hour (`429 comment.article_limit`, deleted ones count), and
not the same text (case and spacing ignored) within 10 minutes (`409 comment.duplicate`).

Who sees what: readers get visible comments; a comment hidden by a moderator is shown in full only to its author and to
moderators (`isHidden: true`). A deleted, or hidden-for-you, top-level comment that still has replies is a placeholder
(`isDeleted` or `isHidden`, `body` and `author` null) so its replies keep their thread; otherwise it's left out. When an
account is deleted, its comments stay with `author: null` ("Deleted user"), as the public account-deletion page promises.

`Articles.CommentCount` (and the live `commentCount`) counts visible comments and replies.

Live events (F27) under `/live/articles/{id}/events`: `comment.created`, `reply.created` (with `parentId`),
`comment.updated` (edited, hidden or unhidden), `comment.deleted`, `comment.liked`, `comment.pinned` (pin or unpin), each
with `commentId`. They carry no content: refetch `GET /comments/{commentId}`. A retried write can repeat an event, so
dedupe by `commentId`, and skip events for your own just-made change. Events are kept 24 hours and at most 100 per article
(hourly cleanup job).

### Reports and moderation (F22 hooks in F11; Bearer, rate limit `writes`)

| Method | Path | Body → Response |
|---|---|---|
| POST | `/reports` | `{ targetType: "comment", targetId, reason: spam\|misinformation\|harassment\|copyright\|other, details? (≤ 500) }` → `204`. Permission `reports.create`. Reporting again is a no-op. `400 report.own_content`, `400 report.target_not_supported` (articles and users come with F22), validation `report.reason_invalid`, `404 report.target_not_found` |
| POST | `/moderation/actions` | `{ action: hide\|unhide\|delete, targetType: "comment", targetId }` → `204`. Permission `moderation.manage` (Moderator, Admin, SuperAdmin). Hide and delete resolve the comment's open reports; every action is in the audit log. `404 comment.not_found` |

The queue that lists and resolves reports comes with F22.

### Live counters (F27, SPEC §21.2)

After a reaction or save change commits, an outbox handler recomputes that article's counters from SQL (idempotent:
always recounted, never incremented), stores them on `Articles` (`ReactionCount` = the sum of the four per-type
columns, `SaveCount`), refreshes the cached details and writes `/live/articles/{id}` through `IRealtimePublisher`:
`{ reactions: { insightful, love, fire, mindBlown }, commentCount, saveCount, updatedAt }` (published articles only).
Clients apply their own action optimistically, and when live counters arrive they **replace** the numbers (never add),
so your own action is never counted twice. Feed cards subscribe only while visible; the reader while open.

| Method | Path | Auth | Response |
|---|---|---|---|
| POST | `/admin/realtime/rebuild-counters` | Bearer, `system.settings` | → `200 { articleCount }`: every article's counters recomputed from SQL and republished |

### Writing (Bearer, permission `articles.create`)

| Method | Path | Body → Response |
|---|---|---|
| POST | `/articles` | `CreateArticleRequest` → `201 { id, slug }` (draft) |
| PUT | `/articles/{id}/attachments` | `SetAttachmentsRequest` → `204`. Replaces the whole attachment set; `items: []` clears it |
| POST | `/articles/{id}/publish` | → `204`. Fails with `article.sources_required` when the field has `requiresSources` and no source was given |

### Media (Bearer) — see [ADR 0011](../adr/0011-media-pipeline-and-pdf-preview.md)

| Method | Path | Body → Response |
|---|---|---|
| POST | `/uploads/images` | `multipart/form-data`: `file` (jpeg/png/webp/heic, ≤ 10 MB, ≤ 8000×8000), `purpose` = `image` (default) \| `avatar` \| `cover` → `201 MediaAssetDto` with `status: "ready"` (images are processed in the request) |
| POST | `/uploads/documents` | `multipart/form-data`: `file` (PDF, ≤ 20 MB, ≤ 100 pages, no password), `title` (optional, ≤ 5000, defaults to the file name), `allowDownload` (`true`/`false`, default `false`) → `202 MediaAssetDto` with `status: "processing"` and `pageCount` set. Pages are rendered in the background, page 1 first |
| GET | `/uploads/{id}` | → `200 MediaAssetDto` (owner only). Poll every 2 s while `status` is `processing` |
| DELETE | `/uploads/{id}` | → `204` (owner only; `409 media.in_use` while attached to an article) |
| GET | `/documents/{assetId}/download` 🌐 | → `200 application/pdf` with `Content-Disposition: attachment`. Allowed when the article is published and `allowDownload` is on, or for the owner / a moderator. `403 media.download_not_allowed`, `404 media.not_found` |

Uploaded files are public, immutable `.webp` URLs under `/uploads/...` (absolute URLs in every DTO). PDFs are never served from `/uploads`.

Quotas: 50 uploads per user per day (`409 media.quota_daily`), 200 MB stored per user (`409 media.quota_storage`).

Media error codes: `media.purpose_invalid`, `media.file_required`, `media.too_large`, `media.unsupported_type`, `media.dimensions_too_large`, `media.image_corrupted`, `media.pdf_encrypted`, `media.pdf_corrupted`, `media.pdf_too_many_pages`, `media.quota_daily`, `media.quota_storage`, `media.not_found`, `media.in_use`, `media.download_not_allowed`, `media.processing_failed`, `media.processing_timeout`, `attachments.mixed_kinds`, `attachments.too_many_images`, `attachments.single_document`, `attachments.alt_text_required`, `attachments.alt_text_too_long`, `attachments.caption_too_long`, `attachments.title_required`, `attachments.title_too_long`, `attachments.asset_not_found`, `attachments.asset_not_ready`, `attachments.duplicate_asset`.

### Real-time (Bearer) — SPEC §21.2, [ADR 0008](../adr/0008-firebase-scope-fcm-and-rtdb.md)

| Method | Path | Body → Response |
|---|---|---|
| POST | `/realtime/token` | → `200 { token }`: a Firebase **custom token** whose `uid` is your user id (valid for one hour). Pass it to `signInWithCustomToken` on the client's own Firebase app (`readin-live`); it only lets you read `/live/users/{yourId}` and is **not** a ReadIn sign-in. Ask for one on every page load / app start and sign in; sign out of Firebase when you sign out of ReadIn. 10 a minute per user (`429 rate_limited`); `500 realtime.unavailable` when Firebase can't sign one (stay on REST and try again on the next start) |

Live paths in the Firebase Realtime Database. Only the API writes them, after the SQL commit; clients only read. They
carry signals, never content: fetch the data itself through REST. Times are epoch milliseconds. Anything can be missing
(RTDB unavailable, or nothing published yet): keep the REST values then.

| Path | Who reads | Value |
|---|---|---|
| `/live/articles/{articleId}` | 🌐 | `reactions: { insightful, love, fire, mindBlown }`, `commentCount`, `saveCount`, `updatedAt` (server time). Totals, not deltas. Listen to the three counter children rather than the node, so `events` isn't downloaded |
| `/live/articles/{articleId}/events/{pushId}` | 🌐 | `{ type, commentId, parentId?, at }`: `type` is `comment.created` \| `comment.updated` \| `comment.deleted` \| `reply.created` \| `comment.liked` \| `comment.pinned`; `at` is server time, so query `orderByChild('at').startAt(serverNow)`. A retried write can repeat an event |
| `/live/feed/latestPublishedAt` | 🌐 | Publish time of the newest article the feed can show. Higher than when the feed was loaded → show "مقالات جديدة ↑" |
| `/live/users/{userId}` | that user (custom token) | `unreadNotifications`, `lastNotificationAt` |
| `/live/users/{userId}/media/{assetId}` | that user (custom token) | `{ status: processing \| ready \| failed, pagesReady, pageCount, failureReason, updatedAt }` while a PDF renders. Polling `GET /uploads/{id}` stays the contract |

### Reading & streaks (Bearer) — see [ADR 0013](../adr/0013-reading-days-and-streaks.md)

| Method | Path | Body → Response |
|---|---|---|
| PUT | `/articles/{id}/progress` | `ReadingProgressRequest` → `200 ReadingProgressResultDto`. Completes the article at `percent ≥ 70` and ≥ 30 credited seconds. Seconds are credited up to the time that really passed since the previous report (+10 s, ≤ 600); the first report credits none. `404 article.not_found` (not published), `409 reading.conflict` (a parallel report: send it again), `429` above 60 reports a minute |
| GET | `/me/stats` | → `200 ReadingStatsDto` (owner only) |
| GET | `/me/stats/heatmap?days=` | → `200 ReadingHeatmapDto`. `days` 1–371, default 365 |

Readers report on open (`activeSecondsDelta: 0`), every 15 s while the article is visible and the user was active in the
last 60 s, and when they leave. A failed report keeps its seconds for the next one. Guests don't report.

## DTOs (TypeScript notation)

```ts
type UiLanguage = 'ar' | 'en';
type ArticleLanguage = 'ar-EG' | 'en';
type ThemePreference = 'system' | 'light' | 'dark';

interface AuthConfigDto {
  pinLength: number;             // default 4
  password: { minLength: number; maxLength: number; requireLetter: boolean; requireDigit: boolean };
  externalProviders: ExternalProvider[]; // configured on this server; hide the other buttons (and Apple on Android)
}

type ExternalProvider = 'google' | 'apple';

interface ExternalCredential {
  provider: ExternalProvider;
  idToken: string;               // Google ID token / Apple identityToken (JWT from the provider SDK)
  nonce?: string;                // RAW nonce: required for Apple, which must have been given its SHA-256 (hex)
}

interface ExternalSignInRequest extends ExternalCredential {
  displayName?: string;          // Apple sends the name only on the first authorization; used for new accounts
  uiLanguage?: UiLanguage;
  timeZone?: string;
  link?: { phoneNumber: string; password: string }; // "I already have an account"
  createAccount?: boolean;       // "Create a new account" (not together with link)
}

interface RegisterRequest {
  phoneNumber: string;           // E.164, e.g. "+201001234567" (mobile numbers only)
  password: string;              // 8..128, a letter and a digit, not common, not containing the number
  recoveryPin: string;           // pinLength digits, not weak (SPEC §9.4)
  uiLanguage?: UiLanguage;
  timeZone?: string;             // IANA, e.g. "Africa/Cairo"
}

interface LoginRequest { phoneNumber: string; password: string }
interface RefreshRequest { refreshToken?: string }   // omit on the web (cookie)
interface VerifyPinRequest { phoneNumber: string; pin: string }

interface SessionDto {
  accessToken: string;           // JWT, send as Bearer
  accessTokenExpiresAt: string;  // ~15 minutes
  refreshToken: string | null;   // null on the web (HttpOnly cookie)
  refreshTokenExpiresAt: string; // 30 days; rotates on every refresh
  user: MeDto;
}

// Validation codes (in `errors`): phone.invalid · password.too_short | too_long | letter_required | digit_required |
// too_common | contains_phone · pin.length | digits_only | weak · provider.invalid

interface MeDto {
  id: string;
  phoneNumber: string | null;    // E.164; only in MeDto and admin endpoints (SPEC §9.5); null for Google/Apple-only accounts
  email: string | null;          // provider-verified only
  displayName: string;
  username: string;              // @handle without "@"
  avatarUrl: string | null;
  bio: string | null;
  links: { github?: string; linkedin?: string; website?: string };
  uiLanguage: UiLanguage;
  articleLanguage: ArticleLanguage;
  theme: ThemePreference;
  timeZone: string;
  reminderTime: string;          // "08:00"
  isVerified: boolean;           // has VerifiedWriter role
  onboardingCompleted: boolean;  // true once ≥ 3 interests are saved
  mustChangePassword: boolean;   // after an Admin reset, or the production SuperAdmin's first sign in
  mustSetRecoveryPin: boolean;
  isProfileComplete: boolean;
  hasRecoveryPin: boolean;
  hasPassword: boolean;          // false for Google/Apple-only accounts: offer "add phone sign in" instead of "change password"
  externalLogins: { provider: ExternalProvider; email: string | null; linkedAt: string }[];
  roles: string[];               // e.g. ["Member", "VerifiedWriter"]
  permissions: string[];         // e.g. ["articles.read", "articles.create", ...]
  interests: { fieldIds: string[]; topicIds: string[] };
}

interface UpdateProfileRequest {
  displayName: string;           // 2..60
  username: string;              // ^[a-z0-9_]{3,30}$
  bio?: string | null;           // ≤ 300
  avatarUrl?: string | null;
  links?: { github?: string; linkedin?: string; website?: string };
}

interface UpdatePreferencesRequest {
  uiLanguage: UiLanguage;
  articleLanguage: ArticleLanguage;
  theme: ThemePreference;
  timeZone: string;
  reminderTime: string;          // "HH:mm"
}

interface UpdateInterestsRequest { fieldIds: string[]; topicIds: string[] }

interface RegisterDeviceRequest { token: string; platform: 'android' | 'ios' | 'web' }

interface FieldDto {
  id: string; slug: string;
  name: string;                  // localized by Accept-Language
  nameAr: string; nameEn: string;
  icon: string;                  // Lucide icon name, e.g. "cpu"
  color: string;                 // token name, e.g. "primary"
  isSensitive: boolean;
  requiresSources: boolean;      // publishing needs at least one source
  topicCount: number;
}

interface TopicDto { id: string; fieldId: string; slug: string; name: string; nameAr: string; nameEn: string }

interface AuthorDto { id: string; displayName: string; username: string; avatarUrl: string | null; isVerified: boolean }

interface FieldRefDto { id: string; slug: string; name: string; nameAr: string; nameEn: string }

interface ArticleCardDto {
  id: string; slug: string;
  language: ArticleLanguage;     // language actually served
  title: string; subtitle: string | null;
  coverUrl: string | null;
  field: FieldRefDto;
  author: AuthorDto;
  readingTimeMinutes: number;
  isReviewed: boolean; isAiAssisted: boolean;
  versionBadge: string | null;   // e.g. ".NET 10"
  publishedAt: string;
  reactionCount: number;         // always the sum of `reactions`
  reactions: ReactionCountsDto;
  commentCount: number;          // 0 until F11
  saveCount: number;
  myReaction: ReactionType | null; // the caller's reaction; null for guests
  isSaved: boolean;              // the caller saved it; false for guests
  attachments: ArticleAttachmentsDto | null;  // feed cards carry at most the first 10 PDF pages
}

// ── Reactions, saved, follow (F10, F12, F13) ──────────────────────
type ReactionType = 'insightful' | 'love' | 'fire' | 'mindBlown';   // 💡 ❤️ 🔥 🤯 (SPEC F10)
interface ReactionCountsDto { insightful: number; love: number; fire: number; mindBlown: number }

interface ArticleReactionsDto { reactions: ReactionCountsDto; total: number; myReaction: ReactionType | null }
interface ReactorDto { user: AuthorDto; type: ReactionType; reactedAt: string }

interface SaveStateDto { isSaved: boolean; saveCount: number }
interface SavedArticleDto { savedAt: string; collectionIds: string[]; article: ArticleCardDto }
interface CollectionDto { id: string; name: string; articleCount: number; createdAt: string } // articleCount: openable articles

interface FollowStateDto { isFollowing: boolean; followerCount: number }
interface UserSummaryDto {
  id: string; displayName: string; username: string; avatarUrl: string | null; isVerified: boolean;
  bio: string | null;
  isFollowing: boolean;          // the caller follows this user (false for guests)
  followsYou: boolean;           // this user follows the caller (false for guests)
}

interface InterestsDto { fieldIds: string[]; topicIds: string[] }  // as in MeDto.interests

// ── Media (ADR 0011) ──────────────────────────────────────────────
type MediaKind = 'image' | 'document';
type MediaPurpose = 'image' | 'avatar' | 'cover' | 'document';
type MediaStatus = 'uploading' | 'processing' | 'ready' | 'failed';

/** One responsive WebP rendition. Widths per purpose (never upscaled; a smaller original adds its own width):
 *  avatar 64/128/256/512 (square, center crop) · cover 400/800/1200 · image 320/640/1080/1600. */
interface MediaVariantDto { width: number; height: number; url: string; bytes: number }

/** A rendered PDF page: 400 px thumb + 1080 px view. */
interface MediaPageDto { pageNo: number; width: number; height: number; blurHash: string; thumbUrl: string; viewUrl: string }

interface MediaAssetDto {
  id: string;
  kind: MediaKind;
  purpose: MediaPurpose;
  status: MediaStatus;
  failureReason: string | null;  // stable code when status = "failed", e.g. "media.processing_timeout"
  width: number | null;          // image: oriented original; document: first page (view size)
  height: number | null;
  blurHash: string | null;       // placeholder (https://blurha.sh); document: first page
  sizeBytes: number;             // original upload
  variants: MediaVariantDto[];   // images, ascending width
  title: string | null;          // documents
  pageCount: number | null;      // documents, known as soon as the upload is accepted
  pagesReady: number;            // documents, pages rendered so far (page 1 first)
  pages: MediaPageDto[];         // documents, rendered pages in order
  allowDownload: boolean;
  createdAt: string;
}

interface ImageAttachmentDto {
  assetId: string; order: number;
  caption: string | null;        // ≤ 5000, render with dir="auto"
  altText: string;               // required
  width: number; height: number; blurHash: string | null;
  variants: MediaVariantDto[];
}

interface DocumentAttachmentDto {
  assetId: string;
  title: string;
  pageCount: number;
  allowDownload: boolean;        // the author's setting
  canDownload: boolean;          // for the current caller: allowDownload, or owner / moderator
  downloadUrl: string;           // GET /documents/{assetId}/download (absolute)
  pages: MediaPageDto[];
}

/** Either 1–10 images or exactly one PDF, never both. */
interface ArticleAttachmentsDto { kind: 'images' | 'document'; images: ImageAttachmentDto[]; document: DocumentAttachmentDto | null }

interface CreateArticleRequest {
  fieldId: string; topicId?: string | null;
  language: ArticleLanguage;
  title: string;                 // 5..150
  subtitle?: string | null;
  content: RDoc;
  tags?: string[]; sources?: { title: string; url: string }[];
  coverUrl?: string | null; versionBadge?: string | null; isAiAssisted: boolean;
}

interface SetAttachmentsRequest {
  items: {
    mediaAssetId: string; order: number;
    caption?: string | null;     // images, ≤ 5000
    altText?: string | null;     // images, required, ≤ 5000
    title?: string | null;       // the document, required, ≤ 5000
    allowDownload?: boolean;     // the document
  }[];
}

interface ArticleDetailsDto extends ArticleCardDto {
  availableLanguages: ArticleLanguage[];
  summary: string | null;        // TL;DR plain text
  content: RDoc;                 // shared/rdoc/rdoc.schema.json
  topic: FieldRefDto | null;
  tags: string[];
  sources: { title: string; url: string }[];
  reviewedBy: { displayName: string; username: string } | null;
  lastReviewedAt: string | null;
  readCount: number;             // saveCount comes from ArticleCardDto
  isFollowingAuthor: boolean;    // false for guests and on your own articles
  collectionIds: string[];       // the caller's collections that hold it, oldest entry first; [] for guests and unsaved articles
}

// Reading & streaks (ADR 0013). Dates are the user's local dates, "yyyy-MM-dd".
interface ReadingProgressRequest {
  language: ArticleLanguage;
  percent: number;               // 0–100, highest scroll position reached
  lastPosition: string | null;   // ≤ 100 chars, restores the scroll position
  activeSecondsDelta: number;    // 0–3600, active seconds since the previous report
}

interface StreakDto {
  current: number;               // 0 once broken
  longest: number;
  readToday: boolean;
  freezeAvailable: boolean;      // a freeze is ready for the next missed day (one per rolling 7 days)
  freezePending: boolean;        // yesterday was missed; reading today uses a freeze and keeps the streak
  today: string;
}

interface ReadingProgressResultDto {
  percent: number;
  completed: boolean;
  completedNow: boolean;         // this report made the article "read"
  streak: StreakDto | null;      // set when completedNow
  milestone: 7 | 30 | 100 | 365 | null;  // celebrate with a shareable card
}

interface ReadingStatsDto {
  streak: StreakDto;
  totalArticles: number;
  minutesRead: number;
  articlesThisWeek: number;      // last 7 local days
  minutesThisWeek: number;
  articlesThisMonth: number;     // last 30 local days
  topFields: { id: string; slug: string; name: string; icon: string; color: string; articles: number }[]; // ≤ 3, localized
}

interface ReadingHeatmapDto {
  from: string;
  to: string;                    // the user's local today
  days: { date: string; articles: number; minutes: number; frozen: boolean }[]; // only days with a read or a freeze
}

// Comments (F11)
interface CommentDto {
  id: string;
  articleId: string;
  parentId: string | null;       // the thread's top-level comment; null for top-level comments
  body: string | null;           // null for placeholders; render with dir="auto"
  author: AuthorDto | null;      // null: "Deleted user" (or a placeholder)
  isArticleAuthor: boolean;      // the "الكاتب" badge
  mentions: { userId: string; username: string }[];  // link exactly these @handles
  likeCount: number;
  likedByMe: boolean;
  replyCount: number;            // visible replies (top-level comments)
  isPinned: boolean;
  createdAt: string;
  editedAt: string | null;       // "edited"
  isDeleted: boolean;            // placeholder of a deleted comment kept for its replies
  isHidden: boolean;             // hidden by a moderator: placeholder for others, full text for its author and moderators
  canEdit: boolean; canDelete: boolean; canPin: boolean; canReport: boolean; canModerate: boolean;
  replies?: CommentDto[];        // in lists: the first 2 replies of a top-level comment
}

interface CommentPageDto { items: CommentDto[]; nextCursor: string | null; total: number } // total = article's comment count
interface CommentLikeDto { likeCount: number; liked: boolean }
interface MentionCandidateDto { id: string; displayName: string; username: string; avatarUrl: string | null; isVerified: boolean }
```

Validation codes (in `errors`) for this area: `reaction.invalid` (`type`), `validation.required` /
`validation.max_length` (`name` of a collection, `q`). Error codes: `collection.not_found`, `collection.name_taken`,
`collection.limit`, `follow.self`, `topic.not_found`.

## Push payloads (FCM)

Pushes come only from background jobs and outbox handlers (SPEC §21.1), to every token registered with `POST /me/devices`.
Each has a visible `notification` (`title`, `body`, in the user's UI language) and a `data` map of strings. `data.link`
is always the deep link to open (`readin://a/{slug}`); clients map it to their own route and drop anything else.
Tokens FCM reports as unregistered or invalid are deleted by the API.

### Daily article (`daily_article`, SPEC F07)

Sent once a day at the user's `reminderTime`, in their `timeZone`, for the article `GET /feed/today` returns that day.

```jsonc
{
  "notification": { "title": "مقال النهارده جاهز ☕", "body": "<article title>" }, // en: "Today's article is ready ☕"
  "data": {
    "type": "daily_article",
    "articleId": "0a1b2c3d-…",
    "slug": "rag-vs-fine-tuning",
    "link": "readin://a/rag-vs-fine-tuning",
    "lang": "ar"                 // the article version the body comes from: "ar" (ar-EG) | "en"; the web opens /{lang}/a/{slug}
  }
}
```

| Platform | Delivery |
|---|---|
| Android | channel `readin_default`, high priority, collapse key and tag `daily_article`, TTL until the user's midnight |
| iOS | `apns-push-type: alert`, `apns-collapse-id: daily_article`, `thread-id: daily_article`, sound `default`, expires at the user's midnight |
| Web | `TTL` header until the user's midnight; `data` also carries `tag: "daily_article"`, so a newer daily push replaces an unread one |

No push when the user already read that day's article, when the account is suspended or has no device, or when the push
would be more than 2 hours late (the article stays the hero card either way).

## Local development

- API: `http://localhost:5080` (Scalar UI: `/docs`, OpenAPI: `/openapi/v1.json`)
- Seeded demo users (SPEC §18.3): `+12025550110` (reader1) … with the password from `Seed:DemoPassword` and the recovery PIN from `Seed:DemoPin`. Neither is committed; set them once with `dotnet user-secrets set "Seed:DemoPassword" "<password>" --project backend/src/ReadIn.Api` and `dotnet user-secrets set "Seed:DemoPin" "<4 digits, not weak>" --project backend/src/ReadIn.Api`. Without a password you can't sign in as them; without a PIN they must set one after signing in.

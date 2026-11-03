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

Clients translate `code` (and each validation error code) with their own `ar`/`en` strings, and use `title` only as a fallback. Stable codes: `validation.failed`, `auth.unauthorized`, `auth.forbidden`, `user.suspended`, `user.not_found`, `user.username_taken`, `user.interests.min_three`, `field.not_found`, `article.not_found`, `rate_limited`, `server.error`, plus the auth codes below.

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
  reactionCount: number; commentCount: number;
  attachments: ArticleAttachmentsDto | null;  // feed cards carry at most the first 10 PDF pages
}

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
  saveCount: number; readCount: number;
}
```

## Local development

- API: `http://localhost:5080` (Scalar UI: `/docs`, OpenAPI: `/openapi/v1.json`)
- Seeded demo users (SPEC §18.3): `+12025550110` (reader1) … with the password from `Seed:DemoPassword` and the recovery PIN from `Seed:DemoPin`. Neither is committed; set them once with `dotnet user-secrets set "Seed:DemoPassword" "<password>" --project backend/src/ReadIn.Api` and `dotnet user-secrets set "Seed:DemoPin" "<4 digits, not weak>" --project backend/src/ReadIn.Api`. Without a password you can't sign in as them; without a PIN they must set one after signing in.

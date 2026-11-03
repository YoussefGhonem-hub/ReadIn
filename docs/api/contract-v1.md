# ReadIn API v1 — Foundation Contract

This is the hand-written contract for the endpoints built in **Phase 0 / early Phase 1**. The OpenAPI document served by the API (`/openapi/v1.json`, Scalar UI at `/docs` in non-production) is the authoritative version. When they disagree, OpenAPI wins and this file gets fixed.

## Conventions

| Item | Value |
|---|---|
| Base URL (local) | `http://localhost:5080/api/v1` |
| Auth | `Authorization: Bearer <Firebase ID token>`. Anonymous calls are allowed where marked 🌐 |
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

Clients translate `code` (and each validation error code) with their own `ar`/`en` strings, and use `title` only as a fallback. Stable codes: `validation.failed`, `auth.unauthorized`, `auth.forbidden`, `user.suspended`, `user.not_synced`, `user.not_found`, `user.username_taken`, `user.interests.min_three`, `field.not_found`, `article.not_found`, `server.error`.

## Endpoints

### Auth & Me

| Method | Path | Auth | Body → Response |
|---|---|---|---|
| POST | `/auth/sync` | Bearer | `SyncUserRequest` → `200 MeDto`. Creates the user on first call (role `Member`) and refreshes email/photo after that. Call it after every sign-in. |
| GET | `/me` | Bearer | → `200 MeDto` (`404 user.not_synced` if `/auth/sync` was never called) |
| PATCH | `/me` | Bearer | `UpdateProfileRequest` → `204` |
| PUT | `/me/preferences` | Bearer | `UpdatePreferencesRequest` → `204` |
| PUT | `/me/interests` | Bearer | `UpdateInterestsRequest` → `204` (at least 3 field ids + topic ids combined) |
| POST | `/me/devices` | Bearer | `RegisterDeviceRequest` → `204` (FCM token upsert) |

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
| POST | `/uploads/documents` | `multipart/form-data`: `file` (PDF, ≤ 20 MB, ≤ 100 pages, no password), `title` (optional, ≤ 150, defaults to the file name), `allowDownload` (`true`/`false`, default `false`) → `202 MediaAssetDto` with `status: "processing"` and `pageCount` set. Pages are rendered in the background, page 1 first |
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

interface SyncUserRequest { uiLanguage?: UiLanguage; timeZone?: string /* IANA, e.g. "Africa/Cairo" */ }

interface MeDto {
  id: string;
  email: string;
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
  caption: string | null;        // ≤ 120, render with dir="auto"
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
    caption?: string | null;     // images, ≤ 120
    altText?: string | null;     // images, required, ≤ 250
    title?: string | null;       // the document, required, ≤ 150
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
- Firebase Auth emulator: `http://127.0.0.1:9099`, project id `demo-readin`
- Seeded demo users: `reader1@readin.test` … with the password from `Seed:DemoPassword`. It is never committed; set it once with `dotnet user-secrets set "Seed:DemoPassword" "<your password>" --project backend/src/ReadIn.Api`. Without it, demo users are created in SQL Server only and you can't sign in as them.

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

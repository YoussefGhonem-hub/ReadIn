# ReadIn — Product & Technical Specification

> **ReadIn — مقال كل يوم يفرق معاك**
> *Read daily. Grow daily.*

| | |
|---|---|
| **Document** | Product & Technical Specification |
| **Version** | 1.1 |
| **Status** | Approved for development |
| **Platforms** | Web (Angular) · Mobile (Flutter: Android & iOS) |
| **Backend** | ASP.NET Core · SQL Server · Firebase (push + real-time only) |

> **v1.1 changes:** phone + password sign-in handled by the backend (no Firebase Auth, no SMS), recovery PIN for forgotten passwords, Firebase limited to FCM + Realtime Database, uploads stored in `wwwroot`, image optimization, and post attachments (image carousel + PDF preview).

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Golden Rules](#2-golden-rules)
3. [Tech Stack](#3-tech-stack)
4. [System Architecture](#4-system-architecture)
5. [Repository Structure](#5-repository-structure)
6. [Backend: Clean Architecture + CQRS + Mapster](#6-backend-clean-architecture--cqrs--mapster)
7. [Web: Angular](#7-web-angular)
8. [Mobile: Flutter](#8-mobile-flutter)
9. [Authentication: Phone + Password](#9-authentication-phone--password)
10. [Roles & Permissions](#10-roles--permissions)
11. [Features](#11-features)
12. [Feature Parity Matrix (Web + Mobile)](#12-feature-parity-matrix-web--mobile)
13. [Article Content Format: RDoc](#13-article-content-format-rdoc)
14. [Bilingual & Bidirectional Text (BiDi)](#14-bilingual--bidirectional-text-bidi)
15. [Design System & Dark Mode](#15-design-system--dark-mode)
16. [Database Design](#16-database-design)
17. [API Design](#17-api-design)
18. [Seeding: Users, Reference Data, Articles](#18-seeding-users-reference-data-articles)
19. [Content Pipeline: 1000+ Trusted Articles](#19-content-pipeline-1000-trusted-articles)
20. [Trust & Content Quality](#20-trust--content-quality)
21. [Notifications & Real-time](#21-notifications--real-time)
22. [Search](#22-search)
23. [SEO](#23-seo)
24. [Security](#24-security)
25. [Performance & Scalability](#25-performance--scalability)
26. [Accessibility](#26-accessibility)
27. [Testing Strategy](#27-testing-strategy)
28. [DevOps, Environments & CI/CD](#28-devops-environments--cicd)
29. [Git Workflow & Conventions](#29-git-workflow--conventions)
30. [Roadmap](#30-roadmap)
31. [Definition of Done](#31-definition-of-done)

---

## 1. Product Overview

### 1.1 Vision
ReadIn is a bilingual (Arabic + English) knowledge platform where anyone with valuable knowledge can publish beautifully formatted articles, and readers build a habit of reading **one valuable article every day** in the field they love.

### 1.2 Problem
- Existing platforms (Medium, LinkedIn Articles, Substack, Dev.to) handle Arabic poorly. Mixing Arabic and English in one paragraph breaks punctuation, word order and code blocks.
- Arabic knowledge content is either editorial-only (no community) or discussion-only (no long-form articles).
- People want to learn daily but lose the habit without structure and motivation.

### 1.3 Solution & Differentiators
| # | Differentiator | Description |
|---|---|---|
| 1 | **Perfect mixed Arabic/English text** | Per-block direction, isolated inline English terms, code always LTR. |
| 2 | **Daily reading habit** | "مقال النهارده" (Today's article) at the user's chosen time, streaks, learning paths. |
| 3 | **Trust by design** | Verified writers, reviewed articles, mandatory sources, tested code, "last reviewed" date and version badges. |
| 4 | **Two versions per article** | Egyptian Arabic + English terms (`ar-EG`) and English-only (`en`). |
| 5 | **Rich editorial formatting** | Callouts, code tabs, comparison tables, steps, glossary terms, not just plain text. |

### 1.4 Fields (Domains)
- **Software** (launch focus): AI, Machine Learning, Deep Learning & LLMs, Claude & AI coding tools, .NET, Frontend, Mobile, Databases, DevOps & Cloud, Software Architecture, Security, Testing.
- **Medicine**, **Engineering**, **Public Health** (enabled after launch, require verified writers + reviewer approval).

### 1.5 Target Users
Arab developers, students and professionals (18–35) who want to grow daily, plus experts who want to share knowledge and build a reputation.

---

## 2. Golden Rules

These rules apply to **every** feature, commit and code review.

1. **Feature parity:** every user-facing feature ships on **Web AND Mobile** in the same release. A feature is not "done" until it works on both (see [§12](#12-feature-parity-matrix-web--mobile)).
2. **Dark mode always:** every screen, component, image and email template supports Light, Dark and System themes. No hard-coded colors, only design tokens (see [§15](#15-design-system--dark-mode)).
3. **Bilingual always:** every UI string exists in Arabic (`ar`) and English (`en`). No hard-coded text. Every layout works in RTL and LTR.
4. **Clean Architecture + CQRS + Mapster** in the backend, no exceptions (see [§6](#6-backend-clean-architecture--cqrs--mapster)).
5. **One content format (RDoc):** articles are stored as structured JSON blocks, never raw HTML (see [§13](#13-article-content-format-rdoc)).
6. **Trust first:** no fake author personas, every AI-assisted article is labeled, and every technical article has sources.
7. **Security by default:** every endpoint is authorized by permission, every input is validated, and all user content is sanitized.

---

## 3. Tech Stack

### 3.1 Backend
| Concern | Technology |
|---|---|
| Runtime | **.NET 10 (LTS)**, ASP.NET Core Web API |
| Architecture | **Clean Architecture** + **CQRS** |
| CQRS dispatcher | **Mediator** (`martinothamar/Mediator`, source-generated, MIT). Avoids MediatR's commercial license (v13+). |
| Mapping | **Mapster** + `Mapster.DependencyInjection` (+ `Mapster.Tool` for generated mappers) |
| Validation | **FluentValidation** |
| ORM | **EF Core 10** (writes + simple reads), **Dapper** (heavy read queries, e.g. feeds) |
| Database | **SQL Server 2022+** (Full-Text Search, Arabic collation) |
| Auth | **Own JWT auth**: phone number + password. Access token (JWT, 15 min) + rotating refresh token. Passwords hashed with `PasswordHasher<T>` (`Microsoft.Extensions.Identity.Core`, no Identity tables). See [§9](#9-authentication-phone--password). |
| Phone numbers | `libphonenumber-csharp` (validation + E.164 normalization) |
| Push notifications | **Firebase Cloud Messaging (FCM)** via `FirebaseAdmin` SDK |
| Real-time | **Firebase Realtime Database** (live counters, comment events, unread badges), written by the backend only via `FirebaseAdmin` SDK. **No SignalR.** |
| File storage | **`wwwroot/uploads`** on the API server (Development and Production), behind `IFileStorage` |
| Image processing | **SkiaSharp** (resize, WebP, strip EXIF), **BlurHash** placeholders |
| PDF processing | **PDFtoImage** (PDFium, page rendering) + **PdfPig** (metadata, text extraction) |
| Background jobs | **Hangfire** (SQL Server storage): daily article push, streak reset, link checks, scheduled publishing |
| Caching | `HybridCache` (in-memory + optional Redis) |
| Logging | **Serilog** (console + Seq in dev, App Insights / file in prod) |
| API docs | OpenAPI + **Scalar** UI |
| API versioning | `Asp.Versioning` (`/api/v1/...`) |
| Resilience | Built-in rate limiting, `Microsoft.Extensions.Http.Resilience` |
| Testing | xUnit, FluentAssertions-style asserts, NSubstitute, **Testcontainers** (SQL Server), **NetArchTest** |

### 3.2 Web
| Concern | Technology |
|---|---|
| Framework | **Angular (latest stable, v21+)**, standalone components, **Signals** |
| Rendering | **SSR + hydration** (`@angular/ssr`), required for SEO |
| State | **NgRx Signal Store** |
| Styling | **Tailwind CSS** + CSS custom properties (design tokens) + Angular CDK |
| i18n | **Transloco** (runtime language switch `ar` / `en`) |
| Editor | **Tiptap** (`ngx-tiptap`) with custom RDoc extensions |
| Code highlighting | **Shiki** (light + dark themes) |
| Firebase | Firebase JS SDK directly: `firebase/messaging` (web push), `firebase/database` (real-time), and `firebase/auth` **only** for `signInWithCustomToken` to read the Realtime Database. Never used for user sign-in. |
| Phone input | `libphonenumber-js` + `flag-icons` (SVG flags) |
| Images | `NgOptimizedImage` with a custom loader (`srcset`), client-side compression before upload (`browser-image-compression`), BlurHash placeholders |
| HTTP | `HttpClient` + interceptors (auth with single-flight refresh, language, errors) + typed API client generated from OpenAPI |
| Testing | Vitest/Jest (unit), **Playwright** (E2E, RTL + dark mode screenshots) |

### 3.3 Mobile
| Concern | Technology |
|---|---|
| Framework | **Flutter (latest stable)** + Dart 3, Android & iOS |
| Architecture | **Clean Architecture**, feature-first (data / domain / presentation) |
| State | **flutter_bloc** (Cubit/Bloc) |
| DI | `get_it` + `injectable` |
| Navigation | `go_router` (deep links: `readin.app/a/{slug}`) |
| Networking | `dio` + `retrofit` + interceptors |
| Models | `freezed` + `json_serializable` |
| Local storage | `hive_ce` (cache, offline saved articles), `flutter_secure_storage` (tokens) |
| i18n | `flutter_localizations` + `intl` (ARB files `ar`, `en`) |
| Editor | `appflowy_editor` with RDoc converters |
| Code highlighting | `re_highlight` (light + dark themes) |
| Firebase | `firebase_messaging` (+ `flutter_local_notifications`), `firebase_database`, and `firebase_auth` **only** for `signInWithCustomToken` to read the Realtime Database (never for user sign-in). No Firebase Storage, Crashlytics or Analytics. |
| Phone input | `phone_numbers_parser` + bundled-asset flags |
| Images | `flutter_image_compress` (before upload), `cached_network_image`, `flutter_blurhash` |
| Testing | `flutter_test`, `bloc_test`, `mocktail`, golden tests (RTL/LTR × light/dark), `integration_test` |

### 3.4 Shared / Tooling
- **Design tokens** defined once in `design/tokens.json` and generated for CSS variables (web) and Dart `ThemeExtension` (mobile).
- **RDoc JSON Schema** in `shared/rdoc/rdoc.schema.json`, used by the backend validator and both clients.
- **OpenAPI** contract generated from the API and used to generate the Angular client.
- **GitHub Actions** for CI/CD.

---

## 4. System Architecture

```text
 ┌──────────────────┐     ┌──────────────────┐
 │  Angular (SSR)   │     │  Flutter (iOS/   │
 │  Web             │     │  Android)        │
 └───┬─────────▲────┘     └───┬─────────▲────┘
     │ REST +  │ live reads   │ REST +  │ live reads
     │ JWT     │ + push       │ JWT     │ + push
     ▼         │              ▼         │
 ┌─────────────┼────────────────────────┼──────┐
 │           ReadIn.Api (ASP.NET Core)  │      │
 │  REST /api/v1 · Auth (JWT) · /uploads · Scalar
 ├─────────────────────────────────────────────┤
 │ Application: Commands / Queries (CQRS)      │
 │ Validation · Authorization · Caching        │
 ├─────────────────────────────────────────────┤
 │ Domain: Aggregates · Value Objects · Events │
 ├─────────────────────────────────────────────┤
 │ Infrastructure: EF Core · Dapper · Hangfire │
 │ Outbox · FCM sender · RTDB publisher        │
 │ wwwroot file storage · image/PDF pipeline   │
 └───────┬───────────────────┬─────────────────┘
         ▼                   ▼ (Admin SDK, writes only)
   ┌───────────┐    ┌─────────────────────────────┐
   │SQL Server │    │ Firebase                    │
   │ (truth)   │    │ · Cloud Messaging (push)    │
   └───────────┘    │ · Realtime Database (live)  │
                    └─────────────────────────────┘
```

**Firebase has exactly two jobs:** push notifications (FCM) and real-time updates for posts (Realtime Database). It is **not** used for sign-in, file storage, Firestore, crash reporting or analytics.
**SQL Server is the single source of truth** for all business data, including users, credentials and roles. The Realtime Database only holds small, disposable signals and counters that can be rebuilt from SQL Server at any time.

---

## 5. Repository Structure

Monorepo: `https://github.com/YoussefGhonem-hub/ReadIn`

```text
ReadIn/
├── README.md
├── .gitignore
├── .gitattributes
├── .editorconfig
├── .github/
│   └── workflows/              # backend.yml, web.yml, mobile.yml, content.yml
├── docs/
│   ├── SPEC.md                 # this document
│   ├── adr/                    # Architecture Decision Records
│   └── design/                 # approved UI/UX screens, logo
├── design/
│   └── tokens.json             # colors, typography, spacing (light + dark)
├── firebase/
│   └── database.rules.json     # Realtime Database security rules
├── shared/
│   ├── rdoc/
│   │   ├── rdoc.schema.json    # article content JSON Schema
│   │   └── examples/
│   ├── countries/
│   │   ├── countries.json      # generated from libphonenumber (dial codes, ar/en names)
│   │   └── phone-fixtures.json # shared phone parsing test cases
│   └── auth/
│       └── pin-fixtures.json   # shared weak-PIN test cases
├── backend/
│   ├── ReadIn.slnx
│   ├── Directory.Build.props
│   ├── Directory.Packages.props   # central package management
│   ├── src/
│   │   ├── ReadIn.Domain/
│   │   ├── ReadIn.Application/
│   │   ├── ReadIn.Infrastructure/
│   │   ├── ReadIn.Api/
│   │   │   └── wwwroot/uploads/   # user uploads (git-ignored, excluded from publish)
│   │   └── ReadIn.ContentStudio/  # content pipeline CLI (generate/validate/import)
│   └── tests/
│       ├── ReadIn.Domain.UnitTests/
│       ├── ReadIn.Application.UnitTests/
│       ├── ReadIn.Api.IntegrationTests/
│       └── ReadIn.ArchitectureTests/
├── web/                        # Angular workspace
├── mobile/                     # Flutter app
└── content/
    ├── taxonomy.yaml           # fields → topics → planned articles
    ├── glossary/               # glossary terms (ar/en)
    ├── paths/                  # learning paths
    └── articles/
        └── {field}/{topic}/{slug}/
            ├── meta.json       # status, version badge, sources, reviewer
            ├── en.json         # RDoc, English-only (source of truth)
            └── ar-EG.json      # RDoc, Egyptian Arabic + English terms
```

---

## 6. Backend: Clean Architecture + CQRS + Mapster

### 6.1 Layers & Dependency Rule

```text
Api ──► Application ──► Domain
 │           ▲
 └──► Infrastructure ──┘
```

| Layer | Contains | May depend on |
|---|---|---|
| **Domain** | Entities, aggregates, value objects, domain events, enums, domain errors, specifications | Nothing |
| **Application** | Commands, queries, handlers, validators, DTOs, Mapster configs, interfaces (`IAppDbContext`, `ICurrentUser`, `IPasswordHasher`, `IRecoveryPinHasher`, `ITokenService`, `IRefreshTokenStore`, `IPhoneNumberService`, `IPushSender`, `IRealtimePublisher`, `IFileStorage`, `IImageProcessor`, `IPdfProcessor`, `IDateTime`), pipeline behaviors | Domain |
| **Infrastructure** | EF Core DbContext & configurations, migrations, Dapper read queries, auth services (hashing, tokens), Firebase services (FCM sender, RTDB publisher), file storage + image/PDF pipeline, Hangfire jobs, Outbox processor, seeders | Application, Domain |
| **Api** | Endpoints (Minimal APIs grouped by feature), middleware, JWT Bearer setup, static files for `/uploads`, OpenAPI | Application, Infrastructure (composition root only) |

Enforced by **NetArchTest** in `ReadIn.ArchitectureTests` (e.g. Domain must not reference EF Core, Application must not reference Infrastructure).

### 6.2 Application Folder Layout (feature-sliced)

```text
ReadIn.Application/
├── Common/
│   ├── Behaviors/          # Validation, Logging, Authorization, Transaction, Caching
│   ├── Interfaces/
│   ├── Models/             # Result<T>, Error, PagedList<T>, CursorPage<T>
│   ├── Security/           # Permissions constants, [RequirePermission] attribute
│   └── Mapping/            # MappingRegistration (scans IRegister)
└── Features/
    ├── Auth/               # register, login, refresh, logout, recovery PIN, reset password
    ├── Media/              # image/PDF uploads, attachments
    ├── Realtime/           # realtime token, outbox → RTDB handlers
    ├── Articles/
    │   ├── Commands/
    │   │   ├── CreateArticle/
    │   │   │   ├── CreateArticleCommand.cs
    │   │   │   ├── CreateArticleCommandHandler.cs
    │   │   │   └── CreateArticleCommandValidator.cs
    │   │   ├── PublishArticle/
    │   │   └── ...
    │   ├── Queries/
    │   │   ├── GetArticleBySlug/
    │   │   │   ├── GetArticleBySlugQuery.cs
    │   │   │   ├── GetArticleBySlugQueryHandler.cs
    │   │   │   └── ArticleDetailsDto.cs
    │   │   └── ...
    │   └── ArticleMappings.cs   # Mapster IRegister
    ├── Comments/
    ├── Reactions/
    ├── Follows/
    ├── SavedArticles/
    ├── Feed/
    ├── LearningPaths/
    ├── Notifications/
    ├── Users/
    ├── Search/
    ├── Moderation/
    ├── Verification/
    └── Admin/
```

### 6.3 CQRS Rules
- **Commands** change state, return `Result` or `Result<TId>`, never return full entities.
- **Queries** never change state, use `AsNoTracking()` + Mapster `ProjectToType<TDto>()` (or Dapper for heavy feeds), and return DTOs only.
- One handler per command/query. Handlers are `internal sealed`.
- **Pipeline behaviors** (in order): `Logging → Authorization → Validation → Caching (queries) → Transaction (commands)`.
- Cache invalidation via tags (e.g. publishing an article invalidates `feed:*`, `article:{slug}`).
- Domain events raised inside aggregates are saved to an **Outbox** table in the same transaction, then processed by a Hangfire job (notifications, counters, search index updates).

```csharp
// Command
public sealed record CreateArticleCommand(
    Guid FieldId,
    Guid? TopicId,
    string Language,          // "ar-EG" | "en"
    string Title,
    string? Subtitle,
    JsonDocument Content,     // RDoc
    IReadOnlyList<string> Tags,
    IReadOnlyList<SourceInput> Sources) : ICommand<Result<Guid>>;

// Handler
internal sealed class CreateArticleCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, IRDocService rdoc)
    : ICommandHandler<CreateArticleCommand, Result<Guid>>
{
    public async ValueTask<Result<Guid>> Handle(CreateArticleCommand cmd, CancellationToken ct)
    {
        var content = rdoc.Parse(cmd.Content);           // validates + sanitizes
        if (content.IsFailure) return content.Error;

        var article = Article.CreateDraft(currentUser.Id, cmd.FieldId, cmd.TopicId);
        article.AddTranslation(cmd.Language, cmd.Title, cmd.Subtitle, content.Value);
        article.SetTags(cmd.Tags);
        article.SetSources(cmd.Sources.Adapt<List<ArticleSource>>());

        db.Articles.Add(article);
        await db.SaveChangesAsync(ct);
        return article.Id;
    }
}
```

### 6.4 Mapster Rules
- All mapping configuration lives in `IRegister` classes **inside Application**, one per feature (`ArticleMappings`, `CommentMappings`, ...).
- `TypeAdapterConfig` is registered once as a singleton; `config.Compile()` runs at startup in Development to fail fast on bad configs.
- Queries use `ProjectToType<TDto>()` so mapping is translated to SQL (no over-fetching).
- **Never** map request DTOs directly onto existing entities for updates. Updates go through domain methods (`article.UpdateTitle(...)`).
- Language-aware mapping: the requested language is passed via `MapContext` to pick the right translation, falling back to the source language.
- No mapping in Api or Domain layers.

```csharp
public sealed class ArticleMappings : IRegister
{
    public void Register(TypeAdapterConfig config)
    {
        config.NewConfig<Article, ArticleCardDto>()
            .Map(d => d.Title, s => s.Translations
                .Where(t => t.Language == MapContext.Current!.Parameters["lang"])
                .Select(t => t.Title).FirstOrDefault()
                ?? s.Translations.First(t => t.IsSource).Title)
            .Map(d => d.AuthorName, s => s.Author.DisplayName)
            .Map(d => d.IsReviewed, s => s.ReviewStatus == ReviewStatus.Approved);
    }
}
```

### 6.5 Error Handling
- `Result<T>` pattern with typed `Error` (`Validation`, `NotFound`, `Conflict`, `Forbidden`, `Unauthorized`).
- Mapped to RFC 9457 **ProblemDetails** with a stable `code` (e.g. `article.not_found`) that clients translate into Arabic/English.
- Unhandled exceptions → global exception handler → ProblemDetails 500 + Serilog with correlation id.

### 6.6 Domain Model (main aggregates)
| Aggregate | Key behavior |
|---|---|
| `User` | `Register`, `ChangePassword`, `ChangePhoneNumber`, `SetRecoveryPin`, `RecordFailedLogin`, `RecordFailedRecovery`, `RotateSecurityStamp`, `CompleteProfile`, `UpdateProfile`, `SetPreferences`, `Suspend`, `GrantRole`, `RecordReading` (streak logic) |
| `Article` | `CreateDraft`, `AddTranslation`, `SetAttachments`, `SubmitForReview`, `Approve`, `RequestChanges`, `Publish`, `Schedule`, `Archive`, `CreateRevision` |
| `MediaAsset` | `CreateImage`, `CreateDocument`, `MarkProcessing`, `MarkReady`, `MarkFailed` |
| `Comment` | `Create`, `Reply` (max depth 2), `Edit`, `SoftDelete`, `Pin` |
| `LearningPath` | `AddArticle`, `Reorder`, `Publish` |
| `VerificationRequest` | `Submit`, `Approve`, `Reject` |
| `Report` | `Open`, `Resolve`, `Dismiss` |

---

## 7. Web: Angular

### 7.1 Structure
```text
web/src/app/
├── core/
│   ├── auth/            # session (in-memory access token), auth/profile/onboarding/PIN guards, permission guards
│   ├── http/            # interceptors: auth token + single-flight refresh, Accept-Language, errors, loading
│   ├── i18n/            # Transloco config, ar.json / en.json
│   ├── theme/           # ThemeService (light/dark/system), token loader
│   ├── api/             # generated OpenAPI client
│   ├── realtime/        # RealtimeService (Firebase RTDB, browser only)
│   └── push/            # FCM web push + service worker registration
├── shared/
│   ├── ui/              # buttons, chips, cards, avatar, badges, bottom sheet, skeletons,
│   │                    # phone field + country picker, password field, PIN input,
│   │                    # media carousel, full-screen viewer
│   ├── rdoc/            # RDoc renderer components (one per block type)
│   ├── directives/      # autoDir, bdi helpers
│   └── pipes/           # relativeTime, readingTime, localizedNumber
├── layout/              # shell, top bar, side nav, bottom nav (mobile web)
└── features/
    ├── auth/  onboarding/  home/  explore/  article/  editor/
    ├── comments/  profile/  saved/  paths/  notifications/
    ├── search/  settings/  verification/  moderation/  admin/
```

### 7.2 Rules
- Standalone components, `OnPush` everywhere, Signals for local state, Signal Store for feature state.
- Lazy-loaded routes per feature.
- SSR: article pages, writer profiles, fields and paths are server-rendered. User-specific parts (reactions state, saved) hydrate on the client.
- `dir` and `lang` on `<html>` follow the UI language. Content blocks use their own `dir`.
- Theme applied before first paint (inline script + `theme` cookie for SSR) to avoid a flash.
- Responsive: mobile web uses the same bottom navigation as the app.

---

## 8. Mobile: Flutter

### 8.1 Structure
```text
mobile/lib/
├── main.dart
├── app/                 # App widget, router, theme, localization setup
├── core/
│   ├── di/              # get_it + injectable
│   ├── network/         # dio client, interceptors, api error mapping
│   ├── theme/           # tokens → ThemeData light/dark + ThemeExtensions
│   ├── l10n/            # app_ar.arb, app_en.arb
│   ├── storage/         # hive boxes, secure storage (refresh token)
│   ├── realtime/        # Firebase RTDB data source
│   ├── push/            # FCM + local notifications, deep-link routing
│   └── errors/          # Failure types
├── shared/
│   ├── widgets/         # phone field + country picker, password field, PIN input,
│   │                    # media carousel, full-screen viewer
│   └── rdoc/            # RDoc renderer widgets + editor converters
└── features/
    └── article/
        ├── data/         # datasources (remote/local), models, repository impl
        ├── domain/       # entities, repository contracts, use cases
        └── presentation/ # blocs/cubits, pages, widgets
    (auth, onboarding, home, explore, editor, comments, profile, saved,
     paths, notifications, search, settings, verification, moderation, admin)
```

### 8.2 Rules
- Presentation never calls Dio directly: `Page → Bloc → UseCase → Repository → DataSource`.
- Every screen built and golden-tested in **4 variants**: `ar/light`, `ar/dark`, `en/light`, `en/dark`.
- Offline: saved articles and today's article are cached for offline reading.
- Deep links and push notification taps open the exact article/comment.

---

## 9. Authentication: Phone + Password

### 9.1 Decisions
| Topic | Decision |
|---|---|
| Sign up / sign in | **Phone number + password only.** No SMS, no OTP, no email login, no Google/Apple. |
| Who handles auth | The **.NET backend** (own JWT). Firebase Auth is **not** used for sign-in. |
| Forgot password | **Recovery PIN** (4 digits, set at sign up): phone + PIN → new password. |
| Last fallback | "نسيت الـ PIN كمان؟" → contact support → an Admin resets the password. |
| Guests | Can browse and read without an account. |

**Known trade-off:** without SMS, the app cannot prove that a user owns the phone number. This is mitigated by the "confirm your number" step at sign up, the recovery PIN and owner notifications.

### 9.2 Screens & Flows (web + mobile, identical)
Every screen supports ar/en × light/dark, has loading and error states, and prevents double submits. Shared components: phone field + country picker ([§9.4](#94-shared-input-components)), password field, PIN input.

```text
Welcome ─► Sign in ─────────────────────────────────────────────────────► Home
        ─► Create account (3 steps) ─► Complete profile ─► Onboarding ─► Home
Sign in ─► Forgot password ─► (phone + PIN) ─► New password ─► Sign in
```

**Welcome:** logo + tagline, "اعمل حساب جديد" (Create account), "عندي حساب، سجل دخول" (Sign in), "تصفح كزائر" (Browse as guest), UI language switcher.

**Sign in:**
- Phone field, password field, "نسيت كلمة السر؟" link, "سجل دخول" button, "معندكش حساب؟ اعمل حساب" link.
- Wrong credentials → one generic error: "رقم التليفون أو كلمة السر غلط" (never reveals whether the number exists).
- 5 wrong attempts → "محاولات كتير. جرّب تاني بعد 15 دقيقة". Suspended → "الحساب ده موقوف. تواصل مع الدعم".
- After success, guards apply in order: `MustChangePassword` → change password, `MustSetRecoveryPin` → set PIN, profile incomplete → Complete profile, onboarding not done → Onboarding, otherwise → Home.

**Create account (stepper "خطوة 1 من 3"):**
1. **Phone & password:** phone field, password + strength meter, confirm password, live rules checklist (8+ characters, a letter, a digit). Number already registered → "الرقم ده عليه حساب بالفعل" + Sign in action.
2. **Recovery PIN:** "اعمل PIN للطوارئ", explanation that it is needed if the password is forgotten, PIN input + confirm PIN. Errors for mismatch and weak PINs.
3. **Confirm your number** (dialog): the number in large LTR text with the warning "هتستخدم الرقم ده في تسجيل الدخول، ومش هتقدر تسترجع حسابك لو الرقم غلط." Buttons: "صح، اعمل الحساب" / "تعديل".

Then **Complete profile** (display name, unique `@username` with live availability check, optional avatar) → **Onboarding** ([F02](#f02--onboarding-3-steps)).

**Forgot password:**
1. Phone field (pre-filled from Sign in) + PIN input → "كمّل". Generic error "رقم التليفون أو الـ PIN غلط". Link "نسيت الـ PIN كمان؟" opens the contact-support sheet.
2. New password + strength meter + confirm → "احفظ". Success → Sign in with the number pre-filled and the banner "تم تغيير كلمة السر. سجل دخول بكلمة السر الجديدة". Expired reset token → "انتهت المهلة، ابدأ من الأول".

**Set recovery PIN (mandatory):** shown when `mustSetRecoveryPin = true` (accounts created before the PIN existed, admin-reset accounts, the production SuperAdmin). Cannot be skipped.

**Settings → Account:** see [F18](#f18--settings).

### 9.3 Tokens & Sessions
| Token | Details |
|---|---|
| Access token | JWT, **15 minutes**. Claims: `sub`, `security_stamp`. Signed with `Jwt:SigningKey`. Issuer, audience, lifetime and key are validated. |
| Refresh token | Random 256-bit, **30 days**, **rotating**, stored **hashed** in `RefreshTokens`. Reusing an already-rotated token revokes the whole token family (theft detection). |
| Reset token | Random 256-bit, **10 minutes**, single use, bound to the user and the creating IP, stored hashed. Issued after a correct recovery PIN. |

- An `IClaimsTransformation` loads roles & permissions from SQL Server (cached, invalidated on role change). Tokens whose `security_stamp` no longer matches are rejected.
- `SecurityStamp` changes on password change, password reset, phone change and "sign out of all devices", which signs out every other session.
- **Web:** refresh token in an `HttpOnly`, `Secure`, `SameSite=Strict` cookie (path `/api/v1/auth`); access token in memory only (never localStorage). On start (browser only) the app calls `/auth/refresh`. SSR of public pages is anonymous. The interceptor refreshes once on 401 (single-flight) and retries.
- **Mobile:** refresh token in `flutter_secure_storage`, access token in memory, Dio `QueuedInterceptor` with the same single-flight refresh. Splash → restore session → route by guards.
- Suspended users get `403` with code `user.suspended`.

### 9.4 Shared Input Components
**Phone field + country picker**
- Country list in `shared/countries/countries.json`, generated from libphonenumber (`iso2`, `dialCode`, `nameAr`, `nameEn`, `exampleNational`).
- Pinned first: Egypt, Saudi Arabia, UAE, Kuwait, Qatar, Bahrain, Oman, Jordan, Lebanon, Iraq, Morocco, Algeria, Tunisia, Libya, Sudan, Palestine, Syria, Yemen; then all other countries alphabetically in the UI language.
- Default country: last used → device/browser region → Egypt (+20).
- Picker: searchable by Arabic name, English name, ISO code and dial code. Web uses an accessible CDK overlay (bottom sheet on small screens) with SVG flags (`flag-icons`, because emoji flags don't render on Windows); mobile uses a full-height bottom sheet with bundled flags.
- The field is **always LTR**. Arabic-Indic (٠-٩) and Persian (۰-۹) digits are converted, pasted international numbers switch the country, the trunk prefix is stripped, and the number is formatted as you type.
- Validation with libphonenumber on all three platforms (mobile numbers only). The API always receives and stores **E.164** (`+201001234567`) and re-validates it.

**Password field:** show/hide toggle, always LTR, password-manager autofill hints. Rules: 8–128 characters, at least one letter and one digit, not in the 10,000 most common passwords, must not contain the phone number.

**PIN input:** separate boxes (length from `GET /auth/config`, default **4**, configurable via `Recovery:PinLength`), always LTR, numeric keyboard, masked with a show/hide toggle, paste support, Arabic-Indic digits converted. **Weak PINs are rejected** (same digit repeated, ascending/descending sequences, the 100 most common PINs, years 1950–2030, the last 4 digits of the phone number, the first 4 digits of the password).

### 9.5 Security Rules
| Area | Rule |
|---|---|
| Password hashing | `PasswordHasher<User>` (PBKDF2), rehash when needed. |
| PIN hashing | `PasswordHasher( HMACSHA256(pepper, userId + ":" + pin) )`. The **pepper** (`Security:RecoveryPinPepper`) lives only in secrets, never in the database, so a leaked database cannot be used to brute-force the 10,000 PINs offline. |
| Login lockout | 5 wrong attempts → locked 15 minutes. Rate limits: 5/min per phone, 20/min per IP. |
| Register | 3/hour per IP. |
| Recovery lockout | 5 wrong PINs → recovery locked 1 hour. 3 lockouts within 7 days → recovery disabled until an Admin reset. Rate limits: 10/hour per IP, 5/hour per phone. |
| Anti-enumeration | Generic errors for login and recovery; a dummy hash runs for unknown numbers so timing stays the same. |
| After reset / password change / phone change / sign out all | New `SecurityStamp`, all refresh tokens revoked, counters reset, audit log entry. |
| Owner notifications (push + in-app) | Recovery lockout, password changed, PIN changed, phone number changed. These ignore quiet hours. |
| Admin reset | Permission `users.reset_password`: temporary password + `MustChangePassword`, PIN cleared + `MustSetRecoveryPin`, `RecoveryDisabled = false`, sessions revoked, audit log. |
| PII | Phone numbers never appear in public DTOs (profiles, comments, articles); only in `GET /me` and admin endpoints with `users.read.pii`. Masked in logs (`+20******4567`). Passwords, PINs, hashes and tokens are never logged. |

> Roles and credentials are stored in **SQL Server** (source of truth).

---

## 10. Roles & Permissions

### 10.1 Roles
| Role | Description |
|---|---|
| **Guest** | Not signed in. Can browse and read published articles. |
| **Member** | Default for every signed-up user. Reads, interacts, and can write articles. |
| **VerifiedWriter** | Member whose identity/expertise is verified. Gets a badge, articles get priority in feeds. Required to publish in Medicine and Public Health. |
| **Reviewer** | Expert who reviews articles in assigned fields and grants the "Reviewed" badge. |
| **Moderator** | Handles reports, hides content, suspends users. |
| **Admin** | Manages fields, topics, paths, verification requests, featured content and roles (except SuperAdmin). |
| **SuperAdmin** | Full access, including managing Admins and system settings. |

Users can have multiple roles (e.g. `Member` + `VerifiedWriter` + `Reviewer`).

### 10.2 Permission-based Authorization
Endpoints require **permissions**, not roles. Roles are bundles of permissions.

| Permission | Guest | Member | Verified Writer | Reviewer | Moderator | Admin | Super Admin |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `articles.read` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `articles.create` | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `articles.publish.sensitive` (Medicine/Health) | | | ✅ | ✅ | | ✅ | ✅ |
| `articles.review` | | | | ✅ | | ✅ | ✅ |
| `articles.feature` | | | | | | ✅ | ✅ |
| `comments.create` / `reactions.create` | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `follows.manage` / `saved.manage` | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `reports.create` | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `moderation.manage` (hide content, resolve reports) | | | | | ✅ | ✅ | ✅ |
| `users.suspend` | | | | | ✅ | ✅ | ✅ |
| `users.reset_password` (admin password reset) | | | | | | ✅ | ✅ |
| `users.read.pii` (see phone numbers) | | | | | | ✅ | ✅ |
| `verification.manage` | | | | | | ✅ | ✅ |
| `taxonomy.manage` (fields, topics, tags) | | | | | | ✅ | ✅ |
| `paths.manage` | | | | | | ✅ | ✅ |
| `roles.manage` | | | | | | ✅* | ✅ |
| `system.settings` | | | | | | | ✅ |

\* Admin cannot grant or revoke `Admin` / `SuperAdmin`.

**Ownership rules:** a user can always edit/delete their own articles, comments and reactions. Editing a published article creates a new revision and resets the "Reviewed" badge if content changed significantly.

---

## 11. Features

> Every feature below ships on **Web + Mobile** (see [§12](#12-feature-parity-matrix-web--mobile)), supports **ar/en** and **light/dark**.

### F01 — Authentication & Account
- Sign up / sign in with **phone number + password only** (country picker, E.164). Full screens and rules in [§9](#9-authentication-phone--password).
- Sign up is a 3-step stepper: phone + password → recovery PIN → confirm your number.
- **Forgot password** with phone + recovery PIN → new password. "Forgot the PIN too" → contact support → Admin reset.
- Mandatory "set recovery PIN" screen for accounts without a PIN.
- Complete profile after sign up: display name, unique `@username`, optional avatar.
- Guest browsing with a soft prompt to sign in when trying to interact.
- Sign out, sign out of all devices, delete account (requires the password; soft delete then hard delete after 30 days, content attributed to "Deleted user").

### F02 — Onboarding (3 steps)
1. Welcome + value proposition.
2. **Choose interests** (fields/topics chips, minimum 3).
3. **Preferences:** article language (`مصري + English` / `English only`), daily reminder time (default 8:00 AM, user's time zone), notifications permission (asked here, in context, never on first launch).

### F03 — Home: "النهارده" (Today)
- Greeting + **streak badge** 🔥 + notifications bell.
- **Today's article (Hero card):** one reviewed article picked for the user (see [§11 F07](#f07--daily-article-مقال-النهارده)).
- Continue reading (resume last unfinished article).
- Learning path progress card.
- Field filter chips + feed: **For you** (interests + popularity + freshness) and **Following** tabs.
- Feed cards show attachments: a single image, an **image carousel** or a **PDF page carousel** ([F26](#f26--post-attachments--media)).
- Live counters on visible cards and a "مقالات جديدة ↑" banner when new articles are published ([F27](#f27--real-time-updates)).
- Infinite scroll with cursor pagination, skeleton loading, pull to refresh.

### F04 — Article Reader
- Reading progress bar, estimated reading time, table of contents for long articles.
- **Language toggle** per article: `مصري+EN` / `EN` (shown only when both versions exist).
- Trust row: verified writer badge, "✓ Reviewed by …", "Last reviewed: date", version badge (e.g. `.NET 10`), "AI-assisted" label when applicable.
- Rich RDoc rendering: headings, callouts (tip/warning/info/danger), code blocks with copy button and filename, code tabs (C# / TypeScript / Dart), tables, steps, quotes, images with captions, glossary terms (tap → definition sheet).
- **TL;DR summary** at the top (optional per article).
- **Sources** section at the bottom (mandatory for technical and health articles).
- Font size control (S / M / L / XL), reading mode toggle.
- Attachments (image carousel or PDF page carousel) with a full-screen viewer ([F26](#f26--post-attachments--media)).
- Floating action bar: reactions, comments, save, share. Reaction and comment counts update live ([F27](#f27--real-time-updates)).
- Remembers the last scroll position. Marks the article as "read" when ≥ 70% scrolled **and** ≥ 30 seconds spent.
- Related articles + "Next in path" at the end.
- Report article.

### F05 — Article Editor (Write)
- Block-based rich editor producing **RDoc**: all block types in [§13](#13-article-content-format-rdoc), slash menu (`/`) to insert blocks, markdown shortcuts.
- Per-block automatic direction (`dir="auto"`) with manual override, code blocks forced LTR.
- Cover image upload (compressed on the device, processed by the backend, stored in `wwwroot/uploads`), field, topic, tags (max 5).
- **Attachments:** 1–10 images **or** one PDF ([F26](#f26--post-attachments--media)). The attachment bar is one reusable component (web) / widget (mobile). Until the block editor ships, `/write` is a **post composer** that hosts it: field, language, title, plain-text body (paragraphs become RDoc `paragraph` blocks), sources and attachments, then create → set attachments → publish.
- **Sources** list (title + URL), required for Software, Medicine and Health fields.
- Second language version: add `en` or `ar-EG` translation of the same article.
- Autosave drafts every 10 seconds + local backup (offline-safe).
- Preview exactly as readers will see it (light/dark, ar/en).
- Publish now, schedule, or submit for review (sensitive fields).
- Revision history with restore.
- Live checks: missing sources, title length, missing alt text, reading time.

### F06 — Article Lifecycle
```text
Draft ──► Submitted ──► InReview ──► Approved ──► Published ──► Archived
              │                │
              │                └──► ChangesRequested ──► Submitted
              └── (non-sensitive fields may publish directly; review is optional)
```
- `Published` articles without review show no "Reviewed" badge but are visible.
- Medicine / Public Health articles **must** be approved by a Reviewer before publishing.
- Only reviewed articles are eligible for **Today's article**.

### F07 — Daily Article (مقال النهارده)
- Picked per user daily by a Hangfire job at the user's local time minus 30 minutes.
- **Algorithm:** reviewed + published, in user's interests, not read before, matches language preference, reading time 4–10 minutes, weighted by quality score (reactions, completion rate, freshness), not from the same field 3 days in a row, prefers the next item in the user's active learning path.
- Push notification at the chosen time: *"مقال النهارده جاهز ☕ — {title}"*.
- If the user doesn't open it, it stays as the hero card for the day.

### F08 — Streaks & Reading Stats
- Streak +1 per day the user completes at least one article (local time zone).
- **Streak freeze:** 1 free freeze per week, auto-used on a missed day.
- Stats: current streak, longest streak, articles read this week/month, minutes read, top fields, **reading heatmap** (GitHub-style, last 12 months).
- Milestone celebrations (7, 30, 100, 365 days) with a shareable card.

### F09 — Learning Paths (مسارات)
- Curated ordered series (e.g. "أساسيات ASP.NET Core — 10 مقالات").
- Enroll, progress bar, "next article", completion badge.
- Paths are created by Admins (and later by Verified Writers).

### F10 — Reactions
- Four reactions: 💡 مفيد (Insightful), ❤️ (Love), 🔥 (Fire), 🤯 (Mind-blown).
- One reaction per user per article (change or remove anytime).
- Counts per reaction, list of who reacted.

### F11 — Comments & Replies
- Threaded comments: top-level + replies (max depth 2, shown as one indented level with a connector line).
- Sort: **Top** / **Newest**.
- Like comments, reply, `@mention` users (notifies them), edit (shows "edited"), delete (soft).
- Writer badge "الكاتب" on the author's comments, author can **pin** one comment.
- Mixed Arabic/English input renders correctly (`dir="auto"` per comment).
- **Live:** new comments/replies appear without refreshing, edits/deletes update in place, and a "N تعليقات جديدة" pill appears when the user is scrolled away ([F27](#f27--real-time-updates)).
- Rate limit: 10 comments / minute per user. Report comment.

### F12 — Follow
- Follow writers and follow fields/topics.
- Followers / following lists with search.
- Following feed tab on Home.
- Suggested writers to follow (by field overlap).

### F13 — Saved Articles (Bookmarks)
- Save / unsave from card or reader.
- Saved list with filter by field and search.
- **Collections:** optional named lists (e.g. "Interview prep").
- Saved articles available **offline** on mobile.

### F14 — Profile
- Avatar, display name, username (`@handle`), verified badge, bio (mixed text), links (GitHub, LinkedIn, website), fields of expertise.
- Stats: articles, followers, following, total reads.
- Tabs: **Articles** / **Saved** (own profile only) / **Paths** / **About**.
- Reading stats card + heatmap (own profile, optional public).
- Edit profile, including avatar upload (compressed, square-cropped variants 64/128/256/512).
- The phone number is never shown on public profiles.

### F15 — Explore
- Browse by field → topic.
- Trending this week, most saved, new writers, featured paths.
- Top writers per field.

### F16 — Search
- Search articles, writers, topics and tags in Arabic and English.
- Arabic normalization (see [§22](#22-search)), filters (field, language, reading time, reviewed only), recent searches.

### F17 — Notifications
- In-app notification center (SQL `Notifications` table, live unread badge via Firebase Realtime Database) + push (FCM).
- Types: new follower, reply to your comment, mention, reactions milestone (10/50/100), comment on your article, article reviewed/approved/changes requested, verification result, daily article, streak reminder (evening, if not read yet), new article from a followed writer, **security alerts** (password/PIN/phone changed, recovery lockout).
- Per-type preferences (push / in-app / off), quiet hours. Details in [§21](#21-notifications--real-time).

### F18 — Settings
- Theme: **System / Light / Dark** (synced to profile across devices).
- UI language: العربية / English.
- Article language preference, daily reminder time, notification preferences, font size.
- Privacy: public reading stats on/off, who can mention me.
- **Account:**
  - Phone number (visible to the owner only) + "تغيير الرقم" (new number + current password + confirm-number dialog).
  - "تغيير كلمة السر" (current + new + confirm).
  - "تغيير الـ PIN" (current password + new PIN + confirm).
  - Sign out, sign out of all devices, delete account (requires the password).

### F19 — Writer Verification
- Request verification: field, job title, proof (LinkedIn/GitHub URL, certificate or syndicate card upload).
- Admin reviews and approves/rejects with a reason. Approved users get the `VerifiedWriter` role and badge.

### F20 — Review Workflow
- Reviewer queue filtered by assigned fields.
- Inline review notes per block, approve / request changes.
- Approved article shows "✓ Reviewed by {name}" + review date.

### F21 — Glossary (قاموس المصطلحات)
- Central glossary of technical terms (`Dependency Injection` → Arabic explanation + English definition + related articles).
- Writers mark a term in the editor, readers tap to see the definition.
- Seeded with 500+ software terms.

### F22 — Reporting & Moderation
- Report article/comment/user with reason (spam, misinformation, harassment, copyright, other).
- Moderation queue: hide/unhide content, warn, suspend (temporary/permanent) users, resolve reports.
- Full **audit log** of moderation actions.

### F23 — Admin Console
- Dashboard: daily active readers, articles read, new users, top articles, streak retention.
- Manage fields, topics, tags, learning paths, featured content.
- Manage users & roles, verification requests.
- Content pipeline status (generated / auto-checked / in review / published counts).
- Available on **web and mobile** (mobile uses a compact layout).

### F24 — Sharing
- Share article link (deep link opens app if installed, otherwise web).
- Share a **quote card**: select text → generate an image (light/dark) for social media.

### F25 — Offline & Resilience (mobile + web PWA basics)
- Today's article and saved articles cached for offline reading.
- Queued actions (reactions, saves) replay when back online.

### F26 — Post Attachments & Media
A post/article has **either** 1–10 images **or** exactly one PDF (never both), like LinkedIn.

**Composer / editor**
- Attachment bar: "📷 صور" (Images) and "📄 ملف PDF" (PDF document).
- Images: multi-select up to 10, drag to reorder, remove, optional caption per image (`dir="auto"`, max 5000 characters), **required alt text** per image (max 5000 characters; publishing is blocked until every image has one). Both are multi-line fields that grow with their text; a character counter appears only in the last 500 characters.
- PDF: one file, max 20 MB, max 100 pages, required document title (pre-filled from the file name, max 5000 characters, no line breaks), "السماح بتحميل الملف" (Allow download) toggle, off by default. Shows "بنجهز الصفحات…" while processing, then a preview.
- Each upload shows progress, cancel and retry. Publishing is blocked while anything is uploading or processing.

**Display (feed card + post/article page)**
- One image → full width. Two or more images, or a PDF → **carousel**:
  - Horizontal scroll-snap; the next slide peeks from the edge; counter badge "3 / 12".
  - Desktop web: round ❮ ❯ arrows on hover (hidden at the ends) + keyboard ← →. Touch: swipe.
  - Optional caption bar under image slides.
  - RTL: starts from the right in the Arabic UI, arrows mirrored.
  - Only about 3 slides around the current one are rendered; BlurHash placeholders while loading.
- PDF: header strip "📄 {title} · 12 صفحة", page slides, and a "+N صفحة، افتح الملف" card after 10 pages.
- **Full-screen viewer:** swipe/arrows, pinch and double-tap zoom, counter + thumbnail strip (PDF), close with ✕ / back / swipe down, "تحميل" (Download, only when allowed) and "مشاركة" (Share).

**Image optimization (all images in the app)**
- Compressed on the device **before upload** (max 2048px, quality 85, orientation fixed).
- Re-processed by the backend (never trusts the client): metadata and GPS stripped, sRGB, **WebP variants** (quality 78, never upscaled) and a **BlurHash**:

| Purpose | Variant widths |
|---|---|
| Avatar | 64, 128, 256, 512 (square crop) |
| Cover | 400, 800, 1200 |
| Post / article image | 320, 640, 1080, 1600 |
| PDF page | 400 (thumbnail), 1080 (viewer) |

- Clients load the smallest variant that fits (`srcset` on web, width × pixel ratio on mobile), lazy-load off-screen images and always reserve the image size (no layout shift).
- Budgets: typical feed image ≤ 150 KB, avatar ≤ 30 KB.

**PDF processing** (background job, never in the request)
- Validation: `%PDF-` magic bytes, size/page limits; encrypted or corrupted files are rejected ("الملف ده عليه باسورد، ارفعه من غير باسورد").
- Page 1 is rendered first so the preview appears quickly, then the rest. Text is extracted for search ([§22](#22-search)).
- Status `Processing → Ready / Failed`; clients poll the upload status and also get a live signal ([F27](#f27--real-time-updates)).
- Per-job timeout, limited concurrency and capped render DPI.

**Quotas:** 50 uploads per user per day, 200 MB stored per user (configurable).

### F27 — Real-time Updates
Powered by **Firebase Realtime Database**, written only by the backend ([§21.2](#212-real-time-firebase-realtime-database)).
- Reader: reaction and comment counts update live.
- Comments: new comments/replies appear live with a short highlight, edits/deletes/likes update in place, "N تعليقات جديدة" pill when scrolled away.
- Feed: live counters on visible cards only, "مقالات جديدة ↑" banner.
- Notification bell: live unread badge.
- Upload processing status for the user's own PDFs.
- The user's own optimistic actions are not counted twice.
- If the Realtime Database is unavailable, everything still works through the REST API; only live updates are missing.

---

## 12. Feature Parity Matrix (Web + Mobile)

| ID | Feature | Web | Mobile | Phase |
|---|---|:-:|:-:|:-:|
| F01 | Authentication & Account | ✅ | ✅ | 1 |
| F02 | Onboarding | ✅ | ✅ | 1 |
| F03 | Home (Today) | ✅ | ✅ | 1 |
| F04 | Article Reader | ✅ | ✅ | 1 |
| F05 | Article Editor | ✅ | ✅ | 1 |
| F06 | Article Lifecycle | ✅ | ✅ | 1 |
| F07 | Daily Article | ✅ | ✅ | 1 |
| F08 | Streaks & Stats | ✅ | ✅ | 2 |
| F09 | Learning Paths | ✅ | ✅ | 2 |
| F10 | Reactions | ✅ | ✅ | 1 |
| F11 | Comments & Replies | ✅ | ✅ | 1 |
| F12 | Follow | ✅ | ✅ | 1 |
| F13 | Saved Articles | ✅ | ✅ | 1 |
| F14 | Profile | ✅ | ✅ | 1 |
| F15 | Explore | ✅ | ✅ | 2 |
| F16 | Search | ✅ | ✅ | 2 |
| F17 | Notifications | ✅ | ✅ | 2 |
| F18 | Settings (incl. Dark Mode) | ✅ | ✅ | 1 |
| F19 | Writer Verification | ✅ | ✅ | 2 |
| F20 | Review Workflow | ✅ | ✅ | 2 |
| F21 | Glossary | ✅ | ✅ | 3 |
| F22 | Reporting & Moderation | ✅ | ✅ | 2 |
| F23 | Admin Console | ✅ | ✅ | 2 |
| F24 | Sharing | ✅ | ✅ | 2 |
| F25 | Offline | ✅ | ✅ | 3 |
| F26 | Post Attachments & Media | ✅ | ✅ | 1 |
| F27 | Real-time Updates | ✅ | ✅ | 1 |

**Process:** each feature is one GitHub issue with three sub-tasks (`backend`, `web`, `mobile`). The issue closes only when all three are committed to `dev` (see [§29](#29-git-workflow--conventions)).

---

## 13. Article Content Format: RDoc

**RDoc (ReadIn Document)** is the canonical JSON format for article content. The backend validates it against `shared/rdoc/rdoc.schema.json` and sanitizes it. Web (Tiptap) and mobile (AppFlowy editor) convert to/from RDoc.

### 13.1 Document
```json
{
  "version": 1,
  "language": "ar-EG",
  "blocks": [ /* Block[] */ ]
}
```

### 13.2 Block Types
| Type | Attributes | Notes |
|---|---|---|
| `paragraph` | `dir`, `content: Inline[]` | |
| `heading` | `level: 2 \| 3`, `dir`, `content` | H1 is the article title, not a block |
| `bulletList` / `orderedList` | `items: Inline[][]`, `dir` | |
| `steps` | `items: { title, content }[]` | numbered visual steps |
| `quote` | `content`, `cite?` | |
| `callout` | `variant: tip \| info \| warning \| danger`, `title?`, `content` | 💡 ℹ️ ⚠️ ⛔ |
| `code` | `lang`, `filename?`, `code`, `highlightLines?` | **always LTR** |
| `codeTabs` | `tabs: { label, lang, code }[]` | e.g. C# / TypeScript / Dart |
| `table` | `header: Inline[][]`, `rows: Inline[][][]`, `dir` | comparison tables |
| `image` | `src`, `alt` (required), `caption?`, `darkSrc?` | `darkSrc` for diagrams in dark mode |
| `divider` | | |
| `embed` | `provider: youtube \| github-gist`, `url` | allow-listed providers only |
| `summary` | `content` | TL;DR box at the top |

`dir` values: `auto` (default), `rtl`, `ltr`.

**Attachments are not blocks.** A post's image carousel or PDF ([F26](#f26--post-attachments--media)) lives in `ArticleAttachments` and is rendered after the content, so RDoc stays a pure text format. If inline galleries inside an article are ever needed, they will be a new `gallery` block (`items: { src, alt, caption? }[]`, same `rdoc-asset://` sources and alt-text rule as `image`); the name is reserved and the schema rejects it until then ([ADR 0011](adr/0011-media-pipeline-and-pdf-preview.md)).

### 13.3 Inline Nodes & Marks
- Inline nodes: `text`, `term` (glossary term id + display text), `mention` (user id), `hardBreak`.
- Marks: `bold`, `italic`, `code`, `link` (`href`, http/https only), `highlight`, `strike`.

### 13.4 Example
```json
{
  "version": 1,
  "language": "ar-EG",
  "blocks": [
    { "id": "b1", "type": "paragraph", "dir": "auto", "content": [
      { "type": "text", "text": "لو انت شغال بـ " },
      { "type": "text", "text": "ASP.NET Core", "marks": [{ "type": "bold" }] },
      { "type": "text", "text": "، أكيد شفت الـ " },
      { "type": "term", "termId": "dependency-injection", "text": "Dependency Injection" },
      { "type": "text", "text": " في كل حتة." }
    ]},
    { "id": "b2", "type": "callout", "variant": "tip", "content": [
      { "type": "text", "text": "استخدم " },
      { "type": "text", "text": "AddScoped", "marks": [{ "type": "code" }] },
      { "type": "text", "text": " لأي service بتتعامل مع DbContext." }
    ]},
    { "id": "b3", "type": "code", "lang": "csharp", "filename": "Program.cs",
      "code": "builder.Services.AddScoped<IOrderService, OrderService>();" }
  ]
}
```

### 13.5 Server-side Processing
On save, the backend:
1. Validates against the JSON Schema (unknown types/attributes rejected).
2. Sanitizes links (http/https only, `rel="nofollow ugc"` for user content) and embed URLs (allow-list).
3. Extracts **plain text** (for search + reading time), **headings** (TOC), **terms** used, **code languages**.
4. Calculates reading time (Arabic ≈ 180 wpm, English ≈ 230 wpm, code blocks counted separately).

---

## 14. Bilingual & Bidirectional Text (BiDi)

### 14.1 Two Language Axes
| Axis | Values | Controls |
|---|---|---|
| **UI language** | `ar`, `en` | App strings, layout direction (RTL/LTR) |
| **Article language** | `ar-EG`, `en` | Which article version is shown |

They are independent: an English UI user can read `ar-EG` articles and vice versa.

### 14.2 Rendering Rules (Web + Mobile)
1. Every block is rendered with its own direction (`dir="auto"` on web, `Directionality` from first strong character on Flutter).
2. Inline English inside Arabic is wrapped in **`<bdi>`** (web) / Unicode isolates `U+2068 … U+2069` (Flutter) so punctuation and word order never break.
3. `code` and `codeTabs` blocks are **always LTR** with left-aligned text, even inside RTL articles.
4. Numbers: Western digits (0–9) everywhere for consistency with code.
5. Icons with direction (back arrow, chevrons, progress) mirror in RTL. Icons without direction (play, check) do not.
6. Mixed text in titles, comments, bios and search inputs uses the same rules.
7. **Test fixtures:** a shared set of tricky mixed-text samples (punctuation at the end of English words, parentheses, numbers, URLs, `@mentions`) used in web and mobile tests.

### 14.3 Writing Style for `ar-EG` Content
- Clear, friendly Egyptian Arabic understandable by all Arabs (no heavy slang).
- Technical terms stay in **English** (`Dependency Injection`, not "حقن الاعتماديات"), optionally with a short Arabic explanation on first use.
- The `ar-EG` version is a **natural adaptation** of the English source, not a literal translation.

---

## 15. Design System & Dark Mode

### 15.1 Brand
- **Name:** ReadIn (always written in English, also in the Arabic UI).
- **Taglines:** "ReadIn — مقال كل يوم يفرق معاك" / "Read daily. Grow daily."
- **Logo:** approved logo in `docs/design/`. Must not resemble LinkedIn (no LinkedIn blue, no identical "in" box).
- **Mood:** calm, premium, editorial. "Medium meets Duolingo".

### 15.2 Color Tokens
| Token | Light | Dark | Usage |
|---|---|---|---|
| `color.primary` | `#0F5E52` | `#3FB8A3` | Buttons, links, logo, active states |
| `color.primary.container` | `#E3F1EE` | `#16302A` | Selected chips, soft backgrounds |
| `color.accent` | `#F2A93B` | `#F5B95A` | Streaks, highlights, badges |
| `color.bg` | `#FAF8F4` | `#121413` | App background |
| `color.surface` | `#FFFFFF` | `#1B1E1C` | Cards, sheets |
| `color.surface.raised` | `#FFFFFF` | `#232624` | Dialogs, menus |
| `color.border` | `#E8E4DC` | `#2E322F` | Dividers, outlines |
| `color.text.primary` | `#1A1A1A` | `#ECEAE6` | Main text |
| `color.text.secondary` | `#6B6B6B` | `#A3A39E` | Meta text |
| `color.callout.tip` | `#E8F3EF` | `#16302A` | 💡 Tip |
| `color.callout.info` | `#EEF1F5` | `#1E2530` | ℹ️ Info |
| `color.callout.warning` | `#FDF3E1` | `#3A2E17` | ⚠️ Warning |
| `color.callout.danger` | `#FBEAEA` | `#3A1E1E` | ⛔ Danger |
| `color.code.bg` | `#1E2321` | `#0E100F` | Code blocks (dark in both modes) |
| `color.success` / `color.error` | `#2E7D5B` / `#C0392B` | `#5CC594` / `#E5675A` | States |

All text/background pairs must pass **WCAG AA** contrast in both modes.

### 15.3 Typography
| Role | Font | Size / Line height |
|---|---|---|
| UI (Arabic + English) | **IBM Plex Sans Arabic** / **IBM Plex Sans** | 14–16px / 1.5 |
| Article body | IBM Plex Sans Arabic / IBM Plex Sans | 17–18px / **1.8** |
| Headings | IBM Plex Sans Arabic SemiBold | 22 / 28 / 32px |
| Code | **JetBrains Mono** | 14px / 1.6 |

### 15.4 Shape & Spacing
8pt grid · card radius 16px · chip radius 999px · soft shadows (light) / subtle borders instead of shadows (dark) · line icons (Lucide on web, matching set on mobile).

### 15.5 Dark Mode Rules (mandatory)
1. Modes: **System** (default), **Light**, **Dark**. Stored locally and synced to the user profile.
2. **Tokens only:** no hex colors in components. Web uses CSS variables on `:root[data-theme]`, Flutter uses `ThemeData` + `ThemeExtension<ReadInColors>`.
3. Dark mode uses warm near-black (`#121413`), never pure `#000000`.
4. Elevation in dark mode via lighter surfaces, not shadows.
5. Images: diagrams support `darkSrc`. Avatars/photos get a subtle border in dark mode.
6. Code highlighting has matching light/dark themes (Shiki / re_highlight).
7. No theme flash on web (theme resolved before first paint, SSR reads the `theme` cookie).
8. Shareable quote cards, emails and push images exist in light and dark variants.
9. **Every UI change is covered by light + dark screenshots** (ar + en) for web and mobile: Playwright screenshots on web, golden tests on mobile.

---

## 16. Database Design

### 16.1 Conventions
- SQL Server, EF Core migrations in `ReadIn.Infrastructure`.
- Primary keys: `uniqueidentifier`, generated by **EF Core's default Guid generation** (`ValueGeneratedOnAdd`). On SQL Server, EF Core uses its sequential GUID generator, whose values follow SQL Server's `uniqueidentifier` sort order, so inserts stay ordered in the clustered index. Keys are assigned when an entity is added to the `DbContext`; domain code never generates them, and `Guid.CreateVersion7()` is not used for keys (v7 GUIDs are not sequential under SQL Server's ordering). Domain events are materialized at `SaveChanges`, after keys exist. Fixed reference keys (roles, system accounts) stay explicit constants; every other seeded row is upserted by its natural key (role name, permission code, field slug, email, article slug). See [ADR 0006](adr/0006-sequential-guids.md).
- Audit columns on all tables: `CreatedAt`, `CreatedBy`, `UpdatedAt`, `UpdatedBy` (UTC `datetime2`).
- Soft delete: `IsDeleted`, `DeletedAt` with global query filters.
- Text columns used for search use collation **`Arabic_100_CI_AI`** (ignores case and diacritics).
- `rowversion` concurrency token on aggregates (Articles, Comments, Users).
- Counters (reactions, comments, saves, reads) are denormalized on `Articles` and updated by outbox handlers.

### 16.2 Tables
| Area | Tables |
|---|---|
| Identity | `Users` (PhoneNumber E.164 `varchar(16)` unique, PasswordHash, SecurityStamp, FailedLoginCount, LockoutEndAt, MustChangePassword, RecoveryPinHash, RecoveryPinSetAt, RecoveryFailedCount, RecoveryLockoutEndAt, RecoveryDisabled, MustSetRecoveryPin, IsProfileComplete, Email (optional, never used for login), DisplayName, Username unique, AvatarUrl, Bio, Links JSON, UiLanguage, ArticleLanguagePref, ThemePref, TimeZone, ReminderTime, IsSuspended, SuspendedUntil), `Roles`, `Permissions`, `RolePermissions`, `UserRoles` |
| Auth | `RefreshTokens` (UserId, TokenHash, FamilyId, ExpiresAt, CreatedAt, CreatedByIp, DeviceName, RevokedAt, ReplacedById), `PasswordResetTokens` (UserId, TokenHash, ExpiresAt, UsedAt, CreatedByIp), `RecoveryAttempts` (UserId?, PhoneNumberHash, Ip, Succeeded, CreatedAt) |
| Devices | `UserDevices` (FCM token, platform, device name, app version, language, last seen) |
| Media | `MediaAssets` (OwnerId, Kind Image/Document, Purpose Image/Avatar/Cover/Document, Status Uploading/Processing/Ready/Failed, FailureReason (stable code), OriginalPath, OriginalSizeBytes, StoredBytes (quota), Width, Height, BlurHash, Variants JSON `{ "320": { height, path, bytes }, … }` + `ISJSON` check, PageCount, Title `nvarchar(max)` ≤ 5000 (`Arabic_100_CI_AI`), AllowDownload, ExtractedText `nvarchar(max)` (`Arabic_100_CI_AI`)), `MediaAssetPages` (AssetId + PageNo key, ThumbPath, ViewPath, Width, Height, BlurHash, Bytes), `ArticleAttachments` (ArticleId + MediaAssetId key, Order, Caption ≤ 5000, AltText ≤ 5000, both `nvarchar(max)`); see [ADR 0011](adr/0011-media-pipeline-and-pdf-preview.md) |
| Taxonomy | `Fields` (Slug, NameAr, NameEn, Icon, Color, IsSensitive, IsEnabled), `Topics`, `Tags`, `UserInterests` |
| Articles | `Articles` (AuthorId, FieldId, TopicId, Slug, Status, ReviewStatus, SourceLanguage, CoverUrl, IsAiAssisted, VersionBadge, LastReviewedAt, ReviewedById, PublishedAt, ScheduledAt, QualityScore, counters), `ArticleTranslations` (ArticleId, Language, Title, Subtitle, Summary, ContentJson `nvarchar(max)` + `ISJSON` check, PlainText, SearchText, ReadingTimeMinutes, IsSource), `ArticleRevisions`, `ArticleTags`, `ArticleSources` (Title, Url, LastCheckedAt, IsAlive), `ArticleReviews` (ReviewerId, Decision, Notes JSON) |
| Engagement | `Reactions` (UserId+ArticleId unique, Type), `Comments` (ArticleId, ParentId, AuthorId, Body, IsPinned, LikeCount, EditedAt), `CommentLikes`, `UserFollows` (FollowerId+FolloweeId), `FieldFollows`, `SavedArticles`, `Collections`, `CollectionItems` |
| Reading | `ReadingProgress` (UserId, ArticleId, Language, Percent, LastPosition, CompletedAt), `DailyPicks` (UserId, Date, ArticleId, OpenedAt), `UserStats` (CurrentStreak, LongestStreak, FreezesLeft, LastReadDate, TotalArticles, TotalMinutes), `ReadingDays` (heatmap) |
| Learning | `LearningPaths`, `LearningPathItems` (Order), `PathEnrollments` |
| Glossary | `GlossaryTerms` (Slug, TermEn, ExplanationAr, DefinitionEn, FieldId), `ArticleTerms` |
| Trust & Moderation | `VerificationRequests`, `Reports`, `ModerationActions`, `AuditLogs` |
| Notifications | `Notifications` (UserId, Type, Payload JSON, IsRead), `NotificationPreferences` |
| Infrastructure | `OutboxMessages`, `SeedHistory` (seeder name + version + checksum), Hangfire schema |

### 16.3 Key Indexes
- `Articles(Status, PublishedAt DESC)` filtered on `IsDeleted = 0`.
- `Articles(FieldId, Status, QualityScore DESC)`.
- `ArticleTranslations(ArticleId, Language)` unique.
- `Comments(ArticleId, ParentId, CreatedAt)`.
- `ReadingProgress(UserId, ArticleId)` unique.
- `Reactions(ArticleId, Type)`, `UserFollows(FolloweeId)`.
- Full-Text index on `ArticleTranslations(SearchText)`, `MediaAssets(ExtractedText)` and `Users(DisplayName, Username)` (created with F16 Search; the columns and their collation exist already).
- `Users(PhoneNumber)` unique, `RefreshTokens(TokenHash)` unique, `RefreshTokens(UserId, RevokedAt)`.
- `ArticleAttachments(MediaAssetId)` unique (an asset belongs to one post), `MediaAssets(OwnerId, CreatedAt)` (quotas), `MediaAssets(CreatedAt)` (orphan cleanup).
- Media paths are stored **relative** (`/uploads/...`); absolute URLs are built from `Storage:PublicBaseUrl`, so a domain change never needs a data migration.

---

## 17. API Design

### 17.1 Conventions
- REST, JSON, base path `/api/v1`, OpenAPI documented, Scalar UI at `/docs` (non-production).
- `Accept-Language: ar | en` controls error messages and taxonomy names. `?lang=ar-EG|en` selects the article version.
- Cursor pagination for feeds (`?cursor=...&limit=20`), offset pagination for admin tables.
- Idempotent `PUT`/`DELETE` for toggles (reactions, follow, save).
- Errors: ProblemDetails with `code`, `traceId` and `errors` (validation).

### 17.2 Main Endpoints
| Area | Endpoints |
|---|---|
| Auth | `GET /auth/config` (PIN length, password rules) · `POST /auth/register` (phone, password, pin) · `POST /auth/login` · `POST /auth/refresh` · `POST /auth/logout` · `POST /auth/logout-all` · `POST /auth/recovery/verify-pin` → reset token · `POST /auth/recovery/reset-password` |
| Me | `GET /me` (incl. `hasRecoveryPin`, `mustSetRecoveryPin`, `mustChangePassword`, `isProfileComplete`) · `PATCH /me` · `PUT /me/profile/complete` · `PUT /me/password` · `PUT /me/phone` · `POST /me/recovery-pin` (first set) · `PUT /me/recovery-pin` (change) · `PUT /me/preferences` · `PUT /me/interests` · `POST /me/devices` · `DELETE /me/devices/{token}` · `DELETE /me` · `GET /users/username-available?u=` |
| Real-time | `POST /realtime/token` (Firebase custom token, used only to read the Realtime Database) |
| Feed | `GET /feed/today` · `GET /feed/for-you` · `GET /feed/following` · `GET /feed/continue-reading` |
| Articles | `GET /articles/{slug}?lang=` · `POST /articles` · `PUT /articles/{id}` · `PUT /articles/{id}/translations/{lang}` · `POST /articles/{id}/submit` · `POST /articles/{id}/publish` · `POST /articles/{id}/schedule` · `DELETE /articles/{id}` · `GET /articles/{id}/revisions` · `GET /articles/{id}/related` · `PUT /articles/{id}/progress` |
| Reactions | `PUT /articles/{id}/reaction` · `DELETE /articles/{id}/reaction` · `GET /articles/{id}/reactions` |
| Comments | `GET /articles/{id}/comments?sort=top\|new` · `POST /articles/{id}/comments` · `POST /comments/{id}/replies` · `PATCH /comments/{id}` · `DELETE /comments/{id}` · `PUT /comments/{id}/like` · `POST /comments/{id}/pin` |
| Follow | `PUT /users/{id}/follow` · `DELETE /users/{id}/follow` · `GET /users/{id}/followers` · `GET /users/{id}/following` · `PUT /fields/{id}/follow` |
| Saved | `GET /me/saved` · `PUT /articles/{id}/save` · `DELETE /articles/{id}/save` · `CRUD /me/collections` |
| Users | `GET /users/{username}` · `GET /users/{username}/articles` · `GET /me/stats` |
| Taxonomy | `GET /fields` · `GET /fields/{slug}/topics` · `GET /tags?q=` |
| Paths | `GET /paths` · `GET /paths/{slug}` · `POST /paths/{id}/enroll` |
| Search | `GET /search?q=&type=articles\|users\|topics&field=&lang=` |
| Glossary | `GET /glossary/{slug}` · `GET /glossary?q=` |
| Notifications | `GET /notifications` · `POST /notifications/read` · `GET/PUT /me/notification-preferences` |
| Uploads & media | `POST /uploads/images` (purpose `image` \| `avatar` \| `cover`; `article-image` is still accepted) · `POST /uploads/documents` (PDF, `202` + processing) · `GET /uploads/{id}` (status, variants, pages) · `DELETE /uploads/{id}` · `PUT /articles/{id}/attachments` · `GET /documents/{assetId}/download` — contract in [`docs/api/contract-v1.md`](api/contract-v1.md) |
| Trust | `POST /verification-requests` · `GET /reviews/queue` · `POST /articles/{id}/reviews` |
| Moderation | `POST /reports` · `GET /moderation/reports` · `POST /moderation/actions` |
| Admin | `/admin/users`, `POST /admin/users/{id}/reset-password`, `/admin/roles`, `/admin/fields`, `/admin/topics`, `/admin/paths`, `/admin/verification-requests`, `/admin/dashboard`, `/admin/content-pipeline` |

---

## 18. Seeding: Users, Reference Data, Articles

### 18.1 Principles
- Seeders are **idempotent** (upsert by natural keys: role name, field slug, phone number, article slug) and **versioned** (`SeedHistory` stores name + version + checksum, so a seeder only re-runs when its data changes).
- Run on startup in Development, and via `dotnet run --project ReadIn.Api -- seed` in Production.
- Environment-gated: **demo users and demo interactions are seeded only into the local database** (`Development` and `Testing` environments), never into production.
- Passwords and PINs are **never** committed. They come from configuration: `Seed:DemoPassword`, `Seed:DemoPin` (must pass the weak-PIN policy), `Seed:SuperAdminPhone`, `Seed:SuperAdminPassword` (user-secrets locally, secret store in production).

### 18.2 Seeding Order
| # | Seeder | Environments |
|---|---|---|
| 1 | Roles & Permissions | All |
| 2 | Fields, Topics, Tags (from `content/taxonomy.yaml`) | All |
| 3 | System accounts (`ReadIn Editorial`, `SuperAdmin`) | All |
| 4 | Demo users (SQL Server) | Local only |
| 5 | Glossary terms | All |
| 6 | Articles (from `content/articles/`, status-aware) | All |
| 7 | Learning paths | All |
| 8 | Demo interactions (follows, reactions, comments, saves, reading history, streaks, sample image/PDF attachments) | Local only |

### 18.3 Seed Users
Users are created in SQL Server only (no Firebase Auth). Phone numbers use the reserved fictional range **+1 202 555 01XX** (555-0100 to 555-0199 are reserved for fiction, so they never belong to a real person).

| Phone | Display name | Roles | Recovery PIN | Environments |
|---|---|---|:-:|---|
| `+12025550100` | ReadIn Editorial (فريق ReadIn) | Member, VerifiedWriter | — | All (cannot sign in, author of seeded articles) |
| `+12025550101` | Super Admin | SuperAdmin | ✅ | Local |
| `+12025550102` | Admin User | Admin | ✅ | Local |
| `+12025550103` | Moderator User | Moderator | ✅ | Local |
| `+12025550104` | .NET Reviewer | Member, VerifiedWriter, Reviewer (.NET, Architecture) | ✅ | Local |
| `+12025550105` | AI Reviewer | Member, VerifiedWriter, Reviewer (AI, ML, Claude) | ✅ | Local |
| `+12025550106` | Verified Writer | Member, VerifiedWriter | ✅ | Local |
| `+12025550107` … `+12025550109` | Writer 1–3 | Member | ✅ | Local |
| `+12025550110` … `+12025550118` | Reader 1–9 | Member | ✅ | Local |
| `+12025550119` | Reader 10 | Member | ❌ (tests the mandatory "set PIN" screen) | Local |
| `+12025550120` | Suspended User | Member (suspended) | ❌ | Local |

**Production SuperAdmin:** seeded from `Seed:SuperAdminPhone` + `Seed:SuperAdminPassword` with `MustChangePassword = true` and `MustSetRecoveryPin = true`.

**Dev login panel (debug builds only):** lists the seed users with a PIN ✅/❌ indicator and signs in with one tap. It is compiled out / tree-shaken from production builds.

Demo users get realistic profiles (bios mixing Arabic and English, interests, avatars), follow relationships, reading history with streaks (e.g. `reader1` has a 12-day streak), comments and replies, reactions and saved articles, so every screen looks real in development.

> **No fake personas in production.** All seeded articles are published under **ReadIn Editorial** with the "AI-assisted" label.

---

## 19. Content Pipeline: 1000+ Trusted Articles

### 19.1 Target Taxonomy (Software)
| Field | Example topics | Target |
|---|---|---:|
| AI Fundamentals | AI concepts, prompt engineering, AI ethics, RAG, agents | 80 |
| Machine Learning | Supervised/unsupervised, feature engineering, evaluation, scikit-learn, MLOps | 100 |
| Deep Learning & LLMs | Neural networks, transformers, embeddings, fine-tuning, vector DBs | 80 |
| Claude & AI Coding Tools | Claude Code, CLAUDE.md, `/compact` & context management, Skills, Hooks, Subagents, MCP servers, Plugins, Claude API & tool use, prompt caching, community plugins (e.g. Superpowers, **labeled as community, not official**) | 60 |
| .NET | C#, ASP.NET Core, EF Core, Clean Architecture, CQRS, Mapster, minimal APIs, testing, performance | 180 |
| Frontend | HTML/CSS, TypeScript, Angular, React, state management, accessibility, performance | 150 |
| Mobile | Flutter, Dart, state management, Kotlin, Swift, app architecture, publishing | 120 |
| Databases | SQL Server, PostgreSQL, indexing, query tuning, NoSQL, Redis | 80 |
| DevOps & Cloud | Git, Docker, CI/CD, Kubernetes basics, Azure, observability | 70 |
| Software Architecture | SOLID, design patterns, DDD, microservices, system design | 60 |
| Security | OWASP Top 10, auth (OAuth/OIDC/JWT), secrets, secure coding | 40 |
| **Total** | | **1,020** |

Each planned article in `content/taxonomy.yaml` has: slug, field, topic, level (beginner/intermediate/advanced), learning path + order, target version (e.g. `.NET 10`), and official sources to cite.

### 19.2 Pipeline (`ReadIn.ContentStudio` CLI)
```text
taxonomy.yaml
   │
   ▼
1. Outline        → structured outline per article (sections, code examples, sources)
2. Draft (en)     → English RDoc, the SOURCE OF TRUTH, generated with Claude (model configurable)
3. Adapt (ar-EG)  → Egyptian Arabic + English terms, natural adaptation, same structure
4. Validate       → automatic checks (see 19.3)       status: AutoChecked / Failed
5. Review         → human Reviewer in the app          status: Approved / ChangesRequested
6. Import         → seeder imports into SQL Server     status: Published (drip schedule)
```

Commands:
```bash
dotnet run --project src/ReadIn.ContentStudio -- generate --field dotnet --limit 20
dotnet run --project src/ReadIn.ContentStudio -- validate --all
dotnet run --project src/ReadIn.ContentStudio -- import --status approved
```

### 19.3 Automatic Validation
| Check | How |
|---|---|
| Schema | Validate both files against `rdoc.schema.json` |
| Structure parity | `en` and `ar-EG` have the same sections, code blocks and sources |
| **Code compiles** | C# snippets compiled with Roslyn, TypeScript with `tsc`, Dart with `dart analyze` (snippets marked `"compile": false` are skipped intentionally) |
| Sources alive | Every source URL returns HTTP 200, preferred domains are official docs (learn.microsoft.com, angular.dev, docs.flutter.dev, official Anthropic docs, etc.) |
| Duplicates | Title + embedding similarity against existing articles |
| Quality | Length (800–2,000 words), reading time 4–10 min, at least one callout or code/table, alt text on images |
| Freshness | Version badge required for versioned technologies |

### 19.4 Publishing Strategy
- **Launch with ~200 reviewed articles** organized into learning paths.
- **Drip publishing** of the rest (e.g. 10–15 per day) as reviews complete, until 1,000+.
- Avoids "scaled content" SEO penalties and keeps quality high.
- Fast-moving topics (Claude, AI tools, framework versions) get a **re-verification job** every 90 days: sources re-checked, `LastReviewedAt` updated or the article flagged "may be outdated".

### 19.5 Content Files in Git
Approved content lives in `content/articles/` so it is versioned, reviewable in git history, and reproducible in every environment.

---

## 20. Trust & Content Quality

| Mechanism | Description |
|---|---|
| Verified writers | Identity/expertise verification with a badge |
| Reviewed badge | "✓ Reviewed by {name}" + date |
| Sources | Mandatory for technical and health content, shown at the end of every article |
| Version badge | e.g. `.NET 10`, `Angular 21`, `Flutter 3.x` |
| Last reviewed date | Shown on every article, re-verification for fast-moving topics |
| AI-assisted label | Shown on every AI-assisted article. Never hidden. |
| Tested code | Code snippets compiled in the content pipeline |
| Community signals | Reports for misinformation, quality score based on completion rate + reactions |
| Sensitive fields | Medicine/Public Health require reviewer approval and a disclaimer ("لا يغني عن استشارة الطبيب") |

---

## 21. Notifications & Real-time

### 21.1 Notifications
| Channel | Technology | Use |
|---|---|---|
| Push | **Firebase Cloud Messaging** (Android, iOS, Web Push) | Daily article, replies, mentions, followers, review results, security alerts |
| In-app | SQL `Notifications` table + live unread badge from the **Realtime Database** | Notification center |
| Email (Phase 3) | Transactional provider | Weekly digest, verification results |

- Pushes are sent **only** from outbox handlers and Hangfire jobs (`IPushSender` → `FcmPushSender`, multicast + batching), never inside request handlers.
- Every push also creates a `Notifications` row and increments `/live/users/{id}/unreadNotifications`.
- Device tokens: registered on sign-in/app start, refreshed when FCM rotates them, deleted on sign out, and removed when FCM reports them as invalid.
- Daily article and streak reminders are scheduled per user's **time zone** via Hangfire.
- Message language = the user's UI language. Aggregation: "أحمد و9 غيره عملوا رياكت على مقالك" instead of 10 pushes.
- Quiet hours respected (default 23:00 – 07:00); security alerts ignore quiet hours.
- Payloads carry a deep link (`readin://a/{slug}#comment-{id}`). Taps open the right screen from terminated, background and foreground states.
- Web: `firebase-messaging-sw.js` + VAPID key, foreground messages as an in-app toast. Mobile: `firebase_messaging` + `flutter_local_notifications`, Android 13+ `POST_NOTIFICATIONS`, iOS APNs.
- Permission is requested **in context** (onboarding reminder step or when enabling a notification type), never on first launch.

### 21.2 Real-time: Firebase Realtime Database
The Realtime Database (RTDB) was chosen over Firestore because Firestore bills every document read, which is expensive for frequently updated live counters.

**Principle: RTDB carries signals, not content.** Comment text, user data and phone numbers never go to RTDB. Clients update counters from RTDB and fetch full data from the REST API.

```text
/live/articles/{articleId}
    reactions: { insightful, love, fire, mindBlown }
    commentCount, saveCount, updatedAt
/live/articles/{articleId}/events/{pushId}
    { type: comment.created | comment.updated | comment.deleted
          | reply.created | comment.liked | comment.pinned,
      commentId, parentId?, at }
/live/feed
    latestPublishedAt
/live/users/{userId}
    unreadNotifications, lastNotificationAt
/live/users/{userId}/media/{assetId}
    status
```

- **Writes:** only the backend (`IRealtimePublisher` → `FirebaseRealtimePublisher`, Firebase Admin SDK), in outbox handlers **after** the SQL commit, with retry and backoff. If RTDB is down, the app keeps working through REST.
- **Cleanup:** a Hangfire job keeps events for 24 hours and at most 100 per article. A rebuild command recalculates all counters from SQL Server.
- **Access:** signed-in users get a Firebase **custom token** from `POST /realtime/token` and call `signInWithCustomToken` only to read RTDB (it is not a login method). Guests read public paths without a token. Signing out of ReadIn also signs out of Firebase.
- **Security rules** (`firebase/database.rules.json`): `/live/articles` and `/live/feed` are public read; `/live/users/$uid` is readable only when `auth.uid === $uid`; **no client writes anywhere**; everything else is denied.
- **Lifecycle:** web subscribes in the browser only (never during SSR) and cleans up on destroy; mobile cancels subscriptions in the Bloc's `close()` and pauses listeners in the background. Feed cards subscribe only while visible.

---

## 22. Search

- SQL Server **Full-Text Search** on `ArticleTranslations.SearchText` (Arabic word breaker for `ar-EG`, English for `en`), `MediaAssets.ExtractedText` (text of attached PDFs) + `Users`.
- **Documents:** the PDF job extracts each page's text with PdfPig and stores it Arabic-normalized (same rules as below) in `MediaAssets.ExtractedText` (up to 1,000,000 characters). Search results for a document point to the post it is attached to; unattached or unpublished documents are never returned.
- **Arabic normalization** into `SearchText` and on queries: remove diacritics (تشكيل) and tatweel (ـ), unify `أ إ آ → ا`, `ى → ي`, `ة → ه`.
- Ranking: full-text rank × quality score × freshness.
- Typo tolerance and suggestions in Phase 3 (or move to Azure AI Search / Elasticsearch if needed).

---

## 23. SEO

- Angular **SSR** for public pages: articles, profiles, fields, paths, glossary terms.
- Clean URLs: `/ar/a/{slug}`, `/en/a/{slug}`, `/@{username}`, `/f/{field}`, `/paths/{slug}`.
- `hreflang` between `ar` and `en` versions, canonical URLs.
- `schema.org/Article` structured data (author, datePublished, dateModified, reviewedBy).
- Dynamic `sitemap.xml` (split per language), `robots.txt`, Open Graph + Twitter cards with generated cover images.
- Core Web Vitals budget: LCP < 2.5s, CLS < 0.1, INP < 200ms.

---

## 24. Security

- **Authentication:** own JWT access tokens (15 min) validated on every request, rotating hashed refresh tokens with reuse detection, security-stamp invalidation. Full rules (hashing, PIN pepper, lockouts, anti-enumeration, owner alerts) in [§9.5](#95-security-rules).
- **Permission-based** authorization on every endpoint + ownership checks in handlers.
- FluentValidation for all commands, RDoc schema validation + sanitization for content (no raw HTML stored or rendered).
- Rate limiting per user/IP (login, register, recovery, refresh, comments, reactions, search, uploads).
- **Uploads:**
  - Images up to 10 MB (jpeg/png/webp/heic), PDFs up to 20 MB / 100 pages, validated by **magic bytes** (never the extension or Content-Type), images over 8000×8000 rejected.
  - Images re-encoded to WebP with metadata/GPS stripped; random GUID file names; path traversal blocked. HEIC is decoded by Magick.NET only when the magic bytes say HEIF, with the format forced and ImageMagick resource limits set; the pixels then go through the same SkiaSharp pipeline.
  - `/uploads` static files serve **only `.webp`** with `X-Content-Type-Options: nosniff`, `Cache-Control: public, max-age=31536000, immutable` and `Content-Security-Policy: default-src 'none'`. Everything else returns 404.
  - PDFs are **never** served as static files: only via `GET /documents/{assetId}/download` with permission checks (published post or owner; `AllowDownload` or owner/moderator), `Content-Disposition: attachment`, `nosniff` and `Content-Security-Policy: sandbox`.
  - PDF processing runs in background jobs on a dedicated Hangfire `media` queue: at most 2 jobs at a time, a 2-minute timeout per job (`media.processing_timeout`), PDFium calls serialized, and pages rendered at most 200 DPI and 1080 × 4320 px so a crafted page size can't exhaust memory. Encrypted (even owner-password-only) and corrupted PDFs are rejected in the request, before anything is stored.
  - Quotas: 50 uploads per user per rolling day, 200 MB stored per user (`Media:*` settings), `409 media.quota_daily` / `media.quota_storage`.
- **Firebase:** the Realtime Database rules allow no client writes; the service-account key lives only in secrets.
- CORS restricted to app origins (with credentials for the web origin), HTTPS only, HSTS, security headers (CSP, X-Content-Type-Options, Referrer-Policy).
- Secrets in user-secrets (dev) and a secret store (production), never in the repo: `Jwt:SigningKey`, `Security:RecoveryPinPepper`, seed passwords/PIN, the Firebase service-account JSON. `google-services.json` and `GoogleService-Info.plist` are git-ignored.
- **PII:** phone numbers are never in public DTOs and are masked in logs. Passwords, PINs, hashes and tokens are never logged.
- Audit log for admin/moderation actions and security events (password/PIN/phone changes, admin resets, sign out of all devices, account deletion).
- Dependabot + `dotnet list package --vulnerable` + `npm audit` + `flutter pub outdated` in CI.

---

## 25. Performance & Scalability

- Feeds via Dapper with covering indexes, cursor pagination, cached per user for 60s.
- Article details cached (`HybridCache`, tag-invalidated on update).
- Denormalized counters updated asynchronously via outbox.
- Images: compressed on the device before upload, served from `wwwroot/uploads` as WebP variants with `srcset`, lazy loading, BlurHash placeholders and immutable caching (see [F26](#f26--post-attachments--media) for budgets). A CDN can be put in front of `/uploads` later without code changes.
- **Image budgets:** a typical feed image ≤ 150 KB (the 640 px variant of a photo at WebP quality 78), avatars ≤ 30 KB (the 128/256 px variants; 512 only on the profile page), PDF page thumbs (400 px) for the feed and 1080 px pages only in the viewer. Feed cards carry at most 10 page thumbs; carousels render about 3 slides around the current one. Every image has width/height (or an aspect ratio) reserved before it loads, so images never cause layout shift (CLS 0).
- Real-time: counters and events through the Realtime Database instead of polling; subscriptions only for visible content.
- API response compression (Brotli), HTTP/2.
- Mobile: image caching, list virtualization, lazy RDoc rendering for long articles.
- Targets: p95 API latency < 200 ms for reads, < 400 ms for writes.

---

## 26. Accessibility

- WCAG 2.2 AA on web, platform accessibility on mobile (TalkBack / VoiceOver labels in ar + en).
- Color contrast verified in light and dark modes.
- Font scaling up to 200% without broken layouts.
- Keyboard navigation and visible focus states on web.
- Images require `alt` text (enforced by the editor and RDoc validation).
- Respect "reduce motion".

---

## 27. Testing Strategy

| Level | Backend | Web | Mobile |
|---|---|---|---|
| Unit | Domain + handlers + validators + Mapster configs (`config.Compile()` test) | Components, stores, pipes | Blocs, use cases, repositories |
| Integration | API + SQL Server via Testcontainers, Realtime Database emulator, temporary uploads folder | API client contract tests | Repository + Dio mocks |
| Security rules | Realtime Database rules tests (`@firebase/rules-unit-testing`) | — | — |
| Architecture | NetArchTest (layer rules, naming, sealed handlers) | ESLint boundaries | `import_lint` rules |
| UI / Visual | — | Playwright screenshots: ar/en × light/dark | Golden tests: ar/en × light/dark |
| E2E | — | Playwright critical flows | `integration_test` critical flows |
| BiDi | RDoc text extraction tests | Mixed-text fixtures | Mixed-text fixtures |

**Critical flows (E2E on both platforms):** sign up (phone + password + PIN) → complete profile → onboarding → read today's article → react → comment → reply → save → follow writer → switch theme → switch article language → sign out → forgot password (phone + PIN) → sign in with the new password.

**Shared fixtures** used on all three platforms: mixed-text samples, `shared/countries/phone-fixtures.json`, `shared/auth/pin-fixtures.json`, and small test PDFs (normal, encrypted, corrupted, 101 pages).

Coverage targets: Domain/Application ≥ 80%, clients ≥ 60%.

---

## 28. DevOps, Environments & CI/CD

### 28.1 Environments
There is **one** real Firebase project, used **only** for Cloud Messaging and the Realtime Database. Local development and automated tests use the **Realtime Database emulator** (FCM has no emulator).

| Env | Purpose | Firebase | Data |
|---|---|---|---|
| Local (+ all automated tests) | Development, CI | **Realtime Database emulator** (port 9000), project `demo-readin`; pushes go to `LoggingPushSender` (logged + visible on a debug-only "Sent pushes" admin page) | Docker SQL Server, full demo seed (demo users + demo interactions), local `wwwroot/uploads` |
| Production | Deployed app | **The single real Firebase project** (FCM + Realtime Database) | Reference data + editorial content + system accounts only, production `wwwroot/uploads` |

- **Demo users and demo interactions are seeded only into the local database**; demo seeders run only in `Development` and `Testing`.
- There is no staging Firebase project. Switching between the emulator and the real project is a configuration choice per platform:

| Platform | Emulator (default) | Real project |
|---|---|---|
| Backend | `Firebase:UseEmulator = true` (`appsettings.Development.json`) | `Firebase:UseEmulator = false` + `Firebase:ProjectId` + `Firebase:DatabaseUrl` + service-account JSON from secrets |
| Web | `environment.development.ts` (RTDB emulator URL set) | `environment.ts` (production build, VAPID key) |
| Mobile | `dev` flavor (`--dart-define-from-file=config/dev.json`) | `prod` flavor (`config/prod.json`) |

Step-by-step creation and wiring of the real project: [`docs/setup/firebase.md`](setup/firebase.md) ([ADR 0005](adr/0005-single-firebase-project.md)).

### 28.2 Local Setup
- `docker compose up` → SQL Server (host port **14333**, because a local SQL Server already uses 1433) + Seq.
- `firebase emulators:start` → Realtime Database emulator only.
- Backend: `dotnet run --project backend/src/ReadIn.Api` (migrates + seeds in Development, creates `wwwroot/uploads` if missing).
- Web: `npm start` in `web/`. Mobile: `flutter run` in `mobile/` (flavors: `dev` = emulator, `prod` = real project).
- Required secrets (`dotnet user-secrets`): `Jwt:SigningKey`, `Security:RecoveryPinPepper`, `Seed:DemoPassword`, `Seed:DemoPin`.

### 28.3 Uploads in Production (`wwwroot/uploads`)
Uploads live inside the API folder, so deployments must never delete them:
- `wwwroot/uploads/` is git-ignored (only a `.gitkeep` is committed) and **excluded from `dotnet publish`** (`<Content Update="wwwroot\uploads\**" CopyToPublishDirectory="Never" />`).
- Deploy methods that wipe the target folder (e.g. "remove additional files at destination") must exclude `wwwroot/uploads`. With Docker, `wwwroot/uploads` is a named **volume**.
- IIS / Windows Server: the app pool identity gets write permission on `wwwroot/uploads` only.
- At startup the API creates the folder if missing and fails fast with a clear log message if it isn't writable.
- **Backups:** back up `wwwroot/uploads` together with the SQL Server database; restoring one without the other breaks images.
- Configuration: `Storage:UploadsPath` (default `wwwroot/uploads`; on servers it may point **outside** the app folder, which no deploy tool can touch) and `Storage:PublicBaseUrl` (e.g. `https://api.readin.app`).
- **Limitation:** with more than one API server, uploads must move to shared or cloud storage by swapping the `IFileStorage` implementation (no Application code changes).
- Details, per-tool exclusions (Web Deploy, robocopy/rsync, Docker, IIS, App Service) and a scheduled backup script: [`docs/setup/deployment.md`](setup/deployment.md). Decision, risks and migration path: [ADR 0010](adr/0010-uploads-in-wwwroot.md).

### 28.4 CI/CD (GitHub Actions)
| Workflow | Trigger | Steps |
|---|---|---|
| `backend.yml` | changes in `backend/**` | restore → build → test (Testcontainers) → architecture tests → publish image |
| `web.yml` | changes in `web/**` | install → lint → test → Playwright (ar/en × light/dark) → build SSR |
| `mobile.yml` | changes in `mobile/**` | analyze → test → golden tests → build APK/IPA (release on tags) |
| `content.yml` | changes in `content/**` | RDoc schema validation → code compile checks → link checks |

Deploy targets (suggested): API + SSR on a single server or container host (with the uploads rules in [§28.3](#283-uploads-in-production-wwwrootuploads)), SQL Server, mobile via Play Console / App Store Connect (Fastlane).

---

## 29. Git Workflow & Conventions

- **Branches:** exactly two. `main` (production) and `dev` (all development). No `feature/*`, `fix/*` or `content/*` branches.
- All work is committed **directly to `dev`**, one or more commits per feature. `dev` is pushed after each feature passes its quality gates: backend build + all tests (unit, integration, architecture), web lint + unit tests + SSR build, mobile `flutter analyze` + all tests including goldens, and clean `npm audit` / `dotnet list package --vulnerable`.
- **No pull requests per feature.** There is exactly **one** pull request, `dev → main`, opened only when the product owner asks for a release. Nothing is pushed to `main` directly.
- **Conventional Commits** with scope: `feat(backend): ...`, `feat(web): ...`, `feat(mobile): ...`, `fix(...)`, `test(...)`, `refactor(...)`, `content(dotnet): ...`, `docs: ...`, `chore(ci): ...`.
- Each feature tracks `backend`, `web` and `mobile` parts (see [§12](#12-feature-parity-matrix-web--mobile)); it is done when all three are committed to `dev`.
- Secrets are never committed: the Firebase service-account key, `google-services.json`, `GoogleService-Info.plist`, `Jwt:SigningKey`, `Security:RecoveryPinPepper`, passwords and PINs.
- Architecture decisions recorded as ADRs in `docs/adr/`. Existing: 0001–0006, `0010-uploads-in-wwwroot.md`, `0011-media-pipeline-and-pdf-preview.md`. To add with the v1.1 changes: `0007-phone-password-authentication.md` (supersedes 0001 and the auth part of 0004), `0008-firebase-scope-fcm-and-rtdb.md`, `0009-recovery-pin.md`.

---

## 30. Roadmap

| Phase | Scope |
|---|---|
| **0 — Foundation** | Repo, solution skeleton, CI, design tokens, RDoc schema, Firebase project + emulators, seeders for roles/fields/users |
| **1 — MVP** | F01–F07, F10–F14, F18, F26, F27 · phone + password auth with recovery PIN · ~200 reviewed seeded articles · Web + Mobile beta |
| **2 — Growth** | F08, F09, F15–F17, F19, F20, F22–F24 · drip publishing toward 1,000+ articles |
| **3 — Depth** | F21, F25, email digest, quizzes at the end of articles, text-to-speech, AI translation for user articles, Medicine/Engineering/Public Health fields |

---

## 31. Definition of Done

A feature is **done** only when:

- [ ] Backend: command/query handlers, validators, Mapster configs, permissions, unit + integration tests.
- [ ] **Web** implemented and tested.
- [ ] **Mobile** implemented and tested.
- [ ] Works in **Arabic (RTL)** and **English (LTR)**, including mixed-text content.
- [ ] Works in **Light** and **Dark** mode (Playwright screenshots on web, goldens on mobile).
- [ ] Empty, loading and error states designed and implemented.
- [ ] Accessibility checks pass (contrast, labels, font scaling).
- [ ] Seed data updated so the feature is visible in development.
- [ ] API documented in OpenAPI, ADR added if an architectural decision was made.
- [ ] CI green on all affected workflows.

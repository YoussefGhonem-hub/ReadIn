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
>
> **v1.2 changes (2026-11-03):** no article review and no scheduling: anyone publishes in any field; the F05 editor keeps a private working copy of published articles until **Update**; Today's article can be any published article, ranked by a quality score ([ADR 0015](adr/0015-open-publishing-and-the-editor.md), which supersedes the review part of ADR 0014).

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
9. [Authentication: Phone, Google, Apple](#9-authentication-phone-google-apple)
10. [Roles & Permissions](#10-roles--permissions)
11. [Features](#11-features)
12. [Feature Parity Matrix (Web + Mobile)](#12-feature-parity-matrix-web--mobile)
13. [Article Content Format: RDoc](#13-article-content-format-rdoc)
14. [Bilingual & Bidirectional Text (BiDi)](#14-bilingual--bidirectional-text-bidi)
15. [Design System & Dark Mode](#15-design-system--dark-mode)
16. [Database Design](#16-database-design)
17. [API Design](#17-api-design)
18. [Seeding: Users, Reference Data, Articles](#18-seeding-users-reference-data-articles)
19. [Content Pipeline: 300 Seed Articles](#19-content-pipeline-300-seed-articles)
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
ReadIn is a bilingual (Arabic + English) knowledge platform where **anyone can publish beautifully formatted articles about any topic**, and readers build a habit of reading **one valuable article every day** in the field they love.

### 1.2 Problem
- Existing platforms (Medium, LinkedIn Articles, Substack, Dev.to) handle Arabic poorly. Mixing Arabic and English in one paragraph breaks punctuation, word order and code blocks.
- Arabic knowledge content is either editorial-only (no community) or discussion-only (no long-form articles).
- People want to learn daily but lose the habit without structure and motivation.

### 1.3 Solution & Differentiators
| # | Differentiator | Description |
|---|---|---|
| 1 | **Perfect mixed Arabic/English text** | Per-block direction, isolated inline English terms, code always LTR. |
| 2 | **Daily reading habit** | "مقال النهارده" (Today's article) at the user's chosen time, streaks, learning paths. |
| 3 | **Trust by design** | Verified writers, sources, tested code in seeded articles, version badges and community moderation. There is no review ([ADR 0015](adr/0015-open-publishing-and-the-editor.md)). |
| 4 | **Two versions per article** | Egyptian Arabic + English terms (`ar-EG`) and English-only (`en`). |
| 5 | **Rich editorial formatting** | Callouts, code tabs, comparison tables, steps, glossary terms, not just plain text. |

### 1.4 Fields (Domains)
**ReadIn is open to any topic.** It is not limited to software or health: any signed-in member can publish an article about anything, in any enabled field, without approval. Every field is enabled from launch:

- **Software:** AI, Machine Learning, Deep Learning & LLMs, Claude & AI coding tools, .NET, Frontend, Mobile, Databases, DevOps & Cloud, Software Architecture, Security, Testing.
- **Health & engineering:** Medicine, Public Health, Engineering.
- **Everything else:** Science, Business & Finance, Education, Self-growth, History & Culture, Arts & Literature, Law, Sports, Lifestyle.
- **General (موضوعات عامة):** the catch-all, so no article is left without a field.

Rules that apply to every field:
- **There is no review**: anyone publishes directly ([F06](#f06--article-lifecycle), [ADR 0015](adr/0015-open-publishing-and-the-editor.md)).
- Admins can add fields and topics at any time ([F23](#f23--admin-console)); free tags (max 5, [F32](#f32--tags-التاجات)) cover anything more specific, and writers can organize their own articles into personal categories ([F31](#f31--writer-categories-أقسام-الكاتب)).
- Open publishing still follows the community guidelines: illegal or harmful content can be reported and removed ([F22](#f22--reporting--moderation)).
- The 300 seeded articles are software only ([§19](#19-content-pipeline-300-seed-articles)). That is launch content, not a limit on what people can publish.

### 1.5 Target Users
Arabic and English readers and writers (18–35 first) who want to learn something new every day, in any field, plus anyone who wants to share knowledge and build a reputation.

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
| Auth | **Own JWT auth**: phone number + password, or Google/Apple ID tokens verified by the API ([ADR 0012](adr/0012-google-and-apple-sign-in.md)). Access token (JWT, 15 min) + rotating refresh token. Passwords hashed with `PasswordHasher<T>` (`Microsoft.Extensions.Identity.Core`, no Identity tables). See [§9](#9-authentication-phone-google-apple). |
| Phone numbers | `libphonenumber-csharp` (validation + E.164 normalization) |
| Push notifications | **Firebase Cloud Messaging (FCM)** via `FirebaseAdmin` SDK |
| Real-time | **Firebase Realtime Database** (live counters, comment events, unread badges), written by the backend only via `FirebaseAdmin` SDK. **No SignalR.** |
| File storage | **`wwwroot/uploads`** on the API server (Development and Production), behind `IFileStorage` |
| Image processing | **SkiaSharp** (resize, WebP, strip EXIF), **BlurHash** placeholders |
| PDF processing | **PDFtoImage** (PDFium, page rendering) + **PdfPig** (metadata, text extraction) |
| PDF export ([F33](#f33--download-article-pdf-تحميل-المقال-pdf)) | **PuppeteerSharp** + headless Chromium, with the fonts bundled in the API |
| Background jobs | **Hangfire** (SQL Server storage): daily article push, streak reset, link checks, article quality score |
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
| Navigation | `go_router` (App Links / Universal Links: the web's `{domain}/{ar|en}/a/{slug}`, F24) |
| Networking | `dio` + `retrofit` + interceptors |
| Models | `freezed` + `json_serializable` |
| Local storage | `hive_ce` (cache, offline saved articles), `flutter_secure_storage` (tokens) |
| i18n | `flutter_localizations` + `intl` (ARB files `ar`, `en`) |
| Editor | `appflowy_editor` with RDoc converters |
| Code highlighting | `re_highlight` (light + dark themes) |
| Firebase | `firebase_messaging` (+ `flutter_local_notifications`), `firebase_database`, and `firebase_auth` **only** for `signInWithCustomToken` to read the Realtime Database (never for user sign-in). No Firebase Storage, Crashlytics or Analytics. |
| Phone input | `phone_numbers_parser` + bundled-asset flags |
| Images | `flutter_image_compress` (before upload), `cached_network_image`, `flutter_blurhash` |
| Testing | `flutter_test`, `bloc_test`, `mocktail`, golden tests in `ar/light` and `en/dark` (both directions, both themes), `integration_test` |

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
            ├── meta.json       # status, version badge, sources
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
            .Map(d => d.AuthorName, s => s.Author.DisplayName);
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
| `Article` | `CreateDraft`, `AddTranslation`, `ReplaceTranslations`, `SetAttachments`, `SaveDraft`, `DiscardDraft`, `RestoreDraft`, `Publish`, `Archive` |
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
- Every screen is built and tested in **4 variants**: `ar/light`, `ar/dark`, `en/light`, `en/dark`. Golden baselines are kept for `ar/light` and `en/dark` only (both directions and both themes). The tests still build every screen in `ar/dark` and `en/light`, so an exception or an overflow there fails them.
- Offline: saved articles and today's article are cached for offline reading.
- Deep links and push notification taps open the exact article/comment.

---

## 9. Authentication: Phone, Google, Apple

### 9.1 Decisions
| Topic | Decision |
|---|---|
| Sign up / sign in | **Phone number + password, Google, or Apple**, all on **one account** with the same sessions. No SMS, no OTP, no email + password login. |
| Google / Apple | The app gets an ID token from the provider SDK and sends it to `POST /auth/external`; the backend verifies it against Google's / Apple's published keys and our client ids, then starts a normal ReadIn session ([ADR 0012](adr/0012-google-and-apple-sign-in.md)). Google on web, Android and iOS; Apple on iOS and web (Android later: it needs a server callback). Apple must be offered on iOS whenever Google is (App Store guideline 4.8). Buttons show only for providers listed in `GET /auth/config` → `externalProviders`. |
| Linking | A Google/Apple identity is linked automatically when the provider reports a **verified** email that matches an account. Otherwise the person chooses "create a new account" or "I already have an account" (phone + password links it). Settings links and unlinks providers; Google/Apple-only accounts can add phone + password later. |
| Who handles auth | The **.NET backend** (own JWT). Firebase Auth is **not** used for sign-in. |
| Forgot password | **Recovery PIN** (4 digits, set at sign up): phone + PIN → new password. Google/Apple-only accounts recover through their provider and have no PIN. |
| Last fallback | "نسيت الـ PIN كمان؟" → contact support → the SuperAdmin resets the password. |
| Guests | Can browse and read without an account. |

**Known trade-off:** without SMS, the app cannot prove that a user owns the phone number. This is mitigated by the "confirm your number" step at sign up, the recovery PIN and owner notifications.

### 9.2 Screens & Flows (web + mobile, identical)
Every screen supports ar/en × light/dark, has loading and error states, and prevents double submits. Shared components: phone field + country picker ([§9.4](#94-shared-input-components)), password field, PIN input.

```text
Welcome ─► Sign in ─────────────────────────────────────────────────────► Home
        ─► Create account (3 steps) ─► Complete profile ─► Onboarding ─► Home
        ─► Continue with Google / Apple ─► linked or verified-email match ─► Home
                                        ─► not linked ─► Create new account ─► Complete profile ─► Onboarding ─► Home
                                                      ─► I already have an account (phone + password) ─► linked ─► Home
Sign in ─► Forgot password ─► (phone + PIN) ─► New password ─► Sign in
```

**Welcome:** logo + tagline, "اعمل حساب جديد" (Create account), "عندي حساب، سجل دخول" (Sign in), "كمّل بجوجل" / "كمّل بأبل" (Continue with Google / Apple), "تصفح كزائر" (Browse as guest), UI language switcher.

**Sign in:**
- Phone field, password field, "نسيت كلمة السر؟" link, "سجل دخول" button, "معندكش حساب؟ اعمل حساب" link, then "أو" and the Google / Apple buttons.
- Wrong credentials → one generic error: "رقم التليفون أو كلمة السر غلط" (never reveals whether the number exists).
- 5 wrong attempts → "محاولات كتير. جرّب تاني بعد 15 دقيقة". Suspended → "الحساب ده موقوف. تواصل مع الدعم".
- After success, guards apply in order: `MustChangePassword` → change password, `MustSetRecoveryPin` → set PIN, profile incomplete → Complete profile, onboarding not done → Onboarding, otherwise → Home.

**Create account (stepper "خطوة 1 من 3"):**
1. **Phone & password:** phone field, password + strength meter, confirm password, live rules checklist (8+ characters, a letter, a digit). Number already registered → "الرقم ده عليه حساب بالفعل" + Sign in action.
2. **Recovery PIN:** "اعمل PIN للطوارئ", explanation that it is needed if the password is forgotten, PIN input + confirm PIN. Errors for mismatch and weak PINs.
3. **Confirm your number** (dialog): the number in large LTR text with the warning "هتستخدم الرقم ده في تسجيل الدخول، ومش هتقدر تسترجع حسابك لو الرقم غلط." Buttons: "صح، اعمل الحساب" / "تعديل".

Then **Complete profile** (display name, unique `@username` with live availability check, optional avatar, optional title) → **Onboarding** ([F02](#f02--onboarding-3-steps)).

**Forgot password:**
1. Phone field (pre-filled from Sign in) + PIN input → "كمّل". Generic error "رقم التليفون أو الـ PIN غلط". Link "نسيت الـ PIN كمان؟" opens the contact-support sheet.
2. New password + strength meter + confirm → "احفظ". Success → Sign in with the number pre-filled and the banner "تم تغيير كلمة السر. سجل دخول بكلمة السر الجديدة". Expired reset token → "انتهت المهلة، ابدأ من الأول".

**Continue with Google / Apple:**
- Cancelling the provider dialog does nothing. A linked identity, or a verified email that matches an account, signs in and the same guards apply (Google/Apple-only accounts never need a PIN).
- Not linked (`auth.external_not_linked`) → sheet "مفيش حساب ReadIn مربوط بالحساب ده لسه" with "اعمل حساب جديد" (creates it → Complete profile → Onboarding) and "عندي حساب برقم تليفون" (phone + password; links it and signs in). A phone account that already has another Google (or Apple) account → "في حساب تاني من نفس النوع مربوط بالفعل".
- Apple gives the name only on the first authorization; the app sends it as the display name of a new account.

**Set recovery PIN (mandatory):** shown when `mustSetRecoveryPin = true` (accounts created before the PIN existed, admin-reset accounts, the production SuperAdmin). Cannot be skipped.

**Settings → Account:** see [F18](#f18--settings).

### 9.3 Tokens & Sessions
| Token | Details |
|---|---|
| Access token | JWT, **15 minutes**. Claims: `sub`, `security_stamp`. Signed with `Jwt:SigningKey`. Issuer, audience, lifetime and key are validated. |
| Refresh token | Random 256-bit, **30 days**, **rotating**, stored **hashed** in `RefreshTokens`. Reusing an already-rotated token revokes the whole token family (theft detection). |
| Reset token | Random 256-bit, **10 minutes**, single use, bound to the user and the creating IP, stored hashed. Issued after a correct recovery PIN. |

- An `IClaimsTransformation` loads roles & permissions from SQL Server (cached, invalidated on role change). Tokens whose `security_stamp` no longer matches are rejected.
- `SecurityStamp` changes on password change, password reset, phone change, adding phone sign in to a Google/Apple account and "sign out of all devices", which signs out every other session.
- Google/Apple sign in starts the same session (access + refresh token). Provider tokens are verified once and never stored.
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
| Recovery lockout | 5 wrong PINs → recovery locked 1 hour. 3 lockouts within 7 days → recovery disabled until an admin reset (the SuperAdmin). Rate limits: 10/hour per IP, 5/hour per phone. |
| Anti-enumeration | Generic errors for login and recovery; a dummy hash runs for unknown numbers so timing stays the same. |
| After reset / password change / phone change / sign out all | New `SecurityStamp`, all refresh tokens revoked, counters reset, audit log entry. |
| Google / Apple tokens | Verified with the provider's OpenID Connect keys: RS256 signature, issuer, audience (`ExternalAuth:{Google,Apple}:ClientIds`), expiry. Apple tokens must carry the SHA-256 of the raw nonce the app sends (so a leaked token can't be replayed). Only the provider's `sub` and the email it reported are kept, in `UserExternalLogins`, plus, for Apple, the refresh token from exchanging the sign-in `authorizationCode` (AES-GCM encrypted) so it can be revoked when the account is deleted (§9.6). |
| Linking | Automatic only for a provider-**verified** email matching `Users.Email`, which is itself only ever set from a provider-verified address (or seeding), never from user input. Linking from Settings needs the password or an already linked provider, so a stolen access token can't add a way in. One identity per provider per account; the last way to sign in can't be removed. |
| Owner notifications (push + in-app) | Recovery lockout, password changed, PIN changed, phone number changed, Google/Apple linked or unlinked, phone sign in added. These ignore quiet hours. |
| Admin reset | Permission `users.reset_password` (the SuperAdmin): temporary password + `MustChangePassword`, PIN cleared + `MustSetRecoveryPin`, `RecoveryDisabled = false`, sessions revoked, audit log. An account that holds a permission the caller doesn't can't be reset by them, so only a SuperAdmin resets a SuperAdmin ([ADR 0018](adr/0018-two-roles-and-a-verified-badge.md)). |
| PII | Phone numbers never appear in public DTOs (profiles, comments, articles); only in `GET /me` and admin endpoints with `users.read.pii`. Masked in logs (`+20******4567`). Passwords, PINs, hashes and tokens are never logged. |

> Roles and credentials are stored in **SQL Server** (source of truth).

### 9.6 Account Deletion & Data Map

Delete account ([F01](#f01--authentication--account)) is **immediate and for good** ([ADR 0016](adr/0016-immediate-account-deletion.md)): no grace period, nothing to restore.

**Flow (web + mobile, identical):** Settings → Account → **Delete account** (red; also the last row of Settings) → a screen stating what is deleted, what is kept and for how long, and that it can't be undone → confirm it's you (the password, or a fresh Google/Apple sign in; an Apple-linked account confirms with Apple when the server has no token to revoke) → tick "I understand, delete my account" → final dialog → `DELETE /me` with progress. Errors keep the account and offer Retry; offline is an error, never queued. On success the app deletes its local data and its push token, signs out and shows "Your account was deleted" on the sign-in screen. Deletion by email stays available ([/delete-account](../public/delete-account.html)).

**Server:** confirm (password or fresh provider token) → revoke every Apple token of the account (the stored one and the one from a fresh code; retried; Apple unreachable or the key not configured → `503 account.deletion_unavailable` and nothing is deleted; no token → `400 auth.apple_confirmation_required`) → one transaction (`AccountEraser`) → delete uploaded files, private verification proofs (F19) and the Realtime Database node, drop the cached details of the articles that stay and recompute the counters of the articles the account reacted to or saved → drop the cached access. A retry with a token that outlived the account gets `204`; any other request with it gets `401`. The phone number, email and Google/Apple identities can sign up again at once, as a new, empty account.

**Data map.** Keep it in sync with `AccountEraser`, the deletion screens, `public/delete-account.html` and `public/privacy.html`. Any new table keyed by a user must appear here.

| Data | Where | On deletion | Why / how long |
|---|---|---|---|
| Phone number, email, password hash, recovery PIN hash, name, @username, photo, title (headline), bio, social links, preferences and privacy settings, quiet hours, lockout counters, security stamp | `Users` | **Deleted** | |
| Roles, interests, fields of expertise | `UserRoles`, `UserInterests`, `UserExpertiseFields` | **Deleted** (cascade) | |
| Devices and FCM push tokens | `UserDevices` | **Deleted** (cascade); the apps also delete the token on the device | No notification reaches a deleted account |
| Google/Apple links and the encrypted Apple refresh token | `UserExternalLogins` | Apple tokens **revoked at Apple** first, then **deleted** | The same Google/Apple account can sign up again |
| Sessions, password reset tokens | `RefreshTokens`, `PasswordResetTokens` | **Deleted** (cascade) | Every session ends |
| Recovery attempts (phone hash, IP) | `RecoveryAttempts` | **Deleted** | |
| Reading progress, reading days, streak and stats, daily picks | `ReadingProgress`, `ReadingDays`, `UserStats`, `DailyPicks` | **Deleted** (cascade) | |
| Own drafts and every own article that isn't published (archived, deleted), with translations, revisions, tags, sources, attachments, and other people's reactions, saves and comments on them; the private working copy of published ones (F05) | `Articles` and children, `ArticleDrafts` | **Deleted** | Unpublished work goes with the account |
| Own **published** articles, with translations, revisions, tags, sources, attachments, and other people's reactions, saves and comments on them | `Articles` and children | **Anonymized**: `AuthorId`, `CreatedBy` and `UpdatedBy` set to null; readers see "Deleted user" (no name, @username, photo or profile link; `author` is `null` in the API) | Links, learning paths and discussions other readers rely on keep working. A writer who wants an article gone deletes it first |
| Images and PDFs a kept article shows (attachments, cover, images in its content or revisions) | `MediaAssets`, `MediaAssetPages`, files under `/uploads` | **Anonymized**: `OwnerId`, `CreatedBy` and `UpdatedBy` set to null; files kept | They're part of the article that stays |
| Every other upload: avatar, images and PDFs of deleted articles, unused uploads, with their page previews | `MediaAssets`, `MediaAssetPages`, files under `/uploads` | **Deleted**; files right after the commit (a failed file delete is finished by the daily orphaned-uploads job) | |
| Live signals | Firebase RTDB `/live/users/{id}` | **Deleted** (best effort; they expire after 24 hours anyway) | |
| The account's reactions, saved articles, collections, reposts (F29), follows in both directions | `Reactions`, `SavedArticles`, `Collections`, `CollectionItems`, `Reposts`, `UserFollows` | **Deleted** (cascade from `Users`; follows *of* the account deleted explicitly); the counters of the articles it reacted to, saved or reposted are recomputed right after. Reposts of its deleted articles go with those articles | |
| The account's comments (F11) | `Comments` | **Anonymized**: `AuthorId` set to null by the foreign key, `CreatedBy` and `UpdatedBy` cleared; shown as "Deleted user". Its comments that were already deleted (by it or a moderator) keep only the placeholder: their text is erased | Replies and discussions keep their context |
| The account's comment likes, mentions of it | `CommentLikes`, `CommentMentions` | **Deleted** (cascade); the like counts of the comments it liked are recomputed in the same transaction | |
| The account's notifications (with their actors) and notification settings (F17) | `Notifications`, `NotificationActors`, `UserNotificationSettings` | **Deleted** (cascade) | |
| The account as the actor of other people's notifications ("X commented on your article") | `NotificationActors.ActorId` | **Deleted** explicitly (no cascade: a second path from `Users`); the entry stays and shows "Deleted user", or drops out of the list when nothing is left of it (a follow) | |
| Other people's notifications about the account's deleted articles or the comments on them | `Notifications.ArticleId` / `CommentId` | **Deleted** explicitly before the articles (no cascade) | Their target is gone |
| Reports it filed; reports about the account, its deleted articles and the comments on them | `Reports` | **Deleted** | Their target is gone |
| Comments and articles it hid, reports it resolved, and moderation log entries it made or that name it | `Comments.HiddenById`, `Articles.HiddenById`, `Reports.ResolvedById`, `ModerationActions.ModeratorId` / `TargetUserId` | **Anonymized**: the link to the account is removed | The moderation decision stays |
| Security log entries about the account (sign ins, password, PIN and phone changes…) | `AuditLogs` | **Deleted** | They hold IP addresses |
| Revisions made on other writers' articles | `ArticleRevisions.CreatedBy` | **Anonymized**: the link to the account is removed; the article keeps its history | Other people's content stays intact |
| Moderation actions the account took on other accounts | `AuditLogs` (actor) | **Anonymized**: kept without the IP address | Accountability for actions on other people's accounts |
| `CreatedBy` / `UpdatedBy` on rows that stay (articles, comments, media, learning paths, fields, other accounts) | audit columns | **Anonymized**: set to null | Nothing links a kept row back to the account |
| Deletion record: account id and time | `AuditLogs` (`account.deleted`) | **Retained**, no IP or other personal data | Proves the deletion happened and answers retried requests; kept with the security log |
| Writer verification requests (field, job title, proof URL, note, decision) and their proof files (F19) | `VerificationRequests`, files in the private store (`Storage:PrivatePath`) | **Deleted** (cascade from `Users`); proof files right after the commit (a failed delete is finished by the daily proofs cleanup job). A decided request has no file any more | Proof is only needed while a request is pending |
| Verification requests the account decided as an admin | `VerificationRequests.DecidedById` | **Anonymized**: the link to the account is removed (no FK; nulled explicitly) | The decision and its reason stay with the user it concerns |
| Tags the account created (F32) | `Tags.CreatedById` | **Anonymized**: the link to the account is removed (no FK; nulled explicitly) | Tags are shared by everyone; a tag no article carries is still deleted by the daily cleanup |
| Writer categories (F31) | `WriterCategories`, `Articles.WriterCategoryId` | **Deleted** (cascade); the published articles that stay lose their category (`ON DELETE SET NULL`) | They only group the writer's own articles |
| Highlights (F30): the account's own highlights | `ArticleHighlights` | **Deleted** (cascade from `Users`); the cached popular ranges of the articles it highlighted are dropped right after, so its marks stop counting at once. Highlights on its deleted articles go with those articles; other people's highlights on its kept articles stay | They were private; popular ranges never said who marked them |
| Mutes and "show less" marks (F28): the writers, fields and topics the account muted, other people's mutes of the account, its "show less" marks | `UserMutes`, `ContentMutes`, `ArticleFeedback` | **Deleted** (cascade from `Users`; mutes *of* the account deleted explicitly) | Private choices; nobody was ever told about them |
| Database, uploads and private files backups | backup storage | **Retained up to 14 days**, then overwritten | Disaster recovery ([deployment](setup/deployment.md)) |
| Server logs | Serilog sink | May hold the account id and masked phone numbers (§9.5) for the log store's retention | Operations |

---

## 10. Roles & Permissions

### 10.1 Roles
| Role | Description |
|---|---|
| **Guest** | Not signed in. Can browse and read published articles. |
| **Member** | Default for every signed-up user. Reads, interacts, and can write articles. A user stays a Member with or without the Verified badge. |
| **SuperAdmin** | The app's owner. Full access: reports and moderation, suspending users, fields, topics, tags, paths, featured content, verification requests and system settings. |

An account is a `Member` or the `SuperAdmin`, and `Guest` only means not signed in. There is no Reviewer role ([ADR 0015](adr/0015-open-publishing-and-the-editor.md)).

**Only two account roles.** Every account that signs up is a `Member`, and the `SuperAdmin` is the app's owner, created from `Seed:SuperAdminPhone`. There are no Admin or Moderator roles: the SuperAdmin does that work, so wherever this SPEC says admin or moderator, it means the SuperAdmin. Endpoints still check permissions rather than roles, so a staff role can be added later without changing them.

**Verified is a badge, not a role.** A Member can request verification (F19). When the SuperAdmin approves it, `Users.IsVerified` is set and the badge appears next to the name everywhere. Roles and permissions don't change, so the user stays a `Member`. The badge also gives priority in feeds, and it isn't required to publish in any field.

### 10.2 Permission-based Authorization
Endpoints require **permissions**, not roles. Roles are bundles of permissions.

| Permission | Guest | Member | Super Admin |
|---|:-:|:-:|:-:|
| `articles.read` | ✅ | ✅ | ✅ |
| `articles.create` | | ✅ | ✅ |
| `articles.export_pdf` ([F33](#f33--download-article-pdf-تحميل-المقال-pdf)) | | ✅ | ✅ |
| `articles.feature` | | | ✅ |
| `comments.create` / `reactions.create` / `reposts.create` / `highlights.create` | | ✅ | ✅ |
| `follows.manage` / `saved.manage` | | ✅ | ✅ |
| `reports.create` | | ✅ | ✅ |
| `moderation.manage` (hide content, resolve reports) | | | ✅ |
| `users.suspend` | | | ✅ |
| `users.reset_password` (admin password reset) | | | ✅ |
| `users.read.pii` (see phone numbers) | | | ✅ |
| `verification.manage` | | | ✅ |
| `taxonomy.manage` (fields, topics, tags) | | | ✅ |
| `paths.manage` | | | ✅ |
| `system.settings` | | | ✅ |


**Ownership rules:** a user can always edit/delete their own articles, comments and reactions. Editing a published article happens in a private working copy; readers see the change after **Update**, which records a revision (F05).

---

## 11. Features

> Every feature below ships on **Web + Mobile** (see [§12](#12-feature-parity-matrix-web--mobile)), supports **ar/en** and **light/dark**.

### F01 — Authentication & Account
- Sign up / sign in with **phone number + password** (country picker, E.164), **Google** or **Apple**, all on one account. Full screens and rules in [§9](#9-authentication-phone-google-apple).
- Sign up is a 3-step stepper: phone + password → recovery PIN → confirm your number.
- **Forgot password** with phone + recovery PIN → new password. "Forgot the PIN too" → contact support → admin reset by the SuperAdmin.
- Mandatory "set recovery PIN" screen for accounts without a PIN.
- Complete profile after sign up: display name, unique `@username`, optional avatar, optional title.
- Guest browsing with a soft prompt to sign in when trying to interact.
- Sign out, sign out of all devices, delete account (the password, or Google/Apple for accounts without one): **immediate and for good**, Apple tokens revoked first, see [§9.6](#96-account-deletion--data-map).

### F02 — Onboarding (3 steps)
1. Welcome + value proposition.
2. **Choose interests** (fields/topics chips, minimum 3).
3. **Preferences:** article language (`مصري + English` / `English only`), daily reminder time (default 8:00 AM, user's time zone), notifications permission (asked here, in context, never on first launch).

### F03 — Home: "النهارده" (Today)
- Greeting + **streak badge** 🔥 + notifications bell.
- **Today's article:** one published article picked for the user (see [§11 F07](#f07--daily-article-مقال-النهارده)), shown first as a post card labeled "مقال النهارده" ([F34](#f34--post-style-feed-card-كارت-البوست)).
- **Continue reading:** the most recently read unfinished article (scrolled ≥ 5%, read in the last 30 days, not today's hero), with its progress; tapping it resumes where you stopped.
- **Learning path card:** your active path (enrolled, with an unread article, latest activity first) with its progress and the next article; without one, a short prompt to browse paths ([F09](#f09--learning-paths-مسارات)).
- Field filter chips + feed: **For you** (interests + popularity + freshness) and **Following** tabs.
- Feed items are **post cards** ([F34](#f34--post-style-feed-card-كارت-البوست)): the beginning of the article with "اقرأ المزيد", and reacting and commenting without leaving the feed.
- Feed cards show attachments: a single image, an **image carousel** or a **PDF page carousel** ([F26](#f26--post-attachments--media)).
- Live counters on visible cards and a "مقالات جديدة ↑" banner when new articles are published ([F27](#f27--real-time-updates)).
- Infinite scroll with cursor pagination, skeleton loading, pull to refresh.

### F04 — Article Reader
- Reading progress bar, estimated reading time, table of contents for long articles.
- **Language toggle** per article: `مصري+EN` / `EN` (shown only when both versions exist).
- Trust row: the writer's title (F14), verified writer badge, version badge (e.g. `.NET 10`), "AI-assisted" label when applicable.
- Rich RDoc rendering: headings, callouts (tip/warning/info/danger), code blocks with copy button and filename, code tabs (C# / TypeScript / Dart), tables, steps, quotes, images with captions, glossary terms (tap → definition sheet).
- **TL;DR summary** at the top (optional per article).
- **Sources** section at the bottom (required by the field's `RequiresSources` setting, see F05).
- **Health disclaimer** on Medicine and Public Health articles: "المعلومات دي للتوعية ولا تغني عن استشارة الطبيب" (for awareness only, not a substitute for a doctor).
- Font size control (S / M / L / XL), reading mode toggle.
- Attachments (image carousel or PDF page carousel) with a full-screen viewer ([F26](#f26--post-attachments--media)).
- Floating action bar: reactions, comments, repost ([F29](#f29--repost)), save, share, and a "⋯" menu ([F28](#f28--article-menu-mute--show-less)). Reaction and comment counts update live ([F27](#f27--real-time-updates)).
- Remembers the last scroll position: on open, the reader goes back to where you left off (unless you finished the article or the link points at a block) and offers "Start over". Marks the article as "read" when ≥ 70% scrolled **and** ≥ 30 seconds spent.
- Related articles + "Next in path" at the end. Related ranks the same topic first, then the same field, then shared tags and glossary terms; it skips your own articles, puts the ones you've read last, and leaves the article's path neighbours to "Next in path". Related articles are post cards ([F34](#f34--post-style-feed-card-كارت-البوست)).
- Report article (from the "⋯" menu).
- Download PDF for signed-in members (from the "⋯" menu, [F33](#f33--download-article-pdf-تحميل-المقال-pdf)).
- Highlights: mark sentences, see popular ones, hide them ([F30](#f30--highlights)).

### F05 — Article Editor (Write)
- Block-based rich editor producing **RDoc**: all block types in [§13](#13-article-content-format-rdoc), slash menu (`/`) to insert blocks, markdown shortcuts, `@` mentions (suggestions offer only people who allow the author, [F18](#f18--settings) "who can mention me"; every publish and Update checks each mention again in every language version: allowed ones link with the user's current `@username` (at most 20 people per article), the rest become plain text, and newly mentioned users get a [F17](#f17--notifications) notification), and a glossary button that marks the selected words as a term ([F21](#f21--glossary-قاموس-المصطلحات): search the glossary, pick; select a term to change or remove it).
- Per-block automatic direction (`dir="auto"`) with manual override, code blocks forced LTR.
- Cover image upload (compressed on the device, processed by the backend, stored in `wwwroot/uploads`), field, topic, an optional personal category ([F31](#f31--writer-categories-أقسام-الكاتب)), and tags: pick existing ones or create new ones, max 5 ([F32](#f32--tags-التاجات)).
- **Attachments:** 1–10 images **or** one PDF ([F26](#f26--post-attachments--media)). The attachment bar is one reusable component (web) / widget (mobile); attachments are part of the draft and go live with it.
- **Sources** list (title + URL). Required in fields with `RequiresSources` on (software, Medicine, Public Health, Engineering), optional in the others.
- Second language version: add `en` or `ar-EG` translation of the same article.
- Autosave drafts every 10 seconds + local backup (offline-safe). The whole draft is saved as one document with a version, so a second device gets a conflict instead of overwriting the first.
- Editing a published article works on a private **working copy**: readers keep the published version until the writer presses **Update**; **Discard changes** drops the working copy.
- Preview exactly as readers will see it (light/dark, ar/en).
- **Publish now.** There is no scheduling and no review: anyone publishes in any field ([ADR 0015](adr/0015-open-publishing-and-the-editor.md)). The reader URL (slug) is fixed at the first publish.
- Revision history: one revision per publish, with preview and restore into the working copy.
- Live checks: missing field, title length (5–150), empty content, missing sources, missing alt text (image blocks and attachments), attachments still processing, reading time. Saving never fails because the article is unfinished; publishing is blocked while any check fails.
- **My articles** (opened from Write): Drafts and Published tabs, each article with Edit and Delete, plus New article. Published articles also have Download PDF ([F33](#f33--download-article-pdf-تحميل-المقال-pdf)).

### F06 — Article Lifecycle
```text
Draft ──► Published ──► Archived
            ▲   │
            └───┘  edits go to a private working copy until "Update"
```
- **Anyone publishes directly, in any field, including Medicine and Public Health.** There is no review and no scheduling ([ADR 0015](adr/0015-open-publishing-and-the-editor.md)).
- The only publish checks are content ones: the article has content, and has sources if its field requires them.
- Medicine / Public Health articles show a disclaimer (§20).
- Any published article can become **Today's article** ([F07](#f07--daily-article-مقال-النهارده)).

### F07 — Daily Article (مقال النهارده)
- Picked per user daily by a Hangfire job at the user's local time minus 30 minutes.
- **Algorithm:** any published article (written by anyone, never the reader's own), in user's interests, not read before, matches language preference, reading time 4–10 minutes, ranked by the quality score (engagement, read completion, freshness; formula in [ADR 0015](adr/0015-open-publishing-and-the-editor.md)), not from the same field 3 days in a row, prefers the next item in the user's active learning path.
- **Fallback:** constraints relax in order when nothing matches (length, then interests).
- Push notification at the chosen time: *"مقال النهارده جاهز ☕ — {title}"*.
- If the user doesn't open it, it stays as the hero card for the day.
- **Job details:** runs every 5 minutes, for users with at least one push device (others get the pick on demand from `GET /feed/today`; both store the same one pick per local date). Times are wall-clock in the user's time zone, so DST never moves a reminder. The push is sent once per day (`DailyPicks.NotifiedAt`), skipped when the user already read the article, and at most 2 hours late after a missed run; "read" is `ReadingProgress.CompletedAt` (F04), and "3 days in a row" means the picks of the two previous days. Payload: [`contract-v1.md`](api/contract-v1.md#push-payloads-fcm).

### F08 — Streaks & Reading Stats
- Streak +1 per day the user completes at least one article (local date in the profile time zone, see [ADR 0013](adr/0013-reading-days-and-streaks.md)).
- **Streak freeze:** 1 free freeze per rolling 7 days, auto-used on a single missed day (two missed days in a row end the streak).
- Stats: current streak, longest streak, articles read this week/month (last 7 / 30 days), minutes read, top fields, **reading heatmap** (GitHub-style, last 12 months).
- Milestone celebrations (7, 30, 100, 365 days) with a shareable card.

### F09 — Learning Paths (مسارات)
- Curated ordered series (e.g. "أساسيات ASP.NET Core — 10 مقالات").
- Enroll, progress bar, "next article", completion badge.
- Paths are created by Admins (and later by Verified Writers).
- **Pages:** paths list (All / My paths, field chips) and a path page (articles in order with read ticks; start / continue / leave). The reader ends with a "Next in path" block, and the profile has a Paths tab, private unless reading stats are public (F14, F18).
- **Progress** is the F04 "read" rule, so articles read before enrolling count. Only articles a reader can open are counted. Enrolling when everything is read completes the path at once. The badge stays when a path grows later.
- **Active path:** the enrolled path with an unread article and the latest activity (enrolling or reading one of its articles). It feeds the Home card (F03) and today's article (F07).
- **Editorial paths** come from `content/taxonomy.yaml` and are read-only for admins. Admin-made paths are managed with the `paths.manage` API (screens with F23).

### F10 — Reactions
- Four reactions: 💡 مفيد (Insightful), ❤️ (Love), 🔥 (Fire), 🤯 (Mind-blown).
- One reaction per user per article (change or remove anytime).
- Counts per reaction, list of who reacted.
- **Reaction picker, like LinkedIn:** the four reactions in a floating bar with no numbers or labels (the counts stay in the who-reacted list). On hover on web or a long press on mobile, the bar and its reactions animate in one after the other, the one under the pointer grows and rises, and picking one plays a short animation. It respects "reduce motion" (§26).

### F11 — Comments & Replies
- Threaded comments: top-level + replies (max depth 2, shown as one indented level). Replying to a reply joins the same thread.
- **Replies in pages (like Facebook and LinkedIn):**
  - A thread first shows only its first reply.
  - "عرض المزيد من الردود" (show N more replies) shows up to 5 more at a time, and "إخفاء الردود" (Hide replies) folds the thread back to its first reply.
  - Your own new reply, and replies that arrive live, show at once at the end of the thread.
- Sort: **Top** / **Newest**.
- **Comment box:** your avatar, then a rounded field with "اكتب تعليق…" (Add a comment…) an emoji button that opens an emoji picker, and a send icon, disabled until there is text, with no text button like "نشر". Reply boxes look the same. The same box is used in the reader and on feed cards, on web and mobile.
- **Text and emoji only:** comments and replies have no images, GIFs or attachments, and there is no button or API field for them.
- **Each comment shows:** the avatar, name and verified badge, the writer's title (F14) on one line under the name (not their `@username`), the time, "متابعة" (Follow) when you don't follow them and it isn't you, and "⋯". Tapping the avatar or name opens the profile.
- **Compact layout:**
  - A small avatar: 32 px, or 24 px for replies.
  - A rounded bubble holding the name row, the title and the text.
  - Under the bubble, one short row of text actions: Like (with its count) and Reply.
- **Profile card on hover (web, devices with a mouse):** resting the pointer on an `@mention` (in comments and in articles), or on a commenter's name or avatar, opens a small card about that person:
  - the avatar, name, verified badge, `@username` and title;
  - "Follows you", when they do;
  - their follower and article counts;
  - a Follow button, or "View profile" on your own card.
  On touch screens a tap opens the profile as before.
- **Reply with a mention:** "رد" (Reply) opens the comment box with `@name` of the person you're replying to already in it, so they are mentioned and notified, and you can delete the mention. If they don't allow you to mention them (F18), the reply stays in the thread with no mention, and they still get the reply notification (F17).
- Like comments, reply, `@mention` users (only people who allow the author, [F18](#f18--settings) "who can mention me"; any other `@handle` stays plain text; each mentioned user is notified, [F17](#f17--notifications)), edit (shows "edited"), delete (soft: a comment with replies stays as a "deleted" placeholder).
- Writer badge "الكاتب" on the author's comments, author can **pin** one comment.
- Mixed Arabic/English input renders correctly (`dir="auto"` per comment).
- **Live:** new comments/replies appear without refreshing, edits/deletes update in place, and a "N تعليقات جديدة" pill appears when the user is scrolled away ([F27](#f27--real-time-updates)).
- Rate limit: 10 comments / minute per user, at most 20 per user on one article per hour, and not the same text twice within 10 minutes.
- Report comment (stored for the F22 queue). Moderators hide, unhide or delete any comment from its menu (audited); a hidden comment stays visible to its author and moderators.
- A deleted account's comments stay, shown as "Deleted user" (as the public account-deletion page promises).
- Comments can also be read and written from a feed card, without opening the article ([F34](#f34--post-style-feed-card-كارت-البوست)).

### F12 — Follow
- Follow writers and follow fields/topics.
- Followers / following lists with search.
- Following feed tab on Home.
- Suggested writers to follow (by field overlap).
- **Following panel (web, wide screens):** signed-in members get the people they follow in a panel docked at the bottom corner of the window, on the end side. It stays closed to its header bar until clicked, and each browser remembers whether it was left open. Open, it has a search box (name or @username), then the people you follow, newest first: each row opens their profile and shows "Follows you" when they do. When you follow fewer than 5 people, writers you might like follow, from `GET /users/suggested` (field overlap), each with Follow. No messages: it is a list, not a chat. Not shown on phones, in narrow windows or in the editor.

### F13 — Saved Articles (Bookmarks)
- Save / unsave from card or reader.
- Saved list with filter by field and search.
- **Collections:** optional named lists (e.g. "Interview prep").
- Saved articles available **offline** on mobile.

### F14 — Profile
- Avatar, display name, username (`@handle`), verified badge, title (below), bio (mixed text), social links (below), fields of expertise.
- Stats: articles, followers, following, total reads.
- Tabs: **Articles** (all published articles, newest first) / **Categories** ([F31](#f31--writer-categories-أقسام-الكاتب)) / **Reposts** / **Saved** (own profile only, with a Highlights section) / **Paths** / **About**.
- Reading stats card + heatmap (own profile, optional public).
- Edit profile, including avatar upload (compressed, square-cropped variants 64/128/256/512).
- The phone number is never shown on public profiles.

**Title (المسمى)**
- Any member can add a short title in Edit profile, and optionally in Complete profile, like "Senior Full Stack .NET Engineer | .NET | Angular".
- **Rules:** optional, up to 120 characters, one line, mixed Arabic and English (§14.2), with no direction-override characters.
- **Where it shows:** under the name on every post card (F34), in the reader's author row (F04), on comments and replies (F11) and on the profile. Everywhere except the profile it is cut to one line with "…", and the profile shows all of it. With no title, the line is hidden.
- It always shows the writer's current title, so changing it updates their older posts too. A title isn't checked by anyone: only the Verified badge (F19) means a review happened.
- **Abuse:** a title is reported by reporting the user (F22), and the SuperAdmin can clear it from the case, audited.
- **Data:** `Users.Headline` (`nvarchar(120)`), `headline` in `AuthorDto` (null when empty), the profile and `PATCH /me`. The official account's title is "مقال كل يوم يفرق معاك", and the demo writers get titles so it shows in development.

**Social links**
- Any member can add links to their accounts from Edit profile, in a "روابط" (Links) section with "+ إضافة رابط" (Add link): pick the platform, then paste the link. Links are optional.
- **Platforms, each with its own icon:** LinkedIn, X, Instagram, Facebook, YouTube, TikTok, Snapchat, Threads, Telegram, GitHub, Medium, Behance, Website, and **Other** for anything else, with a label of 2–30 characters. Brand icons come from one bundled set, used the same on web and mobile.
- **Rules:** at most 8 links in total and one per platform (Other can repeat). Each is at most 500 characters and `https` only (`instagram.com/name` becomes `https://instagram.com/name`), with no username or password in the URL. A named platform's link must be on that platform's site, so an Instagram link has to be on `instagram.com`. Website and Other accept any `https` site. A bad link shows an error under its field, in both languages.
- **On the profile:** a row of icons under the bio, for everyone including guests. Each has an accessible name ("Instagram", or the label for Other) and icons don't mirror in RTL. With no links, the row is hidden.
- **Opening a link:** in the system browser or the platform's app. On web, a new tab with `rel="nofollow ugc noopener noreferrer"`.
- **Abuse:** a link is reported by reporting the user (F22), and the SuperAdmin can clear that user's links from the case, audited.
- `links` in `GET /users/{username}`, `GET /me` and `PATCH /me` becomes an array of `{ platform, url, label? }`. Stored GitHub, LinkedIn and website links carry over.
- Links are deleted with the account (§9.6).

### F15 — Explore
API: [`docs/api/contract-v1.md`](api/contract-v1.md) ("Explore and field pages": endpoints, ranking windows and weights).
- Browse by field → topic.
- Trending this week, most saved, new writers, featured paths.
- Top writers per field.

### F16 — Search
API: [`docs/api/contract-v1.md`](api/contract-v1.md) ("Search"); engines in [ADR 0017](adr/0017-search-full-text-with-like-fallback.md).
- Search articles, writers, topics and tags in Arabic and English.
- Arabic normalization (see [§22](#22-search)), filters (field, language, reading time), recent searches.

### F17 — Notifications
**Built.** API: [`docs/api/contract-v1.md`](api/contract-v1.md) ("Notifications", "Push payloads"); details in [§21.1](#211-notifications).
- In-app notification center (SQL `Notifications` table, live unread badge via Firebase Realtime Database) + push (FCM).
- Types: new follower, reply to your comment, mention (comments and articles), reactions milestone (10/50/100), comment on your article, verification result (F19: approved or rejected), daily article, streak reminder (20:00, if not read yet), new article from a followed writer, repost of your article (`article_reposted`, F29), **security alerts** (password/PIN/phone changed, recovery lockout, Google/Apple linked or unlinked), moderation notices (F22).
- Per-type preferences (push / in-app / off), quiet hours. Details in [§21](#21-notifications--real-time).

### F18 — Settings
- Theme: **System / Light / Dark** (synced to profile across devices).
- UI language: العربية / English.
- Article language preference, daily reminder time, notification preferences, font size.
- Privacy: public reading stats on/off, who can mention me (**Everyone**, the default / **People I follow** / **Nobody**; you can always mention yourself, and deleted, suspended and system accounts are never linked). Checked by the mention suggestions, by comments when they are written or edited (existing comments keep their mentions), and by articles at every publish and Update.
- **Muted:** muted writers, fields and topics, with unmute ([F28](#f28--article-menu-mute--show-less)).
- Show or hide highlights ([F30](#f30--highlights)).
- **Account:**
  - Phone number (visible to the owner only) + "تغيير الرقم" (new number + current password + confirm-number dialog).
  - "تغيير كلمة السر" (current + new + confirm).
  - "تغيير الـ PIN" (current password + new PIN + confirm).
  - "الحسابات المربوطة" (Linked accounts): Google and Apple with the linked email, "اربط" (confirmed with the password, or with an already linked provider) and "فك الربط" (refused if it is the only way to sign in).
  - Google/Apple-only accounts see "ضيف رقم تليفون وكلمة سر" (phone + password + recovery PIN, confirmed with Google/Apple) instead of the number, password and PIN items above.
  - Sign out, sign out of all devices, and a red **Delete account** (also the last row of Settings): the flow and data map are in [§9.6](#96-account-deletion--data-map).

### F19 — Writer Verification
**Built.** API: [`docs/api/contract-v1.md`](api/contract-v1.md) ("Writer verification"). The user's page is `/verification` on the web and Settings → "Writer verification" (`/settings/verification`) on mobile; the admin queue is web only (`/admin/verification`).
- Request verification: field, job title, proof (LinkedIn/GitHub URL, certificate or syndicate card upload).
- The SuperAdmin reviews and approves or rejects with a reason. An approved user gets the Verified badge (`Users.IsVerified`) next to their name and stays a `Member`: no role or permission changes.
- **Request:** a field (enabled), a job title (2–100), proof (an `https://` URL ≤ 500, a file, or both) and an optional note (≤ 500). At most one pending request per user (a filtered unique index); verified writers and suspended users can't ask. The user can withdraw a pending request (it is deleted with its file), and ask again after a rejection. The page shows the latest request: pending with its date, approved, or rejected with the reason.
- **Proof files are private.** A PDF, JPEG, PNG or WebP of at most 10 MB, recognized by its magic bytes (never the name or the client's content type), stored as `verification/{requestId}{.ext}` in the **private store** (`Storage:PrivatePath`, default `App_Data/private`), never in `wwwroot` and never at a public URL. The API refuses to start when that folder overlaps the web root or the uploads folder. Only `GET /admin/verification-requests/{id}/proof` (`verification.manage`) reads a file: `Content-Disposition: attachment` under a neutral name, `Cache-Control: no-store`, `nosniff`. The uploaded name is only shown to admins, sanitized (no folders, control or direction-override characters, ≤ 120). Configuration and backups: [deployment](setup/deployment.md#8-private-files-verification-proofs).
- **Review queue** (`verification.manage`: SuperAdmin only; web only): Pending (oldest first), Approved and Rejected (newest decided first). **Approve** sets `IsVerified` and `VerifiedAt`, and the badge shows at once; **Reject** needs a reason (5–500) that only the user's verification page shows. A request is decided once (`409 verification.already_decided`). Both are in the audit log (`admin.verification_approved` / `_rejected`). The SuperAdmin can also remove a badge (F23, audited), and that user can request again.
- **Retention:** the proof file is deleted when the request is decided; the decision, the reviewer, the reason and the URL stay. Withdrawing deletes the request and its file; deleting the account deletes the user's requests and files and removes the account from the requests it decided (§9.6). A daily job deletes proof files that no request points at any more (a delete that failed).
- **Notification:** `verification_result` (F17) to the requester on each decision, `data.approved` true/false, no actor, link `readin://verification`; not configurable, quiet hours apply. Push: "بقيت كاتب موثّق ✓" / "You're now a verified writer ✓", or "طلب التوثيق بتاعك ماتقبلش" / "Your verification request wasn't approved" with "افتحه عشان تعرف السبب" / "Open it to see why". The reason is never in the push.

### F20 — Review Workflow (removed)
- Removed on 2026-11-03: there is no review, anyone publishes ([ADR 0015](adr/0015-open-publishing-and-the-editor.md)).

### F21 — Glossary (قاموس المصطلحات)
- Central glossary of technical terms (`Dependency Injection` → Arabic explanation + English definition + related articles).
- Writers mark a term in the editor, readers tap to see the definition: the term, the Arabic explanation (on `ar-EG` versions or an Arabic UI), the English definition and up to 5 other articles that use it.
- Seeded with 500+ software terms from `content/glossary/*.yaml` (one file per writing group; term ids are unique across files and are the RDoc `termId`). Which articles use which term (`ArticleTerms`) is rebuilt from the content on seeding and on publish.

### F22 — Reporting & Moderation
**Built.** API: [`docs/api/contract-v1.md`](api/contract-v1.md) ("Reports and moderation").
- Report article/comment/user with reason (spam, misinformation, harassment, copyright, other) and optional details (≤ 500). You can't report your own content or yourself; reporting the same thing twice is a no-op. A suspended user can be reported.
- **Moderation queue** (`moderation.manage`; web `/moderation`, mobile Settings → "الإشراف", nav badge with the open count): open / resolved / dismissed tabs, type filter, one item per target with its reason counts; open cases with the most reports first. A case shows the target, every report and its history.
- **Actions:** hide/unhide articles and comments, delete comments (moderators never delete articles), warn, suspend (1–365 days or permanent; `users.suspend`) and unsuspend users, dismiss reports. Hide, delete, warn and suspend resolve the target's reports (and optionally those of the content an author is warned for); dismiss closes them without touching the content. A note is required to warn or suspend. Nobody warns or suspends themselves or staff (holders of `moderation.manage`); staff content can be hidden.
- **Hidden article:** gone from every list, feed, count, today's pick, profile, saved list and collection; only its author and moderators open it, with a "Hidden by moderators" banner.
- **Suspension:** the account is blocked at once (`403 user.suspended` on every call and on sign in, with when it ends); a temporary suspension ends by itself.
- **Notices:** a warning or a hidden article is a notice (dialog with "فهمت") the user acknowledges, with a push.
- Full **moderation log** (`ModerationActions`) of every action that changed something; actions on a user's content or account are also in `AuditLogs`.

### F23 — Admin Console
- Dashboard: daily active readers, articles read, new users, top articles, streak retention.
- Manage fields, topics, tags, learning paths, featured content.
- Manage users and verification requests. There is no role management, because the only account roles are Member and SuperAdmin (§10).
- Content pipeline status (generated / auto-checked / published counts).
- Available on **web and mobile** (mobile uses a compact layout).

### F24 — Sharing
- Share article link (deep link opens app if installed, otherwise web). **Built.** Setup: [docs/setup/app-links.md](setup/app-links.md).
  - The link is the web's canonical URL of the version being read, `https://{domain}/{ar|en}/a/{slug}`, on the web
    (`siteUrl`) and on mobile (the reader's share button and the attachment viewer; `WEB_ORIGIN` in `config/prod.json`).
  - Android App Links (intent filter on `/ar/a/` and `/en/a/`, host from `WEB_ORIGIN`) and iOS Universal Links open it
    in the app, in that version (`/a/{slug}?lang=`). The web's SSR server serves `/.well-known/assetlinks.json` and
    `/.well-known/apple-app-site-association` from its environment (`ANDROID_CERT_SHA256`, `ANDROID_APP_ID`,
    `IOS_APP_IDS`). The domain, the signing fingerprints and the iOS Associated Domains entitlement are set by hand.
- Share a **quote card** (كارت الاقتباس): select text in the reader → **شارك اقتباس** / **Share quote** next to Highlight (F30), guests too → a picture of the quote for social media, light or dark, square (1080 × 1080) or landscape (1200 × 630), with the article title, the writer (verified badge, or "Deleted user"), the ReadIn logo (its dark version on dark cards) and the article link. **Built.**
  - The server draws it with the F33 Chromium (fonts embedded, JavaScript off, every request blocked) from the F30 selection range, checked against the article's current text like a highlight, so web and mobile get the same image and nobody can put invented words under an article. Nothing is stored ([ADR 0019](adr/0019-quote-cards-drawn-by-the-server.md)).
  - 3–400 characters after trimming; longer selections are refused, never cut. A long quote gets a smaller font down to a readable minimum and never overflows.
  - `POST /articles/{id}/quote-card` → PNG. Visible like the article (hidden: `409 quote.hidden` for its author and moderators, 404 for everyone else). Shares the PDF build slots (10 s wait, 20 s to draw); 30 cards per hour per user, guests per IP. Errors: `quote.text_mismatch`, `quote.block_not_allowed`, `quote.too_short`, `quote.too_long`, `quote.hidden`, `quote.limit`, `quote.busy`, `quote.failed`. API and texts: [`docs/api/contract-v1.md`](api/contract-v1.md) ("Quote card (F24)").

### F25 — Offline & Resilience (mobile + web PWA basics)
- Today's article and saved articles cached for offline reading.
- Queued actions (reactions, saves) replay when back online.

### F26 — Post Attachments & Media
A post/article has **either** 1–10 images **or** exactly one PDF (never both), like LinkedIn.

**Composer / editor**
- Attachment bar: "📷 صور" (Images) and "📄 ملف PDF" (PDF document).
- Images: multi-select up to 10, drag to reorder, remove, optional caption per image (`dir="auto"`, max 5000 characters), **required alt text** per image (max 5000 characters; publishing is blocked until every image has one). Both are multi-line fields that grow with their text; a character counter appears only in the last 500 characters.
- PDF: one file, max 20 MB, max 100 pages, required document title (pre-filled from the file name, max 5000 characters, no line breaks), "السماح بتحميل الملف" (Allow download) toggle, on by default, and the writer can turn it off. Shows "بنجهز الصفحات…" while processing, then a preview.
- Each upload shows progress, cancel and retry. Publishing is blocked while anything is uploading or processing.

**Display (feed card + post/article page)**
- One image → full width. Two or more images, or a PDF → **carousel**:
  - Horizontal scroll-snap; the next slide peeks from the edge; counter badge "3 / 12".
  - Desktop web: round ❮ ❯ arrows on hover (hidden at the ends) + keyboard ← →. Touch: swipe.
  - Optional caption bar under image slides.
  - RTL: starts from the right in the Arabic UI, arrows mirrored.
  - Only about 3 slides around the current one are rendered; BlurHash placeholders while loading.
- PDF: header strip "📄 {title} · 12 صفحة", page slides, a "+N صفحة، افتح الملف" card after 10 pages, and a download icon in the strip when download is allowed.
- **Full-screen viewer:** swipe/arrows, pinch and double-tap zoom, counter + thumbnail strip (PDF), close with ✕ / back / swipe down, "تحميل" (Download, only when allowed) and "مشاركة" (Share). Closing the viewer returns to exactly the same scroll position and focus, on web and mobile, and the page never jumps to the top.

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
- Feed: live counters on visible cards only, comments only while open on a card (F34), "مقالات جديدة ↑" banner.
- Notification bell: live unread badge.
- Upload processing status for the user's own PDFs.
- The user's own optimistic actions are not counted twice.
- If the Realtime Database is unavailable, everything still works through the REST API; only live updates are missing.


### F28 — Article Menu, Mute & Show Less
The reader's action bar has a "⋯" menu (web + mobile). Guests get a sign-in prompt for every item in it.

| Menu item | What it does |
|---|---|
| **قلّل من النوع ده** (Show less like this) | Removes this article from your feeds and lowers its topic (or its field if it has no topic) in **For you** for 90 days. Undo from the confirmation toast. |
| **إخفاء الـ Highlights** (Hide highlights) | Turns highlights on or off ([F30](#f30--highlights)). Also `Ctrl + /` on web. |
| **تابع الكاتب** (Follow author) | Follow or unfollow ([F12](#f12--follow)). Hidden on your own article. |
| **كتم الكاتب** (Mute author) | Hides the writer's articles and comments from you. Removes your follow of them. Hidden on your own article. Undo from the toast. |
| **كتم المواضيع** (Mute topics) | A sheet with the article's field and topic, each with a toggle. Undo by toggling it back. |
| **تحميل PDF** (Download PDF) | Downloads the article as a PDF ([F33](#f33--download-article-pdf-تحميل-المقال-pdf)). |
| **الإبلاغ عن المقال** (Report article) | Opens the report sheet with reason + details ([F22](#f22--reporting--moderation)). Shown in the error color, hidden on your own article. |

Mute author (كتم / إلغاء الكتم) is also on a profile's "⋯" (not on your own profile or the official account) and on a comment's "⋯" (mutes the commenter; not on your own comments), with the same rules and Undo, so someone who only writes comments can be muted too.

**What muting changes:**
- Muted writers, fields and topics disappear from For you, Following, Today's article, Related, Explore, Search and article lists on field pages.
- Comments and replies by a muted writer are collapsed to "تعليق من شخص كتمته" with a "عرض" action. Replies under them stay.
- A muted writer's activity sends you no notifications.
- Opening a direct link still works, so the reader can reach the Unmute action. A banner says "انت كاتم الكاتب ده" with "إلغاء الكتم".
- Muting is private: the muted writer is not told and keeps seeing your content.
- Mute is ReadIn's answer to the App Store's requirement to let people block abusive users (Guideline 1.2). Apple's review decides whether it is enough; if not, a separate Block action is needed.

**Settings → Muted (F18):** one list of muted writers, fields and topics, each with an unmute action.

### F29 — Repost
- Action bar: a repost button with a count, next to comments. Requires sign-in.
  - Tap it to open a small menu: **Repost** (right away, optimistic, with rollback on failure) or **Repost with your thoughts** (a dialog with an optional caption).
  - Once you've reposted, the same button opens **Edit your thoughts** and **Undo repost**.
- One repost per user per article. You can't repost your own article (`repost.own_article`).
- **Caption** (optional, plain text, at most 500 characters after trimming, line breaks kept; `repost.caption_too_long`): your thoughts on the article.
  - It shows under the "أعاد نشره {name}" label, above the article, wherever that label shows (Following feed, Reposts tab).
  - Editing it keeps the repost's time and sends no new notification; an empty caption clears it.
  - Undoing the repost deletes the caption with it.
- **Following feed:** an article a followed writer reposted appears at the time of the repost, labeled "أعاد نشره {name}". If several people you follow reposted it, it appears once, at the newest repost, labeled "{name} و N غيره". Articles you already got from a writer you follow aren't repeated.
- **Profile:** a **Reposts** tab, newest first.
- **Notification:** the author gets `article_reposted` (aggregated, respects preferences and mutes).
- **Live:** `repostCount` is added to `/live/articles/{id}` and updates like other counters ([F27](#f27--real-time-updates)).
- Article cards and details include `repostCount` and `isReposted`.
- Muted writers' reposts don't appear, and neither do reposts of articles by muted writers or in muted fields and topics.

### F30 — Highlights
Readers mark sentences in an article. Everyone sees the popular ones.

**Creating**
- Select text in a paragraph, heading, list item, quote, callout or summary block. A small toolbar offers **Highlight**. Selecting inside an existing highlight of yours offers **Remove**. Requires sign-in.
- A highlight stays inside one block: a selection across blocks is clipped to the first one. Code and table blocks can't be highlighted.
- 3–1,000 characters, at most 100 highlights per user per article.

**Storage**
- `ArticleHighlights`: `UserId`, `ArticleId`, `Language`, `BlockId`, `StartOffset`, `EndOffset`, `Text`, `CreatedAt`. One row per range per user; deleted with the user or the article.
- Offsets count UTF-16 code units in the block's **plain text**, without any BiDi isolate characters a renderer inserts. Web and mobile must produce the same offsets for the same selection (shared fixtures in `shared/rdoc/highlight-fixtures.json`).
- Plain text: the block's inline nodes in order (terms and mentions give their text, a hard break gives a line break); a list's items are joined by a line break and a highlight stays inside one item; a callout's title and a quote's cite are not part of it. Whitespace at both ends of a selection is trimmed.
- `Text` is checked by the server against the current translation's block. A wrong offset or text is rejected (`highlight.text_mismatch`), and so is a block that can't be highlighted (`highlight.block_not_allowed`).
- Your highlights in a block never overlap: a new one that overlaps or touches yours joins them into one.
- Language-specific: `ar-EG` highlights only show on the `ar-EG` version.
- If the author later edits the block, a highlight whose text no longer matches at its offsets is not returned and doesn't count; it is deleted the next time its owner highlights in that version.
- Errors: `highlight.text_mismatch`, `highlight.block_not_allowed`, `highlight.too_short`, `highlight.too_long`, `highlight.limit`, `highlight.not_found`. API and texts: [`docs/api/contract-v1.md`](api/contract-v1.md) ("Highlights (F30)"). Writes need `highlights.create` and use the `writes` rate limit.

**Reading**
- Your own highlights: amber underline with a soft background.
- Popular highlights: the same range marked by at least 3 readers, shown with a lighter underline. Tapping one shows "N قارئ علّموا الجملة دي". At most 5 popular highlights per article, most marked first.
- Muted users' highlights don't count for you. Neither a highlighter's name nor who marked what is ever shown to others.
- The same range means the same block, offsets and text. Each version's block texts and popular ranges are cached once for all readers; your own highlights and your mutes are applied per request and never cached.
- All colors work in light and dark mode, and highlights never break mixed Arabic/English text direction.

**Hide highlights**
- The menu item (and `Ctrl + /` on web) hides or shows all highlight marks.
- Stored as `ShowHighlights` in the profile preferences (F18), default on, synced across devices (`showHighlights` in `GET /me` and `PUT /me/preferences`). Guests can see popular highlights and hide them locally: it is the one "⋯" item that works for guests without the sign-in prompt.
- While hidden, no marks are drawn and selecting text shows no Highlight toolbar.

**Saved list:** the profile's **Saved** tab gets a **Highlights** section: `GET /me/highlights`, newest first, grouped by article (one group per language version, ordered by its newest highlight), tapping opens the article at the block. Articles you can no longer open are left out.


### F31 — Writer Categories (أقسام الكاتب)
A writer's own way to organize their articles. It is separate from:
- **Fields and topics:** platform-wide. Every article still has a field.
- **Collections (F13):** private lists of articles someone saved.
- **Learning paths (F09):** curated, ordered series.

**Creating and using**
- The editor's metadata panel has an optional **القسم** (Category) picker: the writer's own categories, plus "＋ قسم جديد" to create one on the spot.
- An article has **zero or one** category, and it applies to the article in all its language versions.
- Only the owner can see the picker or use a category (`category.not_owner`).
- Changing an article's category applies immediately. It needs no republish and creates no revision.

**Managing** (own profile → Categories)
- Create, rename, reorder and delete.
- Names: 1–40 characters, plain text, mixed Arabic/English with `dir="auto"`, unique per writer ignoring case and Arabic normalization (§22). At most 50 categories per writer (`category.limit`).
- Deleting asks for confirmation and shows how many articles are in the category. The articles stay published and become uncategorized.

**On the profile (web + mobile, for everyone including guests)**
- **Articles tab:** all the writer's published articles, newest first, regardless of category, like a Facebook profile feed.
- **Categories tab (الأقسام):** one card per category with its name and published-article count, in the writer's order. Tapping opens the category page, newest first with cursor paging. Articles with no category appear last, under "مقالات تانية".
- Visitors see only published articles, and empty categories are hidden from them. The owner also sees empty categories.
- Category page: `/@{username}/c/{slug}` on web (server-rendered) and `/u/{username}/c/{slug}` on mobile. The slug is generated once from the name (Arabic allowed), is unique per writer, and doesn't change on rename, so links keep working.
- **Reader:** the author row shows "في قسم {name}", which links to the category page.

**Edge cases**
- Articles hidden by moderation (F22) are not listed or counted.
- Offensive category names are handled by reporting the user (F22); a moderator can clear the name from the user's case (`clear_category`: a neutral `قسم {n}` / `Category {n}` and a new slug, logged and audited).
- Categories are deleted with the writer's account, and the articles that stay lose their category (§9.6).

### F32 — Tags (التاجات)
Tags are shared across the platform, so an article can be found by any tag on it, from any writer.

**Adding** (editor metadata panel)
- Type in the tag field to get suggestions from existing tags, most used first (`GET /tags?q=`).
- Pick a suggestion, or press Enter or comma. If nothing matches, the writer creates a new tag ("إنشاء تاج جديد"), usable by everyone from then on.
- At most **5 tags per article** (`article.too_many_tags`). Tags are optional.

**Rules**
- 2–30 characters: letters, digits, spaces and `- _ . + #`, so `C#`, `.NET` and `C++` work. A leading `#` is removed and extra spaces are collapsed.
- Tags are compared ignoring case and with Arabic normalization (§22), so `AI` and `ai` are one tag. The first spelling is kept.
- At most 20 new tags per user per day (`tag.limit`), to limit spam.

**Tag page**
- Every tag on the reader and on article cards is tappable, and it opens the tag page.
- Web: `/tags/{slug}` (server-rendered). Mobile: `/tags/:slug`, with deep links. Guests can open it.
- It shows the tag's name, its article count and **all published articles with that tag, from all writers**, newest first, with cursor paging and post cards (F34).
- Articles hidden by moderation (F22) are excluded, and muted writers and topics are too once F28 ships.
- An empty tag shows an empty state, and on web it is `noindex`.

**Upkeep**
- Users with `taxonomy.manage` can rename, merge and hide tags (F23). A hidden tag can't be picked and its page returns 404.
- A daily job deletes user-created tags that have had no articles for 30 days. System tags stay: the tags the seed articles use (the `tags` in each article's `meta.json` under `content/articles/`).

### F33 — Download Article PDF (تحميل المقال PDF)
Any signed-in member can download any article they can read as a clean, well-organized PDF that carries the ReadIn logo. The backend builds the file, so web and mobile get exactly the same result.

**Who and what**
- Any signed-in member, for any article they can open, with no verification needed. Guests get the sign-in prompt (F28).
- Published articles, and an author's own archived articles. The PDF shows the published version, even when a working copy has unpublished edits (F05). Drafts have no PDF.
- One PDF per language. In the reader it is the version on screen. In My articles, an article with two versions asks which one.
- An article hidden by moderators (F22) can't be downloaded, because the file carries the ReadIn logo: `409 article.pdf_hidden` for its author and `404 article.not_found` for everyone else.

**Where**
- Reader: "تحميل PDF" (Download PDF) in the "⋯" menu (F28).
- My articles (F05): the same action on each article in the Published tab.
- While the file is built the action shows "بنجهز الـ PDF…". A failure shows an error with "حاول تاني". With no connection it says internet is needed.
- Web: a normal browser download. Mobile: the system share sheet, to save the file or send it, with no storage permission.
- File name: `{slug}-{lang}.pdf`, sent with RFC 5987 `filename*` so Arabic slugs work, and `readin-article.pdf` as the ASCII fallback.

**Page layout**
- A4 portrait on white paper, always the light theme, whatever theme the app uses. Colors are the light tokens in §15.2.
- Direction follows the article language (`ar-EG` RTL, `en` LTR), not the app language. Labels in the file ("المصادر" / "Sources") follow it too.
- **Logo:** the approved `docs/design/app-store/logo/lockup.png` (R + ر mark with the ReadIn wordmark), copied into the API's resources, never redrawn or recolored. 32 mm wide at the top of the first page and 18 mm wide in every page's footer. No watermark over the text.
- **First page:** logo, title, writer's name with the verified badge, publish date, reading time, the AI-assisted label when the article has it (§20), field and topic, tags, the health disclaimer on Medicine and Public Health articles (§20), then the cover image. No phone number or other private data.
- **Footer on every page:** a thin line, then the logo, `readin.app` and the page number as `2 / 5`.
- **End of the article:** attachments, Sources with their full clickable URLs, then "منشور على ReadIn" (Published on ReadIn) with a link to the article.
- **Left out:** comments, reactions, counters, related articles, highlights and app buttons.
- **Text:** the fonts in §15.3. Body 11.5 pt with line height 1.8, H2 17 pt, H3 14 pt, code 9.5 pt.

| Content | In the PDF |
|---|---|
| `paragraph`, `heading`, lists | Each block keeps its own direction (§14.2) |
| `summary` | Tinted box at the top of the content |
| `steps`, `quote`, `divider` | Numbered steps with their titles, a quote with its source, a thin line |
| `callout` | Tinted box with a bundled SVG icon per variant, not an emoji |
| `code` | Always LTR on a light background, with the filename above it. Long lines wrap and are never cut. `highlightLines` get a tinted background. No syntax colors in the first version |
| `codeTabs` | Every tab printed one after the other under its label, because paper has no tabs |
| `table` | Full content width with wrapping text. The header repeats on each page and a row never splits |
| `image` | Up to the content width from the 1600 variant (cover: 1200), never upscaled, on one page with its caption. `darkSrc` is ignored and `alt` becomes the PDF's alternative text |
| `embed` | A card with the provider name and the full clickable link. The server fetches nothing from it |
| `term`, `mention`, `link` | Plain text, `@username` linked to the profile, and a clickable link |
| Image attachments | Printed after the content, each with its caption |
| PDF attachment | A card with its title, page count and a link to the article. Its pages are not merged into the file |

**No-bug rules** (each one has a test in §27, and a failure blocks the release)
1. **Arabic and mixed text:** letters connected and in the right order, and English, numbers and punctuation inside Arabic in the right place, using the same rules and shared fixtures as §14.2.
2. **No empty squares:** IBM Plex Sans Arabic, IBM Plex Sans, JetBrains Mono, Noto Sans (fallback), Noto Color Emoji, and Noto Sans Symbols 2 and Noto Sans Math (symbols such as ★ and ⇒) ship with the API and are embedded in the file. Nothing depends on fonts installed on the server.
3. **Nothing cut off:** long URLs, long words, code, tables and images stay inside the margins.
4. **Clean page breaks:** a heading stays with the lines after it, and an image stays with its caption. Callouts, list items, table rows and code of up to 20 lines don't split. Paragraphs keep at least 2 lines on each side of a break. Longer code and tables continue on the next page. There are no blank pages, including at the end.
5. **Real text:** text can be selected and searched, links can be clicked, and pages are never images.
6. **A proper document:** tagged PDF, bookmarks from H2 and H3, and title, author and language in the metadata. Western digits everywhere (§14.2). There is no contents page, since the bookmarks cover it.
7. **Small file:** a typical article stays under 5 MB.

**How it's built**
- `GET /articles/{id}/pdf?lang=`: `IArticlePdfRenderer` in Infrastructure turns RDoc into print HTML with all text HTML-encoded, and **headless Chromium** (through **PuppeteerSharp**) prints it. Chromium is the engine browsers use for Arabic shaping, BiDi and page breaks, which is the hard part of this feature. Building on the device would give two different files, and a pure .NET PDF library would have to prove all of that again.
- The footer template gets its own inline font and logo, because Chromium doesn't pass the page's fonts to it.
- **Built in the request, nothing stored:** the limits below keep the load small, and its input is validated RDoc rather than an uploaded file. The PDF is streamed and discarded, so there is no table, no file on disk and nothing new in §9.6.
- **Limits:** at most 2 builds at a time; a request waits up to 30 seconds, then `503 article.pdf_busy`. A build has 60 seconds, then `500 article.pdf_failed`, and Chromium restarts if it crashed. 10 PDFs per user per hour: `429 article.pdf_limit`.

### F34 — Post-style Feed Card (كارت البوست)
Articles appear in lists as social posts, like on LinkedIn and Facebook, not as a title next to a small image. People read the beginning, react and comment while scrolling, without leaving the feed. This replaces the current article row on web and mobile. Only the layout is similar to those apps: colors and logo stay ReadIn's (§15), with no LinkedIn blue.

**The card, top to bottom**

| Part | Content |
|---|---|
| Label (optional) | "مقال النهارده" (F07) or "أعاد نشره {name}" (F29) |
| Header | Avatar, name with the verified badge (or "Deleted user", with no profile link or follow). Under it: the writer's title (F14) on one line, then field · time since publishing · reading time. On the other side: "متابعة" (Follow) when you don't follow the writer and it isn't your article, Save, and "⋯" (F28) |
| Text | Title (up to 3 lines), then the beginning of the article, cut at 4 lines with "… اقرأ المزيد" (Read more) at the end of the last line. The button has its own `<bdi>`, so it never covers text or breaks mixed text (§14.2) |
| Media | Attachments if there are any (F26), otherwise the cover at full width (16:9). With neither there is no image at all, and the old placeholder icon is gone |
| Tags | Up to 3 tags (F32), then "+N" |
| Action bar | **Icons only, with no text labels**, each with its count beside it: React, Comment, Repost (F29), then Share (F24), which has no count. A count of 0 shows no number. On the other side, up to 3 reaction emojis that open who reacted. Always visible. Each icon still has an accessible name with its count (§26) |

Parts that belong to a feature not built yet (F24, F28, F29, F32) appear when that feature ships.

**Tapping:** the title opens the reader, the text expands it, an image opens the viewer (F26), the writer opens the profile. The action bar never leaves the feed. The whole card is no longer one big link.

**Read more**
- Tapping expands the card in place. The first expansion loads `GET /articles/{id}/preview?lang=`: about the first 300 words as real RDoc blocks, never cutting a block, always at least one.
- The card shows them with the reader's own renderer, so formatting, code, tables, images, glossary terms and BiDi look the same as in the reader. Embeds show as a link.
- If the article is longer, the end of the text shows "اقرأ المقال كله" (Read the full article), which opens the reader.
- "عرض أقل" (Show less) collapses it. Expanding only grows downward and moves nothing on screen. Collapsing brings the card's top back into view if it scrolled off.
- With no more text than the collapsed lines, there is no button.
- **Counting as read:** expanding alone is not a read. An article shown complete in the card counts under the F04 rule (70% seen and 30 seconds) through `PUT /articles/{id}/progress`, so short articles count toward streaks (F08). A cut-off article counts only in the reader.

**React and comment while scrolling**
- **React:** a tap gives 💡 or removes your reaction, and the icon changes to show your reaction. A long press on mobile, or hover or the keyboard on web, opens the four reactions (F10). It updates at once and rolls back on failure.
- **Comment on wide screens:** the comment icon opens a section in place under the card, with the comment box (F11), the top 2 comments and "عرض كل التعليقات", which loads more in place.
- **Comment on phones (app and narrow web):** a bottom sheet with the comments and the comment box (F11), and the feed stays where it was behind it.
- All F11 rules apply: the comment box and rows, replies, mentions, mixed text, rate limits, editing and live updates.
- Guests get the sign-in prompt, then return to the same place in the feed.
- Hidden, muted and deleted content follows the same rules as everywhere (F22, F28).

**While scrolling**
- Expanded cards, open comments, unsent comment text and the scroll position survive scrolling away and coming back from the reader or a profile. Pull to refresh resets them, except unsent text.
- New articles never push the list: only the "مقالات جديدة ↑" banner appears (F03).
- Counters are live on visible cards. Comments subscribe only while open (F27).

**Where it's used**
- **Post card:** Home (Today's article, For you, Following), field pages, Explore lists, profile Articles and Reposts, category pages (F31), tag pages (F32) and Related articles (F04).
- **Compact row stays** in lists people scan rather than read: Search results, Continue reading, learning path lists and "Next in path", My articles, Saved and the moderation queue.
- **Layout:** on web, one centered column up to 640 px wide. On mobile, full width. Cards are separated by a gap on `color.bg`.

**Data**
- `ArticleTranslations.Excerpt`: up to 400 characters of plain text, cut at a word, taken in order from the summary, paragraphs, lists, steps, quotes and callouts. Headings, code, tables, images and embeds are skipped. It is computed on publish (§13.5) and backfilled for existing articles.
- `ArticleCardDto` adds `excerpt`, `hasMore`, `isFollowingAuthor`, up to 3 `tags` and `tagCount` (for "+N").
- `preview` answers `404 article.not_found` wherever the article itself would, and is cached like article details.

**Accessibility:** every action is a real button with a label in both languages and reachable by keyboard, Read more has `aria-expanded`, focus stays on the card when it expands, and "reduce motion" is respected (§26).

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
| F20 | ~~Review Workflow~~ (removed, ADR 0015) | — | — | — |
| F21 | Glossary | ✅ | ✅ | 3 |
| F22 | Reporting & Moderation | ✅ | ✅ | 2 |
| F23 | Admin Console | ✅ | ✅ | 2 |
| F24 | Sharing | ✅ | ✅ | 2 |
| F25 | Offline | ✅ | ✅ | 3 |
| F26 | Post Attachments & Media | ✅ | ✅ | 1 |
| F27 | Real-time Updates | ✅ | ✅ | 1 |
| F28 | Article Menu, Mute & Show Less | ✅ | ✅ | 1 |
| F29 | Repost | ✅ | ✅ | 1 |
| F30 | Highlights | ✅ | ✅ | 1 |
| F31 | Writer Categories | ✅ | ✅ | 1 |
| F32 | Tags | ✅ | ✅ | 1 |
| F33 | Download Article PDF | ✅ | ✅ | 2 |
| F34 | Post-style Feed Card | ✅ | ✅ | 1 |

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
- Inline nodes: `text`, `term` (glossary term id + display text), `mention` (user id + display text `@username`: readers link it by that text, which the server rewrites at every publish, F05), `hardBreak`.
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
3. Extracts **plain text** (for search + reading time), the **excerpt** (feed cards, F34), **headings** (TOC), **terms** used, **code languages**.
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

### 14.4 Interface Copy (Web)
- The web interface's Arabic is **Modern Standard Arabic** (فصحى معاصرة), not Egyptian colloquial: standard, concise
  wording like the Arabic interface of major apps (user decision, 2026-11-06). Article content keeps §14.3.
- Buttons, menu items and tabs use verbal nouns (حفظ، حذف، مشاركة). Confirmation dialogs ask a question and offer
  «إلغاء» / «موافق».
- Brand and product names stay in Latin letters (ReadIn, Google, Apple, PDF).
- The top bar has an Arabic/English switch for the interface language (the `lang` cookie, and the profile when signed in).

---

## 15. Design System & Dark Mode

### 15.1 Brand
- **Name:** ReadIn (always written in English, also in the Arabic UI).
- **Taglines:** "ReadIn — مقال كل يوم يفرق معاك" / "Read daily. Grow daily."
- **Logo:** approved logo in `docs/design/`. Must not resemble LinkedIn (no LinkedIn blue, no identical "in" box).
- **Mood:** calm, premium, editorial. "Medium meets Duolingo". Lists feel like a social feed of posts ([F34](#f34--post-style-feed-card-كارت-البوست)), and the reader stays calm and editorial.

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
9. **Every UI change is covered by screenshots in `ar/light` and `en/dark`** for web and mobile: Playwright screenshots on web, golden tests on mobile. The two cover both directions and both themes, so Playwright flows and mobile golden tests run only in those two. Mobile widget and logic tests still run in all four combinations (ar/en × light/dark).

---

## 16. Database Design

### 16.1 Conventions
- SQL Server, EF Core migrations in `ReadIn.Infrastructure`.
- Primary keys: `uniqueidentifier`, generated by **EF Core's default Guid generation** (`ValueGeneratedOnAdd`). On SQL Server, EF Core uses its sequential GUID generator, whose values follow SQL Server's `uniqueidentifier` sort order, so inserts stay ordered in the clustered index. Keys are assigned when an entity is added to the `DbContext`; domain code never generates them, and `Guid.CreateVersion7()` is not used for keys (v7 GUIDs are not sequential under SQL Server's ordering). Domain events are materialized at `SaveChanges`, after keys exist. Fixed reference keys (roles, system accounts) stay explicit constants; every other seeded row is upserted by its natural key (role name, permission code, field slug, email, article slug). See [ADR 0006](adr/0006-sequential-guids.md).
- Audit columns on all tables: `CreatedAt`, `CreatedBy`, `UpdatedAt`, `UpdatedBy` (UTC `datetime2`).
- Soft delete: `IsDeleted`, `DeletedAt` with global query filters.
- Text columns used for search use collation **`Arabic_100_CI_AI`** (ignores case and Latin accents). It does **not** ignore Arabic diacritics (تشكيل) or letter forms, so searches compare text with the §22 normalization applied to both sides.
- `rowversion` concurrency token on aggregates (Articles, Comments, Users).
- Counters (reactions, comments, saves, reads) are denormalized on `Articles` and updated by outbox handlers.

### 16.2 Tables
| Area | Tables |
|---|---|
| Identity | `Users` (PhoneNumber E.164 `varchar(16)` unique, PasswordHash, SecurityStamp, FailedLoginCount, LockoutEndAt, MustChangePassword, RecoveryPinHash, RecoveryPinSetAt, RecoveryFailedCount, RecoveryLockoutEndAt, RecoveryDisabled, MustSetRecoveryPin, IsProfileComplete, IsVerified, VerifiedAt, Email (only from a provider-verified address; links Google/Apple sign in), DisplayName, Username unique, AvatarUrl, Headline, Bio, Links JSON (`[{ platform, url, label? }]`, F14), UiLanguage, ArticleLanguagePref, ThemePref, TimeZone, ReminderTime, PublicReadingStats, WhoCanMention Everyone/Following/Nobody (default Everyone), ShowHighlights (default on, F30), IsSuspended, SuspendedUntil), `UserExpertiseFields` (UserId + FieldId key, Position; ≤ 5 per user, F14), `UserExternalLogins` (UserId, Provider google/apple, Subject, Email, LinkedAt, LastUsedAt, ProviderRefreshToken (Apple, encrypted), ProviderClientId), `Roles`, `Permissions`, `RolePermissions`, `UserRoles` |
| Auth | `RefreshTokens` (UserId, TokenHash, FamilyId, ExpiresAt, CreatedAt, CreatedByIp, DeviceName, RevokedAt, ReplacedById), `PasswordResetTokens` (UserId, TokenHash, ExpiresAt, UsedAt, CreatedByIp), `RecoveryAttempts` (UserId?, PhoneNumberHash, Ip, Succeeded, CreatedAt) |
| Devices | `UserDevices` (FCM token, platform, device name, app version, language, last seen) |
| Media | `MediaAssets` (OwnerId (null once a deleted account's asset stays with its published article), Kind Image/Document, Purpose Image/Avatar/Cover/Document, Status Uploading/Processing/Ready/Failed, FailureReason (stable code), OriginalPath, OriginalSizeBytes, StoredBytes (quota), Width, Height, BlurHash, Variants JSON `{ "320": { height, path, bytes }, … }` + `ISJSON` check, PageCount, Title `nvarchar(max)` ≤ 5000 (`Arabic_100_CI_AI`), AllowDownload, ExtractedText `nvarchar(max)` (`Arabic_100_CI_AI`)), `MediaAssetPages` (AssetId + PageNo key, ThumbPath, ViewPath, Width, Height, BlurHash, Bytes), `ArticleAttachments` (ArticleId + MediaAssetId key, Order, Caption ≤ 5000, AltText ≤ 5000, both `nvarchar(max)`); see [ADR 0011](adr/0011-media-pipeline-and-pdf-preview.md) |
| Taxonomy | `Fields` (Slug, NameAr, NameEn, Icon, Color, IsSensitive (shows the health disclaimer, never blocks publishing), RequiresSources, IsEnabled), `Topics`, `Tags` (Slug (made once, URL-safe, unique), Name (the first spelling), NormalizedName (lower case + §22 normalization, unique, compared exactly: `Latin1_General_100_BIN2`), IsSystem (used by the seed content; never cleaned up), CreatedById (no FK; null for system tags and once the creator deleted the account), CreatedAt, IsHidden, EmptySince (no published article carries it since then; the daily cleanup, F32)), `ArticleTags` (ArticleId + TagId key, Position: the writer's order), `WriterCategories` (F31: UserId → Users cascade, Name ≤ 40 (the writer's spelling), NormalizedName (lower case + §22 normalization, compared exactly: `Latin1_General_100_BIN2`), Slug (made once from the first name; a moderator's clear makes a new one), SortOrder, CreatedAt; UserId+Slug unique, UserId+NormalizedName unique; ≤ 50 per writer), `UserInterests` |
| Articles | `Articles` (AuthorId (null: the author deleted their account, §9.6), FieldId, TopicId, WriterCategoryId (null: no category; F31, `ON DELETE SET NULL`, set outside the editor's working copy), Slug, Status Draft/Published/Archived, SourceLanguage, CoverUrl, IsAiAssisted, VersionBadge, AutoCheckedAt, PublishedAt, QualityScore, counters, HiddenAt + HiddenById (hidden by a moderator, F22; no FK)), `ArticleTranslations` (ArticleId, Language, Title, Subtitle, Summary, Excerpt `nvarchar(400)` + ExcerptHasMore (the F34 card text and whether the article holds more; Excerpt null until the backfill job fills a pre-F34 version), ContentJson `nvarchar(max)` + `ISJSON` check, PlainText, SearchText, ReadingTimeMinutes, IsSource), `ArticleDrafts` (ArticleId key, DocumentJson: the editor's working copy, Version concurrency token, HasChanges, SavedAt; F05), `ArticleRevisions` (ArticleId, RevisionNumber, Title, Languages, DocumentJson: the document of one publish, CreatedBy, CreatedAt), `ArticleTags`, `ArticleSources` (Title, Url, LastCheckedAt, IsAlive) |
| Engagement | `Reposts` (UserId+ArticleId unique, CreatedAt), `ArticleHighlights` (F30: UserId → Users cascade, ArticleId → Articles cascade, Language `varchar(5)`, BlockId `varchar(64)`, StartOffset, EndOffset (UTF-16 code units, end exclusive, ≤ 1000 apart, a check constraint), Text `nvarchar(1000)`, CreatedAt; BlockId and Text compared exactly: `Latin1_General_100_BIN2`), `UserMutes` (MuterId+MutedUserId unique), `ContentMutes` (UserId, TargetType Field/Topic, TargetId, unique), `ArticleFeedback` (UserId+ArticleId unique, Type ShowLess, CreatedAt), `Reactions` (UserId+ArticleId unique, Type), `Comments` (ArticleId, ParentId = the top-level comment, AuthorId nullable = "Deleted user", Body ≤ 2000, IsPinned, PinnedAt, LikeCount, ReplyCount, EditedAt, HiddenAt, HiddenById, DeletedByModerator; one pinned per article), `CommentLikes` (CommentId+UserId unique), `CommentMentions` (CommentId+UserId), `UserFollows` (FollowerId+FolloweeId), `FieldFollows`, `SavedArticles`, `Collections`, `CollectionItems` |
| Reading | `ReadingProgress` (UserId, ArticleId, Language, Percent, LastPosition, ActiveSeconds, StartedAt, CompletedAt), `DailyPicks` (UserId, Date, ArticleId, OpenedAt), `UserStats` (CurrentStreak, LongestStreak, LastReadDate, LastFreezeDate, TotalArticles, TotalSeconds), `ReadingDays` (UserId, local Date, ArticlesRead, ActiveSeconds; streaks + heatmap) |
| Learning | `LearningPaths` (Slug, FieldId, TitleAr/En, DescriptionAr/En, SortOrder, IsPublished, IsEditorial, IsFeatured + FeaturedOrder (Explore's featured paths, F15; editorial paths start featured in their sort order, F23 will manage it)), `LearningPathItems` (PathId + ArticleId unique, Order), `PathEnrollments` (UserId + PathId unique, EnrolledAt, LastActivityAt, CompletedAt) |
| Glossary | `GlossaryTerms` (Slug = the RDoc `termId` unique, TermEn, DefinitionEn, ExplanationAr), `ArticleTerms` (ArticleId + TermId key; rebuilt from the content's `term` nodes) |
| Trust & Moderation | `VerificationRequests` (F19: UserId → Users cascade, FieldId → Fields no cascade, JobTitle ≤ 100, ProofUrl ≤ 500, ProofFilePath / ProofFileContentType / ProofFileSizeBytes / ProofFileName ≤ 120 (null once decided), Note ≤ 500, Status `Pending`/`Approved`/`Rejected` (a concurrency token), SubmittedAt, DecidedAt, DecidedById (no FK; account deletion nulls it), RejectionReason ≤ 500), `Reports` (TargetType article/comment/user, TargetId, ReporterId, Reason, Details, Status open/resolved/dismissed, ResolvedAt, ResolvedById (resolved or dismissed by); one per reporter and target), `ModerationActions` (the moderation log, F22: Action `varchar(32)` e.g. `article.hide`, TargetType, TargetId, TargetUserId, ModeratorId, TargetLabel ≤ 200 (title / first 80 characters / @username at the time), Note ≤ 500, SuspendedUntil, ReportsClosed, CreatedAt, NoticeKind warning/article_hidden (a notice the user acknowledges), AcknowledgedAt; no FKs to Users, account deletion nulls them), `AuditLogs` |
| Notifications | `Notifications` (UserId, Type, Payload JSON, IsRead), `NotificationPreferences` |
| Infrastructure | `OutboxMessages`, `SeedHistory` (seeder name + version + checksum), Hangfire schema |

### 16.3 Key Indexes
- `Articles(Status, PublishedAt DESC)` filtered on `IsDeleted = 0`.
- `Articles(FieldId, Status, QualityScore DESC)`.
- `ArticleTranslations(ArticleId, Language)` unique.
- `Comments(ArticleId, ParentId, CreatedAt)`.
- `Reports(Status, TargetType, TargetId)` (the queue), `ModerationActions(TargetType, TargetId, CreatedAt)`, `(TargetUserId, CreatedAt)`, `(ModeratorId, CreatedAt)` and `(TargetUserId, AcknowledgedAt)` filtered on `NoticeKind IS NOT NULL` (notices).
- `ReadingProgress(UserId, ArticleId)` unique.
- `VerificationRequests(Status, SubmittedAt)` (the admin queue), `(UserId, SubmittedAt)` (the user's latest request) and `(UserId)` unique filtered on `[Status] = 'Pending'` (one pending request per user).
- `Reactions(ArticleId, Type)`, `UserFollows(FolloweeId)`.
- `ArticleHighlights(UserId, ArticleId, Language, BlockId, StartOffset, EndOffset)` unique, including `CreatedAt` (your highlights, the limit, Saved → Highlights), and `ArticleHighlights(ArticleId, Language, BlockId, StartOffset, EndOffset)` including `UserId` (popular ranges and the viewer's muted writers, F30).
- `Articles(WriterCategoryId, PublishedAt DESC)` and `ArticleTags(TagId, ArticleId)`, for the category and tag pages.
- `Tags(Slug)` and `Tags(NormalizedName)` unique, `Tags(CreatedById, CreatedAt)` (new tags per writer per day, F32).
- Full-Text indexes on `ArticleTranslations(SearchText)` and `MediaAssets(ExtractedText)` in the catalog `ReadInSearch` (Arabic word breaker, no stoplist, automatic change tracking), created by the `SearchFullText` migration only when the server has Full-Text Search; without it search uses its `LIKE` fallback ([ADR 0017](adr/0017-search-full-text-with-like-fallback.md)). Names (`Users`, fields, topics, tags) are matched with normalized `LIKE`, not full-text.
- `Users(PhoneNumber)` unique, `RefreshTokens(TokenHash)` unique, `RefreshTokens(UserId, RevokedAt)`, `UserExternalLogins(Provider, Subject)` unique, `UserExternalLogins(UserId, Provider)` unique.
- `ArticleAttachments(MediaAssetId)` unique (an asset belongs to one post), `MediaAssets(OwnerId, CreatedAt)` (quotas), `MediaAssets(CreatedAt)` (orphan cleanup).
- Media paths are stored **relative** (`/uploads/...`); absolute URLs are built from `Storage:PublicBaseUrl`, so a domain change never needs a data migration.

---

## 17. API Design

### 17.1 Conventions
- REST, JSON, base path `/api/v1`, OpenAPI documented, Scalar UI at `/docs` (non-production).
- `Accept-Language: ar | en` controls error messages and taxonomy names. `?lang=ar-EG|en` selects the article version.
- Article cards (feeds, today's article, a profile's articles) come in the viewer's article language preference; for a guest, in the version that matches `Accept-Language` (`ar` → `ar-EG`, `en` → `en`). Either way the source language is the fallback.
- Cursor pagination for feeds (`?cursor=...&limit=20`), offset pagination for admin tables.
- Idempotent `PUT`/`DELETE` for toggles (reactions, follow, save).
- Errors: ProblemDetails with `code`, `traceId` and `errors` (validation).

### 17.2 Main Endpoints
| Area | Endpoints |
|---|---|
| Auth | `GET /auth/config` (PIN length, password rules) · `POST /auth/register` (phone, password, pin) · `POST /auth/login` · `POST /auth/refresh` · `POST /auth/logout` · `POST /auth/logout-all` · `POST /auth/recovery/verify-pin` → reset token · `POST /auth/recovery/reset-password` |
| Me | `GET /me` (incl. `hasRecoveryPin`, `mustSetRecoveryPin`, `mustChangePassword`, `isProfileComplete`, `privacy`) · `PATCH /me` (incl. `avatarAssetId`, `expertiseFieldIds`, `links[]`, `headline`) · `PUT /me/privacy` · `PUT /me/profile/complete` · `PUT /me/password` · `PUT /me/phone` · `POST /me/recovery-pin` (first set) · `PUT /me/recovery-pin` (change) · `PUT /me/preferences` (incl. `showHighlights`, F30) · `PUT /me/interests` · `POST /me/devices` · `DELETE /me/devices/{token}` · `DELETE /me` · `GET /users/username-available?u=` |
| Real-time | `POST /realtime/token` (Firebase custom token, used only to read the Realtime Database) |
| Feed | `GET /feed/today` · `GET /feed/for-you` · `GET /feed/following` · `GET /feed/continue-reading` |
| Articles | `GET /articles/{slug}?lang=` · `GET /articles/{id}/related` · `PUT /articles/{id}/progress` · `GET /articles/{id}/pdf?lang=` (signed-in members, F33) · `POST /articles/{id}/quote-card` (`{ language, blockId, startOffset, endOffset, text, theme, format }` → PNG, F24) · `GET /articles/{id}/preview?lang=` (first ~300 words as RDoc + `isComplete`, F34) |
| Editor (F05) | `GET /me/articles?status=draft\|published` · `POST /articles` (new draft) · `GET /articles/{id}/edit` · `PUT /articles/{id}/draft` (autosave, `baseVersion`) · `DELETE /articles/{id}/draft` (discard) · `POST /articles/{id}/publish` (publish or Update) · `GET /articles/{id}/revisions` · `GET /articles/{id}/revisions/{n}` · `POST /articles/{id}/revisions/{n}/restore` · `DELETE /articles/{id}` |
| Reactions | `PUT /articles/{id}/reaction` · `DELETE /articles/{id}/reaction` · `GET /articles/{id}/reactions` |
| Reposts | `PUT /articles/{id}/repost` · `DELETE /articles/{id}/repost` (idempotent, return `{ repostCount, isReposted }`) · `GET /users/{username}/reposts` |
| Mute & feedback | `PUT` / `DELETE /users/{id}/mute` · `PUT` / `DELETE /me/mutes/fields/{id}` · `PUT` / `DELETE /me/mutes/topics/{id}` · `GET /me/mutes` · `PUT` / `DELETE /articles/{id}/show-less` |
| Highlights | `GET /articles/{id}/highlights?lang=` (returns `{ articleId, language, mine[], popular[] }`) · `POST /articles/{id}/highlights` (`{ language, blockId, startOffset, endOffset, text }` → `{ highlight, replacedIds }`) · `DELETE /highlights/{id}` · `GET /me/highlights?cursor=&limit=` (groups per article version) — contract in [`docs/api/contract-v1.md`](api/contract-v1.md) ("Highlights (F30)") |
| Comments | `GET /articles/{id}/comments?sort=top\|new` · `POST /articles/{id}/comments` · `GET /comments/{id}` · `GET /comments/{id}/replies` · `POST /comments/{id}/replies` · `PATCH /comments/{id}` · `DELETE /comments/{id}` · `PUT/DELETE /comments/{id}/like` · `POST/DELETE /comments/{id}/pin` · `GET /users/mention-suggestions?q=` |
| Follow | `PUT /users/{id}/follow` · `DELETE /users/{id}/follow` · `GET /users/{id}/followers` · `GET /users/{id}/following` · `GET /users/suggested` · `PUT/DELETE /me/interests/fields/{id}` · `PUT/DELETE /me/interests/topics/{id}` |
| Saved | `GET /me/saved` · `PUT /me/saved/{articleId}` · `DELETE /me/saved/{articleId}` · `CRUD /me/collections` · `PUT/DELETE /me/collections/{id}/articles/{articleId}` |
| Users | `GET /users/{username}` · `GET /users/{username}/articles` · `GET /users/{username}/stats` · `GET /users/{username}/stats/heatmap` (public reading stats only, F18) · `GET /me/stats` · `GET /me/stats/heatmap` |
| Taxonomy | `GET /fields` · `GET /fields/{slug}/topics` |
| Tags | `GET /tags?q=` (most used first) · `GET /tags/{slug}` · `GET /tags/{slug}/articles?cursor=` · `/admin/tags` (rename, merge, hide) |
| Writer categories | `GET /users/{username}/categories` · `GET /users/{username}/categories/{slug}` (page header) · `GET /users/{username}/categories/{slug}/articles?cursor=` (`_other` = the uncategorized list) · `GET` / `POST /me/categories` · `PATCH` / `DELETE /me/categories/{id}` · `PUT /me/categories/order` · `PUT /articles/{id}/category` (`{ categoryId \| null }`) — contract in [`docs/api/contract-v1.md`](api/contract-v1.md) ("Writer categories") |
| Paths | `GET /paths` · `GET /paths/{slug}` · `POST /paths/{id}/enroll` |
| Search | `GET /search?q=&type=articles\|users\|topics\|tags&field=&lang=&minMinutes=&maxMinutes=&cursor=&limit=20` · `GET /search/suggest?q=` (top 3 of each type) — contract in [`docs/api/contract-v1.md`](api/contract-v1.md) ("Search") |
| Explore | `GET /explore` (fields, trending, most saved, new writers, featured paths) · `GET /explore/trending?cursor=` · `GET /explore/most-saved?cursor=` · `GET /fields/{slug}` (field page header and topics) · `GET /fields/{slug}/articles?topic=&cursor=` · `GET /fields/{slug}/writers` (F15) — contract in [`docs/api/contract-v1.md`](api/contract-v1.md) ("Explore and field pages") |
| Glossary | `GET /glossary/{slug}` · `GET /glossary?q=` |
| Notifications | `GET /notifications` · `POST /notifications/read` · `GET/PUT /me/notification-preferences` |
| Uploads & media | `POST /uploads/images` (purpose `image` \| `avatar` \| `cover`; `article-image` is still accepted) · `POST /uploads/documents` (PDF, `202` + processing) · `GET /uploads/{id}` (status, variants, pages) · `DELETE /uploads/{id}` · `GET /documents/{assetId}/download` (attachments are part of the editor draft) — contract in [`docs/api/contract-v1.md`](api/contract-v1.md) |
| Trust | `GET /me/verification` · `POST /verification-requests` (multipart) · `DELETE /me/verification` (withdraw) |
| Moderation | `POST /reports` · `GET /moderation/summary` · `GET /moderation/reports?status=&type=` · `GET /moderation/reports/{targetType}/{targetId}` · `POST /moderation/actions` · `GET /moderation/actions` (log) · `GET /me/moderation-notices` · `POST /me/moderation-notices/{id}/acknowledge` |
| Admin | `/admin/users`, `POST /admin/users/{id}/reset-password`, `/admin/fields`, `/admin/topics`, `/admin/paths`, `/admin/verification-requests` (list, detail, `/{id}/proof`, `/{id}/approve`, `/{id}/reject`), `DELETE /admin/users/{id}/verification`, `/admin/dashboard`, `/admin/content-pipeline`, `POST /admin/realtime/rebuild-counters` |

---

## 18. Seeding: Users, Reference Data, Articles

### 18.1 Principles
- Seeders are **idempotent** (upsert by natural keys: role name, field slug, phone number, article slug) and **versioned** (`SeedHistory` stores name + version + checksum, so a seeder only re-runs when its data changes).
- **Runs automatically at API start in every environment, Production included**, with nothing to run by hand: `Database:MigrateOnStartup` and `Seed:RunOnStartup` are on by default. The first start on an empty production database creates the roles, fields, system accounts and the 300 articles. Later starts only touch what changed (`SeedHistory`), so they stay fast and never duplicate an article. `dotnet run --project ReadIn.Api -- seed [--force]` stays for manual runs.
- **`content/` ships with the API:** `dotnet publish` and the container image include the `content/` folder, and `Content:RootPath` defaults to it, so production doesn't need the repo.
- The API serves requests only after seeding finishes, so the first start takes longer and the host's health check must allow for it. A failed seeder logs a clear error and stops the start, like a failed migration.
- Re-importing an article changes only its content and metadata, never its reactions, comments, saves or reads.
- **Articles are real content in every environment.** Every seeded article belongs to the official `@readin` account and comes from `content/articles`: text, with images only when they are real and fit the article. There are no demo authors, demo PDFs or placeholder images, and demo accounts have no articles of any status. Demo accounts and their interactions stay local only.
- Environment-gated: **demo users and demo interactions are seeded only into the local database** (`Development` and `Testing` environments), never into production.
- Passwords and PINs are **never** committed. They come from configuration: `Seed:DemoPassword`, `Seed:DemoPin` (must pass the weak-PIN policy), `Seed:SuperAdminPhone`, `Seed:SuperAdminPassword` (user-secrets locally, secret store in production).

### 18.2 Seeding Order
| # | Seeder | Environments |
|---|---|---|
| 1 | Roles & Permissions | All |
| 2 | Fields and Topics (from `content/taxonomy.yaml`) | All |
| 3 | System accounts (the official `ReadIn` account, `SuperAdmin`) | All |
| 4 | Demo users (SQL Server) | Local only |
| 5 | Official account avatar (`content/assets/readin-avatar.png` through the image pipeline) | All |
| 6 | Articles (from `content/articles/`, status-aware, covers through the image pipeline, re-imported per article when its files change). The tags in their `meta.json` become system tags (F32) | All, Production included |
| 7 | Learning paths (`learningPaths` in `taxonomy.yaml` + each article's `learningPath`) | All |
| 8 | Glossary terms (`content/glossary/*.yaml`, upserted by term id) and the article-term index, rebuilt when a glossary file or an article changes | All |
| 9 | Demo interactions (follows, reactions, comments, saves, reading history, streaks) | Local only |
| 10 | Demo reports (`demo-reports`, F22): open, resolved and dismissed reports on @readin's articles, comments and a user, and a warning notice for reader7 | Development only |
| 11 | Demo notifications (`demo-notifications`, F17): a few read and unread entries of every kind for reader1, writer1, reader2 and reader7, without pushes | Development only |
| 12 | Demo verification requests (`demo-verification`, F19): pending for writer1 (LinkedIn URL + PNG certificate), writer2 (GitHub URL only) and writer3 (PDF syndicate card only), reader5 rejected with a reason and the .NET Writer approved, both by the demo SuperAdmin (`+12025550101`); the proof files are drawn by the seeder into the private store; no notifications | Development only |

### 18.3 Seed Users
Users are created in SQL Server only (no Firebase Auth). Phone numbers use the reserved fictional range **+1 202 555 01XX** (555-0100 to 555-0199 are reserved for fiction, so they never belong to a real person).

| Phone | Display name | Roles | Recovery PIN | Environments |
|---|---|---|:-:|---|
| `+201229391155` | ReadIn (official account, `@readin`) | Member + Verified badge | — | All (cannot sign in, author of seeded articles; fixed id) |
| `+12025550101` | Super Admin | SuperAdmin | ✅ | Local |
| `+12025550104` | .NET Writer | Member + Verified badge | ✅ | Local |
| `+12025550105` | AI Writer | Member + Verified badge | ✅ | Local |
| `+12025550107` … `+12025550109` | Writer 1–3 | Member | ✅ | Local |
| `+12025550110` … `+12025550118` | Reader 1–9 | Member | ✅ | Local |
| `+12025550119` | Reader 10 | Member | ❌ (tests the mandatory "set PIN" screen) | Local |
| `+12025550120` | Suspended User | Member (suspended) | ❌ | Local |

**Production SuperAdmin:** seeded from `Seed:SuperAdminPhone` + `Seed:SuperAdminPassword` with `MustChangePassword = true` and `MustSetRecoveryPin = true`.

**Dev login panel (debug builds only):** lists the seed users with a PIN ✅/❌ indicator and signs in with one tap. It is compiled out / tree-shaken from production builds.

Demo users get realistic profiles (bios mixing Arabic and English, interests, avatars), follow relationships, reading history with streaks (e.g. `reader1` has a 12-day streak), comments and replies, reactions and saved articles, so every screen looks real in development.

> **No fake personas in production.** All seeded articles are published under the official **ReadIn** account with the "AI-assisted" label. There is no review ([ADR 0015](adr/0015-open-publishing-and-the-editor.md)).

---

## 19. Content Pipeline: 300 Seed Articles

### 19.1 Seed Plan (Software)
The platform's own launch content, published by the official ReadIn account. Members can publish about any topic ([§1.4](#14-fields-domains)); this plan only covers what ReadIn seeds.

| Field | Example topics | Articles |
|---|---|---:|
| AI Fundamentals | AI concepts, prompt engineering, AI ethics, RAG, agents | 20 |
| Machine Learning | Supervised/unsupervised, feature engineering, evaluation, scikit-learn, MLOps | 30 |
| Deep Learning & LLMs | Neural networks, transformers, embeddings, fine-tuning, vector DBs | 10 |
| Claude & AI Coding Tools | Claude Code, CLAUDE.md, `/compact` & context management, Skills, Hooks, Subagents, MCP servers, Plugins, Claude API & tool use, prompt caching, community plugins (e.g. Superpowers, **labeled as community, not official**) | 25 |
| .NET | C#, ASP.NET Core, EF Core, Clean Architecture, CQRS, Mapster, minimal APIs, testing, performance | 45 |
| Frontend | HTML/CSS, TypeScript, Angular, React, state management, accessibility, performance | 70 |
| Mobile | Flutter, Dart, state management, Kotlin, Swift, app architecture, publishing | 25 |
| Databases | SQL Server, PostgreSQL, indexing, query tuning, NoSQL, Redis | 20 |
| DevOps & Cloud | Git, Docker, CI/CD, Kubernetes basics, Azure, observability | 20 |
| Software Architecture | SOLID, design patterns, DDD, microservices, system design | 20 |
| Security | OWASP Top 10, auth (OAuth/OIDC/JWT), secrets, secure coding | 15 |
| **Total** | | **300** |

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
5. Import         → seeder imports into SQL Server     status: Published
```

Commands:
```bash
dotnet run --project src/ReadIn.ContentStudio -- generate --field dotnet --limit 20
dotnet run --project src/ReadIn.ContentStudio -- validate --all
dotnet run --project src/ReadIn.ContentStudio -- import
```

### 19.3 Automatic Validation
`ContentStudio validate` runs every check below and fails on any error; the `content` CI workflow runs it with `--plan` and `--all`. The writing rules behind them are in [content/AUTHORING.md](../content/AUTHORING.md).

| Check | How |
|---|---|
| Plan | `validate --plan`: unique kebab-case slugs, known field/topic/learning path, path orders 1..N, 2–5 https sources, near-duplicate titles (error) and misconceptions (warning) by keyword similarity |
| Schema | Both files pass `rdoc.schema.json` and the server-side sanitizer (§13.5) |
| Structure | TL;DR summary first, hook paragraph, ≥ 3 H2, ≥ 1 `tip` and ≥ 1 `warning`/`danger` callout, a comparison table, code (or `steps` for non-code topics), and a final "Key takeaways" H2 with 3–5 bullets |
| Structure parity | `en` and `ar-EG` have the same blocks in the same order: same ids and types, identical code (lang, filename, text), same table shapes, list/step counts and callout variants |
| Length | 900–1,800 words per language, reading time 5–9 min (§13.5 formula) |
| Text & BiDi | No emoji in body text (only the ❌/✅ tab labels), no raw HTML, alt text on images, Western digits and Arabic punctuation (، ؛ ؟) in `ar-EG`, no `ar-EG` block that would resolve LTR, glossary terms exist in `content/glossary/` |
| **Code compiles** | C# with Roslyn (.NET 10, Web SDK implicit usings, ASP.NET Core/EF Core/Mapster/Mediator referenced), TypeScript/TSX with `tsc --noEmit` (React 19, Angular 22), Dart with `dart analyze`, Python byte-compiled **and run** with scikit-learn, JavaScript `node --check`, Bash `bash -n`, JSON/YAML parsed. `"compile": false` needs a reason in `meta.json`; other languages are listed as not compiled. A missing toolchain is an error |
| Sources alive | Every source answers HTTP 200 after redirects (polite: 2 requests per host, retries with back-off; successes cached for a week). A host that still answers 429 after the retries (it limits automated requests, as rfc-editor.org does) is a warning, not an error, and is checked again next run |
| Duplicates | Unique slugs; titles compared by keyword similarity across all articles |
| Trust & freshness | Matches the plan (field, topic, level, path, version badge, titles), `status: published`, `isAiAssisted: true`, `lastReviewedAt` (the pipeline check date), 2–5 sources, a 1200×630 `cover.webp` |

### 19.4 Publishing Strategy
- **Seed set: 300 articles** by the official **ReadIn** account, planned in `content/taxonomy.yaml` (23 learning paths across AI, ML, Claude & AI tools, .NET, React, Angular, frontend, mobile, databases, architecture, DevOps and security). Each one corrects a misconception developers commonly hold. They are published with the AI-assisted label, with staggered publish dates over the last ~120 days, and like any published article they can be Today's article (F07, ADR 0015).
- **Launch with all 300**, organized into learning paths.
- **Growth after launch** comes from members publishing in any field, plus more ReadIn articles when wanted (`ContentStudio generate`). There is no fixed article target.
- Quality gates (§19.3) and the AI-assisted label keep seeded content from being thin, unlabeled mass content, which search engines penalize.
- Fast-moving topics (Claude, AI tools, framework versions) get a **re-verification job** every 90 days: sources re-checked, `AutoCheckedAt` updated or the article flagged "may be outdated".

### 19.5 Content Files in Git
Seed content lives in `content/articles/{field}/{topic}/{slug}/` so it is versioned, reviewable in git history, and reproducible in every environment: `meta.json`, `en.json` (source of truth), `ar-EG.json` and `cover.webp` (1200×630, rendered by `tools/content-covers`). Writers draft in `en.md` / `ar-EG.md` (git-ignored) and `ContentStudio compose` turns them into RDoc. Glossary terms live in `content/glossary/{field}.yaml`; the official account's avatar is `content/assets/readin-avatar.png`.

---

## 20. Trust & Content Quality

| Mechanism | Description |
|---|---|
| Verified writers | Identity/expertise verification with a badge |
| Sources | Required in fields with `RequiresSources` on (software, Medicine, Public Health, Engineering), optional elsewhere, shown at the end of the article |
| Version badge | e.g. `.NET 10`, `Angular 21`, `Flutter 3.x` |
| AI-assisted label | Shown on every AI-assisted article. Never hidden. |
| Tested code | Code snippets compiled in the content pipeline |
| Community signals | Reports for misinformation, quality score from engagement, read completion and freshness (ranks Today's article, ADR 0015) |
| Health content | Medicine/Public Health articles publish without approval, show a disclaimer ("لا يغني عن استشارة الطبيب") and require sources. Misinformation is handled through reports and moderation (F22) |

---

## 21. Notifications & Real-time

### 21.1 Notifications
| Channel | Technology | Use |
|---|---|---|
| Push | **Firebase Cloud Messaging** (Android, iOS, Web Push) | Daily article, replies, mentions, followers, security alerts |
| In-app | SQL `Notifications` table + live unread badge from the **Realtime Database** | Notification center |
| Email (Phase 3) | Transactional provider | Weekly digest, verification results |

- Pushes are sent **only** from outbox handlers and Hangfire jobs (`IPushSender` → `FcmPushSender`, multicast + batching), never inside request handlers.
- Every push also has a `Notifications` row (written first; the push carries its id), and `/live/users/{id}` gets the new unread count.
- Device tokens: registered on sign-in/app start, refreshed when FCM rotates them, deleted on sign out, and removed when FCM reports them as invalid.
- Daily article and streak reminders are scheduled per user's **time zone** via Hangfire.
- Message language = the user's UI language. Aggregation: "أحمد و9 غيره علّقوا على مقالك" instead of 10 pushes.
- Quiet hours respected (default 23:00 – 07:00); security alerts ignore quiet hours.
- Payloads carry a deep link (`readin://a/{slug}#comment-{id}`). Taps open the right screen from terminated, background and foreground states.
- Web: `firebase-messaging-sw.js` + VAPID key, foreground messages as an in-app toast. Mobile: `firebase_messaging` + `flutter_local_notifications`, Android 13+ `POST_NOTIFICATIONS`, iOS APNs.
- Permission is requested **in context** (onboarding reminder step or when enabling a notification type), never on first launch.

**How it is built (F17).** Endpoints, DTOs, types, links and push payloads are in [`docs/api/contract-v1.md`](api/contract-v1.md) ("Notifications").

| Part | Details |
|---|---|
| Tables | `Notifications` (Id, UserId → Users cascade, Type, GroupKey, DedupeKey, ArticleId and CommentId with no cascade, Data JSON, CreatedAt, UpdatedAt = latest activity, SeenAt, ReadAt, PushStatus None/Pending/Sent/Skipped/Failed, PushAfter, PushedAt, PushAttempts); `NotificationActors` (NotificationId cascade + ActorId with no cascade, At); `UserNotificationSettings` (UserId + Type, Mode all/inApp/off; no row = all); `Users.QuietHoursEnabled/Start/End` (default on, 23:00, 07:00). Indexes: unique (UserId, DedupeKey) where set, (UserId, UpdatedAt DESC, Id DESC) for the list, (PushStatus, PushAfter) for pending pushes |
| Writing | Outbox handlers (`UserFollowedDomainEvent`, `CommentChangedDomainEvent`, `ReactionChangedDomainEvent`, `ArticlePublishedDomainEvent`, `ArticleMentionsDomainEvent` (every publish and Update with mentions; the handler checks the article and "who can mention me" again), `UserSecurityChangedDomainEvent`, `ModerationNoticeIssuedDomainEvent`, `VerificationDecidedDomainEvent` (F19)) and jobs (daily article, streak reminder) write through `NotificationWriter`; they never push. Never about your own action; suspended, deleted and system accounts get nothing; `off` writes nothing, `inApp` writes without a push |
| Idempotency | A dedupe key per user (`mention:{commentId}`, `mention:article:{articleId}` (so an Update tells only newly mentioned users), `reactions_milestone:{articleId}:{n}`, `followed_writer_article:{articleId}`, `security_alert:{change}:{event ticks}`, `moderation_notice:{noticeId}`, `verification_result:{requestId}`, `daily_article:{date}`, `streak_reminder:{date}`), and an aggregated entry ignores an actor's activity it already has, so outbox retries change nothing |
| Aggregation | `new_follower` per day, `article_comment` and `article_reposted` (F29) per article, `comment_reply` per thread: new activity joins an unread entry of the group that moved in the last 24 hours (distinct actors, moved to the top, seen/read cleared, push armed again) |
| Push job | `NotificationPushJob` (Hangfire, every minute and right after a write): pending entries that are due, batched, title/body in the user's UI language, collapse key = group or type, quiet hours (the push waits for their end; security alerts ignore them), checked again when sending (mode, content still there, account active), dropped after 24 hours (streak reminder: 4), invalid tokens deleted, other failures retried after 1 and 5 minutes (3 sends) |
| Streak reminder | `StreakReminderJob`, every 5 minutes: from 20:00 to 22:00 in each user's time zone, one per local date, when the streak is ≥ 1 (a pending freeze counts, ADR 0013) and nothing was read today |
| Daily article | The F07 job writes the `daily_article` entry and sends its own push with the entry's id; `inApp` → entry only, `off` → neither; quiet hours hold the push within F07's 2-hour late window |
| Badge | `/live/users/{id}` `{ unreadNotifications, lastNotificationAt }` after every write, seen, read and read-all (seen/read through `UserNotificationsChangedDomainEvent`, so other devices follow); `GET /me/notifications/unread-count` is the same number. Entries whose comment or article is gone drop out of the list and the count |
| Account deletion | §9.6: own entries and settings cascade; actor rows of the account and entries about its deleted articles are deleted explicitly |

### 21.2 Real-time: Firebase Realtime Database
The Realtime Database (RTDB) was chosen over Firestore because Firestore bills every document read, which is expensive for frequently updated live counters.

**Principle: RTDB carries signals, not content.** Comment text, user data and phone numbers never go to RTDB. Clients update counters from RTDB and fetch full data from the REST API.

```text
/live/articles/{articleId}
    reactions: { insightful, love, fire, mindBlown }
    commentCount, saveCount, repostCount, updatedAt
/live/articles/{articleId}/events/{pushId}
    { type: comment.created | comment.updated | comment.deleted
          | reply.created | comment.liked | comment.pinned,
      commentId, parentId?, at }
/live/feed
    latestPublishedAt
/live/users/{userId}
    unreadNotifications, lastNotificationAt
/live/users/{userId}/media/{assetId}
    status, pagesReady, pageCount, failureReason, updatedAt
```

Times are epoch milliseconds; `updatedAt` and `at` are the RTDB server clock.

- **Writes:** only the backend (`IRealtimePublisher` → `FirebaseRealtimePublisher`, the RTDB REST API with the Admin SDK service account, since the .NET Admin SDK has no RTDB client), in outbox handlers **after** the SQL commit, with retry, backoff and a circuit breaker. Counters are PATCHed so `events` is kept. If RTDB is down, the app keeps working through REST.
- **Cleanup:** a Hangfire job keeps events for 24 hours and at most 100 per article. A rebuild command recalculates all counters from SQL Server.
- **Access:** signed-in users get a Firebase **custom token** from `POST /realtime/token` and call `signInWithCustomToken` only to read RTDB (it is not a login method). Guests read public paths without a token. Signing out of ReadIn also signs out of Firebase.
- **Security rules** (`firebase/database.rules.json`): `/live/articles` and `/live/feed` are public read; `/live/users/$uid` is readable only when `auth.uid === $uid`; **no client writes anywhere**; everything else is denied.
- **Lifecycle:** web subscribes in the browser only (never during SSR) and cleans up on destroy; mobile cancels subscriptions in the Bloc's `close()` and pauses listeners in the background. Feed cards subscribe only while visible.

---

## 22. Search

- SQL Server **Full-Text Search** on `ArticleTranslations.SearchText` and `MediaAssets.ExtractedText` (text of attached PDFs), with the Arabic word breaker, which also breaks English words (one indexed column has one word breaker; every query word is a prefix term, so English needs no stemming). A server without full-text uses a normalized `LIKE` fallback, chosen at startup ([ADR 0017](adr/0017-search-full-text-with-like-fallback.md)). People, fields, topics and tags are matched with normalized `LIKE` by both engines. Local development and the integration tests run SQL Server with full-text (`docker/sqlserver`).
- **Documents:** the PDF job extracts each page's text with PdfPig and stores it Arabic-normalized (same rules as below) in `MediaAssets.ExtractedText` (up to 1,000,000 characters). Search results for a document point to the post it is attached to; unattached or unpublished documents are never returned.
- **Arabic normalization** into `SearchText` and on queries: remove diacritics (تشكيل) and tatweel (ـ), unify `أ إ آ → ا`, `ى → ي`, `ة → ه`.
- Ranking: full-text rank × quality score × freshness (the formula is in [`docs/api/contract-v1.md`](api/contract-v1.md), "Search").
- Typo tolerance and "did you mean" in Phase 3 (or move to Azure AI Search / Elasticsearch if needed). As-you-type suggestions (`GET /search/suggest`) ship with F16.

---

## 23. SEO

- Angular **SSR** for public pages: articles, profiles, fields, paths, glossary terms.
- Clean URLs: `/ar/a/{slug}`, `/en/a/{slug}`, `/@{username}`, `/@{username}/c/{slug}`, `/f/{field}`, `/tags/{slug}`, `/paths/{slug}`.
- `hreflang` between `ar` and `en` versions, canonical URLs.
- `schema.org/Article` structured data (author, datePublished, dateModified).
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
  - **Private files** (writer verification proofs, F19) never touch `wwwroot` or the uploads folder: they live in the private store (`Storage:PrivatePath`, `IPrivateFileStorage`, no public URL), and the API refuses to start if that folder overlaps the web root or the uploads folder. PDF, JPEG, PNG or WebP ≤ 10 MB by magic bytes; read only by `GET /admin/verification-requests/{id}/proof` (`verification.manage`, attachment, `no-store`, `nosniff`); deleted once the request is decided.
  - PDF processing runs in background jobs on a dedicated Hangfire `media` queue: at most 2 jobs at a time, a 2-minute timeout per job (`media.processing_timeout`), PDFium calls serialized, and pages rendered at most 200 DPI and 1080 × 4320 px so a crafted page size can't exhaust memory. Encrypted (even owner-password-only) and corrupted PDFs are rejected in the request, before anything is stored.
  - Quotas: 50 uploads per user per rolling day, 200 MB stored per user (`Media:*` settings), `409 media.quota_daily` / `media.quota_storage`.
- **PDF export (F33):** Chromium runs with its sandbox on, JavaScript off and every network request blocked. The API reads fonts, the logo and images from its own disk by asset id and inlines them, so article content can't make the server fetch anything. The response has `Content-Type: application/pdf`, `Content-Disposition: attachment`, `nosniff` and `Cache-Control: private, no-store`.
- **Quote cards (F24):** drawn by the same Chromium under the same rules (sandbox on, JavaScript off, every request blocked, fonts and logo inlined, text HTML-encoded); the quoted text must match the article. `image/png` with `nosniff`, never stored, 30 per hour per user or guest IP.
- **Firebase:** the Realtime Database rules allow no client writes; the service-account key lives only in secrets.
- CORS restricted to app origins (with credentials for the web origin), HTTPS only, HSTS, security headers (CSP, X-Content-Type-Options, Referrer-Policy).
- Secrets in user-secrets (dev) and a secret store (production), never in the repo: `Jwt:SigningKey`, `Security:RecoveryPinPepper`, seed passwords/PIN, the Firebase service-account JSON. `google-services.json` and `GoogleService-Info.plist` are git-ignored.
- **PII:** phone numbers are never in public DTOs and are masked in logs. Passwords, PINs, hashes and tokens are never logged.
- Audit log for admin/moderation actions and security events (password/PIN/phone changes, admin resets, sign out of all devices, account deletion).
- Dependabot + `dotnet list package --vulnerable` + `npm audit` + `flutter pub outdated` in CI.

---

## 25. Performance & Scalability

- Feeds via Dapper with covering indexes, cursor pagination, cached per user for 60s. Feed cards carry only the stored excerpt, and the rest of the text loads when a card is expanded (F34). Long feeds keep only cards near the screen rendered, without losing their state.
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
| UI / Visual | — | Playwright flows and screenshots in `ar/light` and `en/dark` | Golden tests in `ar/light` and `en/dark`; widget tests in ar/en × light/dark |
| E2E | — | Playwright critical flows | `integration_test` critical flows |
| BiDi | RDoc text extraction tests | Mixed-text fixtures | Mixed-text fixtures |
| Post card (F34) | Excerpt rules, `preview` cut at block boundaries and visibility | Expand, react and comment without leaving the feed, scroll position kept, mixed-text excerpts, screenshots in `ar/light` and `en/dark` | The same flows, comment sheet, goldens in `ar/light` and `en/dark` |
| PDF (F33) | Built from `shared/rdoc/` fixtures with every block type, mixed text, emoji, a very long URL, a wide table, long code and a tall image. PdfPig checks embedded fonts, text, links, metadata and no blank pages. Page images are compared with baselines, one Arabic and one English, since the file is always light | Menu item and download flow | Menu item and share sheet |

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
- `docker compose up` → SQL Server with Full-Text Search (host port **14333**, because a local SQL Server already uses 1433; the image is built once from `docker/sqlserver`, for search, F16) + Seq.
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
- **Private files** (verification proofs, F19) are not uploads: they go to `Storage:PrivatePath` (default `App_Data/private` next to the app), which must be **outside** the web root and the uploads folder (the API refuses to start otherwise), survive deployments, be writable by the app's identity and be backed up with the database. On servers, point it outside the app folder. Same single-server limitation (`IPrivateFileStorage`). Details: [`docs/setup/deployment.md` §8](setup/deployment.md#8-private-files-verification-proofs).
- Details, per-tool exclusions (Web Deploy, robocopy/rsync, Docker, IIS, App Service) and a scheduled backup script: [`docs/setup/deployment.md`](setup/deployment.md). Decision, risks and migration path: [ADR 0010](adr/0010-uploads-in-wwwroot.md).

### 28.4 CI/CD (GitHub Actions)
| Workflow | Trigger | Steps |
|---|---|---|
| `backend.yml` | changes in `backend/**` | restore → build → test (Testcontainers) → architecture tests → publish image |
| `web.yml` | changes in `web/**` | install → lint → test → Playwright (ar/light and en/dark) → build SSR |
| `mobile.yml` | changes in `mobile/**` | analyze → test → golden tests → build APK/IPA (release on tags) |
| `content.yml` | changes in `content/**` | RDoc schema validation → code compile checks → link checks |

Deploy targets (suggested): API + SSR on a single server or container host (with the uploads rules in [§28.3](#283-uploads-in-production-wwwrootuploads)), SQL Server, mobile via Play Console / App Store Connect (Fastlane).

The API host and `backend.yml` need Chromium and its system libraries for F33, installed with the image or server setup and never downloaded at runtime. The steps are in [`docs/setup/deployment.md` §10](setup/deployment.md#10-chromium-for-article-pdfs-spec-f33).

---

## 29. Git Workflow & Conventions

- **Branches:** exactly two. `main` (production) and `dev` (all development). No `feature/*`, `fix/*` or `content/*` branches.
- All work is committed **directly to `dev`**, one or more commits per feature. `dev` is pushed after each feature passes its quality gates: backend build + all tests (unit, integration, architecture), web lint + unit tests + SSR build, mobile `flutter analyze` + all tests including goldens, and clean `npm audit` / `dotnet list package --vulnerable`.
- **One folder:** all work happens directly on `dev` in the one working copy (`D:\freelancer\ReadIn`). No new branches or worktrees, also for Claude Code agents (no worktree isolation). The rules for sessions are in [`CLAUDE.md`](../CLAUDE.md).
- **Commit only your own files**, by path: `git commit -m "..." -- <paths>`. Never `git add -A`, `git add .` or `git commit -a`. Never run `git stash`, `git reset`, `git rebase`, `git switch` / `git checkout <branch>` or `git clean` in the shared folder, and never force-push.
- **No pull requests per feature.** There is exactly **one** pull request, `dev → main`, opened only when the product owner asks for a release. Nothing is pushed to `main` directly.
- **Conventional Commits** with scope: `feat(backend): ...`, `feat(web): ...`, `feat(mobile): ...`, `fix(...)`, `test(...)`, `refactor(...)`, `content(dotnet): ...`, `docs: ...`, `chore(ci): ...`.
- Each feature tracks `backend`, `web` and `mobile` parts (see [§12](#12-feature-parity-matrix-web--mobile)); it is done when all three are committed to `dev`.
- Secrets are never committed: the Firebase service-account key, `google-services.json`, `GoogleService-Info.plist`, `Jwt:SigningKey`, `Security:RecoveryPinPepper`, passwords and PINs.
- Architecture decisions recorded as ADRs in `docs/adr/`. Existing: 0001–0016 (`0007-phone-password-authentication.md` supersedes 0001 and the auth part of 0004; `0008-firebase-scope-fcm-and-rtdb.md`; `0009-recovery-pin.md`; `0012-google-and-apple-sign-in.md` amends 0007; `0014-open-topics-and-optional-review.md`, whose review part is superseded by `0015-open-publishing-and-the-editor.md`; `0016-immediate-account-deletion.md` amends 0007 and 0012). The index is `docs/adr/README.md`.

---

## 30. Roadmap

| Phase | Scope |
|---|---|
| **0 — Foundation** | Repo, solution skeleton, CI, design tokens, RDoc schema, Firebase project + emulators, seeders for roles/fields/users |
| **1 — MVP** | F01–F07, F10–F14, F18, F26–F32, F34 · phone + password auth with recovery PIN · all fields open to any topic · 300 seeded articles · Web + Mobile beta |
| **2 — Growth** | F08, F09, F15–F17, F19, F22–F24, F33 |
| **3 — Depth** | F21, F25, email digest, quizzes at the end of articles, text-to-speech, AI translation for user articles |

---

## 31. Definition of Done

A feature is **done** only when:

- [ ] Backend: command/query handlers, validators, Mapster configs, permissions, unit + integration tests.
- [ ] **Web** implemented and tested.
- [ ] **Mobile** implemented and tested.
- [ ] Works in **Arabic (RTL)** and **English (LTR)**, including mixed-text content.
- [ ] Works in **Light** and **Dark** mode in both languages: Playwright flows and screenshots (web) and goldens (mobile) run in `ar/light` and `en/dark`; mobile widget tests run all four combinations.
- [ ] Empty, loading and error states designed and implemented.
- [ ] Accessibility checks pass (contrast, labels, font scaling).
- [ ] Seed data updated so the feature is visible in development.
- [ ] API documented in OpenAPI, ADR added if an architectural decision was made.
- [ ] CI green on all affected workflows.

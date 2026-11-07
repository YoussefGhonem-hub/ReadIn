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

Clients translate `code` (and each validation error code) with their own `ar`/`en` strings, and use `title` only as a fallback. Stable codes: `validation.failed`, `auth.unauthorized`, `auth.forbidden`, `user.suspended`, `user.not_found`, `user.username_taken`, `user.interests.min_three`, `field.not_found`, `topic.not_found`, `article.not_found`, `rate_limited`, `server.error`, plus the auth, social, profile, path, editor, media, notification and verification codes below. Editor: `article.not_found`, `article.not_owner`, `article.draft_conflict`, `article.not_published`, `article.revision_not_found`, `article.status_invalid`, `field.not_found`, `topic.not_in_field`, `article.no_content`, `article.invalid_transition`, `article.slug_taken`, `article.content_language_mismatch`, the validation codes `article.language_invalid`, `article.too_many_tags` and `tag.invalid`, and the problem codes listed with `DraftProblemDto`. Tags: `tag.not_found`, `tag.invalid`, `article.too_many_tags`, `tag.hidden`, `tag.limit` (see Tags). Search: `search.query_invalid`, `search.type_invalid`, `search.filter_invalid` (see Search). Writer categories: `category.not_found`, `category.not_owner`, `category.limit`, `category.name_taken`, `category.name_invalid` (see Writer categories). Profile links and title (pre-production step): the validation codes `link.*` and `profile.headline_*` (see Profile). Reposts (F29): `repost.own_article` and the validation code `repost.caption_too_long` (see Reposts). Highlights (F30): `highlight.text_mismatch`, `highlight.block_not_allowed`, `highlight.too_short`, `highlight.too_long`, `highlight.limit`, `highlight.not_found` (see Highlights). Quote card (F24): `quote.text_mismatch`, `quote.block_not_allowed`, `quote.too_short`, `quote.too_long`, `quote.hidden`, `quote.limit`, `quote.busy`, `quote.failed` (see Quote card). `article.too_many_tags` replaced `article.tags.max_five` in F32; the server no longer sends the old code, and clients may keep translating it.

`403 user.suspended` (every Bearer call of a suspended account, and sign in, refresh and Google/Apple sign in) also carries
`suspendedUntil`: when the suspension ends (ISO UTC), or `null` for a permanent one (F22). Clients show "موقوف لحد {date}" /
"موقوف نهائيًا".

### Roles and permissions (SPEC §10)

An account has one role: `Member` (everyone who signs up) or `SuperAdmin` (the app's owner). `Guest` only means a call
without a token. `GET /me` sends `roles` (`["Member"]` or `["SuperAdmin"]`) and `permissions`. Endpoints check
permissions, never roles, and so do clients: show a screen or an action when `permissions` holds the permission it
needs, and never test a role name (a staff role may be added later with some of these permissions). Where this contract
says "moderators" or "admins", it means whoever holds the permission named, today only the SuperAdmin.

| Permission | Member | SuperAdmin | What it opens |
|---|:-:|:-:|---|
| `articles.read` (Guest too), `articles.create`, `articles.export_pdf`, `comments.create`, `reactions.create`, `reposts.create` (F29, new), `highlights.create` (F30, new), `follows.manage`, `saved.manage`, `reports.create` | ✅ | ✅ | reading, writing, interacting, reporting |
| `moderation.manage` | | ✅ | `/moderation/*` (the queue, the log, the nav badge), hide / unhide / delete in the article, comment and profile menus, the console's Content and Reports |
| `users.suspend` | | ✅ | `suspend` / `unsuspend` in `POST /moderation/actions` |
| `verification.manage` | | ✅ | `/admin/verification-requests/*` and `DELETE /admin/users/{id}/verification` (the admin verification queue) |
| `users.reset_password` | | ✅ | `POST /admin/users/{id}/reset-password` |
| `support.create` (F35, new) | ✅ | ✅ | Help & support: send and follow your own tickets |
| `admin.access`, `users.read`, `support.manage`, `notifications.broadcast`, `audit.read` (F23/F35, new) | | ✅ | the admin console and its sections ("Admin console (F23)" → "Permissions and sections") |
| `users.read.pii`, `articles.feature`, `taxonomy.manage`, `paths.manage`, `system.settings` | | ✅ | the admin console (F23), `/admin/paths`, `/admin/realtime/*` |

**Verified is a badge, not a role.** `isVerified` (on `MeDto`, authors, profiles, people and every user summary) is
`Users.IsVerified`: set when the SuperAdmin approves a verification request, cleared when they remove the badge. It
never changes `roles` or `permissions`.

**Breaking change (2026-11-05):** the `Admin`, `Moderator` and `VerifiedWriter` roles and the `roles.manage` permission
are gone, and there is no role management (`/admin/roles` was never built and won't be). `roles` never holds the old
names; `isVerified` keeps its meaning.

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
**Mobile** sends `X-ReadIn-Client: mobile` on every call: its sessions last 10 years from the last refresh
(`Auth:MobileRefreshTokenLifetime`), the web's and other clients' 30 days. It keeps `refreshToken` in secure storage and
may send `X-Device-Name` (e.g. "Pixel 8"). Tokens rotate: presenting a refresh token that was already used ends the whole
session (a 30-second grace covers parallel tabs), so refresh one call at a time (single-flight) and always keep the
newest token.

**Retrying a lost refresh:** the app stores a random `retryKey` with the refresh token **before** `POST /auth/refresh` and
keeps it until the new token is stored. If the response is lost, send the same `refreshToken` with the same `retryKey`
again. It succeeds as long as the token issued for that refresh was never used: the server issues another one and
retires the unused one. Without the key, with another key, or after the new token was used, it is reuse and ends the
whole session.

### App (mobile) 🌐 — SPEC §8.3

| Method | Path | Response |
|---|---|---|
| GET | `/app/update-policy` | `200 UpdatePolicyDto` (`Cache-Control: no-cache`): the oldest app version each platform still accepts. Older apps block with "Update ReadIn" |

```ts
interface UpdatePolicyDto {
  ios: PlatformUpdatePolicyDto;
  android: PlatformUpdatePolicyDto;
}
interface PlatformUpdatePolicyDto {
  minimumVersion: string | null; // "1.2.0" or "1.2.0+57" (+build: equal versions with a lower build are blocked too); null = none
  storeUrl: string | null;       // the store page; null on iOS until the App Store id is known
}
```

**After sign in**, route by `SessionDto.user` in this order (SPEC §9.2): `mustChangePassword` → change password,
`mustSetRecoveryPin` → set PIN, `!isProfileComplete` → complete profile, `!onboardingCompleted` → onboarding, else home.

### Me (Bearer)

| Method | Path | Body → Response |
|---|---|---|
| GET | `/me` | → `200 MeDto` |
| PATCH | `/me` | `UpdateProfileRequest` → `204`; refetch `GET /me`. `409 user.username_taken`, `400 profile.avatar_invalid`, `400 profile.expertise_invalid`, validation codes as before (`displayName`, `username`, `bio`, `avatarUrl`), and for `headline` and `links` the codes in Profile → "Title and social links" |
| PUT | `/me/privacy` | `{ publicReadingStats?: boolean, whoCanMention?: MentionPolicy }` → `204` (Settings → Privacy, F18; shown in `MeDto.privacy`). Each field is optional (left out = unchanged), so a client that only sends `publicReadingStats` keeps working; clients send the whole privacy object back. `400 validation.failed` with `validation.required` on both fields when neither is sent, `validation.invalid` for an unknown number; an unknown name is a `400` before validation. Nothing changes on an error. `whoCanMention` applies from then on: existing comments keep their mentions |
| DELETE | `/me` | `{ password? , external?: ExternalCredential }` → `204`. Confirm with the password or a fresh token of a linked Google/Apple identity (Apple: include `authorizationCode`). Deletes the account **immediately and for good** (SPEC §9.6): Apple tokens are revoked first, then everything goes in one transaction (published articles stay with `author: null`, shown as "Deleted user"); the phone, email and Google/Apple identities can sign up again at once. **Idempotent:** a retry whose token outlived the account also gets `204`. `400 auth.wrong_password`, `400 auth.confirmation_required`, `400 auth.external_mismatch`, `400 auth.apple_confirmation_required` (Apple-linked account without a revocable token: confirm with Apple), `503 account.deletion_unavailable` (Apple unreachable: nothing was deleted, retry) |
| PUT | `/me/profile/complete` | `{ displayName, username, avatarUrl?, headline? }` → `200 MeDto`. `409 user.username_taken`. `headline` (the optional title, F14) follows the rules of `PATCH /me`: omitted keeps it, `null` or blank clears it |
| PUT | `/me/password` | `{ currentPassword, newPassword }` → `200 SessionDto`; other sessions end. `400 auth.wrong_password` |
| PUT | `/me/phone` | `{ newPhoneNumber, currentPassword }` → `200 SessionDto`; other sessions end. `409 auth.phone_taken`, `400 auth.phone_unchanged` |
| POST | `/me/recovery-pin` | `{ pin }` → `200 MeDto`. Only while `mustSetRecoveryPin` (or without a PIN); `409 auth.pin_already_set` otherwise |
| PUT | `/me/recovery-pin` | `{ currentPassword, newPin }` → `204` |
| POST | `/me/phone-sign-in` | `{ phoneNumber, password, recoveryPin, external: ExternalCredential }` → `200 SessionDto`; other sessions end. Google/Apple-only accounts add phone + password + PIN, confirmed with a linked provider. Same validation codes as `/auth/register`; `409 auth.phone_taken`, `409 auth.phone_sign_in_exists`, `400 auth.external_mismatch` |
| POST | `/me/external-logins` | `{ credential: ExternalCredential, password?, external?: ExternalCredential }` → `200 MeDto`. Links Google/Apple; confirm with the password or a fresh token of an already linked provider. `409 auth.external_in_use` (belongs to another account), `409 auth.external_conflict`, `400 auth.wrong_password`, `400 auth.confirmation_required`, `400 auth.external_mismatch` |
| DELETE | `/me/external-logins/{provider}` | → `200 MeDto`. `400 auth.last_sign_in_method` (it's the only way to sign in), `404 auth.external_login_not_found` |
| PUT | `/me/preferences` | `UpdatePreferencesRequest` → `204`. `showHighlights` (F30) is optional: omitted keeps the current setting |
| PUT | `/me/interests` | `UpdateInterestsRequest` → `204` (at least 3 field ids + topic ids combined) |
| POST | `/me/devices` | `RegisterDeviceRequest` → `204` (FCM token upsert) |
| DELETE | `/me/devices/{token}` | → `204` (idempotent; call on sign out, URL-encode the token) |

A wrong `currentPassword` counts toward the same 15-minute lockout as sign in (`429 auth.locked_out`).

| Method | Path | Auth | Body → Response |
|---|---|---|---|
| GET | `/users/username-available?u=` | 🌐 | → `200 { username, valid, available }` (your own handle counts as available) |
| POST | `/admin/users/{id}/reset-password` | Bearer, `users.reset_password` | → `200 { temporaryPassword }`. "Forgot the PIN too" (ADR 0009): the user must change the password and set a PIN on the next sign in. `403 auth.forbidden` when the account holds a permission the caller doesn't, so only a SuperAdmin resets a SuperAdmin |

### Taxonomy 🌐

| Method | Path | Response |
|---|---|---|
| GET | `/fields` | `FieldDto[]` (enabled fields, ordered) |
| GET | `/fields/{slug}/topics` | `TopicDto[]` |

Field pages (`/fields/{slug}`, `/fields/{slug}/articles`, `/fields/{slug}/writers`): see Explore and field pages (F15).

### Tags (F32) 🌐 (Bearer optional) — SPEC F32

Tags are shared by all writers. A tag has a display `name` (the first spelling anyone used) and a stable `slug`, the
key of its page. Cards and the reader carry `TagRefDto`s: show `#name` with `dir="auto"` and link it to the tag page
(web `/tags/{slug}`, mobile `/tags/:slug`, percent-encoding the slug: it may hold Arabic letters). Clients never build
a slug from a name.

| Method | Path | Response |
|---|---|---|
| GET | `/tags?q=&limit=10` | `TagDto[]`: the editor's suggestions. `q` is cleaned and normalized like a tag name (rules 1 and 3 below, so a leading `#` is dropped). A tag matches when a word of its normalized name starts with `q` (at the start, or after a space, `-`, `_` or `.`), or its slug starts with `q`'s slug (`csharp` finds `C#`). The tag named exactly `q` comes first, then the most used (`articleCount`), then by name. Empty `q`: the most used tags; `q` over 30 characters matches nothing. `limit` 1–20, default 10. Hidden tags are never suggested |
| GET | `/tags/{slug}` | `TagDto`: the tag page's header. `404 tag.not_found` for an unknown or hidden tag |
| GET | `/tags/{slug}/articles?cursor=&limit=` | `CursorPage<ArticleCardDto>`: every published article with the tag, from all writers, newest first, in the caller's article language and with the caller's `myReaction` / `isSaved` / `isFollowingAuthor` like every feed. Articles hidden by moderators (F22) and deleted ones are left out; for a signed-in caller, so are the writers, fields and topics they muted and the articles they marked "show less" (F28). `limit` 1–50, default 20. `404 tag.not_found` like `/tags/{slug}` |

`articleCount` counts the published articles readers can see (not hidden by moderators, not deleted), the same for
everyone; `0` means the tag page shows its empty state (web: `noindex`). The suggestions, the header and the guests'
article pages (server rendering) are cached on the server and refreshed on publish, Update, hide/unhide and delete.

**Tags on articles.** `ArticleCardDto.tags` has the article's first 3 tags and `ArticleDetailsDto.tags` all of them
(≤ 5), as `TagRefDto` in the order the writer gave them; `tagCount` counts them all, for the card's "+N". A hidden tag is
in none of these and not in `tagCount`, but it stays on its articles, so un-hiding it (F23) brings it back.
**Breaking change (F32):** `tags` used to be `string[]` (names).

**Tag names.** The server's rules; clients apply rules 1–3 before adding a chip, with inline messages.
1. **Clean:** remove invisible format characters (Unicode `Cf`: LRM/RLM, bidi isolates, zero-width joiners), trim,
   drop leading `#`s and trim again, turn every run of whitespace into one space, and write Arabic-Indic digits
   (`٠–٩`, `۰–۹`) as `0–9`.
2. **A new tag** needs 2–30 characters after cleaning (UTF-16 code units, i.e. JS / Dart `length`), only letters
   (`\p{L}`), combining marks (`\p{M}`), digits (`\p{Nd}`), spaces and `- _ . + #` (so `C#`, `.NET` and `C++` work),
   and at least one letter or digit (tatweel `ـ` U+0640 is a letter in Unicode but doesn't count here, so `ـــ` is
   refused); otherwise `tag.invalid`. A name that matches an **existing** tag is always
   accepted, even one older than these rules (e.g. `CI/CD`, `Span<T>`): add a picked suggestion as it is, without the
   client check.
3. **Same tag:** two names are one tag when their normalized forms are equal: the cleaned name in lower case with the
   §22 Arabic normalization (remove diacritics U+064B–U+065F, U+0670, U+06D6–U+06ED and tatweel `ـ`; `أ إ آ ٱ → ا`,
   `ى → ي`, `ة → ه`). So `AI`, `ai` and `#AI` are one tag, and it keeps its first spelling as `name`. Clients use this
   to ignore a repeated chip and to know whether a suggestion matches the typed text exactly (else offer
   "إنشاء تاج جديد: {name}" / "Create new tag: {name}").
4. **Slugs** are made by the server when the tag is created and never change: the first spelling in lower case without
   diacritics or tatweel, `#` → `sharp`, `+` → `plus`, a leading `.` → `dot`, every other run of characters that are
   not letters or digits → one `-`, trimmed of `-` (`C#` → `csharp`, `.NET` → `dotnet`, `C++` → `cplusplus`,
   `ASP.NET Core` → `asp-net-core`, `الذكاء الاصطناعي` → `الذكاء-الاصطناعي`); a clash gets `-2`, `-3`, ….

**In the editor** (`ArticleDraftDocument.tags` holds names):
- **Saving** (`POST /articles`, `PUT /articles/{id}/draft`) cleans the names and drops repeats of the same tag (the
  first stays), and creates no tag. `400 validation.failed` when more than 5 remain or more than 50 names are sent
  (`errors["document.tags"]: ["article.too_many_tags"]`; past 50 the names aren't checked one by one) or a name breaks
  rule 2 (`errors["document.tags[i]"]: ["tag.invalid"]`, `i` = its index in the list sent). `document.tags` comes back cleaned.
  A published article's working copy keeps all its tags, hidden ones included.
- **Publish and Update** use the existing tag for each name and create the missing ones (owned by the writer; a system
  tag from the seed content has no owner). Two live checks, reported in `checks.problems` on every save, so publishing
  fails with them like with any other problem (`400` with the first problem's code and `problems`); each problem
  carries the name in `DraftProblemDto.tag`:
  - `tag.hidden`: the name is a hidden tag the published article doesn't already have (keeping one it has is fine);
  - `tag.limit`: the writer would create more than 20 new tags in 24 hours (rolling). The new names past what is left
    of the 20 get it, in document order.

**Renamed and merged tags (F23).** An admin may rename a tag (its slug stays) or merge it into another; the old spelling
and a merged tag's name become aliases. Typing an alias in the editor gives its tag (never `tag.limit`; that tag's hidden
state applies). `GET /tags/{slug}` and `GET /tags/{slug}/articles` answer the target tag for a merged tag's slug, and
`TagDto.slug` is then the target's: replace the URL (the web's server answers `301`). Suggestions and search don't match
aliases. See "Admin console (F23)" → "Taxonomy and tags".

Tag error codes: `tag.not_found` (404), `tag.invalid` and `article.too_many_tags` (validation codes in `errors`),
`tag.hidden` and `tag.limit` (problem codes: in `checks.problems`, and `400` on publish).

### Search (F16) 🌐 (Bearer optional, rate limit `search`) — SPEC F16, §22

| Method | Path | Response |
|---|---|---|
| GET | `/search?q=&type=&field=&lang=&minMinutes=&maxMinutes=&cursor=&limit=20` | One tab of results, best first. `type` = `articles` (the default) → `CursorPage<SearchArticleDto>`, `users` → `CursorPage<UserSummaryDto>`, `topics` → `CursorPage<SearchTopicDto>`, `tags` → `CursorPage<TagDto>`. `field`, `lang`, `minMinutes` and `maxMinutes` filter articles; the other types ignore them. `limit` 1–50, default 20 |
| GET | `/search/suggest?q=` | `SearchSuggestionsDto`: the first 3 results of each type, ranked as in `/search` (no filters, no paging), for the as-you-type dropdown. One request for the rate limit |

**The query.** `q` is cleaned like a tag name (Tags rule 1: invisible format characters dropped, Arabic-Indic digits
→ `0–9`, whitespace runs → one space, trimmed, leading `#`s dropped), then one leading `@` is dropped, then it is
normalized like `SearchText` (§22: Arabic diacritics and tatweel removed, `أ إ آ ٱ → ا`, `ى → ي`, `ة → ه`, lower case).
The cleaned `q` must have 1–100 characters (UTF-16 code units) and at least one letter or digit, else
`400 search.query_invalid`. Clients search as you type from 2 characters and on Enter from 1.

**Matching, for every type.** `q` is split into words at spaces (the first 8 count, the rest are ignored). Every word
must be found at the start of a word (`dock` finds `Docker`); an Arabic word also matches after a leading `ال` (`ذكاء`
finds `الذكاء`). Case, Arabic diacritics, tatweel and letter forms never matter (`مكتبة` = `مكتبه`, `أحمد` = `احمد`).
Quotes, brackets and punctuation around a word (and a full stop after it) are ignored, and a "word" without a letter or
digit doesn't count. There is no query syntax: `OR`, `AND`, `NEAR`, `*`, `%`, `_` and `[` are never operators or
wildcards.

**Articles** (`type=articles`, `SearchArticleDto`)
- Only articles readers can open (as `GET /articles/{slug}`): published, not deleted, in an enabled field and not
  hidden by moderators (F22), not even for their author. For a signed-in caller, muted writers, fields and topics are
  left out too (F28; "show less" marks are not). One result per article.
- Searched: each language version's title + text (`SearchText`), and the text of the post's attached PDF
  (`ExtractedText`, F26). All words must be in one version's title + text, or all in the PDF. A PDF counts only while it
  is attached to an article that can be opened, and once it is processed: unattached PDFs and PDFs of unpublished or
  hidden posts are never searched or returned.
- `matchedIn`: `title` when the served version's title holds every word, else `text` when its title + text do, else
  `attachment` (only the PDF matched: the row says "لقيناها في ملف الـ PDF المرفق" / "Found in the attached PDF").
- Filters: `field` = a field slug (an unknown one gives an empty page). `lang` = `ar-EG` | `en`: only versions in that
  language are searched and served. `minMinutes` / `maxMinutes` (0–600, inclusive): only versions whose reading time is
  in range. The reading-time chips send `maxMinutes=5` ("لحد 5 دقايق" / "Up to 5 min"),
  `minMinutes=6&maxMinutes=10` ("من 5 لـ 10 دقايق" / "5–10 min"), `minMinutes=11` ("أكتر من 10 دقايق" / "Over 10 min").
  A bad `lang`, a value outside 0–600 or `minMinutes > maxMinutes` is `400 search.filter_invalid`; a value that isn't a
  whole number is `400 request.invalid`.
- The card (`article`) is a normal `ArticleCardDto` with the caller's `myReaction` / `isSaved` / `isFollowingAuthor`,
  in a version whose title + text matched, or, when only the PDF matched, any version the filters keep. When more than
  one is left: the caller's article language (guests: `Accept-Language`, `ar` → `ar-EG`), else the source language.
  Clients show it as the **compact row** (F34), not the post card.
- **Ranking:** best `score` first; ties go to the newer `publishedAt`, then the id. An article that matches in several
  places keeps its best score.

  ```
  score     = relevance × quality × freshness
  relevance = place × (0.5 + 0.5 × rank)
    place   = 1.0 title · 0.6 text · 0.4 attachment   (where it matched, as matchedIn)
    rank    = full-text engine: the hit's CONTAINSTABLE RANK ÷ the highest RANK among this query's hits on the same
              column (SearchText for title and text, ExtractedText for attachment), so 0–1
              fallback engine:   1 when the searched text holds the whole cleaned q as one phrase, else 0.5
  quality   = 0.5 + Articles.QualityScore              (the F07 score, 0–1, refreshed hourly) → 0.5–1.5
  freshness = 1 ÷ (1 + days since the first publish ÷ 365)   → 1 when new, 0.5 after a year, 0.33 after two
  ```

**Users** (`type=users`, `UserSummaryDto`)
- People whose display name holds every word, or whose `@username` starts with `q` (for a one-word `q`).
- Left out: deleted accounts, suspended accounts (while suspended), accounts that haven't completed their profile (the
  `@reader_…` placeholder), and writers the caller muted (F28). System accounts (the official `@readin`) are
  found like everyone, and so is the caller (`isFollowing: false`; show no Follow button on your own row).
- Order: an exact `@username` or display name first, then a username or display name that starts with `q`, then the
  rest; within each, verified first, then the most followers, then `@username`. Follow with `PUT /users/{id}/follow`
  (guests get the sign-in prompt).

**Topics** (`type=topics`, `SearchTopicDto`)
- Enabled fields and their topics whose Arabic or English name holds every word, or whose slug starts with `q` made into
  a slug (Tags rule 4, so `C#` finds `csharp`). Fields and topics the caller muted, and the topics of a muted field, are left out (F28).
- Order: an exact name (either language) first, then fields before topics, then the most articles, then the name in
  `Accept-Language`.
- Opens the field page (F15) on web and mobile: `/f/{fieldSlug}` for a field, `/f/{fieldSlug}?topic={topicSlug}` for a
  topic.

**Tags** (`type=tags`, `TagDto`)
- Tags whose name holds every word (a word also starts after `-`, `_` or `.`), or whose slug starts with `q` made into a
  slug (`csharp` finds `C#`). Hidden tags never appear, and neither do tags without a visible article
  (`articleCount: 0`).
- Order: the tag named exactly `q` first, then the most used (`articleCount`), then the name. Opens the tag page (F32).

**Paging.** `cursor` is opaque: pass back `nextCursor` with the same `q`, `type` and filters (a cursor that doesn't decode
starts from the first page). A query returns at most 200 results, then `nextCursor` is `null`. Results can shift
between pages while articles are published or counters change, so drop an id you already show. Guests' results may be
cached for up to 2 minutes; signed-in callers always get their own state.

**Engines** ([ADR 0017](../adr/0017-search-full-text-with-like-fallback.md)). Article text and PDF text are searched
with SQL Server Full-Text Search when the server has it installed (full-text indexes on
`ArticleTranslations(SearchText)` and `MediaAssets(ExtractedText)`, Arabic word breaker), and otherwise with a fallback
that runs `LIKE` over the same normalized text (with `%`, `_` and `[` escaped). The engine is chosen once at startup.
Both follow the rules above; the fallback may also match inside a word (`net` finds `internet`), and its `rank` is the
phrase rule. Full-text indexing is asynchronous: a new or updated article is found a few seconds after it is published.
People, topics and tags are small tables whose names aren't stored normalized, so both engines match them the same
way (§22 normalization on both sides, escaped `LIKE` at word starts).

**Rate limit `search`:** 60 requests a minute per signed-in user, or per IP for guests, `/search` and `/search/suggest`
together; then `429 rate_limited`. Clients wait 300 ms after the last keystroke before searching.

Search error codes: `search.query_invalid` (400), `search.type_invalid` (400: `type` isn't one of the four),
`search.filter_invalid` (400), plus `request.invalid` and `rate_limited`.

### Explore and field pages (F15) 🌐 (Bearer optional) — SPEC F15

| Method | Path | Response |
|---|---|---|
| GET | `/explore` | `ExploreDto`: every section of the Explore page (web `/explore`, mobile Explore tab) in one call |
| GET | `/explore/trending?cursor=&limit=` | `CursorPage<ArticleCardDto>`: "Trending this week" in full ("عرض الكل" / "See all"), best first |
| GET | `/explore/most-saved?cursor=&limit=` | `CursorPage<ArticleCardDto>`: "Most saved" in full, best first |
| GET | `/fields/{slug}` | `FieldPageDto`: the field page's header and topic chips |
| GET | `/fields/{slug}/articles?topic=&cursor=&limit=` | `CursorPage<ArticleCardDto>`: the field's articles, newest first. `topic` = a topic slug of this field (empty: the whole field). `404 topic.not_found` for a `topic` that isn't one of this field's |
| GET | `/fields/{slug}/writers?limit=` | `UserSummaryDto[]`: "Top writers in this field", best first. `limit` 1–10, default 10 |

`{slug}` and `topic` are matched ignoring case. An unknown or disabled field is `404 field.not_found` on all three
`/fields/{slug}` endpoints.

**Article lists.** Every list here (Explore sections, the two rankings, field articles) holds only articles readers can
open (as `GET /articles/{slug}`: published, not deleted, in an enabled field, not hidden by moderators, F22), one card
per article, in the caller's article language (guests: `Accept-Language`, `ar` → `ar-EG`; else the source language),
with the caller's `myReaction` / `isSaved` / `isFollowingAuthor` like every feed. Clients show the two rankings ("See
all") and the field articles as the **post card** (F34); Explore's `trending` / `mostSaved` previews show their first 3
as the compact article row, with "See all" next to the section title. For a signed-in caller, muted writers, fields and
topics, and articles marked "show less", are left out too (F28; a field page keeps its own field and the picked topic). `limit` 1–50, default 20; a cursor that doesn't decode starts from the
first page.

**Explore (`ExploreDto`).** A section with nothing in it is `[]`; clients hide it.
- `fields`: every enabled field in display order (as `GET /fields`), empty ones included, with `articleCount` (articles
  readers can see, the same for everyone). Opens the field page; topics are reached there. Fields the caller muted are
  left out (F28).
- `trending`: the first 6 of `/explore/trending`. `mostSaved`: the first 6 of `/explore/most-saved`.
- `newWriters`: ≤ 10 people whose first article was published in the last 30 days, latest first publish first (the
  first article = the earliest `publishedAt` among their articles readers can see). Left out: system accounts (the
  official `@readin`), suspended accounts (while suspended), deleted accounts, profiles not completed (the
  `@reader_…` placeholder), and writers the caller muted (F28). The caller can be listed (`isFollowing:
  false`; show no Follow button on your own row). Follow with `PUT /users/{id}/follow` (guests get the sign-in prompt).
- `featuredPaths`: ≤ 6 published paths flagged featured (`LearningPaths.IsFeatured`), in featured order
  (`FeaturedOrder`, then the editorial order), as `PathCardDto` like `/paths` (a path with no article a reader can open
  is left out; `progress` / `enrollment` for a signed-in caller). Editorial paths start featured, in their sort order;
  F23 manages the flag and the order (`PUT /admin/paths/featured`). Opens `/paths/{slug}`.
- `featuredArticles` (F23): ≤ 6 articles readers can open that an admin featured (`articles.feature`), the most recently
  featured first, as `ArticleCardDto`s (the viewer's mutes apply). `[]` when none: clients hide the section. Clients show
  them as the compact article row under the title «مقالات مختارة» / "Featured articles".

**Trending this week** (`/explore/trending`)

```
engagement = 1 × completed reads + 2 × reactions + 4 × comments + 6 × saves      (in the last 7 days, rolling)
order      = engagement DESC, QualityScore DESC, publishedAt DESC, id DESC
```
- Completed reads: `ReadingProgress.completedAt` in the window (the F04 "read", once per reader). Reactions: the ones
  whose current type was chosen in the window (`reactedAt`). Comments: comments and replies written in the window that
  are still visible (not deleted, not hidden). Saves: articles still saved, saved in the window.
- Activity by the article's own author doesn't count.
- The weights are the quality score's interaction weights (reaction 1, comment 2, save 3; F07) doubled, plus 1 for a
  completed read, so a read counts half a reaction.
- **Fallback:** articles without engagement this week follow in quality-score order (F07, refreshed hourly), so a quiet
  week shows the quality ranking.

**Most saved** (`/explore/most-saved`)

```
order = saves in the last 30 days DESC, saveCount DESC, publishedAt DESC, id DESC
```
- Saves in the last 30 days: articles still saved, saved in the window, not by the article's author. **Fallback:**
  all-time saves (`saveCount`, the card's number). Articles nobody saved (`saveCount: 0`) are left out.

**Paging the rankings.** Each ranking holds at most 100 articles; then `nextCursor` is `null`. The cursor is a position
(as in Search), and rankings move while people read, so drop an id you already show.

**Field page (`FieldPageDto`).** Web `/f/{slug}` (`?topic={topicSlug}` selects a chip, the link Search gives topics),
mobile `/f/:slug`, deep links `readin://f/{slug}` and `https://{host}/f/{slug}`.
- `articleCount`: articles readers can see in the field (the same for everyone); `0` → the empty state (web:
  `noindex`). `isSensitive`: show the health disclaimer note.
- `followerCount`: people who follow the field itself (a followed topic doesn't count). `isFollowing`: the caller does
  (`false` for guests).
- Follow / Unfollow with `PUT` / `DELETE /me/interests/fields/{id}` (the F12 interests endpoints, `InterestsDto`):
  clients flip `isFollowing` and move `followerCount` by 1 themselves. `400 user.interests.min_three` when fewer than 3
  interests would remain: keep the toggle on and show the message. Guests get the sign-in prompt.
- `topics`: every topic of the field in editorial order, empty ones included (a topic can be followed before it has
  articles), each with `articleCount` and `isFollowing` (follow with `PUT` / `DELETE /me/interests/topics/{id}`).

**Field articles** (`/fields/{slug}/articles`): newest first (`publishedAt` DESC, id DESC), keyset cursor, so paging
never repeats or skips an article.

**Top writers** (`/fields/{slug}/writers`)

```
score = 1 × completed reads + 2 × reactions     (on their articles in this field, in the last 90 days, not their own)
order = score DESC, their articles readers can see in this field DESC, followers DESC, username ASC
```
- Writers with at least one article readers can see in the field; those without activity in the window follow in the
  fallback order. Left out like `newWriters`: system accounts, suspended, deleted and not completed profiles, and (F28)
  writers the caller muted. The caller can be listed (`isFollowing: false`).

**Caching.** `/explore`, the two rankings, the field header and top writers are cached on the server for up to 5
minutes, shared by everyone with the same UI language and article language, and dropped on publish, Update,
hide/unhide and delete. Guests' field article pages are cached like tag pages. What belongs to the caller
(`myReaction`, `isSaved`, `isFollowingAuthor`, `isFollowing`, `followsYou`, a path's `progress` / `enrollment`) is
filled per caller after the cache, never cached. The people in `newWriters` and the top writers are checked on every
request too, so a writer suspended (or whose account is deleted) leaves both lists at once. Counts can lag up to 5
minutes; live counters (F27) refresh visible cards.

Explore error codes: `field.not_found` (404), `topic.not_found` (404).

### Articles & Feed 🌐 (Bearer optional)

| Method | Path | Response |
|---|---|---|
| GET | `/articles/{slug}?lang=` | `ArticleDetailsDto` |
| GET | `/feed/for-you?field=&cursor=&limit=` | `CursorPage<ArticleCardDto>`. Signed in: the articles in the user's interests first, then all the other published articles; guests, users without interests, and any `field` filter: one group of all published articles. Within each group the articles are **ranked by freshness + popularity, with priority for verified writers** (see "For you ranking" below; the cursor remembers the group and a snapshot time, so paging never repeats or skips an article). Signed in, what you muted or marked "show less" is left out, and the topics (or fields) you marked "show less" in the last 90 days come last, in a tier of their own (F28, see Mute & feedback). `field` is a field slug. |
| GET | `/feed/today` | `ArticleCardDto` or `204` when no pick is available yet |
| GET | `/feed/following?cursor=&limit=` | Bearer → `CursorPage<ArticleCardDto>`: the Home "Following" tab. Published articles by the writers you follow **and articles they reposted** (F29), each once, newest placement first, without your muted writers, fields and topics and "show less" articles (F28). A card a repost placed carries `repostedBy` (the label "أعاد نشره {name}"). Rules in Reposts → "The Following feed" |
| GET | `/articles/{id}/related?lang=&limit=` | `ArticleCardDto[]`, 0–`limit` cards (1–10, default 4) for the end of the reader (F04). `lang` is the version being read; cards use it when they have it, else their source language. `404 article.not_found` when the article isn't published |
| GET | `/articles/{id}/preview?lang=` | `ArticlePreviewDto`: what a feed card's "Read more" shows (F34). `content` is an RDoc document with the article's first whole blocks, in order, until about 300 words of text (the block that reaches 300 is kept whole, so there is always at least one block, and a cut preview never ends on a heading or divider); `isComplete` is true when that is the whole article. `lang` picks the version like `GET /articles/{slug}` (an unknown or missing version gives the source language; `language` says which). Visible exactly like the article: `404 article.not_found` for unknown, unpublished and deleted articles, and for a hidden one to everyone but its author and moderators. Cached like the details and invalidated with them (publish, Update, hide/unhide, delete) |

Every card (feeds, today, field lists, profile articles, related, saved, continue reading, paths) carries the article's
counters (`repostCount` too, F29), the post-card fields (F34: `excerpt`, `hasMore`, `tags`, `tagCount`) and, for a
signed-in caller, their own `myReaction` / `isSaved` / `isFollowingAuthor` / `isReposted` (`null` / `false` / `false` /
`false` for guests; `isFollowingAuthor` is also `false` on your own articles and for a deleted author). The author's
`headline` (the writer's title, F14) is on `author`. `repostedBy` (F29) is set only on Following-feed cards a repost
placed and on a profile's Reposts tab; it is `null` everywhere else, `ArticleDetailsDto` included. `ArticleDetailsDto` adds `collectionIds`, your collections that
hold the article (`[]` for guests and unsaved articles), so "add to collection" can show its ticks, and `category`, the
writer's category of the article (F31, `{ slug, name }` or `null`; see Writer categories).

**Post-card text (F34).** `excerpt` is the served version's beginning as plain text: at most 400 characters cut at a
word (no "…" stored: clients add "… Read more"), taken in document order from the summary, paragraphs, list items,
steps (title, then text), quotes and callouts (title, then text), one line each joined by `\n` (a hard break inside a
block is a `\n` too); glossary terms and mentions give their text; marks are dropped. Headings, code, tables, images,
embeds and a quote's cite are skipped. `hasMore` is `false` only when `excerpt` is the whole article (so a card needs no
"Read more" unless its text runs past 4 lines); cut text, later blocks or anything skipped make it `true`. `excerpt` is
`null` only for a version published before F34 that the backfill job hasn't reached yet (clients show the title only),
and then `hasMore` is `true`. An article whose blocks give no text has `excerpt: ""` and `hasMore: true`.

**Related articles (F04).** Ranked by what they share with the article: the same topic first, then the same field,
then tags and glossary terms in common; ties go to the higher quality score, then the newest. Never included: the
article itself and its direct neighbours in a learning path (the "Next in path" block shows those). For a signed-in
caller, their own articles are left out and articles they have already read come last.
An article **hidden by a moderator** (F22) is left out of every list, feed, count and today's pick. `GET /articles/{slug}`
and what is done on it (comments, replies, likes, pins, reactions, saves, progress) answer `404 article.not_found` to
everyone but its author and moderators; they get it with `moderation: { hiddenAt, note }` (the latest hide's note) for the
"Hidden by moderators" banner. `moderation` is `null` otherwise.

**For you ranking (leftovers step, SPEC F03 and §10.1, [ADR 0020](../adr/0020-for-you-ranking-and-snapshot-cursor.md)).**
The groups stay as they are (your interests, then everything else, then what you marked "show less"; one group for
guests, users without interests and a `field` filter). Inside each group the articles are ordered by an effective time,
highest first, then the later `publishedAt`, then the id:

```text
rank = publishedAt + 4 days × popularity + 1 day × verified          (whole seconds)
popularity = 1 − 1 / (1 + E / 20)                                       (0 … < 1; E = 20 gives 0.5)
E = completed reads × 1 + reactions × 2 + comments × 4 + saves × 6 + reposts × 6
```

- `E` counts other people's activity only (never the author's own) in the **30 days before the snapshot time**; hidden
  and deleted comments don't count. So engagement moves an article up by at most 4 days of freshness, and an old
  article sinks however popular it once was.
- `verified` is 1 when the author has the Verified badge (`isVerified`, SPEC §10.1 "the badge also gives priority in
  feeds") and got it before the snapshot time; 0 otherwise (also for a deleted author). A verified writer's article
  ranks as if it were a day newer. The badge counts the same way in every group.
- **Stable pages.** The first page (no cursor) takes the current time as the snapshot; `nextCursor` carries that
  snapshot, and every later page ranks against it: activity after it isn't counted, articles published after it don't
  show (the "مقالات جديدة ↑" banner and a refresh bring them), and a badge given after it doesn't count. Scores only
  use what existed at the snapshot, so they don't move while you page: nothing is skipped. An article whose score
  dropped since (someone took back a reaction, a save or a comment) may come again further down; clients already drop
  the ids they show (as for the "show less" Undo). The one exception is a moderator **un-hiding** a comment or an
  article during a scroll: visibility is read when each page is asked for, so that article can rise above the cursor
  (or come back above it) and be missed for the rest of that scroll. It is in the next first page.
- **Cursors from before this change** (they carry the group and a publish time) still work: that scroll finishes in the
  old order (newest first within each group, old-style cursors), and the next first page is ranked. Cursors stay
  opaque; clients change nothing.
- The Following feed stays chronological (newest placement first). Today's article (F07) keeps the quality score
  first; between equal scores a verified writer's article wins, then the newest.

### Reactions (F10; writes: Bearer, permission `reactions.create`, rate limit `writes`)

| Method | Path | Body → Response |
|---|---|---|
| PUT | `/articles/{id}/reaction` | `{ type: ReactionType }` → `200 ArticleReactionsDto`. Sets or changes your one reaction per article. `400` validation code `reaction.invalid` (in `errors.type`), `404 article.not_found` (also for drafts, archived, deleted or other unpublished articles) |
| DELETE | `/articles/{id}/reaction` | → `200 ArticleReactionsDto` (idempotent) |
| GET | `/articles/{id}/reactions?type=&cursor=&limit=` | 🌐 → `CursorPage<ReactorDto>` ("who reacted"), newest first; `type` keeps one reaction (`reaction.invalid` otherwise) |

The `ArticleReactionsDto` of a write is counted from the rows right after your change. Counters on cards and details
come from the article's denormalized columns, which the outbox updates right after the commit (see Live counters).

### Reposts (F29) — SPEC F29

Writes: Bearer, permission **`reposts.create`** (every member, SPEC §10.2; new in `GET /me` `permissions`), rate limit
`writes` (30 a minute). Guests get `401 auth.unauthorized`: clients show the sign-in prompt instead of calling.

| Method | Path | Body → Response |
|---|---|---|
| PUT | `/articles/{id}/repost` | `RepostRequest` (optional body) → `200 RepostStateDto`. Reposts, or, when you already reposted it, only sets the caption (the repost keeps its first time, the count doesn't move and no new notification goes out). No body, or a missing or `null` `caption`, means no caption on a new repost and the caption unchanged on an existing one; a string sets it, and an empty one clears it. `400 repost.own_article` (your own article), `400 validation.failed` with `caption: ["repost.caption_too_long"]` (more than 500 characters after trimming), `404 article.not_found` (unknown, unpublished, deleted; a hidden article for anyone but its author and moderators, as `GET /articles/{slug}`) |
| GET | `/articles/{id}/repost` | Bearer → `200 RepostStateDto`: your repost of it now, with its caption (prefills "Edit your thoughts"). `404 article.not_found` as above |
| DELETE | `/articles/{id}/repost` | → `200 RepostStateDto` (idempotent; on your own article it answers `isReposted: false`). The caption goes with the repost. `404 article.not_found` as above |
| GET | `/users/{username}/reposts?cursor=&limit=` | 🌐 (Bearer optional) → `CursorPage<ArticleCardDto>`: the profile's **Reposts** tab, newest repost first. Each card's `repostedBy` is this user (`othersCount: 0`, `repostedAt` = their repost). Articles readers can't open (hidden, deleted, unpublished) are left out. Like the other profile tabs it keeps what the caller muted (cards carry `isAuthorMuted`). `limit` 1–50, default 20. `404 user.not_found` (unknown, deleted or suspended, as in Profile) |

`RepostStateDto` is `{ repostCount, isReposted, caption }`, counted from the rows right after your change; `caption`
is your repost's caption (`null` when it has none or you haven't reposted). One repost per user per article (unique
`Reposts(UserId, ArticleId)`); a repost keeps its first time.

**Caption.** `Reposts.Caption` is optional plain text: trimmed, an empty or all-space caption is stored as `null`, at
most 500 characters after trimming, line breaks kept (`\r\n` and a lone `\r` become `\n`). A too-long caption is
rejected (`validation.failed`) before the article is looked up, so it wins over `404` and `repost.own_article`.
`GET /articles/{id}/repost` needs only a token (no permission, no rate limit). It is not RDoc: no mentions, links or
formatting. Clients render it as plain text (`white-space: pre-line`, direction from its first strong character) and
never as HTML.
- `RepostLabelDto.caption` carries the caption of the label's `user`:
  - on the Following feed, the newest followed reposter's caption (the others' captions aren't shown);
  - on the Reposts tab, the profile owner's caption.
- Clients show the caption under the label line and above the card's own header (LinkedIn's "repost with your
  thoughts").
- The `article_reposted` notification doesn't carry it.

Cards and details carry `repostCount` (the denormalized `Articles.RepostCount`, recomputed by the outbox right after
the commit) and the caller's `isReposted`.

**Clients.** The Repost icon sits between Comment and Share on the post card's action bar and next to comments in the
reader's bar, with its count beside it (no number at 0); accessible name "إعادة نشر، 3" / "Repost, 3" (with the count
when > 0).

A tap opens a small menu:
- **Not reposted yet:**
  - "أعد النشر" / "Repost" reposts at once, optimistically (`PUT` with no body); on a failure it rolls back and shows
    the error.
  - "أعد النشر مع رأيك" / "Repost with your thoughts" opens the caption dialog.
- **Reposted:**
  - "عدّل رأيك" / "Edit your thoughts" opens the dialog prefilled from `GET /articles/{id}/repost`.
  - "إلغاء إعادة النشر" / "Undo repost" sends `DELETE`, optimistically.

**The caption dialog:**
- The title "أعد نشر المقال" / "Repost this article".
- A compact preview of the article: title and author.
- A multi-line field (placeholder "قول رأيك في المقال… (اختياري)" / "Add your thoughts… (optional)").
- A counter "n/500", turning red over the limit.
- "انشر" / "Repost", or "احفظ" / "Save" when editing, plus "إلغاء" / "Cancel".
- Submitting sends `PUT` with `{ caption }`. The dialog stays open on an error and shows it. On your own
article (`author.id` = your id) the button is disabled with the hint "مينفعش تعيد نشر مقالك" / "You can't repost your
own article" (the API answers `repost.own_article` anyway). Live `repostCount` replaces the number (see Live counters).

**The Following feed** (`GET /feed/following`):
- Items are the published articles you can open that were written **or reposted** by writers you follow. Each article
  appears **once**.
- Its place (`feedAt`) is the **later** of: its publish time, when you follow its author; and the newest repost by a writer
  you follow. Order: `feedAt` newest first, then id. The cursor encodes `(feedAt, id)`, so paging never repeats or skips
  an item while nothing changes.
- **Label.** When a repost placed the item (the author isn't followed, or the newest followed repost is later than the
  publish), the card's `repostedBy` is `{ user, othersCount, repostedAt }`: `user` = the newest followed reposter,
  `othersCount` = the other writers you follow who reposted it. Clients show "أعاد نشره {name}" / "{name} reposted
  this", or with `othersCount > 0` "{name} و{n} غيره أعادوا نشره" / "{name} and {n} others reposted this"
  (`n` = `othersCount`; Arabic "{name} وشخص تاني أعادوا نشره" when `n` = 1). `{name}` links to `/@{user.username}`.
  Otherwise `repostedBy` is `null` and the card is the author's own post, as before.
- So an article you already got from a writer you follow isn't repeated: a later repost by someone you follow moves
  that one item up, labeled.
- Never in your Following feed: your own articles (you hear about reposts through the notification), articles by
  writers you muted, in fields or topics you muted, or marked "show less" (F28). A writer you follow is never muted
  (muting ends the follow), so a muted writer's reposts never place anything.
- Hidden, deleted and unpublished articles drop out. A repost by an account that is deleted goes with it.
- Things that move while you scroll: a new repost moves an item to the top, so if it was further down it now appears on
  the next refresh, not in the next page; an undone repost can move an item down into a later page. As with For you,
  drop ids you already show.

**Notification `article_reposted`** (F17; SPEC F29 calls it `article.reposted`). To the article's author when someone
reposts it, aggregated per article like `article_comment` (group `article_reposted:{articleId}`: new reposters join an
unread entry that moved in the last 24 hours). Undoing and reposting again is not news. It respects the type's mode
(configurable: `all` / `inApp` / `off`), quiet hours and mutes (a writer you muted tells you nothing). Nobody hears about
their own action (you can't repost your own article anyway); suspended, deleted and system accounts get nothing; nothing
for a hidden or deleted article. Undoing a repost leaves the entry. See Notifications and Push payloads for texts and the
link.

**Account deletion (SPEC §9.6).** The account's reposts are deleted with it (cascade), and the `repostCount` of the
articles it had reposted is recomputed right after (and republished live). Reposts of its deleted articles go with those
articles; other people's reposts of its kept published articles stay. It disappears as an actor of `article_reposted`
entries like any deleted actor.

Repost error codes: `repost.own_article` (400) and the validation code `repost.caption_too_long`:

| Code | Arabic | English |
|---|---|---|
| `400 repost.own_article` | "مينفعش تعيد نشر مقالك." | "You can't repost your own article." |
| `repost.caption_too_long` (in `validation.failed` → `caption`) | "رأيك لازم يكون 500 حرف أو أقل." | "Your thoughts must be 500 characters or fewer." |

### Highlights (F30) — SPEC F30

Readers mark text in an article; everyone sees the ranges many readers marked. Reading is 🌐 (Bearer optional). Writes:
Bearer, permission **`highlights.create`** (every member, new in `GET /me` `permissions`), rate limit `writes` (30 a
minute). Guests get `401 auth.unauthorized`: clients show the sign-in prompt instead of calling.

| Method | Path | Body → Response |
|---|---|---|
| GET | `/articles/{id}/highlights?lang=` | 🌐 → `200 ArticleHighlightsDto`. `lang` picks the version like `GET /articles/{slug}` (unknown or missing → the source language; `language` says which). `mine`: your highlights on that version in document order (`[]` for guests). `popular`: at most 5, most marked first. `404 article.not_found` for unknown, unpublished and deleted articles, and for a hidden one to everyone but its author and moderators |
| POST | `/articles/{id}/highlights` | `CreateHighlightRequest` → `201 HighlightCreatedDto` (made a highlight, maybe joining some of yours), or `200 HighlightCreatedDto` when the range is already inside one of yours (nothing changed, `replacedIds: []`). Checks and errors below |
| DELETE | `/highlights/{id}` | → `204`. `404 highlight.not_found` when it isn't one of yours (someone else's answers the same) or is already gone: treat it as removed |
| GET | `/me/highlights?cursor=&limit=` | Bearer → `CursorPage<HighlightGroupDto>`: the profile's Saved tab, **Highlights** section (F14). `limit` 1–50 groups, default 20. Rules below |

**Offsets** (fixtures: [`shared/rdoc/highlight-fixtures.json`](../../shared/rdoc/highlight-fixtures.json); the
backend's extraction and both clients' selection mapping are tested against it):
- `startOffset` (inclusive) and `endOffset` (exclusive) count **UTF-16 code units** (JavaScript and Dart `String`
  indexes) in the block's **plain text**, and `text` is exactly `plainText.slice(startOffset, endOffset)`. Nothing is
  normalized (no NFC, no Arabic normalization).
- A block's plain text is its inline nodes in order: `text`, `term` and `mention` give their `text` (a mention gives
  its `@username` text), `hardBreak` gives `"\n"`; marks add nothing. A list's plain text is its items' texts joined by
  one `"\n"`, and each item is its own unit: a highlight never crosses from one item into another. A callout's title, a
  quote's cite, the summary's label and list bullets or numbers are never part of the plain text.
- Highlightable blocks: `paragraph`, `heading`, `bulletList` / `orderedList` items, `quote`, `callout`, `summary`.
  Never `code`, `codeTabs`, `table`, `steps`, `image`, `divider`, `embed`.
- Isolate and embedding characters a renderer inserts (U+2066–U+2069 and U+202A–U+202E: Flutter's isolates, any
  `<bdi>` text) never count. Stored content never holds them (the server strips them on save), so a renderer that
  inserts them subtracts them when mapping a selection.
- **Selection → range** (clients): order the two ends; take the block (list: the item) where the selection starts; if
  that block can't be highlighted, show no toolbar; clip the end to the end of that block's (item's) text; trim
  whitespace at both ends (U+0009–U+000D, U+0020, U+0085, U+00A0, U+1680, U+2000–U+200A, U+2028, U+2029, U+202F,
  U+205F, U+3000); fewer than 3 code units left → no **Highlight** button; more than 1,000 → show `highlight.too_long`
  without calling. A selection that starts in a callout's title starts at the callout's text.

**Creating** (`POST`), checked in this order:
1. A malformed body is `400 validation.failed`: `language` (`validation.required`, `article.language_invalid`),
   `blockId` (`validation.required`, `validation.invalid` when it isn't `^[A-Za-z0-9_-]{1,64}$`), `startOffset` and
   `endOffset` (`validation.required`, `validation.invalid` for a negative offset or `endOffset ≤ startOffset`), `text`
   (`validation.required`).
2. `404 article.not_found`, as `GET`.
3. `400 highlight.text_mismatch` when the article has no `language` version or the block isn't in it;
   `400 highlight.block_not_allowed` when the block is a code, code tabs, table, steps, image, divider or embed block
   (whatever the offsets and text).
4. `400 highlight.text_mismatch`: an offset falls past the block's text or inside a surrogate pair, the range crosses a
   list item, or `text` isn't exactly the text at those offsets. Usually the author updated the article meanwhile: reload
   the article and its highlights. (A `text` holding half a surrogate pair isn't valid JSON text and is refused before
   these checks with a `400`.)
5. Whitespace at both ends is trimmed, as above (the stored range is the trimmed one). `400 highlight.too_short` below
   3 code units, `400 highlight.too_long` above 1,000.
6. **Joining:** your highlights in the same version and block that overlap or touch the range become one highlight
   covering them all (`text` from the block; `400 highlight.too_long` if that is over 1,000). `replacedIds` lists the
   ones it replaced (deleted); `highlight` is the new one (`createdAt` now). So your highlights in a block never overlap,
   and selecting inside one of yours offers **Remove** (`DELETE` it). A range already inside one of yours changes
   nothing: `200` with that highlight.
7. `400 highlight.limit`: more than 100 of your highlights on this article (both versions together; joined ones count
   once).

**When the author updates the article.** A highlight belongs to the published text of its version. After an Update, a
highlight whose `text` is no longer at its offsets (its block changed, was removed, or became a type that can't be
highlighted) is not returned anywhere (`mine`, `popular`, `/me/highlights`) and doesn't count toward popular ranges or
the limit; it is deleted the next time you highlight in that version. Nobody is told. `ar-EG` highlights show only on
the `ar-EG` version and `en` ones only on `en`.

**Popular.** A range (the same block, offsets and text, in that version) marked by **at least 3 readers**. For a
signed-in viewer, writers they muted (F28) don't count; guests count everyone. At most 5, most marked first, then in
document order. `count` includes the viewer when they marked it too, so `popular` and `mine` can hold the same range:
draw it as yours; tapping it still shows the count. Who marked what is never sent to anyone. The server caches each
version's block texts and popular ranges once for all readers (dropped on publish, Update, hide, delete and on every
highlight change); `mine` and the mute adjustment are read per request, never cached.

**Saved → Highlights** (`GET /me/highlights`). One group per article **version** you highlighted (`article.language`),
holding all your highlights on it, newest first. Groups are ordered by `latestAt`, newest first, then by article id and
language; the cursor encodes that, so paging never repeats or skips a group while nothing changes (a new highlight
moves its group to the top: drop groups you already show). `latestAt` is the time of your newest highlight on that
version, also when an Update hid it (it then isn't listed, so `latestAt` can be newer than every highlight shown). Left out: articles you can no
longer open (hidden, deleted, unpublished), highlights an Update hid, and groups with nothing left. Mutes don't apply
(as in Saved). `article.title` is that version's title, `author` is `null` for a deleted account. Tapping a highlight
opens the article in that language scrolled to `blockId`, like a block link.

**Hide highlights** (`showHighlights`, F18). `MeDto.showHighlights` (default `true`); `PUT /me/preferences` takes
`showHighlights?: boolean` (omitted keeps it; send the other preferences as they are in `MeDto`). The reader's "⋯" item
"إخفاء الـ Highlights" / "Hide highlights" ("إظهار الـ Highlights" / "Show highlights" while hidden), `Ctrl + /` on web
and the Settings toggle flip it: optimistic, rolled back on failure. While hidden, no mark (yours or popular) is drawn
and selecting text shows no Highlight toolbar; clients may skip `GET` until shown again. Guests can use the menu item
and the shortcut too: their choice stays on the device (no sign-in prompt).

**Account deletion (SPEC §9.6).** The account's highlights are deleted with it (cascade) and leave the popular counts at
once (the cached copies are dropped). Highlights on its deleted articles go with those articles; other people's
highlights on its kept articles stay.

Highlight error codes:

| Code | Arabic | English |
|---|---|---|
| `400 highlight.text_mismatch` | "النص ده اتغيّر في المقال. حدّث الصفحة وجرّب تاني." | "This text has changed in the article. Reload and try again." |
| `400 highlight.block_not_allowed` | "مينفعش تعمل Highlight للجزء ده." | "This part can't be highlighted." |
| `400 highlight.too_short` | "اختار 3 حروف على الأقل." | "Select at least 3 characters." |
| `400 highlight.too_long` | "الـ Highlight لازم يكون 1000 حرف أو أقل." | "A highlight can be at most 1,000 characters." |
| `400 highlight.limit` | "وصلت لأقصى عدد Highlights في المقال ده (100)." | "You can have at most 100 highlights in one article." |
| `404 highlight.not_found` | "الـ Highlight ده مش موجود." | "Highlight not found." |

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

### Mute & feedback (F28) — SPEC F28

Bearer on every route (guests: `401 auth.unauthorized`; clients show the sign-in prompt instead of calling). Writes need
`follows.manage` (every member) and use the `writes` rate limit (30 a minute); `GET /me/mutes` is unthrottled.

| Method | Path | Body → Response |
|---|---|---|
| PUT | `/users/{id}/mute` | → `200 UserMuteStateDto` (idempotent). Mutes the writer and ends your follow of them (`followRemoved: true` when there was one). `400 mute.self`, `400 mute.system_account` (the official `@readin`), `400 mute.limit` (500 muted writers), `404 user.not_found` (unknown or deleted). A suspended account can be muted |
| DELETE | `/users/{id}/mute?restoreFollow=` | → `200 UserMuteStateDto` (idempotent; `followRemoved: false`). `restoreFollow=true` also follows the writer again, as `PUT /users/{id}/follow`: the toast's Undo after a mute whose answer had `followRemoved: true`. The banner and Settings → Muted leave it out. `404 user.not_found` |
| PUT | `/me/mutes/fields/{id}` | → `200 ContentMutesDto` (idempotent). `404 field.not_found` (unknown or disabled) |
| DELETE | `/me/mutes/fields/{id}` | → `200 ContentMutesDto` (idempotent, any id) |
| PUT | `/me/mutes/topics/{id}` | → `200 ContentMutesDto` (idempotent). `404 topic.not_found` |
| DELETE | `/me/mutes/topics/{id}` | → `200 ContentMutesDto` (idempotent, any id) |
| GET | `/me/mutes` | → `200 MutesDto`: Settings → Muted (F18). Writers, fields and topics, each newest mute first, not paged |
| PUT | `/articles/{id}/show-less` | → `204` (idempotent: a repeat changes nothing). "قلّل من النوع ده". `400 mute.own_article`, `404 article.not_found` (an article you can't open, as `GET /articles/{slug}`) |
| DELETE | `/articles/{id}/show-less` | → `204` (idempotent, any id): the toast's Undo |

**Mute a writer.** Private: the writer isn't told, keeps seeing your content, and their follow of you stays. Muting
ends your follow of them, and following a writer you muted (`PUT /users/{id}/follow`) ends the mute, so the two never
hold at once. For you, their articles leave the lists below, their comments and replies collapse
(`CommentDto.isAuthorMuted`) and their activity sends you no notification. Direct links still open: the reader
(`ArticleDetailsDto.isAuthorMuted`) and the profile (`ProfileDto.isMuted`) show "انت كاتم الكاتب ده" with "إلغاء
الكتم" (`DELETE /users/{id}/mute`); the profile's tabs and category pages still list their articles.

**Mute a field or topic** (the "كتم المواضيع" sheet): one toggle for the card's `field` (`isFieldMuted`) and one for its
`topic` (`isTopicMuted`; no row when `topic` is `null`). On = `PUT`, off = `DELETE`; set both toggles from the returned
`ContentMutesDto`. Your interests (F02, F12) don't change, but a mute wins over an interest. A muted field hides its
topics' articles too (and its topics in Search); a topic mute is kept apart, so it stays when the field is unmuted.

**Show less.** The article leaves your feeds (every list below but Search) until you Undo. Its topic, or its field when
it has no topic, is **lowered in For you** for 90 days from then: For you's tiers become (1) your interests, (2) all
the others, (3) lowered articles (their topic is one you lowered, or their field is), each newest first; without
interests, or with a `field` filter, (1) the rest and (2) lowered. Guests are unchanged. The cursor names the tier, so
paging never repeats or skips a card while your marks stay the same; a Show less mid-scroll moves the other articles of
that topic to the last tier, where they can come again, so drop ids you already show. Undo deletes the mark and the
lowering it caused (another mark on the same topic keeps it lowered). A cursor whose tier no longer exists (the Undo
removed the lowered tier while you paged in it) restarts the last tier from the top, so nothing is skipped; again, drop
ids you already show. There is no list of these marks.

**Where mutes apply** (signed-in callers; guests see everything):

| List | Muted writers | Muted fields and topics | Show less |
|---|---|---|---|
| For you, Following (reposted articles too, F29), Today's article, Related | left out | left out | left out (For you also lowers the topic) |
| Explore `trending` / `mostSaved` and both rankings, tag pages | left out | left out | left out |
| Explore `fields` and `newWriters`, a field's top writers, suggested writers (`/users/suggested`) | left out | muted fields left out | — |
| `/fields/{slug}/articles` | left out | the other muted topics left out; the page's own field and the topic picked in `topic` are shown (you opened them) | left out |
| Search | articles and people left out | articles, fields and topics left out | kept (you searched for it) |
| Profile tabs (Reposts included, F29), category pages, saved, paths, continue reading, glossary | kept | kept | kept |

Today's article: the pick skips them. When the day's pick is by a writer you then mute, in a field or topic you then
mute, or one you mark Show less, `GET /feed/today` gives the next eligible pick instead, and that one stays for the rest
of the day (unmuting doesn't bring the first back); `204` only when nothing eligible is left.

**Viewer flags** (filled per caller like `isSaved`, never cached; `false` for guests): `isAuthorMuted`, `isFieldMuted`,
`isTopicMuted` on every `ArticleCardDto` and `ArticleDetailsDto`, `isAuthorMuted` on every `CommentDto`, `isMuted` on
`ProfileDto`. In lists that apply mutes they are `false` (such cards are left out), except a field page's own field
and picked topic. Cards now carry `topic` (it was on `ArticleDetailsDto` only).

**The "⋯" menu** (reader action bar and post-card header, F04/F34), in this order: Show less, Hide highlights (the
reader only, F30), Follow author, Mute author, Mute topics, Download PDF (the reader only, F33), Report (error color),
then the moderator's Hide/Unhide after a divider. On your own article only Hide highlights, Mute topics and Download PDF
stay. Guests get the sign-in prompt for every item except Hide highlights, which a guest's device keeps locally (F30).
Mute/Unmute is also on a profile's "⋯" (not your own, not the official account) and a comment's "⋯" (the commenter; not
your own comments), with the same Undo. After Mute author, remove every card by that writer from the list on screen;
after Show less, that card; after a field or topic toggle, the cards in it (animated unless reduce motion is on). Undo
puts them back in place. In the reader, Mute author shows the banner instead of leaving the page.

**Comments (F11).** `isAuthorMuted: true` → show "تعليق من شخص كتمته" with "عرض", which expands it locally (the body is
in the DTO). Replies under it render as usual; counts don't change. The same in feed-card comments (F34).

**Notifications (F17).** No entry, and no actor in an aggregated entry, comes from a writer you muted: follows,
comments, replies, mentions (comments and articles), reposts (F29). Entries written before the mute stay. Milestones and the daily
article have no actor and still come (the daily pick skips muted content).

**Account deletion (SPEC §9.6).** The account's mutes, both ways (whom it muted, who muted it), and its show-less marks
are deleted.

Mute error codes: `mute.self`, `mute.system_account`, `mute.limit`, `mute.own_article` (all 400), plus `user.not_found`,
`field.not_found`, `topic.not_found` and `article.not_found` (404).

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
| GET | `/users/mention-suggestions?q=&limit=8` | Bearer → `MentionCandidateDto[]`: `@username` prefix (with or without `@`) or display name, not you, and only people you may mention (see below). The comment box and the article editor both use it |

Text rules: trimmed, line ends trimmed, at most one empty line in a row, 1–2000 characters (`400 comment.empty`,
`comment.too_long`). `@username` (3–30 of a–z 0–9 _, not right after a Latin letter or digit, so emails aren't mentions;
fine after an Arabic letter, "و@writer1") resolves to real users you may mention, at most 10, never yourself; they come
back in `mentions`, and clients link exactly those handles. Any other `@handle` stays plain text: not in `mentions`, no
link, no notification. Each mentioned user gets a `mention` notification (F17). Flood limits on top of the
rate limit: at most 20 comments per user on one article per hour (`429 comment.article_limit`, deleted ones count), and
not the same text (case and spacing ignored) within 10 minutes (`409 comment.duplicate`).

**Who you may mention** ("who can mention me", F18 privacy, `MeDto.privacy.whoCanMention`): yourself (an article keeps a
link to your own handle; comments and suggestions leave you out, as above, and nobody is notified about themselves);
anyone whose setting is `everyone` (the default); someone whose setting is `following` when **they follow you**; nobody
whose setting is `nobody`. The account must also be active: deleted, suspended and system accounts are never linked. The
rule is checked by the suggestions, by comments when they are written or edited (a later change of the setting leaves
existing comments alone), and by articles when they go live (see Editor).

**Text and emoji only (F11).** The write bodies are `{ body }` and nothing else: comments and replies have no images,
GIFs or attachments. Any other property in the body (`attachments`, `imageUrl`, `gif`, `mediaAssetId`…) is ignored:
only the text is stored, and `CommentDto` has no media field. Emoji are ordinary text (an emoji counts as its UTF-16
length toward the 2000).

**Reply with a mention (F11).** "رد" / "Reply" pre-fills the box with `@{username} ` of the comment's author (not when
you reply to yourself), as plain text like any typed mention, with the caret after it; the user can delete it. Posting
resolves it like every mention. When that person doesn't allow you to mention them (their setting, or a suspended or
system account), the reply is still posted (`201`, no error) with the handle as plain text: not in `mentions`, no link,
no `mention` notification. The reply notification still goes to the author of the comment replied to (`comment_reply`,
aggregated per thread; a reply to a reply tells the author of that reply). When the mention is allowed, they get the
`mention` instead (one entry per recipient per comment, see Notifications).

**The comment row (F11).** `author.headline` is the writer's title (one line with "…", in place of the `@username`;
hidden when `null`). `isFollowingAuthor` says whether you follow the comment's author: show "متابعة" / "Follow" when it is
`false`, `author` isn't `null` and `author.id` isn't your id (guests: the button opens the sign-in prompt). The flag is
`false` for guests, on your own comments, for a deleted author and on placeholders. Following from a
row uses `PUT /users/{id}/follow` and the shared follow store, so every row, card and profile of that writer updates.
Seed the store from `isFollowingAuthor` like cards do.

**Replies in pages (F11).** The list's first 2 replies are kept, but a thread shows only the first until "show N more
replies". Each tap shows up to 5 more: first the ones already loaded, then `GET /comments/{id}/replies?limit=5&cursor=…`.
The first call has no cursor, so dedupe the 2 the list gave. N = `replyCount` minus the replies shown. "Hide replies"
folds the thread back to its first reply without dropping what was loaded.

**Profile card on hover (web).** The card a pointer opens on an `@mention` or a commenter's name reads
`GET /users/{username}` (`ProfileDto`). It uses `displayName`, `avatarUrl`, `isVerified`, `headline`, `followsYou`,
`stats.followers`, `stats.articles`, `isFollowing` and `isMe`. Clients cache it briefly per viewer. There is no new
endpoint.

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

### Reports and moderation (F22; Bearer)

| Method | Path | Body → Response |
|---|---|---|
| POST | `/reports` | `{ targetType: "article"\|"comment"\|"user", targetId, reason: spam\|misinformation\|harassment\|copyright\|other, details? (≤ 500) }` → `204`. Permission `reports.create`, rate limit `writes`. Reporting the same target again is a no-op. `400 report.own_content` (your article or comment, or yourself), `404 report.target_not_found` (unknown or deleted; a hidden article and its comments for anyone but its author and moderators), validation `report.target_invalid`, `report.reason_invalid`. A suspended user can be reported |
| GET | `/moderation/summary` | → `{ open: { article, comment, user, total } }`: targets with open reports (the nav badge) |
| GET | `/moderation/reports?status=&type=&cursor=&limit=` | → `CursorPage<ModerationQueueItemDto>`, one item per target. `status` = `open` (default) \| `resolved` \| `dismissed`; `type` = `article` \| `comment` \| `user` (optional). Open: most reports first, then the most recent report. Resolved and dismissed: most recently closed first. `limit` 1–50 (default 20). Validation `report.status_invalid`, `report.target_invalid` |
| GET | `/moderation/reports/{targetType}/{targetId}` | → `ModerationCaseDto`; a user's case also lists the user's writer categories (`categories`, F31). `404 report.target_not_found` when nobody reported it |
| POST | `/moderation/actions` | `ModerationActionRequest` → `204`. Rate limit `writes`. Rules below |
| GET | `/moderation/actions?targetUserId=&moderatorId=&targetType=&cursor=&limit=` | → `CursorPage<ModerationActionDto>`, newest first (the log). `limit` 1–50 (default 20) |
| GET | `/me/moderation-notices` | Any signed-in user → `{ items: ModerationNoticeDto[] }`: unacknowledged warnings and hidden articles, oldest first. Show each as a dialog on start |
| POST | `/me/moderation-notices/{id}/acknowledge` | → `204` ("فهمت"; idempotent). `404 moderation.notice_not_found` for someone else's notice |

Every `/moderation/*` route needs `moderation.manage` (the SuperAdmin; `403 auth.forbidden` otherwise, so for every
Member).

`ModerationActionRequest`: `{ action, targetType, targetId, note?, durationDays?, resolveReportsOf?: { targetType, targetId }, categoryId?, hideContent? }`
(`hideContent`: `suspend` only, F23; with `true` the user's articles and comments are hidden too, see "Admin console (F23)" →
"Users". F23 also adds the user actions `hide_content` and `unhide_content`, and "staff" now also means holders of
`admin.access`.)
(`categoryId`: `clear_category` only).

| Target | Actions |
|---|---|
| `comment` | `hide`, `unhide`, `delete`, `dismiss` |
| `article` | `hide`, `unhide`, `dismiss` (moderators never delete articles) |
| `user` | `warn`, `suspend`, `unsuspend` (both need `users.suspend`, `403 auth.forbidden` otherwise), `clear_category` (F31), `clear_links`, `clear_headline` (F14), `dismiss` |

- Any other pair, or an unknown action or type: `400 moderation.action_invalid`.
- `note` (≤ 500, validation `validation.max_length`) is required for `warn` and `suspend` (`400 moderation.note_required`); it
  is shown to the user for `warn` and an article `hide`.
- `durationDays` is for `suspend` only: 1–365, or `null`/omitted for a permanent suspension (`400 moderation.duration_invalid`).
- `warn`, `suspend`, `unsuspend` on yourself: `400 moderation.self`; on staff, i.e. a user with `moderation.manage`
  (today the SuperAdmin), or a system account: `403 moderation.staff_target`. Hiding staff's articles or comments is
  allowed.
- `clear_category` (F31, an offensive writer-category name reported with the user): `categoryId` is required
  (`400 validation.failed`, `errors.categoryId: ["validation.required"]`) and must be one of that user's categories
  (`404 category.not_found`); the user's case lists them in `ModerationCaseDto.categories`. The category is renamed to a neutral placeholder, `قسم {n}` when the writer's UI language
  is Arabic or `Category {n}` in English (the smallest `n` the writer doesn't use), and gets a new slug made from it (the
  old slug held the name, so its links answer `404 category.not_found`); its articles stay in it. A category already
  named like that is left alone (`204`, nothing logged). Allowed on any user, like hiding content. Like `hide`, it
  resolves the user's open reports (and those of `resolveReportsOf`). Logged as `user.clear_category` with the old name
  as `targetLabel`, and in the audit log; the writer gets no notice.
- `clear_links` and `clear_headline` (F14, an abusive social link or title reported with the user): remove all of the
  user's links (`links: []`) or their title (`headline: null`). Like `clear_category` they are content actions: allowed on
  any user (staff, a system account and yourself included), `note` optional, no notice or notification to the user.
  When there is nothing to clear (no links, no title) the answer is `204` and nothing is logged or resolved. Otherwise
  they resolve the user's open reports (and those of `resolveReportsOf`) and are logged as `user.clear_links` (label: the
  removed URLs joined by a space, cut to 200 characters) and `user.clear_headline` (label: the removed title), and in the
  audit log (`moderation.links_cleared`, `moderation.headline_cleared`). The cards, reader and comments show the change
  at once (the cached article pages of the user are dropped). The user's case shows both: `target.author.headline` and
  `target.links` (user targets only).
- `404 article.not_found` / `comment.not_found` / `user.not_found` for an unknown or deleted target (a deleted target can
  still be `dismiss`ed).
- `hide`, `delete`, `warn`, `suspend`, `clear_category`, `clear_links` and `clear_headline` resolve the target's open
  reports, and those of `resolveReportsOf` (e.g. warn the author from an article case). `dismiss` closes the target's open reports as dismissed and changes nothing else.
- Repeating an action that changes nothing (hide a hidden article, unsuspend an active user) is `204` and logs nothing.
- Every action that changed something is a `ModerationActionDto` in the log; actions on a user's content or account are
  also in the audit log. `warn` and an article `hide` are notices to the user (`GET /me/moderation-notices`) with a push.
- A suspension blocks the account at once (`403 user.suspended` with `suspendedUntil`, see Errors), and a temporary one
  ends by itself at `suspendedUntil`.

### Writer verification (F19; Bearer) — SPEC F19

| Method | Path | Body → Response |
|---|---|---|
| GET | `/me/verification` | → `VerificationStatusDto`: `isVerified` (the Verified badge, `Users.IsVerified`), `canRequest` (not verified, not suspended, nothing pending) and `request`, the latest request whatever its status (`null` when there was none) |
| POST | `/verification-requests` | `multipart/form-data`: `fieldId`, `jobTitle`, `proofUrl?`, `note?`, `proof?` (file) → `201 MyVerificationRequestDto` (`Location: /api/v1/me/verification`). Rate limit `writes`. Rules below |
| DELETE | `/me/verification` | Withdraws the pending request: it is deleted with its file → `204`. Rate limit `writes`. `404 verification.not_found` when nothing is pending |
| GET | `/admin/verification-requests?status=&cursor=&limit=` | → `CursorPage<AdminVerificationRequestDto>`. `status` = `pending` (default, oldest first) \| `approved` \| `rejected` (most recently decided first). `limit` 1–50 (default 20). Validation `verification.status_invalid` |
| GET | `/admin/verification-requests/{id}` | → `AdminVerificationRequestDto`. `404 verification.not_found` |
| GET | `/admin/verification-requests/{id}/proof` | → `200` the file, with its stored `Content-Type` (`application/pdf` \| `image/jpeg` \| `image/png` \| `image/webp`), `Content-Disposition: attachment; filename="verification-proof-{id}{.ext}"`, `Cache-Control: no-store`, `X-Content-Type-Options: nosniff`. `404 verification.proof_not_found` when the request has no file (URL only, or decided: the file is gone), `404 verification.not_found` |
| POST | `/admin/verification-requests/{id}/approve` | → `204`. Rate limit `writes`. The user gets the Verified badge at once (`IsVerified = true`, `VerifiedAt` = now; a user who already has it keeps the first `VerifiedAt`); roles and permissions don't change, the user stays a `Member`. Refresh `GET /me` to show it; cached public pages follow within their cache time (≤ 10 minutes). The proof file is deleted, `verification_result` is written, audit `admin.verification_approved`. `409 verification.already_decided`, `404 verification.not_found` |
| POST | `/admin/verification-requests/{id}/reject` | `{ reason }` (5–500 characters after trimming, required; validation `validation.required` / `validation.length` on `reason`) → `204`. Rate limit `writes`. The proof file is deleted, `verification_result` is written, audit `admin.verification_rejected`. `409 verification.already_decided`, `404 verification.not_found` |
| DELETE | `/admin/users/{id}/verification` | Removes a user's Verified badge → `204`. Rate limit `writes`. Clears `IsVerified` and `VerifiedAt`, audit `admin.verification_removed`. The user's past requests stay as they were (an approved one stays approved), the user can request again (`canRequest`), and nothing is sent to the user (no notification, no push). `404 user.not_found` (unknown or deleted user), `409 verification.not_verified` (the user has no badge), `409 verification.system_account` (a system account, i.e. the official @readin account: its badge stays) |

Every `/admin/verification-requests` route and `DELETE /admin/users/{id}/verification` need `verification.manage`
(the SuperAdmin; `403 auth.forbidden` for every Member). A suspended account gets `403 user.suspended` on every route,
as elsewhere.

**Removing a badge** (web: "Remove badge", with a confirmation, on an Approved item of `/admin/verification` while
`user.isVerified` is still true): after `204`, refresh the item (or the list) so its `user.isVerified` turns `false`
and the action goes away. A `409 verification.not_verified` means someone already removed it: refresh the same way.
A `409 verification.system_account` changes nothing: show the error, and the badge stays.

`POST /verification-requests`, checked in this order:

- Validation (`400 validation.failed`): `jobTitle` required, 2–100 characters after trimming (`validation.required`,
  `validation.length`); `proofUrl` an absolute `https://` URL (`validation.url`) of at most 500 characters
  (`validation.max_length`); `note` at most 500 (`validation.max_length`). Blank `proofUrl` / `note` count as missing.
- `409 verification.already_verified` (the user has the Verified badge, `isVerified`), then `409 verification.already_pending`
  (one pending request per user, also for two submits at once).
- `400 verification.field_invalid`: `fieldId` missing, not a GUID, unknown or disabled (`GET /fields`).
- `400 verification.proof_required`: neither `proofUrl` nor `proof`. Both are allowed.
- `400 verification.proof_invalid`: the file is empty, larger than 10 MB, or not a PDF, JPEG, PNG or WebP **by its
  bytes** (the file name and the part's `Content-Type` are ignored; HEIC, GIF and the rest are refused). A body far
  over the limit gets the same answer (the server stops reading it). Clients should check type and size first.
- A body that isn't `multipart/form-data` (e.g. JSON): `415 request.unsupported_media_type`.
- The file is stored privately as `verification/{id}{.ext}` (never under `/uploads`, never at a public URL). Its name
  is kept only for display (`proofFileName`), sanitized: no folders, control or direction-override characters,
  at most 120 characters.

Retention: the proof file is deleted when the request is approved or rejected (`proofFileName` and `proof` become
`null`); the decision, the reason and `proofUrl` stay. A rejected user can send a new request; `GET /me/verification`
then shows the new one. The reason is only shown on the verification page, never in the notification or its push.

Error codes: `verification.proof_required`, `verification.proof_invalid`, `verification.field_invalid`,
`verification.already_pending`, `verification.already_verified`, `verification.already_decided`,
`verification.not_found`, `verification.proof_not_found`, `verification.status_invalid` (validation, `status`),
`verification.not_verified` and `verification.system_account` (new with the roles change,
`DELETE /admin/users/{id}/verification`):

| Code | Arabic | English |
|---|---|---|
| `409 verification.not_verified` | "المستخدم ده مش موثّق." | "This user isn't verified." |
| `409 verification.system_account` | "ده حساب ReadIn الرسمي، والتوثيق بتاعه ثابت." | "This is ReadIn's official account; its badge stays." |

`request.unsupported_media_type` (415) is new and general: any endpoint answering 415 (a JSON body sent to a multipart
upload) now carries it instead of `server.error`.

### Notifications (F17; Bearer) — SPEC F17, §21.1

Reads are unthrottled; writes use the `writes` rate limit (30 a minute).

| Method | Path | Body → Response |
|---|---|---|
| GET | `/me/notifications?cursor=&limit=` | → `CursorPage<NotificationDto>`, latest activity (`updatedAt`) first. `limit` 1–50, default 20 |
| GET | `/me/notifications/unread-count` | → `{ unread: number }`: entries not seen yet. The REST fallback of `/live/users/{id}/unreadNotifications` (same number) |
| POST | `/me/notifications/seen` | → `204`. Call when the center opens: every entry is seen and the badge is 0. Entries stay **unread** until opened |
| POST | `/me/notifications/{id}/read` | → `204`. Call when an entry, or its push, is opened (it is seen too). Idempotent. `404 notification.not_found` (unknown, or someone else's) |
| POST | `/me/notifications/read-all` | → `204` ("mark all read") |
| GET | `/me/notification-settings` | → `NotificationSettingsDto`: quiet hours and **every** configurable type's mode |
| PUT | `/me/notification-settings` | `NotificationSettingsDto` → `204`. `types` is partial (types left out keep their mode), `quietHours` may be left out. `400 notification.type_invalid` (unknown type, or `security_alert` / `moderation_notice` / `verification_result`), `400 notification.mode_invalid` (not `all` / `inApp` / `off`), `400 notification.quiet_hours_invalid` (not `HH:mm`, or start = end). Nothing changes on an error |

Types and what writes them (one entry per recipient; nobody is told about their own action; suspended and system
accounts get nothing):

| `type` | When | Aggregated | `link` |
|---|---|---|---|
| `new_follower` | someone follows you | per day (your time zone); following again the same day is not news | 1 follower `readin://u/{their username}`, more `readin://u/{your username}/followers` |
| `article_comment` | a top-level comment on your article | per article | `readin://a/{slug}#comment-{latest comment id}` |
| `comment_reply` | a reply to your comment | per thread | same |
| `mention` | a comment @mentions you (also when an edit adds you), or a published article does (also when an "Update" adds you; once per article, ever): `comment: null`, `article` set | no | a comment: same; an article: `readin://a/{slug}` |
| `reactions_milestone` | your article reaches 10, 50 or 100 reactions (each once, ever) | no | `readin://a/{slug}` |
| `followed_writer_article` | a writer you follow publishes an article (first publish only) | no; **the official @readin account: per day** (your time zone, see below) | `readin://a/{slug}`; @readin with `data.articleCount` ≥ 2: `readin://u/readin` |
| `daily_article` | Today's article push (F07); also written when the push waits for quiet hours | no | `readin://a/{slug}` |
| `streak_reminder` | 20:00 your time, your streak is ≥ 1 and you haven't read today | no | `readin://me/stats` |
| `security_alert` | password, PIN or phone changed, password reset, recovery locked, Google/Apple linked or unlinked, phone sign in added | no | `readin://settings/account` |
| `moderation_notice` | a moderator warned you or hid your article (F22) | no | the hidden article `readin://a/{slug}`, a warning `readin://notifications` (the app shows the notice from `GET /me/moderation-notices`) |
| `verification_result` | the SuperAdmin approved or rejected your verification request (F19; removing a badge later sends nothing): `data.approved` `true` / `false`, no actor, no article. Without `data.approved` (never written now) render a generic text | no | `readin://verification` |
| `article_reposted` | someone reposted your article (F29; undoing and reposting again is not news) | per article | `readin://a/{slug}` |
| `announcement` | an admin's announcement (F23): `data.announcementId`, `data.title`, `data.body` (in Accept-Language); no actor | no | the article `readin://a/{slug}`, the path `readin://paths/{slug}`, or `readin://notifications` |

- One entry per recipient per comment: `mention` > `comment_reply` > `article_comment`. An edit only tells users it
  mentions for the first time.
- A mention in an article: every user the live version mentions (any language version) whom the author may mention
  (see Comments, "Who you may mention") gets one entry, actor = the author, written after the publish or "Update". Each
  user hears about an article once, ever: an update tells only newly mentioned users, and removing and re-adding a
  mention tells nobody again. Never the author. At most 20 people per article (all language versions, in document
  order) keep their link and are told; mentions of anyone after them become plain text, as past 10 in a comment. Clients show `type: "mention"` with `comment: null` as
  "X mentioned you in an article" / "X عمل لك منشن في مقال", then the article's title; with a `comment` it stays "…in a
  comment". The entry stays in the list while its article is readable. Both follow the `mention` type's mode, so its
  Settings label covers both: "Mentions" / "المنشن", hint "When someone mentions you in a comment or an article" /
  "لما حد يعمل لك منشن في تعليق أو مقال".
- Aggregation: new activity joins an **unread** entry of the same group that moved in the last 24 hours; the entry moves
  to the top as unseen, with the newest actor, and its push goes out again with the count. A read entry starts a new one.
- `article_reposted` (F29, new): actor = the latest reposter, `actorCount` = distinct reposters, `article` set, `comment`
  `null`, `data` `{}`. Row text: "{name} أعاد نشر مقالك" / "{name} reposted your article"; more: "{name} و{n} غيره أعادوا
  نشر مقالك" / "{name} and {n} others reposted your article"; then the article's title. It is a configurable type, so
  `GET /me/notification-settings` now returns **9** types; Settings label "إعادة النشر" / "Reposts", hint "لما حد يعيد
  نشر مقالك" / "When someone reposts your article". The entry stays in the list while its article is readable.
- **The official @readin account's articles, grouped per day (leftovers step).** Every other writer still gives one
  `followed_writer_article` per article. For the official account (the system account, `@readin`) each follower gets
  **one entry per day** (the follower's time zone) instead: the type stays `followed_writer_article`, actor = the
  account (`actorCount` 1), `article` = its **newest** article in the entry, and `data.articleCount` = how many of its
  new articles the entry holds (≥ 1; the key is only on these entries). A new article that day joins the unread entry:
  it moves to the top as unseen, shows the newest article, and its push is armed again; a read entry starts a new one
  (counting from 1), as for every group. Each article counts once (a retried event changes nothing).
  - `link`: one article → `readin://a/{slug}`; two or more → `readin://u/readin` (the account's profile, its articles
    newest first).
  - Row text (clients): `articleCount` 1 → as today ("نشر {name} مقالًا جديدًا" / "{name} published a new article",
    then the title). `articleCount` ≥ 2 → "نشر {name} مقالين جديدين" (2), "نشر {name} {n} مقالات جديدة" (3–10),
    "نشر {name} {n} مقالًا جديدًا" (11–99), "نشر {name} {n} مقال جديد" (100+), CLDR plural forms of `n`, verb first;
    English "{name} published {n} new articles"; then the newest article's title. A client that doesn't read
    `articleCount` shows the single-article text with the newest title and still opens `link`.
  - Push: as every F17 push (the type's mode `all` / `inApp` / `off`, quiet hours; the official account can't be
    muted, `mute.system_account`), but it waits
    **10 minutes after the account's latest article** (so a batch of articles is one push), title as the row text,
    body = the newest article's title, collapse key = the group (`followed_writer_article:{accountId}:{yyyy-MM-dd}`),
    `data.link` as above (`data.lang` only with an article link).
  - Settings: no new type; the `followed_writer_article` setting covers it (`GET /me/notification-settings` still
    returns 9 types).
  - Known limit: the entry hangs on its newest article. If a moderator hides that one or it is deleted (or its field
    is turned off), the whole entry leaves the list (its push, if still pending, is skipped), like any entry whose
    article isn't readable, even though its other articles are still there; and `articleCount` keeps counting
    articles hidden or deleted since.
- What the list (and the badge) leaves out: entries whose comment was deleted or hidden, whose article isn't readable
  any more (a moderation notice keeps its hidden article), and `new_follower` entries whose followers all deleted their
  accounts. A deleted actor is gone from `actor` / `actorCount`: an entry left with no actor shows "Deleted user"
  (`actor: null`).
- `announcement` (F23, new): an admin's message to everyone or to the readers of a field or an article language, at
  most one a day. No actor; the row shows `data.title`, then `data.body`. With an article link it carries `article`
  and, like every entry with an article, leaves the list when that article can't be read any more. A configurable type:
  `GET /me/notification-settings` now returns **10** types; Settings label «الإعلانات» / "Announcements", hint
  «إعلانات من فريق ReadIn» / "News from the ReadIn team". Quiet hours apply.
- Modes per type: `all` (in-app + push, the default), `inApp` (no push), `off` (no entry at all). `security_alert`,
  `moderation_notice` and `verification_result` always come. Quiet hours (default on, 23:00–07:00 in the user's time
  zone) hold pushes until they end; `security_alert` ignores them, and the daily article keeps F07's rule (a push due in
  quiet hours goes out once they end, within its 2-hour late window).
- Live badge: after every change the API writes `/live/users/{id}` `{ unreadNotifications, lastNotificationAt }` (see
  Real-time); listen to it, and use `unread-count` when RTDB isn't there.

### Profile (F14) 🌐 (Bearer optional)

`{username}` is matched ignoring case and one leading `@` (`/users/@Mona` = `/users/mona`). Deleted and suspended
accounts are `404 user.not_found` on all five, except that holders of `users.read` (F23) also get suspended accounts;
system accounts (the official `@readin`) are shown like everyone else. `ProfileDto.admin` is set only for holders of
`users.read`, for the admin items of the profile's "⋯" ("Admin console (F23)" → "Admin actions inside the app").
The phone number and e-mail are never in these responses (SPEC §9.5).

| Method | Path | Response |
|---|---|---|
| GET | `/users/{username}` | `200 ProfileDto` (with `headline` in full and `links`, for guests too) |
| GET | `/users/{username}/articles?cursor=&limit=` | `CursorPage<ArticleCardDto>`: published articles, newest first, with the caller's `myReaction` / `isSaved` like every feed. `limit` 1–50, default 20 |
| GET | `/users/{username}/reposts?cursor=&limit=` | `CursorPage<ArticleCardDto>`: the **Reposts** tab (F29), newest repost first; see Reposts |
| GET | `/users/{username}/stats` | `200 ReadingStatsDto`, computed in **that user's** time zone. `403 profile.stats_private` unless it's your own profile or the user turned on `publicReadingStats` |
| GET | `/users/{username}/stats/heatmap?days=` | `200 ReadingHeatmapDto` (as `/me/stats/heatmap`), same privacy rule |

Editing (Bearer, `PATCH /me`, `UpdateProfileRequest`):
- **Avatar.** Upload with `POST /uploads/images`, `purpose=avatar` (square, center-cropped WebP 64/128/256/512; show the
  256 variant as the preview), then send its `id` as `avatarAssetId`. The server stores the 256 px variant in
  `avatarUrl`, so every `AuthorDto` / `UserSummaryDto` shows it. **Omit** `avatarAssetId` (and `avatarUrl`) to keep the
  current avatar; send `"avatarAssetId": null` to remove it. Anything but your own `avatar` upload (someone else's, a
  cover, an unknown id) is `400 profile.avatar_invalid`, also listed in `errors.avatarAssetId`. `avatarUrl` is still
  accepted from the previous release (an uploaded avatar's URL or an external https image; `null` removes); when both
  are sent, a non-null `avatarAssetId` wins.
- **Expertise.** `expertiseFieldIds`: 0–5 enabled field ids, kept in the order sent (a repeated id counts once); `[]`
  clears them, omitted keeps them. More than 5 or an unknown/disabled id is `400 profile.expertise_invalid`, also listed
  in `errors.expertiseFieldIds`.
- `displayName`, `username` and `bio` replace the current values as before (an omitted `bio` clears it).
- **Title** (`headline`, new) and **links** (new shape): below. Unlike `bio`, **omitting** either one keeps it.

#### Title and social links (F14, pre-production step)

**Title** (`headline`, "المسمى" / "Title"): one optional line under the writer's name, e.g. "Senior Full Stack .NET
Engineer | .NET | Angular".
- `PATCH /me` and `PUT /me/profile/complete`: `headline` omitted keeps the current title; `null`, `""` or only spaces
  clears it. A value is trimmed and stored as written (Arabic, English or mixed).
- At most **120** characters after trimming (`profile.headline_too_long`); one line with no control or
  direction-override characters: line breaks, tabs, U+0000–U+001F, U+007F–U+009F, U+200E/U+200F, U+202A–U+202E and
  U+2066–U+2069 are refused (`profile.headline_invalid`). Both codes are validation codes in `errors.headline`.
- Returned as `headline` (`null` when empty) on `MeDto`, `ProfileDto`, every `AuthorDto` (cards, reader, comments and
  replies, who reacted, the moderation case, category pages, repost labels) and every `UserSummaryDto` (followers,
  following, suggestions, search people, Explore writers, mutes list).
- Always the writer's current title. Changing the title, the name, the @username or the avatar drops the cached reader
  pages, cards and lists that show the writer, so the change shows at once (not after the 10-minute cache time).
- Clients: on cards, in the reader's author row and on comment rows show it on one line, cut with "…", with
  `dir="auto"` (§14.2); on the profile in full (wrapped). With `null` the line is hidden. On cards and in the reader the
  line "field · time · reading time" moves below it.

**Social links** (`links`, "روابط" / "Links"): an ordered array of `ProfileLinkDto` `{ platform, url, label }`.
- `PATCH /me`: `links` omitted or `null` keeps the current links; an array **replaces the whole list** (`[]` removes
  them all). Kept in the order sent; the profile shows them in that order. `PUT /me/profile/complete` has no links.
- Read back on `GET /me` and `GET /users/{username}` (for guests too), always an array (`[]` when none).
- **Breaking change:** `links` was an object `{ github, linkedin, website }`; it is now this array in requests and
  responses. Saved GitHub, LinkedIn and website links were migrated in that order to `github`, `linkedin`,
  `website` entries (a migrated link that breaks a rule below is kept until the user saves, then it is reported).

| `platform` | Icon / name | Allowed hosts (the host itself or any subdomain, e.g. `www.`, `m.`) |
|---|---|---|
| `linkedin` | LinkedIn | `linkedin.com`, `lnkd.in` |
| `x` | X | `x.com`, `twitter.com` |
| `instagram` | Instagram | `instagram.com`, `instagr.am` |
| `facebook` | Facebook | `facebook.com`, `fb.com`, `fb.me` |
| `youtube` | YouTube | `youtube.com`, `youtu.be` |
| `tiktok` | TikTok | `tiktok.com` |
| `snapchat` | Snapchat | `snapchat.com` |
| `threads` | Threads | `threads.net`, `threads.com` |
| `telegram` | Telegram | `t.me`, `telegram.me` |
| `github` | GitHub | `github.com` |
| `medium` | Medium | `medium.com` (and `*.medium.com`) |
| `behance` | Behance | `behance.net` |
| `website` | Website ("الموقع") | any `https` host |
| `other` | the member's `label` | any `https` host |

Rules (checked in this order per link; every failure is a validation code under its index, e.g.
`errors["links[2].url"]`):
- At most **8** links: `link.too_many` in `errors.links`.
- `platform` is one of the 14 values above, lower case: `link.platform_invalid` (`links[i].platform`).
- One link per platform, except `other`, which may repeat: `link.duplicate_platform` on each repeat
  (`links[i].platform`).
- `url` is required (`validation.required`), trimmed. Without a scheme, `https://` is added (`instagram.com/name` →
  `https://instagram.com/name`); the stored and returned `url` is that normalized value.
- At most **500** characters after that (`link.too_long`).
- `https` only: `http://` or any other scheme is `link.https_required`.
- A real absolute URL with a host name (a dot in it, not an IP address, no spaces), the default port and **no username
  or password**: `link.url_invalid`.
- A named platform's link is on one of its hosts: `link.host_mismatch`. `website` and `other` accept any host.
- `label` is for `other` only: required there (`link.label_required`), 2–30 characters after trimming, one line, no
  control or direction-override characters (`link.label_invalid`); sent with any other platform:
  `link.label_not_allowed`. Stored trimmed; `null` on every other platform.

Clients: on the profile, a row of icons under the bio (hidden when `[]`), for everyone including guests; each icon is a
link with an accessible name (the platform's name, or the label for `other`), icons don't mirror in RTL. Web opens a new
tab with `rel="nofollow ugc noopener noreferrer"`; mobile the system browser or the platform's app. In Edit profile, a
"روابط" / "Links" section with "+ إضافة رابط" / "Add link" (platform picker, then the URL; a label field for Other),
at most 8, each error under its own field.

| Validation code | Arabic | English |
|---|---|---|
| `profile.headline_too_long` | "المسمى لازم يكون 120 حرف أو أقل." | "A title has at most 120 characters." |
| `profile.headline_invalid` | "المسمى لازم يكون سطر واحد من غير رموز خاصة." | "A title must be one line, without special characters." |
| `link.too_many` | "تقدر تضيف 8 روابط بس." | "You can add up to 8 links." |
| `link.platform_invalid` | "اختار المنصة من القايمة." | "Choose a platform from the list." |
| `link.duplicate_platform` | "عندك رابط للمنصة دي بالفعل." | "You already have a link for this platform." |
| `link.too_long` | "الرابط لازم يكون 500 حرف أو أقل." | "A link has at most 500 characters." |
| `link.https_required` | "الرابط لازم يبدأ بـ https." | "The link must start with https." |
| `link.url_invalid` | "الرابط ده مش صحيح." | "This link isn't valid." |
| `link.host_mismatch` | "الرابط ده مش على موقع المنصة اللي اخترتها." | "This link isn't on the platform you chose." |
| `link.label_required` | "اكتب اسم للرابط." | "Give this link a name." |
| `link.label_invalid` | "اسم الرابط لازم يكون من 2 لـ 30 حرف في سطر واحد." | "A link name has 2–30 characters on one line." |
| `link.label_not_allowed` | "الاسم للروابط من نوع «تاني» بس." | "Only \"Other\" links have a name." |

**Moderation.** A SuperAdmin clears a user's links or title from the user's report case: `clear_links` /
`clear_headline` in `POST /moderation/actions` (see Reports and moderation).

**Account deletion.** The title and links are on `Users` and are deleted with the account (SPEC §9.6).

Profile error codes: `user.not_found` (404), `profile.stats_private` (403), `profile.avatar_invalid` (400),
`profile.expertise_invalid` (400), and the validation codes above.

The profile's **Categories** tab (between Articles and Reposts) and the category pages: see Writer categories (F31).

### Writer categories (F31) — SPEC F31

A writer's own way to group their articles ("أقسام الكاتب"), apart from fields and topics (platform-wide), collections
(F13, private) and learning paths (F09). An article has zero or one category, for all its language versions. Show a
`name` with `dir="auto"`; link with its `slug` (percent-encoded: it may hold Arabic letters), never with a name.

**Reading** 🌐 (Bearer optional). `{username}` as in Profile (ignoring case and one leading `@`); deleted and suspended
accounts are `404 user.not_found`.

| Method | Path | Response |
|---|---|---|
| GET | `/users/{username}/categories` | `WriterCategoryListDto`: the profile's Categories tab. `items`: the categories with at least one article readers can see, in the writer's order. `uncategorizedCount`: those articles without a category, the last card "مقالات تانية" / "Other articles" (hidden when 0). The same for everyone; the writer's own profile uses `GET /me/categories`, which also has the empty ones |
| GET | `/users/{username}/categories/{slug}` | `WriterCategoryPageDto`: the category page's header (title, description, server rendering). An empty category answers too: the page shows its empty state (web: `noindex`). `404 category.not_found` for a slug the writer doesn't have |
| GET | `/users/{username}/categories/{slug}/articles?cursor=&limit=` | `CursorPage<ArticleCardDto>`: the category's articles readers can see, newest first (`publishedAt` DESC, id DESC, keyset cursor, so paging never repeats or skips one), shown as the post card (F34), in the caller's article language and with the caller's `myReaction` / `isSaved` / `isFollowingAuthor` like every feed. `limit` 1–50, default 20; a cursor that doesn't decode starts from the first page. `404` like the header |

- **"مقالات تانية" (the uncategorized list)** is the reserved `{slug}` `_other`: its header has `id: null` and
  `name: null` (clients show "مقالات تانية" / "Other articles"), its articles are the writer's articles readers can see
  that have no category. A category's slug never starts with `_`, so the two never clash.
- **Pages.** Web `/@{username}/c/{slug}` (server-rendered; `/@{username}/c/_other` for the uncategorized list), mobile
  `/u/{username}/c/{slug}`, deep links `readin://u/{username}/c/{slug}` and `https://{host}/@{username}/c/{slug}`.
  `{slug}` is matched ignoring case.
- **What counts.** Lists and every `articleCount` / `uncategorizedCount` hold only articles readers can open (as
  `GET /articles/{slug}`: published, not deleted, in an enabled field, not hidden by moderators, F22); drafts never. The
  numbers are the same for everyone, the writer included. Like the profile's Articles tab, these pages don't apply mutes
  (F28): they belong to the one writer the caller opened.

**Managing** (Bearer, permission `articles.create`, rate limit `writes` on writes)

| Method | Path | Body → Response |
|---|---|---|
| GET | `/me/categories` | → `WriterCategoryListDto`: all your categories in your order, **empty ones included**, and `uncategorizedCount` as on your profile. For your own Categories tab (the manage view) and the editor's picker |
| POST | `/me/categories` | `{ name }` → `201 WriterCategoryDto`, added last. `400 category.limit` (50 per writer; it holds when several creates arrive at once, as they run one after the other), `409 category.name_taken`, `400 validation.failed` with `errors.name: ["category.name_invalid"]` |
| PATCH | `/me/categories/{id}` | `{ name }` → `200 WriterCategoryDto`. Renames; the slug stays, so links keep working. Same name errors; another spelling of its own name (e.g. its case) is fine |
| DELETE | `/me/categories/{id}` | → `204`. Its articles stay published and become uncategorized (drafts too). Confirm first with the category's `articleCount` from the list ("القسم ده فيه {n} مقالات") |
| PUT | `/me/categories/order` | `{ categoryIds: string[] }` → `200 WriterCategoryListDto` (as `GET /me/categories`). Your categories in the order sent; ids that aren't your categories are ignored, a repeat counts once, and categories left out keep their order after the listed ones (so a list from another device never fails). `400 validation.failed` with `errors.categoryIds`: `validation.required` (missing) or `category.limit` (more than 50 ids) |
| PUT | `/articles/{id}/category` | `{ categoryId: string \| null }` → `204`. Puts your article (draft or published) in that category, or in none with `null`. Applies at once: no publish, no revision, and the working copy's `version` doesn't change (the category isn't part of `ArticleDraftDocument`). Idempotent. `404 article.not_found`, `403 article.not_owner`, `404 category.not_found`, `403 category.not_owner` |

`404 category.not_found` for an unknown id and `403 category.not_owner` for another writer's category, on `PATCH`,
`DELETE` and `PUT /articles/{id}/category` (the order call ignores such ids).

**Names.** Cleaned like tag names (Tags, rule 1, but a leading `#` stays): invisible format characters (Unicode `Cf`)
and control characters are removed, the name is trimmed, every run of whitespace becomes one space, and Arabic-Indic
digits become `0–9`. Then it needs 1–40 characters (UTF-16 code units, i.e. JS / Dart `length`) and at least one letter
(tatweel `ـ` doesn't count) or digit; otherwise `category.name_invalid`. Other characters (punctuation, symbols, emoji)
are allowed: a name is plain text, never markup, on one line. Two names are the same (`409 category.name_taken`, per
writer) when they are equal after tag rule 3 (lower case + the §22 Arabic normalization), so `AI` and `ai` clash. The
name keeps the writer's spelling. Clients run the same checks before sending, with inline messages.

**Slugs** are made once, when the category is created, from its name with tag rule 4 (`C#` → `csharp`,
`نصايح البرمجة` → `نصايح-البرمجة`); a clash with another of the writer's slugs gets `-2`, `-3`, …. Renaming never changes
the slug; only a moderator's clear (Reports and moderation, `clear_category`) does.

**The editor.** `ArticleEditDto.categoryId` is the article's category (`null`: none), in every editor answer. It is not in
`ArticleDraftDocument`, so autosave, discard, restoring a revision and publishing never change it. The picker ("القسم")
lists `GET /me/categories`, plus "＋ قسم جديد" (`POST /me/categories`, then `PUT /articles/{id}/category` with the new
id). A new article that has no id yet is saved first (`POST /articles`), then its category is set.

**The reader.** `ArticleDetailsDto.category` is `{ slug, name }` or `null`; the author row shows "في قسم {name}" /
"In {name}", linking to `/@{author.username}/c/{slug}` (mobile `/u/{username}/c/{slug}`).

**Caching.** The public list, the page header and the guests' article pages are cached on the server like tag pages,
and dropped when a category is created, renamed, reordered, deleted or cleared by a moderator, when an article's
category changes, on publish, Update, hide/unhide and delete of the writer's articles, and when the fields change (an
article in a disabled field isn't counted). The reader's cached details
(`category`) are dropped with them. `GET /me/categories` is never cached.

**Account deletion (SPEC §9.6).** The writer's categories are deleted with the account; the articles that stay lose
their category.

**Moderation.** An offensive name is handled by reporting the user (F22). The user's case
(`GET /moderation/reports/user/{id}`) lists all their categories in `categories`, and a moderator clears one with
`POST /moderation/actions` `{ action: "clear_category", targetType: "user", targetId: <the writer's id>, categoryId }`
(see Reports and moderation).

Writer category error codes: `category.not_found` (404), `category.not_owner` (403), `category.limit` (400; also a
validation code on `categoryIds`), `category.name_taken` (409), `category.name_invalid` (a validation code in
`errors.name`).

### Live counters (F27, SPEC §21.2)

After a reaction, save, comment or repost change commits, an outbox handler recomputes that article's counters from SQL
(idempotent: always recounted, never incremented), stores them on `Articles` (`ReactionCount` = the sum of the four
per-type columns, `SaveCount`, `CommentCount`, `RepostCount`), refreshes the cached details and writes
`/live/articles/{id}` through `IRealtimePublisher`:
`{ reactions: { insightful, love, fire, mindBlown }, commentCount, saveCount, repostCount, updatedAt }` (published
articles only). `repostCount` is new with F29: clients that don't see it yet (an article not touched since) keep the
REST value.
Clients apply their own action optimistically, and when live counters arrive they **replace** the numbers (never add),
so your own action is never counted twice. Feed cards subscribe only while visible; the reader while open.

| Method | Path | Auth | Response |
|---|---|---|---|
| POST | `/admin/realtime/rebuild-counters` | Bearer, `system.settings` | → `200 { articleCount }`: every article's counters (reposts included) recomputed from SQL and republished |

### Editor (F05; Bearer, permission `articles.create`, rate limit `writes` on writes) — see [ADR 0015](../adr/0015-open-publishing-and-the-editor.md)

Anyone publishes in any field; there is no review and no scheduling. The editor edits one **working copy** per article,
the whole `ArticleDraftDocument`, and publishing applies it. Readers only ever see the published version.

| Method | Path | Body → Response |
|---|---|---|
| GET | `/me/articles?status=draft\|published&cursor=&limit=20` | → `CursorPage<MyArticleDto>`. Drafts: never published, latest edit first. Published: newest publish first. `400 article.status_invalid` |
| POST | `/articles` | `ArticleDraftDocument` → `201 ArticleEditDto`: a new, never-published draft |
| GET | `/articles/{id}/edit` | → `ArticleEditDto` (the author only; `404 article.not_found` for anyone else) |
| PUT | `/articles/{id}/draft` | `{ baseVersion: number, document: ArticleDraftDocument }` → `ArticleEditDto`. Autosave: replaces the whole working copy. `409 article.draft_conflict` when `baseVersion` is not the current `version` |
| DELETE | `/articles/{id}/draft` | → `ArticleEditDto`: "Discard changes" of a published article (the working copy goes back to what readers see). `409 article.not_published` for a draft |
| POST | `/articles/{id}/publish` | `{ baseVersion: number }` → `PublishedArticleDto`. First publish, or "Update" of a published article. `400` with the first problem's code and every problem in `problems: DraftProblemDto[]`; `409 article.draft_conflict` |
| GET | `/articles/{id}/revisions` | → `ArticleRevisionDto[]`, newest first (one per publish) |
| GET | `/articles/{id}/revisions/{number}` | → `ArticleRevisionDetailsDto` (for its preview). `404 article.revision_not_found` |
| POST | `/articles/{id}/revisions/{number}/restore` | `{ baseVersion: number }` → `ArticleEditDto`: the revision becomes the working copy (live after the next publish) |
| DELETE | `/articles/{id}` | → `204`. Own articles only (`403 article.not_owner`). Its working copy, revisions and the uploads only they used are deleted too |

**Saving is lenient, publishing is strict.** Saving never fails because the article is unfinished: an empty title, no
field, an image block with `alt: ""`, attachments still processing or a block the RDoc schema rejects all come back in
`checks.problems`. Only a malformed body is a `400 validation.failed`: more than 2 versions, duplicate languages,
`sourceLanguage` not among them, `content` that is not an RDoc object in that language, more than 2000 blocks, more than
5 tags, 30 sources or 10 attachments, a new tag name that breaks the tag rules (see Tags), too-long strings, non-http(s)
URLs. Publishing re-runs the checks and fails while any problem remains.

- `version` starts at 1 and goes up with every save, discard and restore; a publish doesn't change it. An article
  created before the editor has `version: 0` until its first save.
- After a publish `hasUnpublishedChanges` is `false`; the next save of a published article makes it `true`.
- The slug is assigned at the first publish from the source title and never changes; `slug` is `null` before that.
- Image block `src` and `coverUrl`: send the URL an upload returned (any variant). The API stores its own upload URLs as
  relative paths / `rdoc-asset://` and always answers with public URLs (ADR 0010).
- Attachments are part of the document (there is no attachments call). They go live with the publish; a PDF's `title`
  and `allowDownload` are applied to its asset then.
- The writer's **category** (F31) is not part of the document: `ArticleEditDto.categoryId`, changed at once with
  `PUT /articles/{id}/category` (see Writer categories).
- **Mentions** (RDoc `mention` nodes, `{ type: "mention", userId, text }`; pick people with `GET /users/mention-suggestions`):
  autosave keeps them as written. Every publish and "Update" checks each one, in every language version, against the
  author ("who you may mention", see Comments): an allowed, active user keeps the node with `text` set to
  `"@" + their current username` (readers link a mention by its text); anyone else, an unknown `userId`, a deleted or a
  suspended account becomes a plain `text` node with the same text (no link). What readers, the working copy and the
  revision get is the checked version. Newly mentioned users get a `mention` notification (see Notifications).

### Article PDF (F33) — SPEC F33

Bearer, permission `articles.export_pdf` (every account, SPEC §10.2), on any article you can open (user decision
2026-11-06: not only the writer).

The Arabic client texts quoted in this section are the mobile app's (Egyptian). The web shows them in Modern Standard
Arabic (SPEC §14.4): see the table after "Errors and what clients show". The file's own texts are the same for both.

| Method | Path | Response |
|---|---|---|
| GET | `/articles/{id}/pdf?lang=` | → `200 application/pdf`: the article's **published** version in one language as a PDF, built in the request and never stored (A4, always the light theme, the ReadIn logo). Errors below are ProblemDetails JSON, as everywhere |

**Who, which article, which version**
- `{id}` is the article id (`ArticleDetailsDto.id`, `MyArticleDto.id`).
- **Any signed-in member**, for any **published** article the reader opens for them (published, in an enabled field,
  not deleted, not hidden), whoever wrote it. Every member gets the same file: the writer's name, never the caller's.
  A deleted account's kept article prints "مستخدم محذوف" / "Deleted user" with no profile link.
- **Archived:** the author only. Anyone else gets `404 article.not_found`.
- **Hidden by moderators (F22):** the author gets `409 article.pdf_hidden` (below); **everyone else**, moderators and
  SuperAdmin included, gets `404 article.not_found`.
- An unknown or deleted article and a draft (never published) are `404 article.not_found` for everyone. Guests (no
  token) get `401 auth.unauthorized`.
- Clients show "Download PDF" (web "تنزيل PDF", mobile "تحميل PDF") in the reader's "⋯" menu (F28) on **every**
  article, your own included, and to guests too, who get the usual sign-in prompt instead of a request. A moderator
  reading someone else's hidden article (`ArticleDetailsDto.moderation` set, not your article) gets no item, since the
  answer would be `404`. My articles keeps the action on each article of the **Published** tab
  (`MyArticleDto.status === 'published'`), never on drafts.
- The file is always the **published** version, even while the working copy has unpublished changes
  (`hasUnpublishedChanges`); a member who isn't the writer never gets anything of the working copy.
- `lang` (`ar-EG` | `en`) is the version to print. **Reader:** `ArticleDetailsDto.language`, the version on screen.
  **My articles:** `MyArticleDto.publishedLanguages` (added in F33), the published versions with the source language
  first: one entry → send it without asking; two → ask which first ("أنهي نسخة؟"), in that order. A missing, unknown or
  unpublished `lang` prints the source language, as on the other article endpoints; the file name says which one.
- Hidden by moderators (F22), to its author: `409 article.pdf_hidden`, because the file carries the ReadIn logo.
  Clients still show the item to the author (My articles doesn't know it's hidden); the message explains.

**The 200 response**
- `Content-Type: application/pdf`, `Content-Length`, `X-Content-Type-Options: nosniff`, `Cache-Control: private, no-store`
  and `Content-Disposition: attachment; filename="readin-article.pdf"; filename*=UTF-8''{slug}-{lang}.pdf`.
  CORS exposes `Content-Disposition` to the web origin.
- **File name** `{slug}-{lang}.pdf`: the article's slug and the printed language, e.g. `clean-code-en.pdf`,
  `article-1a2b3c4d-ar-EG.pdf`. `filename*` is RFC 5987 (UTF-8, percent-encoded), so any slug works, Arabic included
  (today's slugs are ASCII: the title's Latin words, else `article-xxxxxxxx`): clients take the name from `filename*`
  (percent-decode the part after `UTF-8''`). `filename` is always the ASCII fallback `readin-article.pdf`, used only
  when `filename*` is missing or doesn't decode.
- **Web:** a normal download: fetch with the Bearer token → blob → an object URL on `<a download="{name}">`, clicked,
  then revoked. **Mobile:** write the bytes to a temp file named `{name}` and open the system share sheet
  (`share_plus`), so the user saves or sends it; no storage permission.
- A typical article is under 5 MB.

**Time and limits** (all counted per API instance)
- A request may wait up to 30 s for a build slot, then the build has up to 60 s. Give this call a receive timeout of at
  least **100 s** (not the client's default). While it runs, the item shows "بنجهز الـ PDF…" / "Preparing the PDF…",
  disabled, with a spinner; a second tap does nothing.
- At most 2 builds at a time; a request that gets no slot within 30 s: `503 article.pdf_busy`.
- A build that fails or takes more than 60 s: `500 article.pdf_failed` (a crashed Chromium is restarted).
- 10 requests per user per hour: `429 article.pdf_limit`. ASP.NET Core's rate limiter, partitioned by user: a fixed
  one-hour window from the user's first request; every request counts whatever its answer, except the 429s. The count is
  in memory, so it is per API instance (with several instances a user can get more) and starts over when the API
  restarts. It runs before the other checks, so a limited user gets `429` for any article.

**Errors and what clients show** (other codes, e.g. `403 user.suspended`, keep their usual messages)

| Status and code | When | Clients show (ar / en) | "حاول تاني" / "Try again" |
|---|---|---|---|
| `401 auth.unauthorized` | not signed in, token expired | the usual refresh, then sign-in flow | — |
| `404 article.not_found` | unknown, deleted, a draft; someone else's archived or hidden article | "المقال مش موجود." / "Article not found." | no |
| `409 article.pdf_hidden` | your own article, hidden by moderators | "المشرفين خفّوا المقال ده، فمينفعش يتحمّل PDF." / "Moderators hid this article, so it can't be downloaded as a PDF." | no |
| `429 article.pdf_limit` | more than 10 in the hour | "حمّلت PDFs كتير الساعة دي. حاول تاني بعد شوية." / "You've downloaded many PDFs this hour. Try again later." | yes |
| `503 article.pdf_busy` | no build slot within 30 s | "فيه PDFs كتير بتتجهز دلوقتي. حاول تاني كمان شوية." / "Many PDFs are being prepared right now. Try again in a moment." | yes |
| `500 article.pdf_failed` (and `server.error`, a client timeout, any other failure) | the build failed or took too long | "معرفناش نجهّز الـ PDF. حاول تاني." / "We couldn't prepare the PDF. Try again." | yes |
| no connection (client side) | offline before or during the call | "محتاج إنترنت عشان تحمّل الـ PDF." / "You need an internet connection to download the PDF." | yes |

The Arabic in the table is the mobile app's (Egyptian). The web shows the same texts in Modern Standard Arabic
(SPEC §14.4), with the same English:

| Where | Web (ar) |
|---|---|
| the item; while it builds; the retry button | "تنزيل PDF"; "جارٍ تجهيز ملف PDF…"; "إعادة المحاولة" |
| My articles, two published versions | "أي نسخة تريد؟" |
| `404 article.not_found` | "المقال غير موجود." |
| `409 article.pdf_hidden` | "أخفى المشرفون هذا المقال، لذا لا يمكن تنزيله بصيغة PDF." |
| `429 article.pdf_limit` | "نزّلت ملفات PDF كثيرة خلال هذه الساعة. حاول مرة أخرى لاحقًا." |
| `503 article.pdf_busy` | "يجري الآن تجهيز ملفات PDF كثيرة. حاول مرة أخرى بعد قليل." |
| `500 article.pdf_failed` and any other failure | "تعذّر تجهيز ملف PDF. حاول مرة أخرى." |
| no connection | "تحتاج إلى اتصال بالإنترنت لتنزيل ملف PDF." |

**What the file holds** (the full layout is SPEC F33): A4 portrait, always light; direction from the article language
(`ar-EG` RTL, `en` LTR), not the app's; the logo at the top of page 1 and in every page's footer with `readin.app` and
`2 / 5`; the title, the writer with the verified badge, publish date, reading time, the AI-assisted label ("بمساعدة AI" /
"AI-assisted", SPEC §20) when the article has it, field and topic, tags, the health disclaimer for sensitive fields and
the cover; the content; then attachments, Sources and "منشور على ReadIn" /
"Published on ReadIn" with the article's link. No comments, reactions, counters, related articles, highlights or app
buttons. Real, selectable text with clickable links and embedded fonts; a tagged PDF with bookmarks from H2/H3 and the
title, author and language in its metadata. The server fetches nothing remote: images come from its own uploads (the
1600 variant; the cover's 1200), an image block whose `src` isn't a ReadIn upload prints as a card with its alt text or
caption and its link, and embeds become link cards.

Article PDF error codes: `article.pdf_hidden` (409), `article.pdf_busy` (503), `article.pdf_failed` (500),
`article.pdf_limit` (429).

### Quote card (F24) — SPEC F24

🌐 Bearer optional, permission `articles.read` (guests have it). Rate limit `quote-card`: 30 cards per hour per user,
guests per IP address. See [ADR 0019](../adr/0019-quote-cards-drawn-by-the-server.md).

| Method | Path | Body → Response |
|---|---|---|
| POST | `/articles/{id}/quote-card` | `QuoteCardRequest` → `200 image/png`: a picture of the selected text for social media, drawn by the server with the F33 headless Chromium and never stored. Errors below are ProblemDetails JSON, as everywhere |

```ts
interface QuoteCardRequest {      // POST /articles/{id}/quote-card; {id} = ArticleDetailsDto.id
  language: ArticleLanguage;      // the version on screen (ArticleDetailsDto.language)
  blockId: string;                // the F30 selection range, exactly as for POST /articles/{id}/highlights
  startOffset: number;            // UTF-16 code units in the block's plain text, end exclusive
  endOffset: number;
  text: string;                   // exactly plainText.slice(startOffset, endOffset)
  theme: 'light' | 'dark';
  format: 'square' | 'landscape'; // 1080 × 1080 px | 1200 × 630 px
}
```

**The selection.** The same `{ blockId, startOffset, endOffset, text }` the reader computes for **Highlight** (Highlights
(F30) → Offsets; [`shared/rdoc/highlight-fixtures.json`](../../shared/rdoc/highlight-fixtures.json)): offsets in the
block's plain text, the selection clipped to the first block (list: item) it touches, whitespace trimmed at both ends.
The same blocks as Highlight: paragraph, heading, list items, quote, callout, summary; never code, code tabs, table,
steps, image, divider or embed (no **Share quote** button there). Length after trimming: **3–400** code units (a
highlight may be up to 1,000). Clients check before calling: under 3 → no button; over 400 → show `quote.too_long`
without calling. The server checks everything again against the version's current text (as for a highlight), so a card
never shows words the article doesn't have. It draws the trimmed text.

**Who and which article.** Like the reader: guests and members, on any published article they can open.
- Unknown, unpublished (draft, archived) and deleted articles: `404 article.not_found`.
- Hidden by moderators (F22): `404 article.not_found` for everyone but its author and moderators, who get
  `409 quote.hidden` (the card carries the ReadIn logo). Clients hide **Share quote** while
  `ArticleDetailsDto.moderation` is set.
- A `language` the article has no version in: `400 quote.text_mismatch` (clients always send the version on screen).

**Checked in this order**
1. The rate limit: `429 quote.limit` (below).
2. A malformed body is `400 validation.failed`: `language` (`validation.required`, `article.language_invalid`),
   `blockId` (`validation.required`, `validation.invalid` when it isn't `^[A-Za-z0-9_-]{1,64}$`), `startOffset` and
   `endOffset` (`validation.required`, `validation.invalid` for a negative offset or `endOffset ≤ startOffset`), `text`
   (`validation.required`), `theme` and `format` (`validation.required`, `validation.invalid` for another value).
3. `404 article.not_found`, then `409 quote.hidden`, as above.
4. `400 quote.text_mismatch` when the version or the block isn't there; `400 quote.block_not_allowed` for a code, code
   tabs, table, steps, image, divider or embed block (whatever the offsets and text).
5. `400 quote.text_mismatch`: an offset falls past the block's text or inside a surrogate pair, the range crosses a list
   item, or `text` isn't exactly the text at those offsets. Usually the author updated the article meanwhile: reload it.
6. Whitespace at both ends is trimmed; `400 quote.too_short` below 3 code units, `400 quote.too_long` above 400.
7. Drawing: `503 quote.busy`, `500 quote.failed` (below).

**The 200 response**
- `Content-Type: image/png`, exactly **1080 × 1080** (square, for Instagram and WhatsApp) or **1200 × 630** (landscape,
  for X, Facebook and LinkedIn) pixels; usually 30–150 KB.
- `Content-Disposition: inline; filename="readin-quote.png"; filename*=UTF-8''readin-quote-{slug}.png`: RFC 5987, as the
  PDF (take the name from `filename*`, percent-decoded; `readin-quote.png` is the ASCII fallback). CORS exposes
  `Content-Disposition` to the web origin.
- `Cache-Control: private, max-age=600` and `X-Content-Type-Options: nosniff`. HTTP caches never keep a POST answer, so
  clients keep the images of the open sheet in memory (keyed by the whole request) and reuse them when the user switches
  back to a theme or format; **Share** and **Save** use the bytes already shown, with no new call.

**What the card shows.** Its direction is the one the reader gives the quoted block (§14.2 rule 1: the block's
explicit `dir`, else its first strong character with inline code skipped, else the article language), not the quote's
own first strong character: an Arabic sentence selected from its English term on ("ASP.NET Core، أكيد شفت …") still reads
right to left. Its words come from the article language ("مستخدم محذوف" / "Deleted user"), not the app's.
- The quote, large, under a quotation mark; mixed Arabic/English isolated as in the reader (§14.2); hard breaks stay
  line breaks. A long quote gets a smaller font, down to a readable minimum, and is **never cut**; if it still doesn't
  fit, its line breaks become spaces, and only text nobody selects to share (e.g. 400 wide letters without a space) goes
  below that size.
- The article's title in that version (at most 2 lines on a square card, 1 on a landscape one, then "…"), and the
  writer's display name with the verified badge (`isVerified`), or "مستخدم محذوف" / "Deleted user" for a deleted
  account. No photo, counters or other data.
- The ReadIn logo (the approved lockup; its dark version on dark cards) and the article's link without `https://`,
  e.g. `readin.app/en/a/clean-code`: the F24 share link `{web origin}/{ar|en}/a/{slug}` of the quoted version.
- Light or dark colours from §15.2, the §15.3 fonts (with Noto fallbacks, emoji and symbols) shipped with the API.

**Time and limits** (all counted per API instance)
- The cards share the F33 Chromium and its build slots: at most 2 PDFs and cards are drawn at a time. A card waits up
  to 10 s for a slot (`503 quote.busy`) and then has 20 s (`500 quote.failed`); it usually takes well under a second.
  Give the call a receive timeout of at least **40 s**. While it loads, the sheet shows a box of the card's shape with a
  spinner, and the theme/format switches and **Share** / **Save** stay usable for the images already loaded.
- 30 cards per hour per user, guests per IP address: `429 quote.limit`. ASP.NET Core's rate limiter, a fixed one-hour
  window from the first request; every request counts whatever its answer, except the 429s. The count is in memory, so
  it is per API instance and starts over when the API restarts. It runs before every other check.

**Errors and what clients show** (other codes, e.g. `403 user.suspended`, keep their usual messages)

| Status and code | When | Clients show (ar / en) | "حاول تاني" / "Try again" |
|---|---|---|---|
| `400 validation.failed` | a malformed body (a client bug) | the generic error message | no |
| `404 article.not_found` | unknown, unpublished, deleted, or hidden from you | "المقال مش موجود." / "Article not found." | no |
| `409 quote.hidden` | hidden by moderators (you are its author or a moderator) | "المشرفين خفّوا المقال ده، فمينفعش تشارك منه اقتباس." / "Moderators hid this article, so its quotes can't be shared." | no |
| `400 quote.text_mismatch` | the text changed, or the range is wrong | "النص ده اتغيّر في المقال. حدّث الصفحة وجرّب تاني." / "This text has changed in the article. Reload and try again." | no |
| `400 quote.block_not_allowed` | code, table, steps, image, divider or embed | "مينفعش تشارك الجزء ده كاقتباس." / "This part can't be shared as a quote." | no |
| `400 quote.too_short` | under 3 characters after trimming | "اختار 3 حروف على الأقل." / "Select at least 3 characters." | no |
| `400 quote.too_long` | over 400 characters after trimming | "الاقتباس لازم يكون 400 حرف أو أقل. اختار جزء أصغر." / "A quote can be at most 400 characters. Select less text." | no |
| `429 quote.limit` | more than 30 in the hour | "عملت كروت اقتباس كتير الساعة دي. حاول تاني بعد شوية." / "You've made many quote cards this hour. Try again later." | yes |
| `503 quote.busy` | no build slot within 10 s | "فيه كروت كتير بتتجهز دلوقتي. حاول تاني كمان شوية." / "Many cards are being prepared right now. Try again in a moment." | yes |
| `500 quote.failed` (and `server.error`, a client timeout, any other failure) | drawing failed or took over 20 s | "معرفناش نجهّز كارت الاقتباس. حاول تاني." / "We couldn't prepare the quote card. Try again." | yes |
| no connection (client side) | offline before or during the call | "محتاج إنترنت عشان تعمل كارت اقتباس." / "You need an internet connection to make a quote card." | yes |

The Arabic above is the mobile app's; the web says the same in Modern Standard Arabic (SPEC §14.4), e.g. «تغيّر هذا
النص في المقال. حدّث الصفحة وحاول مرة أخرى.» and «إعادة المحاولة». On `quote.text_mismatch` both clients load the
article and its highlights again, as for `highlight.text_mismatch`. Both sheets offer **Share**, **Download** (web) /
**Save** (mobile) and **Copy link**.

Quote card error codes: `quote.text_mismatch`, `quote.block_not_allowed`, `quote.too_short`, `quote.too_long` (400),
`quote.hidden` (409), `quote.limit` (429), `quote.busy` (503), `quote.failed` (500).

### Media (Bearer) — see [ADR 0011](../adr/0011-media-pipeline-and-pdf-preview.md)

| Method | Path | Body → Response |
|---|---|---|
| POST | `/uploads/images` | `multipart/form-data`: `file` (jpeg/png/webp/heic, ≤ 10 MB, ≤ 8000×8000), `purpose` = `image` (default) \| `avatar` \| `cover` → `201 MediaAssetDto` with `status: "ready"` (images are processed in the request) |
| POST | `/uploads/documents` | `multipart/form-data`: `file` (PDF, ≤ 20 MB, ≤ 100 pages, no password), `title` (optional, ≤ 5000, defaults to the file name), `allowDownload` (`true`/`false`, **default `true`** when omitted, pre-production step; send `false` to turn it off) → `202 MediaAssetDto` with `status: "processing"` and `pageCount` set. Pages are rendered in the background, page 1 first |
| GET | `/uploads/{id}` | → `200 MediaAssetDto` (owner only). Poll every 2 s while `status` is `processing` |
| DELETE | `/uploads/{id}` | → `204` (owner only; `409 media.in_use` while attached to an article or in an editor working copy) |
| GET | `/documents/{assetId}/download` 🌐 | → `200 application/pdf` with `Content-Disposition: attachment`. Allowed when the article is published and `allowDownload` is on, or for the owner / a moderator. `403 media.download_not_allowed`, `404 media.not_found` |

Uploaded files are public, immutable `.webp` URLs under `/uploads/...` (absolute URLs in every DTO). PDFs are never served from `/uploads`.

**Allow download (F26, pre-production step).** "السماح بتحميل الملف" / "Allow download" is **on by default**: both
composers start the toggle on and send `allowDownload` with the upload (and in the draft's `DraftAttachment`), and the
API takes `true` when the upload omits it. The writer can turn it off (`false`). `DraftAttachment.allowDownload` omitted
keeps the asset's value. Documents uploaded before keep the value they have. A document's `canDownload` (owner,
moderators, or `allowDownload`) shows the download icon in the PDF's title strip on the card and in the full-screen
viewer; it calls `downloadUrl` (`GET /documents/{assetId}/download` → `Content-Disposition: attachment`).

Quotas: 50 uploads per user per day (`409 media.quota_daily`), 200 MB stored per user (`409 media.quota_storage`).

- **Uploads per day (leftovers step):** every upload the API accepted (`201` / `202`) in the last 24 hours (rolling)
  counts, **also the ones deleted since** (`DELETE /uploads/{id}`, the orphan cleanup, a deleted draft or article), so
  deleting doesn't free the allowance. A rejected file (wrong type, too large, encrypted, a quota error) doesn't count.
  Images and PDFs share the 50.
- **Storage:** only what is still stored counts (original PDF, pages and image variants), so deleting frees space.
- Both are checked before any work is done; the error texts are unchanged.

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
| `/live/articles/{articleId}` | 🌐 | `reactions: { insightful, love, fire, mindBlown }`, `commentCount`, `saveCount`, `repostCount` (F29), `updatedAt` (server time). Totals, not deltas. Listen to the four counter children rather than the node, so `events` isn't downloaded |
| `/live/articles/{articleId}/events/{pushId}` | 🌐 | `{ type, commentId, parentId?, at }`: `type` is `comment.created` \| `comment.updated` \| `comment.deleted` \| `reply.created` \| `comment.liked` \| `comment.pinned`; `at` is server time, so query `orderByChild('at').startAt(serverNow)`. A retried write can repeat an event |
| `/live/feed/latestPublishedAt` | 🌐 | Publish time of the newest article the feed can show. Higher than when the feed was loaded → show "مقالات جديدة ↑" |
| `/live/users/{userId}` | that user (custom token) | `unreadNotifications` (entries not seen yet, the same number as `GET /me/notifications/unread-count`), `lastNotificationAt` (latest activity, epoch ms; missing when there is none). Written after every new entry, seen, read and read-all (F17) |
| `/live/users/{userId}/media/{assetId}` | that user (custom token) | `{ status: processing \| ready \| failed, pagesReady, pageCount, failureReason, updatedAt }` while a PDF renders. Polling `GET /uploads/{id}` stays the contract |

### Reading & streaks (Bearer) — see [ADR 0013](../adr/0013-reading-days-and-streaks.md)

| Method | Path | Body → Response |
|---|---|---|
| PUT | `/articles/{id}/progress` | `ReadingProgressRequest` → `200 ReadingProgressResultDto`. Completes the article at `percent ≥ 70` and ≥ 30 credited seconds. Seconds are credited up to the time that really passed since the previous report (+10 s, ≤ 600); the first report credits none. `404 article.not_found` (not published), `409 reading.conflict` (a parallel report: send it again), `429` above 60 reports a minute |
| GET | `/me/stats` | → `200 ReadingStatsDto` (owner only) |
| GET | `/me/stats/heatmap?days=` | → `200 ReadingHeatmapDto`. `days` 1–371, default 365 |

Readers report on open (`activeSecondsDelta: 0`), every 15 s while the article is visible and the user was active in the
last 60 s, and when they leave. A failed report keeps its seconds for the next one. Guests don't report.

**Resume (F04).** `lastPosition` is the scroll position as a fraction of the article's scrollable range, written with
four decimals (`"0.4523"`), on web and mobile alike. `ArticleDetailsDto.myProgress` gives it back to the signed-in
reader. On open, the reader scrolls back to it when all of these hold: `myProgress` is set, `completedAt` is null, its
`language` is the version being shown, the link has no block anchor, the value is between 0.05 and 0.95, and the
reader hasn't scrolled yet. It then shows a toast ("كمّلنا من مكان ما وقفت" / "Picked up where you left off") with a
"Start over" action that scrolls to the top.

### Glossary (F21) 🌐

| Method | Path | Response |
|---|---|---|
| GET | `/glossary/{slug}?lang=` | `GlossaryTermDto`. `slug` is the RDoc `term` node's `termId`. `lang` is the version being read and picks the titles of `articles`. `404 glossary.term_not_found` |
| GET | `/glossary?q=&limit=` | `GlossaryTermSummaryDto[]`: matches on the English term or the slug, those starting with `q` first, then A–Z. `limit` 1–50, default 20; an empty `q` lists from A. For the editor's term picker |

Glossary terms come from `content/glossary/*.yaml`; there are no write endpoints yet.
### Continue reading (F03; Bearer)

| Method | Path | Body → Response |
|---|---|---|
| GET | `/me/continue-reading?limit=` | → `200 ContinueReadingDto[]`, most recently read first. `limit` 1–10, default 3. Unfinished articles (`completedAt` null) with `percent ≥ 5`, reported in the last 30 days, that a reader can still open. Each card is in the version you were reading |

Home shows the first item whose article isn't today's hero article. Tapping it opens the normal article page in that
`language`; the reader resumes from your `lastPosition`.

### Learning paths (F09) 🌐 (Bearer optional)

| Method | Path | Body → Response |
|---|---|---|
| GET | `/paths?field=` | → `200 PathCardDto[]`: published paths in editorial order. `field` = field slug. Signed in: `progress` and `enrollment` are filled |
| GET | `/paths/{slug}` | → `200 PathDetailsDto`. `404 path.not_found` (unknown, unpublished, or no article a reader can open) |
| GET | `/articles/{id}/path` | → `200 ArticlePathDto` or `204` when the article is in no published path; `404 article.not_found`. The "Next in path" block at the end of the reader |
| GET | `/users/{username}/paths` | → `200 PathCardDto[]`: that user's enrolled paths (in progress first, then completed), with **their** progress. `403 profile.stats_private` unless it's your own profile or the user turned on `publicReadingStats` (as `/users/{username}/stats`; `ProfileDto.readingStatsVisible` tells you up front). `404 user.not_found` |

Only articles a reader can open count: `articleCount`, positions (1..N, no gaps) and progress skip unpublished ones.
"Read" is the F04 rule (`ReadingProgress.completedAt`), so progress also counts articles read before enrolling.

### My paths (F09; Bearer, rate limit `writes` on writes)

| Method | Path | Body → Response |
|---|---|---|
| GET | `/me/paths` | → `200 PathCardDto[]`: your enrolled paths. In progress first (latest activity first), then completed (latest completion first) |
| GET | `/me/paths/active` | → `200 PathCardDto` (with `progress.next`) or `204` when no enrolled path has an unread article. The Home "learning path" card |
| PUT | `/me/paths/{pathId}` | → `200 PathCardDto` (enroll; idempotent). Already read everything → `enrollment.completedAt` is set at once. `404 path.not_found` |
| DELETE | `/me/paths/{pathId}` | → `204` (leave; idempotent). Reading history stays; enrolling again shows the same progress |

Reading one of the path's articles moves its "latest activity" (which path is active) and, once every article is read,
sets `enrollment.completedAt` (the completion badge) a moment later (outbox). The badge stays when the path grows later.
Today's article (F07) is the active path's next unread article, unless that would make 3 days in a row of one field.

### Path admin (F09; Bearer, permission `paths.manage`, rate limit `writes`)

The screens are in the F23 Admin Console (web). Every write is audited (`admin.path_created`, `admin.path_updated`,
`admin.path_items_set`, `admin.path_deleted`) and drops Explore's cache. Featured paths: `PUT /admin/paths/featured`
(`articles.feature`, "Admin console (F23)" → "Paths and featured").

| Method | Path | Body → Response |
|---|---|---|
| GET | `/admin/paths` | → `200 AdminPathDto[]` (every path, unpublished included, editorial order) |
| POST | `/admin/paths` | `UpsertPathRequest` → `201 { id, slug }`. `409 path.slug_taken`, `404 field.not_found`, `400 path.items_invalid` when `isPublished` (a new path has no items yet) |
| PUT | `/admin/paths/{id}` | `UpsertPathRequest` → `204`. Publishing needs at least one item (`400 path.items_invalid`). `409 path.editorial`, `409 path.slug_taken`, `404 path.not_found` |
| PUT | `/admin/paths/{id}/items` | `{ articleIds: string[] }` (1–100, no repeats, articles a reader can open; order = array order) → `204`. `400 path.items_invalid`, `409 path.editorial` |
| DELETE | `/admin/paths/{id}` | → `204` (idempotent; its enrollments go with it). `409 path.editorial` |

Editorial paths come from `content/taxonomy.yaml` (`learningPaths` + each article's `learningPath`) and are managed
there (seeder #7); every admin write to one is `409 path.editorial`.

Path error codes: `path.not_found` (404), `path.slug_taken` (409), `path.editorial` (409), `path.items_invalid` (400).

### Sitemap (SPEC §23) 🌐

| Method | Path | Response |
|---|---|---|
| GET | `/sitemap` | `200 SitemapDto`: every page a guest can open, for the web's `/sitemap.xml`. Cached 30 minutes; a publish, edit, hide or delete clears it |

```ts
interface SitemapDto {
  /** One entry per language version of each article readers can open, newest first (at most 40,000 articles). */
  articles: { slug: string; language: 'ar-EG' | 'en'; lastModified: string }[];
  /** Writers with at least one such article who aren't suspended; lastModified = their newest article. */
  writers: { username: string; lastModified: string }[];
  /** Their categories (F31) with at least one such article. */
  categories: { username: string; slug: string; lastModified: string }[];
  fields: { slug: string; lastModified: null }[];             // enabled fields
  tags: { slug: string; lastModified: string | null }[];      // not hidden, with at least one such article
  paths: { slug: string; lastModified: string | null }[];     // published, with at least one such article
}
```

The web's SSR server builds the URLs (`web/src/server/sitemap.ts`): `/sitemap.xml` is an index of `/sitemap-ar.xml`,
`/sitemap-en.xml` (the article versions, `/{ar|en}/a/{slug}`) and `/sitemap-pages.xml` (home, Explore, `/paths`,
`/@{username}`, `/@{username}/c/{slug}`, `/f/{slug}`, `/tags/{slug}`, `/paths/{slug}`); it also serves `/robots.txt`.

### Admin console (F23) — SPEC F23

The SuperAdmin's console: web `/admin` (a lazy route group, `noindex`), mobile Settings → «لوحة التحكم». Every route
here needs a Bearer token (`401 auth.unauthorized` without one) and the permission on its row (`403 auth.forbidden`
without it, so for every Member); a suspended account gets `403 user.suspended` as everywhere. Reads are unthrottled;
writes use the `writes` rate limit (30 a minute). Every write is in the audit log, under the codes in "Audit actions"
below.

**Decisions** (what SPEC F23 leaves open)

1. **Permissions.** Six new codes (SPEC §10.2): `admin.access`, `users.read`, `support.create` (Member and
   SuperAdmin), `support.manage`, `notifications.broadcast` and `audit.read`. `articles.feature` (it exists) also
   covers featured paths. The roles seeder gives the SuperAdmin every permission and Members `support.create` on the
   next start. Clients show the console entry when `MeDto.permissions` holds `admin.access`, and each section and action
   when it holds that one's permission (tables below); they never test a role name.
2. **Protected accounts.** Nobody suspends, warns, signs out or hides the content of (`hide_content`) themselves
   (`400 moderation.self`), a holder of `admin.access` or `moderation.manage`, or a system account, the official
   `@readin` (`403 moderation.staff_target`). F22's "staff" (holders of `moderation.manage`) now also covers holders of
   `admin.access`. Hiding one article or comment of staff stays allowed (F22).
3. **Pages.** Admin tables use offset pages (§17.1): `?page=&pageSize=` → `PagedList<T>`. A `page` below 1 counts as
   1, and `pageSize` is clamped to 1–100 (default 50). A page past the end has `items: []` and the real `totalCount`.
   The existing cursor queues (`/moderation/*`, `/admin/verification-requests`) stay as they are.
4. **Days and periods** are calendar days in `Admin:TimeZone` (default `Africa/Cairo`). `period`: `today` = from
   today's midnight to now; `yesterday` = all of yesterday; `7d` = the last 7 days including today (from midnight 6 days
   ago to now); `30d` the same with 30. The **previous period** is the same window moved back by its length in days (1,
   1, 7 or 30), so `today` compares with yesterday up to the same time of day. Date filters (`from`, `to`,
   `joinedFrom`, …) are `YYYY-MM-DD` in that zone, both ends included.
5. **Dashboard numbers.** A **read** is the F04 rule: `ReadingProgress.CompletedAt` in the window, once per reader and
   article. **Active readers** are the distinct accounts with a read in the window. **New users** are the accounts
   created in the window, split by how they signed up: a new column `Users.SignUpMethod` (`phone` | `google` |
   `apple`), filled once for existing accounts from the audit log (an `auth.external_sign_up` entry → the provider of
   their oldest link, else `phone`). **Articles published** = a first publish (`PublishedAt`) in the window, not deleted.
   **Comments** = comments and replies written in the window and not deleted; **reactions** = reactions whose current
   type was chosen in the window (`reactedAt`); **reposts** = reposts made in the window that still exist. System
   accounts never count as users or readers. The four state cards (open reports, open tickets, pending verification
   requests, accounts suspended now) are the numbers right now and have no previous value.
6. **Streak retention** doesn't depend on `period`. The cohort is last week's active readers (a read in the 7 days
   before today); `kept` is those of them whose reading streak (`UserStats.CurrentStreak`) is 3 or more and still alive
   (they read yesterday or today). `rate` = kept ÷ cohort, `null` for an empty cohort.
7. **Last seen** lives in its own table, `UserPresence` (`UserId` → `Users`, cascade; `LastSeenAt`), not on the
   `Users` row, whose row version would make a parallel request's save fail. Any signed-in request sets it, at most once
   an hour per account (an in-memory check, then a conditional upsert): accurate to the hour, one write an hour per
   active account. It is `null` until the account's first request after F23 ships.
8. **Searches with no results** (`SearchMisses`, §22). `GET /search` records a miss when a first page (no `cursor`) of
   `type=articles` with no `field`, `minMinutes` or `maxMinutes` filter finds nothing. The query is the cleaned and
   normalized `q` (≤ 100 characters); `language` is `ar` when it holds an Arabic letter, else `en`; the date is today in
   `Admin:TimeZone`. Clients search as you type, so a miss waits 30 seconds per searcher (the user, or the IP for a
   guest) and is dropped when that searcher's next search extends it (`dock` → `docker`); a restart loses at most those
   30 seconds. No user id or IP is stored. Kept 90 days.
9. **Suspend and hide everything.** `suspend` takes `hideContent: true` to also hide all of the user's articles and
   comments in the same call. Two new user actions do it on their own: `hide_content`, and its undo `unhide_content`.
   What `hide_content` hid is flagged (`Articles.HiddenWithAccount`, `Comments.HiddenWithAccount`), so the undo brings
   back only that, never content hidden one by one before or after.
10. **Featured articles** (`Articles.FeaturedAt`). Nothing showed featured articles before F23. They now fill a new
    Explore section, `ExploreDto.featuredArticles` (≤ 6, the most recently featured first, only articles readers can
    open; `[]` when none, so clients hide it), and `ArticleDetailsDto.isFeatured` drives the article's "⋯" item. Their
    order is the time they were featured; only featured paths have a manual order.
11. **Fields and topics** (§18). The first console change to a field or topic sets its `CustomizedAt`, and from then on
    the taxonomy seeder leaves that row alone: it never renames, re-orders, disables or re-enables it. Rows nobody
    edited keep following `content/taxonomy.yaml`. The console can add fields and topics (customized from the start),
    but deletes nothing: disable instead. Slugs never change. Topics get `IsEnabled` (new): a disabled topic leaves the
    topic lists and chips, the editor's picker, onboarding and search; its articles stay in their field and keep it.
12. **Tags** (F32). Renaming keeps the slug, so links keep working. When the normalized name changes, the old spelling
    becomes an **alias** of the tag (new table `TagAliases`): writers who type it, and seed content that names it, get
    this tag, so a re-import never creates it again. Merging A into B moves A's articles to B, makes A's name and slug
    aliases of B (`/tags/{a-slug}` answers B) and deletes A. A merge can't be undone.
13. **Announcements.** "Everyone" = every active account (not suspended, not a system account) except the sender; "the
    readers of a field" = accounts that follow the field or one of its topics (their interests, F02/F12); "the readers
    of a language" = accounts whose article language is that one. Accounts that set `announcement` to `off` aren't
    counted or told; `inApp` gets no push. "One a day" is one per calendar day in `Admin:TimeZone`, held by a unique key
    so two sends at once can't both pass; tests don't count. A background job writes the entries in batches.
14. **The audit browser** merges `AuditLogs` and `ModerationActions`. It leaves out the `moderation.*` audit entries,
    because each repeats a moderation log entry, which has the label and the note. `AuditLogs` gains `TargetType`,
    `TargetId` and `Details` (≤ 500, never personal data), so taxonomy, path, announcement and ticket actions say what
    they touched.
15. **System page data.** Every Hangfire run is a row in a new `JobRuns` table (written by a server filter, kept 7
    days). Every push send adds its counts to `PushDeliveryStats`, one row per UTC hour, written by a wrapper around the
    push sender, so the F17 pushes and the daily article both count (kept 7 days). Both survive a restart. Storage is
    measured by walking the uploads folder and the private store, cached 10 minutes.
16. **The content pipeline** is part of the dashboard (`AdminDashboardDto.contentPipeline`). There is no
    `/admin/content-pipeline`.
17. **Suspended profiles.** A suspended account's profile is `404` for everyone (F14), so its "⋯" could never offer
    "Unsuspend". Holders of `users.read` now get suspended accounts on all five profile routes, and `ProfileDto.admin`
    gives them the account's state.
18. **Sign out of all devices** needs `users.suspend` (it ends access, like a suspension) and sends the user nothing.
19. **Phone numbers.** Lists show masked numbers only (`+20***1234`: the country code, `***`, the last 4 digits). The
    full number comes one at a time from `GET /admin/users/{id}/phone` (`users.read.pii`, audited, `writes` rate limit,
    so it can't be scraped). Searching by phone number needs `users.read.pii` too.
20. **A user's page** carries each section only for holders of its permission (`null` otherwise): moderation history and
    reports (`moderation.manage`), verification requests (`verification.manage`), tickets (`support.manage`) and audit
    entries (`audit.read`). Each list holds the newest 20, with a total.
21. **The suspension reason** stays as F22 checks it on the server (required, ≤ 500); the console's form asks for 5–500
    (SPEC F23), so existing callers keep working.
22. **Cleanup.** A new daily job, `admin-cleanup` (03:50 UTC), deletes `SearchMisses` older than 90 days, and `JobRuns`
    and `PushDeliveryStats` rows older than 7 days.

#### Permissions and sections

| Permission | Opens |
|---|---|
| `admin.access` (new) | the console entry and layout, `GET /admin/summary`, `GET /admin/dashboard` |
| `users.read` (new) | Users: `GET /admin/users`, `GET /admin/users/{id}`; suspended accounts' profiles (decision 17) |
| `users.read.pii` | `GET /admin/users/{id}/phone`, phone search, IP addresses in the audit log |
| `users.suspend` | suspend / unsuspend (with `moderation.manage`), `POST /admin/users/{id}/logout-all` |
| `users.reset_password` | `POST /admin/users/{id}/reset-password` |
| `moderation.manage` | Reports (the F22 queue), Content (`/admin/articles`, `/admin/comments`), hide / unhide / delete, warn, `hide_content` / `unhide_content` |
| `articles.feature` | `PUT` / `DELETE /admin/articles/{id}/featured`, `PUT /admin/paths/featured` |
| `support.create` (new; Members too) | the member's routes in Support (F35) |
| `support.manage` (new) | Tickets (`/admin/support/tickets/*`), the `support_ticket` notification |
| `verification.manage` | Verification (the F19 queue), `DELETE /admin/users/{id}/verification` |
| `taxonomy.manage` | Taxonomy & Tags: `/admin/fields`, `/admin/topics`, `/admin/tags` |
| `paths.manage` | Paths: `/admin/paths` (F09) |
| `notifications.broadcast` (new) | Announcements: `/admin/announcements/*` |
| `audit.read` (new) | Audit log: `GET /admin/audit` |
| `system.settings` | System: `GET /admin/system`, `POST /admin/realtime/rebuild-counters` |

Mobile has Dashboard, Users, Content, Reports, Tickets and Verification; the other sections are web only (SPEC F23).
Reports, Tickets and Verification are the existing F22 and F19 queues and the F35 queue below.

#### Summary and dashboard (`admin.access`)

| Method | Path | Response |
|---|---|---|
| GET | `/admin/summary` | `AdminSummaryDto`: the badge on the console entry (open reports + open tickets + pending verification requests). Not cached. Clients ask on open, on resume and every 60 seconds |
| GET | `/admin/dashboard?period=` | `AdminDashboardDto`. `period` = `today` (default) \| `yesterday` \| `7d` \| `30d`; anything else is `400 validation.failed` (`errors.period: ["validation.invalid"]`). Cached 60 seconds per period and UI language (`generatedAt` says when); the state cards are read per caller, after the cache |

- No personal data: articles and writers appear as on any public page (`AuthorDto`), and searches without who searched.
- "Articles published" opens Content with `from` = `fromDate` and `to` = `toDate` (the period's local dates).
- **Top articles:** the 10 articles readers can open with the most reads in the period (ties: the newer
  `publishedAt`). **Top writers:** the 10 authors with an account and the most reads of their articles in the period,
  with how many of their articles were read. **Missed searches:** the 20 queries with the most misses on the period's
  dates (ties: A–Z).
- **Charts:** the last 30 days up to today, one point a day, zeros included, oldest first, whatever the period.
- **Content pipeline:** the article folders in `content/articles` (a `meta.json` each, read once per process), the
  `@readin` articles in the database (any status, not deleted), how many of those readers can open, and the newest
  `SeedHistory.AppliedAt`.

#### Users (`users.read`)

| Method | Path | Permission | Body → Response |
|---|---|---|---|
| GET | `/admin/users?q=&status=&verified=&method=&joinedFrom=&joinedTo=&hasReports=&sort=&dir=&page=&pageSize=` | `users.read` | → `PagedList<AdminUserRowDto>`. Rules below |
| GET | `/admin/users/{id}` | `users.read` | → `AdminUserDto` (a user's page). `404 user.not_found` (unknown or deleted) |
| GET | `/admin/users/{id}/phone` | `users.read` + `users.read.pii` | → `{ phoneNumber: string \| null }` (E.164; `null` for a Google/Apple-only account), `Cache-Control: no-store`. Rate limit `writes`. Audited `admin.pii_viewed` when there is a number. `404 user.not_found` |
| POST | `/admin/users/{id}/logout-all` | `users.suspend` | → `204`. Ends every session of the account (a new security stamp, every refresh token revoked): its next call is `401`. Audited `admin.sessions_revoked`. `404 user.not_found`, `400 moderation.self`, `403 moderation.staff_target` |
| POST | `/admin/users/{id}/reset-password` | `users.reset_password` | exists (see Me); audited `admin.password_reset` |
| DELETE | `/admin/users/{id}/verification` | `verification.manage` | exists (see Writer verification) |
| POST | `/moderation/actions` | `moderation.manage` (+ `users.suspend` for `suspend` / `unsuspend`) | exists (F22); F23 adds `hideContent`, `hide_content` and `unhide_content` (below) |

**The list** (`/admin/users`)
- `q` (trimmed, ≤ 100, else `validation.max_length`): `@handle` → usernames that start with it; a GUID → that
  account; with `users.read.pii`, a phone number in any form the phone field accepts (normalized to E.164) → that
  exact number; otherwise every word starts a word of the display name (§22 normalization, as people search), or the
  username starts with `q`. Without `users.read.pii` a phone-shaped `q` only matches names. Exact matches (username,
  id, phone) come first. Clients send `+` as `%2B`. Request logs keep the path only, never the query string.
- Filters: `status` = `active` | `suspended` (suspended now); `verified` = `true` | `false`; `method` = `phone` |
  `google` | `apple` (can sign in that way now); `joinedFrom` / `joinedTo` (dates, decision 4); `hasReports=true` (open
  reports about the user, their articles or their comments).
- `sort` = `joined` (default) | `lastSeen` | `followers` | `openReports`; `dir` = `desc` (default) | `asc`; ties by
  id. Accounts never seen come last either way.
- System accounts are listed (`isSystemAccount`); deleted accounts never are. An unknown filter or sort value is
  `400 validation.failed` with `validation.invalid` on that parameter.

**A user's page** (`AdminUserDto`). Its actions call existing endpoints, and `actions` says which ones this caller may
use on this account (permissions + decision 2):

| Action | Shown when | Call |
|---|---|---|
| Suspend for 1, 3, 7 or 30 days, 1–365 days, or permanently, with a reason and "Also hide all of their articles and comments" | `actions.canSuspend`, `status: "active"` | `POST /moderation/actions` `{ action: "suspend", targetType: "user", targetId, note, durationDays, hideContent }` |
| Unsuspend | `actions.canSuspend`, `status: "suspended"` | `{ action: "unsuspend", targetType: "user", targetId }` |
| Warn | `actions.canWarn` | `{ action: "warn", targetType: "user", targetId, note }` |
| Restore the content hidden with the account | `actions.canRestoreContent` (`moderation.hiddenWithAccount > 0`) | `{ action: "unhide_content", targetType: "user", targetId }` |
| Reset password (show the temporary password once) | `actions.canResetPassword` | `POST /admin/users/{id}/reset-password` |
| Sign out of all devices | `actions.canLogoutAll` | `POST /admin/users/{id}/logout-all` |
| Remove verified badge | `actions.canRemoveBadge` | `DELETE /admin/users/{id}/verification` |
| Clear title / Clear links | `actions.canClearProfile` and a `headline` / `links` to clear | `{ action: "clear_headline" \| "clear_links", targetType: "user", targetId }` |
| Show phone number | `actions.canRevealPhone` | `GET /admin/users/{id}/phone` |

**`POST /moderation/actions` (F23 additions)**
- `ModerationActionRequest` gains `hideContent?: boolean`, for `suspend` only (`true` on any other action is
  `400 moderation.action_invalid`). `suspend` with `hideContent: true` is `suspend` and then `hide_content`, in one
  transaction (two log entries).
- `hide_content` (user target; `moderation.manage`; protected accounts as decision 2; `note` optional): hides every
  article (published or archived) and comment of the user that isn't already hidden or deleted, flags each one as
  hidden with the account, and resolves the open reports of what it hid. The user gets no notice or push. Logged once
  as `user.hide_content` (label `@username`) and audited `moderation.content_hidden` (details: the counts). Nothing to
  hide → `204`, nothing logged.
- `unhide_content` (user target; `moderation.manage`; allowed on anyone): unhides what `hide_content` hid and is still
  hidden (unhiding one item by hand clears its flag). Logged `user.unhide_content`, audited
  `moderation.content_restored`. Nothing flagged → `204`, nothing logged. Closed reports stay closed.
- Feeds, Explore, counters and the cached pages of the articles touched refresh as for a single hide.

#### Content (`moderation.manage`; featuring: `articles.feature`)

| Method | Path | Permission | Body → Response |
|---|---|---|---|
| GET | `/admin/articles?from=&to=&field=&topic=&writer=&status=&hidden=&featured=&reported=&q=&sort=&page=&pageSize=` | `moderation.manage` | → `PagedList<AdminArticleRowDto>` |
| GET | `/admin/articles/{id}` | `moderation.manage` | → `AdminArticleRowDto` ("Open in console"). `404 article.not_found` (unknown, a draft, or deleted) |
| GET | `/admin/comments?hidden=&page=&pageSize=` | `moderation.manage` | → `PagedList<AdminCommentRowDto>` ("Latest comments") |
| PUT | `/admin/articles/{id}/featured` | `articles.feature` | → `204`. Rate limit `writes` |
| DELETE | `/admin/articles/{id}/featured` | `articles.feature` | → `204` (idempotent). Rate limit `writes` |

- **Articles:** published and archived ones (never drafts or deleted ones), hidden ones included. `from` / `to` apply
  to the first publish date. `field`, `topic`, `writer` are ids. `status` = `published` | `archived`; `hidden`,
  `featured` = `true` | `false`; `reported=true` = with open reports. `q` (≤ 100) = words in the title of any version
  (§22 normalization). `sort` = `published` (default, newest first) | `featured` (most recently featured first: the
  featured list is `featured=true&sort=featured`). Bad values: `400 validation.failed`. The title is the caller's
  UI-language version (`ar` → `ar-EG`), else the source. Hide or unhide with `POST /moderation/actions`; the reports
  are the F22 case `GET /moderation/reports/article/{id}` (when `reportCount > 0`).
- **Comments:** newest first across all articles, replies included; deleted comments, and comments of deleted
  articles, are left out; hidden ones are in (`hidden=true|false` filters). Hide, unhide and delete with
  `POST /moderation/actions`; reports through `GET /moderation/reports/comment/{id}`.
- **Featuring:** `PUT` features an article readers can open (`404 article.not_found` otherwise: unknown, not
  published, hidden or deleted); one already featured keeps its time (`204`, nothing written). `DELETE` works on any
  article, even one no longer readable. Audited `admin.article_featured` / `admin.article_unfeatured`. Drops Explore's
  cache and the article's cached details. A featured article that stops being readable stays featured but leaves
  Explore until it is readable again.

#### Taxonomy and tags (`taxonomy.manage`, web only)

| Method | Path | Body → Response |
|---|---|---|
| GET | `/admin/fields` | → `AdminTaxonomyDto`: every field, disabled ones too, in display order, each with all its topics, plus the `icons` and `colors` the clients can draw |
| POST | `/admin/fields` | `CreateFieldRequest` → `201 AdminFieldDto`. `409 field.slug_taken` |
| PUT | `/admin/fields/{id}` | `UpdateFieldRequest` → `200 AdminFieldDto`. `404 field.not_found` |
| PUT | `/admin/fields/order` | `{ ids: string[] }` (every field once, in display order) → `204`. `400 admin.order_invalid` |
| POST | `/admin/topics` | `CreateTopicRequest` → `201 AdminTopicDto`. `404 field.not_found`, `409 topic.slug_taken` |
| PUT | `/admin/topics/{id}` | `UpdateTopicRequest` → `200 AdminTopicDto`. `404 topic.not_found` |
| PUT | `/admin/fields/{id}/topics/order` | `{ ids: string[] }` (every topic of the field once) → `204`. `404 field.not_found`, `400 admin.order_invalid` |
| GET | `/admin/tags?q=&status=&origin=&sort=&page=&pageSize=` | → `PagedList<AdminTagDto>` |
| PUT | `/admin/tags/{id}` | `{ name: string }` (rename) → `200 AdminTagDto`. `404 tag.not_found`, `409 tag.name_taken` |
| POST | `/admin/tags/{id}/merge` | `{ intoTagId: string }` → `200 AdminTagDto` (the tag merged into). `400 tag.merge_self`, `404 tag.not_found` |
| PUT | `/admin/tags/{id}/hidden` | → `200 AdminTagDto` (hide; idempotent). `404 tag.not_found` |
| DELETE | `/admin/tags/{id}/hidden` | → `200 AdminTagDto` (unhide; idempotent). `404 tag.not_found` |

Every write here has the `writes` rate limit.

**Fields and topics**
- `slug`: kebab-case (`^[a-z0-9]+(-[a-z0-9]+)*$`), 2–64 characters (`validation.slug`); it never changes. `nameAr`,
  `nameEn`: 1–100 after trimming (`validation.required`, `validation.max_length`). `icon` must be one of
  `AdminTaxonomyDto.icons` (`field.icon_invalid`) and `color` one of `colors` (`field.color_invalid`), one server list
  that both clients draw.
- A new field goes last, a new topic last in its field. A field created disabled stays out of every list until it is
  enabled.
- Disabling a field does what `enabled: false` in `taxonomy.yaml` does today: the field and its articles leave feeds,
  Explore, field pages, search, saved lists, paths, interests and the editor; the articles stay and come back when it is
  enabled again (the UI confirms with `articleCount`). Disabling a topic: decision 11.
- A change that changes nothing → `200`, nothing written (no audit entry, `customizedAt` stays). Otherwise the row's
  `customizedAt` is set (decision 11).
- Audited `admin.field_created`, `admin.field_updated`, `admin.fields_reordered`, `admin.topic_created`,
  `admin.topic_updated`, `admin.topics_reordered` (target: the field or topic; details: the changed properties, e.g.
  `nameEn, isEnabled=false`).
- Every write drops the taxonomy caches, feeds and Explore, and the article pages (they carry field and topic names).

**Tags**
- The list: `q` (≤ 64) is cleaned and normalized like a tag name (F32 rules 1 and 3); a tag matches when its
  normalized name, its slug or one of its aliases contains it. `status` = `all` (default) | `visible` | `hidden`;
  `origin` = `all` (default) | `system` | `user`; `sort` = `articles` (default: `articleCount` desc, then name) |
  `name` | `newest`.
- **Rename:** the new name must pass F32 rules 1–2 (`400 validation.failed`, `errors.name: ["tag.invalid"]`). The same
  normalized form → only the spelling changes. A normalized form that another tag or alias has → `409 tag.name_taken`,
  with `tagId` and `tagSlug` of that tag in the problem (offer "Merge into #{name}"). Otherwise the old spelling becomes
  an alias (and the new name stops being an alias, if it was one of this tag's). The slug never changes. No change →
  `200`, nothing written. Audited `admin.tag_renamed` (details `old → new`).
- **Merge** `{id}` (A) into `intoTagId` (B), in one transaction: each article of A gets B in A's place (an article that
  has both keeps B once, at the first of the two places, and its other tags keep their order, so the 5-tag limit holds);
  A's aliases move to B, and A's name and slug become aliases of B; if A was a system tag, B becomes one; B keeps its
  own hidden state; A is deleted. Audited `admin.tag_merged` (target B, details `A → B (n articles)`). The UI confirms
  with `taggedCount`: it can't be undone.
- **Hide / unhide:** F32's effects (not suggested, not on cards or the reader, its page `404`, `tag.hidden` in the
  editor for new uses; it stays on its articles, so unhiding brings it back). Audited `admin.tag_hidden` /
  `admin.tag_unhidden`.
- Every tag write drops the tag caches (suggestions, headers, guests' tag pages), feeds and Explore, and the article
  pages (they carry tag names).
- **Aliases elsewhere (changes to Tags, F32):** `GET /tags/{slug}` and `GET /tags/{slug}/articles` answer the target
  tag for a merged tag's slug, and `TagDto.slug` is the target's: clients replace the URL (the web's server answers
  `301`). The editor resolves an alias to its tag (so it never counts toward `tag.limit`, and the tag's hidden state
  applies). Suggestions and search don't match aliases.

#### Paths and featured (`paths.manage`, `articles.feature`, web only)

| Method | Path | Permission | Body → Response |
|---|---|---|---|
| GET, POST, PUT, DELETE | `/admin/paths…` | `paths.manage` | exist (Path admin, F09). `AdminPathDto` gains `isFeatured` and `featuredOrder`. The writes are now audited (`admin.path_created`, `admin.path_updated`, `admin.path_items_set`, `admin.path_deleted`) and drop Explore's cache |
| PUT | `/admin/paths/featured` | `articles.feature` | `{ pathIds: string[] }` → `204`. Rate limit `writes`. Rules below |

- `PUT /admin/paths/featured` takes the whole featured list in Explore order: these paths get `IsFeatured` with
  `FeaturedOrder` 1..N, every other path is unfeatured, and `[]` unfeatures all. 0–20 different existing paths,
  editorial ones included (featuring isn't editing them); an unpublished path shows on Explore once it is published.
  Anything else is `400 path.featured_invalid`. No change → `204`, nothing written; otherwise audited
  `admin.featured_paths_set` (details: the slugs in order) and Explore's cache is dropped.
- Featured articles: Content with `featured=true&sort=featured`. The article picker for a path's items is
  `GET /search?type=articles&q=`.

#### Announcements (`notifications.broadcast`, web only)

| Method | Path | Body → Response |
|---|---|---|
| GET | `/admin/announcements` | → `AnnouncementsDto`: `canSend`, `nextAllowedAt` and the latest 50 announcements, newest first |
| POST | `/admin/announcements/preview` | `AnnouncementRequest` → `200 AnnouncementPreviewDto`: who it would reach now. Nothing is sent or written |
| POST | `/admin/announcements/test` | `AnnouncementRequest` → `204`. Rate limit `writes`. Sends it to you alone, at once (your `announcement` mode and quiet hours are ignored); it doesn't count as the day's announcement and isn't in the list. Audited `admin.announcement_tested` |
| POST | `/admin/announcements` | `AnnouncementRequest` → `202 AnnouncementDto` (`status: "sending"`). Rate limit `writes`. `429 announcement.limit`, `400 announcement.no_recipients`. Audited `admin.announcement_sent` |

- Validation (`400 validation.failed`): `titleAr` / `titleEn` 1–60 and `bodyAr` / `bodyEn` 1–180 after trimming,
  all four required (`validation.required`, `validation.max_length`); `audience.type` = `all` | `field` | `language`,
  `audience.language` = `ar-EG` | `en` (`validation.invalid`). `audience.fieldId` must be an enabled field
  (`404 field.not_found`). `link` (optional) = `{ type: "article" | "path", id }` pointing at an article readers can
  open or a published path, else `400 announcement.link_invalid`. `/preview` and `/test` check the same.
- Clients preview it, send a test, then confirm a dialog that shows `recipientCount`.
- Sending writes one `announcement` entry per recipient (decision 13) in a background job; when it is done the
  announcement is `sent` with its final `recipientCount`. Pushes follow F17: only for the mode `all`, held during quiet
  hours, dropped after 24 hours, in the recipient's UI language. The entry shows the announcement's title and body in
  the reader's UI language (`NotificationDto.data.title` / `body`) and opens the article (`readin://a/{slug}`), the
  path (`readin://paths/{slug}`) or, without a link, the notification center.

#### Audit log (`audit.read`, web only)

| Method | Path | Response |
|---|---|---|
| GET | `/admin/audit?actor=&target=&action=&source=&from=&to=&page=&pageSize=` | `PagedList<AuditEntryDto>`, newest first |

- `actor` / `target`: account ids (who did it / whom it concerns). `action`: an exact code, or a prefix that ends in
  `.` (`admin.`, `auth.`, `user.`), ≤ 64. `source` = `audit` | `moderation` (default: both). `from` / `to`: dates
  (decision 4). Bad values: `400 validation.failed` (`validation.invalid` on the parameter).
- Rows come from `AuditLogs` (without `moderation.*`, decision 14) and `ModerationActions`. `ip` only with
  `users.read.pii`; moderation rows never have one. An account deleted since shows as `null`, and its own security
  entries are gone (§9.6).

#### System (`system.settings`, web only)

| Method | Path | Response |
|---|---|---|
| GET | `/admin/system` | `AdminSystemDto`. Not cached, except storage (10 minutes) and the Firebase check (60 seconds) |
| POST | `/admin/realtime/rebuild-counters` | exists; now audited `admin.counters_rebuilt` (details: the article count) |

- `api`: the API's informational version (the build), when this process started, and the environment (`Production`,
  `Staging`, `Development` or `Testing`). `updatePolicy`: what `GET /app/update-policy` answers (§8.3).
- `database.reachable`: a `SELECT 1` within 3 seconds, with its time. `firebase`: whether FCM credentials are
  configured, whether the Realtime Database is, and whether a read of it answered within 3 seconds (`null` when it
  isn't configured).
- `jobs`: every recurring job (`outbox`, `notification-push`, `daily-article`, `streak-reminder`, `article-quality`,
  `article-excerpts-backfill`, `uploads-orphan-cleanup`, `verification-proofs-cleanup`, `identity-cleanup`,
  `tags-cleanup`, `rtdb-events-cleanup`, `admin-cleanup`, and F35's `support-auto-close` and `support-retention`), with
  its last run and its runs and failures in the last 24 hours. Without Hangfire (tests) every `lastRunAt` is `null`.
- `push`: pushes sent and failed, and invalid tokens removed, in the last 24 hours (decision 15).
- `storage`: bytes and files under the uploads folder and the private store.

#### Admin actions inside the app

| Menu | Item | Shown when | Call |
|---|---|---|---|
| A profile's "⋯" | "Suspend…" / "Unsuspend" | `moderation.manage` + `users.suspend`, not `isMe`, `ProfileDto.admin.isStaff` false; "Unsuspend" while `admin.isSuspended` | `POST /moderation/actions` `suspend` (the console's form) / `unsuspend` |
| | "Warn…" | `moderation.manage`, not `isMe`, `admin.isStaff` false | `warn` |
| | "Remove verified badge" | `verification.manage`, `isVerified`, not `isSystemAccount` | `DELETE /admin/users/{id}/verification` |
| | "Open in console" | `users.read` | web `/admin/users/{id}`; mobile: the console's user page |
| An article's "⋯" | "Hide" / "Unhide" | `moderation.manage` (hidden: `ArticleDetailsDto.moderation` is set) | `hide` / `unhide` |
| | "Feature" / "Unfeature" | `articles.feature` (`ArticleDetailsDto.isFeatured`) | `PUT` / `DELETE /admin/articles/{id}/featured` |
| | "Open in console" | `moderation.manage` | web `/admin/content/{id}` (`GET /admin/articles/{id}`) |
| A comment's "⋯" | "Hide" / "Delete" | `moderation.manage` | `hide` / `delete` (F22) |

Each item confirms first and is audited by its endpoint. "Remove verified badge" sends nothing to the user (F19).

#### As built (implementation notes, 2026-11-07)
- **Fields:** a field may keep an icon or color that isn't on the lists any more; only a changed value must come from
  them. `admin.fields_reordered` has no target, `admin.topics_reordered` targets the field, both with details `{n} moved`;
  each moved row becomes customized. Taxonomy writes also drop the tag caches.
- **Disabled topics:** following one (`PUT /me/interests/topics/{id}`) is `404 topic.not_found`; `PUT /me/interests` keeps
  accepting one already in the user's list (Settings never breaks); picking one in the editor is `400 topic.not_in_field`
  (an article keeps the one it has).
- **Featured articles:** `DELETE /admin/articles/{id}/featured` is `404 article.not_found` for an unknown or deleted id
  (repeating it on a real article stays `204`). Their audit entries name the author as the user, so they go with that
  account (§9.6). `AdminArticleRowDto.publishedAt` is `null` for an archived article that was never published.
- **Audit details:** `hide_content` → `articles=N comments=M`; path items → `{slug}: N articles`; an empty featured list →
  `-`.
- **Announcements:** a test send has no `data.announcementId` (no row exists). `AdminSystemDto.push.since` is rounded down
  to the hour. A job that ran but isn't registered any more still shows, with an empty `schedule`.
- **Dashboard:** articles published, comments and active readers count hidden content too; open reports count distinct
  targets (as `/moderation/summary`).
- **A user's page:** `tickets` lists the member's newest 20 tickets (F35) for holders of `support.manage`.

#### Changes elsewhere in this contract (made with the implementation)
- **Roles and permissions:** the six new codes (decision 1).
- **Profile (F14):** `ProfileDto.admin` (`null` for everyone without `users.read`), and suspended accounts on the five
  profile routes for holders of `users.read` (decision 17).
- **Articles:** `ArticleDetailsDto.isFeatured` (the same for everyone; cached with the details).
- **Explore:** `ExploreDto.featuredArticles` (decision 10).
- **Tags:** alias slugs (above). **Search:** misses are recorded (decision 8); responses don't change.
- **Reports and moderation:** `hideContent`, `hide_content`, `unhide_content`; staff includes holders of
  `admin.access` (decision 2). `ModerationActionDto.action` adds `user.hide_content` and `user.unhide_content`.
- **Path admin:** `AdminPathDto.isFeatured` / `featuredOrder`, audited writes, Explore's cache dropped.
- **Notifications:** new types `announcement` (configurable, quiet hours apply; F23), `support_reply` (always comes,
  like `verification_result`) and `support_ticket` (configurable, only for holders of `support.manage`) (F35).
  `GET /me/notification-settings` returns 10 types (11 with `support.manage`); a `PUT` with `support_ticket` from
  anyone else is `400 notification.type_invalid`, and so is one with `support_reply`.

#### Error codes (new)

| Code | Where | Arabic | English |
|---|---|---|---|
| `429 announcement.limit` | `POST /admin/announcements` | «أُرسل إعلان اليوم بالفعل. يمكن إرسال إعلان واحد في اليوم.» | "An announcement was already sent today. You can send one a day." |
| `400 announcement.no_recipients` | `POST /admin/announcements` | «لا يوجد مستلمون لهذا الإعلان.» | "This announcement has no recipients." |
| `400 announcement.link_invalid` | announcements | «يجب أن يشير الرابط إلى مقال منشور أو مسار منشور.» | "The link must point to a published article or path." |
| `409 field.slug_taken` | `POST /admin/fields` | «يوجد مجال آخر بهذا المعرّف.» | "Another field uses this slug." |
| `409 topic.slug_taken` | `POST /admin/topics` | «يوجد موضوع آخر في هذا المجال بهذا المعرّف.» | "Another topic in this field uses this slug." |
| `field.icon_invalid` (validation, `errors.icon`) | fields | «اختر أيقونة من القائمة.» | "Choose an icon from the list." |
| `field.color_invalid` (validation, `errors.color`) | fields | «اختر لونًا من القائمة.» | "Choose a color from the list." |
| `400 admin.order_invalid` | the two `…/order` routes | «يجب أن تضم القائمة كل العناصر مرة واحدة.» | "The list must hold every item exactly once." |
| `409 tag.name_taken` (+ `tagId`, `tagSlug`) | tag rename | «يوجد وسم آخر بهذا الاسم. إن كانا الوسم نفسه فادمجهما.» | "Another tag already has this name. If they're the same, merge them." |
| `400 tag.merge_self` | tag merge | «لا يمكن دمج الوسم في نفسه.» | "A tag can't be merged into itself." |
| `400 path.featured_invalid` | `PUT /admin/paths/featured` | «اختر 20 مسارًا على الأكثر، موجودة ومن دون تكرار.» | "Choose up to 20 different existing paths." |

Reused: `auth.forbidden`, `auth.unauthorized`, `user.suspended`, `user.not_found`, `article.not_found`,
`field.not_found`, `topic.not_found`, `tag.not_found`, `tag.invalid`, `path.*`, `moderation.self`,
`moderation.staff_target`, `moderation.action_invalid`, `verification.*`, `validation.failed` with
`validation.required` / `validation.max_length` / `validation.slug` / `validation.invalid`, `rate_limited`.

#### Audit actions (new)

Clients label every code in the audit log; an unknown code shows as it is.

| Code | Target | Arabic | English |
|---|---|---|---|
| `admin.pii_viewed` | user | «عرض رقم الهاتف» | "Viewed a phone number" |
| `admin.sessions_revoked` | user | «إنهاء كل الجلسات» | "Signed out of all devices" |
| `moderation.content_hidden` / `moderation.content_restored` | user | «إخفاء كل محتوى المستخدم» / «استعادة محتوى المستخدم» | "Hid all of the user's content" / "Restored the user's content" |
| `admin.article_featured` / `admin.article_unfeatured` | article | «إبراز مقال» / «إلغاء إبراز مقال» | "Featured an article" / "Unfeatured an article" |
| `admin.featured_paths_set` | — | «تعديل المسارات المبرزة» | "Changed the featured paths" |
| `admin.field_created` / `admin.field_updated` / `admin.fields_reordered` | field | «إضافة مجال» / «تعديل مجال» / «إعادة ترتيب المجالات» | "Added a field" / "Edited a field" / "Reordered the fields" |
| `admin.topic_created` / `admin.topic_updated` / `admin.topics_reordered` | topic (reorder: field) | «إضافة موضوع» / «تعديل موضوع» / «إعادة ترتيب المواضيع» | "Added a topic" / "Edited a topic" / "Reordered the topics" |
| `admin.tag_renamed` / `admin.tag_merged` | tag | «إعادة تسمية وسم» / «دمج وسمين» | "Renamed a tag" / "Merged tags" |
| `admin.tag_hidden` / `admin.tag_unhidden` | tag | «إخفاء وسم» / «إظهار وسم» | "Hid a tag" / "Unhid a tag" |
| `admin.path_created` / `admin.path_updated` / `admin.path_items_set` / `admin.path_deleted` | path | «إنشاء مسار» / «تعديل مسار» / «تعديل مقالات مسار» / «حذف مسار» | "Created a path" / "Edited a path" / "Set a path's articles" / "Deleted a path" |
| `admin.announcement_sent` / `admin.announcement_tested` | announcement | «إرسال إعلان» / «إرسال إعلان تجريبي» | "Sent an announcement" / "Sent a test announcement" |
| `admin.counters_rebuilt` | — | «إعادة حساب العدادات» | "Rebuilt the counters" |

#### Data (one migration, `AdminConsole`)

| Change | Details |
|---|---|
| `UserPresence` | `UserId` (the key) → `Users` cascade, `LastSeenAt datetime2`; index `(LastSeenAt)`. Kept off the `Users` row (decision 7) |
| `Users.SignUpMethod` | `varchar(8) NULL`: `phone` / `google` / `apple` (null for system accounts); filled once by hand-written SQL in the migration (decision 5), wrapped in `EXEC` so the idempotent script compiles |
| index | `Users(CreatedAt)` |
| `SearchMisses` | `Id`, `Date date`, `Language varchar(2)`, `Query nvarchar(100)` (`Latin1_General_100_BIN2`), `Count int`; unique `(Date, Language, Query)` |
| `Fields.CustomizedAt`, `Topics.CustomizedAt` | `datetime2 NULL` |
| `Topics.IsEnabled` | `bit NOT NULL DEFAULT 1` |
| `TagAliases` | `Id`, `TagId` → `Tags` cascade, `Name nvarchar(64)`, `NormalizedName nvarchar(64)` (`Latin1_General_100_BIN2`, unique), `Slug nvarchar(100) NULL` (unique where not null: a merged tag's slug), `CreatedAt`; index `(TagId)` |
| `AuditLogs.TargetType`, `TargetId`, `Details` | `varchar(16) NULL`, `uniqueidentifier NULL` (no FK), `nvarchar(500) NULL`; indexes `(ActorId, CreatedAt)` and `(TargetType, TargetId, CreatedAt)` next to the existing `(UserId, CreatedAt)` and `(CreatedAt)` |
| `Articles.FeaturedAt`, `FeaturedById` | `datetime2 NULL`, `uniqueidentifier NULL` (no FK; account deletion nulls it); index `(FeaturedAt)` where not null |
| `Articles.HiddenWithAccount`, `Comments.HiddenWithAccount` | `bit NOT NULL DEFAULT 0` |
| `Announcements` | `Id`, `TitleAr`, `TitleEn nvarchar(60)`, `BodyAr`, `BodyEn nvarchar(180)`, `LinkType varchar(8) NULL`, `LinkId uniqueidentifier NULL`, `AudienceType varchar(8)`, `FieldId NULL` (no FK), `Language varchar(5) NULL`, `SentById NULL` (no FK; account deletion nulls it), `LocalDate date` (unique: one a day), `Status tinyint`, `RecipientCount int`, `CreatedAt`, `CompletedAt NULL` |
| `JobRuns` | `Id`, `Job varchar(64)`, `StartedAt`, `DurationMs int`, `Succeeded bit`, `Error nvarchar(500) NULL` (the exception's type and message); indexes `(Job, StartedAt)`, `(StartedAt)` |
| `PushDeliveryStats` | `Hour datetime2` (the UTC hour, the key), `Sent`, `Failed`, `InvalidTokens int` |
| dashboard indexes | `ReadingProgress(CompletedAt)` including `(UserId, ArticleId)` where not null; `Comments(CreatedAt)`; `Reactions(ReactedAt)`; `Reposts(CreatedAt)` |

Account deletion (§9.6): `Announcements.SentById` and `Articles.FeaturedById` are anonymized (nulled explicitly);
`UserPresence` goes with the account (cascade) and `Users.SignUpMethod` with the row; `SearchMisses`, `TagAliases`, `JobRuns` and `PushDeliveryStats`
hold no personal data. New configuration: `Admin:TimeZone` (default `Africa/Cairo`).

### Support (F35) — SPEC F35

Members send tickets from Settings → «المساعدة والدعم» (web `/support`, mobile `/settings/support`); the SuperAdmin
answers them in the console's Tickets (web and mobile). Routes need a Bearer token unless marked 🌐; writes use the
`writes` rate limit. A suspended account gets `403 user.suspended` here too: the suspension screen shows the support
email instead.

**Decisions** (what SPEC F35 leaves open)

1. **Categories:** `app_problem` (a problem in the app), `account` (account and sign in), `content` (content or a
   report), `verification`, `suggestion`, `other`.
2. **Limits:** "5 a day" = 5 tickets created in the last 24 hours (rolling); "open at once" = not closed (Open or
   Answered), at most 10. Both answer `429 support.limit`, with `limit: "daily" | "open"` in the problem so clients can
   say which.
3. **Ticket numbers:** each ticket has a `number` (a sequence from 1), shown as "#12" in both apps and usable in email.
4. **Who answered:** the member sees support's replies as from «فريق الدعم» / "Support" (`fromSupport: true`, no admin
   name), like moderators (F22). Admins see who wrote each message.
5. **Messages:** a member's message has 1–2000 characters (the first one, with the ticket, 10–2000) and up to 3
   screenshots. Support's replies and internal notes are text only, sent as JSON (§17.2).
6. **Statuses:** a member's message moves Answered → Open; a support reply moves Open → Answered (and keeps Answered);
   internal notes and category changes never change the status or tell the member. A closed ticket takes no messages
   (`409 support.ticket_closed`): the member reopens it within 30 days of closing (later: `409 support.reopen_expired`),
   support reopens it any time with `PATCH`. Reopening makes it Open.
7. **Jobs:** `support-auto-close` (hourly) closes an Answered ticket whose last support reply is 14 days old with no
   member message since (`closedBy: "auto"`, no notification). `support-retention` (daily, 04:15 UTC) deletes tickets
   closed more than 365 days ago, with their messages and files, and files under `support/` that no row points at
   (a failed delete) once they are a day old.
8. **Notifications:** `support_reply` on a support reply and when support closes the ticket (not on auto-close, notes
   or category changes); `support_ticket` to every holder of `support.manage` except whoever acted, on a new ticket and
   on each member message. Both are grouped per ticket: new activity joins an unread entry of the same ticket from the
   last 24 hours (F17 aggregation).
9. **The support email** comes from `GET /support/config` (🌐), so the public `/support` page, the suspension screen
   and the "forgot the PIN too" sheet can show it without signing in; `email` is `null` when `Support:Email` isn't set.
10. **Device details** are optional text sent with the ticket. The app fills them; the web sends `platform: "web"`,
    the browser and OS as `osVersion` and its build as `appVersion`. An unknown `platform` or `language` is stored as
    `null` and over-long text is cut, never an error, so an odd device never blocks a ticket. No device identifier.
11. **Screenshots** are stored as received (like F19 proofs), in the private store; only the owner and holders of
    `support.manage` read them, as attachments.
12. **Audit:** every admin write (`admin.ticket_*`), with the ticket's owner as the user and the ticket as the target,
    never the text.

#### Member routes

| Method | Path | Permission | Body → Response |
|---|---|---|---|
| GET | `/support/config` | 🌐 | → `SupportConfigDto` (`Cache-Control: public, max-age=300`) |
| POST | `/support/tickets` | `support.create` | `multipart/form-data`: `category`, `subject`, `message`, `platform?`, `osVersion?`, `appVersion?`, `language?`, `screen?`, `screenshots` (0–3 files) → `201 SupportTicketDto` (`Location: /api/v1/support/tickets/{id}`). Rules below |
| GET | `/me/support/tickets?status=&cursor=&limit=` | `support.create` | → `CursorPage<SupportTicketSummaryDto>`, latest activity first. `status` = `active` (Open or Answered) \| `closed`; omitted = all; anything else `400 validation.failed`. `limit` 1–50, default 20 |
| GET | `/support/tickets/{id}` | `support.create` | → `SupportTicketDto` (without internal notes). `404 support.ticket_not_found` (unknown, or someone else's) |
| POST | `/support/tickets/{id}/messages` | `support.create` | `multipart/form-data`: `message` (1–2000), `screenshots` (0–3) → `201 SupportMessageDto`. `404 support.ticket_not_found`, `409 support.ticket_closed`, the screenshot errors below |
| POST | `/support/tickets/{id}/close` | `support.create` | → `204` (idempotent). `404 support.ticket_not_found` |
| POST | `/support/tickets/{id}/reopen` | `support.create` | → `204` (a ticket that isn't closed: `204`, nothing changes). `404 support.ticket_not_found`, `409 support.reopen_expired` |
| GET | `/support/attachments/{id}` | the ticket's owner, or `support.manage` | → the file with its stored `Content-Type` (`image/jpeg` \| `image/png` \| `image/webp`), `Content-Disposition: attachment; filename="support-{number}-{n}{.ext}"`, `Cache-Control: no-store`, `X-Content-Type-Options: nosniff`. `404 support.attachment_not_found` (unknown, or not yours) |

`POST /support/tickets` and `POST /support/tickets/{id}/messages`, checked in this order:
- A body that isn't `multipart/form-data` → `415 request.unsupported_media_type`.
- Validation (`400 validation.failed`): `category` one of decision 1 (`support.category_invalid`); `subject` 5–120
  characters after trimming (`validation.required`, `validation.length`); `message` 10–2000 for a new ticket, 1–2000
  after it (`validation.required`, `validation.length`).
- A new ticket: `429 support.limit` (decision 2).
- Screenshots: more than 3 → `400 support.too_many_attachments`; one that is empty, over 5 MB, or not JPEG, PNG or
  WebP **by its bytes** → `400 support.attachment_invalid` (the file name and the part's `Content-Type` are ignored; a
  body far over the limit gets the same answer, since the server stops reading it).
- Stored as `support/{messageId}/{n}{.ext}` (`n` = 1–3 in the order sent) in the private store
  (`Storage:PrivatePath`), never under `/uploads`.
- Device fields (decision 10): `platform` `ios` | `android` | `web`, `osVersion` ≤ 60, `appVersion` ≤ 40 (version and
  build, e.g. `1.2.0+57`), `language` `ar` | `en` (the UI language), `screen` ≤ 100 (the route the ticket came from).
- Then `support_ticket` goes to the holders of `support.manage`.

#### Admin routes (`support.manage`; in the console on web and mobile)

| Method | Path | Body → Response |
|---|---|---|
| GET | `/admin/support/tickets?status=&category=&q=&page=&pageSize=` | → `PagedList<AdminTicketRowDto>`. `status` = `open` (default; waiting longest first) \| `answered` (latest reply first) \| `closed` (latest closed first); `category` one of decision 1; `q` (≤ 100) = words in the subject, the member's name or `@username` (as people search), or `#12` for a ticket number. Bad values `400 validation.failed` |
| GET | `/admin/support/tickets/{id}` | → `AdminTicketDto`: the conversation with internal notes, the member's card, the device details, and their reports and moderation history. `404 support.ticket_not_found` |
| POST | `/admin/support/tickets/{id}/messages` | `{ body: string, internal: boolean }` (body 1–2000 after trimming) → `201 AdminSupportMessageDto`. Rate limit `writes`. A reply (`internal: false`) makes the ticket Answered and sends `support_reply`; a closed ticket → `409 support.ticket_closed` (reopen it first). An internal note works in any status and tells nobody. Audited `admin.ticket_replied` / `admin.ticket_note_added` |
| PATCH | `/admin/support/tickets/{id}` | `{ status?: "open" \| "closed", category?: SupportCategory }` (at least one; `validation.required`) → `200 AdminTicketDto`. Rate limit `writes`. `closed` closes it (`closedBy: "support"`) and sends `support_reply`; `open` reopens it (no time limit). The same value as now changes nothing and writes nothing. Audited `admin.ticket_closed`, `admin.ticket_reopened`, `admin.ticket_category_changed` |

The console badge counts tickets in Open (`AdminSummaryDto.openTickets`). A member's page in the console lists their
tickets (`AdminUserDto.tickets`: `{ items: AdminTicketRowDto[], total }`, newest 20).

#### As built (implementation notes, 2026-11-07)
- **Order of checks on a message:** `404 support.ticket_not_found` and `409 support.ticket_closed` come before the
  screenshots. A non-multipart request with no body is `400 request.invalid`; one with a JSON body `415`.
- **Screenshots:** a row whose file is missing on disk answers `404 support.attachment_not_found`. The private store gets a
  `support/` folder at startup; a message's folder goes with its last file.
- **Excerpts** (`lastMessage.excerpt`): whitespace collapsed to single spaces, cut at 140 characters with "…".
- **Admin routes:** `PATCH` with neither field is `400 validation.failed` with `errors.status: ["validation.required"]`;
  a reply's or note's `body` uses `validation.required` / `validation.max_length`.
- **Notifications:** `GET /me/notification-settings` returns 10 types, 11 for holders of `support.manage` (with
  `support_ticket`). An entry whose ticket was deleted stays in the center (opening it gives `404`); its push is skipped.
- **Jobs:** `support-auto-close` runs hourly at :20, `support-retention` daily at 04:15 UTC.
- New tickets and messages are saved inside the per-member lock's transaction; their outbox events (the notifications)
  are dispatched right after that transaction commits.

#### Error codes (new)

| Code | Arabic | English |
|---|---|---|
| `429 support.limit` (+ `limit`) | «وصلت إلى حد التذاكر: 5 تذاكر جديدة في اليوم و10 تذاكر مفتوحة على الأكثر.» | "You've reached the ticket limit: 5 new tickets a day and 10 open at once." |
| `404 support.ticket_not_found` | «التذكرة غير موجودة.» | "Ticket not found." |
| `404 support.attachment_not_found` | «المرفق غير موجود.» | "Attachment not found." |
| `409 support.ticket_closed` | «هذه التذكرة مغلقة. أعد فتحها أولًا.» | "This ticket is closed. Reopen it first." |
| `409 support.reopen_expired` | «مضى أكثر من 30 يومًا على إغلاق التذكرة. أرسل تذكرة جديدة.» | "This ticket was closed more than 30 days ago. Send a new one." |
| `400 support.attachment_invalid` | «يجب أن تكون الصورة بصيغة JPEG أو PNG أو WebP، وألا يزيد حجمها على 5 م.ب.» | "Screenshots must be JPEG, PNG or WebP, up to 5 MB each." |
| `400 support.too_many_attachments` | «يمكن إرفاق 3 صور على الأكثر.» | "You can attach up to 3 images." |
| `support.category_invalid` (validation, `errors.category`) | «اختر تصنيفًا من القائمة.» | "Choose a category from the list." |

#### Audit actions (new)

| Code | Arabic | English |
|---|---|---|
| `admin.ticket_replied` | «الرد على تذكرة» | "Replied to a ticket" |
| `admin.ticket_note_added` | «إضافة ملاحظة داخلية» | "Added an internal note" |
| `admin.ticket_closed` / `admin.ticket_reopened` | «إغلاق تذكرة» / «إعادة فتح تذكرة» | "Closed a ticket" / "Reopened a ticket" |
| `admin.ticket_category_changed` | «تغيير تصنيف تذكرة» | "Changed a ticket's category" |

#### Data (one migration, `SupportTickets`)

| Table | Columns and indexes |
|---|---|
| `SupportTickets` | `Id`, `Number int` (identity, unique), `UserId` → `Users` cascade, `Category varchar(16)`, `Subject nvarchar(120)`, `Status tinyint` (Open / Answered / Closed), `Platform varchar(8) NULL`, `OsVersion nvarchar(60) NULL`, `AppVersion nvarchar(40) NULL`, `Language varchar(2) NULL`, `Screen nvarchar(100) NULL`, `CreatedAt`, `UpdatedAt` (the latest message), `LastUserMessageAt`, `LastAdminReplyAt NULL`, `ClosedAt NULL`, `ClosedById NULL` (no FK), `ClosedBy tinyint NULL` (Member / Support / Auto); indexes `(Status, LastUserMessageAt)` (the queue), `(UserId, CreatedAt)` (My tickets, the daily limit), `(Status, LastAdminReplyAt)` (auto-close), `(Status, ClosedAt)` (retention) |
| `SupportMessages` | `Id`, `TicketId` → cascade, `AuthorId NULL` (no FK; null once that account is deleted), `FromSupport bit`, `IsInternalNote bit`, `Body nvarchar(2000)`, `CreatedAt`; index `(TicketId, CreatedAt)` |
| `SupportAttachments` | `Id`, `MessageId` → cascade, `Position tinyint` (1–3), `FilePath varchar(200)`, `ContentType varchar(16)`, `SizeBytes int`, `CreatedAt`; index `(MessageId)` |

Account deletion follows §9.6: the account's tickets, messages and attachments go by cascade and their files right
after the commit; on other members' tickets its replies and notes stay with `AuthorId` and `ClosedById` nulled. New
configuration: `Support:Email` (empty = none).

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
  authorizationCode?: string;    // Apple only: the one-time code from the SDK, so the API can keep a revocable token (SPEC §9.6)
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
  recoveryPin: string;           // pinLength digits, any digits (SPEC §9.4)
  uiLanguage?: UiLanguage;
  timeZone?: string;             // IANA, e.g. "Africa/Cairo"
}

interface LoginRequest { phoneNumber: string; password: string }
interface RefreshRequest {
  refreshToken?: string;         // omit on the web (cookie)
  retryKey?: string;             // mobile: random, at most 200 characters; resend with the same token after a lost response
}
interface VerifyPinRequest { phoneNumber: string; pin: string }

interface SessionDto {
  accessToken: string;           // JWT, send as Bearer
  accessTokenExpiresAt: string;  // ~15 minutes
  refreshToken: string | null;   // null on the web (HttpOnly cookie)
  refreshTokenExpiresAt: string; // 30 days (web), 10 years (X-ReadIn-Client: mobile); rotates on every refresh
  user: MeDto;
}

// Validation codes (in `errors`): phone.invalid · password.too_short | too_long | letter_required | digit_required |
// too_common | contains_phone · pin.length | digits_only · provider.invalid

interface MeDto {
  id: string;
  phoneNumber: string | null;    // E.164; only in MeDto and admin endpoints (SPEC §9.5); null for Google/Apple-only accounts
  email: string | null;          // provider-verified only
  displayName: string;
  username: string;              // @handle without "@"
  avatarUrl: string | null;
  headline: string | null;       // the title (F14): one line, ≤ 120; null when empty
  bio: string | null;
  links: ProfileLinkDto[];       // F14, in the user's order; [] when none (was { github, linkedin, website })
  uiLanguage: UiLanguage;
  articleLanguage: ArticleLanguage;
  theme: ThemePreference;
  timeZone: string;
  reminderTime: string;          // "08:00"
  showHighlights: boolean;       // F30: draw highlight marks in the reader; default true. PUT /me/preferences
  isVerified: boolean;           // the Verified badge (Users.IsVerified), not a role
  onboardingCompleted: boolean;  // true once ≥ 3 interests are saved
  mustChangePassword: boolean;   // after an admin reset (users.reset_password), or the production SuperAdmin's first sign in
  mustSetRecoveryPin: boolean;
  isProfileComplete: boolean;
  hasRecoveryPin: boolean;
  hasPassword: boolean;          // false for Google/Apple-only accounts: offer "add phone sign in" instead of "change password"
  externalLogins: { provider: ExternalProvider; email: string | null; linkedAt: string }[];
  roles: string[];               // ["Member"] or ["SuperAdmin"]; gate on permissions, never on role names
  permissions: string[];         // e.g. ["articles.read", "articles.create", ...]
  interests: { fieldIds: string[]; topicIds: string[] };
  privacy: {                     // Settings → Privacy (F18). PUT /me/privacy
    publicReadingStats: boolean; // default false
    whoCanMention: MentionPolicy; // default "everyone"
  };
}

// Who may @mention you in comments and articles (F18): everyone, the people you follow, or nobody (but yourself).
type MentionPolicy = 'everyone' | 'following' | 'nobody';

interface UpdateProfileRequest {
  displayName: string;           // 2..60
  username: string;              // ^[a-z0-9_]{3,30}$
  bio?: string | null;           // ≤ 300
  headline?: string | null;      // F14 title, ≤ 120, one line. OMIT to keep it; null or blank clears it
  links?: ProfileLinkInput[] | null; // F14, ≤ 8, in display order. OMIT (or null) to keep them; an array replaces them all ([] clears)
  avatarAssetId?: string | null; // POST /uploads/images purpose=avatar → id. OMIT to keep the avatar; null removes it
  expertiseFieldIds?: string[];  // 0–5 enabled field ids in display order; omit to keep, [] to clear
  /** @deprecated previous release: an uploaded avatar's URL or an external https image; null removes. */
  avatarUrl?: string | null;
}

interface UpdatePreferencesRequest {
  uiLanguage: UiLanguage;
  articleLanguage: ArticleLanguage;
  theme: ThemePreference;
  timeZone: string;
  reminderTime: string;          // "HH:mm"
  showHighlights?: boolean;      // F30 "Hide highlights": omit to keep the current setting
}

interface UpdateInterestsRequest { fieldIds: string[]; topicIds: string[] }

interface RegisterDeviceRequest { token: string; platform: 'android' | 'ios' | 'web' }

interface FieldDto {
  id: string; slug: string;
  name: string;                  // localized by Accept-Language
  nameAr: string; nameEn: string;
  icon: string;                  // Lucide icon name, e.g. "cpu"
  color: string;                 // token name, e.g. "primary"
  isSensitive: boolean; // shows a health disclaimer; never blocks publishing
  requiresSources: boolean;      // publishing needs at least one source
  topicCount: number;
}

interface TopicDto { id: string; fieldId: string; slug: string; name: string; nameAr: string; nameEn: string }

interface AuthorDto {
  id: string; displayName: string; username: string; avatarUrl: string | null; isVerified: boolean;
  headline: string | null;       // F14: the writer's current title; one line with "…" on cards, the reader and comments; null → hide the line
}

// ── Profile links (F14) ─────────────────────────────────────────────
type LinkPlatform = 'linkedin' | 'x' | 'instagram' | 'facebook' | 'youtube' | 'tiktok' | 'snapchat' | 'threads'
  | 'telegram' | 'github' | 'medium' | 'behance' | 'website' | 'other';
interface ProfileLinkDto {
  platform: LinkPlatform;
  url: string;                   // https, ≤ 500, normalized ("https://" added when it was typed without a scheme)
  label: string | null;          // 'other' only (2–30, one line): its accessible name and tooltip; null for the rest
}
interface ProfileLinkInput { platform: string; url: string; label?: string | null } // PATCH /me; rules in Profile → "Title and social links"

interface FieldRefDto {
  id: string; slug: string; name: string; nameAr: string; nameEn: string;
  isSensitive: boolean;          // Medicine, Public Health: the reader shows the health disclaimer (SPEC F04); a topic carries its field's flag
}

interface ArticleCardDto {
  id: string; slug: string;
  language: ArticleLanguage;     // language actually served
  title: string; subtitle: string | null;
  excerpt: string | null;        // F34: the served version's beginning, plain text, ≤ 400 chars cut at a word, lines joined by "\n"; null only until the backfill reaches a pre-F34 version
  hasMore: boolean;              // F34: the article holds more than `excerpt` (cut text, later blocks, skipped blocks); true when excerpt is null
  coverUrl: string | null;
  field: FieldRefDto;
  topic: FieldRefDto | null;     // F28: the article's topic (on cards since F28; it was on ArticleDetailsDto only), for the "كتم المواضيع" sheet
  author: AuthorDto | null;      // null: the author deleted their account (SPEC §9.6); show "Deleted user", no profile link or follow
  readingTimeMinutes: number;
  isAiAssisted: boolean;
  versionBadge: string | null;   // e.g. ".NET 10"
  publishedAt: string;
  tags: TagRefDto[];             // F32/F34: on cards the first 3 tags, in the writer's order; all of them (≤ 5) in ArticleDetailsDto. Hidden tags left out. Was string[] before F32
  tagCount: number;              // F34: all the article's visible tags (0–5), for the card's "+N"
  reactionCount: number;         // always the sum of `reactions`
  reactions: ReactionCountsDto;
  commentCount: number;          // 0 until F11
  saveCount: number;
  repostCount: number;           // F29: people who reposted it; the number beside the Repost icon (hidden at 0)
  myReaction: ReactionType | null; // the caller's reaction; null for guests
  isSaved: boolean;              // the caller saved it; false for guests
  isReposted: boolean;           // F29: the caller reposted it; false for guests
  repostedBy: RepostLabelDto | null; // F29: only on Following-feed cards a repost placed and on a profile's Reposts tab; null elsewhere
  isFollowingAuthor: boolean;    // the caller follows the author; false for guests, on your own articles and for a deleted author
  isAuthorMuted: boolean;        // F28: the caller muted the author (the reader's "انت كاتم الكاتب ده" banner); false for guests, on your own articles and for a deleted author
  isFieldMuted: boolean;         // F28: the caller muted `field` (the sheet's toggle); false for guests
  isTopicMuted: boolean;         // F28: the caller muted `topic`; false for guests and without a topic
  attachments: ArticleAttachmentsDto | null;  // feed cards carry at most the first 10 PDF pages
}

// GET /articles/{id}/preview (F34): a feed card's "Read more"
interface ArticlePreviewDto {
  id: string;
  language: ArticleLanguage;     // the version served: the requested one, else the source language
  content: RDoc;                 // same shape as ArticleDetailsDto.content: the first whole blocks, ~300 words, at least one
  isComplete: boolean;           // content is the whole article (no "Read the full article")
}

// ── Reactions, saved, follow (F10, F12, F13) ──────────────────────
type ReactionType = 'insightful' | 'love' | 'fire' | 'mindBlown';   // 💡 ❤️ 🔥 🤯 (SPEC F10)
interface ReactionCountsDto { insightful: number; love: number; fire: number; mindBlown: number }

interface ArticleReactionsDto { reactions: ReactionCountsDto; total: number; myReaction: ReactionType | null }
interface ReactorDto { user: AuthorDto; type: ReactionType; reactedAt: string }

interface SaveStateDto { isSaved: boolean; saveCount: number }
interface SavedArticleDto { savedAt: string; collectionIds: string[]; article: ArticleCardDto }
interface CollectionDto { id: string; name: string; articleCount: number; createdAt: string } // articleCount: openable articles

// ── Reposts (F29) ─────────────────────────────────────────────────
interface RepostRequest { caption?: string | null }  // PUT /articles/{id}/repost (optional body): missing/null = keep (none on a new repost); "" clears; ≤ 500 chars after trim
interface RepostStateDto { repostCount: number; isReposted: boolean; caption: string | null } // GET / PUT / DELETE /articles/{id}/repost
/** The card's label "أعاد نشره {name}" / "{name} و{n} غيره أعادوا نشره". */
interface RepostLabelDto {
  user: AuthorDto;               // the newest reposter you follow (Following feed), or the profile's owner (Reposts tab); name links to /@{username}
  othersCount: number;           // other writers you follow who reposted it; always 0 on the Reposts tab
  repostedAt: string;            // that repost's time: where the item is placed
  caption: string | null;        // `user`'s thoughts on it (plain text, ≤ 500 chars), shown under the label
}

// ── Highlights (F30) ──────────────────────────────────────────────
// Offsets: UTF-16 code units in the block's plain text, end exclusive (shared/rdoc/highlight-fixtures.json).
interface CreateHighlightRequest {  // POST /articles/{id}/highlights
  language: ArticleLanguage;     // the version being read (ArticleHighlightsDto.language)
  blockId: string;
  startOffset: number;
  endOffset: number;
  text: string;                  // exactly plainText.slice(startOffset, endOffset)
}
interface HighlightDto {           // one of yours; never sent to anyone else
  id: string;
  blockId: string;
  startOffset: number;
  endOffset: number;
  text: string;
  createdAt: string;
}
interface PopularHighlightDto {    // marked by ≥ 3 readers; no ids, no names
  blockId: string;
  startOffset: number;
  endOffset: number;
  text: string;
  count: number;                 // "N قارئ علّموا الجملة دي" / "N readers highlighted this"; your muted writers don't count
}
interface ArticleHighlightsDto {   // GET /articles/{id}/highlights?lang=
  articleId: string;
  language: ArticleLanguage;     // the version these belong to
  mine: HighlightDto[];          // document order; [] for guests
  popular: PopularHighlightDto[]; // ≤ 5, most marked first, then document order
}
interface HighlightCreatedDto {    // POST → 201 (made) or 200 (already inside one of yours)
  highlight: HighlightDto;       // the highlight now covering the range
  replacedIds: string[];         // your highlights it joined (deleted): drop them
}
interface HighlightGroupDto {      // GET /me/highlights: one article version
  article: HighlightArticleDto;
  highlights: HighlightDto[];    // all of yours on it, newest first
  latestAt: string;              // your newest highlight on it (also one an Update hid): groups come newest first by it
}
interface HighlightArticleDto {
  id: string;
  slug: string;
  language: ArticleLanguage;     // open the article in this version, at the highlight's blockId
  title: string;                 // that version's title
  author: AuthorDto | null;      // null: the author deleted their account
}

interface FollowStateDto { isFollowing: boolean; followerCount: number }
interface UserSummaryDto {
  id: string; displayName: string; username: string; avatarUrl: string | null; isVerified: boolean;
  headline: string | null;       // F14 title (one line with "…"); null → hidden
  bio: string | null;
  isFollowing: boolean;          // the caller follows this user (false for guests)
  followsYou: boolean;           // this user follows the caller (false for guests)
}

interface InterestsDto { fieldIds: string[]; topicIds: string[] }  // as in MeDto.interests

// ── Mute & feedback (F28) ─────────────────────────────────────────
interface UserMuteStateDto {     // PUT / DELETE /users/{id}/mute
  isMuted: boolean;
  isFollowing: boolean;          // after the change: a mute always ends your follow; DELETE ?restoreFollow=true follows again
  followerCount: number;         // the writer's followers after the change
  followRemoved: boolean;        // PUT: this mute ended your follow, so Undo sends restoreFollow=true; always false on DELETE
}
interface ContentMutesDto { fieldIds: string[]; topicIds: string[] } // every field and topic you muted, after the change
interface MutesDto {             // GET /me/mutes (Settings → Muted); each list newest mute first
  users: UserSummaryDto[];       // isFollowing is always false (a mute ends the follow); suspended accounts stay listed
  fields: MutedFieldDto[];
  topics: MutedTopicDto[];
}
interface MutedFieldDto { id: string; slug: string; name: string; nameAr: string; nameEn: string; icon: string; color: string } // name in Accept-Language; icon = Lucide name, color = token
interface MutedTopicDto { id: string; slug: string; name: string; nameAr: string; nameEn: string; field: MutedFieldDto }

// ── Profile (F14) ─────────────────────────────────────────────────
interface ProfileDto {
  id: string;
  displayName: string;
  username: string;              // without "@"; render dir="ltr"
  avatarUrl: string | null;      // the 256 px variant, the same URL AuthorDto / UserSummaryDto carry
  /** Every key always present, one URL per avatar size: a small upload (never upscaled) repeats its largest variant.
   *  null without an avatar or for an avatar that isn't an upload (e.g. a Google photo). */
  avatarVariants: { '64': string; '128': string; '256': string; '512': string } | null;
  isVerified: boolean;
  headline: string | null;       // F14 title, shown in full (wrapped) under the name; null → hidden. dir="auto"
  bio: string | null;            // mixed ar/en: render dir="auto"
  links: ProfileLinkDto[];       // F14: the icon row under the bio, in order; [] → hidden (was { github, linkedin, website })
  expertise: ExpertiseFieldDto[]; // ≤ 5, in the user's order
  joinedAt: string;
  stats: { articles: number; followers: number; following: number; totalReads: number }; // published articles; sum of their readCount
  isMe: boolean;
  isFollowing: boolean;          // false for guests and on your own profile
  followsYou: boolean;           // false for guests and on your own profile
  readingStatsVisible: boolean;  // isMe, or the user turned on publicReadingStats: then /stats and /stats/heatmap answer 200
  isMuted: boolean;              // F28: the caller muted this user: "انت كاتم الكاتب ده" + "إلغاء الكتم"; false for guests and on your own profile
  isSystemAccount: boolean;      // F28: the official @readin account; it can't be muted, so the profile's "⋯" has no Mute
  admin: { isSuspended: boolean; suspendedUntil: string | null; isStaff: boolean } | null; // F23: users.read holders only; null for everyone else
}

interface ExpertiseFieldDto { id: string; slug: string; name: string; icon: string; color: string } // name localized by Accept-Language

// ── Writer categories (F31) ─────────────────────────────────────────
/** A card of the profile's Categories tab and a row of the writer's manage list. Show `name` with dir="auto". */
interface WriterCategoryDto {
  id: string;
  slug: string;                  // made once from the name, never changes on rename; opens /@{username}/c/{slug} (percent-encoded)
  name: string;                  // 1–40 characters, the writer's spelling
  articleCount: number;          // articles readers can see in it, the same for everyone; 0 only in GET /me/categories
  sortOrder: number;             // the writer's order, ascending (1..N in GET /me/categories); lists already come sorted
}

interface WriterCategoryListDto {  // GET /users/{username}/categories, GET /me/categories, PUT /me/categories/order
  items: WriterCategoryDto[];    // the profile: non-empty ones only; /me: all of them, empty ones included
  uncategorizedCount: number;    // articles readers can see without a category: the last card "مقالات تانية" (/c/_other); hidden when 0
}

/** GET /users/{username}/categories/{slug}: the category page's header. */
interface WriterCategoryPageDto {
  id: string | null;             // null for the uncategorized list (slug "_other")
  slug: string;
  name: string | null;           // null for "_other": show "مقالات تانية" / "Other articles"
  articleCount: number;          // 0 → the empty state (web: noindex)
  author: AuthorDto;             // the writer: the page title ("{name} · {displayName}") and the link back to the profile
}

/** ArticleDetailsDto.category: "في قسم {name}" / "In {name}", linking to /@{author.username}/c/{slug}. */
interface WriterCategoryRefDto { slug: string; name: string }

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

// ── Editor (F05, ADR 0015) ─────────────────────────────────────────
type ArticleStatus = 'draft' | 'published';

/** Everything the editor edits; sent whole on every autosave. */
interface ArticleDraftDocument {
  sourceLanguage: ArticleLanguage;       // one of translations[].language
  translations: DraftTranslation[];      // 1 or 2, distinct languages
  fieldId: string | null;                // required to publish
  topicId: string | null;                // must belong to fieldId
  tags: string[];                        // ≤ 5 names (F32 rules, see Tags); stored cleaned, repeats dropped; new names become tags on publish
  sources: { title: string; url: string }[]; // ≤ 30; required to publish when the field has requiresSources
  coverUrl: string | null;               // from POST /uploads/images (purpose=cover)
  versionBadge: string | null;           // ≤ 30
  isAiAssisted: boolean;
  attachments: DraftAttachment[];        // 1–10 images OR one PDF, or []
}
interface DraftTranslation {
  language: ArticleLanguage;
  title: string;                         // '' allowed in a draft; 5..150 to publish
  subtitle: string | null;               // ≤ 250
  content: RDoc;                         // content.language === language
}
interface DraftAttachment {
  mediaAssetId: string; order: number;
  caption?: string | null;               // images, ≤ 5000
  altText?: string | null;               // images, required to publish, ≤ 5000
  title?: string | null;                 // the PDF, required to publish, ≤ 5000, no line breaks
  allowDownload?: boolean;               // the PDF; omitted keeps the asset's value (uploads default to true); the composer's toggle starts on
}

interface ArticleEditDto {
  id: string;
  status: ArticleStatus;
  slug: string | null;                   // null until the first publish
  publishedAt: string | null;
  version: number;                       // send back as baseVersion
  savedAt: string;
  hasUnpublishedChanges: boolean;        // published articles only
  categoryId: string | null;             // F31: the writer's category (null: none). Not in `document`; PUT /articles/{id}/category
  document: ArticleDraftDocument;        // public URLs
  media: MediaAssetDto[];                // the attachments' assets (yours only)
  checks: DraftChecksDto;
}
interface DraftChecksDto {
  readingTime: { language: ArticleLanguage; minutes: number; words: number }[];
  problems: DraftProblemDto[];           // empty → can publish
}
interface DraftProblemDto {
  code: string;                          // see below
  language: ArticleLanguage | null;      // translation problems
  blockId: string | null;                // the RDoc block (image alt, or the first block the schema rejects)
  mediaAssetId: string | null;           // attachment problems
  tag: string | null;                    // tag problems: the name as in document.tags (F32)
}
// Problem codes: article.field_required, article.title_length, article.content_empty (no text and no attachments),
// article.content_invalid, article.image_alt_required, article.sources_required, attachments.alt_text_required,
// attachments.title_required, attachments.asset_not_ready (uploading, failed, missing or not yours),
// attachments.mixed_kinds, attachments.single_document, media.in_use (shown in another article),
// tag.hidden (a hidden tag the published article doesn't have), tag.limit (over 20 new tags in 24 hours) (F32, see Tags).

interface PublishedArticleDto { id: string; slug: string; publishedAt: string; revision: number; firstPublish: boolean }
interface ArticleRevisionDto { number: number; createdAt: string; title: string; languages: ArticleLanguage[] }
interface ArticleRevisionDetailsDto extends ArticleRevisionDto { document: ArticleDraftDocument; media: MediaAssetDto[] }

interface MyArticleDto {
  id: string;
  status: ArticleStatus;
  slug: string | null;
  language: ArticleLanguage;             // source language
  title: string;                         // '' → "Untitled" / "بدون عنوان"
  coverUrl: string | null;
  field: FieldRefDto | null;             // null: a draft without a field yet
  readingTimeMinutes: number;
  savedAt: string;
  publishedAt: string | null;
  hasUnpublishedChanges: boolean;
  reactionCount: number; commentCount: number; readCount: number;
  publishedLanguages: ArticleLanguage[]; // F33: the published versions, source language first; [] for a draft. Two → "Download PDF" asks which
}

// ── Tags (F32) ──────────────────────────────────────────────────────
/** A tag on a card or in the reader: show "#name" (dir="auto"), link to /tags/{slug} (percent-encoded). */
interface TagRefDto { slug: string; name: string }
/** GET /tags?q= (suggestions) and GET /tags/{slug} (the tag page's header). Never a hidden tag. */
interface TagDto {
  slug: string;                  // stable; lower case letters (Arabic too), digits and "-"
  name: string;                  // the first spelling, e.g. "C#", ".NET", "الذكاء الاصطناعي"
  articleCount: number;          // published articles readers can see (not hidden, not deleted); 0 → empty state, noindex
}

// ── Search (F16) ────────────────────────────────────────────────────
// GET /search?type=: articles → CursorPage<SearchArticleDto>, users → CursorPage<UserSummaryDto>,
// topics → CursorPage<SearchTopicDto>, tags → CursorPage<TagDto>.
type SearchType = 'articles' | 'users' | 'topics' | 'tags';
/** Where the query was found, best first: the served version's title, its title + text, or only the attached PDF. */
type SearchMatch = 'title' | 'text' | 'attachment';

interface SearchArticleDto {
  article: ArticleCardDto;       // in the version that matched; shown as the compact row (F34)
  matchedIn: SearchMatch;        // 'attachment' → "لقيناها في ملف الـ PDF المرفق" / "Found in the attached PDF"
}

interface SearchTopicDto {
  kind: 'field' | 'topic';
  id: string;                    // the field's or the topic's id
  name: string;                  // in Accept-Language
  nameAr: string; nameEn: string;
  fieldSlug: string;
  topicSlug: string | null;      // null for a field. Opens /f/{fieldSlug}, or /f/{fieldSlug}?topic={topicSlug} for a topic
  fieldName: string;             // the field's name in Accept-Language (= name for a field): a topic's subtitle
  icon: string;                  // the field's Lucide icon name, e.g. "cpu"
  color: string;                 // the field's color token, e.g. "primary"
  articleCount: number;          // published articles readers can see in it (the same for everyone)
}

interface SearchSuggestionsDto { // GET /search/suggest: at most 3 of each type, ranked as in /search
  articles: SearchArticleDto[];
  users: UserSummaryDto[];
  topics: SearchTopicDto[];
  tags: TagDto[];
}

// ── Explore and field pages (F15) ───────────────────────────────────
interface ExploreDto {           // GET /explore; an empty section is [] (clients hide it)
  fields: FieldSummaryDto[];     // every enabled field, display order
  trending: ArticleCardDto[];    // ≤ 6, the first of /explore/trending
  mostSaved: ArticleCardDto[];   // ≤ 6, the first of /explore/most-saved
  newWriters: UserSummaryDto[];  // ≤ 10, latest first publish first
  featuredPaths: PathCardDto[];  // ≤ 6, featured order
  featuredArticles: ArticleCardDto[]; // F23: ≤ 6, most recently featured first; [] hides the section
}

interface FieldSummaryDto {      // a field tile on Explore; opens /f/{slug}
  id: string; slug: string;
  name: string;                  // in Accept-Language
  nameAr: string; nameEn: string;
  icon: string;                  // Lucide icon name, e.g. "cpu"
  color: string;                 // color token, e.g. "primary"
  articleCount: number;          // articles readers can see in it (the same for everyone)
}

interface FieldPageDto {         // GET /fields/{slug}
  id: string;                    // for PUT/DELETE /me/interests/fields/{id}
  slug: string;
  name: string;                  // in Accept-Language
  nameAr: string; nameEn: string;
  icon: string; color: string;
  isSensitive: boolean;          // show the health disclaimer note
  articleCount: number;          // 0 → empty state (web: noindex)
  followerCount: number;         // people who follow the field itself
  isFollowing: boolean;          // the caller follows the field; false for guests
  topics: FieldPageTopicDto[];   // every topic, editorial order, empty ones included
}

interface FieldPageTopicDto {    // a topic chip: filters with ?topic={slug}
  id: string;                    // for PUT/DELETE /me/interests/topics/{id}
  slug: string;
  name: string;                  // in Accept-Language
  nameAr: string; nameEn: string;
  articleCount: number;
  isFollowing: boolean;          // false for guests
}

interface ArticleDetailsDto extends ArticleCardDto {
  availableLanguages: ArticleLanguage[];
  summary: string | null;        // TL;DR plain text
  content: RDoc;                 // shared/rdoc/rdoc.schema.json
  topic: FieldRefDto | null;
  // tags: all of the article's visible tags here as TagRefDto (ArticleCardDto has the first 3); isFollowingAuthor comes from ArticleCardDto
  sources: { title: string; url: string }[];
  readCount: number;             // saveCount comes from ArticleCardDto
  collectionIds: string[];       // the caller's collections that hold it, oldest entry first; [] for guests and unsaved articles
  myProgress: MyProgressDto | null; // the caller's reading progress (F04 resume); null for guests and unopened articles
  moderation: { hiddenAt: string; note: string | null } | null; // hidden by a moderator (only its author and moderators see it)
  category: WriterCategoryRefDto | null; // F31: the writer's category of the article ("في قسم {name}"); null: none
  isFeatured: boolean;           // F23: featured on Explore (articles.feature holders show Feature / Unfeature in "⋯")
}

// Reports and moderation (F22)
type ReportReason = 'spam' | 'misinformation' | 'harassment' | 'copyright' | 'other';
type ModerationTargetType = 'article' | 'comment' | 'user';
type ReportStatus = 'open' | 'resolved' | 'dismissed';

interface ModerationQueueItemDto {
  targetType: ModerationTargetType;
  targetId: string;
  status: ReportStatus;          // the status filtered on
  reportCount: number;           // reports in this status
  reasons: Partial<Record<ReportReason, number>>;
  firstReportedAt: string;
  lastReportedAt: string;
  closedAt: string | null;       // resolved/dismissed lists
  target: ModerationTargetDto;
}

interface ModerationTargetDto {  // the fields of the other target types are null
  state: 'visible' | 'hidden' | 'deleted' | 'active' | 'suspended'; // article/comment: visible|hidden|deleted; user: active|suspended|deleted
  author: AuthorDto | null;      // article/comment author (null = deleted user); for a user target: the user
  title: string | null; slug: string | null; language: string | null;                                       // article
  body: string | null; articleId: string | null; articleSlug: string | null; articleTitle: string | null;    // comment
  suspendedUntil: string | null; // user: while suspended (null = permanent)
  warningCount: number | null;   // user: warnings so far
  links: ProfileLinkDto[] | null; // user: their social links now (F14), for clear_links; null for articles and comments
  // user: their title is author.headline (F14), for clear_headline
}

interface ModerationReportDto {
  id: string;
  reporter: UserSummaryDto | null; // null = the reporter deleted their account
  reason: ReportReason;
  details: string | null;
  status: ReportStatus;
  createdAt: string;
  closedAt: string | null;
  closedBy: UserSummaryDto | null;
}

interface ModerationCaseDto {
  item: ModerationQueueItemDto;  // status = open if any open report, else the latest closed status
  reports: ModerationReportDto[]; // all statuses, newest first
  history: ModerationActionDto[]; // actions on this target and, for article/comment, on its author's account; newest first (≤ 100)
  categories: WriterCategoryDto[]; // F31, user targets: all of the user's writer categories (empty ones too), in their order, for "clear the name" (clear_category); [] for articles and comments
}

interface ModerationActionDto {
  id: string;
  action: 'comment.hide' | 'comment.unhide' | 'comment.delete' | 'article.hide' | 'article.unhide'
        | 'user.warn' | 'user.suspend' | 'user.unsuspend' | 'user.clear_category' | 'user.clear_links' | 'user.clear_headline'
        | 'user.hide_content' | 'user.unhide_content' // F23
        | 'reports.dismiss'; // clear_category: F31; clear_links, clear_headline: F14
  targetType: ModerationTargetType;
  targetId: string;
  targetLabel: string | null;    // article title / first 80 characters of the comment / @username, at the time
  targetUser: UserSummaryDto | null; // the affected user (author or user target)
  moderator: UserSummaryDto | null;  // null = the moderator deleted their account
  note: string | null;
  suspendedUntil: string | null; // user.suspend: when it ends (null = permanent)
  reportsClosed: number;
  createdAt: string;
}

interface ModerationNoticeDto {
  id: string;
  kind: 'warning' | 'article_hidden';
  note: string | null;
  article: { id: string; slug: string; title: string } | null; // article_hidden
  createdAt: string;
}

// Writer verification (F19)
type VerificationStatus = 'pending' | 'approved' | 'rejected';

interface VerificationStatusDto {
  isVerified: boolean;           // the Verified badge (Users.IsVerified)
  canRequest: boolean;           // not verified, not suspended and nothing pending: show the form
  request: MyVerificationRequestDto | null; // the latest request, whatever its status
}

interface MyVerificationRequestDto {
  id: string;
  status: VerificationStatus;
  field: { id: string; slug: string; name: string }; // name in Accept-Language
  jobTitle: string;
  proofUrl: string | null;
  proofFileName: string | null;  // the uploaded file's (sanitized) name while pending; null once decided (the file is deleted)
  note: string | null;
  submittedAt: string;
  decidedAt: string | null;
  rejectionReason: string | null; // rejected only
}

interface AdminVerificationRequestDto {
  id: string;
  status: VerificationStatus;
  user: { id: string; displayName: string; username: string; avatarUrl: string | null; isVerified: boolean; headline: string | null }; // an AuthorDto; isVerified: has the badge now (offer "Remove badge"); headline: F14 title
  field: { id: string; slug: string; name: string };
  jobTitle: string;
  proofUrl: string | null;
  proof: { fileName: string; contentType: string; sizeBytes: number } | null; // download: GET …/{id}/proof (with the session)
  note: string | null;
  submittedAt: string;
  decidedAt: string | null;
  decidedBy: { id: string; username: string } | null; // null while pending, or once the reviewer deleted their account
  rejectionReason: string | null;
}

// Notifications (F17)
type NotificationType = 'new_follower' | 'article_comment' | 'comment_reply' | 'mention' | 'reactions_milestone' | 'announcement' // F23
  | 'followed_writer_article' | 'daily_article' | 'streak_reminder' | 'security_alert' | 'verification_result' | 'moderation_notice'
  | 'article_reposted'; // F29

type SecurityChange = 'passwordChanged' | 'passwordReset' | 'recoveryPinChanged' | 'phoneNumberChanged' | 'recoveryLockedOut'
  | 'externalLoginLinked' | 'externalLoginUnlinked' | 'phoneSignInAdded';

interface NotificationDto {
  id: string;
  type: NotificationType;
  createdAt: string; updatedAt: string;  // updatedAt = latest activity (the list order)
  isRead: boolean;
  actor: { id: string; displayName: string; username: string; avatarUrl: string | null; isVerified: boolean } | null; // latest actor
  actorCount: number;            // distinct actors (≥ 1 when actor-based, 0 otherwise): "X and {actorCount - 1} others"
  article: { id: string; slug: string; title: string; language: ArticleLanguage } | null; // your article language, else the source
  comment: { id: string; parentId: string | null; excerpt: string } | null;              // excerpt ≤ 140 chars, plain text, one line; null for a mention in an article
  data: { threshold?: number; streakDays?: number; securityChange?: SecurityChange; approved?: boolean; articleCount?: number; announcementId?: string; title?: string; body?: string }; // only the keys that apply; approved: verification_result; articleCount: the official @readin account's day entry (followed_writer_article, ≥ 1); announcementId/title/body: announcement (F23; title and body in Accept-Language; a test send has no announcementId)
  link: string;                  // readin://… (the same as the push's data.link)
}
// actor: also set for followed_writer_article (the writer); null for reactions_milestone, daily_article, streak_reminder,
// security_alert, moderation_notice (moderators stay anonymous), verification_result (the reviewer stays anonymous), and when every
// actor deleted their account ("Deleted user").
// verification_result: data.approved true = "You're now a verified writer ✓" / "بقيت كاتب موثّق ✓"; false = "Your
// verification request wasn't approved" / "طلب التوثيق بتاعك ماتقبلش"; missing = the generic text.
// moderation_notice: article set = "your article was hidden", article null = "you received a warning".

type NotificationMode = 'all' | 'inApp' | 'off';
interface NotificationSettingsDto {
  quietHours: { enabled: boolean; start: string; end: string };   // "HH:mm", your time zone; end exclusive, may be before start
  types: Partial<Record<Exclude<NotificationType, 'security_alert' | 'verification_result' | 'moderation_notice'>, NotificationMode>>;
}
// GET returns all 10 configurable types (article_reposted is the 9th, F29; announcement the 10th, F23); PUT may send any subset.

interface MyProgressDto {
  language: ArticleLanguage;     // the version the progress was recorded on
  percent: number;               // highest percent reached, 0–100
  lastPosition: string | null;   // as sent in ReadingProgressRequest, e.g. "0.4523"
  completedAt: string | null;    // set once the article counts as read
}

// Glossary (F21)
interface GlossaryTermDto {
  slug: string;                  // the RDoc termId, e.g. "dependency-injection"
  term: string;                  // English term, always shown LTR
  definitionEn: string;
  explanationAr: string;         // Egyptian Arabic with English terms (SPEC §14 BiDi rules apply)
  articles: GlossaryArticleDto[]; // ≤ 6 published articles that use the term, best first; the reader drops the open one and shows ≤ 5
}

interface GlossaryArticleDto {
  id: string; slug: string;
  language: ArticleLanguage;     // language of `title`
  title: string;
  readingTimeMinutes: number;
  field: FieldRefDto;
}

interface GlossaryTermSummaryDto { slug: string; term: string; definitionEn: string }

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
  author: AuthorDto | null;      // null: "Deleted user" (or a placeholder). author.headline: the title under the name, instead of @username
  isAuthorMuted: boolean;        // F28: the caller muted the author: collapse to "تعليق من شخص كتمته" + "عرض" (expands locally); replies stay. false for guests and placeholders
  isFollowingAuthor: boolean;    // the caller follows the comment's author ("متابعة" shows when false and it isn't you); false for guests, own comments, deleted authors and placeholders
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

// ── Continue reading (F03) and learning paths (F09) ──
interface ContinueReadingDto {
  article: ArticleCardDto;       // in the version you were reading (`language`)
  percent: number;               // 5–100, how far you scrolled
  language: ArticleLanguage;
  updatedAt: string;             // your last progress report
}

interface PathCardDto {
  id: string;
  slug: string;
  title: string;                 // in the UI language
  description: string | null;    // in the UI language
  field: FieldRefDto;
  articleCount: number;          // articles a reader can open
  readingTimeMinutes: number;    // sum of their reading times, in the versions served to you
  coverUrl: string | null;       // absolute; the first article's cover
  progress: PathProgressDto | null;     // signed in (also when not enrolled); on a profile, that user's. null for guests
  enrollment: PathEnrollmentDto | null; // null when not enrolled, and for guests
}

interface PathProgressDto {
  readCount: number;             // articles of the path read (F04 "read")
  total: number;                 // = articleCount
  percent: number;               // floor(readCount * 100 / total)
  next: PathArticleRefDto | null; // first unread article in path order; null when all are read
}

interface PathEnrollmentDto {
  enrolledAt: string;
  completedAt: string | null;    // the completion badge; stays when the path grows (then readCount < total)
}

interface PathArticleRefDto {
  id: string; slug: string;
  title: string;                 // in your article language (falls back to the source language)
  language: ArticleLanguage;
  position: number;              // 1-based place in the path
  readingTimeMinutes: number;
}

interface PathItemDto { position: number; article: ArticleCardDto; isRead: boolean } // isRead false for guests
interface PathDetailsDto extends PathCardDto { items: PathItemDto[] }  // path order

interface ArticlePathDto {
  path: PathCardDto;             // in several paths: the one you're enrolled in with the latest activity, else the first
  position: number;              // this article's place, 1-based
  total: number;
  previous: PathArticleRefDto | null;
  next: ArticleCardDto | null;   // the following article in path order (read or not); null on the last one
}

interface UpsertPathRequest {
  slug: string;                  // kebab-case, 3–100 (validation code validation.slug)
  fieldId: string;
  titleAr: string; titleEn: string;                             // 1–200
  descriptionAr?: string | null; descriptionEn?: string | null; // ≤ 500
  sortOrder: number;             // ≥ 0; editorial paths use 1..N
  isPublished: boolean;
}

interface AdminPathDto {
  id: string; slug: string; fieldId: string;
  titleAr: string; titleEn: string; descriptionAr: string | null; descriptionEn: string | null;
  sortOrder: number; isPublished: boolean; isEditorial: boolean;
  articleIds: string[];          // path order
  enrollmentCount: number;
  isFeatured: boolean;           // F23: in Explore's featured paths (shown only while published)
  featuredOrder: number | null;  // F23: 1-based place among the featured; null when not featured
}
```

Validation codes (in `errors`) for this area: `reaction.invalid` (`type`), `validation.required` /
`validation.max_length` (`name` of a collection, `q`). Error codes: `collection.not_found`, `collection.name_taken`,
`collection.limit`, `follow.self`, `topic.not_found`.

```ts
// ── Article PDF (F33) ───────────────────────────────────────────────
// GET /articles/{id}/pdf answers the file itself (application/pdf, see Article PDF), never JSON; its errors are
// ProblemDetails. F33 adds no DTO of its own. Clients read:
//   reader:      ArticleDetailsDto.id, .language (the version on screen, sent as `lang`); every article has the item, except
//                someone else's hidden one (.moderation set, .author?.id not your id); guests get the sign-in prompt
//   My articles: MyArticleDto.id, .status === 'published', .publishedLanguages (added in F33; two entries → ask which)
//   file name:   Content-Disposition filename* (RFC 5987) → "{slug}-{lang}.pdf"; fallback filename "readin-article.pdf"
```

```ts
// ── Admin console (F23) ─────────────────────────────────────────────
interface PagedList<T> {         // offset pages of the admin tables (§17.1)
  items: T[];
  page: number;                  // 1-based, as used (below 1 → 1)
  pageSize: number;              // as used (1–100, default 50)
  totalCount: number;
  totalPages: number;            // ceil(totalCount / pageSize); 0 when empty
}

interface AdminSummaryDto {      // GET /admin/summary: the badge on the console entry
  openReports: number | null;    // targets with open reports (= /moderation/summary open.total); null without moderation.manage
  openTickets: number | null;    // tickets in Open (waiting for support); null without support.manage
  pendingVerifications: number | null; // null without verification.manage
  total: number;                 // the badge: the sum of the three that aren't null
}

type AdminPeriod = 'today' | 'yesterday' | '7d' | '30d';

interface AdminDashboardDto {
  period: AdminPeriod;
  timeZone: string;              // Admin:TimeZone, e.g. "Africa/Cairo"
  from: string; to: string;      // the window, ISO UTC, end exclusive (now for today, 7d and 30d)
  fromDate: string; toDate: string; // the same window as local dates "YYYY-MM-DD", both included: Content's from / to
  generatedAt: string;           // when the numbers were computed (≤ 60 s ago)
  cards: DashboardCardsDto;
  charts: DashboardDayDto[];     // the last 30 local days up to today, oldest first, zeros included (any period)
  topArticles: DashboardArticleDto[];         // ≤ 10, most reads in the period first
  topWriters: DashboardWriterDto[];           // ≤ 10
  missedSearches: DashboardMissedSearchDto[]; // ≤ 20, most misses first
  streakRetention: { cohort: number; kept: number; rate: number | null }; // rate 0–1 (3 decimals), null when cohort is 0
  contentPipeline: ContentPipelineDto;
}

interface DashboardValueDto {
  value: number;                 // this period
  previous: number;              // the previous period of the same length; change = value - previous
}

interface DashboardCardsDto {
  articlesPublished: DashboardValueDto;
  newUsers: DashboardValueDto & { phone: number; google: number; apple: number }; // value split by sign-up method
  activeReaders: DashboardValueDto;
  reads: DashboardValueDto;
  comments: DashboardValueDto;
  reactions: DashboardValueDto;
  reposts: DashboardValueDto;
  openReports: number | null;    // now (no previous); null without moderation.manage
  openTickets: number | null;    // now; null without support.manage
  pendingVerifications: number | null; // now; null without verification.manage
  suspendedNow: number;          // accounts suspended right now
}

interface DashboardDayDto { date: string; newUsers: number; activeReaders: number; articlesPublished: number } // date "YYYY-MM-DD"

interface DashboardArticleDto {
  id: string; slug: string;
  title: string; language: ArticleLanguage; // the caller's UI-language version (ar → ar-EG), else the source
  author: AuthorDto | null;      // null = deleted account
  field: FieldRefDto;
  publishedAt: string;
  reads: number;                 // reads in the period
}

interface DashboardWriterDto {
  writer: AuthorDto;
  reads: number;                 // reads of their articles in the period
  articles: number;              // how many of their articles were read in it
}

interface DashboardMissedSearchDto { query: string; language: 'ar' | 'en'; count: number } // render query with dir="auto"

interface ContentPipelineDto {
  folders: number;               // article folders (meta.json) in content/articles
  seeded: number;                // @readin articles in the database (any status, not deleted)
  published: number;             // of those, articles readers can open now
  lastSeedRunAt: string | null;  // the newest SeedHistory.AppliedAt
}

type SignInMethod = 'phone' | 'google' | 'apple'; // phone = phone number + password

interface AdminUserRowDto {      // a row of GET /admin/users
  id: string; displayName: string; username: string; avatarUrl: string | null;
  isVerified: boolean;
  isSystemAccount: boolean;      // the official @readin account
  roles: string[];               // ["Member"] or ["SuperAdmin"]: display only
  signInMethods: SignInMethod[]; // the ways the account can sign in now
  phoneMasked: string | null;    // "+20***1234"; null without a phone number. The full one: GET /admin/users/{id}/phone
  joinedAt: string;
  lastSeenAt: string | null;     // UserPresence.LastSeenAt, to the hour; null = not seen since F23 shipped
  publishedArticles: number;     // articles readers can open
  followers: number;
  status: 'active' | 'suspended';
  suspendedUntil: string | null; // suspended: when it ends, null = permanently; null when active
  openReports: number;           // open reports about the user, their articles and their comments
}

interface AdminUserDto extends AdminUserRowDto { // GET /admin/users/{id}: a user's page
  headline: string | null; bio: string | null; links: ProfileLinkDto[];
  uiLanguage: UiLanguage;
  signUpMethod: SignInMethod | null; // null for system accounts
  isStaff: boolean;              // yourself, an admin.access / moderation.manage holder or a system account: can't be suspended, warned or signed out
  stats: {
    drafts: number; comments: number; following: number; totalReads: number; // totalReads: reads of their articles
    articlesRead: number; currentStreak: number; longestStreak: number;       // their own reading
  };
  access: {
    activeSessions: number;      // signed-in devices: unexpired, unrevoked refresh-token families
    hasRecoveryPin: boolean; recoveryDisabled: boolean;
    mustChangePassword: boolean; mustSetRecoveryPin: boolean;
    lockedOutUntil: string | null; // sign-in lockout (5 wrong passwords)
  };
  actions: {                     // what THIS caller may do to this account now (permissions + protected accounts)
    canSuspend: boolean;         // moderation.manage + users.suspend, not isStaff
    canWarn: boolean;            // moderation.manage, not isStaff
    canLogoutAll: boolean;       // users.suspend, not isStaff
    canResetPassword: boolean;   // users.reset_password, a phone + password account holding no permission the caller lacks
    canRemoveBadge: boolean;     // verification.manage, isVerified, not a system account
    canClearProfile: boolean;    // moderation.manage (clear_headline / clear_links)
    canRestoreContent: boolean;  // moderation.manage and moderation.hiddenWithAccount > 0
    canRevealPhone: boolean;     // users.read.pii and a phone number
  };
  moderation: {                  // null without moderation.manage
    warnings: number; suspensions: number;
    hiddenArticles: number; hiddenComments: number; // hidden now, any way
    hiddenWithAccount: number;   // of those, hidden by hide_content (what unhide_content restores)
    history: ModerationActionDto[]; historyTotal: number; // actions about the user and their content, newest 20
  } | null;
  reports: {                     // null without moderation.manage
    against: AdminUserReportDto[]; againstTotal: number; // about the user, their articles and comments, newest 20
    filed: AdminUserReportDto[]; filedTotal: number;     // reports they filed, newest 20
  } | null;
  verification: { items: AdminVerificationRequestDto[]; total: number } | null; // newest 20; null without verification.manage
  tickets: { items: AdminTicketRowDto[]; total: number } | null;                // newest 20; null without support.manage
  audit: { items: AuditEntryDto[]; total: number } | null;                      // entries about them, newest 20; null without audit.read
}

interface AdminUserReportDto {
  id: string;
  targetType: ModerationTargetType; targetId: string;
  targetLabel: string | null;    // article title, first 80 characters of the comment, or @username; null once deleted
  reason: ReportReason; details: string | null;
  status: ReportStatus;
  createdAt: string;
  reporter: UserSummaryDto | null; // in `against`; null in `filed`, or once the reporter deleted their account
}

interface AdminArticleRowDto {   // GET /admin/articles, GET /admin/articles/{id}
  id: string; slug: string;
  status: 'published' | 'archived';
  title: string; language: ArticleLanguage; // the caller's UI-language version, else the source
  author: AuthorDto | null;
  field: FieldRefDto; topic: FieldRefDto | null;
  publishedAt: string | null;    // null: archived without ever being published
  readCount: number; reactionCount: number; commentCount: number;
  hiddenAt: string | null;       // hidden by a moderator
  featuredAt: string | null;     // featured (F23)
  openReports: number;
  reportCount: number;           // any status: > 0 → the F22 case exists
}

interface AdminCommentRowDto {   // GET /admin/comments
  id: string;
  body: string;                  // in full; render dir="auto"
  author: AuthorDto | null;
  article: { id: string; slug: string; title: string; language: ArticleLanguage };
  parentId: string | null;       // a reply: its top-level comment
  createdAt: string; editedAt: string | null;
  hiddenAt: string | null;
  likeCount: number; replyCount: number;
  openReports: number; reportCount: number;
}

interface AdminTaxonomyDto {     // GET /admin/fields
  fields: AdminFieldDto[];       // display order
  icons: string[];               // the icon names both clients draw (Lucide), A–Z
  colors: string[];              // the color tokens both clients draw
}

interface AdminFieldDto {
  id: string; slug: string;      // the slug never changes (/f/{slug}, the seeder's key)
  nameAr: string; nameEn: string;
  icon: string; color: string;
  sortOrder: number;
  isSensitive: boolean; requiresSources: boolean; isEnabled: boolean;
  inTaxonomyFile: boolean;       // listed in content/taxonomy.yaml
  customizedAt: string | null;   // set by the first console change: the seeder leaves the row alone from then on
  articleCount: number;          // articles readers can see in it (what disabling would hide)
  topics: AdminTopicDto[];       // display order
}

interface AdminTopicDto {
  id: string; fieldId: string; slug: string;
  nameAr: string; nameEn: string;
  sortOrder: number;
  isEnabled: boolean;
  inTaxonomyFile: boolean;
  customizedAt: string | null;   // console-created topics have it from the start
  articleCount: number;
}

interface CreateFieldRequest {
  slug: string;                  // kebab-case, 2–64 (validation.slug)
  nameAr: string; nameEn: string; // 1–100
  icon: string; color: string;   // from AdminTaxonomyDto.icons / colors
  isSensitive: boolean; requiresSources: boolean; isEnabled: boolean;
}
interface UpdateFieldRequest {   // the whole row but the slug (the form sends every value back)
  nameAr: string; nameEn: string; icon: string; color: string;
  isSensitive: boolean; requiresSources: boolean; isEnabled: boolean;
}
interface CreateTopicRequest { fieldId: string; slug: string; nameAr: string; nameEn: string; isEnabled: boolean }
interface UpdateTopicRequest { nameAr: string; nameEn: string; isEnabled: boolean }
interface OrderRequest { ids: string[] } // PUT /admin/fields/order, PUT /admin/fields/{id}/topics/order

interface AdminTagDto {
  id: string; slug: string; name: string;
  articleCount: number;          // published articles readers can see (as TagDto)
  taggedCount: number;           // every article that carries it, hidden ones too: what a merge moves
  isHidden: boolean;
  isSystem: boolean;             // used by the seed content: never cleaned up
  createdAt: string;
  createdBy: { id: string; username: string } | null; // null: a system tag, or the creator deleted their account
  emptySince: string | null;     // a user tag with no published article since then (the daily cleanup deletes it after 30 days)
  aliases: string[];             // old spellings and merged names that lead here, oldest first
}

// AdminPathDto (Path admin, F09) gains:
//   isFeatured: boolean;          // in Explore's "Featured paths" (shown only while published)
//   featuredOrder: number | null; // 1-based place among the featured; null when not featured
interface SetFeaturedPathsRequest { pathIds: string[] } // 0–20, Explore order

type AnnouncementAudience =
  | { type: 'all' }
  | { type: 'field'; fieldId: string }             // accounts following the field or one of its topics
  | { type: 'language'; language: ArticleLanguage }; // accounts with that article language

interface AnnouncementRequest {  // POST /admin/announcements, /preview, /test
  titleAr: string; titleEn: string; // 1–60 after trimming
  bodyAr: string; bodyEn: string;   // 1–180
  link: { type: 'article' | 'path'; id: string } | null;
  audience: AnnouncementAudience;
}

interface AnnouncementPreviewDto {
  recipientCount: number;        // accounts that get the entry (announcement not "off")
  pushCount: number;             // of those, with push on ("all") and at least one device
  canSend: boolean;              // no announcement sent today yet
  nextAllowedAt: string | null;  // when canSend is false: the next local midnight (ISO UTC)
}

interface AnnouncementDto {
  id: string;
  titleAr: string; titleEn: string; bodyAr: string; bodyEn: string;
  link: { type: 'article' | 'path'; id: string; slug: string; title: string } | null; // title in the caller's UI language
  audience: { type: 'all' | 'field' | 'language'; field: { id: string; slug: string; name: string } | null; language: ArticleLanguage | null };
  status: 'sending' | 'sent';
  recipientCount: number;        // while sending: the preview's count; final once sent
  sentBy: { id: string; username: string } | null; // null once that account is deleted
  createdAt: string;
  completedAt: string | null;
}

interface AnnouncementsDto {     // GET /admin/announcements
  canSend: boolean;
  nextAllowedAt: string | null;
  items: AnnouncementDto[];      // the latest 50, newest first
}

interface AuditUserDto { id: string; displayName: string; username: string; avatarUrl: string | null }

interface AuditEntryDto {        // GET /admin/audit
  id: string;
  source: 'audit' | 'moderation'; // AuditLogs or ModerationActions
  action: string;                // audit: e.g. "admin.pii_viewed"; moderation: ModerationActionDto.action, e.g. "user.suspend"
  actor: AuditUserDto | null;    // null: a job, an anonymous flow (recovery), or a deleted account
  targetUser: AuditUserDto | null; // the account it concerns
  target: { type: 'user' | 'article' | 'comment' | 'field' | 'topic' | 'tag' | 'path' | 'announcement' | 'ticket'; id: string; label: string | null } | null;
  details: string | null;        // AuditLogs.Details or the moderation note; data, never personal data: dir="auto"
  ip: string | null;             // users.read.pii only; null on moderation rows
  createdAt: string;
}

interface AdminSystemDto {       // GET /admin/system
  api: { version: string; startedAt: string; environment: string };
  updatePolicy: UpdatePolicyDto; // as GET /app/update-policy
  database: { reachable: boolean; latencyMs: number | null };
  firebase: { messagingConfigured: boolean; realtimeConfigured: boolean; realtimeReachable: boolean | null };
  jobs: AdminJobStatusDto[];     // every recurring job, A–Z
  push: { sent: number; failed: number; invalidTokens: number; since: string }; // the last 24 hours (since = its start)
  storage: { uploadsBytes: number; uploadsFiles: number; privateBytes: number; privateFiles: number; measuredAt: string };
}

interface AdminJobStatusDto {
  id: string;                    // the Hangfire recurring job id, e.g. "notification-push"
  schedule: string;              // its cron expression
  lastRunAt: string | null;
  lastSucceeded: boolean | null;
  lastDurationMs: number | null;
  lastError: string | null;      // the exception's type and message, ≤ 500
  runs24h: number; failures24h: number;
}

// ProfileDto (F14) gains:
//   admin: { isSuspended: boolean; suspendedUntil: string | null; isStaff: boolean } | null; // users.read holders only
// ArticleDetailsDto gains:  isFeatured: boolean;
// ExploreDto gains:         featuredArticles: ArticleCardDto[]; // ≤ 6, most recently featured first; [] hides the section
// ModerationActionRequest gains: hideContent?: boolean;  // suspend only; actions hide_content / unhide_content on a user
// ModerationActionDto.action adds: 'user.hide_content' | 'user.unhide_content'
// NotificationType adds:    'announcement' | 'support_reply' | 'support_ticket'
// NotificationDto.data adds (only the keys that apply):
//   announcement:                  announcementId: string; title: string; body: string  // its text in Accept-Language
//   support_reply, support_ticket: ticketId: string; ticketNumber: number; subject: string
//   support_reply:                 closed?: boolean  // true: support closed the ticket
// NotificationDto.actor: support_ticket → the member (latest); announcement, support_reply → null (support stays anonymous)

// ── Support (F35) ───────────────────────────────────────────────────
type SupportCategory = 'app_problem' | 'account' | 'content' | 'verification' | 'suggestion' | 'other';
type SupportStatus = 'open' | 'answered' | 'closed';

interface SupportConfigDto {     // GET /support/config 🌐
  email: string | null;          // Support:Email; null when not set (hide it)
  categories: SupportCategory[]; // in display order
  maxAttachments: number;        // 3
  maxAttachmentBytes: number;    // 5 MB
  attachmentTypes: string[];     // ["image/jpeg", "image/png", "image/webp"]
}

interface SupportDeviceDto {
  platform: 'ios' | 'android' | 'web' | null;
  osVersion: string | null;      // e.g. "iOS 18.1", "Android 15", "Windows · Chrome 131"
  appVersion: string | null;     // e.g. "1.2.0+57"
  language: UiLanguage | null;   // the UI language when sent
  screen: string | null;         // the route it came from
}

interface SupportAttachmentDto {
  id: string;
  contentType: 'image/jpeg' | 'image/png' | 'image/webp';
  sizeBytes: number;
  // GET /support/attachments/{id} with the session; never cache it
}

interface SupportMessageDto {
  id: string;
  fromSupport: boolean;          // true: «فريق الدعم» / "Support" (no admin name); false: you
  body: string;                  // render dir="auto"
  attachments: SupportAttachmentDto[]; // ≤ 3; support's replies have none
  createdAt: string;
}

interface SupportTicketSummaryDto { // My tickets
  id: string;
  number: number;                // "#12"
  category: SupportCategory;
  subject: string;
  status: SupportStatus;
  createdAt: string;
  updatedAt: string;             // the latest message: the list order
  lastMessage: { fromSupport: boolean; excerpt: string; createdAt: string }; // excerpt ≤ 140 characters, one line
  closedAt: string | null;
  canReopen: boolean;            // closed less than 30 days ago
}

interface SupportTicketDto extends SupportTicketSummaryDto {
  device: SupportDeviceDto;
  messages: SupportMessageDto[]; // oldest first; never internal notes
}

interface AdminTicketRowDto {    // GET /admin/support/tickets
  id: string; number: number;
  category: SupportCategory; subject: string; status: SupportStatus;
  user: AuthorDto;               // the member (a ticket goes with its account)
  createdAt: string;
  waitingSince: string | null;   // Open: the member's last message ("waiting 3 h"); null otherwise
  lastMessage: { fromSupport: boolean; isInternalNote: boolean; excerpt: string; createdAt: string };
  closedAt: string | null;
}

interface AdminSupportMessageDto extends SupportMessageDto {
  isInternalNote: boolean;       // only admins see notes
  author: { id: string; displayName: string; username: string } | null; // the member or the admin; null once that account is deleted
}

interface AdminTicketDto extends AdminTicketRowDto { // GET /admin/support/tickets/{id}
  device: SupportDeviceDto;
  messages: AdminSupportMessageDto[]; // oldest first, internal notes included
  closedBy: 'member' | 'support' | 'auto' | null;
  member: {                      // the user card; links to /admin/users/{id}
    status: 'active' | 'suspended'; suspendedUntil: string | null;
    joinedAt: string;
    signInMethods: SignInMethod[];
    ticketCount: number;         // all their tickets
  };
  reportsFiled: { items: AdminUserReportDto[]; total: number } | null; // their reports, newest 10; null without moderation.manage
  reportsAgainst: number | null;                                        // open reports about them, their articles and comments
  moderation: ModerationActionDto[] | null; // warnings and suspensions about them, newest 10; null without moderation.manage
}
```

## Push payloads (FCM)

Pushes come only from background jobs and outbox handlers (SPEC §21.1), to every token registered with `POST /me/devices`.
Each has a visible `notification` (`title`, `body`, in the user's UI language) and a `data` map of strings. `data.link`
is always the deep link to open (`readin://…`, see Notifications); clients map it to their own route and drop anything
else. Every push of F17 also carries `data.notificationId`: on a tap, call `POST /me/notifications/{id}/read`.
Tokens FCM reports as unregistered or invalid are deleted by the API.

New deep links with F17: `readin://u/{username}/followers`, `readin://me/stats`, `readin://settings/account` and
`readin://notifications` (the center), next to `readin://a/{slug}` (with an optional `#comment-{id}`) and
`readin://u/{username}`. Where they land: `me/stats` is the reading stats page on mobile and your own profile on the web
(where the stats are); `settings/account` is the Account section of Settings (`/settings?section=account` on mobile,
`/settings#account` on the web).

New deep link with F19: `readin://verification`, the writer verification page (`/verification` on the web,
`/settings/verification` on mobile).

### Notifications (F17)

Every notification type except `daily_article` is pushed by the notification push job (every minute, and right after
an entry is written), for entries whose type is on `all`:

```jsonc
{
  "notification": { "title": "أحمد و9 غيره علّقوا على مقالك", "body": "<the latest comment>" },
  // en: "Ahmed and 9 others commented on your article"
  "data": {
    "type": "article_comment",          // the NotificationType
    "notificationId": "0a1b2c3d-…",     // POST /me/notifications/{id}/read on a tap
    "link": "readin://a/rag-vs-fine-tuning#comment-0a1b…",
    "lang": "en"                        // article links only: the version the text came from, "ar" (ar-EG) | "en"
  }
}
```

| `type` | Title (ar / en) | Body |
|---|---|---|
| `new_follower` | "{name} بدأ يتابعك" / "{name} started following you"; more: "{name} و{n} غيره بدأوا يتابعوك" / "{name} and {n} others started following you" | empty |
| `article_comment` | "{name} علّق على مقالك" / "{name} commented on your article"; more: "{name} و{n} غيره علّقوا على مقالك" / "{name} and {n} others commented on your article" | the latest comment (≤ 140 characters) |
| `comment_reply` | "{name} ردّ على تعليقك" / "{name} replied to your comment"; more: "… و{n} غيره ردّوا على تعليقك" / "… and {n} others replied to your comment" | the reply |
| `mention` | in a comment: "{name} عمل لك منشن في تعليق" / "{name} mentioned you in a comment"; in an article (no comment): "{name} عمل لك منشن في مقال" / "{name} mentioned you in an article" | the comment; in an article: the article's title |
| `reactions_milestone` | "مقالك وصل لـ {threshold} رياكشن 🎉" / "Your article reached {threshold} reactions 🎉" | the article's title |
| `followed_writer_article` | "نشر {name} مقالًا جديدًا" / "{name} published a new article"; the official @readin account's day entry with 2 or more articles: "نشر {name} مقالين جديدين" / "نشر {name} {n} مقالات جديدة" / "نشر {name} {n} مقالًا جديدًا" / "نشر {name} {n} مقال جديد" (Arabic plural forms of `n`) / "{name} published {n} new articles" | the article's title (@readin: the newest one). @readin: sent 10 minutes after its latest article, collapse key `followed_writer_article:{accountId}:{yyyy-MM-dd}`, `data.link` = `readin://u/readin` from 2 articles |
| `streak_reminder` | "متضيّعش الـ streak بتاعك 🔥" / "Don't lose your streak 🔥" | "الـ streak بتاعك {n} يوم…" / "Your streak is {n} days. Read an article today to keep it going." |
| `security_alert` | "تنبيه أمان" / "Security alert" | what changed, e.g. "Your password was changed. If this wasn't you, reset it now." |
| `verification_result` | approved: "بقيت كاتب موثّق ✓" / "You're now a verified writer ✓"; rejected: "طلب التوثيق بتاعك ماتقبلش" / "Your verification request wasn't approved" | approved: empty; rejected: "افتحه عشان تعرف السبب" / "Open it to see why" (never the reason). `data.link` = `readin://verification`; collapse key `verification_result` |
| `moderation_notice` | as below | as below |
| `article_reposted` (F29) | "{name} أعاد نشر مقالك" / "{name} reposted your article"; more: "{name} و{n} غيره أعادوا نشر مقالك" / "{name} and {n} others reposted your article" | the article's title. `data.link` = `readin://a/{slug}` (with `data.lang`); collapse key `article_reposted:{articleId}` |

`{n}` is the number of other actors (one other: "وشخص تاني" / "and 1 other"); names are wrapped in Unicode isolates
(U+2068 … U+2069) so a Latin name keeps its place in an Arabic sentence. A deleted actor is "مستخدم محذوف" / "Deleted user".

| Item | Rule |
|---|---|
| Collapse key (Android collapse key and tag, `apns-collapse-id`, web `tag`) | the entry's group (`article_comment:{articleId}`, `comment_reply:{commentId}`, `new_follower:{yyyy-MM-dd}`, `article_reposted:{articleId}`), otherwise the type: a newer push of the group replaces the older one |
| Quiet hours | held until they end (user's time zone); `security_alert` ignores them |
| Checked when sending | the type is still on `all`; the comment or article is still there (a mention in an article: its article is still readable); a moderation notice isn't acknowledged yet; the account isn't suspended |
| Too late | dropped when the entry's last activity is more than 24 hours old (`streak_reminder`: 4 hours); TTL = what is left of that |
| Failures | tokens FCM reports as invalid are deleted; other failures are retried after 1 and 5 minutes, 3 sends in all |

### Daily article (`daily_article`, SPEC F07)

Sent once a day at the user's `reminderTime`, in their `timeZone`, for the article `GET /feed/today` returns that day,
by the daily-article job itself (not the push job). It is also an entry in the center.

```jsonc
{
  "notification": { "title": "مقال النهارده جاهز ☕", "body": "<article title>" }, // en: "Today's article is ready ☕"
  "data": {
    "type": "daily_article",
    "notificationId": "0a1b2c3d-…", // F17: its entry in the center
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

No push when the user already read that day's article, when the account is suspended or has no device, when the user
set `daily_article` to `inApp` (entry only) or `off` (nothing), or when the push would be more than 2 hours late (the
article stays the hero card either way). In quiet hours the push waits for them to end, within those 2 hours.

### Moderation notice (`moderation_notice`, SPEC F22)

Pushed once by the notification push job (F17 took it over from F22) when a moderator warns the user or hides their
article. The notice itself waits in `GET /me/moderation-notices` either way, so a lost push loses nothing, and a notice
acknowledged before its push went out isn't pushed.

```jsonc
{
  "notification": { "title": "فريق الإشراف خفى مقالك", "body": "<article title>" }, // en: "The moderators hid your article"
  // warning: title "وصلك تحذير من فريق الإشراف" (en: "You received a warning from the moderators"), body = the note
  "data": {
    "type": "moderation_notice",
    "notificationId": "0a1b2c3d-…",
    "noticeId": "0a1b2c3d-…",
    "kind": "article_hidden",    // | "warning"
    "link": "readin://a/rag-vs-fine-tuning", // a warning: "readin://notifications"
    "articleId": "…", "slug": "rag-vs-fine-tuning", "lang": "en" // article_hidden only
  }
}
```

A warning links to the center; the app shows the notice itself from `GET /me/moderation-notices`. Collapse key and tag
`moderation_notice`; quiet hours apply; dropped after 24 hours like every F17 push.

### Announcements, support replies and new tickets (`announcement` SPEC F23; `support_reply`, `support_ticket` SPEC F35)

Pushed by the notification push job like every F17 type (checked when sending, dropped after 24 hours, invalid tokens
removed), in the recipient's UI language (Modern Standard Arabic, SPEC §14.4).

```jsonc
// announcement: title and body are the announcement's own, in the recipient's UI language
{
  "notification": { "title": "<titleAr | titleEn>", "body": "<bodyAr | bodyEn>" },
  "data": {
    "type": "announcement",
    "notificationId": "0a1b2c3d-…",
    "announcementId": "0a1b2c3d-…",
    "link": "readin://a/rag-vs-fine-tuning", // or "readin://paths/{slug}", or "readin://notifications" without a link
    "lang": "en"                             // article links only: the version to open, "ar" (ar-EG) | "en"
  }
}
// support_reply
{
  "notification": { "title": "ردّ فريق الدعم على تذكرتك", "body": "#12 · <subject>" },
  // en: "Support replied to your ticket"; closed by support: «أُغلقت تذكرتك» / "Your ticket was closed"
  "data": { "type": "support_reply", "notificationId": "…", "ticketId": "…", "link": "readin://support/0a1b2c3d-…" }
}
// support_ticket (holders of support.manage)
{
  "notification": { "title": "رسالة دعم جديدة من ⁨Ahmed⁩", "body": "#12 · <subject>" },
  // en: "New support message from Ahmed"
  "data": { "type": "support_ticket", "notificationId": "…", "ticketId": "…", "link": "readin://admin/support/0a1b2c3d-…" }
}
```

| `type` | Quiet hours | Settings | Collapse key | Row text in the center (clients) |
|---|---|---|---|---|
| `announcement` | apply | configurable ("الإعلانات" / "Announcements", hint "إعلانات من فريق ReadIn" / "News from the ReadIn team") | `announcement:{announcementId}` | `data.title`, then `data.body` |
| `support_reply` | apply | always comes (like `verification_result`) | `support_reply:{ticketId}` | «ردّ فريق الدعم على تذكرتك» / "Support replied to your ticket" (`data.closed`: «أُغلقت تذكرتك» / "Your ticket was closed"), then `#{ticketNumber} · {subject}` |
| `support_ticket` | apply | configurable, holders of `support.manage` only ("تذاكر الدعم" / "Support tickets") | `support_ticket:{ticketId}` | «رسالة دعم جديدة من {name}» / "New support message from {name}", then `#{ticketNumber} · {subject}` |

Names are wrapped in Unicode isolates (U+2068 … U+2069), as in every F17 push. Checked when sending: an announcement's
recipient still has the type on `all`; a support entry's ticket still exists; the account isn't suspended.

New deep links: `readin://paths/{slug}` (a learning path: web `/paths/{slug}`, mobile `/paths/{slug}`),
`readin://support/{ticketId}` (the member's ticket: web `/support/tickets/{id}`, mobile
`/settings/support/tickets/{id}`) and `readin://admin/support/{ticketId}` (the console's ticket: web
`/admin/tickets/{id}`, mobile the console's ticket page; a client without `support.manage` opens the notification
center instead).

## Local development

- API: `http://localhost:5080` (Scalar UI: `/docs`, OpenAPI: `/openapi/v1.json`)
- Seeded demo users (SPEC §18.3): `+12025550110` (reader1) … with the password from `Seed:DemoPassword` and the recovery PIN from `Seed:DemoPin`. Neither is committed; set them once with `dotnet user-secrets set "Seed:DemoPassword" "<password>" --project backend/src/ReadIn.Api` and `dotnet user-secrets set "Seed:DemoPin" "<4 digits>" --project backend/src/ReadIn.Api`. Without a password you can't sign in as them; without a PIN they must set one after signing in.

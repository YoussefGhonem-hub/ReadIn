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

Clients translate `code` (and each validation error code) with their own `ar`/`en` strings, and use `title` only as a fallback. Stable codes: `validation.failed`, `auth.unauthorized`, `auth.forbidden`, `user.suspended`, `user.not_found`, `user.username_taken`, `user.interests.min_three`, `field.not_found`, `topic.not_found`, `article.not_found`, `rate_limited`, `server.error`, plus the auth, social, profile, path, editor, media, notification and verification codes below. Editor: `article.not_found`, `article.not_owner`, `article.draft_conflict`, `article.not_published`, `article.revision_not_found`, `article.status_invalid`, `field.not_found`, `topic.not_in_field`, `article.no_content`, `article.invalid_transition`, `article.slug_taken`, `article.content_language_mismatch`, the validation codes `article.language_invalid`, `article.too_many_tags` and `tag.invalid`, and the problem codes listed with `DraftProblemDto`. Tags: `tag.not_found`, `tag.invalid`, `article.too_many_tags`, `tag.hidden`, `tag.limit` (see Tags). Search: `search.query_invalid`, `search.type_invalid`, `search.filter_invalid` (see Search). Writer categories: `category.not_found`, `category.not_owner`, `category.limit`, `category.name_taken`, `category.name_invalid` (see Writer categories). `article.too_many_tags` replaced `article.tags.max_five` in F32; the server no longer sends the old code, and clients may keep translating it.

`403 user.suspended` (every Bearer call of a suspended account, and sign in, refresh and Google/Apple sign in) also carries
`suspendedUntil`: when the suspension ends (ISO UTC), or `null` for a permanent one (F22). Clients show "موقوف لحد {date}" /
"موقوف نهائيًا".

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
| PATCH | `/me` | `UpdateProfileRequest` → `204`; refetch `GET /me`. `409 user.username_taken`, `400 profile.avatar_invalid`, `400 profile.expertise_invalid`, validation codes as before (`displayName`, `username`, `bio`, `links.*`, `avatarUrl`) |
| PUT | `/me/privacy` | `{ publicReadingStats?: boolean, whoCanMention?: MentionPolicy }` → `204` (Settings → Privacy, F18; shown in `MeDto.privacy`). Each field is optional (left out = unchanged), so a client that only sends `publicReadingStats` keeps working; clients send the whole privacy object back. `400 validation.failed` with `validation.required` on both fields when neither is sent, `validation.invalid` for an unknown number; an unknown name is a `400` before validation. Nothing changes on an error. `whoCanMention` applies from then on: existing comments keep their mentions |
| DELETE | `/me` | `{ password? , external?: ExternalCredential }` → `204`. Confirm with the password or a fresh token of a linked Google/Apple identity (Apple: include `authorizationCode`). Deletes the account **immediately and for good** (SPEC §9.6): Apple tokens are revoked first, then everything goes in one transaction (published articles stay with `author: null`, shown as "Deleted user"); the phone, email and Google/Apple identities can sign up again at once. **Idempotent:** a retry whose token outlived the account also gets `204`. `400 auth.wrong_password`, `400 auth.confirmation_required`, `400 auth.external_mismatch`, `400 auth.apple_confirmation_required` (Apple-linked account without a revocable token: confirm with Apple), `503 account.deletion_unavailable` (Apple unreachable: nothing was deleted, retry) |
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
| GET | `/tags/{slug}/articles?cursor=&limit=` | `CursorPage<ArticleCardDto>`: every published article with the tag, from all writers, newest first, in the caller's article language and with the caller's `myReaction` / `isSaved` / `isFollowingAuthor` like every feed. Articles hidden by moderators (F22) and deleted ones are left out; for a signed-in caller, muted writers and topics will be too once F28 ships. `limit` 1–50, default 20. `404 tag.not_found` like `/tags/{slug}` |

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
  left out too once F28 ships. One result per article.
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
  `@reader_…` placeholder), and, once F28 ships, writers the caller muted. System accounts (the official `@readin`) are
  found like everyone, and so is the caller (`isFollowing: false`; show no Follow button on your own row).
- Order: an exact `@username` or display name first, then a username or display name that starts with `q`, then the
  rest; within each, verified first, then the most followers, then `@username`. Follow with `PUT /users/{id}/follow`
  (guests get the sign-in prompt).

**Topics** (`type=topics`, `SearchTopicDto`)
- Enabled fields and their topics whose Arabic or English name holds every word, or whose slug starts with `q` made into
  a slug (Tags rule 4, so `C#` finds `csharp`). Once F28 ships, fields and topics the caller muted are left out.
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
topics will be left out too once F28 ships. `limit` 1–50, default 20; a cursor that doesn't decode starts from the
first page.

**Explore (`ExploreDto`).** A section with nothing in it is `[]`; clients hide it.
- `fields`: every enabled field in display order (as `GET /fields`), empty ones included, with `articleCount` (articles
  readers can see, the same for everyone). Opens the field page; topics are reached there. Once F28 ships, fields the
  caller muted are left out.
- `trending`: the first 6 of `/explore/trending`. `mostSaved`: the first 6 of `/explore/most-saved`.
- `newWriters`: ≤ 10 people whose first article was published in the last 30 days, latest first publish first (the
  first article = the earliest `publishedAt` among their articles readers can see). Left out: system accounts (the
  official `@readin`), suspended accounts (while suspended), deleted accounts, profiles not completed (the
  `@reader_…` placeholder), and, once F28 ships, writers the caller muted. The caller can be listed (`isFollowing:
  false`; show no Follow button on your own row). Follow with `PUT /users/{id}/follow` (guests get the sign-in prompt).
- `featuredPaths`: ≤ 6 published paths flagged featured (`LearningPaths.IsFeatured`), in featured order
  (`FeaturedOrder`, then the editorial order), as `PathCardDto` like `/paths` (a path with no article a reader can open
  is left out; `progress` / `enrollment` for a signed-in caller). Editorial paths start featured, in their sort order;
  F23 will manage the flag. Opens `/paths/{slug}`.

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
| GET | `/feed/for-you?field=&cursor=&limit=` | `CursorPage<ArticleCardDto>`. Signed in: the articles in the user's interests first, then all the other published articles, newest first within each group (the cursor remembers the group, so paging never repeats or skips an article). Guests, users without interests, and any `field` filter: latest published. `field` is a field slug. |
| GET | `/feed/today` | `ArticleCardDto` or `204` when no pick is available yet |
| GET | `/feed/following?cursor=&limit=` | Bearer → `CursorPage<ArticleCardDto>`: published articles by the writers you follow, newest first (the Home "Following" tab) |
| GET | `/articles/{id}/related?lang=&limit=` | `ArticleCardDto[]`, 0–`limit` cards (1–10, default 4) for the end of the reader (F04). `lang` is the version being read; cards use it when they have it, else their source language. `404 article.not_found` when the article isn't published |
| GET | `/articles/{id}/preview?lang=` | `ArticlePreviewDto`: what a feed card's "Read more" shows (F34). `content` is an RDoc document with the article's first whole blocks, in order, until about 300 words of text (the block that reaches 300 is kept whole, so there is always at least one block, and a cut preview never ends on a heading or divider); `isComplete` is true when that is the whole article. `lang` picks the version like `GET /articles/{slug}` (an unknown or missing version gives the source language; `language` says which). Visible exactly like the article: `404 article.not_found` for unknown, unpublished and deleted articles, and for a hidden one to everyone but its author and moderators. Cached like the details and invalidated with them (publish, Update, hide/unhide, delete) |

Every card (feeds, today, field lists, profile articles, related, saved, continue reading, paths) carries the article's
counters, the post-card fields (F34: `excerpt`, `hasMore`, `tags`, `tagCount`) and, for a signed-in caller, their own
`myReaction` / `isSaved` / `isFollowingAuthor` (`null` / `false` / `false` for guests; `isFollowingAuthor` is also
`false` on your own articles and for a deleted author). `ArticleDetailsDto` adds `collectionIds`, your collections that
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

Every `/moderation/*` route needs `moderation.manage` (Moderator, Admin, SuperAdmin; `403 auth.forbidden` otherwise).

`ModerationActionRequest`: `{ action, targetType, targetId, note?, durationDays?, resolveReportsOf?: { targetType, targetId }, categoryId? }`
(`categoryId`: `clear_category` only).

| Target | Actions |
|---|---|
| `comment` | `hide`, `unhide`, `delete`, `dismiss` |
| `article` | `hide`, `unhide`, `dismiss` (moderators never delete articles) |
| `user` | `warn`, `suspend`, `unsuspend` (both need `users.suspend`, `403 auth.forbidden` otherwise), `clear_category` (F31), `dismiss` |

- Any other pair, or an unknown action or type: `400 moderation.action_invalid`.
- `note` (≤ 500, validation `validation.max_length`) is required for `warn` and `suspend` (`400 moderation.note_required`); it
  is shown to the user for `warn` and an article `hide`.
- `durationDays` is for `suspend` only: 1–365, or `null`/omitted for a permanent suspension (`400 moderation.duration_invalid`).
- `warn`, `suspend`, `unsuspend` on yourself: `400 moderation.self`; on a user with `moderation.manage` (or a system
  account): `403 moderation.staff_target`. Hiding a moderator's article or comment is allowed.
- `clear_category` (F31, an offensive writer-category name reported with the user): `categoryId` is required
  (`400 validation.failed`, `errors.categoryId: ["validation.required"]`) and must be one of that user's categories
  (`404 category.not_found`); the user's case lists them in `ModerationCaseDto.categories`. The category is renamed to a neutral placeholder, `قسم {n}` when the writer's UI language
  is Arabic or `Category {n}` in English (the smallest `n` the writer doesn't use), and gets a new slug made from it (the
  old slug held the name, so its links answer `404 category.not_found`); its articles stay in it. A category already
  named like that is left alone (`204`, nothing logged). Allowed on any user, like hiding content. Like `hide`, it
  resolves the user's open reports (and those of `resolveReportsOf`). Logged as `user.clear_category` with the old name
  as `targetLabel`, and in the audit log; the writer gets no notice.
- `404 article.not_found` / `comment.not_found` / `user.not_found` for an unknown or deleted target (a deleted target can
  still be `dismiss`ed).
- `hide`, `delete`, `warn`, `suspend` and `clear_category` resolve the target's open reports, and those of
  `resolveReportsOf` (e.g. warn the author from an article case). `dismiss` closes the target's open reports as dismissed and changes nothing else.
- Repeating an action that changes nothing (hide a hidden article, unsuspend an active user) is `204` and logs nothing.
- Every action that changed something is a `ModerationActionDto` in the log; actions on a user's content or account are
  also in the audit log. `warn` and an article `hide` are notices to the user (`GET /me/moderation-notices`) with a push.
- A suspension blocks the account at once (`403 user.suspended` with `suspendedUntil`, see Errors), and a temporary one
  ends by itself at `suspendedUntil`.

### Writer verification (F19; Bearer) — SPEC F19

| Method | Path | Body → Response |
|---|---|---|
| GET | `/me/verification` | → `VerificationStatusDto`: `isVerified` (has the `VerifiedWriter` role), `canRequest` (not verified, not suspended, nothing pending) and `request`, the latest request whatever its status (`null` when there was none) |
| POST | `/verification-requests` | `multipart/form-data`: `fieldId`, `jobTitle`, `proofUrl?`, `note?`, `proof?` (file) → `201 MyVerificationRequestDto` (`Location: /api/v1/me/verification`). Rate limit `writes`. Rules below |
| DELETE | `/me/verification` | Withdraws the pending request: it is deleted with its file → `204`. Rate limit `writes`. `404 verification.not_found` when nothing is pending |
| GET | `/admin/verification-requests?status=&cursor=&limit=` | → `CursorPage<AdminVerificationRequestDto>`. `status` = `pending` (default, oldest first) \| `approved` \| `rejected` (most recently decided first). `limit` 1–50 (default 20). Validation `verification.status_invalid` |
| GET | `/admin/verification-requests/{id}` | → `AdminVerificationRequestDto`. `404 verification.not_found` |
| GET | `/admin/verification-requests/{id}/proof` | → `200` the file, with its stored `Content-Type` (`application/pdf` \| `image/jpeg` \| `image/png` \| `image/webp`), `Content-Disposition: attachment; filename="verification-proof-{id}{.ext}"`, `Cache-Control: no-store`, `X-Content-Type-Options: nosniff`. `404 verification.proof_not_found` when the request has no file (URL only, or decided: the file is gone), `404 verification.not_found` |
| POST | `/admin/verification-requests/{id}/approve` | → `204`. Rate limit `writes`. The user gets the `VerifiedWriter` role at once (refresh `GET /me` to show the badge), the proof file is deleted, `verification_result` is written. `409 verification.already_decided`, `404 verification.not_found` |
| POST | `/admin/verification-requests/{id}/reject` | `{ reason }` (5–500 characters after trimming, required; validation `validation.required` / `validation.length` on `reason`) → `204`. Rate limit `writes`. The proof file is deleted, `verification_result` is written. `409 verification.already_decided`, `404 verification.not_found` |

Every `/admin/verification-requests` route needs `verification.manage` (Admin, SuperAdmin; `403 auth.forbidden`
otherwise, also for moderators). A suspended account gets `403 user.suspended` on every route, as elsewhere.

`POST /verification-requests`, checked in this order:

- Validation (`400 validation.failed`): `jobTitle` required, 2–100 characters after trimming (`validation.required`,
  `validation.length`); `proofUrl` an absolute `https://` URL (`validation.url`) of at most 500 characters
  (`validation.max_length`); `note` at most 500 (`validation.max_length`). Blank `proofUrl` / `note` count as missing.
- `409 verification.already_verified` (the user has the `VerifiedWriter` role), then `409 verification.already_pending`
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
`verification.not_found`, `verification.proof_not_found`, `verification.status_invalid` (validation, `status`).
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
| `followed_writer_article` | a writer you follow publishes an article (first publish only) | no | `readin://a/{slug}` |
| `daily_article` | Today's article push (F07); also written when the push waits for quiet hours | no | `readin://a/{slug}` |
| `streak_reminder` | 20:00 your time, your streak is ≥ 1 and you haven't read today | no | `readin://me/stats` |
| `security_alert` | password, PIN or phone changed, password reset, recovery locked, Google/Apple linked or unlinked, phone sign in added | no | `readin://settings/account` |
| `moderation_notice` | a moderator warned you or hid your article (F22) | no | the hidden article `readin://a/{slug}`, a warning `readin://notifications` (the app shows the notice from `GET /me/moderation-notices`) |
| `verification_result` | an admin approved or rejected your verification request (F19): `data.approved` `true` / `false`, no actor, no article. Without `data.approved` (never written now) render a generic text | no | `readin://verification` |

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
- What the list (and the badge) leaves out: entries whose comment was deleted or hidden, whose article isn't readable
  any more (a moderation notice keeps its hidden article), and `new_follower` entries whose followers all deleted their
  accounts. A deleted actor is gone from `actor` / `actorCount`: an entry left with no actor shows "Deleted user"
  (`actor: null`).
- Modes per type: `all` (in-app + push, the default), `inApp` (no push), `off` (no entry at all). `security_alert`,
  `moderation_notice` and `verification_result` always come. Quiet hours (default on, 23:00–07:00 in the user's time
  zone) hold pushes until they end; `security_alert` ignores them, and the daily article keeps F07's rule (a push due in
  quiet hours goes out once they end, within its 2-hour late window).
- Live badge: after every change the API writes `/live/users/{id}` `{ unreadNotifications, lastNotificationAt }` (see
  Real-time); listen to it, and use `unread-count` when RTDB isn't there.

### Profile (F14) 🌐 (Bearer optional)

`{username}` is matched ignoring case and one leading `@` (`/users/@Mona` = `/users/mona`). Deleted and suspended
accounts are `404 user.not_found` on all four; system accounts (the official `@readin`) are shown like everyone else.
The phone number and e-mail are never in these responses (SPEC §9.5).

| Method | Path | Response |
|---|---|---|
| GET | `/users/{username}` | `200 ProfileDto` |
| GET | `/users/{username}/articles?cursor=&limit=` | `CursorPage<ArticleCardDto>`: published articles, newest first, with the caller's `myReaction` / `isSaved` like every feed. `limit` 1–50, default 20 |
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
- `displayName`, `username`, `bio` and `links` replace the current values as before (an omitted `bio` or link clears it).

Profile error codes: `user.not_found` (404), `profile.stats_private` (403), `profile.avatar_invalid` (400),
`profile.expertise_invalid` (400).

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

After a reaction or save change commits, an outbox handler recomputes that article's counters from SQL (idempotent:
always recounted, never incremented), stores them on `Articles` (`ReactionCount` = the sum of the four per-type
columns, `SaveCount`), refreshes the cached details and writes `/live/articles/{id}` through `IRealtimePublisher`:
`{ reactions: { insightful, love, fire, mindBlown }, commentCount, saveCount, updatedAt }` (published articles only).
Clients apply their own action optimistically, and when live counters arrive they **replace** the numbers (never add),
so your own action is never counted twice. Feed cards subscribe only while visible; the reader while open.

| Method | Path | Auth | Response |
|---|---|---|---|
| POST | `/admin/realtime/rebuild-counters` | Bearer, `system.settings` | → `200 { articleCount }`: every article's counters recomputed from SQL and republished |

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

### Media (Bearer) — see [ADR 0011](../adr/0011-media-pipeline-and-pdf-preview.md)

| Method | Path | Body → Response |
|---|---|---|
| POST | `/uploads/images` | `multipart/form-data`: `file` (jpeg/png/webp/heic, ≤ 10 MB, ≤ 8000×8000), `purpose` = `image` (default) \| `avatar` \| `cover` → `201 MediaAssetDto` with `status: "ready"` (images are processed in the request) |
| POST | `/uploads/documents` | `multipart/form-data`: `file` (PDF, ≤ 20 MB, ≤ 100 pages, no password), `title` (optional, ≤ 5000, defaults to the file name), `allowDownload` (`true`/`false`, default `false`) → `202 MediaAssetDto` with `status: "processing"` and `pageCount` set. Pages are rendered in the background, page 1 first |
| GET | `/uploads/{id}` | → `200 MediaAssetDto` (owner only). Poll every 2 s while `status` is `processing` |
| DELETE | `/uploads/{id}` | → `204` (owner only; `409 media.in_use` while attached to an article or in an editor working copy) |
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

Backend only for now; the screens come with the F23 Admin Console.

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
  links?: { github?: string | null; linkedin?: string | null; website?: string | null }; // https URLs
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

interface AuthorDto { id: string; displayName: string; username: string; avatarUrl: string | null; isVerified: boolean }

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
  myReaction: ReactionType | null; // the caller's reaction; null for guests
  isSaved: boolean;              // the caller saved it; false for guests
  isFollowingAuthor: boolean;    // the caller follows the author; false for guests, on your own articles and for a deleted author
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

interface FollowStateDto { isFollowing: boolean; followerCount: number }
interface UserSummaryDto {
  id: string; displayName: string; username: string; avatarUrl: string | null; isVerified: boolean;
  bio: string | null;
  isFollowing: boolean;          // the caller follows this user (false for guests)
  followsYou: boolean;           // this user follows the caller (false for guests)
}

interface InterestsDto { fieldIds: string[]; topicIds: string[] }  // as in MeDto.interests

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
  bio: string | null;            // mixed ar/en: render dir="auto"
  links: { github: string | null; linkedin: string | null; website: string | null };
  expertise: ExpertiseFieldDto[]; // ≤ 5, in the user's order
  joinedAt: string;
  stats: { articles: number; followers: number; following: number; totalReads: number }; // published articles; sum of their readCount
  isMe: boolean;
  isFollowing: boolean;          // false for guests and on your own profile
  followsYou: boolean;           // false for guests and on your own profile
  readingStatsVisible: boolean;  // isMe, or the user turned on publicReadingStats: then /stats and /stats/heatmap answer 200
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
  allowDownload?: boolean;               // the PDF
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
        | 'user.warn' | 'user.suspend' | 'user.unsuspend' | 'user.clear_category' | 'reports.dismiss'; // clear_category: F31
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
  isVerified: boolean;           // has the VerifiedWriter role (the badge)
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
  user: { id: string; displayName: string; username: string; avatarUrl: string | null; isVerified: boolean };
  field: { id: string; slug: string; name: string };
  jobTitle: string;
  proofUrl: string | null;
  proof: { fileName: string; contentType: string; sizeBytes: number } | null; // download: GET …/{id}/proof (with the session)
  note: string | null;
  submittedAt: string;
  decidedAt: string | null;
  decidedBy: { id: string; username: string } | null; // null while pending, or once that admin deleted their account
  rejectionReason: string | null;
}

// Notifications (F17)
type NotificationType = 'new_follower' | 'article_comment' | 'comment_reply' | 'mention' | 'reactions_milestone'
  | 'followed_writer_article' | 'daily_article' | 'streak_reminder' | 'security_alert' | 'verification_result' | 'moderation_notice';

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
  data: { threshold?: number; streakDays?: number; securityChange?: SecurityChange; approved?: boolean }; // only the keys that apply; approved: verification_result
  link: string;                  // readin://… (the same as the push's data.link)
}
// actor: also set for followed_writer_article (the writer); null for reactions_milestone, daily_article, streak_reminder,
// security_alert, moderation_notice (moderators stay anonymous), verification_result (admins stay anonymous), and when every
// actor deleted their account ("Deleted user").
// verification_result: data.approved true = "You're now a verified writer ✓" / "بقيت كاتب موثّق ✓"; false = "Your
// verification request wasn't approved" / "طلب التوثيق بتاعك ماتقبلش"; missing = the generic text.
// moderation_notice: article set = "your article was hidden", article null = "you received a warning".

type NotificationMode = 'all' | 'inApp' | 'off';
interface NotificationSettingsDto {
  quietHours: { enabled: boolean; start: string; end: string };   // "HH:mm", your time zone; end exclusive, may be before start
  types: Partial<Record<Exclude<NotificationType, 'security_alert' | 'verification_result' | 'moderation_notice'>, NotificationMode>>;
}
// GET returns all 8 configurable types; PUT may send any subset.

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
}
```

Validation codes (in `errors`) for this area: `reaction.invalid` (`type`), `validation.required` /
`validation.max_length` (`name` of a collection, `q`). Error codes: `collection.not_found`, `collection.name_taken`,
`collection.limit`, `follow.self`, `topic.not_found`.

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
| `followed_writer_article` | "{name} نشر مقال جديد" / "{name} published a new article" | the article's title |
| `streak_reminder` | "متضيّعش الـ streak بتاعك 🔥" / "Don't lose your streak 🔥" | "الـ streak بتاعك {n} يوم…" / "Your streak is {n} days. Read an article today to keep it going." |
| `security_alert` | "تنبيه أمان" / "Security alert" | what changed, e.g. "Your password was changed. If this wasn't you, reset it now." |
| `verification_result` | approved: "بقيت كاتب موثّق ✓" / "You're now a verified writer ✓"; rejected: "طلب التوثيق بتاعك ماتقبلش" / "Your verification request wasn't approved" | approved: empty; rejected: "افتحه عشان تعرف السبب" / "Open it to see why" (never the reason). `data.link` = `readin://verification`; collapse key `verification_result` |
| `moderation_notice` | as below | as below |

`{n}` is the number of other actors (one other: "وشخص تاني" / "and 1 other"); names are wrapped in Unicode isolates
(U+2068 … U+2069) so a Latin name keeps its place in an Arabic sentence. A deleted actor is "مستخدم محذوف" / "Deleted user".

| Item | Rule |
|---|---|
| Collapse key (Android collapse key and tag, `apns-collapse-id`, web `tag`) | the entry's group (`article_comment:{articleId}`, `comment_reply:{commentId}`, `new_follower:{yyyy-MM-dd}`), otherwise the type: a newer push of the group replaces the older one |
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

## Local development

- API: `http://localhost:5080` (Scalar UI: `/docs`, OpenAPI: `/openapi/v1.json`)
- Seeded demo users (SPEC §18.3): `+12025550110` (reader1) … with the password from `Seed:DemoPassword` and the recovery PIN from `Seed:DemoPin`. Neither is committed; set them once with `dotnet user-secrets set "Seed:DemoPassword" "<password>" --project backend/src/ReadIn.Api` and `dotnet user-secrets set "Seed:DemoPin" "<4 digits, not weak>" --project backend/src/ReadIn.Api`. Without a password you can't sign in as them; without a PIN they must set one after signing in.

# ReadIn Web (Angular 22, SSR)

Web client for ReadIn. Spec: [`docs/SPEC.md`](../docs/SPEC.md) (§7 Web, §9 Authentication, §13 RDoc, §14 BiDi, §15 design system, §23 SEO). API contract: [`docs/api/contract-v1.md`](../docs/api/contract-v1.md).

## Run

```bash
npm install
npm start                 # http://localhost:4200 (dev server with SSR)
npm run build             # production SSR build → dist/readin-web
npm run serve:ssr         # serve the production build (PORT, default 4000)
npm test                  # unit tests (Vitest, headless)
npm run e2e               # Playwright visual tests: ar/en × light/dark
npm run tokens            # regenerate src/styles/tokens*.css from design/tokens.json
npm run tokens:check      # CI: fail if generated tokens are stale
```

Local dependencies: the API on `http://localhost:5080` and the Firebase emulators (`firebase emulators:start` at the repo root, project `demo-readin`) for the Realtime Database. Both URLs live in `src/environments/environment.development.ts`.

`npm run e2e` is self-contained: it starts the mock API (`e2e/mock-api/server.mjs`) on `:5180` and `ng serve --configuration e2e` on `:4280` (the development build pointed at the mock, `src/environments/environment.e2e.ts`), so a local API on `:5080` or `npm start` on `:4200` can keep running. Visual baselines are per platform (`*-win32.png` today).

SSR can call the API over an internal address with `READIN_API_INTERNAL_URL` (e.g. `http://readin-api:8080/api/v1`); the transfer cache maps it back to the public origin. Allowed SSR hosts are set in `angular.json` → `security.allowedHosts`.

## Sign in (SPEC §9, ADR 0007, ADR 0012)

- **Phone number + password, Google or Apple, against the API.** Firebase is not a sign-in method any more (ADR 0008): it only carries web push and the Realtime Database, whose custom token comes from `POST /realtime/token` with the API access token.
- **Session.** The 15-minute access token lives in `AuthService`'s memory only (never `localStorage`/`sessionStorage`). The rotating refresh token is an `HttpOnly` cookie set by the API; every `/auth/*` call and `PUT /me/password`, `PUT /me/phone`, `DELETE /me` go out with `withCredentials` and `X-ReadIn-Client: web`. On start (browser only) `POST /auth/refresh` restores the session; `401` means guest. The token is refreshed a minute before it expires and once after a `401` (single-flight, shared by concurrent requests, then the request is retried); a refresh the API refuses signs out locally. SSR is always anonymous.
- **Guards** (`core/auth/guards.ts`), in the order of SPEC §9.2: `mustChangePassword` → `/auth/change-password`, `mustSetRecoveryPin` → `/auth/recovery-pin`, `!isProfileComplete` → `/auth/complete-profile`, `!onboardingCompleted` → `/onboarding`, then the requested page (`returnUrl` is kept through the steps). Guests browse freely. Guards only decide in the browser.
- **Shared inputs** (`shared/ui/phone`, `password`, `pin`): the phone field + country picker reads `shared/countries/countries.json` directly and validates with `libphonenumber-js` (mobile metadata, pinned to the version the JSON was generated from); flags are SVGs from `flag-icons`, copied to `/flags` by `angular.json`. Password and PIN rules mirror the API's (`shared/security/*.txt` are bundled as text via the `.txt` loader in `angular.json`).
- **Google and Apple** (ADR 0012): Google Identity Services and Sign in with Apple JS are loaded lazily in the browser only and give an ID token that goes straight to `POST /auth/external`; nothing is stored. A button shows only when `GET /auth/config` lists the provider in `externalProviders` and the build has a client id (`googleWebClientId`, `appleServicesId` in the environment; Apple stays hidden while the Services ID is empty). Google's button is the official one rendered by GIS; Apple's follows Apple's black/white rules. A not-linked identity opens a sheet: create a new account, or link it with phone + password. Settings → Account lists linked accounts (link, unlink), and Google/Apple-only accounts (`hasPassword: false`) add phone + password + PIN there and confirm deletion with the provider. The app sets no Content-Security-Policy today; if one is added, allow `https://accounts.google.com` (script, frame, connect) and `https://appleid.cdn-apple.com` / `https://appleid.apple.com` (script, frame).
- **Dev login panel.** Development builds show the seed users of SPEC §18.3 under the sign-in form. Type your `Seed:DemoPassword` into the panel once (it stays in this browser's `localStorage`, development builds only) and a tap signs in. Production builds don't contain the panel: `src/app/features/auth/dev/dev-login.ts` is replaced by `dev-login.development.ts` only in the `development` and `e2e` configurations.
- Safari doesn't store `Secure` cookies over `http://localhost`; use Chrome, Edge or Firefox against a local API.

## Structure (SPEC §7.1)

```text
src/app/
├── core/       auth (session, guards, account-setup order) · http (interceptors) · i18n (Transloco)
│               theme (ThemeService, reader prefs) · api (typed contract-v1 services) · realtime · push · platform
│               social (reactions, saves, collections, follows: shared optimistic state + live counters)
├── shared/     ui (cards, sheets, states, icons, phone field + country picker, password field, PIN input)
│               rdoc (renderer, one component per block) · directives (BiDi) · pipes
│               social (follow button, person row, collection sheets)
├── layout/     shell, top bar, side nav (desktop), bottom nav (narrow screens)
└── features/   auth (welcome, sign in/up, forgot password, setup steps) · onboarding · home · article · saved
                · settings · placeholders for later phases
```

## Reactions, follow, saved (F10, F12, F13, F27)

- **One state per article and per writer.** `core/social` keeps what the UI shows about reactions, saves and follows, so a change on a feed card also shows in the reader and on the Saved page. Fresh API copies replace it (`absorb`), except while one of your actions is still on its way. Signing out clears it.
- **Optimistic, one request at a time.** A tap changes the UI at once. Quick taps coalesce into the latest wish, with one request per article and kind at a time. A failure rolls back to what the server last confirmed and shows the translated error code. Guests get the soft sign-in prompt instead.
- **Live counters replace, never add.** `bindLiveCounters` listens to `/live/articles/{id}` for the open reader, and for feed cards while they are on screen (browser only). A live value that differs from the server's last value replaces it, so your own reaction is never counted twice. Without the Realtime Database the REST values stay.
- **Personal GETs** (Following feed, Saved, collections, suggestions, who reacted) carry `WITH_SESSION`, so they keep the token while a server-rendered page is still hydrating. SSR is anonymous, so the reader loads the article again with your token once the session is restored.
- **Collections** know an article's membership from the API (`SavedArticleDto.collectionIds` on the Saved list, `ArticleDetailsDto.collectionIds` in the reader) and from changes made in this session; an older copy never undoes a change still on its way. The API reports a bad name with the generic `validation.required` / `validation.max_length` on `errors.name`; the sheets show them as the collection-name messages.
- **e2e:** `e2e/mock-api/social.mjs` keeps reactions, saves, collections and follows per signed-in viewer (the bearer token's `sub`), and `e2e/support/social.ts` signs each test in as its own reader, so the flows run end to end in parallel.

## Rules this codebase follows

- **Tokens only.** Colors come from `design/tokens.json` through `src/styles/tokens*.css` (Tailwind utilities like `bg-surface`, `text-text-secondary`). Never edit the generated files; never use hex colors in components.
- **No theme flash.** The `theme` and `lang` cookies drive `<html data-theme lang dir>` during SSR; an inline script in `index.html` does the same for client-rendered routes.
- **Every string in `public/i18n/{ar,en}.json`.** API errors are translated from their ProblemDetails `code` under `errors.*` (`core/i18n/error-messages.ts` lists the contract codes; a test checks both languages).
- **BiDi.** RDoc blocks resolve their own direction; opposite-direction runs are isolated with `<bdi>`; code is always LTR. Phone numbers, passwords and PINs are always LTR. Use `rd-bdi-text` / `[rdAutoDir]` for user text outside articles. Test fixtures: `shared/bidi/fixtures.json`.
- **Icons.** Register Lucide icons in `shared/ui/icons.ts` and render them with `<svg lucideIcon="Name">`. A single shared template keeps the bundle small.
- **Hydration.** GETs made while hydrating are sent without a token so they're served from the SSR transfer cache. Pages that personalize (Home) refresh once the session is known.

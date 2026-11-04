# ReadIn — Mobile (Flutter)

Android & iOS app for ReadIn (SPEC §3.3, §8). Clean Architecture, feature-first:
`Page → Bloc/Cubit → UseCase → Repository → DataSource`.

## Run

```bash
# 1. Local services (from the repo root)
docker compose up -d                 # SQL Server + Seq
firebase emulators:start             # Realtime Database (9000) + Auth (9099, custom tokens only), project demo-readin
dotnet run --project backend/src/ReadIn.Api   # API on http://localhost:5080

# 2. App (from mobile/)
flutter pub get
dart run build_runner build          # freezed / json / retrofit / injectable
flutter run --dart-define-from-file=config/dev.json
```

| Define | Default (dev) | Notes |
|---|---|---|
| `FLAVOR` | `dev` | `dev` = Firebase Emulator Suite · `prod` = the single real Firebase project (`config/*.json`, ADR 0005) |
| `API_BASE_URL` | `http://10.0.2.2:5080/api/v1` (Android emulator), `http://localhost:5080/api/v1` otherwise | Override for a device on your LAN |
| `USE_FIREBASE_EMULATOR` | `true` | Only honoured in `dev` |
| `DEV_DEMO_PASSWORD` | empty | Debug builds of `dev` only: the API's `Seed:DemoPassword`, so the dev login panel signs in with one tap. Never pass it to a release build |

The app still starts when Firebase is unavailable: it logs the error and runs without push and live updates.
`lib/firebase_options.dart` is the emulator project (`dev`); `lib/firebase_options_prod.dart` is the real project
`readin-cca78` (`prod`), used only for push notifications and the Realtime Database ([docs/setup/firebase.md](../docs/setup/firebase.md)).
Push needs `prod` (the emulator has no Cloud Messaging); live counters and the unread badge work with both.

## Sign in (SPEC §9, ADR 0007–0009)

- **Phone number + password** against the API's own sessions; Firebase is not a sign-in method (it only reads the
  Realtime Database with a custom token from `POST /realtime/token`, on a separate Firebase app).
- **Tokens:** the access token (15 minutes) lives in memory only; the refresh token (30 days, rotating) lives in
  `flutter_secure_storage`. `AuthInterceptor` (a `QueuedInterceptor`) adds `Bearer`, refreshes before expiry or once
  after a `401` (single-flight: concurrent calls share one `POST /auth/refresh`) and retries; a rejected refresh token
  ends the session locally. Every response that carries a session (sign in/up, refresh, sign out everywhere, password
  or number change) replaces both tokens. Sign-in calls carry `X-Device-Name` (the device model).
- **Splash** → `POST /auth/refresh` → the router applies the account guards in the SPEC §9.2 order: must change
  password → set recovery PIN → complete profile → onboarding → the requested page. Guests browse and read.
- **Sign out:** `DELETE /me/devices/{token}` → `POST /auth/logout` → forget the tokens; the live connection signs out
  of Firebase and the FCM token is deleted as the session ends (`LiveSessionBridge`).
- **Delete account** (Settings → Account, the last red row; immediate and final): what is deleted and kept → confirm
  it's you (the password, or a fresh Google / Apple sign in; Apple's sheet opens by itself on
  `auth.apple_confirmation_required`) → "I understand" and a last dialog → `DELETE /me`. On `204` the device forgets the
  account (`AccountDeviceData`: FCM token deleted on the device, cached images, temporary files, the remembered Google
  account and phone country), then the session, and Sign in says "تم حذف حسابك.". A failure deletes nothing; Retry is
  the person's choice, never queued. Every Apple credential (sign in, link, delete) carries `authorizationCode`.
- **Shared inputs** (`lib/shared/widgets/inputs/`): phone field + country picker (bundled flags, `phone_numbers_parser`,
  E.164, always LTR), password field with strength meter and rules checklist, PIN boxes. The rules mirror the API's
  (`lib/core/security/credential_rules.dart`); the server re-checks everything.
- **Dev login panel:** the Sign in screen of debug `dev` builds lists the seed users (SPEC §18.3) with their PIN status;
  `kReleaseMode` removes it from release builds.

## Code generation

| What | Command | Output |
|---|---|---|
| Design tokens | `node tools/tokens/build.mjs --only mobile` (repo root) | `lib/core/theme/tokens.g.dart` |
| Translations | `flutter gen-l10n` (also runs on `flutter pub get`) | `lib/core/l10n/gen/` |
| Models, API clients, DI | `dart run build_runner build` | `*.freezed.dart`, `*.g.dart`, `injection.config.dart` |
| Countries, weak PINs and common passwords (copies of `shared/`) | `node tools/countries/build.mjs --mobile` (repo root; `--check` fails when stale) | `lib/core/phone/country_list.g.dart`, `lib/core/security/common_secrets.g.dart` |

Never hand-edit generated files. Every UI string lives in `lib/core/l10n/app_{ar,en}.arb`;
every color comes from `ReadInColors` (`context.colors`).

## Tests

```bash
flutter analyze
flutter test                                  # unit + widget + golden
flutter test --exclude-tags golden            # skip pixel comparisons
flutter test --tags golden --update-goldens   # regenerate goldens after UI changes
```

- **BiDi**: `test/core/bidi/` runs against the shared fixtures in `../shared/bidi/fixtures.json`.
- **RDoc**: `test/shared/rdoc/` renders `../shared/rdoc/examples/kitchen-sink.ar-EG.json`.
- **Shared lists**: `test/core/generated_copies_test.dart` fails when the compiled-in copies of `../shared/countries`
  and `../shared/security` are stale.
- **Goldens**: every screen in 4 variants: `ar/light`, `ar/dark`, `en/light`, `en/dark`
  (`test/goldens/goldens/*.png`). Goldens are platform-sensitive. Regenerate them on the CI
  platform before gating on them.

## Structure

```text
lib/
├── main.dart              # Hive → DI (Firebase, storage, Dio) → session → app
├── app/                   # App widget, go_router (redirects, shell), splash
├── core/
│   ├── bidi/              # direction detection, Unicode isolates, Arabic normalization
│   ├── config/            # flavors / dart-defines
│   ├── di/                # get_it + injectable
│   ├── errors/            # Failure (stable error codes), Result
│   ├── firebase/          # init + emulator wiring, graceful fallback
│   ├── l10n/              # ARB files, error-code → message, formatters (Western digits)
│   ├── network/           # Dio interceptors (access token + single-flight refresh, device name, Accept-Language), ProblemDetails mapping
│   ├── phone/             # country list (from shared/countries), libphonenumber rules, E.164
│   ├── security/          # password and recovery PIN rules (mirrors the API)
│   ├── storage/           # Hive key/value store, secure storage (refresh token)
│   └── theme/             # tokens.g.dart → ThemeData light/dark
├── shared/
│   ├── rdoc/              # RDoc model + one widget per block type
│   └── widgets/           # state views, badges, BidiText, images, logo; inputs/: phone + country picker, password, PIN
└── features/<feature>/{data,domain,presentation}
    auth · onboarding · home · article · settings · taxonomy · profile
    explore · editor · saved · notifications   (placeholders, "coming soon")
```

Fonts (IBM Plex Sans Arabic, IBM Plex Sans, JetBrains Mono) are bundled under `assets/fonts/`
(SIL Open Font License 1.1).

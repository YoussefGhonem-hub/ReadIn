# ReadIn — Mobile (Flutter)

Android & iOS app for ReadIn (SPEC §3.3, §8). Clean Architecture, feature-first:
`Page → Bloc/Cubit → UseCase → Repository → DataSource`.

## Run

```bash
# 1. Local services (from the repo root)
docker compose up -d                 # SQL Server + Seq
firebase emulators:start             # Auth (9099) + Realtime Database (9000), project demo-readin
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

The app still starts when Firebase is unavailable: it logs the error and runs in guest mode.
`lib/firebase_options.dart` is the emulator project (`dev`); `lib/firebase_options_prod.dart` is the real project
`readin-cca78` (`prod`), used only for push notifications and the Realtime Database ([docs/setup/firebase.md](../docs/setup/firebase.md)).
Push needs `prod` (the emulator has no Cloud Messaging); live counters and the unread badge work with both.

## Code generation

| What | Command | Output |
|---|---|---|
| Design tokens | `node tools/tokens/build.mjs --only mobile` (repo root) | `lib/core/theme/tokens.g.dart` |
| Translations | `flutter gen-l10n` (also runs on `flutter pub get`) | `lib/core/l10n/gen/` |
| Models, API clients, DI | `dart run build_runner build` | `*.freezed.dart`, `*.g.dart`, `injection.config.dart` |

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
│   ├── network/           # Dio interceptors (Firebase token, Accept-Language), ProblemDetails mapping
│   ├── storage/           # Hive key/value store, secure storage
│   └── theme/             # tokens.g.dart → ThemeData light/dark
├── shared/
│   ├── rdoc/              # RDoc model + one widget per block type
│   └── widgets/           # state views, badges, BidiText, images, logo
└── features/<feature>/{data,domain,presentation}
    auth · onboarding · home · article · settings · taxonomy · profile
    explore · editor · saved · notifications   (placeholders, "coming soon")
```

Fonts (IBM Plex Sans Arabic, IBM Plex Sans, JetBrains Mono) are bundled under `assets/fonts/`
(SIL Open Font License 1.1).

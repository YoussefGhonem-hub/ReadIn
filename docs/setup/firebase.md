# Firebase setup: the single real project

ReadIn uses **one** real Firebase project, `readin-cca78`, for the deployed app only ([ADR 0005](../adr/0005-single-firebase-project.md), SPEC §28.1).
Firebase has exactly two jobs there: **push notifications (FCM)** and **live updates (Realtime Database)** (SPEC §21).
It is not used for sign-in (phone + password in the API), file storage (`wwwroot/uploads`, ADR 0010), Firestore or analytics.

Local development, CI and all tests use the **Firebase Emulator Suite** (project `demo-readin`) and need none of the steps below.

> **Never commit:** the Admin SDK key (`*firebase-adminsdk*.json`), `google-services.json`, `GoogleService-Info.plist`, or any password.
> All three file patterns are in `.gitignore`.
>
> **Never seed demo data into this project.** Demo users and demo interactions exist only in the local database
> (`Development` / `Testing`), and the live signals they produce go to the Realtime Database emulator.

| | Value |
|---|---|
| Project ID | `readin-cca78` |
| Realtime Database | `https://readin-cca78-default-rtdb.europe-west1.firebasedatabase.app` (region `europe-west1`) |
| Web app | `ReadIn Web`, config in `web/src/environments/environment.ts` |
| Android / iOS bundle | `app.readin.readin` |

---

## 0. Prerequisites

| Tool | Install / check |
|---|---|
| Firebase CLI | `npm install -g firebase-tools`, then `firebase login` |
| FlutterFire CLI | `dart pub global activate flutterfire_cli` (make sure the pub cache `bin` folder is on your `PATH`) |
| Apple Developer Program membership | Needed for iOS push (APNs) |

The free **Spark** plan covers FCM and the Realtime Database. Set a budget alert anyway if you upgrade later
(Google Cloud console → **Billing → Budgets & alerts**).

---

## 1. Project alias

`.firebaserc` maps the `prod` alias to `readin-cca78`. Check it:

```bash
firebase use prod        # should print "Now using alias prod (readin-cca78)"
firebase use default     # back to the emulator project for daily work
```

---

## 2. Realtime Database

The database already exists in `europe-west1`. Its rules live in the repo (`firebase/database.rules.json`):
`/live/articles` and `/live/feed` are public read, `/live/users/{id}` is readable only by that user, and **no client
can write anywhere**. Only the API writes, with the Admin SDK key from step 6.

Deploy the rules after every change to that file:

```bash
firebase deploy --only database --project prod
```

---

## 3. Authentication (custom tokens only)

Signed-in users read `/live/users/{id}` with a Firebase **custom token** from `POST /realtime/token`; its `uid` is the
ReadIn user id. This is not a sign-in method, but Firebase Authentication must be switched on for custom tokens to work:

1. Console → **Build → Authentication → Get started**.
2. Leave every sign-in provider **disabled**. ReadIn's sign-in is phone + password in the API (SPEC §9).
3. **Authentication → Settings → Authorized domains**: add `readin.app` (and any other domain that serves the web app).

---

## 4. Cloud Messaging (FCM)

The FCM HTTP v1 API is enabled by default. The API sends pushes through the Admin SDK (step 6), so no server key is needed.

1. **Android:** nothing to do. Registering the app (step 5) is enough.
2. **iOS:** Apple Developer → **Keys → +** → enable **Apple Push Notifications service (APNs)** → download the `.p8` key once.
   Then Firebase ⚙ **Project settings → Cloud Messaging → Apple app configuration → APNs Authentication Key → Upload**,
   with the `.p8` file, **Key ID** and **Team ID**. The Xcode capabilities are already committed
   (`Runner.entitlements`, background mode `remote-notification`; see [ios.md](ios.md)).
3. **Web push:** done. The public **VAPID key** (⚙ **Project settings → Cloud Messaging → Web Push certificates**) is
   `firebaseVapidKey` in `web/src/environments/environment.ts`. It is not a secret. If you ever regenerate the key pair,
   update that value: every browser then registers a new token on its next visit.

The web app receives pushes in `web/public/firebase-messaging-sw.js`. It asks for permission only in context
(onboarding reminder step, Settings → Notifications), then registers the browser with `POST /me/devices`.

---

## 5. Mobile apps: `flutterfire configure`

The `dev` flavor keeps using `mobile/lib/firebase_options.dart` (emulator, `demo-readin`). The `prod` flavor uses
`mobile/lib/firebase_options_prod.dart`, which already holds the `readin-cca78` values of the registered Android and iOS
apps (`app.readin.readin`). Regenerate it only if those apps change (a new app, a new bundle ID).

To regenerate, start from a clean working tree (`git status` shows nothing), then:

```bash
cd mobile
flutterfire configure \
  --project=readin-cca78 \
  --platforms=android,ios \
  --android-package-name=app.readin.readin \
  --ios-bundle-id=app.readin.readin \
  --out=lib/firebase_options_prod.dart \
  --yes
```

This registers the Android and iOS apps in the project (if they don't exist yet) and overwrites
`lib/firebase_options_prod.dart`. That file holds only public client identifiers, so commit it.

FlutterFire also writes `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` (both git-ignored),
and edits the Gradle and Xcode project files so the build needs them. ReadIn passes its options explicitly in
`Firebase.initializeApp`, so undo those project edits, otherwise every machine without the ignored files fails to build:

```bash
git status                          # expect: lib/firebase_options_prod.dart, android/…, ios/…, firebase.json
git checkout -- android ios         # drop FlutterFire's Gradle plugin and Xcode file references
rm -f firebase.json                 # FlutterFire's own metadata for re-running configure; not needed
git add lib/firebase_options_prod.dart
```

Run against the real project:

```bash
flutter run --dart-define-from-file=config/prod.json
```

---

## 6. Admin SDK key for the API (`dotnet user-secrets`)

The API uses the Admin SDK key to send FCM pushes, write the Realtime Database and create the custom tokens of step 3.

1. ⚙ **Project settings → Service accounts → Firebase Admin SDK → Generate new private key → Generate key**.
   A file like `readin-cca78-firebase-adminsdk-xxxxx.json` downloads. Keep it **outside** the repository.
2. Store it in user-secrets for the API project. Base64 avoids quoting problems with the JSON:

   **PowerShell**
   ```powershell
   $key = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\Downloads\readin-cca78-firebase-adminsdk-xxxxx.json"))
   dotnet user-secrets set "Firebase:ServiceAccountJson" $key --project backend/src/ReadIn.Api
   ```

   **bash**
   ```bash
   dotnet user-secrets set "Firebase:ServiceAccountJson" "$(base64 -w0 ~/Downloads/readin-cca78-firebase-adminsdk-xxxxx.json)" \
     --project backend/src/ReadIn.Api
   ```
   `Firebase:ServiceAccountJson` accepts the key as plain JSON or base64-encoded JSON.
3. **Delete the downloaded file** once the secret is stored: `dotnet user-secrets list --project backend/src/ReadIn.Api`
   should show `Firebase:ServiceAccountJson = ewog…`.
4. Point the API at the real project. Without the emulator flag the API refuses to start unless `Firebase:ProjectId` is set:
   ```bash
   dotnet user-secrets set "Firebase:ProjectId" "readin-cca78" --project backend/src/ReadIn.Api
   dotnet user-secrets set "Firebase:DatabaseUrl" "https://readin-cca78-default-rtdb.europe-west1.firebasedatabase.app" --project backend/src/ReadIn.Api
   ```
   Running locally against the real project also needs `Firebase:UseEmulator=false`, for example
   `--Firebase:UseEmulator=false`. Demo seeders never run against it.
5. **Deployed API:** user-secrets exist only on a developer machine. On the server, set the same keys as environment
   variables from the host's secret store, using double underscores: `Firebase__ProjectId`, `Firebase__DatabaseUrl`,
   `Firebase__ServiceAccountJson`. Alternatively, leave `ServiceAccountJson` unset and give the host a workload identity
   (Application Default Credentials) with the **Firebase Admin** role.

---

## 7. Web app config

Done: `web/src/environments/environment.ts` holds the `ReadIn Web` config of `readin-cca78` (API key, app ID,
`databaseURL`, sender ID) and the VAPID key. These are public identifiers; access is enforced by the database rules.
`environment.development.ts` keeps pointing at the emulator (Realtime Database on `127.0.0.1:9000`, Auth on `127.0.0.1:9099`).

Protect the browser API key: Google Cloud console → **APIs & Services → Credentials → Browser key (auto created by Firebase)** →
**Application restrictions → Websites** → add `https://readin.app/*` (and `http://localhost:4200/*` only if you run
the production build locally).

---

## 8. Checklist

- [x] Project `readin-cca78`; `.firebaserc` `prod` alias
- [x] Realtime Database in `europe-west1`
- [x] Web app registered; config and VAPID key in `web/src/environments/environment.ts`
- [ ] Database rules deployed from `firebase/database.rules.json`
- [ ] Authentication switched on (no providers); `readin.app` in authorized domains
- [x] APNs key uploaded (development + production)
- [x] Android and iOS apps registered; `mobile/lib/firebase_options_prod.dart` committed
- [ ] Browser API key restricted to `https://readin.app/*`
- [ ] `Firebase:ServiceAccountJson`, `Firebase:ProjectId`, `Firebase:DatabaseUrl` stored with `dotnet user-secrets` (dev) / secret store (server); downloaded key file deleted
- [ ] No `google-services.json`, `GoogleService-Info.plist` or `*firebase-adminsdk*.json` in `git status`

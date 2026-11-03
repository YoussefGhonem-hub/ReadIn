# Firebase setup: the single real project

ReadIn uses **one** real Firebase project, `readin-cca78`, for the deployed app only ([ADR 0005](../adr/0005-single-firebase-project.md), SPEC §28.1).
Firebase has exactly two jobs there: **push notifications (FCM)** and **live updates (Realtime Database)** (SPEC §21).
It is not used for sign-in (phone + password in the API), file storage (`wwwroot/uploads`, ADR 0010), Firestore or analytics.

Local development, CI and all tests use the **Firebase Emulator Suite** (project `demo-readin`, [section 9](#9-local-development-the-emulator-suite))
and need none of the other steps.

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
can write anywhere**. Only the API writes, through the RTDB REST API with the Admin SDK service account from step 6
(the .NET Admin SDK has no Realtime Database client). The API writes nothing until `Firebase:DatabaseUrl` is set
(step 6.4): without it, live updates are off and the apps keep working through REST.

Deploy the rules after every change to that file:

```bash
firebase deploy --only database --project prod
```

`firebase.json` deploys the rules to the database **target** `live`, which `.firebaserc` maps to
`readin-cca78-default-rtdb` for `readin-cca78` and to the `demo-readin` namespace for the emulator (the namespace the
API and the dev apps use). Without that mapping the emulator would load the rules into `demo-readin-default-rtdb` and
leave the namespace in use wide open.

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

### What the API needs to send pushes

The API sends with `FcmPushSender` (Admin SDK, FCM HTTP v1). The first push is the daily article (F07): the `daily-article`
Hangfire job runs every 5 minutes, picks each user's article 30 minutes before their reminder time and sends the push
at it (payload in [contract-v1.md](../api/contract-v1.md#push-payloads-fcm)).

1. **Firebase Cloud Messaging API (V1)** enabled: Google Cloud console → **APIs & Services → Enabled APIs** →
   `Firebase Cloud Messaging API`. It is on by default in Firebase projects; the legacy API is not used.
2. **A service account allowed to send:** the Admin SDK key of step 6 (its account has the *Firebase Admin SDK
   Administrator Service Agent* role, which includes `cloudmessaging.messages.create`), or, without a key, a host
   identity (Application Default Credentials) with the **Firebase Cloud Messaging API Admin** or **Firebase Admin** role.
3. **The API pointed at the real project:** `Firebase:ProjectId` set and `Firebase:UseEmulator` false (step 6).
4. **Hangfire enabled** (`Hangfire:Enabled`, on by default): the job, not the request, sends pushes (SPEC §21.1).

FCM has no emulator. With `Firebase:UseEmulator=true` (local development, tests), and in Development without
`Firebase:ServiceAccountJson`, the API **logs** each push (`Push not sent (no FCM in this environment): …`) instead of
sending it, so the job runs end to end without credentials. Tokens FCM reports as unregistered or invalid are deleted
from `UserDevices`; other failures are logged and the push is retried on the next run, at most 2 hours late.

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
   `Firebase__ServiceAccountJson`.
6. **What the key is used for.** With `Firebase:ServiceAccountJson` set, the API signs the custom tokens of
   `POST /realtime/token` **locally** with that key and gets OAuth access tokens (scopes `firebase.database` +
   `userinfo.email`) for the Realtime Database REST API. The generated Admin SDK account already has every role this
   needs; nothing else to grant.
7. **Keyless alternative (Application Default Credentials).** Leave `ServiceAccountJson` unset and run the API as a
   service account (Google Cloud workload identity, or workload identity federation elsewhere). That identity needs:
   - **Firebase Realtime Database Admin** (`roles/firebasedatabase.admin`), or **Firebase Admin**
     (`roles/firebase.admin`), on `readin-cca78`, to write `/live/...`;
   - **Service Account Token Creator** (`roles/iam.serviceAccountTokenCreator`) **on itself**
     (`iam.serviceAccounts.signBlob`): without a private key the Admin SDK signs custom tokens through the IAM
     Service Account Credentials API, which must be enabled (`iamcredentials.googleapis.com`);
   - `Firebase:ServiceAccountId` = its email (`…@readin-cca78.iam.gserviceaccount.com`) when the host has no
     metadata server to discover it from (anything outside Google Cloud).

   If signing fails, `POST /realtime/token` answers `500 realtime.unavailable` and the API logs the cause; the apps
   carry on without the live unread badge.

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
- [ ] Firebase Cloud Messaging API (V1) enabled; the API's service account (or host identity) may send messages
- [x] APNs key uploaded (development + production)
- [x] Android and iOS apps registered; `mobile/lib/firebase_options_prod.dart` committed
- [ ] Browser API key restricted to `https://readin.app/*`
- [ ] `Firebase:ServiceAccountJson`, `Firebase:ProjectId`, `Firebase:DatabaseUrl` stored with `dotnet user-secrets` (dev) / secret store (server); downloaded key file deleted
- [ ] After deploying the API: `POST /api/v1/realtime/token` with a user's access token answers `200 { token }`, and publishing an article moves `/live/feed/latestPublishedAt` (Firebase console → Realtime Database → Data)
- [ ] No `google-services.json`, `GoogleService-Info.plist` or `*firebase-adminsdk*.json` in `git status`

---

## 9. Local development: the Emulator Suite

The API, the web app and the `dev` mobile flavor talk to the emulators of project `demo-readin`, never to `readin-cca78`.

```bash
# From the repository root. firebase-tools 15 needs Java 21+ for the Realtime Database emulator (JAVA_HOME).
firebase emulators:start --only auth,database
```

| Emulator | Address | Used for |
|---|---|---|
| Realtime Database | `127.0.0.1:9000`, namespace `demo-readin` | Live signals; rules from `firebase/database.rules.json` (target `live`) |
| Authentication | `127.0.0.1:9099` | Only to exchange the custom token of `POST /realtime/token` |
| Emulator UI | `http://127.0.0.1:4000` | Browse `/live/...` and the custom-token users |

`appsettings.Development.json` points the API at them: `Firebase:UseEmulator=true`, `Firebase:AuthEmulatorHost`
(`127.0.0.1:9099`) and `Firebase:DatabaseEmulatorHost` (`127.0.0.1:9000`). With the emulator flag the API

- sets `FIREBASE_AUTH_EMULATOR_HOST` for the Admin SDK, which then mints **unsigned** custom tokens that only the
  Auth emulator accepts (no key needed);
- writes `http://127.0.0.1:9000/live/...json?ns=demo-readin` with the emulator's admin token `owner`;
- ignores `Firebase:DatabaseUrl`, so development signals can never reach the real database.

The web (`environment.development.ts`) and mobile (`lib/firebase_options.dart`) dev configs use the database URL
`https://demo-readin.firebaseio.com`, i.e. the same `demo-readin` namespace. Without the emulators running everything
still works through REST: the API's writes fail fast once its circuit breaker opens, and the apps simply get no live
updates. Tests never need the emulators (integration tests fake the token issuer and the publisher).

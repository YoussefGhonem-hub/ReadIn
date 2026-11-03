# Firebase setup: the single real project

ReadIn uses **one** real Firebase project, for the deployed app only ([ADR 0005](../adr/0005-single-firebase-project.md), SPEC §28.1).
Local development, CI and all tests use the **Firebase Emulator Suite** (project `demo-readin`) and need none of the steps below.

> **Never commit:** the Admin SDK key (`*firebase-adminsdk*.json`), `google-services.json`, `GoogleService-Info.plist`, or any password.
> All three file patterns are in `.gitignore`.
>
> **Never seed demo data into this project.** Demo users and demo interactions are created only when the backend runs with
> `Firebase:UseEmulator = true`, which is itself only allowed in `Development` and `Testing`.

Throughout this guide, `<PROJECT_ID>` is the project ID you choose in step 1 (for example `readin-app-1a2b3`).

---

## 0. Prerequisites

| Tool | Install / check |
|---|---|
| Firebase CLI | `npm install -g firebase-tools`, then `firebase login` |
| FlutterFire CLI | `dart pub global activate flutterfire_cli` (make sure the pub cache `bin` folder is on your `PATH`) |
| Google Cloud CLI (for Storage CORS only) | <https://cloud.google.com/sdk/docs/install>, then `gcloud auth login` |
| Apple Developer Program membership | Needed for Sign in with Apple and iOS push |

---

## 1. Create the project

1. Open <https://console.firebase.google.com> → **Create a project**.
2. Name it `ReadIn`. Note the generated **project ID** (`<PROJECT_ID>`). It is permanent.
3. Google Analytics: enable it (used later by `firebase_analytics`) and pick or create an Analytics account.
4. **Upgrade to the Blaze (pay-as-you-go) plan:** ⚙ **Project settings → Usage and billing → Details & settings → Modify plan**.
   New projects need Blaze to create a Cloud Storage bucket. Set a budget alert at the same time
   (Google Cloud console → **Billing → Budgets & alerts**).
5. Point the repo's `prod` alias at the project. In `.firebaserc`, replace `REPLACE_WITH_YOUR_PROJECT_ID` with `<PROJECT_ID>`, then check it:
   ```bash
   firebase use prod        # should print "Now using alias prod (<PROJECT_ID>)"
   firebase use default     # back to the emulator project for daily work
   ```

---

## 2. Authentication providers

Console → **Build → Authentication → Get started → Sign-in method**.

### 2.1 Email/Password
1. **Add new provider → Email/Password → Enable** (leave *Email link (passwordless sign-in)* off) → **Save**.
2. **Authentication → Templates**: set the sender name to `ReadIn` and review the *Email address verification*
   and *Password reset* templates (both are used by F01). Add an Arabic version of each template if you want localized emails.

### 2.2 Google
1. **Add new provider → Google → Enable**, choose the **project support email** → **Save**.
2. Android needs your signing certificate fingerprints. Add them after registering the Android app (step 5):
   ```bash
   cd mobile/android
   ./gradlew signingReport        # Windows: .\gradlew signingReport
   ```
   Copy the **SHA-1** and **SHA-256** of the `debug` variant, and later of your release/upload key.
   Then go to ⚙ **Project settings → Your apps → Android app → Add fingerprint**.
   If you publish through Google Play App Signing, also add the fingerprints shown in Play Console → **App integrity**.
3. iOS needs the reversed client ID as a URL scheme. Add it after `flutterfire configure` (step 5):
   open the downloaded `GoogleService-Info.plist`, copy `REVERSED_CLIENT_ID`, and add it to
   `mobile/ios/Runner/Info.plist` under `CFBundleURLTypes → CFBundleURLSchemes`.
   This value is not a secret and may be committed. The plist file itself stays ignored.

### 2.3 Apple
Sign in with Apple is required on iOS because the app offers Google sign-in.

1. **Apple Developer → Certificates, Identifiers & Profiles**:
   1. **Identifiers → App IDs →** `app.readin.readin` → enable **Sign In with Apple**.
   2. **Identifiers → Services IDs → +**, for example `app.readin.signin` (used by web and Android).
      Enable **Sign In with Apple → Configure**: primary App ID `app.readin.readin`; domain `<PROJECT_ID>.firebaseapp.com`;
      return URL `https://<PROJECT_ID>.firebaseapp.com/__/auth/handler`.
   3. **Keys → +**, enable **Sign In with Apple** for the primary App ID, then download the `.p8` key **once**.
      Note the **Key ID** and your **Team ID**.
2. Firebase console → **Sign-in method → Add new provider → Apple → Enable**, then fill in:
   **Services ID** (`app.readin.signin`), **Apple team ID**, **Key ID**, and the contents of the `.p8` **private key** → **Save**.
3. Xcode: open `mobile/ios/Runner.xcworkspace` → target **Runner → Signing & Capabilities → + Capability → Sign in with Apple**.
   Commit the resulting `Runner.entitlements` change.
4. Store the `.p8` file in your password manager, never in the repo.

### 2.4 Authorized domains
**Authentication → Settings → Authorized domains**: add `readin.app` (and any other domain that serves the web app).
`localhost` is there by default.

---

## 3. Cloud Storage

1. Console → **Build → Storage → Get started** → choose **production mode** and a location close to your users
   (for example `europe-west1`). The location is permanent.
   The default bucket is named `<PROJECT_ID>.firebasestorage.app`.
2. Deploy the repo's rules (`firebase/storage.rules`):
   ```bash
   firebase deploy --only storage --project prod
   ```
3. Allow browser uploads through signed URLs (F05 covers, F14 avatars) by applying the CORS policy:
   ```bash
   gcloud storage buckets update gs://<PROJECT_ID>.firebasestorage.app --cors-file=firebase/storage.cors.json
   ```
   If you serve the web app from more origins than `https://readin.app`, add them to `firebase/storage.cors.json` first.

---

## 4. Cloud Messaging (FCM)

The FCM HTTP v1 API is enabled by default for new projects. The backend sends pushes through the Admin SDK (step 7), so no server key is needed.

1. **Android:** nothing to do. Registering the app (step 5) is enough.
2. **iOS:** Apple Developer → **Keys → +** → enable **Apple Push Notifications service (APNs)** → download the `.p8` key.
   This can be the same key as Sign in with Apple if you enabled both services on it.
   Then go to Firebase ⚙ **Project settings → Cloud Messaging → Apple app configuration → APNs Authentication Key → Upload**
   and enter the `.p8` file, **Key ID** and **Team ID**.
   In Xcode, add the **Push Notifications** and **Background Modes → Remote notifications** capabilities to Runner.
3. **Web push:** ⚙ **Project settings → Cloud Messaging → Web configuration → Web Push certificates → Generate key pair**.
   Copy the public **VAPID key** into `web/src/environments/environment.ts` (`firebase.vapidKey`). The public key is not a secret.

---

## 5. Mobile apps: `flutterfire configure`

The `dev` flavor keeps using `mobile/lib/firebase_options.dart` (emulator, `demo-readin`). The `prod` flavor uses
`mobile/lib/firebase_options_prod.dart`, which is a committed placeholder until you generate it:

Start from a clean working tree (`git status` shows nothing), then:

```bash
cd mobile
flutterfire configure \
  --project=<PROJECT_ID> \
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

Keep the two downloaded service files locally for reference, because step 2.2 needs `REVERSED_CLIENT_ID` from the plist.
Never force-add them. Then add the Android SHA fingerprints and the iOS URL scheme (step 2.2).

Run against the real project:

```bash
flutter run --dart-define-from-file=config/prod.json
```

---

## 6. Web app config

1. ⚙ **Project settings → General → Your apps → Add app → Web (</>)**. Nickname `ReadIn Web`. Skip Firebase Hosting.
2. Copy the `firebaseConfig` values into `web/src/environments/environment.ts` (the production build):
   ```ts
   firebase: {
     apiKey: '…',
     authDomain: '<PROJECT_ID>.firebaseapp.com',
     projectId: '<PROJECT_ID>',
     storageBucket: '<PROJECT_ID>.firebasestorage.app',
     messagingSenderId: '…',
     appId: '…',
     vapidKey: '…',           // from step 4.3
   },
   assetsBaseUrl: 'https://firebasestorage.googleapis.com/v0/b/<PROJECT_ID>.firebasestorage.app/o',
   authEmulatorUrl: null,
   ```
   These are public identifiers and are safe to commit. `environment.development.ts` keeps pointing at the emulator.
3. Protect the browser API key: Google Cloud console → **APIs & Services → Credentials → Browser key** →
   **Application restrictions → Websites** → add `https://readin.app/*` (and `http://localhost:4200/*` only if you run
   the production build locally).

---

## 7. Admin SDK key for the backend (`dotnet user-secrets`)

The API uses the Admin SDK to provision system accounts, send FCM pushes and sign Storage upload URLs.

1. ⚙ **Project settings → Service accounts → Firebase Admin SDK → Generate new private key → Generate key**.
   A file like `<PROJECT_ID>-firebase-adminsdk-xxxxx.json` downloads. Keep it **outside** the repository.
2. Store it in user-secrets for the API project. Base64 avoids quoting problems with the JSON:

   **PowerShell**
   ```powershell
   $key = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\Downloads\<PROJECT_ID>-firebase-adminsdk-xxxxx.json"))
   dotnet user-secrets set "Firebase:ServiceAccountJson" $key --project backend/src/ReadIn.Api
   ```

   **bash**
   ```bash
   dotnet user-secrets set "Firebase:ServiceAccountJson" "$(base64 -w0 ~/Downloads/<PROJECT_ID>-firebase-adminsdk-xxxxx.json)" \
     --project backend/src/ReadIn.Api
   ```
   `Firebase:ServiceAccountJson` accepts the key as plain JSON or base64-encoded JSON.
3. **Delete the downloaded file** once the secret is stored: `dotnet user-secrets list --project backend/src/ReadIn.Api`
   should show `Firebase:ServiceAccountJson = ewog…`.
4. Point the API at the real project. Without the emulator flag the API refuses to start unless `Firebase:ProjectId` is set:
   ```bash
   dotnet user-secrets set "Firebase:ProjectId" "<PROJECT_ID>" --project backend/src/ReadIn.Api
   dotnet user-secrets set "Firebase:StorageBucket" "<PROJECT_ID>.firebasestorage.app" --project backend/src/ReadIn.Api
   ```
   Running locally against the real project also needs `Firebase:UseEmulator=false`. For example, start the API with
   `--Firebase:UseEmulator=false`. Demo seeders are then skipped automatically.
5. **Deployed API:** user-secrets exist only on a developer machine. On the server, set the same keys as environment
   variables from the host's secret store, using double underscores: `Firebase__ProjectId`, `Firebase__StorageBucket`,
   `Firebase__ServiceAccountJson`. Alternatively, leave `ServiceAccountJson` unset and give the host a workload identity
   (Application Default Credentials).
6. Optional SuperAdmin login (SPEC §18.3): `dotnet user-secrets set "Seed:SuperAdminPassword" "<strong password>" --project backend/src/ReadIn.Api`.
   In production, set `Seed__SuperAdminPassword` in the secret store and then run `dotnet run --project backend/src/ReadIn.Api -- seed`.

If signed uploads later fail with `403`, grant the Admin SDK service account the **Storage Object Admin** role on the
bucket (Google Cloud console → **Cloud Storage → Buckets → `<PROJECT_ID>.firebasestorage.app` → Permissions**).

---

## 8. Checklist

- [ ] `.firebaserc` `prod` alias = `<PROJECT_ID>`
- [ ] Email/Password, Google and Apple providers enabled; authorized domains set
- [ ] Storage bucket created, rules deployed, CORS applied
- [ ] APNs key uploaded; web VAPID key generated
- [ ] `mobile/lib/firebase_options_prod.dart` generated and committed; SHA fingerprints and iOS URL scheme added
- [ ] `web/src/environments/environment.ts` filled in; browser key restricted
- [ ] `Firebase:ServiceAccountJson`, `Firebase:ProjectId`, `Firebase:StorageBucket` stored with `dotnet user-secrets` (dev) / secret store (server); downloaded key file deleted
- [ ] No `google-services.json`, `GoogleService-Info.plist` or `*firebase-adminsdk*.json` in `git status`

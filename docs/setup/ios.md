# iOS Setup: Push Notifications + TestFlight Builds (no Mac needed)

iOS builds run on GitHub Actions macOS runners (`.github/workflows/ios.yml`) and upload straight to **TestFlight**, so you can install the app on an iPhone without owning a Mac.

| | |
|---|---|
| Bundle ID | `app.readin.readin` |
| Team ID | `7A25UFD8VC` |
| Push | `Runner/Runner.entitlements` (`aps-environment`) + `UIBackgroundModes = remote-notification` in `Info.plist` |
| Signing | Automatic, cloud-managed certificates through an App Store Connect API key (no `.p12` or provisioning profiles to manage) |
| Build number | GitHub run number |
| Dart config | `mobile/config/prod.json` (real Firebase project) |

## Already done
- [x] App ID `app.readin.readin` with **Push Notifications** (Apple Developer → Identifiers).
- [x] APNs key uploaded to Firebase (Development + Production) → Project settings → Cloud Messaging.
- [x] `GoogleService-Info.plist` in `mobile/ios/Runner/` (git-ignored, local only). The app initializes Firebase from `lib/firebase_options_prod.dart`, so CI does not need the plist.

## 1. Create the app in App Store Connect (once)
1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps** → **(+)** → **New App**.
2. Platform **iOS**, Name **ReadIn** (must be unique on the App Store; if taken, use e.g. `ReadIn - مقال كل يوم`), Primary language, Bundle ID **app.readin.readin**, SKU `readin-ios`, User Access **Full Access**.
3. **Create**.

Uploads fail with "No suitable application records were found" until this exists.

## 2. Create an App Store Connect API key (once)
This is **not** the APNs key. It lets GitHub Actions sign and upload builds.

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API** → **Team Keys**.
   (First time only: **Request Access**, then accept.)
2. **(+)** → Name `ReadIn GitHub Actions`, Access **Admin** → **Generate**.
   **Admin** is required: cloud-managed signing creates the distribution certificate for you.
3. **Download API Key** → `AuthKey_XXXXXXXXXX.p8`. It downloads **once**. Store it outside the repo, e.g. `C:\secrets\`.
4. Copy the **Key ID** (in the table) and the **Issuer ID** (above the table).

## 3. Add the GitHub secrets (once)
GitHub → repository **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret | Value |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | Key ID from step 2 |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from step 2 |
| `APP_STORE_CONNECT_KEY_BASE64` | The `.p8` file, base64-encoded (below) |

Base64 of the `.p8` in PowerShell (copies it to the clipboard, nothing printed):
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\secrets\AuthKey_XXXXXXXXXX.p8")) | Set-Clipboard
```

Or set all three with the GitHub CLI (`gh secret set` asks for the value, so it is not saved in shell history):
```powershell
gh secret set APP_STORE_CONNECT_KEY_ID --repo YoussefGhonem-hub/ReadIn
gh secret set APP_STORE_CONNECT_ISSUER_ID --repo YoussefGhonem-hub/ReadIn
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\secrets\AuthKey_XXXXXXXXXX.p8")) | gh secret set APP_STORE_CONNECT_KEY_BASE64 --repo YoussefGhonem-hub/ReadIn
```

## 4. Build and upload
Push a tag that starts with `ios-` from the commit you want to build (usually the tip of `dev`):
```bash
git tag ios-2 && git push origin ios-2
```
Use a new number each time. GitHub → **Actions** → **ios-testflight** shows the run. A build takes about 20–30 minutes.

The **Run workflow** button only appears once `ios.yml` exists on the default branch (`main`), because GitHub only offers manual runs for workflows on the default branch.

## 5. Install on your iPhone (TestFlight)
1. App Store Connect → ReadIn → **TestFlight**. The build appears after Apple finishes processing (5–30 minutes).
2. **Internal Testing** → **(+)** create a group (e.g. `Team`) → add yourself (your Apple ID must be a user in App Store Connect).
3. Install **TestFlight** from the App Store on the iPhone, open the invite email, and install ReadIn.

`ITSAppUsesNonExemptEncryption = false` is set in `Info.plist` (the app only uses standard HTTPS), so builds don't wait on the export-compliance question.

## Push notifications checklist
- Push only works on a **real iPhone** with the **prod** config. `lib/firebase_options_prod.dart` must contain the real project values (`flutterfire configure --project=<id> --out=lib/firebase_options_prod.dart`); placeholder values build fine but can't receive pushes.
- The entitlements file says `development`; Xcode switches it to `production` automatically when exporting for App Store / TestFlight.

## Costs
The repository is private, so macOS runner minutes count **10×** against the GitHub plan's included minutes (the Free plan's 2,000 minutes ≈ 200 macOS minutes ≈ 8–10 iOS builds per month). That is why the workflow is **manual only**.

## Troubleshooting
| Error | Fix |
|---|---|
| `Missing APP_STORE_CONNECT_* secrets` | Step 3. |
| `No Accounts` / `Cloud signing permission error` | The API key must have **Admin** access (step 2). |
| `You already have a current Distribution certificate` / certificate limit | Apple allows a limited number of distribution certificates. Revoke an unused one in Apple Developer → Certificates (check it isn't used by another app first). |
| `No suitable application records were found` | Step 1. |
| `The bundle version must be higher` | Re-run the workflow (each run gets a new build number). |
| Provisioning profile doesn't include `aps-environment` | Make sure **Push Notifications** is enabled on the App ID, then re-run. |

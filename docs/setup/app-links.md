# Share links and app links (F24)

A shared article link is the web's address of the article, `https://{domain}/{ar|en}/a/{slug}`. On a phone with
ReadIn installed it opens the article in the app; everywhere else it opens the web. The code is in place. What it
needs from you is a domain, and each place below set to it.

## How it works

| Part | What it does | Where |
|---|---|---|
| Web share button | Shares `{siteUrl}/{ar\|en}/a/{slug}`, the article's canonical URL | `web/src/environments/environment.ts` → `siteUrl` |
| Mobile share button (reader, attachment viewer) | Shares the same URL, in the version being read | `mobile/config/prod.json` → `WEB_ORIGIN` |
| Android App Links | The intent filter opens `https://{host}/ar/a/…` and `/en/a/…` in the app, after Android checks `/.well-known/assetlinks.json` | Host = `WEB_ORIGIN`, read by `mobile/android/app/build.gradle.kts` |
| iOS Universal Links | iOS opens the same paths in the app, after it checks `/.well-known/apple-app-site-association` | The Associated Domains entitlement (step 5 below) |
| `/.well-known/*` files | The web's SSR server builds both files from its environment variables | `web/src/server/app-links.ts`, `web/src/server.ts` |
| In the app | `/ar/a/{slug}` and `/en/a/{slug}` open the reader in that version (`/a/{slug}?lang=`) | `mobile/lib/app/router.dart`, `mobile/lib/core/push/push_links.dart` |

The app only opens links from the one domain in `WEB_ORIGIN`. A bad `WEB_ORIGIN` (not `https://`, or with a path)
stops the Android build with a message.

## What you need to do

1. **Pick the domain** the web app runs on, e.g. `https://readin.app`. (We don't own `readin.app` today. Every setting
   below defaults to it, so change all of them together.)
2. **Web.** Set `siteUrl` in `web/src/environments/environment.ts` to that origin. It is also the canonical URL for
   SEO.
3. **Mobile.** Set `WEB_ORIGIN` in `mobile/config/prod.json` (and `dev.json` if you test links on a dev build) to the
   same origin, then rebuild the apps. CI builds with `config/prod.json`.
4. **Android: the signing certificates.** On the server that runs the web's SSR build (`node
   dist/readin-web/server/server.mjs`), set:
   - `ANDROID_CERT_SHA256`: the SHA-256 fingerprints of the keys the installed app is signed with, comma separated:
     - the **app signing key** from Play Console → your app → Test and release → App integrity → App signing
       (Play re-signs every install with it);
     - the **upload key**, if you also install builds that don't come from Play:
       `keytool -list -v -keystore upload-keystore.jks -alias upload`;
     - for a debug build on your own phone, the debug key:
       `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android`.
   - `ANDROID_APP_ID` only if the application id changes (default `app.readin.readin`).

   Until `ANDROID_CERT_SHA256` is set, `/.well-known/assetlinks.json` answers 404 and links open in the browser.
   Note: release builds are still signed with the debug key (`mobile/android/app/build.gradle.kts`); set up release
   signing before publishing.
5. **iOS: Associated Domains.** These steps need a Mac or the Apple Developer site; I made no iOS change, because the
   entitlement names the domain and an iOS build can't be checked here.
   - In Xcode, open `mobile/ios/Runner.xcworkspace` → Runner target → Signing & Capabilities → **+ Capability** →
     Associated Domains, and add `applinks:{your domain}` (no `https://`). That writes this to
     `mobile/ios/Runner/Runner.entitlements`:
     ```xml
     <key>com.apple.developer.associated-domains</key>
     <array>
         <string>applinks:readin.app</string>
     </array>
     ```
   - CI signs automatically with the App Store Connect key (`-allowProvisioningUpdates`), which normally turns the
     capability on for the App ID `app.readin.readin`. If the archive fails with a provisioning error, enable
     **Associated Domains** under Certificates, Identifiers & Profiles → Identifiers → `app.readin.readin`, and run
     it again.
   - `IOS_APP_IDS` on the web server only if the Team ID or bundle id changes (default
     `7A25UFD8VC.app.readin.readin`).
6. **Serve the files over HTTPS with no redirect.** The phones fetch `https://{domain}/.well-known/assetlinks.json`
   and `https://{domain}/.well-known/apple-app-site-association` directly. A proxy or CDN in front of the SSR server must
   pass `/.well-known/*` through, with no redirect (including `http` → `https` or apex → `www`).

## Check it

- `curl -i https://{domain}/.well-known/apple-app-site-association` and `…/assetlinks.json`: `200`,
  `content-type: application/json`, no `Location` header.
- Google's checker:
  `https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://{domain}&relation=delegate_permission/common.handle_all_urls`.
- Android, with the app installed:
  - `adb shell pm verify-app-links --re-verify app.readin.readin`, then `adb shell pm get-app-links app.readin.readin`:
    the domain should say `verified`;
  - `adb shell am start -a android.intent.action.VIEW -d "https://{domain}/ar/a/{slug}"` opens the reader.
- iOS: Apple fetches the file through its CDN, `https://app-site-association.cdn-apple.com/a/v1/{domain}`, which can
  lag by hours. Then open a link from Notes or Messages (typing it into Safari doesn't open the app).

## Not built yet

SPEC F24 also has a **quote card**: select text in an article and share it as an image (light/dark). It is not
built.

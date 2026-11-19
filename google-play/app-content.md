# Play Console → App content: the answers

Every declaration Google Play asks for before the first release, with the answer for ReadIn and why. The labels are
Play Console's (English). Keep this in sync with the data map in [SPEC §9.6](../docs/SPEC.md#96-account-deletion--data-map)
and the privacy policy ([`web/public/legal/privacy.html`](../web/public/legal/privacy.html)).

## Privacy policy
- **Privacy policy URL:** `https://readin.online/privacy`

## App access
- **All or some functionality is restricted** → add one set of instructions:
  - **Name:** Review account
  - **Username / phone:** choose the country **United States (+1)** and enter `2025550150` (full number `+1 202 555 0150`, @readin_demo).
  - **Password:** the `REVIEWER_PASSWORD` value in `D:\tmp\readin-deploy\config.env` (never in git).
  - **Other information:** `Sign in with phone number and password. No SMS code is needed. Most of the app (Home, articles, Explore, Search) also works without an account through "Browse as guest".`
- Test the account on a real device the same day you submit.

## Ads
- **Does your app contain ads?** No.

## Content rating (IARC questionnaire)
- **Email:** the support email (below).
- **Category:** Reference, News, or Educational.
- Violence, fear, sexuality, nudity, profanity or crude humour, drugs, alcohol, tobacco, gambling, simulated gambling: **No** to all
  (the app's own content has none; user content is covered by the questions below and by the word filter and reporting).
- **Does the app allow users to interact or exchange content with other users?** Yes (comments, replies, articles, reposts, mentions).
- **Does the app share the user's current physical location with other users?** No.
- **Does the app allow users to purchase digital goods?** No.
- **Does the app contain a web browser or search engine (unrestricted internet access)?** No. Links in articles open the
  phone's own browser.
- **Is the app a primarily news or educational product?** Educational.

## Target audience and content
- **Target age groups:** 18 and over only (SPEC §32.5; the audience is developers, students and professionals aged 18–35).
- **Could the app unintentionally appeal to children?** No.
- No Families program, no "Teacher Approved".

## News apps
- **Is your app a news app?** No. It publishes educational articles, not news.

## Health apps, Financial features, Government apps
- None of these. Answer **No** / "My app doesn't provide any financial features".

## Advertising ID
- **Does your app use advertising ID?** No. The app has no ads or analytics SDK; check the merged manifest has no
  `com.google.android.gms.permission.AD_ID` before each release (`aapt dump permissions` on the APK).

## Data safety
**Overview answers**
- Does your app collect or share any of the required user data types? **Yes**
- Is all of the user data collected by your app encrypted in transit? **Yes** (HTTPS only)
- Which of the following methods of account creation does your app support? **Username and password** (phone number
  + password) and **OAuth** (Google; Apple on iOS only). "My app allows users to create an account".
- **Delete account URL:** `https://readin.online/delete-account`
- Do you provide a way for users to request that some or all of their data is deleted, without requiring them to delete
  their account? **No** (users delete their own content in the app; the whole account goes from Settings → Delete account).
- **Data shared with third parties:** none. Firebase (Google) only processes data for us as a service provider, which
  Google Play doesn't count as sharing. Nothing is sold or used for ads.

**Data collected** (all: collected, not shared, processed on our servers; "optional" = the user can use the app without it)

| Play data type | What it is in ReadIn | Required / optional | Purposes |
|---|---|---|---|
| Personal info → **Name** | Display name, @username, headline, bio | Required for an account | App functionality, Account management |
| Personal info → **Phone number** | Phone sign-in and recovery (not needed with Google sign-in) | Optional | App functionality, Account management, Fraud prevention, security, and compliance |
| Personal info → **Email address** | Only when the user links Google or Apple | Optional | Account management |
| Personal info → **User IDs** | Account id, @username | Required for an account | App functionality, Account management |
| Personal info → **Other info** | Social links on the profile | Optional | App functionality |
| Photos and videos → **Photos** | Profile photo, images in articles, support screenshots | Optional | App functionality |
| Files and docs → **Files and docs** | PDFs attached to articles, writer verification proof | Optional | App functionality |
| Messages → **Other in-app messages** | Support ticket conversations | Optional | App functionality, Developer communications |
| App activity → **App interactions** | Reading progress and streak, reactions, saves, follows, highlights, mutes, blocks | Optional | App functionality, Personalization |
| App activity → **Other user-generated content** | Articles, comments, replies, reposts, reports | Optional | App functionality |
| App activity → **Other actions** | Chosen interests and fields | Optional | Personalization |
| App activity → **In-app search history** | Searches that found nothing: kept without the searcher (query, language, day, count) for 90 days, so the team sees what readers miss | Optional | App functionality, Analytics |
| Device or other IDs → **Device or other IDs** | Push notification token (FCM) | Optional | App functionality |

Not collected: location, contacts, calendar, health, financial info, web browsing, audio, crash logs or analytics SDK
data. Recent searches stay on the phone.

## Permissions
The release APK's merged manifest (checked 2026-11-19 with `aapt dump permissions`) asks for `INTERNET`,
`ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS` (Android 13+), `WAKE_LOCK`, `VIBRATE` and Firebase Messaging's `c2dm.RECEIVE`
/ `READ_GSERVICES` for push, and `USE_BIOMETRIC` / `USE_FINGERPRINT`. No photo, camera, location, contacts or `AD_ID`
permissions: images are picked with the system photo picker. Nothing needs a permissions declaration form.

# نشر ReadIn على Google Play

كل اللي محتاجه علشان ترفع التطبيق على Google Play، من أول حساب المطوّر لحد ما التطبيق ينزل للناس. أسماء
الخانات مكتوبة زي ما هي في Play Console بالإنجليزي.

## محتويات الفولدر

| الملف | فيه إيه |
|---|---|
| [`graphics/icon-512.png`](graphics/icon-512.png) | أيقونة المتجر 512×512 |
| [`graphics/feature-graphic-ar.jpg`](graphics/feature-graphic-ar.jpg) و [`-en`](graphics/feature-graphic-en.jpg) | صورة الغلاف (Feature graphic) 1024×500 |
| [`graphics/phone-screenshots/ar/`](graphics/phone-screenshots/ar) و [`en/`](graphics/phone-screenshots/en) | 6 صور شاشة للموبايل لكل لغة، 1080×1920: الرئيسية، والمقال، والاستكشاف، ومسارات التعلّم، والبحث، والوضع الداكن |
| [`screenshots/raw/`](screenshots/raw) | نفس الشاشات من التطبيق الحقيقي من غير إطار (1080×2400). اتصوّرت يوم 2026-11-19 من نسخة الـ release على محاكي Pixel 7، على السيرفر الحقيقي، بحساب المراجعة |
| [`metadata/ar/`](metadata/ar) و [`metadata/en-US/`](metadata/en-US) | الاسم، والوصف القصير، والوصف الكامل، و"What's new" |
| [`app-content.md`](app-content.md) | إجابات كل نماذج App content: Data safety، والتصنيف العمري، والجمهور، والإعلانات، وحساب المراجعة |

الصور بتتعمل تاني من [`tools/google-play-assets/`](../../tools/google-play-assets): `node tools/google-play-assets/render.mjs`.

## معلومات سريعة

| | |
|---|---|
| اسم التطبيق | `ReadIn - مقال كل يوم` (عربي) / `ReadIn: Read Daily, Grow Daily` (إنجليزي) |
| Package name | `app.readin.readin` (مينفعش يتغيّر بعد أول رفع) |
| اللغة الأساسية للصفحة | العربية `ar`، والإنجليزية `en-US` ترجمة |
| النوع | App، مجاني (Free)، من غير إعلانات ولا مشتريات |
| التصنيف (Category) | Education |
| الموقع | `https://readin.online` |
| سياسة الخصوصية | `https://readin.online/privacy` |
| حذف الحساب | `https://readin.online/delete-account` |
| الدعم | `https://readin.online/support` |
| شروط الاستخدام | `https://readin.online/terms` |
| قواعد المجتمع | `https://readin.online/community-guidelines` |
| إيميل التواصل | `youssef.fcaih@gmail.com` (نفس الإيميل اللي في صفحة الخصوصية) |
| الجمهور | 18 سنة وأكبر |
| حساب المراجعة | `+1 202 555 0150` (@readin_demo)، والباسورد في `D:\tmp\readin-deploy\config.env` سطر `REVIEWER_PASSWORD` |

> **قبل أي حاجة:** لينكات `readin.online` لازم تفتح. Google بيرفض التطبيق لو لينك الخصوصية أو حذف الحساب مش شغال.

## 1. حساب المطوّر

1. اعمل حساب على [play.google.com/console](https://play.google.com/console) (25 دولار مرة واحدة)، وأكّد هويتك.
2. **لو الحساب شخصي (Personal) واتعمل بعد نوفمبر 2023:** Google مش هيسمحلك تنزل للناس على طول. لازم الأول
   **Closed testing** فيه **12 مختبر على الأقل** مشتركين **14 يوم ورا بعض**، وبعدها تطلب Production access.
   ابدأ تجمع الـ 12 إيميل (Gmail) من دلوقتي.
3. لو الحساب لشركة (Organization) محتاج رقم D-U-N-S، ومفيش شرط الـ 12 مختبر.

## 2. مفتاح الرفع (Upload key)

- المفتاح اتعمل ومتخزن **بره git**: `D:\tmp\readin-deploy\android\upload-keystore.jks`، والباسوردات في
  `D:\tmp\readin-deploy\android\key.properties`.
- **خد نسخة منهم في مكان آمن** (Google Drive خاص أو فلاشة). لو ضاعوا، ممكن تطلب من Google تغيّر مفتاح الرفع، بس
  ده بياخد أيام.
- علشان أي جهاز يبني نسخة للمتجر: انسخ `key.properties` لـ `mobile/android/key.properties` (متجاهل في git). من غيره
  النسخة بتتوقّع بمفتاح الـ debug، وGoogle بيرفضها.
- بصمة مفتاح الرفع:
  - SHA-1: `A5:34:37:10:C7:B0:FB:C1:4D:8D:3D:F1:03:BE:C7:BD:71:71:A6:8E`
  - SHA-256: `FD:DA:0A:C7:13:68:33:8E:4C:F5:28:61:1B:BE:9D:32:D2:1C:EB:73:84:B8:CD:A4:10:3B:56:EC:EF:E3:60:D5`

## 3. بناء النسخة (AAB)

من فولدر `mobile/`:

```bash
flutter build appbundle --release --dart-define-from-file=config/prod.json --build-number=1
```

- الملف بيطلع في `mobile/build/app/outputs/bundle/release/app-release.aab`.
- **أول نسخة جاهزة للرفع:** `D:\tmp\readin-deploy\android\readin-1.aab` (versionCode 1، اتبنت من `dev` في 2026-11-19
  وموقّعة بمفتاح الرفع).
- **`--build-number`** هو الـ versionCode: لازم يزيد كل مرة ترفع فيها نسخة جديدة (1، 2، 3...).
- `config/prod.json` بيوجّه التطبيق لـ `api.readin.online` و `readin.online`. ما تبنيش للمتجر من غيره.

## 4. Google sign-in على Android (Firebase)

تسجيل الدخول بجوجل على Android بيشتغل بس لو بصمة المفتاح اللي متوقّع بيه التطبيق متسجلة في Firebase:

1. في Play Console، بعد أول رفع: **Test and release → App integrity → App signing**. انسخ **SHA-1** بتاع
   **App signing key certificate** (ده مفتاح Google نفسه، غير مفتاح الرفع).
2. في [Firebase Console](https://console.firebase.google.com) → مشروع **readin-cca78** → Project settings → تطبيق
   Android `app.readin.readin` → **Add fingerprint**: ضيف الـ SHA-1 بتاع App signing، وكمان SHA-1 مفتاح الرفع اللي فوق.
3. نزّل `google-services.json` الجديد وحطه في `mobile/android/app/` (متجاهل في git، ما ترفعهوش)، وابني النسخة تاني
   برقم build أكبر.

> Sign in with Apple مش بيظهر على Android، ده طبيعي.

## 5. إنشاء التطبيق في Play Console

**Create app:**
- App name: `ReadIn - مقال كل يوم`
- Default language: **Arabic – ar**
- App or game: **App**
- Free or paid: **Free**
- وافق على الإقرارات (Developer Program Policies، US export laws).

## 6. صفحة المتجر (Grow users → Store presence → Main store listing)

| الخانة | منين |
|---|---|
| App name | `metadata/ar/title.txt` |
| Short description | `metadata/ar/short_description.txt` |
| Full description | `metadata/ar/full_description.txt` |
| App icon | `graphics/icon-512.png` |
| Feature graphic | `graphics/feature-graphic-ar.jpg` |
| Phone screenshots | الـ 6 صور في `graphics/phone-screenshots/ar/` بالترتيب |
| Tablet screenshots | سيبها فاضية |

بعدين **Add translations → English (United States) – en-US**، واملا نفس الخانات من `metadata/en-US/` و
`feature-graphic-en.jpg` و `phone-screenshots/en/`.

**Store settings:**
- App category: **Education**
- Tags: اختار لحد 5 من قايمة Google، الأقرب للقراءة والتعليم.
- Contact details: الإيميل والموقع اللي في الجدول فوق.

## 7. App content (Policy and programs → App content)

املا كل نموذج من [`app-content.md`](app-content.md). أهمهم:
- Privacy policy
- App access: حساب المراجعة
- Ads: لأ
- Content rating
- Target audience: 18+
- Data safety
- Government / Financial / Health / News: لأ

## 8. الاختبار والنشر

1. **Internal testing** (للتجربة بسرعة): Test and release → Testing → Internal testing → Create new release، ارفع
   الـ AAB، وضيف إيميلك. نزّل التطبيق من لينك الاختبار وجرّب:
   - التسجيل برقم موبايل
   - الدخول بجوجل
   - الإشعارات
   - حذف الحساب
2. **Closed testing** (إجباري للحساب الشخصي): نفس الـ AAB، والـ 12 مختبر، و14 يوم.
3. **Production:** Create new release → اختار الـ AAB → Release notes من `metadata/*/changelogs/1.txt` → Countries:
   كل الدول → **Send for review**. المراجعة عادة بتاخد من يوم لـ 7 أيام.

## 9. كل تحديث بعد كده

1. زوّد `--build-number` (versionCode).
2. ابني الـ AAB بنفس الأمر.
3. Production → Create new release → ارفع، واكتب What's new.

## ملاحظات

- النسخ اللي بتتبني من `dev` فيها «الركن الخاص» (F38). بيظهر لحساب الـ SuperAdmin بس، ومحتاجش إجابة في أي
  نموذج.
- قسم 32.5 في [SPEC](../SPEC.md#325-google-play) فيه متطلبات Google Play، والفولدر ده بيطبّقها.

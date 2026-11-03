// Renders every brand asset from logo.html and screenshots.html with the Playwright Chromium installed for web/.
//   node tools/app-store-assets/render.mjs
// Outputs:
//   docs/design/app-store/logo/          final logo files (icon, lockups, wordmarks)
//   docs/design/app-store/screenshots/   App Store screenshots (ar + en, 6.3" and 6.9")
//   content/assets/readin-avatar.png     avatar of the official ReadIn account (seeded)
//   mobile/ios/.../AppIcon.appiconset/   iOS app icons
//   mobile/android/app/src/main/res/     Android launcher icons (legacy + adaptive)
//   web/public/favicon.ico               web favicon (16/32/48)
import { createRequire } from "node:module";
import { mkdirSync, writeFileSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const require = createRequire(join(root, "web/package.json"));
const { chromium } = require("@playwright/test");

const design = join(root, "docs/design/app-store");
const logoUrl = (v) => `${pathToFileURL(join(here, "logo.html"))}?v=${v}`;
const ready = async (p) => {
  await p.evaluate(() => document.fonts.ready);
  await p.waitForTimeout(250);
};
const ensureDir = (file) => mkdirSync(dirname(file), { recursive: true });

const browser = await chromium.launch();

// Renders a full-viewport logo variant at an exact pixel size.
async function square(variant, size, file, transparent = false) {
  const p = await browser.newPage({ viewport: { width: size, height: size }, deviceScaleFactor: 1 });
  await p.goto(logoUrl(variant));
  await ready(p);
  ensureDir(file);
  await p.screenshot({ path: file, omitBackground: transparent });
  await p.close();
}

try {
  // ---------- Logo files ----------
  const logoDir = join(design, "logo");
  await square("icon", 1024, join(logoDir, "app-icon-1024.png"));
  await square("fg", 1024, join(logoDir, "android-adaptive-foreground-1024.png"), true);
  for (const v of ["lockup", "lockup-dark", "wordmark", "wordmark-dark"]) {
    const p = await browser.newPage({ viewport: { width: 1600, height: 500 }, deviceScaleFactor: 1 });
    await p.goto(logoUrl(v));
    await ready(p);
    await p.locator("#root > *").screenshot({ path: join(logoDir, `${v}.png`), omitBackground: true });
    await p.close();
  }

  // ---------- Official ReadIn account avatar (seeded by the backend) ----------
  await square("icon", 1024, join(root, "content/assets/readin-avatar.png"));

  // ---------- iOS app icons (filenames from AppIcon.appiconset/Contents.json) ----------
  const iosDir = join(root, "mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset");
  const contents = JSON.parse(readFileSync(join(iosDir, "Contents.json"), "utf8"));
  for (const img of contents.images) {
    if (!img.filename) continue;
    const px = Math.round(parseFloat(img.size) * parseInt(img.scale));
    await square("icon", px, join(iosDir, img.filename));
  }

  // ---------- Android launcher icons ----------
  const res = join(root, "mobile/android/app/src/main/res");
  const densities = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
  for (const [d, k] of Object.entries(densities)) {
    await square("icon", Math.round(48 * k), join(res, `mipmap-${d}`, "ic_launcher.png"));
    await square("fg", Math.round(108 * k), join(res, `mipmap-${d}`, "ic_launcher_foreground.png"), true);
    await square("bg", Math.round(108 * k), join(res, `mipmap-${d}`, "ic_launcher_background.png"));
  }
  const adaptive = join(res, "mipmap-anydpi-v26", "ic_launcher.xml");
  ensureDir(adaptive);
  writeFileSync(adaptive, `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
`);

  // ---------- Web favicon: an .ico that embeds 16/32/48 PNGs ----------
  const pngs = [];
  for (const px of [16, 32, 48]) {
    const tmp = join(design, "logo", `.favicon-${px}.png`);
    await square("icon", px, tmp);
    pngs.push({ px, data: readFileSync(tmp) });
  }
  const header = Buffer.alloc(6 + 16 * pngs.length);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(pngs.length, 4);
  let offset = header.length;
  pngs.forEach(({ px, data }, n) => {
    const e = 6 + 16 * n;
    header.writeUInt8(px, e);
    header.writeUInt8(px, e + 1);
    header.writeUInt16LE(1, e + 4);
    header.writeUInt16LE(32, e + 6);
    header.writeUInt32LE(data.length, e + 8);
    header.writeUInt32LE(offset, e + 12);
    offset += data.length;
  });
  writeFileSync(join(root, "web/public/favicon.ico"), Buffer.concat([header, ...pngs.map((p) => p.data)]));
  const { rmSync } = await import("node:fs");
  for (const px of [16, 32, 48]) rmSync(join(design, "logo", `.favicon-${px}.png`));

  // ---------- App Store screenshots ----------
  const shots = ["01-today", "02-reader-bilingual", "03-interests", "04-live-comments", "05-reading-streak", "06-dark-mode"];
  // Canvas is designed at 402×874 CSS px; ×3 gives the exact App Store pixel sizes.
  const sizes = [
    { name: "iphone-6.3in-1206x2622", w: 402, h: 874 },
    { name: "iphone-6.9in-1320x2868", w: 440, h: 956 },
  ];
  for (const size of sizes) {
    const p = await browser.newPage({ viewport: { width: size.w, height: size.h }, deviceScaleFactor: 3 });
    for (const lang of ["ar", "en"]) {
      const dir = join(design, "screenshots", size.name, lang);
      mkdirSync(dir, { recursive: true });
      for (let i = 0; i < shots.length; i++) {
        await p.goto(`${pathToFileURL(join(here, "screenshots.html"))}?lang=${lang}&shot=${i + 1}&w=${size.w}&h=${size.h}`);
        await ready(p);
        await p.screenshot({ path: join(dir, `${shots[i]}.png`) });
      }
    }
    await p.close();
  }
} finally {
  await browser.close();
}
console.log("Done");

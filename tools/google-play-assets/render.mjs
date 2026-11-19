// Renders the Google Play store graphics with the Playwright Chromium installed for web/ (as an image renderer only).
//   node tools/google-play-assets/render.mjs
// Inputs:
//   docs/google-play/screenshots/raw/{ar,en}/NN-name.png   real 1080×2400 captures of the release app (Android emulator)
//   tools/app-store-assets/logo.html                       the app icon (the same source as the launcher icons)
// Outputs (docs/google-play/graphics/):
//   icon-512.png                                           Play app icon: 512×512 PNG, full square (Play rounds it)
//   feature-graphic-{ar,en}.jpg                            1024×500, no transparency
//   phone-screenshots/{ar,en}/NN-name.jpg                  1080×1920 (9:16), no transparency
// Play wants JPEG or 24-bit PNG without alpha for the feature graphic and screenshots, so those are JPEG.
import { createRequire } from "node:module";
import { mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const require = createRequire(join(root, "web/package.json"));
const { chromium } = require("@playwright/test");

const out = join(root, "docs/google-play/graphics");
const SHOTS = ["01-home", "02-reader", "03-explore", "04-paths", "05-search", "06-dark"];
const ready = async (p) => {
  await p.evaluate(() => document.fonts.ready);
  await p.evaluate(() => Promise.all([...document.images].map((i) => i.decode().catch(() => {}))));
  await p.waitForTimeout(250);
};

const browser = await chromium.launch();
try {
  mkdirSync(out, { recursive: true });

  // App icon, from the same source as the launcher icons.
  const icon = await browser.newPage({ viewport: { width: 512, height: 512 }, deviceScaleFactor: 1 });
  await icon.goto(`${pathToFileURL(join(root, "tools/app-store-assets/logo.html"))}?v=icon`);
  await ready(icon);
  await icon.screenshot({ path: join(out, "icon-512.png") });
  await icon.close();

  for (const lang of ["ar", "en"]) {
    const feature = await browser.newPage({ viewport: { width: 1024, height: 500 }, deviceScaleFactor: 1 });
    await feature.goto(`${pathToFileURL(join(here, "feature.html"))}?lang=${lang}`);
    await ready(feature);
    await feature.screenshot({ path: join(out, `feature-graphic-${lang}.jpg`), type: "jpeg", quality: 95 });
    await feature.close();

    const dir = join(out, "phone-screenshots", lang);
    mkdirSync(dir, { recursive: true });
    const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
    for (let i = 0; i < SHOTS.length; i++) {
      await page.goto(`${pathToFileURL(join(here, "frame.html"))}?lang=${lang}&shot=${i + 1}`);
      await ready(page);
      await page.screenshot({ path: join(dir, `${SHOTS[i]}.jpg`), type: "jpeg", quality: 95 });
    }
    await page.close();
  }
} finally {
  await browser.close();
}
console.log("Done");

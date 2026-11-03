// Renders the logo concepts and a comparison sheet.
//   node tools/app-store-assets/render-logo-concepts.mjs      round 1 (logo-concepts.html)
//   node tools/app-store-assets/render-logo-concepts.mjs 2    round 2 (logo-concepts-2.html)
// Output: docs/design/app-store/logo/concepts[-2]/
import { createRequire } from "node:module";
import { mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const require = createRequire(join(root, "web/package.json"));
const { chromium } = require("@playwright/test");

const ROUNDS = {
  1: { html: "logo-concepts.html", dir: "concepts", names: ["01-r-and-ra", "02-daily-page", "03-bookmark", "04-step-in", "05-spark-of-insight", "06-morning-read"] },
  2: { html: "logo-concepts-2.html", dir: "concepts-2", names: ["01-meeting-pages", "02-ribbon-r", "03-bomy-the-owl"] },
  3: { html: "logo-concepts-3.html", dir: "concepts-3", names: ["01-rising-letters", "02-two-language-book", "03-readin-book"] },
};
const round = ROUNDS[process.argv[2] || "1"];
const out = join(root, "docs/design/app-store/logo", round.dir);
mkdirSync(out, { recursive: true });
const url = (q) => `${pathToFileURL(join(here, round.html))}?${q}`;

const browser = await chromium.launch();
try {
  const icon = await browser.newPage({ viewport: { width: 1024, height: 1024 } });
  for (let c = 1; c <= round.names.length; c++) {
    await icon.goto(url(`v=icon&c=${c}`));
    await icon.evaluate(() => document.fonts.ready);
    await icon.screenshot({ path: join(out, `${round.names[c - 1]}.png`) });
  }
  const sheet = await browser.newPage({ viewport: { width: 1800, height: 1000 }, deviceScaleFactor: 1 });
  await sheet.goto(url("v=sheet"));
  await sheet.evaluate(() => document.fonts.ready);
  await sheet.waitForTimeout(300);
  await sheet.locator(".sheet").screenshot({ path: join(out, "00-all-concepts.png") });
} finally {
  await browser.close();
}
console.log(`Done: ${out}`);

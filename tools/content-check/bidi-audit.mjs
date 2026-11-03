// BiDi audit of the Arabic versions in the real web reader (content/AUTHORING.md, SPEC §14.2). For every article it
// opens /ar/a/{slug} and checks that each text block of the body resolves RTL and that no Latin letter sits outside an
// isolate (<bdi>, inline <code>, a code block). Run against a web app that talks to an API seeded with content/.
//   node tools/content-check/bidi-audit.mjs --base http://localhost:4300 [--slug <slug>] [--field <field>]
import { createRequire } from "node:module";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const require = createRequire(join(root, "web/package.json"));
const { chromium } = require("@playwright/test");

const args = process.argv.slice(2);
const option = (name) => (args.includes(name) ? args[args.indexOf(name) + 1] : null);
const base = option("--base") ?? "http://localhost:4200";

function* metas(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const path = join(dir, entry.name);
    if (existsSync(join(path, "meta.json"))) yield JSON.parse(readFileSync(join(path, "meta.json"), "utf8"));
    else yield* metas(path);
  }
}
const articles = [...metas(join(root, "content/articles"))].filter(
  (m) => (!option("--slug") || m.slug === option("--slug")) && (!option("--field") || m.field === option("--field")),
);

const browser = await chromium.launch();
let failures = 0;
try {
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  for (const meta of articles) {
    await page.goto(`${base}/ar/a/${meta.slug}`, { waitUntil: "networkidle" });
    await page.locator("rd-rdoc").first().waitFor({ timeout: 20000 });
    const problems = await page.evaluate(() => {
      const out = [];
      const doc = document.querySelector("rd-rdoc");
      const blocks = doc.querySelectorAll("p, h2, h3, li, td, th, blockquote, .rd-callout, .rd-summary, .rd-step");
      for (const el of blocks) {
        if (el.closest("pre, .rd-code")) continue;
        if (getComputedStyle(el).direction !== "rtl") out.push(`LTR block: ${el.textContent.trim().slice(0, 80)}`);
      }
      const walker = document.createTreeWalker(doc, NodeFilter.SHOW_TEXT);
      for (let n = walker.nextNode(); n; n = walker.nextNode()) {
        if (!/[A-Za-z]/.test(n.textContent)) continue;
        if (n.parentElement.closest("bdi, code, pre, .rd-code, rd-code-view, .rd-code-tabs, button[data-term]")) continue;
        out.push(`not isolated: "${n.textContent.trim().slice(0, 60)}"`);
      }
      return out;
    });
    if (problems.length > 0) {
      failures++;
      console.log(`✗ ${meta.slug}`);
      for (const p of problems.slice(0, 8)) console.log(`    ${p}`);
    } else console.log(`✓ ${meta.slug}`);
  }
} finally {
  await browser.close();
}
console.log(failures === 0 ? `✓ ${articles.length} article(s): every block RTL, every English run isolated.` : `✗ ${failures} article(s) with BiDi problems.`);
process.exit(failures === 0 ? 0 : 1);

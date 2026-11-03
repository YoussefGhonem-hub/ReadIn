// Renders the cover of every seeded article (content/articles/**/cover.webp, 1200×630) from cover.html with the
// Playwright Chromium installed for web/. The seeder imports each cover through the image pipeline (ADR 0011).
//   node tools/content-covers/render.mjs                 # covers that are missing or older than their meta.json
//   node tools/content-covers/render.mjs --slug <slug>   # one article
//   node tools/content-covers/render.mjs --field dotnet  # one field
//   node tools/content-covers/render.mjs --force         # re-render everything (e.g. after a logo change)
//   node tools/content-covers/render.mjs --content backend/tests/fixtures/content   # another content root
import { createRequire } from "node:module";
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const require = createRequire(join(root, "web/package.json"));
const { chromium } = require("@playwright/test");
const yaml = require("js-yaml");
const lucide = require("lucide");

const args = process.argv.slice(2);
const option = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : null;
};
const onlySlug = option("--slug");
const onlyField = option("--field");
const force = args.includes("--force");
const contentRoot = resolve(root, option("--content") ?? "content");

// Deep versions of the field color tokens (taxonomy.yaml `color`), dark enough for white text in both themes.
const PALETTES = {
  primary: { colors: ["#1C806A", "#0F5E52", "#083F36"], accent: "#F2A93B" },
  accent: { colors: ["#B9741C", "#8A5212", "#4F2E0A"], accent: "#F7C062" },
  "callout-info-accent": { colors: ["#4C82BD", "#2F5A88", "#18324F"], accent: "#8DB3E2" },
  "callout-warning-accent": { colors: ["#B8701A", "#8A4F06", "#4A2A03"], accent: "#F5B95A" },
  "callout-danger-accent": { colors: ["#C9473A", "#972C22", "#541611"], accent: "#F5B95A" },
  success: { colors: ["#3A9A70", "#2E7D5B", "#163F2D"], accent: "#F2A93B" },
};
// Fields that share a token still get their own hue so the feed doesn't look uniform.
const FIELD_PALETTES = {
  "deep-learning-llms": { colors: ["#6E5BB8", "#4B3C8F", "#261D4F"], accent: "#C9B8FF" },
  databases: { colors: ["#2F8C9B", "#1D6573", "#0D3640"], accent: "#8FD6E0" },
  "devops-cloud": { colors: ["#4F6B8A", "#34495F", "#1A2633"], accent: "#8DB3E2" },
  "software-architecture": { colors: ["#7A6A4F", "#574A34", "#2E271B"], accent: "#F2A93B" },
  mobile: { colors: ["#2E8A7A", "#1B6B5E", "#0C3A33"], accent: "#F7C062" },
};
const LEVELS = { beginner: "مبتدئ", intermediate: "متوسط", advanced: "متقدم" };

const taxonomy = yaml.load(readFileSync(join(contentRoot, "taxonomy.yaml"), "utf8"));
const fields = new Map(taxonomy.fields.map((f) => [f.slug, f]));
const logo = `data:image/png;base64,${readFileSync(join(contentRoot, "assets/readin-avatar.png")).toString("base64")}`;

function iconSvg(name) {
  const key = name.replace(/(^|-)([a-z0-9])/g, (_, __, c) => c.toUpperCase());
  const nodes = lucide[key] ?? lucide.BookOpen;
  const attrs = (o) => Object.entries(o).map(([k, v]) => `${k}="${v}"`).join(" ");
  return `<svg viewBox="0 0 24 24">${nodes.map(([tag, a]) => `<${tag} ${attrs(a)}/>`).join("")}</svg>`;
}

function* articleFolders(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const path = join(dir, entry.name);
    if (existsSync(join(path, "meta.json"))) yield path;
    else yield* articleFolders(path);
  }
}

const jobs = [];
for (const folder of articleFolders(join(contentRoot, "articles"))) {
  const meta = JSON.parse(readFileSync(join(folder, "meta.json"), "utf8"));
  if (onlySlug && meta.slug !== onlySlug) continue;
  if (onlyField && meta.field !== onlyField) continue;
  const cover = join(folder, "cover.webp");
  const stale = !existsSync(cover) || statSync(cover).mtimeMs < statSync(join(folder, "meta.json")).mtimeMs;
  if (force || onlySlug || stale) jobs.push({ folder, meta, cover });
}

if (jobs.length === 0) {
  console.log("✓ Every cover is up to date.");
  process.exit(0);
}

const browser = await chromium.launch();
try {
  const page = await browser.newPage({ viewport: { width: 1200, height: 630 }, deviceScaleFactor: 1 });
  await page.goto(pathToFileURL(join(here, "cover.html")).href);
  await page.evaluate(() => document.fonts.ready);

  for (const { meta, cover } of jobs) {
    const field = fields.get(meta.field);
    if (!field) throw new Error(`${meta.slug}: unknown field ${meta.field}`);
    const palette = FIELD_PALETTES[field.slug] ?? PALETTES[field.color] ?? PALETTES.primary;
    const chips = [{ text: LEVELS[meta.level] ?? meta.level }];
    if (meta.versionBadge) chips.push({ text: meta.versionBadge, latin: true });

    await page.evaluate((d) => window.renderCover(d), {
      ...palette,
      iconSvg: iconSvg(field.icon ?? "book-open"),
      fieldAr: field.nameAr,
      titleAr: meta.translations["ar-EG"].title,
      titleEn: meta.translations.en.title,
      chips,
      logo,
    });
    const png = await page.screenshot({ type: "png" });
    const webp = await page.evaluate(([b64, q]) => window.toWebp(b64, q), [png.toString("base64"), 0.86]);
    writeFileSync(cover, Buffer.from(webp, "base64"));
    console.log(`✓ ${meta.slug} (${Math.round(statSync(cover).size / 1024)} KB)`);
  }
} finally {
  await browser.close();
}

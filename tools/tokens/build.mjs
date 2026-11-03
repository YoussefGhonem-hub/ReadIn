#!/usr/bin/env node
// Generates platform theme files from design/tokens.json (SPEC §3.4, §15).
//
//   node tools/tokens/build.mjs            # writes into the repo
//   node tools/tokens/build.mjs --check    # fails if generated files are stale (CI)
//   node tools/tokens/build.mjs --out DIR  # writes under DIR instead of the repo root
//   node tools/tokens/build.mjs --only web # only one platform (web | mobile)
//
// Outputs:
//   web/src/styles/tokens.css            CSS custom properties (light, dark, system)
//   web/src/styles/tokens.tailwind.css   Tailwind v4 @theme mapping onto those variables
//   mobile/lib/core/theme/tokens.g.dart  ThemeExtension<ReadInColors> + spacing/radius/type constants

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const args = process.argv.slice(2);
const check = args.includes('--check');
const outIndex = args.indexOf('--out');
const outRoot = outIndex >= 0 ? resolve(args[outIndex + 1]) : repoRoot;
const onlyIndex = args.indexOf('--only');
const only = onlyIndex >= 0 ? args[onlyIndex + 1] : null;

const tokens = JSON.parse(readFileSync(join(repoRoot, 'design', 'tokens.json'), 'utf8'));
const HEADER = 'GENERATED FILE — do not edit. Source: design/tokens.json, generator: tools/tokens/build.mjs';

const camel = (s) => s.replace(/[-.](\w)/g, (_, c) => c.toUpperCase());
const px = (n) => (n === 0 ? '0' : `${n}px`);

function hexToDart(hex) {
  const h = hex.replace('#', '').toUpperCase();
  if (h.length === 6) return `0xFF${h}`;
  if (h.length === 8) return `0x${h.slice(6)}${h.slice(0, 6)}`; // CSS #RRGGBBAA → Dart AARRGGBB
  throw new Error(`Unsupported color: ${hex}`);
}

// ── CSS ─────────────────────────────────────────────────────
function cssVars(mode) {
  const lines = [];
  for (const [name, v] of Object.entries(tokens.color)) lines.push(`  --rd-color-${name}: ${v[mode]};`);
  for (const [name, v] of Object.entries(tokens.elevation)) lines.push(`  --rd-elevation-${name}: ${v[mode]};`);
  lines.push(`  color-scheme: ${mode};`);
  return lines.join('\n');
}

function buildCss() {
  const f = tokens.font.family;
  const shared = [
    `  --rd-font-ui: "${f.arabic}", "${f.latin}", system-ui, sans-serif;`,
    `  --rd-font-latin: "${f.latin}", "${f.arabic}", system-ui, sans-serif;`,
    `  --rd-font-mono: "${f.mono}", ui-monospace, "Cascadia Code", monospace;`,
    ...Object.entries(tokens.typography).flatMap(([name, t]) => [
      `  --rd-text-${name}-size: ${px(t.size)};`,
      `  --rd-text-${name}-line: ${t.lineHeight};`,
      `  --rd-text-${name}-weight: ${t.weight};`,
    ]),
    ...Object.entries(tokens.articleFontScale).map(([k, v]) => `  --rd-article-size-${k}: ${px(v)};`),
    ...Object.entries(tokens.space).map(([k, v]) => `  --rd-space-${k}: ${px(v)};`),
    ...Object.entries(tokens.radius).map(([k, v]) => `  --rd-radius-${k}: ${px(v)};`),
    ...Object.entries(tokens.motion).map(([k, v]) => `  --rd-motion-${k}: ${v}ms;`),
    ...Object.entries(tokens.layout).map(([k, v]) => `  --rd-layout-${k.replace(/[A-Z]/g, (c) => '-' + c.toLowerCase())}: ${px(v)};`),
  ].join('\n');

  return `/* ${HEADER} */

/* Theme selection (SPEC §15.5):
 *   <html data-theme="light">  → light
 *   <html data-theme="dark">   → dark
 *   no attribute / "system"    → follows prefers-color-scheme
 */
:root {
${shared}
}

:root,
:root[data-theme="light"] {
${cssVars('light')}
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
${cssVars('dark').replace(/^/gm, '  ')}
  }
}

:root[data-theme="dark"] {
${cssVars('dark')}
}
`;
}

function buildTailwind() {
  const colorLines = Object.keys(tokens.color).map((n) => `  --color-${n}: var(--rd-color-${n});`);
  const radiusLines = Object.keys(tokens.radius).map((n) => `  --radius-${n}: var(--rd-radius-${n});`);
  const fontLines = [
    '  --font-sans: var(--rd-font-ui);',
    '  --font-latin: var(--rd-font-latin);',
    '  --font-mono: var(--rd-font-mono);',
  ];
  const shadowLines = Object.keys(tokens.elevation).map((n) => `  --shadow-${n}: var(--rd-elevation-${n});`);
  return `/* ${HEADER} */
/* Import after \`@import "tailwindcss";\` so utilities like bg-surface / text-text-primary follow the active theme. */
@theme inline {
${[...colorLines, ...radiusLines, ...fontLines, ...shadowLines].join('\n')}
}
`;
}

// ── Dart ────────────────────────────────────────────────────
function buildDart() {
  const names = Object.keys(tokens.color).map((n) => ({ key: n, field: camel(n) }));
  const instance = (mode) =>
    names.map(({ key, field }) => `    ${field}: Color(${hexToDart(tokens.color[key][mode])}),`).join('\n');

  const ty = Object.entries(tokens.typography)
    .map(([name, t]) => {
      const id = camel(name);
      return `  static const double ${id}Size = ${t.size};\n  static const double ${id}Height = ${t.lineHeight};\n  static const FontWeight ${id}Weight = FontWeight.w${t.weight};`;
    })
    .join('\n');

  return `// ${HEADER}
// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';

/// Semantic colors for ReadIn. Access with \`Theme.of(context).extension<ReadInColors>()!\`
/// (or the \`context.colors\` helper). Never use hex colors in widgets (SPEC §15.5).
@immutable
class ReadInColors extends ThemeExtension<ReadInColors> {
  const ReadInColors({
${names.map(({ field }) => `    required this.${field},`).join('\n')}
  });

${names.map(({ key, field }) => `  /// ${tokens.color[key].usage}\n  final Color ${field};`).join('\n')}

  static const light = ReadInColors(
${instance('light')}
  );

  static const dark = ReadInColors(
${instance('dark')}
  );

  @override
  ReadInColors copyWith({
${names.map(({ field }) => `    Color? ${field},`).join('\n')}
  }) {
    return ReadInColors(
${names.map(({ field }) => `      ${field}: ${field} ?? this.${field},`).join('\n')}
    );
  }

  @override
  ReadInColors lerp(ThemeExtension<ReadInColors>? other, double t) {
    if (other is! ReadInColors) return this;
    return ReadInColors(
${names.map(({ field }) => `      ${field}: Color.lerp(${field}, other.${field}, t)!,`).join('\n')}
    );
  }
}

abstract final class ReadInFonts {
  static const String arabic = '${tokens.font.family.arabic}';
  static const String latin = '${tokens.font.family.latin}';
  static const String mono = '${tokens.font.family.mono}';
}

abstract final class ReadInType {
${ty}
}

abstract final class ReadInArticleFontScale {
${Object.entries(tokens.articleFontScale).map(([k, v]) => `  static const double ${k} = ${v};`).join('\n')}
}

abstract final class ReadInSpace {
${Object.entries(tokens.space).map(([k, v]) => `  static const double s${k} = ${v};`).join('\n')}
}

abstract final class ReadInRadius {
${Object.entries(tokens.radius).map(([k, v]) => `  static const double ${camel(k)} = ${v};`).join('\n')}
}

abstract final class ReadInMotion {
${Object.entries(tokens.motion).map(([k, v]) => `  static const Duration ${k} = Duration(milliseconds: ${v});`).join('\n')}
}

abstract final class ReadInLayout {
${Object.entries(tokens.layout).map(([k, v]) => `  static const double ${k} = ${v};`).join('\n')}
}
`;
}

// ── Write / check ───────────────────────────────────────────
const outputs = [
  ['web/src/styles/tokens.css', buildCss()],
  ['web/src/styles/tokens.tailwind.css', buildTailwind()],
  ['mobile/lib/core/theme/tokens.g.dart', buildDart()],
].filter(([rel]) => !only || rel.startsWith(`${only}/`));

let stale = 0;
for (const [rel, content] of outputs) {
  const target = join(outRoot, rel);
  if (check) {
    const current = existsSync(target) ? readFileSync(target, 'utf8') : '';
    if (current.replace(/\r\n/g, '\n') !== content) {
      console.error(`✗ stale: ${rel}`);
      stale++;
    }
    continue;
  }
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, content);
  console.log(`✓ ${rel}`);
}

if (check && stale > 0) {
  console.error('Design tokens are out of date. Run: node tools/tokens/build.mjs');
  process.exit(1);
}

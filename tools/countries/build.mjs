// Generates shared/countries/countries.json for the phone field + country picker (SPEC §9.4), and the Dart copies the
// mobile app compiles in (Flutter assets can't reference ../shared).
//
//   cd tools/countries && npm ci && npm run build   # countries.json from libphonenumber-js, then the mobile copies
//   node tools/countries/build.mjs --mobile         # only the mobile copies, from the files in shared/ (no npm needed)
//   node tools/countries/build.mjs --check          # fails if the mobile copies are stale (CI)
//
// Calling codes and example mobile numbers come from libphonenumber-js (the same metadata the web uses to validate);
// country names come from ICU via Intl.DisplayNames (Node ships full ICU). Web reads the JSON as is.
//
// Mobile outputs (never edit them by hand):
//   mobile/lib/core/phone/country_list.g.dart        the country list, pinned order and default country
//   mobile/lib/core/security/common_secrets.g.dart   shared/security/common-pins.txt + common-passwords.txt
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, resolve, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, '../..');
const output = resolve(repoRoot, 'shared/countries/countries.json');
const pinsFile = resolve(repoRoot, 'shared/security/common-pins.txt');
const passwordsFile = resolve(repoRoot, 'shared/security/common-passwords.txt');
const mobileCountries = resolve(repoRoot, 'mobile/lib/core/phone/country_list.g.dart');
const mobileSecrets = resolve(repoRoot, 'mobile/lib/core/security/common_secrets.g.dart');

const args = process.argv.slice(2);
const check = args.includes('--check');
const mobileOnly = args.includes('--mobile');

/** Shown first, in this order (SPEC §9.4); everything else is sorted by name in the UI language. */
const PINNED = ['EG', 'SA', 'AE', 'KW', 'QA', 'BH', 'OM', 'JO', 'LB', 'IQ', 'MA', 'DZ', 'TN', 'LY', 'SD', 'PS', 'SY', 'YE'];

/** Names that read better than ICU's defaults in this product. */
const NAME_OVERRIDES = {
  PS: { nameAr: 'فلسطين', nameEn: 'Palestine' },
};

async function buildSharedCountries() {
  const { getCountries, getCountryCallingCode, getExampleNumber } = await import('libphonenumber-js/max');
  const { default: mobileExamples } = await import('libphonenumber-js/mobile/examples');
  const pkg = JSON.parse(readFileSync(resolve(here, 'package.json'), 'utf8'));

  const ar = new Intl.DisplayNames(['ar'], { type: 'region' });
  const en = new Intl.DisplayNames(['en'], { type: 'region' });

  const countries = getCountries()
    .map((iso2) => {
      const example = getExampleNumber(iso2, mobileExamples);
      return {
        iso2,
        dialCode: getCountryCallingCode(iso2),
        nameAr: NAME_OVERRIDES[iso2]?.nameAr ?? ar.of(iso2),
        nameEn: NAME_OVERRIDES[iso2]?.nameEn ?? en.of(iso2),
        exampleNational: example ? example.formatNational() : '',
      };
    })
    .filter((c) => c.nameEn && c.nameEn !== c.iso2)
    .sort((a, b) => a.iso2.localeCompare(b.iso2));

  const missing = PINNED.filter((iso2) => !countries.some((c) => c.iso2 === iso2));
  if (missing.length) throw new Error(`Pinned countries missing from the metadata: ${missing.join(', ')}`);

  mkdirSync(dirname(output), { recursive: true });
  writeFileSync(
    output,
    JSON.stringify({ source: `libphonenumber-js ${pkg.devDependencies['libphonenumber-js']}`, defaultCountry: 'EG', pinned: PINNED, countries }, null, 2) + '\n',
  );
  console.log(`Wrote ${countries.length} countries to ${output}`);
}

// ── Mobile (Dart) copies ──────────────────────────────────────────
const HEADER = '// GENERATED FILE — do not edit. Generator: tools/countries/build.mjs';

/** A single-quoted Dart string literal. */
const dart = (s) => `'${s.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$')}'`;

const readLines = (file) =>
  readFileSync(file, 'utf8')
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);

function mobileCountriesDart() {
  const data = JSON.parse(readFileSync(output, 'utf8'));
  const rows = data.countries.map(
    (c) =>
      `  Country(iso2: ${dart(c.iso2)}, dialCode: ${dart(c.dialCode)}, nameAr: ${dart(c.nameAr)}, nameEn: ${dart(c.nameEn)}, exampleNational: ${dart(c.exampleNational)}),`,
  );
  return `${HEADER}
// Source: shared/countries/countries.json (${data.source}).
part of 'countries.dart';

const String _defaultCountry = ${dart(data.defaultCountry)};

const List<String> _pinned = [${data.pinned.map(dart).join(', ')}];

const List<Country> _countries = [
${rows.join('\n')}
];
`;
}

function mobileSecretsDart() {
  const set = (lines) => lines.map((l) => `  ${dart(l)},`).join('\n');
  return `${HEADER}
// Source: shared/security/common-pins.txt and common-passwords.txt (SecLists, MIT).
part of 'credential_rules.dart';

/// The 100 most common 4-digit PINs.
const Set<String> _commonPins = {
${set(readLines(pinsFile))}
};

/// Common passwords that would otherwise pass the rules, lower-cased.
const Set<String> _commonPasswords = {
${set(readLines(passwordsFile))}
};
`;
}

const normalize = (s) => s.replace(/\r\n/g, '\n');

function writeOrCheck(file, content) {
  const name = relative(repoRoot, file).replace(/\\/g, '/');
  if (check) {
    const current = existsSync(file) ? normalize(readFileSync(file, 'utf8')) : null;
    if (current !== content) {
      console.error(`Stale: ${name}. Run: node tools/countries/build.mjs --mobile`);
      return false;
    }
    console.log(`Up to date: ${name}`);
    return true;
  }
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, content);
  console.log(`Wrote ${name}`);
  return true;
}

if (!check && !mobileOnly) await buildSharedCountries();
const ok = [writeOrCheck(mobileCountries, mobileCountriesDart()), writeOrCheck(mobileSecrets, mobileSecretsDart())].every(Boolean);
if (!ok) process.exit(1);

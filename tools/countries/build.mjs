// Generates shared/countries/countries.json for the phone field + country picker (SPEC §9.4).
//
//   cd tools/countries && npm ci && npm run build
//
// Calling codes and example mobile numbers come from libphonenumber-js (the same metadata the web uses to validate);
// country names come from ICU via Intl.DisplayNames (Node ships full ICU). Web and mobile read the JSON as is.
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { getCountries, getCountryCallingCode, getExampleNumber } from 'libphonenumber-js/max';
import mobileExamples from 'libphonenumber-js/mobile/examples';
import pkg from './package.json' with { type: 'json' };

const here = dirname(fileURLToPath(import.meta.url));
const output = resolve(here, '../../shared/countries/countries.json');

/** Shown first, in this order (SPEC §9.4); everything else is sorted by name in the UI language. */
const PINNED = ['EG', 'SA', 'AE', 'KW', 'QA', 'BH', 'OM', 'JO', 'LB', 'IQ', 'MA', 'DZ', 'TN', 'LY', 'SD', 'PS', 'SY', 'YE'];

/** Names that read better than ICU's defaults in this product. */
const NAME_OVERRIDES = {
  PS: { nameAr: 'فلسطين', nameEn: 'Palestine' },
};

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

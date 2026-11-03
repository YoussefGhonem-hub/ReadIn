import ar from '../../../../public/i18n/ar.json';
import en from '../../../../public/i18n/en.json';
import { CONTRACT_ERROR_CODES } from './error-messages';

function lookup(source: unknown, key: string): unknown {
  return key.split('.').reduce<unknown>((node, part) => (node && typeof node === 'object' ? (node as Record<string, unknown>)[part] : undefined), source);
}

describe('Error code translations (docs/api/contract-v1.md)', () => {
  for (const [lang, strings] of [['ar', ar], ['en', en]] as const) {
    it(`translates every contract error code in ${lang}`, () => {
      const missing = CONTRACT_ERROR_CODES.filter((code) => {
        const text = lookup(strings, `errors.${code}`);
        return typeof text !== 'string' || !text.trim();
      });
      expect(missing).toEqual([]);
    });
  }
});

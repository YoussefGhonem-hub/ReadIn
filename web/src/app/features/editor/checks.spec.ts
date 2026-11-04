import ar from '../../../../public/i18n/ar.json';
import en from '../../../../public/i18n/en.json';
import { DraftChecksDto, DraftProblemCode, DraftProblemDto } from '../../core/api/models';
import { checkItems, readingTimeOf, titleState } from './checks';

const ALL_CODES: DraftProblemCode[] = [
  'article.field_required',
  'article.title_length',
  'article.content_empty',
  'article.content_invalid',
  'article.image_alt_required',
  'article.sources_required',
  'attachments.alt_text_required',
  'attachments.title_required',
  'attachments.asset_not_ready',
];

function problem(code: DraftProblemCode, patch: Partial<DraftProblemDto> = {}): DraftProblemDto {
  return { code, language: null, blockId: null, mediaAssetId: null, ...patch };
}

function lookup(source: unknown, key: string): unknown {
  return key.split('.').reduce<unknown>((node, part) => (node && typeof node === 'object' ? (node as Record<string, unknown>)[part] : undefined), source);
}

describe('live checks (checks.problems → what the editor shows)', () => {
  it('has an Arabic and an English message for every problem code', () => {
    const items = checkItems({ readingTime: [], problems: ALL_CODES.map((code) => problem(code)) }, 'ar-EG');
    expect(items).toHaveLength(ALL_CODES.length);
    for (const item of items) {
      for (const strings of [ar, en]) {
        const text = lookup(strings, item.messageKey);
        expect(typeof text === 'string' && text.length > 0, `${item.messageKey}`).toBe(true);
      }
    }
  });

  it('points each problem at the place to fix it', () => {
    const checks: DraftChecksDto = {
      readingTime: [],
      problems: [
        problem('article.image_alt_required', { language: 'en', blockId: 'img1' }),
        problem('article.title_length', { language: 'en' }),
        problem('attachments.alt_text_required', { mediaAssetId: 'asset-1' }),
        problem('article.sources_required'),
        problem('article.content_invalid', { language: 'ar-EG' }),
        problem('article.field_required'),
        problem('article.title_length', { language: 'ar-EG' }),
      ],
    };
    expect(checkItems(checks, 'ar-EG').map((i) => i.target)).toEqual([
      { kind: 'field' },
      { kind: 'title', language: 'ar-EG' },
      { kind: 'title', language: 'en' },
      { kind: 'content', language: 'ar-EG' },
      { kind: 'block', language: 'en', blockId: 'img1' },
      { kind: 'sources' },
      { kind: 'attachment', mediaAssetId: 'asset-1' },
    ]);
  });

  it('drops duplicates and copes with unknown codes', () => {
    const items = checkItems(
      { readingTime: [], problems: [problem('article.field_required'), problem('article.field_required'), problem('article.something_new' as DraftProblemCode)] },
      'en',
    );
    expect(items.map((i) => i.messageKey)).toEqual(['editor.problems.article_field_required', 'editor.problems.unknown']);
    expect(checkItems(null, 'en')).toEqual([]);
  });

  it('shows the title length while typing (trimmed, 5..150)', () => {
    expect(titleState('')).toEqual({ length: 0, state: 'empty' });
    expect(titleState('  DI  ')).toEqual({ length: 2, state: 'short' });
    expect(titleState('يعني إيه DI؟')).toEqual({ length: 12, state: 'ok' });
    expect(titleState('a'.repeat(151))).toEqual({ length: 151, state: 'long' });
  });

  it('reads the reading time of one language version', () => {
    const checks: DraftChecksDto = { readingTime: [{ language: 'en', minutes: 4, words: 812 }], problems: [] };
    expect(readingTimeOf(checks, 'en')).toEqual({ minutes: 4, words: 812 });
    expect(readingTimeOf(checks, 'ar-EG')).toBeNull();
    expect(readingTimeOf(null, 'en')).toBeNull();
  });
});

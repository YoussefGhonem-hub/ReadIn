import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import ar from '../../../../public/i18n/ar.json';
import en from '../../../../public/i18n/en.json';
import { translocoTesting } from '../../../testing/transloco-testing';
import { ApiError } from '../api/api.config';
import { CONTRACT_ERROR_CODES, ErrorMessages } from './error-messages';

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

describe('Tag errors (F32)', () => {
  // The API's wording (ErrorMessages.cs), as mobile has it; the symbols stay in order in Arabic (LRI … PDI).
  const expected: Record<string, [string, string]> = {
    'tag.not_found': ['التاج ده مش موجود.', 'Tag not found.'],
    'tag.invalid': [
      'التاج لازم يكون من 2 لـ 30 حرف: حروف وأرقام ومسافات و \u2066- _ . + #\u2069 بس.',
      'A tag has 2–30 characters: letters, digits, spaces and - _ . + # only.',
    ],
    'tag.limit': [
      'عملت تاجات جديدة كتير النهارده. اختار من التاجات الموجودة، أو جرّب تاني بعدين.',
      "You've created a lot of new tags today. Pick existing tags, or try again later.",
    ],
    'tag.hidden': ['التاج ده مش متاح، اختار تاج تاني.', "This tag isn't available. Choose another one."],
    'article.too_many_tags': ['أقصى حاجة 5 تاجات للمقال.', 'An article can have at most 5 tags.'],
  };

  it('read like the API in both languages', () => {
    for (const [code, [arabic, english]] of Object.entries(expected)) {
      expect(lookup(ar, `errors.${code}`), code).toBe(arabic);
      expect(lookup(en, `errors.${code}`), code).toBe(english);
    }
  });

  it('the editor problems say the same', () => {
    for (const strings of [ar, en]) {
      expect(strings.editor.problems.tag_hidden).toBe(strings.errors.tag.hidden);
      expect(strings.editor.problems.tag_limit).toBe(strings.errors.tag.limit);
    }
  });
});

describe('Suspended account message (F22)', () => {
  const suspended = (suspendedUntil?: string | null) =>
    new ApiError(403, 'user.suspended', { title: 'This account is suspended.', status: 403, code: 'user.suspended', ...(suspendedUntil === undefined ? {} : { suspendedUntil }) });

  function setup(lang: 'ar' | 'en') {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({ imports: [translocoTesting()] });
    TestBed.inject(TranslocoService).setActiveLang(lang);
    return TestBed.inject(ErrorMessages);
  }

  it('says until when (date and time in the UI language), or that it is permanent', () => {
    const errors = setup('ar');
    const until = errors.forError(suspended('2026-11-10T14:30:00Z'));
    expect(until).toMatch(/^الحساب ده موقوف لحد .*2026.*\.$/);
    expect(until).toContain('نوفمبر');
    expect(errors.forError(suspended(null))).toBe('الحساب ده موقوف نهائيًا. تواصل مع الدعم.');
    // An API that sends no end at all: the plain message.
    expect(errors.forError(suspended())).toBe('الحساب ده موقوف. تواصل مع الدعم');

    const english = setup('en');
    expect(english.forError(suspended('2026-11-10T14:30:00Z'))).toMatch(/^This account is suspended until November 10, 2026.*\.$/);
    expect(english.forError(suspended(null))).toBe('This account is suspended permanently. Contact support.');
  });

  it('other codes are unchanged', () => {
    const errors = setup('en');
    expect(errors.forError(new ApiError(404, 'article.not_found', null))).toBe(en.errors.article.not_found);
    expect(errors.forError(new ApiError(400, 'moderation.note_required', null))).toBe('Write a note for the user.');
    expect(errors.forError(new Error('boom'))).toBe(en.errors.unknown);
  });
});

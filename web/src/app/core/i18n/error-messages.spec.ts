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
    'tag.not_found': ['هذا الوسم غير موجود.', 'Tag not found.'],
    'tag.invalid': [
      'يجب أن يتكون الوسم من 2 إلى 30 حرفًا: حروف وأرقام ومسافات و \u2066- _ . + #\u2069 فقط.',
      'A tag has 2–30 characters: letters, digits, spaces and - _ . + # only.',
    ],
    'tag.limit': [
      'أنشأت وسومًا جديدة كثيرة اليوم. اختر من الوسوم الموجودة، أو حاول مرة أخرى لاحقًا.',
      "You've created a lot of new tags today. Pick existing tags, or try again later.",
    ],
    'tag.hidden': ['هذا الوسم غير متاح. اختر وسمًا آخر.', "This tag isn't available. Choose another one."],
    'article.too_many_tags': ['الحد الأقصى 5 وسوم للمقال الواحد.', 'An article can have at most 5 tags.'],
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

describe('Writer category errors (F31)', () => {
  // The API's wording (ErrorMessages.cs), as mobile has it.
  const expected: Record<string, [string, string]> = {
    'category.not_found': ['هذه الفئة غير موجودة.', 'Category not found.'],
    'category.not_owner': ['هذه الفئة ليست لك.', "This category isn't yours."],
    'category.limit': ['وصلت إلى الحد الأقصى لعدد الفئات (50).', 'You can have at most 50 categories.'],
    'category.name_taken': ['لديك فئة بالاسم نفسه بالفعل.', 'You already have a category with this name.'],
    'category.name_invalid': [
      'يجب أن يتكون اسم الفئة من 1 إلى 40 حرفًا، وأن يتضمن حرفًا أو رقمًا واحدًا على الأقل.',
      'A category name has 1–40 characters, with at least one letter or digit.',
    ],
  };

  it('read like the API in both languages', () => {
    for (const [code, [arabic, english]] of Object.entries(expected)) {
      expect(lookup(ar, `errors.${code}`), code).toBe(arabic);
      expect(lookup(en, `errors.${code}`), code).toBe(english);
    }
  });
});

describe('Quote card errors (F24)', () => {
  // The contract's table (docs/api/contract-v1.md → Quote card (F24)): its English, and its Arabic said in Modern Standard
  // Arabic (SPEC §14.4; mobile keeps the contract's Egyptian wording).
  const expected: Record<string, [string, string]> = {
    'quote.text_mismatch': ['تغيّر هذا النص في المقال. حدّث الصفحة وحاول مرة أخرى.', 'This text has changed in the article. Reload and try again.'],
    'quote.block_not_allowed': ['لا يمكن مشاركة هذا الجزء كاقتباس.', "This part can't be shared as a quote."],
    'quote.too_short': ['حدّد 3 أحرف على الأقل.', 'Select at least 3 characters.'],
    'quote.too_long': ['يجب ألا يتجاوز الاقتباس 400 حرف. حدّد جزءًا أقصر.', 'A quote can be at most 400 characters. Select less text.'],
    'quote.hidden': ['أخفى المشرفون هذا المقال، لذا لا يمكن مشاركة اقتباس منه.', "Moderators hid this article, so its quotes can't be shared."],
    'quote.limit': ['أنشأت بطاقات اقتباس كثيرة خلال هذه الساعة. حاول مرة أخرى لاحقًا.', "You've made many quote cards this hour. Try again later."],
    'quote.busy': ['يجري الآن تجهيز بطاقات كثيرة. حاول مرة أخرى بعد قليل.', 'Many cards are being prepared right now. Try again in a moment.'],
    'quote.failed': ['تعذّر تجهيز بطاقة الاقتباس. حاول مرة أخرى.', "We couldn't prepare the quote card. Try again."],
  };

  it('read like the API in both languages', () => {
    for (const [code, [arabic, english]] of Object.entries(expected)) {
      expect(lookup(ar, `errors.${code}`), code).toBe(arabic);
      expect(lookup(en, `errors.${code}`), code).toBe(english);
    }
  });

  it('the dialog says "Article not found." and that the internet is needed, as the contract does', () => {
    expect([ar.quoteCard.notFound, en.quoteCard.notFound]).toEqual(['المقال غير موجود.', 'Article not found.']);
    expect([ar.quoteCard.offline, en.quoteCard.offline]).toEqual(['تحتاج إلى اتصال بالإنترنت لإنشاء بطاقة اقتباس.', 'You need an internet connection to make a quote card.']);
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
    expect(until).toMatch(/^هذا الحساب موقوف حتى .*2026.*\.$/);
    expect(until).toContain('نوفمبر');
    expect(errors.forError(suspended(null))).toBe('هذا الحساب موقوف نهائيًا. تواصل مع الدعم.');
    // An API that sends no end at all: the plain message.
    expect(errors.forError(suspended())).toBe('هذا الحساب موقوف. تواصل مع الدعم.');

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

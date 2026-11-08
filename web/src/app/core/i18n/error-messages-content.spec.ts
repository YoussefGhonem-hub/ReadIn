import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { translocoTesting } from '../../../testing/transloco-testing';
import { ApiError } from '../api/api.config';
import { ProblemDetails } from '../api/models';
import { CONTRACT_ERROR_CODES, ErrorMessages } from './error-messages';

const problemOf = (code: string, patch: Partial<ProblemDetails> = {}): ProblemDetails => ({ type: 'about:blank', title: code, status: 422, code, ...patch }) as ProblemDetails;

describe('Block, terms and content filter errors (F36, F37)', () => {
  let errors: ErrorMessages;

  beforeEach(() => {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({ imports: [translocoTesting()] });
    errors = TestBed.inject(ErrorMessages);
  });

  it('are contract codes with the API wording', () => {
    const expected: Record<string, string> = {
      'block.self': 'لا يمكنك حظر نفسك.',
      'block.limit': 'وصلت إلى الحد الأقصى للحسابات المحظورة (1000 حساب).',
      'block.blocked': 'هذا الحساب محظور لديك. ألغِ الحظر أولًا.',
      'auth.terms_required': 'يجب الموافقة على شروط الاستخدام وقواعد المجتمع لإنشاء حساب.',
      'content.objectionable': 'هذا النص يخالف قواعد المجتمع. عدّله وحاول مرة أخرى.',
      'content.too_many': 'وصلت إلى الحد المسموح به: 5 مقالات في اليوم و60 تعليقًا في الساعة.',
      'content_filter.term_invalid': 'أدخل كلمة صالحة من حرفين على الأقل.',
      'repost.not_found': 'إعادة النشر هذه غير موجودة.',
    };
    for (const [code, text] of Object.entries(expected)) {
      expect(CONTRACT_ERROR_CODES).toContain(code);
      expect(errors.forCode(code)).toBe(text);
    }
    expect(TestBed.inject(TranslocoService).translate('errors.block.self', {}, 'en')).toBe("You can't block yourself.");
  });

  it('content.objectionable is one message, never the matched words (the form shows it on the field it names)', () => {
    const error = (patch: Partial<ProblemDetails>) => new ApiError(422, 'content.objectionable', problemOf('content.objectionable', patch));
    for (const patch of [{ field: 'body' }, { field: 'title', language: 'en' as const }, { field: 'somethingNew' }, {}]) {
      expect(errors.forError(error(patch))).toBe('هذا النص يخالف قواعد المجتمع. عدّله وحاول مرة أخرى.');
    }
  });

  it('content.objectionable also marks the field, so a form shows it under that field', () => {
    const error = new ApiError(422, 'content.objectionable', problemOf('content.objectionable', { field: 'caption' }));
    expect(error.validationErrors).toEqual({ caption: ['content.objectionable'] });
    const withOthers = new ApiError(422, 'content.objectionable', problemOf('content.objectionable', { field: 'bio', errors: { bio: ['user.bio_too_long'] } }));
    expect(withOthers.validationErrors).toEqual({ bio: ['user.bio_too_long', 'content.objectionable'] });
    // Any other code keeps its errors as they are.
    const other = new ApiError(400, 'validation.failed', problemOf('validation.failed', { field: 'bio', errors: { bio: ['x'] } }));
    expect(other.validationErrors).toEqual({ bio: ['x'] });
  });

  it('content.too_many says which limit was reached', () => {
    const error = (limit?: string) => new ApiError(429, 'content.too_many', problemOf('content.too_many', limit ? { limit } : {}));
    expect(errors.forError(error('articles_per_day'))).toBe('يمكنك نشر 5 مقالات جديدة في اليوم. حاول مرة أخرى غدًا.');
    expect(errors.forError(error('comments_per_hour'))).toBe('يمكنك كتابة 60 تعليقًا في الساعة. حاول مرة أخرى بعد قليل.');
    expect(errors.forError(error('unknown_limit'))).toBe('وصلت إلى الحد المسموح به: 5 مقالات في اليوم و60 تعليقًا في الساعة.');
    expect(errors.forError(error())).toBe('وصلت إلى الحد المسموح به: 5 مقالات في اليوم و60 تعليقًا في الساعة.');
  });
});

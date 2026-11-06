import { TestBed } from '@angular/core/testing';
import { ApiError } from '../../core/api/api.config';
import { ProblemDetails } from '../../core/api/models';
import { translocoTesting } from '../../../testing/transloco-testing';
import { CommentErrors, commentErrorKey } from './comment-errors';

function apiError(status: number, code: string, errors?: Record<string, string[]>): ApiError {
  const problem: ProblemDetails = { title: `title of ${code}`, status, code, ...(errors ? { errors } : {}) };
  return new ApiError(status, code, problem);
}

describe('commentErrorKey (F11 error codes)', () => {
  it('maps comment, pin and report codes to their translations', () => {
    expect(commentErrorKey(apiError(409, 'comment.duplicate'))).toBe('errors.comment.duplicate');
    expect(commentErrorKey(apiError(409, 'comment.not_available'))).toBe('errors.comment.not_available');
    expect(commentErrorKey(apiError(400, 'comment.empty'))).toBe('errors.comment.empty');
    expect(commentErrorKey(apiError(400, 'comment.too_long'))).toBe('errors.comment.too_long');
    expect(commentErrorKey(apiError(403, 'comment.not_owner'))).toBe('errors.comment.not_owner');
    expect(commentErrorKey(apiError(403, 'comment.pin_not_author'))).toBe('errors.comment.pin_not_author');
    expect(commentErrorKey(apiError(400, 'comment.pin_reply'))).toBe('errors.comment.pin_reply');
    expect(commentErrorKey(apiError(400, 'report.own_content'))).toBe('errors.report.own_content');
    expect(commentErrorKey(apiError(404, 'report.target_not_found'))).toBe('errors.report.target_not_found');
  });

  it('tells the 10-a-minute limit apart from the per-article flood limit', () => {
    expect(commentErrorKey(apiError(429, 'rate_limited'))).toBe('comments.errors.tooFast');
    expect(commentErrorKey(apiError(429, 'comment.article_limit'))).toBe('errors.comment.article_limit');
  });

  it('uses the first field code of a validation failure', () => {
    expect(commentErrorKey(apiError(400, 'validation.failed', { reason: ['report.reason_invalid'] }))).toBe('errors.report.reason_invalid');
    expect(commentErrorKey(apiError(400, 'validation.failed', { details: ['validation.max_length'] }))).toBe('errors.validation.failed');
  });

  it('falls back to the generic codes', () => {
    expect(commentErrorKey(apiError(0, 'network'))).toBe('errors.network');
    expect(commentErrorKey(apiError(403, 'auth.forbidden'))).toBe('errors.auth.forbidden');
    expect(commentErrorKey(new Error('boom'))).toBe('errors.unknown');
  });
});

describe('CommentErrors', () => {
  beforeEach(() => {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({ imports: [translocoTesting()] });
  });

  it('translates in the UI language and falls back to the API title for unknown codes', () => {
    const errors = TestBed.inject(CommentErrors);
    expect(errors.message(apiError(409, 'comment.duplicate'))).toBe('نشرت التعليق نفسه للتو.');
    expect(errors.message(apiError(429, 'rate_limited'))).toBe('أنت تعلّق بسرعة كبيرة. انتظر دقيقة ثم حاول مرة أخرى.');
    expect(errors.message(apiError(400, 'comment.something_new'))).toBe('title of comment.something_new');
    expect(errors.message(new Error('boom'))).toBe('حدث خطأ غير متوقع. حاول مرة أخرى.');
  });
});

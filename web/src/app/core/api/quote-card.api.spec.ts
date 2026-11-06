import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TimeoutError, firstValueFrom } from 'rxjs';
import { TEST_API, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ApiError, SILENT_ERRORS } from './api.config';
import { QUOTE_CARD_FALLBACK_FILE_NAME, QUOTE_CARD_TIMEOUT_MS, QuoteCardApi, QuoteCardRequest, quoteCardFileName } from './quote-card.api';

const ARABIC_NAME = 'readin-quote-الذكاء-الاصطناعي.png';
const disposition = (name: string) => `inline; filename="readin-quote.png"; filename*=UTF-8''${encodeURIComponent(name)}`;
const REQUEST: QuoteCardRequest = { language: 'ar-EG', blockId: 'p2', startOffset: 6, endOffset: 34, text: '@youssef_dev على الشرح 👨‍💻', theme: 'dark', format: 'landscape' };

describe('quoteCardFileName (F24: Content-Disposition → the file name)', () => {
  it('percent-decodes RFC 5987 filename*, so Arabic slugs work', () => {
    expect(quoteCardFileName(disposition(ARABIC_NAME))).toBe(ARABIC_NAME);
    expect(quoteCardFileName(disposition('readin-quote-clean-code.png'))).toBe('readin-quote-clean-code.png');
    expect(quoteCardFileName(`inline; FILENAME*="utf-8'en'readin-quote-x.PNG"`)).toBe('readin-quote-x.PNG');
  });

  it('falls back to readin-quote.png when filename* is missing, does not decode or is not a PNG name', () => {
    expect(QUOTE_CARD_FALLBACK_FILE_NAME).toBe('readin-quote.png');
    for (const header of [
      null,
      undefined,
      '',
      'inline',
      'inline; filename="readin-quote.png"',
      `inline; filename*=UTF-8''%E0%A4%A.png`, // broken percent-encoding
      `inline; filename*=ISO-8859-1''readin-quote-x.png`, // only UTF-8 is sent
      `inline; filename*=UTF-8''readin-quote-x.pdf`,
      `inline; filename*=UTF-8''.png`,
    ]) {
      expect(quoteCardFileName(header), String(header)).toBe(QUOTE_CARD_FALLBACK_FILE_NAME);
    }
  });

  it('never keeps a path or control characters', () => {
    expect(quoteCardFileName(disposition('../readin-quote-x.png'))).toBe('..readin-quote-x.png');
    expect(quoteCardFileName(disposition('a\\b\u0000-q.png'))).toBe('ab-q.png');
  });
});

describe('QuoteCardApi (F24)', () => {
  let http: HttpTestingController;
  let api: QuoteCardApi;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
    api = TestBed.inject(QuoteCardApi);
  });

  afterEach(() => http.verify());

  it('POST /articles/{id}/quote-card with all 7 fields, a blob back, silent; the name comes from the header', async () => {
    const result = firstValueFrom(api.card('a 1', REQUEST));
    const req = http.expectOne((r) => r.url === `${TEST_API}/articles/a%201/quote-card`);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual(REQUEST);
    expect(Object.keys(req.request.body as object)).toHaveLength(7);
    expect(req.request.responseType).toBe('blob');
    expect(req.request.context.get(SILENT_ERRORS)).toBe(true);
    req.flush(new Blob(['\x89PNG'], { type: 'image/png' }), { headers: { 'Content-Disposition': disposition(ARABIC_NAME) } });
    const image = await result;
    expect(image.fileName).toBe(ARABIC_NAME);
    expect(image.blob.type).toBe('image/png');
  });

  it('types an untyped body as a PNG, and uses the fallback name without the header', async () => {
    const result = firstValueFrom(api.card('a1', REQUEST));
    http.expectOne(`${TEST_API}/articles/a1/quote-card`).flush(new Blob(['\x89PNG']));
    const image = await result;
    expect(image.fileName).toBe('readin-quote.png');
    expect(image.blob.type).toBe('image/png');
  });

  it('turns the ProblemDetails blob of a failure into an ApiError with its code', async () => {
    const result = firstValueFrom(api.card('a1', REQUEST)).catch((e: unknown) => e);
    http
      .expectOne(`${TEST_API}/articles/a1/quote-card`)
      .flush(new Blob([JSON.stringify(problem(429, 'quote.limit'))], { type: 'application/problem+json' }), { status: 429, statusText: 'Too Many Requests' });
    const error = (await result) as ApiError;
    expect(error).toBeInstanceOf(ApiError);
    expect(error.status).toBe(429);
    expect(error.code).toBe('quote.limit');
  });

  it(`gives up after ${QUOTE_CARD_TIMEOUT_MS / 1000} s (at least the contract's 40 s) and cancels the call`, async () => {
    expect(QUOTE_CARD_TIMEOUT_MS).toBeGreaterThanOrEqual(40_000);
    vi.useFakeTimers();
    try {
      const result = firstValueFrom(api.card('a1', REQUEST)).catch((e: unknown) => e);
      const req = http.expectOne(`${TEST_API}/articles/a1/quote-card`);
      vi.advanceTimersByTime(QUOTE_CARD_TIMEOUT_MS + 1);
      expect(await result).toBeInstanceOf(TimeoutError);
      expect(req.cancelled).toBe(true);
    } finally {
      vi.useRealTimers();
    }
  });
});

import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { firstValueFrom } from 'rxjs';
import { TEST_API, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ApiError, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { ArticlePdfApi, ArticlePdfFile, PDF_FALLBACK_FILE_NAME, pdfFileName } from './article-pdf.api';

const ARABIC_NAME = 'الذكاء-الاصطناعي-ar-EG.pdf';
const disposition = (name: string) => `attachment; filename="readin-article.pdf"; filename*=UTF-8''${encodeURIComponent(name)}`;

describe('pdfFileName (F33: Content-Disposition → the file name)', () => {
  it('percent-decodes RFC 5987 filename*, so Arabic slugs work', () => {
    expect(pdfFileName(disposition(ARABIC_NAME))).toBe(ARABIC_NAME);
    expect(pdfFileName(disposition('clean-code-en.pdf'))).toBe('clean-code-en.pdf');
  });

  it('reads filename* wherever it is, in any case, quoted or not', () => {
    expect(pdfFileName(`attachment; FILENAME*=utf-8''clean-code-en.pdf; filename="readin-article.pdf"`)).toBe('clean-code-en.pdf');
    expect(pdfFileName(`attachment;filename*="UTF-8'ar'%D9%85%D9%82%D8%A7%D9%84-ar-EG.pdf"`)).toBe('مقال-ar-EG.pdf');
  });

  it('falls back to readin-article.pdf when filename* is missing or does not decode', () => {
    expect(PDF_FALLBACK_FILE_NAME).toBe('readin-article.pdf');
    for (const header of [
      null,
      undefined,
      '',
      'attachment',
      'attachment; filename="readin-article.pdf"',
      `attachment; filename*=UTF-8''%E0%A4%A.pdf`, // broken percent-encoding
      `attachment; filename*=ISO-8859-1''clean-code-en.pdf`, // only UTF-8 is sent
      `attachment; filename*=clean-code-en.pdf`, // no charset part
      `attachment; filename*=UTF-8''`,
    ]) {
      expect(pdfFileName(header), String(header)).toBe(PDF_FALLBACK_FILE_NAME);
    }
  });

  it('never keeps a path or control characters', () => {
    expect(pdfFileName(disposition('../../etc/clean-code-en.pdf'))).toBe('....etcclean-code-en.pdf');
    expect(pdfFileName(disposition('a\\b\u0000\u001f-en.pdf'))).toBe('ab-en.pdf');
    expect(pdfFileName(disposition('/'))).toBe(PDF_FALLBACK_FILE_NAME);
  });
});

describe('ArticlePdfApi (F33)', () => {
  let http: HttpTestingController;
  let api: ArticlePdfApi;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
    api = TestBed.inject(ArticlePdfApi);
  });

  afterEach(() => http.verify());

  it('GET /articles/{id}/pdf?lang= as a blob, silent and with the session; the name comes from the header', async () => {
    const result = firstValueFrom(api.pdf('a 1', 'ar-EG'));
    const req = http.expectOne((r) => r.url === `${TEST_API}/articles/a%201/pdf`);
    expect(req.request.method).toBe('GET');
    expect(req.request.params.get('lang')).toBe('ar-EG');
    expect(req.request.responseType).toBe('blob');
    expect(req.request.context.get(SILENT_ERRORS)).toBe(true);
    expect(req.request.context.get(WITH_SESSION)).toBe(true);
    req.flush(new Blob(['%PDF-1.4'], { type: 'application/pdf' }), { headers: { 'Content-Disposition': disposition(ARABIC_NAME) } });
    const file: ArticlePdfFile = await result;
    expect(file.fileName).toBe(ARABIC_NAME);
    expect(file.blob.type).toBe('application/pdf');
    expect(await file.blob.text()).toBe('%PDF-1.4');
  });

  it('types an untyped body as a PDF, and uses the fallback name without the header', async () => {
    const result = firstValueFrom(api.pdf('a1', 'en'));
    http.expectOne((r) => r.url === `${TEST_API}/articles/a1/pdf`).flush(new Blob(['%PDF-1.4']));
    const file = await result;
    expect(file.fileName).toBe('readin-article.pdf');
    expect(file.blob.type).toBe('application/pdf');
  });

  it('turns the ProblemDetails blob of a failure into an ApiError with its code', async () => {
    const result = firstValueFrom(api.pdf('a1', 'en')).catch((e: unknown) => e);
    http
      .expectOne((r) => r.url === `${TEST_API}/articles/a1/pdf`)
      .flush(new Blob([JSON.stringify(problem(409, 'article.pdf_hidden'))], { type: 'application/problem+json' }), { status: 409, statusText: 'Conflict' });
    const error = (await result) as ApiError;
    expect(error).toBeInstanceOf(ApiError);
    expect(error.status).toBe(409);
    expect(error.code).toBe('article.pdf_hidden');
  });
});

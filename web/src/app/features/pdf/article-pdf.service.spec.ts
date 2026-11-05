import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { TranslocoService } from '@jsverse/transloco';
import { TimeoutError } from 'rxjs';
import ar from '../../../../public/i18n/ar.json';
import en from '../../../../public/i18n/en.json';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ApiError } from '../../core/api/api.config';
import { MyArticleDto } from '../../core/api/models';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { ArticlePdfService, pdfLanguages } from './article-pdf.service';

const URL_OF = (id: string) => `${TEST_API}/articles/${id}/pdf`;

/** The contract's wording (docs/api/contract-v1.md → Article PDF → Errors), as mobile has it. */
const CONTRACT_TEXTS: Record<string, [string, string]> = {
  'errors.article.pdf_hidden': ['المشرفين خفّوا المقال ده، فمينفعش يتحمّل PDF.', "Moderators hid this article, so it can't be downloaded as a PDF."],
  'errors.article.pdf_limit': ['حمّلت PDFs كتير الساعة دي. حاول تاني بعد شوية.', "You've downloaded many PDFs this hour. Try again later."],
  'errors.article.pdf_busy': ['فيه PDFs كتير بتتجهز دلوقتي. حاول تاني كمان شوية.', 'Many PDFs are being prepared right now. Try again in a moment.'],
  'errors.article.pdf_failed': ['معرفناش نجهّز الـ PDF. حاول تاني.', "We couldn't prepare the PDF. Try again."],
  'pdf.offline': ['محتاج إنترنت عشان تحمّل الـ PDF.', 'You need an internet connection to download the PDF.'],
  'pdf.building': ['بنجهز الـ PDF…', 'Preparing the PDF…'],
  'pdf.download': ['تحميل PDF', 'Download PDF'],
  'pdf.retry': ['حاول تاني', 'Try again'],
  'pdf.chooseTitle': ['أنهي نسخة؟', 'Which version?'],
  // One wording per string on web and mobile (mobile: errArticlePdfNotFound, pdfLanguageBody, articleVersionArabic/English).
  'pdf.notFound': ['المقال مش موجود.', 'Article not found.'],
  'pdf.chooseBody': ['المقال ده منشور بلغتين. اختار النسخة اللي عايز تحمّلها PDF.', 'This article is published in two languages. Choose the version to download as a PDF.'],
  'pdf.languages.arEG': ['العربي', 'Arabic'],
  'pdf.languages.en': ['الإنجليزي', 'English'],
};

function lookup(source: unknown, key: string): unknown {
  return key.split('.').reduce<unknown>((node, part) => (node && typeof node === 'object' ? (node as Record<string, unknown>)[part] : undefined), source);
}

describe('Article PDF texts (F33)', () => {
  it('read like the contract in both languages', () => {
    for (const [key, [arabic, english]] of Object.entries(CONTRACT_TEXTS)) {
      expect(lookup(ar, key), key).toBe(arabic);
      expect(lookup(en, key), key).toBe(english);
    }
  });
});

describe('pdfLanguages (My articles → Published)', () => {
  const mine = (patch: Partial<MyArticleDto>) =>
    ({ id: 'a1', status: 'published', language: 'ar-EG', ...patch }) as MyArticleDto;

  it('offers the published versions, source language first', () => {
    expect(pdfLanguages(mine({ publishedLanguages: ['ar-EG', 'en'] }))).toEqual(['ar-EG', 'en']);
    expect(pdfLanguages(mine({ language: 'en', publishedLanguages: ['en'] }))).toEqual(['en']);
  });

  it('falls back to the source language when the API is older than F33', () => {
    expect(pdfLanguages(mine({}))).toEqual(['ar-EG']);
    expect(pdfLanguages(mine({ language: 'en', publishedLanguages: [] }))).toEqual(['en']);
  });
});

describe('ArticlePdfService (F33)', () => {
  let http: HttpTestingController;
  let toasts: ToastService;
  let pdf: ArticlePdfService;
  let clicks: { href: string; download: string }[];
  const created: string[] = [];
  const revoked: string[] = [];

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http, toasts } = setupSocialTesting());
    pdf = TestBed.inject(ArticlePdfService);
    clicks = [];
    created.length = 0;
    revoked.length = 0;
    URL.createObjectURL = vi.fn(() => {
      const url = `blob:http://localhost/pdf-${created.length + 1}`;
      created.push(url);
      return url;
    });
    URL.revokeObjectURL = vi.fn((url: string) => void revoked.push(url));
    vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(function (this: HTMLAnchorElement) {
      clicks.push({ href: this.href, download: this.download });
    });
  });

  afterEach(() => {
    http.verify();
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  const expectPdf = (id = 'a1') => http.expectOne((r) => r.url === URL_OF(id));
  const fail = (req: TestRequest, status: number, code: string) =>
    req.flush(new Blob([JSON.stringify(problem(status, code))], { type: 'application/problem+json' }), { status, statusText: 'Error' });
  const lastToast = () => toasts.toasts().at(-1);

  it('downloads the file under the server name: object URL on <a download>, clicked, then revoked', async () => {
    vi.useFakeTimers();
    const done = pdf.download('a1', 'en');
    const req = expectPdf();
    expect(req.request.params.get('lang')).toBe('en');
    req.flush(new Blob(['%PDF-1.4'], { type: 'application/pdf' }), {
      headers: { 'Content-Disposition': `attachment; filename="readin-article.pdf"; filename*=UTF-8''${encodeURIComponent('الذكاء-الاصطناعي-ar-EG.pdf')}` },
    });
    expect(await done).toBe(true);
    expect(clicks).toEqual([{ href: 'blob:http://localhost/pdf-1', download: 'الذكاء-الاصطناعي-ar-EG.pdf' }]);
    expect(document.querySelector('a[download]')).toBeNull(); // the link is gone again
    expect(revoked).toEqual([]);
    vi.advanceTimersByTime(10_000);
    expect(revoked).toEqual(['blob:http://localhost/pdf-1']);
    expect(toasts.toasts()).toEqual([]);
  });

  it('is building while the request runs; another download of that article does nothing', async () => {
    expect(pdf.isBuilding('a1')).toBe(false);
    const first = pdf.download('a1', 'en');
    expect(pdf.isBuilding('a1')).toBe(true);
    expect(pdf.isBuilding('a2')).toBe(false);
    expect(await pdf.download('a1', 'ar-EG')).toBe(false);
    const req = expectPdf(); // only one request
    req.flush(new Blob(['%PDF-1.4'], { type: 'application/pdf' }));
    expect(await first).toBe(true);
    expect(pdf.isBuilding('a1')).toBe(false);
    expect(clicks.map((c) => c.download)).toEqual(['readin-article.pdf']);
  });

  it('builds two different articles at the same time', async () => {
    const one = pdf.download('a1', 'en');
    const two = pdf.download('a2', 'ar-EG');
    expect(pdf.isBuilding('a1') && pdf.isBuilding('a2')).toBe(true);
    expectPdf('a2').flush(new Blob(['%PDF']));
    expectPdf('a1').flush(new Blob(['%PDF']));
    expect(await Promise.all([one, two])).toEqual([true, true]);
  });

  const cases: { code: string; status: number; message: string; retry: boolean }[] = [
    { code: 'article.not_found', status: 404, message: 'المقال مش موجود.', retry: false },
    { code: 'article.pdf_hidden', status: 409, message: 'المشرفين خفّوا المقال ده، فمينفعش يتحمّل PDF.', retry: false },
    { code: 'article.pdf_limit', status: 429, message: 'حمّلت PDFs كتير الساعة دي. حاول تاني بعد شوية.', retry: true },
    { code: 'article.pdf_busy', status: 503, message: 'فيه PDFs كتير بتتجهز دلوقتي. حاول تاني كمان شوية.', retry: true },
    { code: 'article.pdf_failed', status: 500, message: 'معرفناش نجهّز الـ PDF. حاول تاني.', retry: true },
    { code: 'server.error', status: 500, message: 'معرفناش نجهّز الـ PDF. حاول تاني.', retry: true },
    { code: 'something.new', status: 400, message: 'معرفناش نجهّز الـ PDF. حاول تاني.', retry: true },
    // Another limiter's 429 keeps its usual message, as on mobile.
    { code: 'rate_limited', status: 429, message: 'طلبات كتير، استنى شوية وجرّب تاني.', retry: false },
  ];
  for (const { code, status, message, retry } of cases) {
    it(`${status} ${code} → "${message}"${retry ? ' with حاول تاني' : ', no retry'}`, async () => {
      const done = pdf.download('a1', 'ar-EG');
      fail(expectPdf(), status, code);
      expect(await done).toBe(false);
      expect(pdf.isBuilding('a1')).toBe(false);
      expect(lastToast()?.kind).toBe('error');
      expect(lastToast()?.message).toBe(message);
      expect(lastToast()?.action?.label ?? null).toBe(retry ? 'حاول تاني' : null);
      expect(clicks).toEqual([]);
    });
  }

  it('a failure without a body (e.g. a proxy 502) is a failed build', async () => {
    const done = pdf.download('a1', 'en');
    expectPdf().flush(new Blob(['<html>Bad gateway</html>'], { type: 'text/html' }), { status: 502, statusText: 'Bad Gateway' });
    await done;
    expect(lastToast()?.message).toBe('معرفناش نجهّز الـ PDF. حاول تاني.');
    expect(lastToast()?.action?.label).toBe('حاول تاني');
  });

  it('other known codes keep their usual message (e.g. a suspended account), no retry', async () => {
    const done = pdf.download('a1', 'en');
    fail(expectPdf(), 403, 'user.suspended');
    await done;
    expect(lastToast()?.message).toBe(TestBed.inject(TranslocoService).translate('errors.user.suspended'));
    expect(lastToast()?.action).toBeNull();
  });

  it('"حاول تاني" asks again for the same article and language', async () => {
    const done = pdf.download('a1', 'ar-EG');
    fail(expectPdf(), 503, 'article.pdf_busy');
    await done;
    lastToast()!.action!.run();
    expect(pdf.isBuilding('a1')).toBe(true);
    const again = expectPdf();
    expect(again.request.params.get('lang')).toBe('ar-EG');
    again.flush(new Blob(['%PDF']));
    await flushMicrotasks();
    expect(pdf.isBuilding('a1')).toBe(false);
    expect(clicks).toHaveLength(1);
  });

  it('no connection during the call → "محتاج إنترنت…" with retry', async () => {
    const done = pdf.download('a1', 'en');
    expectPdf().error(new ProgressEvent('error'));
    await done;
    expect(lastToast()?.message).toBe('محتاج إنترنت عشان تحمّل الـ PDF.');
    expect(lastToast()?.action?.label).toBe('حاول تاني');
  });

  it('offline before the call → the same message, and no request', async () => {
    vi.spyOn(navigator, 'onLine', 'get').mockReturnValue(false);
    expect(await pdf.download('a1', 'en')).toBe(false);
    http.expectNone(() => true);
    expect(pdf.isBuilding('a1')).toBe(false);
    expect(lastToast()?.message).toBe('محتاج إنترنت عشان تحمّل الـ PDF.');
    expect(lastToast()?.action?.label).toBe('حاول تاني');
  });

  it('a client timeout counts as a failed build', () => {
    expect(pdf.failureOf(new TimeoutError())).toEqual({ message: 'معرفناش نجهّز الـ PDF. حاول تاني.', retry: true });
    expect(pdf.failureOf(new Error('boom'))).toEqual({ message: 'معرفناش نجهّز الـ PDF. حاول تاني.', retry: true });
    expect(pdf.failureOf(new ApiError(0, 'network', null))).toEqual({ message: 'محتاج إنترنت عشان تحمّل الـ PDF.', retry: true });
  });

  it('gives up after 120 s (the API may take 30 s + 60 s) and cancels the request', async () => {
    vi.useFakeTimers();
    const done = pdf.download('a1', 'en');
    const req = expectPdf();
    vi.advanceTimersByTime(100_000);
    expect(req.cancelled).toBe(false);
    vi.advanceTimersByTime(20_000);
    expect(await done).toBe(false);
    expect(req.cancelled).toBe(true);
    expect(lastToast()?.message).toBe('معرفناش نجهّز الـ PDF. حاول تاني.');
  });

  it('speaks English in the English UI', async () => {
    TestBed.inject(TranslocoService).setActiveLang('en');
    const done = pdf.download('a1', 'en');
    fail(expectPdf(), 429, 'article.pdf_limit');
    await done;
    expect(lastToast()?.message).toBe("You've downloaded many PDFs this hour. Try again later.");
    expect(lastToast()?.action?.label).toBe('Try again');
  });
});

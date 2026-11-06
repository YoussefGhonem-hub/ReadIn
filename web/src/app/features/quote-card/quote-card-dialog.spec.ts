import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import ar from '../../../../public/i18n/ar.json';
import { TEST_API, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ThemeService } from '../../core/theme/theme.service';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { QuoteCardSource } from './quote-card';
import { QuoteCardDialog } from './quote-card-dialog';

const URL_OF = `${TEST_API}/articles/a1/quote-card`;
const ARTICLE_URL = 'https://readin.app/ar/a/clean-architecture';
const SOURCE: QuoteCardSource = {
  article: { id: 'a1', language: 'ar-EG', url: ARTICLE_URL },
  range: { blockId: 'p2', startOffset: 6, endOffset: 34, text: '@youssef_dev على الشرح 👨‍💻' },
};
const PNG = () => new Blob([new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])], { type: 'image/png' });
const NAME = 'readin-quote-clean-architecture.png';
const DISPOSITION = `inline; filename="readin-quote.png"; filename*=UTF-8''${NAME}`;

describe('Quote card dialog (F24)', () => {
  let http: HttpTestingController;
  let toasts: ToastService;
  let fixture: ComponentFixture<QuoteCardDialog>;
  let root: HTMLElement;
  let dismissed: number;
  let textChanges: number;
  let clicks: { href: string; download: string }[];
  let created: string[];
  let revoked: string[];
  const navigatorBackup: Record<string, PropertyDescriptor | undefined> = {};

  /** Replaces a `navigator` member for one test (restored after each). */
  function stubNavigator(name: 'share' | 'canShare' | 'clipboard' | 'onLine', value: unknown): void {
    if (!(name in navigatorBackup)) navigatorBackup[name] = Object.getOwnPropertyDescriptor(navigator, name);
    Object.defineProperty(navigator, name, { value, configurable: true, writable: true });
  }

  async function render(options: { theme?: 'light' | 'dark'; source?: QuoteCardSource } = {}) {
    TestBed.resetTestingModule();
    ({ http, toasts } = setupSocialTesting({ guest: true }));
    TestBed.inject(ThemeService).setPreference(options.theme ?? 'light');
    dismissed = 0;
    textChanges = 0;
    fixture = TestBed.createComponent(QuoteCardDialog);
    fixture.componentRef.setInput('dismiss', () => dismissed++);
    fixture.componentRef.setInput('textChanged', () => textChanges++);
    fixture.componentRef.setInput('source', options.source ?? SOURCE);
    await stable();
    root = fixture.nativeElement as HTMLElement;
  }

  async function stable(): Promise<void> {
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
  }

  const expectCard = () => http.expectOne((r) => r.url === URL_OF && r.method === 'POST');
  const flushCard = async (req: TestRequest) => {
    req.flush(PNG(), { headers: { 'Content-Disposition': DISPOSITION } });
    await stable();
  };
  const fail = async (req: TestRequest, status: number, code: string) => {
    req.flush(new Blob([JSON.stringify(problem(status, code))], { type: 'application/problem+json' }), { status, statusText: 'Error' });
    // The ProblemDetails blob is read asynchronously.
    await vi.waitFor(() => {
      fixture.detectChanges();
      expect(preview().getAttribute('data-state')).toBe('error');
    });
  };
  const preview = () => root.querySelector<HTMLElement>('[data-quote-preview]')!;
  const button = (name: string) => root.querySelector<HTMLButtonElement>(`[data-quote-${name}]`)!;
  const radio = (group: 'theme' | 'format', index: number) => root.querySelectorAll<HTMLButtonElement>(`[data-quote-${group}] [role="radio"]`)[index];
  const choose = async (group: 'theme' | 'format', index: number) => {
    radio(group, index).click();
    await stable();
  };

  beforeEach(() => {
    clicks = [];
    created = [];
    revoked = [];
    URL.createObjectURL = vi.fn(() => {
      const url = `blob:http://localhost/quote-${created.length + 1}`;
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
    for (const [name, descriptor] of Object.entries(navigatorBackup)) {
      if (descriptor) Object.defineProperty(navigator, name, descriptor);
      else delete (navigator as unknown as Record<string, unknown>)[name];
      delete navigatorBackup[name];
    }
  });

  it('asks for the selection in the app theme, square, and shows a box of the card shape while it loads', async () => {
    await render({ theme: 'dark' });
    const req = expectCard();
    expect(req.request.body).toEqual({ language: 'ar-EG', blockId: 'p2', startOffset: 6, endOffset: 34, text: '@youssef_dev على الشرح 👨‍💻', theme: 'dark', format: 'square' });
    expect(root.querySelector('#rd-quote-card-title')!.textContent!.trim()).toBe('مشاركة اقتباس');
    expect(root.querySelector('#rd-quote-card-hint')!.textContent!.trim()).toBe('صورة للجزء الذي حدّدته لمواقع التواصل الاجتماعي، مع رابط المقال.');
    expect(root.querySelector('[role="dialog"]')!.getAttribute('aria-labelledby')).toBe('rd-quote-card-title');
    expect(root.querySelector('[role="dialog"]')!.getAttribute('aria-describedby')).toBe('rd-quote-card-hint');
    expect(preview().getAttribute('data-state')).toBe('loading');
    expect(preview().getAttribute('aria-busy')).toBe('true');
    expect(preview().style.aspectRatio).toBe('1080 / 1080');
    expect(root.querySelector('[data-quote-loading]')!.textContent!.trim()).toBe('جارٍ تجهيز البطاقة…');
    expect(root.querySelector('[data-quote-status]')!.textContent).toBe('جارٍ تجهيز البطاقة…');
    // The app's own words for its themes (Settings), and the card's sizes.
    expect([...root.querySelectorAll('[data-quote-theme] [role="radio"]')].map((r) => r.textContent!.trim())).toEqual([ar.settings.theme.light, ar.settings.theme.dark]);
    expect([...root.querySelectorAll('[data-quote-format] [role="radio"]')].map((r) => r.textContent!.trim())).toEqual(['مربع', 'أفقي']);
    expect(button('share').disabled).toBe(true);
    expect(button('download').disabled).toBe(true);
    expect(button('copy-link').disabled).toBe(false);
    expect(radio('theme', 1).getAttribute('aria-checked')).toBe('true');
    expect(radio('format', 0).getAttribute('aria-checked')).toBe('true');

    await flushCard(req);
    const image = root.querySelector<HTMLImageElement>('[data-quote-image]')!;
    expect(image.getAttribute('src')).toBe('blob:http://localhost/quote-1');
    expect(image.getAttribute('alt')).toBe('بطاقة اقتباس: @youssef_dev على الشرح 👨‍💻');
    expect([image.getAttribute('width'), image.getAttribute('height')]).toEqual(['1080', '1080']);
    expect(preview().getAttribute('data-state')).toBe('ready');
    expect(root.querySelector('[data-quote-status]')!.textContent).toBe('البطاقة جاهزة.');
    expect(button('share').disabled).toBe(false);
  });

  it('switching theme or format asks for that card once; switching back shows the one already drawn', async () => {
    await render();
    await flushCard(expectCard());

    await choose('format', 1);
    const landscape = expectCard();
    expect(landscape.request.body).toMatchObject({ theme: 'light', format: 'landscape' });
    expect(preview().style.aspectRatio).toBe('1200 / 630');
    expect(preview().getAttribute('data-state')).toBe('loading');
    await flushCard(landscape);

    await choose('theme', 1);
    const dark = expectCard();
    expect(dark.request.body).toMatchObject({ theme: 'dark', format: 'landscape' });
    await flushCard(dark);

    await choose('theme', 0);
    await choose('format', 0);
    http.expectNone(URL_OF);
    expect(root.querySelector('[data-quote-image]')!.getAttribute('src')).toBe('blob:http://localhost/quote-1');
    expect(preview().getAttribute('data-state')).toBe('ready');
  });

  it('a slow card keeps loading in the background while another is shown', async () => {
    await render();
    const square = expectCard();
    await choose('format', 1);
    const landscape = expectCard();
    await flushCard(landscape);
    expect(preview().getAttribute('data-state')).toBe('ready');
    await flushCard(square);
    await choose('format', 0);
    expect(root.querySelector('[data-quote-image]')!.getAttribute('src')).toBe('blob:http://localhost/quote-2');
  });

  it('Download saves the card on screen under the server name, with no new call', async () => {
    await render();
    await flushCard(expectCard());
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    try {
      button('download').click();
      expect(clicks).toEqual([{ href: 'blob:http://localhost/quote-2', download: NAME }]);
      expect(document.querySelector('a[download]')).toBeNull();
      vi.advanceTimersByTime(10_000);
      expect(revoked).toEqual(['blob:http://localhost/quote-2']);
      http.expectNone(URL_OF);
    } finally {
      vi.useRealTimers();
    }
  });

  it('Share hands the PNG and the link to the Web Share API when the browser can share files', async () => {
    const share = vi.fn(() => Promise.resolve());
    const canShare = vi.fn(() => true);
    stubNavigator('share', share);
    stubNavigator('canShare', canShare);
    await render();
    await flushCard(expectCard());
    button('share').click();
    await stable();
    const data = (share.mock.calls[0] as unknown as [ShareData])[0];
    expect(data.text).toBe(ARTICLE_URL);
    expect(data.files).toHaveLength(1);
    expect(data.files![0].name).toBe(NAME);
    expect(data.files![0].type).toBe('image/png');
    expect((canShare.mock.calls[0] as unknown as [ShareData])[0].files![0]).toBe(data.files![0]);
    expect(clicks).toEqual([]);
  });

  it('Share downloads the card when files can not be shared, or the share is refused; a dismissed share does nothing', async () => {
    stubNavigator('share', undefined);
    await render();
    await flushCard(expectCard());
    button('share').click();
    expect(clicks.map((c) => c.download)).toEqual([NAME]);

    stubNavigator('share', vi.fn(() => Promise.resolve()));
    stubNavigator('canShare', vi.fn(() => false));
    button('share').click();
    expect(clicks).toHaveLength(2);

    stubNavigator('canShare', vi.fn(() => true));
    stubNavigator('share', vi.fn(() => Promise.reject(new DOMException('cancelled', 'AbortError'))));
    button('share').click();
    await stable();
    expect(clicks).toHaveLength(2);

    stubNavigator('share', vi.fn(() => Promise.reject(new DOMException('policy', 'NotAllowedError'))));
    button('share').click();
    await stable();
    expect(clicks).toHaveLength(3);
  });

  it('Copy link copies the article link (and says so), or says it could not', async () => {
    const writeText = vi.fn(() => Promise.resolve());
    stubNavigator('clipboard', { writeText });
    await render();
    const req = expectCard();
    button('copy-link').click();
    await stable();
    expect(writeText).toHaveBeenCalledWith(ARTICLE_URL);
    expect(toasts.toasts().at(-1)).toMatchObject({ kind: 'success', message: ar.common.linkCopied });

    stubNavigator('clipboard', { writeText: () => Promise.reject(new Error('blocked')) });
    button('copy-link').click();
    await stable();
    expect(toasts.toasts().at(-1)).toMatchObject({ kind: 'error', message: 'تعذّر نسخ الرابط.' });
    await flushCard(req);
  });

  const cases: { status: number; code: string; message: string; retry: boolean }[] = [
    { status: 404, code: 'article.not_found', message: 'المقال غير موجود.', retry: false },
    { status: 409, code: 'quote.hidden', message: 'أخفى المشرفون هذا المقال، لذا لا يمكن مشاركة اقتباس منه.', retry: false },
    { status: 400, code: 'quote.text_mismatch', message: 'تغيّر هذا النص في المقال. حدّث الصفحة وحاول مرة أخرى.', retry: false },
    { status: 400, code: 'quote.block_not_allowed', message: 'لا يمكن مشاركة هذا الجزء كاقتباس.', retry: false },
    { status: 400, code: 'quote.too_short', message: 'حدّد 3 أحرف على الأقل.', retry: false },
    { status: 400, code: 'quote.too_long', message: 'يجب ألا يتجاوز الاقتباس 400 حرف. حدّد جزءًا أقصر.', retry: false },
    // A client bug: the app's generic message.
    { status: 400, code: 'validation.failed', message: ar.errors.unknown, retry: false },
    { status: 429, code: 'quote.limit', message: 'أنشأت بطاقات اقتباس كثيرة خلال هذه الساعة. حاول مرة أخرى لاحقًا.', retry: true },
    { status: 503, code: 'quote.busy', message: 'يجري الآن تجهيز بطاقات كثيرة. حاول مرة أخرى بعد قليل.', retry: true },
    { status: 500, code: 'quote.failed', message: 'تعذّر تجهيز بطاقة الاقتباس. حاول مرة أخرى.', retry: true },
    { status: 500, code: 'server.error', message: 'تعذّر تجهيز بطاقة الاقتباس. حاول مرة أخرى.', retry: true },
    { status: 418, code: 'teapot.unknown', message: 'تعذّر تجهيز بطاقة الاقتباس. حاول مرة أخرى.', retry: true },
  ];
  for (const c of cases) {
    it(`${c.status} ${c.code}: "${c.message}"${c.retry ? ', with Try again' : ''}`, async () => {
      await render();
      await fail(expectCard(), c.status, c.code);
      expect(preview().getAttribute('data-state')).toBe('error');
      const error = root.querySelector('[data-quote-error] [role="alert"]')!;
      expect(error.textContent!.trim()).toBe(c.message);
      expect(!!root.querySelector('[data-quote-retry]')).toBe(c.retry);
      expect(button('share').disabled).toBe(true);
      if (c.retry) expect(button('retry').textContent!.trim()).toBe('إعادة المحاولة');
      // Only a changed text has the reader load the article again.
      expect(textChanges).toBe(c.code === 'quote.text_mismatch' ? 1 : 0);
    });
  }

  it('Try again asks for the card on screen again', async () => {
    await render();
    await fail(expectCard(), 503, 'quote.busy');
    button('retry').click();
    await stable();
    expect(preview().getAttribute('data-state')).toBe('loading');
    await flushCard(expectCard());
    expect(preview().getAttribute('data-state')).toBe('ready');
  });

  it('offline: says the internet is needed without calling; Try again once it is back', async () => {
    stubNavigator('onLine', false);
    await render();
    http.expectNone(URL_OF);
    expect(root.querySelector('[data-quote-error] [role="alert"]')!.textContent!.trim()).toBe('تحتاج إلى اتصال بالإنترنت لإنشاء بطاقة اقتباس.');
    button('retry').click();
    await stable();
    http.expectNone(URL_OF);
    stubNavigator('onLine', true);
    button('retry').click();
    await stable();
    await flushCard(expectCard());
    expect(preview().getAttribute('data-state')).toBe('ready');
  });

  it('a connection lost during the call says the internet is needed, with Try again', async () => {
    await render();
    expectCard().error(new ProgressEvent('error'), { status: 0, statusText: 'Unknown Error' });
    await stable();
    expect(root.querySelector('[data-quote-error] [role="alert"]')!.textContent!.trim()).toBe('تحتاج إلى اتصال بالإنترنت لإنشاء بطاقة اقتباس.');
    expect(root.querySelector('[data-quote-retry]')).not.toBeNull();
  });

  it('closing cancels what is loading and frees the pictures; the next quote starts over in the app theme, square', async () => {
    await render();
    await flushCard(expectCard());
    await choose('format', 1);
    await choose('theme', 1);
    const pending = http.match((r) => r.url === URL_OF);
    expect(pending.map((r) => r.request.body.theme + '|' + r.request.body.format)).toEqual(['light|landscape', 'dark|landscape']);

    root.querySelector<HTMLButtonElement>('[role="dialog"] button[aria-label="إغلاق"]')!.click();
    expect(dismissed).toBe(1);
    fixture.componentRef.setInput('source', null);
    await stable();
    expect(pending.every((r) => r.cancelled)).toBe(true);
    expect(revoked).toEqual(['blob:http://localhost/quote-1']);
    expect(root.querySelector('[role="dialog"]')).toBeNull();

    fixture.componentRef.setInput('source', { ...SOURCE, range: { ...SOURCE.range } });
    await stable();
    expect(expectCard().request.body).toMatchObject({ theme: 'light', format: 'square' });
    expect(radio('format', 0).getAttribute('aria-checked')).toBe('true');
  });
});

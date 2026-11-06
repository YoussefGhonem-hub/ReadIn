import { ChangeDetectionStrategy, Component, ElementRef, Type, computed, inject, signal, viewChild } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import fixtures from '../../../../../shared/rdoc/highlight-fixtures.json';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ArticleHighlightsDto } from '../../core/api/highlights.api';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { HighlighterService } from '../../shared/rdoc/highlighter.service';
import { RDocRenderer } from '../../shared/rdoc/rdoc-renderer';
import { RDoc } from '../../shared/rdoc/rdoc.models';
import { domRangeOf } from '../../shared/rdoc/selection-offsets';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { QuoteCardArticle } from '../quote-card/quote-card';
import { ArticleHighlightsStore } from './article-highlights.store';
import { ReaderHighlights } from './reader-highlights';

const DOC = (fixtures as unknown as { documents: { ar: RDoc } }).documents.ar;
const URL = `${TEST_API}/articles/a1/highlights`;
const PERMISSIONS = ['articles.read', 'highlights.create'];
/** The fixtures' Arabic document and a paragraph longer than a quote may be (450 characters). */
const LONG_TEXT = 'جملة طويلة عن الـ Clean Architecture. '.repeat(12).slice(0, 450);
const QUOTE_DOC: RDoc = { ...DOC, blocks: [...DOC.blocks, { id: 'long1', type: 'paragraph', content: [{ type: 'text', text: LONG_TEXT }] } as RDoc['blocks'][number]] };
const QUOTE_ARTICLE: QuoteCardArticle = { id: 'a1', language: 'ar-EG', url: 'https://readin.app/ar/a/highlights-lab' };

/** The reader's article and its highlights layer, as the article page puts them together. */
@Component({
  imports: [RDocRenderer, ReaderHighlights],
  providers: [ArticleHighlightsStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<rd-rdoc [doc]="doc" [marks]="store.marks()" /><rd-reader-highlights [content]="content()" />`,
})
class ReaderHost {
  protected readonly store = inject(ArticleHighlightsStore);
  protected readonly doc = DOC;
  private readonly rdoc = viewChild(RDocRenderer, { read: ElementRef });
  protected readonly content = computed(() => (this.rdoc()?.nativeElement as HTMLElement | undefined) ?? null);

  constructor() {
    this.store.connect(signal({ id: 'a1', language: 'ar-EG' as const, content: DOC }), () => undefined);
  }
}

/** The same, with an article to share quotes from (F24), as the article page gives it unless the article is hidden. */
@Component({
  imports: [RDocRenderer, ReaderHighlights],
  providers: [ArticleHighlightsStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<rd-rdoc [doc]="doc" [marks]="store.marks()" /><rd-reader-highlights [content]="content()" [quoteArticle]="quote()" />`,
})
class QuoteReaderHost {
  protected readonly store = inject(ArticleHighlightsStore);
  protected readonly doc = QUOTE_DOC;
  readonly quote = signal<QuoteCardArticle | null>(QUOTE_ARTICLE);
  /** How many times the page was asked to load the article again (a text_mismatch). */
  articleReloads = 0;
  private readonly rdoc = viewChild(RDocRenderer, { read: ElementRef });
  protected readonly content = computed(() => (this.rdoc()?.nativeElement as HTMLElement | undefined) ?? null);

  constructor() {
    this.store.connect(signal({ id: 'a1', language: 'ar-EG' as const, content: QUOTE_DOC }), () => this.articleReloads++);
  }
}

const ANSWER: ArticleHighlightsDto = {
  articleId: 'a1',
  language: 'ar-EG',
  mine: [{ id: 'h-p3', blockId: 'p3', startOffset: 16, endOffset: 27, text: 'مُهِمّ جداً', createdAt: '2026-11-05T10:00:00Z' }],
  popular: [{ blockId: 'p1', startOffset: 15, endOffset: 62, text: 'ASP.NET Core، أكيد شفت الـ Dependency Injection', count: 12 }],
};

async function render(options: { guest?: boolean; permissions?: string[]; quotes?: boolean } = {}) {
  localStorage.removeItem('rd.highlights.hidden');
  const { http, session } = setupSocialTesting({
    guest: options.guest,
    providers: [{ provide: HighlighterService, useValue: { highlight: () => Promise.resolve(null) } }],
  });
  if (!options.guest) session.setMe(testMe({ permissions: options.permissions ?? PERMISSIONS }));
  const host: Type<ReaderHost | QuoteReaderHost> = options.quotes ? QuoteReaderHost : ReaderHost;
  const fixture = TestBed.createComponent(host);
  fixture.detectChanges();
  await fixture.whenStable();
  http.expectOne((r) => r.url === URL).flush(ANSWER);
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  await stable();
  return { fixture, http, session, stable, root: fixture.nativeElement as HTMLElement };
}

/**
 * Selects a DOM range as a reader would and lets the toolbar read it. The component waits for the selection to settle
 * (a short timer) before reading it: that timer runs on a fake clock here, so the toolbar is there (or not) when this
 * returns, however busy the machine is (a real sleep made it late in full runs).
 */
async function selectRange(fixture: ComponentFixture<unknown>, range: Range): Promise<void> {
  vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
  try {
    document.getSelection()!.removeAllRanges();
    document.getSelection()!.addRange(range);
    document.dispatchEvent(new Event('selectionchange'));
    vi.runAllTimers();
  } finally {
    vi.useRealTimers();
  }
  fixture.detectChanges();
  await fixture.whenStable();
}

/** Selects a range of a block's plain text, as a reader would, and lets the toolbar read it. */
function select(fixture: ComponentFixture<unknown>, blockId: string, start: number, end: number): Promise<void> {
  const root = fixture.nativeElement as HTMLElement;
  return selectRange(fixture, domRangeOf(root.querySelector(`[data-block-id="${blockId}"]`)!, start, end)!);
}

const toolbar = (root: HTMLElement) => root.querySelector<HTMLElement>('[data-highlight-toolbar]');

describe('Reader highlights (F30)', () => {
  let http: HttpTestingController;
  afterEach(() => {
    http.verify();
    document.getSelection()?.removeAllRanges();
  });

  it('draws yours and the popular ones in the text', async () => {
    const t = await render();
    http = t.http;
    const p1 = t.root.querySelector('[data-block-id="p1"]')!;
    expect([...p1.querySelectorAll('.rd-hl-popular')].map((el) => el.textContent).join('')).toBe('ASP.NET Core، أكيد شفت الـ Dependency Injection');
    expect(t.root.querySelector('[data-block-id="p3"] [data-hl-mine="h-p3"]')!.textContent).toBe('مُهِمّ جداً');
  });

  it('selecting text offers Highlight; it is saved with the selected range', async () => {
    const t = await render();
    http = t.http;
    await select(t.fixture, 'p2', 6, 34);
    const bar = toolbar(t.root)!;
    expect(bar.getAttribute('role')).toBe('toolbar');
    expect(bar.getAttribute('aria-label')).toBe('خيارات التمييز');
    expect(bar.querySelector('[data-highlight-count]')).toBeNull();
    const button = bar.querySelector<HTMLButtonElement>('[data-highlight-create]')!;
    expect(button.textContent!.trim()).toBe('تمييز');
    button.click();
    const req = t.http.expectOne((r) => r.url === URL && r.method === 'POST');
    expect(req.request.body).toEqual({ language: 'ar-EG', blockId: 'p2', startOffset: 6, endOffset: 34, text: '@youssef_dev على الشرح 👨‍💻' });
    req.flush({ highlight: { ...req.request.body, id: 'h-new', createdAt: '2026-11-05T11:00:00Z' }, replacedIds: [] }, { status: 201, statusText: 'Created' });
    await t.stable();
    expect(toolbar(t.root)).toBeNull();
    expect([...t.root.querySelectorAll('[data-hl-mine="h-new"]')].map((el) => el.textContent).join('')).toBe('@youssef_dev على الشرح 👨‍💻');
    expect(t.root.querySelector('[data-highlights-status]')!.textContent).toBe('تم التمييز.');
  });

  it('inside a popular range the toolbar says how many readers marked it; inside yours it offers Remove', async () => {
    const t = await render();
    http = t.http;
    await select(t.fixture, 'p1', 15, 62);
    expect(toolbar(t.root)!.querySelector('[data-highlight-count]')!.textContent!.trim()).toBe('ميّز 12 من القرّاء هذه الجملة');
    expect(toolbar(t.root)!.querySelector('[data-highlight-create]')).not.toBeNull();
    // The toolbar takes no focus: screen readers hear the count from the live region.
    expect(t.root.querySelector('[data-highlights-status]')!.textContent).toBe('ميّز 12 من القرّاء هذه الجملة');

    await select(t.fixture, 'p3', 17, 25);
    const remove = toolbar(t.root)!.querySelector<HTMLButtonElement>('[data-highlight-remove]')!;
    expect(remove.textContent!.trim()).toBe('إزالة التمييز');
    expect(toolbar(t.root)!.querySelector('[data-highlight-create]')).toBeNull();
    remove.click();
    t.http.expectOne(`${TEST_API}/highlights/h-p3`).flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.root.querySelector('[data-hl-mine]')).toBeNull();
  });

  it('tapping a popular highlight shows its count; tapping yours offers Remove', async () => {
    const t = await render();
    http = t.http;
    (t.root.querySelector('[data-block-id="p1"] .rd-hl-popular') as HTMLElement).click();
    await t.stable();
    expect(toolbar(t.root)!.getAttribute('data-kind')).toBe('mark');
    expect(toolbar(t.root)!.querySelector('[data-highlight-count]')!.textContent!.trim()).toBe('ميّز 12 من القرّاء هذه الجملة');
    expect(toolbar(t.root)!.querySelector('button')).toBeNull();
    expect(t.root.querySelector('[data-highlights-status]')!.textContent).toBe('ميّز 12 من القرّاء هذه الجملة');

    (t.root.querySelector('[data-hl-mine="h-p3"]') as HTMLElement).click();
    await t.stable();
    expect(toolbar(t.root)!.querySelector('[data-highlight-remove]')).not.toBeNull();
  });

  it('no toolbar in code or tables, or for fewer than 3 characters', async () => {
    const t = await render();
    http = t.http;
    const code = t.root.querySelector('[data-block-id="k1"]')!;
    const walker = document.createTreeWalker(code, NodeFilter.SHOW_TEXT);
    let text = walker.nextNode() as Text;
    while (text && text.data.length < 6) text = walker.nextNode() as Text;
    const range = document.createRange();
    range.setStart(text, 0);
    range.setEnd(text, 5);
    await selectRange(t.fixture, range);
    expect(toolbar(t.root)).toBeNull();
    await select(t.fixture, 'p1', 0, 2);
    expect(toolbar(t.root)).toBeNull();
  });

  it('fewer than 3 characters inside one of yours still offer Remove (no Highlight)', async () => {
    const t = await render();
    http = t.http;
    await select(t.fixture, 'p3', 20, 22);
    const bar = toolbar(t.root)!;
    expect(bar.querySelector('[data-highlight-create]')).toBeNull();
    const remove = bar.querySelector<HTMLButtonElement>('[data-highlight-remove]')!;
    expect(remove.textContent!.trim()).toBe('إزالة التمييز');
    remove.click();
    t.http.expectOne(`${TEST_API}/highlights/h-p3`).flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.root.querySelector('[data-hl-mine]')).toBeNull();
  });

  it('guests get the sign-in prompt from Highlight, and nothing is sent', async () => {
    const t = await render({ guest: true });
    http = t.http;
    await select(t.fixture, 'p2', 6, 34);
    toolbar(t.root)!.querySelector<HTMLButtonElement>('[data-highlight-create]')!.click();
    await t.stable();
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
    t.http.expectNone((r) => r.method === 'POST');
  });

  it('keyboard: Tab moves into the toolbar, Escape closes it', async () => {
    const t = await render();
    http = t.http;
    await select(t.fixture, 'p2', 6, 34);
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab', bubbles: true, cancelable: true }));
    expect(document.activeElement).toBe(toolbar(t.root)!.querySelector('[data-highlight-create]'));
    toolbar(t.root)!.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    await t.stable();
    expect(toolbar(t.root)).toBeNull();
  });

  it('Ctrl + / hides every highlight (saved to your preferences) and shows them again', async () => {
    const t = await render();
    http = t.http;
    document.dispatchEvent(new KeyboardEvent('keydown', { key: '/', code: 'Slash', ctrlKey: true, bubbles: true, cancelable: true }));
    const hide = t.http.expectOne(`${TEST_API}/me/preferences`);
    expect(hide.request.body.showHighlights).toBe(false);
    hide.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.root.querySelector('.rd-hl')).toBeNull();
    expect(TestBed.inject(SessionStore).me()!.showHighlights).toBe(false);
    expect(t.root.querySelector('[data-highlights-status]')!.textContent).toBe('تم إخفاء التمييزات.');
    // Hidden: selecting offers nothing.
    await select(t.fixture, 'p2', 6, 34);
    expect(toolbar(t.root)).toBeNull();

    document.dispatchEvent(new KeyboardEvent('keydown', { key: '/', code: 'Slash', ctrlKey: true, bubbles: true, cancelable: true }));
    t.http.expectOne(`${TEST_API}/me/preferences`).flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.root.querySelector('.rd-hl')).not.toBeNull();
  });

  it('without the highlights.create permission only the popular count shows', async () => {
    const t = await render({ permissions: ['articles.read'] });
    http = t.http;
    await select(t.fixture, 'p2', 6, 34);
    expect(toolbar(t.root)).toBeNull();
    await select(t.fixture, 'p1', 20, 30);
    expect(toolbar(t.root)!.querySelector('[data-highlight-count]')).not.toBeNull();
    expect(toolbar(t.root)!.querySelector('button')).toBeNull();
  });
});

describe('Reader highlights: Share quote (F24)', () => {
  let http: HttpTestingController;
  const buttons = (root: HTMLElement) => [...toolbar(root)!.querySelectorAll('button')].map((b) => b.textContent!.trim());

  beforeEach(() => {
    globalThis.URL.createObjectURL = vi.fn(() => 'blob:http://localhost/quote');
    globalThis.URL.revokeObjectURL = vi.fn();
  });

  afterEach(() => {
    http.verify();
    document.getSelection()?.removeAllRanges();
    vi.restoreAllMocks();
  });

  it('is next to Highlight; it opens the quote card dialog for the same range, and the toolbar goes', async () => {
    const t = await render({ quotes: true });
    http = t.http;
    await select(t.fixture, 'p2', 6, 34);
    expect(buttons(t.root)).toEqual(['تمييز', 'مشاركة اقتباس']);
    // Keyboard: Tab reaches Highlight first, as before.
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab', bubbles: true, cancelable: true }));
    expect(document.activeElement).toBe(toolbar(t.root)!.querySelector('[data-highlight-create]'));

    toolbar(t.root)!.querySelector<HTMLButtonElement>('[data-quote-share-open]')!.click();
    await t.stable();
    expect(toolbar(t.root)).toBeNull();
    expect(document.getSelection()!.isCollapsed).toBe(true);
    await vi.waitFor(() => {
      t.fixture.detectChanges();
      expect(t.root.querySelector('[data-quote-dialog]')).not.toBeNull();
    });
    const req = t.http.expectOne((r) => r.url === `${TEST_API}/articles/a1/quote-card`);
    expect(req.request.body).toMatchObject({ language: 'ar-EG', blockId: 'p2', startOffset: 6, endOffset: 34, text: '@youssef_dev على الشرح 👨‍💻', format: 'square' });
    req.flush(new Blob(['png'], { type: 'image/png' }));
    await t.stable();
    expect(t.root.querySelector('[data-quote-image]')).not.toBeNull();

    // A selection change while the dialog is open brings no toolbar under it.
    await select(t.fixture, 'p1', 0, 10);
    expect(toolbar(t.root)).toBeNull();

    t.root.querySelector<HTMLButtonElement>('[role="dialog"] button[aria-label="إغلاق"]')!.click();
    await t.stable();
    expect(t.root.querySelector('[data-quote-dialog]')).toBeNull();
    // Closed: selecting offers it again.
    await select(t.fixture, 'p3', 0, 10);
    expect(toolbar(t.root)!.querySelector('[data-quote-share-open]')).not.toBeNull();
  });

  it('guests get it next to Highlight (no sign-in prompt); readers who cannot highlight get it alone', async () => {
    const guest = await render({ quotes: true, guest: true });
    http = guest.http;
    await select(guest.fixture, 'p2', 6, 34);
    expect(buttons(guest.root)).toEqual(['تمييز', 'مشاركة اقتباس']);
    toolbar(guest.root)!.querySelector<HTMLButtonElement>('[data-quote-share-open]')!.click();
    await guest.stable();
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(false);
    await vi.waitFor(() => {
      guest.fixture.detectChanges();
      expect(guest.root.querySelector('[data-quote-dialog]')).not.toBeNull();
    });
    guest.http.expectOne(`${TEST_API}/articles/a1/quote-card`).flush(new Blob(['png'], { type: 'image/png' }));
    http.verify();

    TestBed.resetTestingModule();
    const reader = await render({ quotes: true, permissions: ['articles.read'] });
    http = reader.http;
    await select(reader.fixture, 'p2', 6, 34);
    expect(buttons(reader.root)).toEqual(['مشاركة اقتباس']);
    // Inside a popular range: the count, and Share quote.
    await select(reader.fixture, 'p1', 20, 30);
    expect(toolbar(reader.root)!.querySelector('[data-highlight-count]')).not.toBeNull();
    expect(buttons(reader.root)).toEqual(['مشاركة اقتباس']);
  });

  it('inside one of yours it is next to Remove; not for fewer than 3 characters, in code, or when the page gives no article', async () => {
    const t = await render({ quotes: true });
    http = t.http;
    await select(t.fixture, 'p3', 17, 25);
    expect(buttons(t.root)).toEqual(['إزالة التمييز', 'مشاركة اقتباس']);
    await select(t.fixture, 'p3', 20, 22);
    expect(buttons(t.root)).toEqual(['إزالة التمييز']);
    await select(t.fixture, 'p1', 0, 2);
    expect(toolbar(t.root)).toBeNull();
    const code = t.root.querySelector('[data-block-id="k1"]')!;
    const walker = document.createTreeWalker(code, NodeFilter.SHOW_TEXT);
    let text = walker.nextNode() as Text;
    while (text && text.data.length < 6) text = walker.nextNode() as Text;
    const range = document.createRange();
    range.setStart(text, 0);
    range.setEnd(text, 5);
    await selectRange(t.fixture, range);
    expect(toolbar(t.root)).toBeNull();

    // Hidden by moderators: the page gives no article, so only Highlight.
    (t.fixture.componentInstance as QuoteReaderHost).quote.set(null);
    await t.stable();
    await select(t.fixture, 'p2', 6, 34);
    expect(buttons(t.root)).toEqual(['تمييز']);
  });

  it('while highlights are hidden nothing shows, Share quote included', async () => {
    const t = await render({ quotes: true });
    http = t.http;
    document.dispatchEvent(new KeyboardEvent('keydown', { key: '/', code: 'Slash', ctrlKey: true, bubbles: true, cancelable: true }));
    t.http.expectOne(`${TEST_API}/me/preferences`).flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    await select(t.fixture, 'p2', 6, 34);
    expect(toolbar(t.root)).toBeNull();
  });

  it('over 400 characters it says so when pressed, and asks the server nothing', async () => {
    const t = await render({ quotes: true });
    http = t.http;
    await select(t.fixture, 'long1', 0, 401);
    expect(buttons(t.root)).toEqual(['تمييز', 'مشاركة اقتباس']);
    toolbar(t.root)!.querySelector<HTMLButtonElement>('[data-quote-share-open]')!.click();
    await t.stable();
    expect(TestBed.inject(ToastService).toasts().at(-1)).toMatchObject({ kind: 'error', message: 'يجب ألا يتجاوز الاقتباس 400 حرف. حدّد جزءًا أقصر.' });
    expect(toolbar(t.root)).toBeNull();
    t.http.expectNone((r) => r.url.endsWith('/quote-card'));
    // 400 exactly is fine.
    await select(t.fixture, 'long1', 0, 400);
    toolbar(t.root)!.querySelector<HTMLButtonElement>('[data-quote-share-open]')!.click();
    await vi.waitFor(() => {
      t.fixture.detectChanges();
      expect(t.root.querySelector('[data-quote-dialog]')).not.toBeNull();
    });
    const req = t.http.expectOne(`${TEST_API}/articles/a1/quote-card`);
    expect(req.request.body.text).toHaveLength(400);
    req.flush(new Blob(['png'], { type: 'image/png' }));
  });

  it('keyboard: from Share quote the dialog takes focus, and Escape gives it back to the quoted block, not the top of the page', async () => {
    const t = await render({ quotes: true });
    http = t.http;
    await select(t.fixture, 'p2', 6, 34);
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab', bubbles: true, cancelable: true }));
    expect(document.activeElement).toBe(toolbar(t.root)!.querySelector('[data-highlight-create]'));
    // The next Tab is the browser's own (from Highlight to Share quote), then Enter presses it.
    const share = toolbar(t.root)!.querySelector<HTMLButtonElement>('[data-quote-share-open]')!;
    share.focus();
    share.click();
    await t.stable();
    await vi.waitFor(() => {
      t.fixture.detectChanges();
      expect(t.root.querySelector('[role="dialog"]')?.contains(document.activeElement)).toBe(true);
    });
    t.http.expectOne(`${TEST_API}/articles/a1/quote-card`).flush(new Blob(['png'], { type: 'image/png' }));
    await t.stable();

    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true }));
    await t.stable();
    expect(t.root.querySelector('[data-quote-dialog]')).toBeNull();
    const p2 = t.root.querySelector<HTMLElement>('[data-block-id="p2"]')!;
    await vi.waitFor(() => expect(document.activeElement).toBe(p2));
    expect(p2.getAttribute('tabindex')).toBe('-1');
    expect(t.root.querySelector('rd-rdoc')!.contains(document.activeElement)).toBe(true);
  });

  it('quote.text_mismatch: the dialog says so and the article and its highlights load again, as after highlight.text_mismatch', async () => {
    const t = await render({ quotes: true });
    http = t.http;
    await select(t.fixture, 'p2', 6, 34);
    toolbar(t.root)!.querySelector<HTMLButtonElement>('[data-quote-share-open]')!.click();
    await vi.waitFor(() => {
      t.fixture.detectChanges();
      expect(t.root.querySelector('[data-quote-dialog]')).not.toBeNull();
    });
    t.http
      .expectOne(`${TEST_API}/articles/a1/quote-card`)
      .flush(new Blob([JSON.stringify(problem(400, 'quote.text_mismatch'))], { type: 'application/problem+json' }), { status: 400, statusText: 'Bad Request' });
    // The ProblemDetails blob is read asynchronously.
    await vi.waitFor(() => {
      t.fixture.detectChanges();
      expect(t.root.querySelector('[data-quote-preview]')!.getAttribute('data-state')).toBe('error');
    });
    expect(t.root.querySelector('[data-quote-error] [role="alert"]')!.textContent!.trim()).toBe('تغيّر هذا النص في المقال. حدّث الصفحة وحاول مرة أخرى.');
    expect((t.fixture.componentInstance as QuoteReaderHost).articleReloads).toBe(1);
    t.http.expectOne((r) => r.url === URL && r.method === 'GET').flush(ANSWER);
    await t.stable();
    // The dialog stays open on its message.
    expect(t.root.querySelector('[data-quote-dialog]')).not.toBeNull();
  });
});

import { ChangeDetectionStrategy, Component, ElementRef, computed, inject, signal, viewChild } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import fixtures from '../../../../../shared/rdoc/highlight-fixtures.json';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { ArticleHighlightsDto } from '../../core/api/highlights.api';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { HighlighterService } from '../../shared/rdoc/highlighter.service';
import { RDocRenderer } from '../../shared/rdoc/rdoc-renderer';
import { RDoc } from '../../shared/rdoc/rdoc.models';
import { domRangeOf } from '../../shared/rdoc/selection-offsets';
import { ArticleHighlightsStore } from './article-highlights.store';
import { ReaderHighlights } from './reader-highlights';

const DOC = (fixtures as unknown as { documents: { ar: RDoc } }).documents.ar;
const URL = `${TEST_API}/articles/a1/highlights`;
const PERMISSIONS = ['articles.read', 'highlights.create'];

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

const ANSWER: ArticleHighlightsDto = {
  articleId: 'a1',
  language: 'ar-EG',
  mine: [{ id: 'h-p3', blockId: 'p3', startOffset: 16, endOffset: 27, text: 'مُهِمّ جداً', createdAt: '2026-11-05T10:00:00Z' }],
  popular: [{ blockId: 'p1', startOffset: 15, endOffset: 62, text: 'ASP.NET Core، أكيد شفت الـ Dependency Injection', count: 12 }],
};

async function render(options: { guest?: boolean; permissions?: string[] } = {}) {
  localStorage.removeItem('rd.highlights.hidden');
  const { http, session } = setupSocialTesting({
    guest: options.guest,
    providers: [{ provide: HighlighterService, useValue: { highlight: () => Promise.resolve(null) } }],
  });
  if (!options.guest) session.setMe(testMe({ permissions: options.permissions ?? PERMISSIONS }));
  const fixture = TestBed.createComponent(ReaderHost);
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
    expect(bar.getAttribute('aria-label')).toBe('خيارات الـ Highlight');
    expect(bar.querySelector('[data-highlight-count]')).toBeNull();
    const button = bar.querySelector<HTMLButtonElement>('[data-highlight-create]')!;
    expect(button.textContent!.trim()).toBe('علّم');
    button.click();
    const req = t.http.expectOne((r) => r.url === URL && r.method === 'POST');
    expect(req.request.body).toEqual({ language: 'ar-EG', blockId: 'p2', startOffset: 6, endOffset: 34, text: '@youssef_dev على الشرح 👨‍💻' });
    req.flush({ highlight: { ...req.request.body, id: 'h-new', createdAt: '2026-11-05T11:00:00Z' }, replacedIds: [] }, { status: 201, statusText: 'Created' });
    await t.stable();
    expect(toolbar(t.root)).toBeNull();
    expect([...t.root.querySelectorAll('[data-hl-mine="h-new"]')].map((el) => el.textContent).join('')).toBe('@youssef_dev على الشرح 👨‍💻');
    expect(t.root.querySelector('[data-highlights-status]')!.textContent).toBe('اتعلّمت.');
  });

  it('inside a popular range the toolbar says how many readers marked it; inside yours it offers Remove', async () => {
    const t = await render();
    http = t.http;
    await select(t.fixture, 'p1', 15, 62);
    expect(toolbar(t.root)!.querySelector('[data-highlight-count]')!.textContent!.trim()).toBe('12 قارئ علّموا الجملة دي');
    expect(toolbar(t.root)!.querySelector('[data-highlight-create]')).not.toBeNull();
    // The toolbar takes no focus: screen readers hear the count from the live region.
    expect(t.root.querySelector('[data-highlights-status]')!.textContent).toBe('12 قارئ علّموا الجملة دي');

    await select(t.fixture, 'p3', 17, 25);
    const remove = toolbar(t.root)!.querySelector<HTMLButtonElement>('[data-highlight-remove]')!;
    expect(remove.textContent!.trim()).toBe('شيل العلامة');
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
    expect(toolbar(t.root)!.querySelector('[data-highlight-count]')!.textContent!.trim()).toBe('12 قارئ علّموا الجملة دي');
    expect(toolbar(t.root)!.querySelector('button')).toBeNull();
    expect(t.root.querySelector('[data-highlights-status]')!.textContent).toBe('12 قارئ علّموا الجملة دي');

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
    expect(remove.textContent!.trim()).toBe('شيل العلامة');
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
    expect(t.root.querySelector('[data-highlights-status]')!.textContent).toBe('الـ Highlights اتخفت.');
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

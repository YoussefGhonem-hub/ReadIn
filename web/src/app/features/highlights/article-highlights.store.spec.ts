import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { signal } from '@angular/core';
import fixtures from '../../../../../shared/rdoc/highlight-fixtures.json';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ArticleHighlightsDto, HighlightDto } from '../../core/api/highlights.api';
import { SessionStore } from '../../core/auth/session.store';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { RDoc } from '../../shared/rdoc/rdoc.models';
import { ArticleHighlightsStore, ReaderArticle } from './article-highlights.store';

const DOC = (fixtures as unknown as { documents: { ar: RDoc } }).documents.ar;
const URL = `${TEST_API}/articles/a1/highlights`;

const mine = (id: string, blockId: string, startOffset: number, endOffset: number, text: string): HighlightDto => ({
  id,
  blockId,
  startOffset,
  endOffset,
  text,
  createdAt: '2026-11-05T10:00:00Z',
});

function answer(patch: Partial<ArticleHighlightsDto> = {}): ArticleHighlightsDto {
  return {
    articleId: 'a1',
    language: 'ar-EG',
    mine: [mine('h-p3', 'p3', 16, 27, 'مُهِمّ جداً'), mine('h-p1', 'p1', 0, 6, 'لو انت')],
    popular: [{ blockId: 'p1', startOffset: 15, endOffset: 62, text: 'ASP.NET Core، أكيد شفت الـ Dependency Injection', count: 12 }],
    ...patch,
  };
}

function setup(options: { guest?: boolean } = {}) {
  const { http, session, toasts } = setupSocialTesting({ guest: options.guest, providers: [ArticleHighlightsStore] });
  const store = TestBed.inject(ArticleHighlightsStore);
  const article = signal<ReaderArticle | null>({ id: 'a1', language: 'ar-EG', content: DOC });
  const reloads: number[] = [];
  store.connect(article, () => reloads.push(1));
  TestBed.tick();
  const stable = async () => {
    await flushMicrotasks();
    TestBed.tick();
  };
  return { http, session, toasts, store, article, reloads, stable };
}

describe('ArticleHighlightsStore (F30)', () => {
  let http: HttpTestingController;
  afterEach(() => http.verify());

  it('loads the version on screen, yours in document order, and draws yours over popular ones', async () => {
    const t = setup();
    http = t.http;
    const req = t.http.expectOne((r) => r.url === URL);
    expect(req.request.params.get('lang')).toBe('ar-EG');
    req.flush(answer());
    await t.stable();
    expect(t.store.mine().map((h) => h.id)).toEqual(['h-p1', 'h-p3']);
    const marks = t.store.marks()!;
    expect(marks.get('p1')).toEqual([
      { start: 0, end: 6, mine: 'h-p1', count: null },
      { start: 15, end: 62, mine: null, count: 12 },
    ]);
    expect(marks.get('p3')).toEqual([{ start: 16, end: 27, mine: 'h-p3', count: null }]);
    expect(t.store.popularCount({ blockId: 'p1', startOffset: 20, endOffset: 30, text: '' })).toBe(12);
    expect(t.store.mineContaining({ blockId: 'p3', startOffset: 17, endOffset: 20, text: '' })?.id).toBe('h-p3');
    expect(t.store.mineContaining({ blockId: 'p3', startOffset: 10, endOffset: 20, text: '' })).toBeNull();
  });

  it('create is drawn at once, then the server answer replaces it and the highlights it joined', async () => {
    const t = setup();
    http = t.http;
    t.http.expectOne((r) => r.url === URL).flush(answer());
    await t.stable();
    const done = t.store.create({ blockId: 'p1', startOffset: 3, endOffset: 11, text: 'انت شغال' });
    expect(t.store.mine().some((h) => h.id.startsWith('pending-'))).toBe(true);
    const req = t.http.expectOne(`${URL}`);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({ language: 'ar-EG', blockId: 'p1', startOffset: 3, endOffset: 11, text: 'انت شغال' });
    req.flush({ highlight: mine('h-new', 'p1', 0, 11, 'لو انت شغال'), replacedIds: ['h-p1'] }, { status: 201, statusText: 'Created' });
    expect(await done).toBe(true);
    expect(t.store.mine().map((h) => h.id)).toEqual(['h-new', 'h-p3']);
  });

  it('a refused create goes away with the reason; text_mismatch reloads the article and its highlights', async () => {
    const t = setup();
    http = t.http;
    t.http.expectOne((r) => r.url === URL).flush(answer());
    await t.stable();
    const toasts = TestBed.inject(ToastService);

    const limited = t.store.create({ blockId: 'p2', startOffset: 0, endOffset: 5, text: 'شكراً' });
    t.http.expectOne(URL).flush(problem(400, 'highlight.limit'), { status: 400, statusText: 'Bad Request' });
    expect(await limited).toBe(false);
    expect(t.store.mine().map((h) => h.id)).toEqual(['h-p1', 'h-p3']);
    expect(toasts.toasts().at(-1)?.message).toBe('وصلت لأقصى عدد Highlights في المقال ده (100).');

    const changed = t.store.create({ blockId: 'p2', startOffset: 0, endOffset: 5, text: 'شكراً' });
    t.http.expectOne(URL).flush(problem(400, 'highlight.text_mismatch'), { status: 400, statusText: 'Bad Request' });
    expect(await changed).toBe(false);
    expect(toasts.toasts().at(-1)?.message).toBe('النص ده اتغيّر في المقال. حدّث الصفحة وجرّب تاني.');
    expect(t.reloads).toHaveLength(1);
    t.http.expectOne((r) => r.url === URL && r.method === 'GET').flush(answer({ mine: [] }));
    await t.stable();
    expect(t.store.mine()).toEqual([]);
  });

  it('remove is optimistic; "already gone" counts as removed, another failure puts it back', async () => {
    const t = setup();
    http = t.http;
    t.http.expectOne((r) => r.url === URL).flush(answer());
    await t.stable();

    const gone = t.store.remove('h-p1');
    expect(t.store.mine().map((h) => h.id)).toEqual(['h-p3']);
    t.http.expectOne(`${TEST_API}/highlights/h-p1`).flush(problem(404, 'highlight.not_found'), { status: 404, statusText: 'Not Found' });
    expect(await gone).toBe(true);
    expect(t.store.mine().map((h) => h.id)).toEqual(['h-p3']);

    const failed = t.store.remove('h-p3');
    expect(t.store.mine()).toEqual([]);
    t.http.expectOne(`${TEST_API}/highlights/h-p3`).flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    expect(await failed).toBe(false);
    expect(t.store.mine().map((h) => h.id)).toEqual(['h-p3']);
  });

  it('hidden: nothing is drawn and nothing is asked for until shown again', async () => {
    const t = setup();
    http = t.http;
    t.http.expectOne((r) => r.url === URL).flush(answer());
    await t.stable();
    const session = TestBed.inject(SessionStore);
    session.patchMe({ showHighlights: false });
    TestBed.tick();
    expect(t.store.marks()).toBeNull();
    // Another version while hidden: no request.
    t.article.set({ id: 'a1', language: 'en', content: DOC });
    TestBed.tick();
    t.http.expectNone((r) => r.url === URL);
    session.patchMe({ showHighlights: true });
    TestBed.tick();
    const req = t.http.expectOne((r) => r.url === URL);
    expect(req.request.params.get('lang')).toBe('en');
    // The other version's highlights were dropped at once.
    expect(t.store.mine()).toEqual([]);
    req.flush(answer({ language: 'en', mine: [], popular: [] }));
    await t.stable();
  });

  it('guests load popular ones only after the session is known', async () => {
    const t = setup({ guest: true });
    http = t.http;
    t.http.expectOne((r) => r.url === URL).flush(answer({ mine: [] }));
    await t.stable();
    expect(t.store.marks()!.get('p1')).toEqual([{ start: 15, end: 62, mine: null, count: 12 }]);
  });
});

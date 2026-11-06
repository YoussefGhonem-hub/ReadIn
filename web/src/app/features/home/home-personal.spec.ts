import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { NEVER } from 'rxjs';
import { testContinueReading, testPathCard, testProgress } from '../../../testing/paths-testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto, ContinueReadingDto, PathCardDto } from '../../core/api/models';
import { ReadingApi } from '../../core/api/reading.api';
import { RealtimeService } from '../../core/realtime/realtime.service';
import { SessionStore } from '../../core/auth/session.store';
import { HomePage } from './home.page';
import { CONTINUE_READING_LIMIT, HomeStore } from './home.store';

type Answer<T> = T | 'error' | 'pending';

/** Home's "Continue reading" and learning path cards (F03, F09). */
describe('Home → Continue reading and the learning path (F03, F09)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    // jsdom has no IntersectionObserver; the feed's infinite scroll only needs observe/disconnect here.
    vi.stubGlobal(
      'IntersectionObserver',
      class {
        observe = vi.fn();
        disconnect = vi.fn();
      },
    );
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    http?.verify();
  });

  /** Answers a request, or hands it back to answer later ('pending'). */
  function answer<T>(req: TestRequest, value: Answer<T>, empty = 204): TestRequest | null {
    if (value === 'pending') return req;
    if (value === 'error') req.flush(null, { status: 500, statusText: 'Error' });
    else if (value === null) req.flush(null, { status: empty, statusText: 'No Content' });
    else req.flush(value as object);
    return null;
  }

  async function render(
    options: {
      guest?: boolean;
      today?: Answer<ArticleCardDto | null>;
      continueReading?: Answer<ContinueReadingDto[]>;
      active?: Answer<PathCardDto | null>;
    } = {},
  ) {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({
      guest: options.guest,
      providers: [
        { provide: ReadingApi, useValue: { stats: () => NEVER } },
        { provide: RealtimeService, useValue: { watchLatestPublished: () => () => undefined } },
      ],
    }));
    const fixture = TestBed.createComponent(HomePage);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    // No whenStable: requests left open on purpose ('pending') keep the app unstable.
    const stable = async () => {
      await flushMicrotasks(10);
      fixture.detectChanges();
      await flushMicrotasks(10);
      fixture.detectChanges();
    };
    await stable();
    http.expectOne(`${TEST_API}/fields`).flush([]);
    const pending = { today: answer(http.expectOne(`${TEST_API}/feed/today`), options.today === undefined ? null : options.today), active: null as TestRequest | null };
    http.expectOne((r) => r.url === `${TEST_API}/feed/for-you`).flush({ items: [], nextCursor: null });
    if (!options.guest) {
      const continueReq = http.expectOne((r) => r.url === `${TEST_API}/me/continue-reading`);
      expect(continueReq.request.params.get('limit')).toBe(String(CONTINUE_READING_LIMIT));
      answer(continueReq, options.continueReading ?? []);
      pending.active = answer(http.expectOne(`${TEST_API}/me/paths/active`), options.active === undefined ? null : options.active);
    }
    await stable();
    const store = fixture.debugElement.injector.get(HomeStore);
    return { fixture, root, stable, store, pending, $: <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector) };
  }

  it('continue reading: the latest unfinished article, in the version you were reading', async () => {
    const { $ } = await render({ continueReading: [testContinueReading('c1', 42), testContinueReading('c2', 10)] });
    const card = $<HTMLAnchorElement>('[data-continue-reading]')!;
    expect(card.getAttribute('href')).toBe('/ar/a/slug-c1');
    expect(card.textContent).toContain('متابعة القراءة');
    expect(card.textContent).toContain('Reading c1');
    expect(card.textContent).toContain('البرمجيات');
    const bar = card.querySelector('[role="progressbar"]')!;
    expect(bar.getAttribute('aria-valuenow')).toBe('42');
    expect(bar.getAttribute('aria-label')).toBe('تمت قراءة 42%');
  });

  it("continue reading skips today's article (its post card shows it)", async () => {
    const { $ } = await render({
      today: testCard({ id: 'c1', slug: 'slug-c1' }),
      continueReading: [testContinueReading('c1', 42), testContinueReading('c2', 10)],
    });
    expect($('rd-post-card[data-today-card] [data-card-label]')!.textContent).toContain('مقال اليوم');
    expect($('[data-continue-reading]')!.getAttribute('href')).toBe('/ar/a/slug-c2');
  });

  it('continue reading is hidden when only the hero is left, when empty and on errors', async () => {
    const onlyHero = await render({ today: testCard({ id: 'c1' }), continueReading: [testContinueReading('c1')] });
    expect(onlyHero.$('[data-continue-reading]')).toBeNull();
    const empty = await render({ continueReading: [] });
    expect(empty.$('[data-continue-reading]')).toBeNull();
    const failed = await render({ continueReading: 'error' });
    expect(failed.$('[data-continue-reading]')).toBeNull();
  });

  it('continue reading waits for the first answer about the hero', async () => {
    const { $, stable, pending } = await render({ today: 'pending', continueReading: [testContinueReading('c1')] });
    expect($('[data-continue-reading]')).toBeNull();
    pending.today!.flush(testCard({ id: 'c1' }));
    await stable();
    expect($('[data-continue-reading]')).toBeNull();
  });

  it('your path in progress: title, field, read/total, and the next article as the main action', async () => {
    const { $ } = await render({ active: testPathCard({ ...testProgress(1, { enrolled: true }) }) });
    const card = $('[data-home-path]')!;
    expect(card.textContent).toContain('مسارك');
    expect(card.textContent).toContain('البرمجيات');
    expect($('[data-home-path-link]')!.getAttribute('href')).toBe('/paths/aspnet-core-basics');
    expect($('[data-home-path-count]')!.textContent!.trim()).toBe('1/4');
    expect(card.querySelector('[role="progressbar"]')!.getAttribute('aria-valuenow')).toBe('25');
    const next = $<HTMLAnchorElement>('[data-home-path-next]')!;
    expect(next.getAttribute('href')).toBe('/en/a/article-2');
    expect(next.textContent).toContain('التالي:');
    expect(next.textContent).toContain('Article 2');
    expect($('[data-home-path-prompt]')).toBeNull();
  });

  it('no path in progress (204), an error, or a guest: the slim "explore paths" row', async () => {
    const none = await render({ active: null });
    expect(none.$('[data-home-path]')).toBeNull();
    expect(none.$('[data-home-path-prompt]')!.getAttribute('href')).toBe('/paths');
    expect(none.$('[data-home-path-prompt]')!.textContent).toContain('تعلّم خطوة بخطوة مع المسارات التعليمية');

    const failed = await render({ active: 'error' });
    expect(failed.$('[data-home-path-prompt]')).not.toBeNull();

    // Guests never ask for /me/* (render() checks there is no such request).
    const guest = await render({ guest: true });
    expect(guest.$('[data-home-path-prompt]')).not.toBeNull();
    expect(guest.$('[data-continue-reading]')).toBeNull();
  });

  it('a placeholder while the active path loads', async () => {
    const { $, stable, pending } = await render({ active: 'pending' });
    expect($('[data-home-path-loading]')).not.toBeNull();
    expect($('[data-home-path-prompt]')).toBeNull();
    pending.active!.flush(testPathCard({ ...testProgress(2, { enrolled: true }) }));
    await stable();
    expect($('[data-home-path-loading]')).toBeNull();
    expect($('[data-home-path]')).not.toBeNull();
  });

  it('refresh reloads both cards and keeps them on screen meanwhile; signing out clears them', async () => {
    const { $, stable, store } = await render({ continueReading: [testContinueReading('c1')], active: testPathCard({ ...testProgress(1, { enrolled: true }) }) });
    void store.refresh();
    await stable();
    expect($('[data-continue-reading]')).not.toBeNull();
    expect($('[data-home-path]')).not.toBeNull();
    http.expectOne(`${TEST_API}/feed/today`).flush(null, { status: 204, statusText: 'No Content' });
    http.expectOne((r) => r.url === `${TEST_API}/feed/for-you`).flush({ items: [], nextCursor: null });
    http.expectOne((r) => r.url === `${TEST_API}/me/continue-reading`).flush([testContinueReading('c9')]);
    http.expectOne(`${TEST_API}/me/paths/active`).flush(null, { status: 204, statusText: 'No Content' });
    await stable();
    expect($('[data-continue-reading]')!.getAttribute('href')).toBe('/ar/a/slug-c9');
    expect($('[data-home-path-prompt]')).not.toBeNull();

    TestBed.inject(SessionStore).setGuest();
    await stable();
    expect($('[data-continue-reading]')).toBeNull();
    expect($('[data-home-path-prompt]')).not.toBeNull();
  });
});

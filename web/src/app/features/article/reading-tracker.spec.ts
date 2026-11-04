import { EnvironmentInjector, PLATFORM_ID, createEnvironmentInjector, runInInjectionContext, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Observable, Subject, of, throwError } from 'rxjs';
import { ApiError } from '../../core/api/api.config';
import { ReadingProgressRequest, ReadingProgressResultDto, ReadingStatsDto, StreakDto } from '../../core/api/models';
import { ReadingApi } from '../../core/api/reading.api';
import { SessionStore } from '../../core/auth/session.store';
import { testMe } from '../../../testing/auth-testing';
import { ReadingSheetsService } from '../reading/reading-sheets.service';
import { StreakStore } from '../reading/streak.store';
import { ACTIVE_WINDOW_MS, REPORT_INTERVAL_MS, TrackedArticle, injectReadingTracker } from './reading-tracker';

type Reply = Observable<ReadingProgressResultDto>;

const STREAK: StreakDto = { current: 6, longest: 6, readToday: false, freezeAvailable: true, freezePending: false, today: '2026-11-03' };
const STATS: ReadingStatsDto = {
  streak: STREAK,
  totalArticles: 6,
  minutesRead: 40,
  articlesThisWeek: 6,
  minutesThisWeek: 40,
  articlesThisMonth: 6,
  topFields: [],
};

const ok = (patch: Partial<ReadingProgressResultDto> = {}): Reply =>
  of({ percent: 0, completed: false, completedNow: false, streak: null, milestone: null, ...patch });
const fail = (status: number, code = 'unknown'): Reply => throwError(() => new ApiError(status, code, null));

let visibility: DocumentVisibilityState = 'visible';

function setup(options: { signedIn?: boolean; replies?: (() => Reply)[]; hold?: () => boolean } = {}) {
  const replies = [...(options.replies ?? [])];
  const api = {
    progress: vi.fn<(id: string, body: ReadingProgressRequest, options?: { keepalive?: boolean }) => Reply>(() => (replies.shift() ?? ok)()),
    stats: vi.fn(() => of(STATS)),
  };
  const sheets = { celebrate: vi.fn() };
  TestBed.configureTestingModule({
    providers: [
      { provide: ReadingApi, useValue: api },
      { provide: ReadingSheetsService, useValue: sheets },
      { provide: PLATFORM_ID, useValue: 'browser' },
    ],
  });
  const session = TestBed.inject(SessionStore);
  if (options.signedIn ?? true) session.setMe(testMe());
  else session.setGuest();

  const article = signal<TrackedArticle | null>({ id: 'a1', language: 'ar-EG' });
  const progress = signal(0);
  // The reader's own injector: destroying it is leaving the article.
  const reader = createEnvironmentInjector([], TestBed.inject(EnvironmentInjector));
  runInInjectionContext(reader, () => injectReadingTracker(article, progress, undefined, options.hold));
  TestBed.tick();

  const bodies = () => api.progress.mock.calls.map(([, body]) => body);
  const seconds = () => bodies().map((body) => body.activeSecondsDelta);
  return { api, sheets, session, article, progress, reader, bodies, seconds };
}

/** Advances the fake clock and lets the reports' promises settle. */
const advance = (ms: number) => vi.advanceTimersByTimeAsync(ms);
const interact = (type = 'pointerdown') => window.dispatchEvent(new Event(type));
const setVisibility = (state: DocumentVisibilityState) => {
  visibility = state;
  document.dispatchEvent(new Event('visibilitychange'));
};

describe('injectReadingTracker', () => {
  beforeEach(() => {
    TestBed.resetTestingModule();
    vi.useFakeTimers({ now: new Date('2026-11-03T10:00:00Z') });
    visibility = 'visible';
    Object.defineProperty(document, 'visibilityState', { configurable: true, get: () => visibility });
  });

  afterEach(() => {
    TestBed.resetTestingModule();
    vi.useRealTimers();
    delete (document as { visibilityState?: unknown }).visibilityState;
  });

  it('reports on open without time, then the active seconds every 15 s', async () => {
    const { bodies, progress } = setup();
    await advance(0);
    expect(bodies()).toEqual([{ language: 'ar-EG', percent: 0, lastPosition: '0.0000', activeSecondsDelta: 0 }]);

    await advance(5_000);
    progress.set(0.42);
    TestBed.tick();
    interact('scroll');
    await advance(REPORT_INTERVAL_MS - 5_000);

    expect(bodies()[1]).toEqual({ language: 'ar-EG', percent: 42, lastPosition: '0.4200', activeSecondsDelta: 15 });
  });

  it('sends the highest progress reached and the current position', async () => {
    const { bodies, progress } = setup();
    progress.set(0.8);
    TestBed.tick();
    progress.set(0.31234);
    TestBed.tick();
    await advance(REPORT_INTERVAL_MS);

    expect(bodies().at(-1)).toMatchObject({ percent: 80, lastPosition: '0.3123' });
  });

  it('stops counting 60 s after the last interaction and skips ticks with nothing new', async () => {
    const { seconds } = setup();
    await advance(ACTIVE_WINDOW_MS + 30_000); // ticks at 15, 30, 45, 60, 75 and 90 s

    expect(seconds()).toEqual([0, 15, 15, 15, 15]);

    await advance(10_000); // t = 100 s
    interact('keydown');
    await advance(5_000); // tick at 105 s
    expect(seconds()).toEqual([0, 15, 15, 15, 15, 5]);
  });

  it('counts each kind of interaction', async () => {
    const { seconds } = setup();
    await advance(ACTIVE_WINDOW_MS + 15_000);
    for (const type of ['scroll', 'wheel', 'pointermove', 'touchstart']) {
      const before = seconds().length;
      interact(type);
      await advance(REPORT_INTERVAL_MS);
      expect(seconds().length).toBe(before + 1);
      expect(seconds().at(-1)).toBe(15);
    }
  });

  it('counts nothing while the tab is hidden and reports when it hides', async () => {
    const { api, seconds } = setup();
    await advance(20_000); // a report at 15 s
    setVisibility('hidden');
    await advance(0);

    expect(seconds()).toEqual([0, 15, 5]);
    expect(api.progress.mock.calls.at(-1)?.[2]).toEqual({ keepalive: true });

    await advance(40_000); // still hidden at 60 s: nothing to send
    expect(seconds()).toHaveLength(3);

    setVisibility('visible');
    interact();
    await advance(REPORT_INTERVAL_MS); // tick at 75 s
    expect(seconds()).toEqual([0, 15, 5, 15]);
  });

  it('flushes the last seconds when the reader is closed, then stops', async () => {
    const { reader, seconds } = setup();
    await advance(7_000);
    reader.destroy();
    await advance(0);
    expect(seconds()).toEqual([0, 7]);

    interact();
    await advance(60_000);
    expect(seconds()).toEqual([0, 7]);
  });

  it('keeps the seconds of a failed report for the next one', async () => {
    const { seconds } = setup({ replies: [ok, () => fail(503, 'server.error'), () => fail(409, 'reading.conflict'), () => fail(0, 'network')] });
    interact();
    await advance(REPORT_INTERVAL_MS * 3);
    interact();
    await advance(REPORT_INTERVAL_MS);

    expect(seconds()).toEqual([0, 15, 30, 45, 60]);
  });

  it('stops for good on 404', async () => {
    const { seconds } = setup({ replies: [ok, () => fail(404, 'article.not_found')] });
    await advance(REPORT_INTERVAL_MS);
    expect(seconds()).toEqual([0, 15]);

    interact();
    await advance(60_000);
    setVisibility('hidden');
    await advance(0);
    expect(seconds()).toEqual([0, 15]);
  });

  it('stops for good on 401', async () => {
    const { seconds, reader } = setup({ replies: [() => fail(401, 'auth.unauthorized')] });
    await advance(0);
    interact();
    await advance(60_000);
    reader.destroy();
    await advance(0);
    expect(seconds()).toEqual([0]);
  });

  it('keeps one report in flight at a time', async () => {
    const first = new Subject<ReadingProgressResultDto>();
    const { seconds } = setup({ replies: [() => first] });
    await advance(REPORT_INTERVAL_MS * 2); // ticks at 15 and 30 s wait
    expect(seconds()).toEqual([0]);

    first.next({ percent: 0, completed: false, completedNow: false, streak: null, milestone: null });
    first.complete();
    await advance(REPORT_INTERVAL_MS); // tick at 45 s sends everything so far
    expect(seconds()).toEqual([0, 45]);
  });

  it('sends a flush once the report in flight has answered', async () => {
    const first = new Subject<ReadingProgressResultDto>();
    const { reader, seconds } = setup({ replies: [() => first] });
    await advance(5_000);
    reader.destroy();
    await advance(0);
    expect(seconds()).toEqual([0]);

    first.error(new ApiError(0, 'network', null));
    await advance(0);
    expect(seconds()).toEqual([0, 5]);
  });

  it('never reports for guests, and starts once the user signs in', async () => {
    const { api, session, seconds } = setup({ signedIn: false });
    interact();
    await advance(60_000);
    expect(api.progress).not.toHaveBeenCalled();

    session.setMe(testMe());
    TestBed.tick();
    await advance(0);
    expect(seconds()).toEqual([0]);
  });

  it('ends the session without a report when the user signs out', async () => {
    const { session, seconds } = setup();
    await advance(10_000);
    session.setGuest();
    TestBed.tick();
    await advance(60_000);
    expect(seconds()).toEqual([0]);
  });

  it('waits while held (the reader is resuming your position), then reports from where you are', async () => {
    const held = signal(true);
    const { bodies, progress } = setup({ hold: held });
    await advance(REPORT_INTERVAL_MS * 2);
    expect(bodies()).toEqual([]);

    // Resumed at 45%: the first report keeps that position instead of saving the top over it.
    progress.set(0.45);
    held.set(false);
    TestBed.tick();
    await advance(0);
    expect(bodies()).toEqual([{ language: 'ar-EG', percent: 45, lastPosition: '0.4500', activeSecondsDelta: 0 }]);

    await advance(REPORT_INTERVAL_MS);
    expect(bodies()[1]).toMatchObject({ percent: 45, lastPosition: '0.4500', activeSecondsDelta: 15 });
  });

  it('starts a new session for another language of the article', async () => {
    const { article, bodies } = setup();
    await advance(4_000);
    article.set({ id: 'a1', language: 'en' });
    TestBed.tick();
    await advance(0);

    expect(bodies().map((b) => [b.language, b.activeSecondsDelta])).toEqual([
      ['ar-EG', 0],
      ['ar-EG', 4],
      ['en', 0],
    ]);
  });

  it('updates the streak and celebrates a milestone when a report completes the article', async () => {
    const streak: StreakDto = { ...STREAK, current: 7, longest: 7, readToday: true };
    const { progress, sheets } = setup({ replies: [ok, () => ok({ percent: 90, completed: true, completedNow: true, streak, milestone: 7 })] });
    await advance(0);
    expect(TestBed.inject(StreakStore).streak()).toEqual(STREAK);

    progress.set(0.9);
    TestBed.tick();
    await advance(REPORT_INTERVAL_MS);

    expect(TestBed.inject(StreakStore).streak()).toEqual(streak);
    expect(sheets.celebrate).toHaveBeenCalledExactlyOnceWith(7);
  });

  it('keeps reporting after the article is read', async () => {
    const { seconds } = setup({ replies: [ok, () => ok({ completed: true, completedNow: true, streak: STREAK })] });
    interact();
    await advance(REPORT_INTERVAL_MS * 2);
    expect(seconds()).toEqual([0, 15, 15]);
  });
});

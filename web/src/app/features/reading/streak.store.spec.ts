import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Observable, Subject, of, throwError } from 'rxjs';
import { ApiError } from '../../core/api/api.config';
import { ReadingProgressResultDto, ReadingStatsDto, StreakDto } from '../../core/api/models';
import { ReadingApi } from '../../core/api/reading.api';
import { SessionStore } from '../../core/auth/session.store';
import { testMe } from '../../../testing/auth-testing';
import { StreakStore } from './streak.store';

function streak(patch: Partial<StreakDto> = {}): StreakDto {
  return { current: 4, longest: 9, readToday: false, freezeAvailable: true, freezePending: false, today: '2026-11-03', ...patch };
}

function stats(patch: Partial<StreakDto> = {}): ReadingStatsDto {
  return {
    streak: streak(patch),
    totalArticles: 20,
    minutesRead: 140,
    articlesThisWeek: 3,
    minutesThisWeek: 21,
    articlesThisMonth: 11,
    topFields: [],
  };
}

function result(patch: Partial<ReadingProgressResultDto> = {}): ReadingProgressResultDto {
  return { percent: 80, completed: true, completedNow: true, streak: streak({ current: 5, readToday: true }), milestone: null, ...patch };
}

function setup(options: { stats?: () => Observable<ReadingStatsDto>; platform?: string } = {}) {
  const api = { stats: vi.fn(options.stats ?? (() => of(stats()))) };
  TestBed.configureTestingModule({
    providers: [
      { provide: ReadingApi, useValue: api },
      { provide: PLATFORM_ID, useValue: options.platform ?? 'browser' },
    ],
  });
  const session = TestBed.inject(SessionStore);
  const store = TestBed.inject(StreakStore);
  TestBed.tick();
  return { api, session, store };
}

const flush = () => new Promise<void>((resolve) => setTimeout(resolve, 0));

describe('StreakStore', () => {
  beforeEach(() => TestBed.resetTestingModule());

  it('loads the streak when a user signs in', async () => {
    const { api, session, store } = setup();
    expect(api.stats).not.toHaveBeenCalled();

    session.setMe(testMe());
    TestBed.tick();
    await flush();

    expect(api.stats).toHaveBeenCalledTimes(1);
    expect(store.streak()).toEqual(streak());
  });

  it('re-reads a stale streak when the user comes back, after midnight or 15 minutes', async () => {
    const { api, session, store } = setup();
    session.setMe(testMe());
    TestBed.tick();
    await flush();
    const loadedAt = new Date(2026, 10, 3, 22, 0);
    await store.load(loadedAt);
    api.stats.mockClear();

    await store.refreshIfStale(new Date(2026, 10, 3, 22, 5));
    expect(api.stats).not.toHaveBeenCalled();

    await store.refreshIfStale(new Date(2026, 10, 3, 22, 15));
    expect(api.stats).toHaveBeenCalledTimes(1);

    await store.refreshIfStale(new Date(2026, 10, 4, 0, 1)); // a new day, only minutes later
    expect(api.stats).toHaveBeenCalledTimes(2);
  });

  it('never loads for guests', async () => {
    const { api, session, store } = setup();
    session.setGuest();
    TestBed.tick();
    await flush();

    expect(api.stats).not.toHaveBeenCalled();
    expect(store.streak()).toBeNull();
  });

  it('forgets the streak on sign out and loads the next account’s', async () => {
    const { api, session, store } = setup();
    session.setMe(testMe());
    TestBed.tick();
    await flush();

    session.setGuest();
    TestBed.tick();
    expect(store.streak()).toBeNull();

    api.stats.mockReturnValue(of(stats({ current: 1 })));
    session.setMe(testMe({ id: 'user-2' }));
    TestBed.tick();
    await flush();
    expect(store.streak()?.current).toBe(1);
  });

  it('does not reload when the same user’s profile changes', async () => {
    const { api, session } = setup();
    session.setMe(testMe());
    TestBed.tick();
    await flush();

    session.patchMe({ displayName: 'Mona A.' });
    TestBed.tick();
    expect(api.stats).toHaveBeenCalledTimes(1);
  });

  it('keeps "—" when the stats fail to load', async () => {
    const { session, store } = setup({ stats: () => throwError(() => new ApiError(503, 'server.error', null)) });
    session.setMe(testMe());
    TestBed.tick();
    await flush();
    expect(store.streak()).toBeNull();
  });

  it('drops a load that answers after the user signed out', async () => {
    const pending = new Subject<ReadingStatsDto>();
    const { session, store } = setup({ stats: () => pending });
    session.setMe(testMe());
    TestBed.tick();

    session.setGuest();
    TestBed.tick();
    pending.next(stats());
    pending.complete();
    await flush();

    expect(store.streak()).toBeNull();
  });

  it('takes the streak of a report that completed an article', async () => {
    const { session, store } = setup();
    session.setMe(testMe());
    TestBed.tick();
    await flush();

    store.applyProgress(result({ completedNow: false, streak: null }));
    expect(store.streak()?.current).toBe(4);

    store.applyProgress(result());
    expect(store.streak()).toEqual(streak({ current: 5, readToday: true }));
  });

  it('lets a fresher streak win over a load still in flight', async () => {
    const pending = new Subject<ReadingStatsDto>();
    const { session, store } = setup({ stats: () => pending });
    session.setMe(testMe());
    TestBed.tick();

    store.applyProgress(result());
    pending.next(stats({ current: 4 }));
    pending.complete();
    await flush();

    expect(store.streak()?.current).toBe(5);
  });

  it('ignores updates for guests', () => {
    const { store } = setup();
    store.applyProgress(result());
    store.setStreak(streak());
    expect(store.streak()).toBeNull();
  });

  it('does nothing during SSR', async () => {
    const { api, session, store } = setup({ platform: 'server' });
    session.setMe(testMe());
    TestBed.tick();
    await flush();

    expect(api.stats).not.toHaveBeenCalled();
    expect(store.streak()).toBeNull();
  });
});

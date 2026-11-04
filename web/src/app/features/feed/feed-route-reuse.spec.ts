import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { ActivatedRouteSnapshot, DetachedRouteHandle, Route, Router } from '@angular/router';
import { testMe } from '../../../testing/auth-testing';
import { SessionStore } from '../../core/auth/session.store';
import { FeedMemory } from './feed-memory';
import { FeedRouteReuse } from './feed-route-reuse';

const HOME: Route = { path: '', data: { keepOnBack: true } };
const READER: Route = { path: 'reader' };

function snapshot(config: Route, params: Record<string, string> = {}): ActivatedRouteSnapshot {
  return { routeConfig: config, data: config.data ?? {}, params } as unknown as ActivatedRouteSnapshot;
}

function handle() {
  const destroy = vi.fn();
  return { destroy, handle: { componentRef: { destroy }, route: { value: {} } } as unknown as DetachedRouteHandle };
}

describe('FeedRouteReuse (F34)', () => {
  let trigger: 'imperative' | 'popstate' = 'popstate';

  function setup(platform = 'browser') {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({
      providers: [
        { provide: PLATFORM_ID, useValue: platform },
        { provide: Router, useValue: { currentNavigation: () => ({ trigger }) } },
      ],
    });
    TestBed.inject(SessionStore).setGuest();
    return TestBed.inject(FeedRouteReuse);
  }

  beforeEach(() => (trigger = 'popstate'));

  it('keeps Home (routes with keepOnBack) while you read, and never on the server', () => {
    expect(setup().shouldDetach(snapshot(HOME))).toBe(true);
    expect(setup().shouldDetach(snapshot(READER))).toBe(false);
    expect(setup('server').shouldDetach(snapshot(HOME))).toBe(false);
  });

  it('Back gives the same page back; it is then no longer kept', () => {
    const strategy = setup();
    const kept = handle();
    strategy.store(snapshot(HOME), kept.handle);
    expect(strategy.shouldAttach(snapshot(HOME))).toBe(true);
    expect(strategy.retrieve(snapshot(HOME))).toBe(kept.handle);
    strategy.store(snapshot(HOME), null);
    expect(strategy.shouldAttach(snapshot(HOME))).toBe(false);
    expect(kept.destroy).not.toHaveBeenCalled();
  });

  it('any other way back (a link, the nav) builds a fresh page and drops the kept one', () => {
    const strategy = setup();
    const kept = handle();
    strategy.store(snapshot(HOME), kept.handle);
    trigger = 'imperative';
    expect(strategy.shouldAttach(snapshot(HOME))).toBe(false);
    expect(kept.destroy).toHaveBeenCalled();
    expect(strategy.retrieve(snapshot(HOME))).toBeNull();
  });

  it('a page kept for another account is dropped (you signed in meanwhile)', () => {
    const strategy = setup();
    const kept = handle();
    strategy.store(snapshot(HOME), kept.handle);
    TestBed.inject(SessionStore).setMe(testMe());
    expect(strategy.shouldAttach(snapshot(HOME))).toBe(false);
    expect(kept.destroy).toHaveBeenCalled();
  });

  it('another address of the same route is another page', () => {
    const strategy = setup();
    const profile: Route = { path: 'profile', data: { keepOnBack: true } };
    strategy.store(snapshot(profile, { username: 'mona' }), handle().handle);
    expect(strategy.shouldAttach(snapshot(profile, { username: 'karim' }))).toBe(false);
    expect(strategy.shouldAttach(snapshot(profile, { username: 'mona' }))).toBe(true);
  });

  it('keeps at most 3 pages, dropping the oldest', () => {
    const strategy = setup();
    const pages = [1, 2, 3, 4].map((i) => ({ config: { path: `p${i}`, data: { keepOnBack: true } } as Route, kept: handle() }));
    for (const { config, kept } of pages) strategy.store(snapshot(config), kept.handle);
    expect(pages[0].kept.destroy).toHaveBeenCalled();
    expect(strategy.shouldAttach(snapshot(pages[0].config))).toBe(false);
    expect(strategy.shouldAttach(snapshot(pages[3].config))).toBe(true);
  });
});

describe('FeedMemory (F34)', () => {
  beforeEach(() => {
    TestBed.resetTestingModule();
    sessionStorage.clear();
    TestBed.configureTestingModule({ providers: [{ provide: PLATFORM_ID, useValue: 'browser' }] });
  });

  it('keeps unsent comment text for the tab, and forgets it once empty', () => {
    const memory = TestBed.inject(FeedMemory);
    memory.setDraft('user-1|a1', 'نص لسه متبعتش');
    expect(memory.draft('user-1|a1')).toBe('نص لسه متبعتش');
    expect(memory.draft('user-2|a1')).toBe('');
    // A reload of the tab finds it again.
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({ providers: [{ provide: PLATFORM_ID, useValue: 'browser' }] });
    const reloaded = TestBed.inject(FeedMemory);
    expect(reloaded.draft('user-1|a1')).toBe('نص لسه متبعتش');
    reloaded.setDraft('user-1|a1', '  ');
    expect(JSON.parse(sessionStorage.getItem('rdCommentDrafts')!)).toEqual([]);
  });

  it('the card to come back to is used once, by its own article, and expires', () => {
    const memory = TestBed.inject(FeedMemory);
    memory.rememberReturn('a1', true);
    expect(memory.takeReturn('a2')).toBeNull();
    expect(memory.takeReturn('a1')).toMatchObject({ articleId: 'a1', comments: true });
    expect(memory.takeReturn('a1')).toBeNull();

    vi.useFakeTimers();
    try {
      memory.rememberReturn('a1', false);
      vi.advanceTimersByTime(16 * 60_000);
      expect(memory.takeReturn('a1')).toBeNull();
      expect(memory.pendingReturn()).toBeNull();
    } finally {
      vi.useRealTimers();
    }
  });
});

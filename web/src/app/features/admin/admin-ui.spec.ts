import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Subject } from 'rxjs';
import { TEST_API, setupSocialTesting } from '../../../testing/social-testing';
import { AdminApi, adminParams } from '../../core/api/admin.api';
import { PagedList } from '../../core/api/models';
import { ADMIN_SECTIONS, sectionOf, visibleSections } from './admin-nav';
import { PagedState, boolParam, dateParam, oneOf, pageParam } from './admin-ui';

const page = <T>(items: T[], patch: Partial<PagedList<T>> = {}): PagedList<T> => ({ items, page: 1, pageSize: 50, totalCount: items.length, totalPages: 1, ...patch });

describe('admin console helpers (F23)', () => {
  it('the side menu shows each section only with its permission, in the SPEC order', () => {
    expect(ADMIN_SECTIONS.map((s) => s.id)).toEqual(['dashboard', 'users', 'content', 'reports', 'tickets', 'verification', 'taxonomy', 'paths', 'announcements', 'audit', 'system']);
    expect(visibleSections(new Set(['admin.access'])).map((s) => s.id)).toEqual(['dashboard']);
    expect(visibleSections(new Set(['admin.access', 'moderation.manage', 'articles.feature'])).map((s) => s.id)).toEqual(['dashboard', 'content', 'reports', 'paths']);
    expect(visibleSections(new Set()).length).toBe(0);
  });

  it('finds the section of a URL (the longest path wins; query and hash ignored)', () => {
    expect(sectionOf('/admin')?.id).toBe('dashboard');
    expect(sectionOf('/admin?period=7d')?.id).toBe('dashboard');
    expect(sectionOf('/admin/users/u-1')?.id).toBe('users');
    expect(sectionOf('/admin/reports/article/a-1#x')?.id).toBe('reports');
    expect(sectionOf('/explore')).toBeNull();
  });

  it('reads URL parameters strictly', () => {
    expect([pageParam(undefined), pageParam('0'), pageParam('3'), pageParam('2.5'), pageParam('x')]).toEqual([1, 1, 3, 1, 1]);
    expect([dateParam('2026-11-07'), dateParam('7/11/2026'), dateParam(undefined)]).toEqual(['2026-11-07', null, null]);
    expect([boolParam('true'), boolParam('false'), boolParam('yes')]).toEqual([true, false, null]);
    expect([oneOf('asc', ['asc', 'desc'] as const), oneOf('up', ['asc', 'desc'] as const)]).toEqual(['asc', null]);
  });

  it('builds admin query strings without the empty values (false stays: it is a filter)', () => {
    const params = adminParams({ q: '+201001234567', status: null, verified: false, page: 2, method: undefined, sort: '' });
    expect(params.keys()).toEqual(['q', 'verified', 'page']);
    // `+` must reach the API as %2B (contract).
    expect(params.toString()).toBe('q=%2B201001234567&verified=false&page=2');
  });

  it('PagedState: the newer load wins; a reload keeps the rows on screen; rows can be updated', async () => {
    const replies: Subject<PagedList<{ id: string; n: number }>>[] = [];
    const state = new PagedState(() => {
      const reply = new Subject<PagedList<{ id: string; n: number }>>();
      replies.push(reply);
      return reply;
    });
    const first = state.load();
    expect(state.status()).toBe('loading');
    replies[0].next(page([{ id: 'a', n: 1 }], { totalCount: 120, totalPages: 3, page: 2 }));
    replies[0].complete();
    await first;
    expect(state.items().length).toBe(1);
    expect([state.page(), state.totalPages(), state.totalCount()]).toEqual([2, 3, 120]);

    const older = state.load();
    const newer = state.load();
    expect(state.status()).toBe('loaded');
    expect(state.refreshing()).toBe(true);
    replies[2].next(page([{ id: 'new', n: 2 }]));
    replies[2].complete();
    replies[1].next(page([{ id: 'old', n: 3 }]));
    replies[1].complete();
    await Promise.all([older, newer]);
    expect(state.items().map((i) => i.id)).toEqual(['new']);
    expect(state.refreshing()).toBe(false);

    state.update((i) => i.id === 'new', (i) => ({ ...i, n: 9 }));
    expect(state.items()[0].n).toBe(9);
  });
});

describe('AdminApi (F23)', () => {
  let http: HttpTestingController;
  let api: AdminApi;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
    api = TestBed.inject(AdminApi);
  });

  afterEach(() => http.verify());

  it('calls the contract routes', () => {
    api.users({ q: 'mona', hasReports: true, sort: 'lastSeen', dir: 'asc', page: 2, pageSize: 50 }).subscribe();
    const users = http.expectOne((r) => r.url === `${TEST_API}/admin/users`);
    expect(users.request.params.toString()).toBe('q=mona&hasReports=true&sort=lastSeen&dir=asc&page=2&pageSize=50');
    users.flush(page([]));

    api.dashboard('7d').subscribe();
    http.expectOne(`${TEST_API}/admin/dashboard?period=7d`).flush({});

    api.feature('a 1').subscribe();
    expect(http.expectOne(`${TEST_API}/admin/articles/a%201/featured`).request.method).toBe('PUT');
    api.unfeature('a1').subscribe();
    expect(http.expectOne(`${TEST_API}/admin/articles/a1/featured`).request.method).toBe('DELETE');

    api.setTagHidden('t1', true).subscribe();
    expect(http.expectOne(`${TEST_API}/admin/tags/t1/hidden`).request.method).toBe('PUT');
    api.setTagHidden('t1', false).subscribe();
    expect(http.expectOne(`${TEST_API}/admin/tags/t1/hidden`).request.method).toBe('DELETE');

    api.mergeTag('t1', 't2').subscribe();
    expect(http.expectOne(`${TEST_API}/admin/tags/t1/merge`).request.body).toEqual({ intoTagId: 't2' });

    api.reorderTopics('f1', ['b', 'a']).subscribe();
    expect(http.expectOne(`${TEST_API}/admin/fields/f1/topics/order`).request.body).toEqual({ ids: ['b', 'a'] });

    api.setFeaturedPaths([]).subscribe();
    expect(http.expectOne(`${TEST_API}/admin/paths/featured`).request.body).toEqual({ pathIds: [] });

    api.logoutAll('u1').subscribe();
    expect(http.expectOne(`${TEST_API}/admin/users/u1/logout-all`).request.method).toBe('POST');
  });
});

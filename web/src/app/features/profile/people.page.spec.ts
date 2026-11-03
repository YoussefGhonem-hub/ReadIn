import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { testProfile } from '../../../testing/profile-testing';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { UserSummaryDto } from '../../core/api/models';
import { PEOPLE_SEARCH_DEBOUNCE_MS, PeoplePage } from './people.page';

function person(i: number, patch: Partial<UserSummaryDto> = {}): UserSummaryDto {
  return { id: `u${i}`, displayName: `Reader ${i}`, username: `reader_${i}`, avatarUrl: null, isVerified: false, bio: null, isFollowing: false, followsYou: false, ...patch };
}

const isList = (list: string) => (r: { url: string }) => r.url === `${TEST_API}/users/writer-1/${list}`;

describe('PeoplePage (F12, F14)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
  });

  afterEach(() => {
    vi.useRealTimers();
    http.verify();
  });

  async function render(list: 'followers' | 'following' = 'followers') {
    const fixture = TestBed.createComponent(PeoplePage);
    fixture.componentRef.setInput('username', 'karim');
    fixture.componentRef.setInput('list', list);
    fixture.detectChanges();
    http.expectOne(`${TEST_API}/users/karim`).flush(testProfile());
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
    };
    await stable();
    return { fixture, root, stable, rows: () => root.querySelectorAll('[data-person]') };
  }

  it('lists followers with a Follow button and "Follows you", and loads more pages', async () => {
    const { root, rows, stable, fixture } = await render();
    const first: TestRequest = http.expectOne(isList('followers'));
    expect(first.request.params.get('limit')).toBe('20');
    first.flush({ items: Array.from({ length: 20 }, (_, i) => person(i, { followsYou: i === 0 })), nextCursor: '20' });
    await stable();
    expect(rows()).toHaveLength(20);
    expect(rows()[0].querySelector('[data-follow]')).not.toBeNull();
    expect(rows()[0].textContent).toContain('بيتابعك');
    expect(rows()[0].querySelector('a')!.getAttribute('href')).toBe('/@reader_0');
    expect(root.querySelector('[data-people-list="followers"]')!.getAttribute('aria-current')).toBe('page');

    // What the infinite scroll calls near the end.
    void (fixture.componentInstance as unknown as { store: { loadMore(): Promise<void> } }).store.loadMore();
    const more = http.expectOne(isList('followers'));
    expect(more.request.params.get('cursor')).toBe('20');
    more.flush({ items: [person(19), person(20)], nextCursor: null });
    await stable();
    expect(rows()).toHaveLength(21); // the repeated row is dropped
    expect(root.querySelector('[data-people]')!.textContent).toContain('دول كل الناس');
  });

  it('searches after a pause in typing; nothing found says so', async () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    const { root, stable } = await render();
    http.expectOne(isList('followers')).flush({ items: [person(1)], nextCursor: null });
    await stable();
    const input = root.querySelector<HTMLInputElement>('[data-people-search]')!;
    for (const value of ['n', 'no', 'nou']) {
      input.value = value;
      input.dispatchEvent(new Event('input'));
    }
    vi.advanceTimersByTime(PEOPLE_SEARCH_DEBOUNCE_MS - 1);
    http.expectNone(isList('followers'));
    vi.advanceTimersByTime(1);
    const req = http.expectOne(isList('followers'));
    expect(req.request.params.get('q')).toBe('nou');
    req.flush({ items: [], nextCursor: null });
    await stable();
    expect(root.querySelector('[data-people-no-results]')!.textContent).toContain('«nou»');

    // Clearing the box shows everyone again at once.
    input.value = '';
    input.dispatchEvent(new Event('input'));
    http.expectOne((r) => isList('followers')(r) && !r.params.has('q')).flush({ items: [person(1)], nextCursor: null });
  });

  it('an empty Following list, and a failed load with retry', async () => {
    const { root, stable } = await render('following');
    http.expectOne(isList('following')).flush({ items: [], nextCursor: null });
    await stable();
    expect(root.querySelector('[data-people-empty]')!.textContent).toContain('لسه مش بيتابع حد');
    expect(root.querySelector('h1')!.textContent).toContain('بيتابعهم');
  });

  it('a failed load offers a retry', async () => {
    const { root, stable, rows } = await render();
    http.expectOne(isList('followers')).flush(null, { status: 500, statusText: 'Error' });
    await stable();
    (root.querySelector('rd-error-state button') as HTMLElement).click();
    http.expectOne(isList('followers')).flush({ items: [person(1)], nextCursor: null });
    await stable();
    expect(rows()).toHaveLength(1);
  });
});

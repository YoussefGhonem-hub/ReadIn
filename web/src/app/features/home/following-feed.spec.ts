import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { UserSummaryDto } from '../../core/api/models';
import { FollowingFeed } from './following-feed';
import { HomeStore } from './home.store';

@Component({
  selector: 'rd-host',
  imports: [FollowingFeed],
  providers: [HomeStore],
  template: `<rd-following-feed />`,
})
class Host {}

function writer(id: string, patch: Partial<UserSummaryDto> = {}): UserSummaryDto {
  return { id, displayName: `Writer ${id}`, username: id, avatarUrl: null, isVerified: true, bio: 'Backend engineer.', isFollowing: false, followsYou: false, ...patch };
}

describe('Home → Following (F12)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
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
    http.verify();
  });

  async function render() {
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const store = fixture.debugElement.children[0].injector.get(HomeStore);
    void store.openFollowing();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks(10);
      fixture.detectChanges();
      await fixture.whenStable();
    };
    return { fixture, root, stable, store };
  }

  it('shows articles by people you follow', async () => {
    const { root, stable } = await render();
    const req = http.expectOne((r) => r.url === `${TEST_API}/feed/following`);
    expect(req.request.params.get('limit')).toBe('20');
    req.flush({ items: [testCard(), testCard({ id: 'a2', slug: 'b', title: 'Second' })], nextCursor: null });
    await stable();
    expect(root.querySelectorAll('rd-article-card').length).toBe(2);
    expect(root.querySelector('[data-following-empty]')).toBeNull();
  });

  it('an empty feed suggests writers; following one offers to show the feed', async () => {
    const { root, stable } = await render();
    http.expectOne((r) => r.url === `${TEST_API}/feed/following`).flush({ items: [], nextCursor: null });
    await stable();
    const suggested = http.expectOne((r) => r.url === `${TEST_API}/users/suggested`);
    expect(suggested.request.params.get('limit')).toBe('10');
    suggested.flush([writer('karim'), writer('salma', { isVerified: false, followsYou: true })]);
    await stable();

    expect(root.querySelector('[data-following-empty]')!.textContent).toContain('لسه مفيش مقالات من اللي بتتابعهم');
    const rows = root.querySelectorAll('[data-suggested-writer]');
    expect(rows.length).toBe(2);
    expect(rows[1].textContent).toContain('بيتابعك');
    expect(root.querySelector('[data-following-refresh]')).toBeNull();

    (rows[0].querySelector('[data-follow]') as HTMLElement).click();
    await stable();
    expect(rows[0].querySelector('[data-follow]')!.getAttribute('aria-pressed')).toBe('true');
    http.expectOne(`${TEST_API}/users/karim/follow`).flush({ isFollowing: true, followerCount: 1 });
    await stable();

    (root.querySelector('[data-following-refresh]') as HTMLElement).click();
    http.expectOne((r) => r.url === `${TEST_API}/feed/following`).flush({ items: [testCard()], nextCursor: null });
    await stable();
    expect(root.querySelectorAll('rd-article-card').length).toBe(1);
  });

  it('an error offers a retry', async () => {
    const { root, stable } = await render();
    http.expectOne((r) => r.url === `${TEST_API}/feed/following`).flush(null, { status: 500, statusText: 'Error' });
    await stable();
    (root.querySelector('rd-error-state button') as HTMLElement).click();
    http.expectOne((r) => r.url === `${TEST_API}/feed/following`).flush({ items: [testCard()], nextCursor: null });
    await stable();
    expect(root.querySelectorAll('rd-article-card').length).toBe(1);
  });
});

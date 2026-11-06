import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testMe } from '../../../testing/auth-testing';
import { testProfile } from '../../../testing/profile-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { SessionStore } from '../../core/auth/session.store';
import { PROFILE_CARD_TTL_MS, ProfileCardCache } from './profile-card.cache';

const KARIM = `${TEST_API}/users/karim`;

describe('ProfileCardCache (the hover card)', () => {
  let http: HttpTestingController;
  let session: SessionStore;
  let cache: ProfileCardCache;
  let clock: number;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http, session } = setupSocialTesting());
    cache = TestBed.inject(ProfileCardCache);
    clock = 1_000_000;
    cache.now = () => clock;
    TestBed.tick(); // the account effect knows the viewer
  });

  afterEach(() => http.verify());

  it('shares a request on its way, whatever the case or a leading @', async () => {
    const first = cache.get('karim');
    const second = cache.get('@Karim');
    expect(cache.peek('karim')).toBeNull(); // nothing to draw yet
    http.expectOne(KARIM).flush(testProfile());
    await expect(first).resolves.toMatchObject({ username: 'karim' });
    await expect(second).resolves.toMatchObject({ username: 'karim' });
    expect(cache.peek('KARIM')).toMatchObject({ displayName: 'Karim Hassan' });
  });

  it('keeps a profile about 2 minutes, then asks again', async () => {
    const first = cache.get('karim');
    http.expectOne(KARIM).flush(testProfile());
    await first;

    clock += PROFILE_CARD_TTL_MS - 1;
    await cache.get('karim');
    http.expectNone(KARIM);
    expect(cache.peek('karim')).not.toBeNull();

    clock += 1;
    expect(cache.peek('karim')).toBeNull();
    const again = cache.get('karim');
    http.expectOne(KARIM).flush(testProfile({ stats: { articles: 13, followers: 341, following: 21, totalReads: 5200 } }));
    await expect(again).resolves.toMatchObject({ stats: { followers: 341 } });
  });

  it('a request on its way is never stale, however long it takes', async () => {
    const first = cache.get('karim');
    clock += PROFILE_CARD_TTL_MS * 3;
    const second = cache.get('karim');
    http.expectOne(KARIM).flush(testProfile());
    await Promise.all([first, second]);
  });

  it("doesn't keep a failure: the next card asks again", async () => {
    const failed = cache.get('ghost');
    http.expectOne(`${TEST_API}/users/ghost`).flush(problem(404, 'user.not_found'), { status: 404, statusText: 'Not Found' });
    await expect(failed).rejects.toMatchObject({ status: 404 });
    await flushMicrotasks();

    const again = cache.get('ghost');
    http.expectOne(`${TEST_API}/users/ghost`).flush(testProfile({ username: 'ghost' }));
    await expect(again).resolves.toMatchObject({ username: 'ghost' });
  });

  it('keeps profiles per viewer, and drops them all when the account changes', async () => {
    const mine = cache.get('karim');
    http.expectOne(KARIM).flush(testProfile({ isFollowing: true }));
    await mine;

    // Signed out: the follow state above was someone else's.
    session.setGuest();
    expect(cache.peek('karim')).toBeNull();
    const asGuest = cache.get('karim');
    http.expectOne(KARIM).flush(testProfile({ isFollowing: false }));
    await expect(asGuest).resolves.toMatchObject({ isFollowing: false });
    TestBed.tick();

    // Back as the same account: the old copy was dropped with the switch.
    session.setMe(testMe());
    TestBed.tick();
    expect(cache.peek('karim')).toBeNull();
    const back = cache.get('karim');
    http.expectOne(KARIM).flush(testProfile({ isFollowing: true }));
    await expect(back).resolves.toMatchObject({ isFollowing: true });
  });
});

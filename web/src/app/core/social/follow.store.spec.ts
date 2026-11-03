import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { FollowStore } from './follow.store';

const URL = `${TEST_API}/users/writer-1/follow`;

describe('FollowStore (F12)', () => {
  let http: HttpTestingController;
  let store: FollowStore;
  let toasts: ToastService;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http, toasts } = setupSocialTesting());
    store = TestBed.inject(FollowStore);
    TestBed.tick();
  });

  afterEach(() => http.verify());

  it('follows at once and keeps it when the API confirms', async () => {
    const done = store.toggle('writer-1', false);
    expect(store.isFollowing('writer-1', false)).toBe(true);
    const req = http.expectOne(URL);
    expect(req.request.method).toBe('PUT');
    req.flush({ isFollowing: true, followerCount: 861 });
    await done;
    expect(store.isFollowing('writer-1', false)).toBe(true);
  });

  it('unfollows with DELETE', async () => {
    const done = store.toggle('writer-1', true);
    expect(store.isFollowing('writer-1', true)).toBe(false);
    const req = http.expectOne(URL);
    expect(req.request.method).toBe('DELETE');
    req.flush({ isFollowing: false, followerCount: 860 });
    await done;
    expect(store.isFollowing('writer-1', true)).toBe(false);
  });

  it('rolls back with the translated error', async () => {
    const done = store.toggle('writer-1', false);
    http.expectOne(URL).flush(problem(400, 'follow.self'), { status: 400, statusText: 'Bad Request' });
    await done;
    expect(store.isFollowing('writer-1', false)).toBe(false);
    expect(toasts.toasts().map((t) => t.message)).toEqual(['مينفعش تتابع نفسك.']);
  });

  it('follow → unfollow while the first request runs ends unfollowed, one request at a time', async () => {
    void store.toggle('writer-1', false);
    void store.toggle('writer-1', false);
    expect(store.isFollowing('writer-1', false)).toBe(false);
    http.expectOne(URL).flush({ isFollowing: true, followerCount: 861 });
    await flushMicrotasks();
    const second = http.expectOne(URL);
    expect(second.request.method).toBe('DELETE');
    second.flush({ isFollowing: false, followerCount: 860 });
    await flushMicrotasks();
    expect(store.isFollowing('writer-1', false)).toBe(false);
  });

  it('a fresh API value replaces local state', async () => {
    const done = store.toggle('writer-1', false);
    http.expectOne(URL).flush({ isFollowing: true, followerCount: 861 });
    await done;
    store.absorb('writer-1', false); // e.g. unfollowed on another device, then the reader reloaded
    expect(store.isFollowing('writer-1', true)).toBe(false);
  });
});

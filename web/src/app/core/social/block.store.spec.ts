import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { SessionStore } from '../auth/session.store';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { BlockStore, BlockedPersonRef } from './block.store';
import { FollowStore } from './follow.store';
import { MuteStore } from './mute.store';

const OMAR: BlockedPersonRef = { id: 'writer-2', displayName: 'Omar', username: 'omar' };
const URL = `${TEST_API}/users/writer-2/block`;

describe('BlockStore (F36)', () => {
  let http: HttpTestingController;
  let store: BlockStore;
  let toasts: ToastService;
  let session: SessionStore;

  beforeEach(() => {
    TestBed.resetTestingModule();
    const setup = setupSocialTesting();
    http = setup.http;
    toasts = setup.toasts;
    session = setup.session;
    store = TestBed.inject(BlockStore);
  });
  afterEach(() => http.verify());

  it('starts from what the page knows, and a block shows at once (before the API answers)', async () => {
    expect(store.isBlocked('writer-2')).toBe(false);
    expect(store.isBlocked('writer-2', true)).toBe(true);

    const done = store.block(OMAR);
    expect(store.isBlocked('writer-2')).toBe(true);
    const put = http.expectOne(URL);
    expect(put.request.method).toBe('PUT');
    put.flush({ userId: 'writer-2', isBlocked: true, followRemoved: false });
    expect(await done).toBe(true);
    // A block given by the page is overridden by what changed in this session.
    expect(store.isBlocked('writer-2', false)).toBe(true);
  });

  it('a block ends your follow; the toast names them and its Undo unblocks and follows again', async () => {
    const follows = TestBed.inject(FollowStore);
    follows.learn('writer-2', true);
    const done = store.block(OMAR);
    http.expectOne(URL).flush({ userId: 'writer-2', isBlocked: true, followRemoved: true });
    await done;
    expect(follows.isFollowing('writer-2', true)).toBe(false);

    const [toast] = toasts.toasts();
    expect(toast.message).toBe('تم حظر ⁨Omar⁩.');
    expect(toast.action!.label).toBe('تراجع');
    toast.action!.run();
    expect(store.isBlocked('writer-2')).toBe(false);
    const undo = http.expectOne((r) => r.url === URL && r.method === 'DELETE');
    expect(undo.request.params.get('restoreFollow')).toBe('true');
    undo.flush({ userId: 'writer-2', isBlocked: false, followRemoved: false });
    await flushMicrotasks();
    expect(follows.isFollowing('writer-2', false)).toBe(true);
    // Undo is quiet: no second toast.
    expect(toasts.toasts()).toHaveLength(1);
  });

  it('Undo after a block that ended no follow does not follow them', async () => {
    const done = store.block(OMAR);
    http.expectOne(URL).flush({ userId: 'writer-2', isBlocked: true, followRemoved: false });
    await done;
    toasts.toasts()[0].action!.run();
    const undo = http.expectOne((r) => r.url === URL && r.method === 'DELETE');
    expect(undo.request.params.has('restoreFollow')).toBe(false);
    undo.flush({ userId: 'writer-2', isBlocked: false, followRemoved: false });
  });

  it('a refused block puts the old state back and shows the translated error', async () => {
    const done = store.block(OMAR);
    http.expectOne(URL).flush(problem(400, 'block.limit'), { status: 400, statusText: 'Bad Request' });
    expect(await done).toBe(false);
    expect(store.isBlocked('writer-2')).toBe(false);
    expect(toasts.toasts()).toEqual([expect.objectContaining({ kind: 'error', message: 'وصلت إلى الحد الأقصى للحسابات المحظورة (1000 حساب).' })]);
  });

  it('a second press while a block is on its way sends nothing', async () => {
    const first = store.block(OMAR);
    expect(await store.block(OMAR)).toBe(false);
    http.expectOne(URL).flush({ userId: 'writer-2', isBlocked: true, followRemoved: false });
    expect(await first).toBe(true);
  });

  it('Unblock (an unavailable page, Settings) confirms with a toast; a failure keeps them blocked', async () => {
    let done = store.unblock(OMAR);
    expect(store.isBlocked('writer-2', true)).toBe(false);
    const del = http.expectOne(URL);
    expect(del.request.method).toBe('DELETE');
    del.flush({ userId: 'writer-2', isBlocked: false, followRemoved: false });
    expect(await done).toBe(true);
    expect(toasts.toasts().map((t) => t.message)).toEqual(['تم إلغاء حظر ⁨Omar⁩.']);

    // Blocked again from the page's point of view, then a failed unblock leaves the block in place.
    store.learnBlocked('writer-2');
    done = store.unblock(OMAR);
    http.expectOne(URL).flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    expect(await done).toBe(false);
    expect(store.isBlocked('writer-2')).toBe(true);
  });

  it('"Also block" in the report sheet: the API blocked them, so the store only learns it (and the follow ended)', () => {
    const follows = TestBed.inject(FollowStore);
    follows.learn('writer-2', true);
    store.learnBlocked('writer-2');
    expect(store.isBlocked('writer-2')).toBe(true);
    expect(follows.isFollowing('writer-2', true)).toBe(false);
    http.expectNone(URL);
  });

  it('forgets the changes when another account signs in', () => {
    store.learnBlocked('writer-2');
    TestBed.tick();
    session.setMe(testMe({ id: 'someone-else' }));
    TestBed.tick();
    expect(store.isBlocked('writer-2')).toBe(false);
  });

  it("MuteStore leaves a blocked author's cards out of every list, even where mutes don't apply", () => {
    const mutes = TestBed.inject(MuteStore);
    const card = testCard({ author: { ...testCard().author!, id: 'writer-2' } });
    expect(mutes.hides(card, { applies: false })).toBe(false);
    store.learnBlocked('writer-2');
    expect(mutes.hides(card, { applies: true })).toBe(true);
    expect(mutes.hides(card, { applies: false })).toBe(true);
    expect(mutes.hides(testCard(), { applies: true })).toBe(false);
  });
});

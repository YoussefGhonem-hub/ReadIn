import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../../testing/social-testing';
import { testAdminRequest } from '../../../../testing/verification-testing';
import { AdminVerificationStore } from './admin-verification.store';

const LIST = `${TEST_API}/admin/verification-requests`;

describe('AdminVerificationStore (F19)', () => {
  let http: HttpTestingController;
  let store: AdminVerificationStore;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({ providers: [AdminVerificationStore] }));
    store = TestBed.inject(AdminVerificationStore);
  });

  afterEach(() => http.verify());

  const params = (req: TestRequest) => Object.fromEntries(req.request.params.keys().map((k) => [k, req.request.params.get(k)]));

  async function loaded(ids = ['vr-1', 'vr-2', 'vr-3'], nextCursor: string | null = null): Promise<void> {
    const loading = store.load('pending');
    const req = http.expectOne((r) => r.url === LIST);
    expect(params(req)).toEqual({ status: 'pending', limit: '20' });
    req.flush({ items: ids.map((id) => testAdminRequest(id)), nextCursor });
    await loading;
  }

  it('loads a tab in pages; more without duplicates; a failed page can be retried', async () => {
    await loaded(['vr-1', 'vr-2'], 'c-1');
    expect(store.status()).toBe('loaded');

    const failing = store.loadMore();
    http.expectOne((r) => r.url === LIST && r.params.get('cursor') === 'c-1').flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await failing;
    expect(store.moreFailed()).toBe(true);

    const more = store.loadMore();
    const req = http.expectOne((r) => r.url === LIST);
    expect(params(req)).toEqual({ status: 'pending', cursor: 'c-1', limit: '20' });
    req.flush({ items: [testAdminRequest('vr-2'), testAdminRequest('vr-3')], nextCursor: null });
    await more;
    expect(store.items().map((i) => i.id)).toEqual(['vr-1', 'vr-2', 'vr-3']);
    expect(store.nextCursor()).toBeNull();
    expect(store.moreFailed()).toBe(false);
  });

  it('a newer tab wins over a slower older one', async () => {
    const pending = store.load('pending');
    const approved = store.load('approved');
    const [first, second] = http.match((r) => r.url === LIST);
    second.flush({ items: [testAdminRequest('vr-ok', { status: 'approved' })], nextCursor: null });
    first.flush({ items: [testAdminRequest('vr-old')], nextCursor: null });
    await Promise.all([pending, approved]);
    expect(store.tab()).toBe('approved');
    expect(store.items().map((i) => i.id)).toEqual(['vr-ok']);
  });

  it('a decision leaves the list at once; approve and reject call their endpoints', async () => {
    await loaded();
    const approving = store.decide(store.find('vr-2')!, { kind: 'approve' });
    expect(store.items().map((i) => i.id)).toEqual(['vr-1', 'vr-3']);
    const approve = http.expectOne({ method: 'POST', url: `${LIST}/vr-2/approve` });
    expect(approve.request.body).toBeNull();
    approve.flush(null, { status: 204, statusText: 'No Content' });
    await approving;

    const rejecting = store.decide(store.find('vr-3')!, { kind: 'reject', reason: 'No name on the card.' });
    const reject = http.expectOne({ method: 'POST', url: `${LIST}/vr-3/reject` });
    expect(reject.request.body).toEqual({ reason: 'No name on the card.' });
    reject.flush(null, { status: 204, statusText: 'No Content' });
    await rejecting;
    expect(store.items().map((i) => i.id)).toEqual(['vr-1']);
  });

  it('a refusal puts the request back where it was, and is rethrown', async () => {
    await loaded();
    const deciding = store.decide(store.find('vr-2')!, { kind: 'approve' });
    http.expectOne(`${LIST}/vr-2/approve`).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await expect(deciding).rejects.toMatchObject({ code: 'server.error' });
    expect(store.items().map((i) => i.id)).toEqual(['vr-1', 'vr-2', 'vr-3']);
  });

  it('decided by someone else first (409) or gone (404): the tab loads again', async () => {
    await loaded();
    const deciding = store.decide(store.find('vr-1')!, { kind: 'reject', reason: 'Not enough.' });
    http.expectOne(`${LIST}/vr-1/reject`).flush(problem(409, 'verification.already_decided'), { status: 409, statusText: 'Conflict' });
    await expect(deciding).rejects.toMatchObject({ code: 'verification.already_decided' });
    await flushMicrotasks();
    http.expectOne((r) => r.url === LIST && r.params.get('status') === 'pending').flush({ items: [testAdminRequest('vr-2')], nextCursor: null });
    await flushMicrotasks();
    expect(store.items().map((i) => i.id)).toEqual(['vr-2']);
  });

  describe('removing a badge (roles change: Verified is a badge)', () => {
    const KARIM = { id: 'u-karim', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true };

    async function approvedTab(): Promise<void> {
      const loading = store.load('approved');
      http.expectOne((r) => r.url === LIST && r.params.get('status') === 'approved').flush({
        items: [
          testAdminRequest('vr-karim-2', { status: 'approved', user: KARIM }),
          testAdminRequest('vr-salma', { status: 'approved', user: { ...KARIM, id: 'u-salma', username: 'salma' } }),
          testAdminRequest('vr-karim-1', { status: 'approved', user: KARIM }),
        ],
        nextCursor: null,
      });
      await loading;
    }

    const verified = () => store.items().map((i) => [i.id, i.user.isVerified]);

    it("DELETE /admin/users/{id}/verification; every request of that user shows them unverified at once", async () => {
      await approvedTab();
      const removing = store.removeBadge(store.find('vr-karim-2')!);
      expect(verified()).toEqual([
        ['vr-karim-2', false],
        ['vr-salma', true],
        ['vr-karim-1', false],
      ]);
      const req = http.expectOne({ method: 'DELETE', url: `${TEST_API}/admin/users/u-karim/verification` });
      expect(req.request.body).toBeNull();
      req.flush(null, { status: 204, statusText: 'No Content' });
      await removing;
      // The requests stay where they are (an approved one stays approved).
      expect(store.items().map((i) => i.status)).toEqual(['approved', 'approved', 'approved']);
      expect(verified()).toEqual([
        ['vr-karim-2', false],
        ['vr-salma', true],
        ['vr-karim-1', false],
      ]);
    });

    it('a refusal gives the badge back and is rethrown', async () => {
      await approvedTab();
      const removing = store.removeBadge(store.find('vr-karim-1')!);
      http.expectOne(`${TEST_API}/admin/users/u-karim/verification`).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
      await expect(removing).rejects.toMatchObject({ code: 'server.error' });
      expect(verified()).toEqual([
        ['vr-karim-2', true],
        ['vr-salma', true],
        ['vr-karim-1', true],
      ]);
    });

    it('already removed by someone else (409 verification.not_verified): stays unverified, and is rethrown so the page says so', async () => {
      await approvedTab();
      const removing = store.removeBadge(store.find('vr-karim-2')!);
      http.expectOne(`${TEST_API}/admin/users/u-karim/verification`).flush(problem(409, 'verification.not_verified'), { status: 409, statusText: 'Conflict' });
      await expect(removing).rejects.toMatchObject({ code: 'verification.not_verified' });
      expect(verified()).toEqual([
        ['vr-karim-2', false],
        ['vr-salma', true],
        ['vr-karim-1', false],
      ]);
      http.expectNone((r) => r.url === LIST);
    });
  });
});

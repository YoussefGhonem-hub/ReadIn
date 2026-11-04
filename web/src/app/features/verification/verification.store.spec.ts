import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { testVerificationRequest, testVerificationStatus } from '../../../testing/verification-testing';
import { AuthService } from '../../core/auth/auth.service';
import { VerificationStore } from './verification.store';

const STATUS = `${TEST_API}/me/verification`;
const SUBMIT = `${TEST_API}/verification-requests`;

describe('VerificationStore (F19)', () => {
  let http: HttpTestingController;
  let store: VerificationStore;
  const auth = { refreshMe: vi.fn(async () => null) };

  beforeEach(() => {
    TestBed.resetTestingModule();
    auth.refreshMe.mockClear();
    ({ http } = setupSocialTesting({ providers: [VerificationStore, { provide: AuthService, useValue: auth }] }));
    store = TestBed.inject(VerificationStore);
  });

  afterEach(() => http.verify());

  async function loaded(status = testVerificationStatus({ canRequest: false, request: testVerificationRequest() })): Promise<void> {
    const loading = store.load();
    http.expectOne(STATUS).flush(status);
    await loading;
  }

  it('loads where you stand; a failure is an error state, a quiet reload keeps what is shown', async () => {
    expect(store.status()).toBe('loading');
    const failing = store.load();
    http.expectOne(STATUS).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await failing;
    expect(store.status()).toBe('error');

    await loaded();
    expect(store.view()).toBe('pending');
    const quiet = store.load({ quiet: true });
    expect(store.status()).toBe('loaded');
    http.expectOne(STATUS).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await quiet;
    expect(store.status()).toBe('loaded');
    expect(store.view()).toBe('pending');
  });

  it('a newer load wins over a slower older one', async () => {
    const older = store.load();
    const newer = store.load();
    const [first, second] = http.match(STATUS);
    second.flush(testVerificationStatus({ isVerified: true, canRequest: false }));
    first.flush(testVerificationStatus());
    await Promise.all([older, newer]);
    expect(store.view()).toBe('verified');
  });

  it('verified while the session says otherwise: `me` is read again (the badge)', async () => {
    await loaded(testVerificationStatus({ isVerified: true, canRequest: false }));
    expect(auth.refreshMe).toHaveBeenCalledTimes(1);
  });

  it('a sent request is under review at once; errors are the caller\'s', async () => {
    await loaded(testVerificationStatus());
    const sending = store.submit({ fieldId: 'f-software', jobTitle: 'Backend engineer', proofUrl: 'https://github.com/mona', note: null, proof: null });
    const req = http.expectOne({ method: 'POST', url: SUBMIT });
    const body = req.request.body as FormData;
    expect([...body.keys()]).toEqual(['fieldId', 'jobTitle', 'proofUrl']);
    req.flush(testVerificationRequest({ proofFileName: null }), { status: 201, statusText: 'Created' });
    await sending;
    expect(store.view()).toBe('pending');
    expect(store.data()!.canRequest).toBe(false);

    const refused = store.submit({ fieldId: 'f-software', jobTitle: 'x', proofUrl: null, note: null, proof: null });
    http.expectOne(SUBMIT).flush(problem(409, 'verification.already_pending'), { status: 409, statusText: 'Conflict' });
    await expect(refused).rejects.toMatchObject({ code: 'verification.already_pending' });
  });

  it('withdrawing shows the form at once; a refusal puts the request back; one already gone reads the status again', async () => {
    await loaded();
    const failing = store.withdraw();
    expect(store.view()).toBe('none');
    expect(store.withdrawing()).toBe(true);
    http.expectOne({ method: 'DELETE', url: STATUS }).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await expect(failing).rejects.toMatchObject({ code: 'server.error' });
    expect(store.view()).toBe('pending');
    expect(store.withdrawing()).toBe(false);

    const gone = store.withdraw();
    http.expectOne({ method: 'DELETE', url: STATUS }).flush(problem(404, 'verification.not_found'), { status: 404, statusText: 'Not Found' });
    await gone;
    await flushMicrotasks();
    http.expectOne({ method: 'GET', url: STATUS }).flush(testVerificationStatus({ request: testVerificationRequest({ status: 'rejected', rejectionReason: 'No.' }) }));
    await flushMicrotasks();
    expect(store.view()).toBe('rejected');

    await loaded();
    const ok = store.withdraw();
    http.expectOne({ method: 'DELETE', url: STATUS }).flush(null, { status: 204, statusText: 'No Content' });
    await ok;
    expect(store.view()).toBe('none');
  });
});

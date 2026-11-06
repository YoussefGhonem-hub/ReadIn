import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { testVerificationRequest, testVerificationStatus } from '../../../testing/verification-testing';
import { VerificationStatusDto } from '../../core/api/models';
import { VerificationRow } from './verification-row';

const STATUS = `${TEST_API}/me/verification`;

describe('Settings → Writer verification (F19)', () => {
  let http: HttpTestingController;

  afterEach(() => http.verify());

  async function render(answer: VerificationStatusDto | 'error' | null, options: { verified?: boolean } = {}) {
    TestBed.resetTestingModule();
    const t = setupSocialTesting();
    http = t.http;
    t.session.setMe(testMe({ isVerified: !!options.verified }));
    const fixture = TestBed.createComponent(VerificationRow);
    fixture.detectChanges();
    if (answer === 'error') http.expectOne(STATUS).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    else if (answer) http.expectOne(STATUS).flush(answer);
    await flushMicrotasks();
    fixture.detectChanges();
    const link = (fixture.nativeElement as HTMLElement).querySelector<HTMLAnchorElement>('[data-settings-verification]')!;
    return { link, state: () => link.querySelector('[data-verification-state]')?.textContent?.trim() ?? null };
  }

  it('opens /verification and says where your request stands', async () => {
    let t = await render(testVerificationStatus());
    expect(t.link.getAttribute('href')).toBe('/verification');
    expect(t.link.textContent).toContain('توثيق الكاتب');
    expect(t.state()).toBe('طلب التوثيق');

    t = await render(testVerificationStatus({ canRequest: false, request: testVerificationRequest() }));
    expect(t.state()).toBe('قيد المراجعة');
    expect(t.link.getAttribute('data-status')).toBe('pending');

    t = await render(testVerificationStatus({ request: testVerificationRequest({ status: 'rejected', rejectionReason: 'No.' }) }));
    expect(t.state()).toBe('لم تتم الموافقة');
  });

  it('a verified account needs no call; an unreadable status is left out', async () => {
    let t = await render(null, { verified: true });
    expect(t.state()).toBe('موثّق ✓');

    t = await render('error');
    expect(t.state()).toBeNull();
    t = await render(testVerificationStatus({ canRequest: false }));
    expect(t.state()).toBeNull();
  });
});

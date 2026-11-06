import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { MuteStore } from '../../core/social/mute.store';
import { MutedBanner } from './muted-banner';

async function render() {
  const { http, toasts } = setupSocialTesting();
  const fixture = TestBed.createComponent(MutedBanner);
  fixture.componentRef.setInput('user', { id: 'writer-1', displayName: 'Karim Hassan' });
  fixture.detectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  return { http, toasts, root, stable };
}

describe('MutedBanner (F28)', () => {
  let http: HttpTestingController;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => http.verify());

  it('says you muted the writer and unmutes them without following again', async () => {
    const t = await render();
    http = t.http;
    const banner = t.root.querySelector('[data-muted-banner]')!;
    expect(banner.getAttribute('role')).toBe('status');
    expect(banner.querySelector('h2')!.textContent!.trim()).toBe('لقد كتمت هذا الكاتب');
    const unmute = t.root.querySelector<HTMLButtonElement>('[data-muted-unmute]')!;
    expect(unmute.textContent!.trim()).toBe('إلغاء الكتم');

    unmute.click();
    await t.stable();
    expect(unmute.disabled).toBe(true);
    const req = t.http.expectOne(`${TEST_API}/users/writer-1/mute`);
    expect(req.request.method).toBe('DELETE');
    req.flush({ isMuted: false, isFollowing: false, followerCount: 40, followRemoved: false });
    await t.stable();
    expect(TestBed.inject(MuteStore).isAuthorMuted('writer-1', true)).toBe(false);
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['تم إلغاء كتم \u2068Karim Hassan\u2069.']);
  });

  it('a failed unmute keeps the mute and says why', async () => {
    const t = await render();
    http = t.http;
    t.root.querySelector<HTMLButtonElement>('[data-muted-unmute]')!.click();
    await t.stable();
    t.http.expectOne(`${TEST_API}/users/writer-1/mute`).flush(problem(404, 'user.not_found'), { status: 404, statusText: 'Not Found' });
    await t.stable();
    expect(TestBed.inject(MuteStore).isAuthorMuted('writer-1', true)).toBe(true);
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['هذا المستخدم غير موجود.']);
  });
});

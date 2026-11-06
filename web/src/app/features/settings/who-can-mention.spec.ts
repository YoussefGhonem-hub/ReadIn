import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ProfileSettings } from './profile-settings';
import { WhoCanMention } from './who-can-mention';

describe('Settings → Privacy: who can mention me (F18)', () => {
  beforeEach(() => TestBed.resetTestingModule());

  function render() {
    const fixture = TestBed.createComponent(WhoCanMention);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const group = root.querySelector<HTMLElement>('[role="radiogroup"]')!;
    const radios = () => [...root.querySelectorAll<HTMLButtonElement>('[role="radio"]')];
    const checked = () => radios().find((r) => r.getAttribute('aria-checked') === 'true')?.textContent?.trim();
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
    };
    return { fixture, root, group, radios, checked, stable };
  }

  it('is a labelled radio group of three, with a hint, on "everyone" by default', () => {
    setupSocialTesting();
    const { root, group, radios, checked } = render();
    expect(root.textContent).toContain('من يمكنه الإشارة إليّ');
    expect(group.getAttribute('aria-label')).toBe('من يمكنه الإشارة إليّ');
    expect(radios().map((r) => r.textContent!.trim())).toEqual(['الجميع', 'الأشخاص الذين أتابعهم', 'لا أحد']);
    expect(checked()).toBe('الجميع');
    const hint = root.querySelector(`#${group.getAttribute('aria-describedby')}`)!;
    expect(hint.textContent).toContain('في التعليقات والمقالات');
    expect(root.getAttribute('data-value')).toBe('everyone');
  });

  it('in English', () => {
    setupSocialTesting();
    TestBed.inject(TranslocoService).setActiveLang('en');
    const { root, radios } = render();
    expect(root.textContent).toContain('Who can mention me');
    expect(radios().map((r) => r.textContent!.trim())).toEqual(['Everyone', 'People I follow', 'Nobody']);
  });

  it('shows the saved choice, saves a new one at once (whole settings object) and is disabled meanwhile', async () => {
    const { http, session } = setupSocialTesting();
    session.patchMe({ privacy: { publicReadingStats: true, whoCanMention: 'nobody' } });
    const { root, radios, checked, stable } = render();
    expect(checked()).toBe('لا أحد');

    radios()[1].click();
    await stable();
    expect(checked()).toBe('الأشخاص الذين أتابعهم');
    expect(radios().every((r) => r.disabled)).toBe(true);
    expect(root.getAttribute('aria-busy')).toBe('true');
    const req = http.expectOne({ method: 'PUT', url: `${TEST_API}/me/privacy` });
    expect(req.request.body).toEqual({ publicReadingStats: true, whoCanMention: 'following' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await stable();
    expect(radios().some((r) => r.disabled)).toBe(false);
    expect(root.getAttribute('aria-busy')).toBeNull();
    expect(root.getAttribute('data-value')).toBe('following');
    http.verify();
  });

  it('goes back to the saved choice, with the translated error, when the API refuses it', async () => {
    const { http, toasts } = setupSocialTesting();
    const { radios, checked, stable } = render();
    radios()[2].click();
    await stable();
    expect(checked()).toBe('لا أحد');
    http.expectOne(`${TEST_API}/me/privacy`).flush(problem(400, 'validation.failed'), { status: 400, statusText: 'Bad Request' });
    await stable();
    expect(checked()).toBe('الجميع');
    expect(toasts.toasts()).toEqual([expect.objectContaining({ kind: 'error' })]);
  });

  it('sits in Settings → Privacy next to the public-stats switch, for signed-in users only', () => {
    setupSocialTesting();
    const fixture = TestBed.createComponent(ProfileSettings);
    fixture.detectChanges();
    const privacy = (fixture.nativeElement as HTMLElement).querySelector('[data-settings-privacy]')!;
    expect(privacy.querySelector('[data-public-stats]')).not.toBeNull();
    expect(privacy.querySelector('[data-who-can-mention]')).not.toBeNull();

    TestBed.resetTestingModule();
    setupSocialTesting({ guest: true });
    const guest = TestBed.createComponent(ProfileSettings);
    guest.detectChanges();
    const guestPrivacy = (guest.nativeElement as HTMLElement).querySelector('[data-settings-privacy]')!;
    expect(guestPrivacy.querySelector('[data-who-can-mention]')).toBeNull();
    expect(guestPrivacy.textContent).toContain('سجّل الدخول لتغيير إعدادات الخصوصية.');
  });
});

import { WritableSignal, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { settle, setupAuthTesting } from '../../../testing/auth-testing';
import { PushPermission } from '../../core/push/push-client';
import { PushService } from '../../core/push/push.service';
import { provideAppIcons } from '../../shared/ui/icons';
import { OnboardingPage } from './onboarding.page';

/** Onboarding's last step (F02), where notifications are offered in context (SPEC §21.1). */
async function renderPreferences(permission: PushPermission) {
  const push = {
    permission: signal<PushPermission>(permission),
    enable: vi.fn(async () => 'granted' as PushPermission),
    unregisterDevice: vi.fn(async () => undefined),
    forgetDevice: vi.fn(async () => undefined),
  };
  const { http } = setupAuthTesting({ providers: [provideRouter([]), provideAppIcons(), { provide: PushService, useValue: push }] });
  const fixture = TestBed.createComponent(OnboardingPage);
  fixture.detectChanges();
  for (const request of http.match(() => true)) request.flush([]); // the fields
  await settle(10);
  (fixture.componentInstance as unknown as { step: WritableSignal<number> }).step.set(3);
  fixture.detectChanges();
  const root = fixture.nativeElement as HTMLElement;
  return { root, push, card: () => root.querySelector<HTMLElement>('[data-onboarding-notifications]') };
}

describe('Onboarding: notifications on the last step', () => {
  beforeEach(() => TestBed.resetTestingModule());

  it('a browser (or build) without web push shows no notifications card, only the reminder time', async () => {
    const t = await renderPreferences('unsupported');
    expect(t.card()).toBeNull();
    expect(t.root.textContent).not.toContain('هذا المتصفح لا يدعم الإشعارات');
    expect(t.root.querySelector('#reminder')).not.toBeNull();
  });

  it('a browser that can get them, not asked yet: Enable asks for permission', async () => {
    const t = await renderPreferences('default');
    expect(t.card()!.textContent).toContain('فعّلها ليصلك مقال اليوم.');
    t.card()!.querySelector('button')!.click();
    expect(t.push.enable).toHaveBeenCalledTimes(1);
  });

  it('blocked in the browser: says so, with nothing to click', async () => {
    const t = await renderPreferences('denied');
    expect(t.card()!.textContent).toContain('الإشعارات محظورة في متصفحك.');
    expect(t.card()!.querySelector('button')).toBeNull();
  });
});

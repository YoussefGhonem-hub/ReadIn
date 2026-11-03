import { TestBed } from '@angular/core/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { PrivacyService } from './privacy.service';
import { PublicStatsSwitch } from './public-stats-switch';

describe('PrivacyService and the public-stats switch (F14, F18)', () => {
  beforeEach(() => TestBed.resetTestingModule());

  it('turns public reading stats on at once, sends the whole settings object and keeps it', async () => {
    const { http, session } = setupSocialTesting();
    const privacy = TestBed.inject(PrivacyService);
    expect(privacy.publicReadingStats()).toBe(false); // an API older than F14 sends no privacy object

    const saved = privacy.setPublicReadingStats(true);
    expect(privacy.publicReadingStats()).toBe(true);
    expect(privacy.saving()).toBe(true);
    // One save at a time: a second tap while saving does nothing.
    expect(await privacy.setPublicReadingStats(false)).toBe(false);
    const req = http.expectOne(`${TEST_API}/me/privacy`);
    expect(req.request.method).toBe('PUT');
    expect(req.request.body).toEqual({ publicReadingStats: true });
    req.flush(null, { status: 204, statusText: 'No Content' });
    expect(await saved).toBe(true);
    expect(session.me()!.privacy).toEqual({ publicReadingStats: true });
    expect(privacy.saving()).toBe(false);
    http.verify();
  });

  it('goes back and shows the error when the save fails', async () => {
    const { http, session, toasts } = setupSocialTesting();
    session.patchMe({ privacy: { publicReadingStats: true } });
    const privacy = TestBed.inject(PrivacyService);
    const saved = privacy.setPublicReadingStats(false);
    expect(privacy.publicReadingStats()).toBe(false);
    http.expectOne(`${TEST_API}/me/privacy`).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    expect(await saved).toBe(false);
    expect(privacy.publicReadingStats()).toBe(true);
    expect(toasts.toasts()[0].kind).toBe('error');
  });

  it('guests can not save', async () => {
    const { http } = setupSocialTesting({ guest: true });
    expect(await TestBed.inject(PrivacyService).setPublicReadingStats(true)).toBe(false);
    http.expectNone(`${TEST_API}/me/privacy`);
  });

  it('the switch is a labelled role="switch" that reflects and changes the setting', async () => {
    const { http } = setupSocialTesting();
    const fixture = TestBed.createComponent(PublicStatsSwitch);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const button = root.querySelector<HTMLButtonElement>('[role="switch"]')!;
    expect(button.getAttribute('aria-checked')).toBe('false');
    const label = root.querySelector<HTMLLabelElement>(`label[for="${button.id}"]`)!;
    expect(label.textContent).toContain('اعرضها في بروفايلي العام');
    expect(button.getAttribute('aria-describedby')).toBe(`${button.id}-hint`);

    label.click(); // the label toggles it too
    fixture.detectChanges();
    expect(button.getAttribute('aria-checked')).toBe('true');
    expect(button.disabled).toBe(true);
    http.expectOne(`${TEST_API}/me/privacy`).flush(null, { status: 204, statusText: 'No Content' });
    await flushMicrotasks();
    fixture.detectChanges();
    expect(button.disabled).toBe(false);
  });
});

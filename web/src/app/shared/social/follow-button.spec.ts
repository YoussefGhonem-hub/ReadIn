import { TestBed } from '@angular/core/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { FollowButton } from './follow-button';

async function render(user: { id: string; displayName: string }, initial: boolean, options: { guest?: boolean } = {}) {
  const { http } = setupSocialTesting(options);
  const fixture = TestBed.createComponent(FollowButton);
  fixture.componentRef.setInput('user', user);
  fixture.componentRef.setInput('initial', initial);
  fixture.detectChanges();
  return { fixture, http, button: () => (fixture.nativeElement as HTMLElement).querySelector<HTMLButtonElement>('[data-follow]') };
}

describe('FollowButton (F12)', () => {
  beforeEach(() => TestBed.resetTestingModule());

  it('follows optimistically, with the name for screen readers', async () => {
    const { fixture, http, button } = await render({ id: 'writer-1', displayName: 'Karim Hassan' }, false);
    expect(button()!.textContent).toContain('متابعة');
    expect(button()!.textContent).toContain('Karim Hassan');
    expect(button()!.getAttribute('aria-pressed')).toBe('false');

    button()!.click();
    fixture.detectChanges();
    expect(button()!.getAttribute('aria-pressed')).toBe('true');
    expect(button()!.textContent).toContain('بتتابعه');
    http.expectOne(`${TEST_API}/users/writer-1/follow`).flush({ isFollowing: true, followerCount: 861 });
    await flushMicrotasks();
    http.verify();
  });

  it('is hidden on yourself', async () => {
    const { button } = await render({ id: 'user-1', displayName: 'Mona Adel' }, false);
    expect(button()).toBeNull();
  });

  it('guests get the sign-in prompt', async () => {
    const { http, button } = await render({ id: 'writer-1', displayName: 'Karim Hassan' }, false, { guest: true });
    button()!.click();
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
    http.expectNone(`${TEST_API}/users/writer-1/follow`);
  });
});

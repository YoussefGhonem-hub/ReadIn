import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { testMe } from '../../../testing/auth-testing';
import { setupSocialTesting } from '../../../testing/social-testing';
import { StartPostCard } from './start-post-card';

describe('StartPostCard', () => {
  function render(options: { guest?: boolean; permissions?: string[]; lang?: 'ar' | 'en' } = {}) {
    TestBed.resetTestingModule();
    const { session } = setupSocialTesting({ guest: options.guest });
    if (options.permissions) session.setMe(testMe({ permissions: options.permissions }));
    if (options.lang) TestBed.inject(TranslocoService).setActiveLang(options.lang);
    const fixture = TestBed.createComponent(StartPostCard);
    fixture.detectChanges();
    return { fixture, host: fixture.nativeElement as HTMLElement };
  }

  it('signed in: your avatar, "Start a post…" and Photo / PDF / Article, all opening the editor', () => {
    const { host } = render();
    const card = host.querySelector('[data-start-post]')!;
    expect(card.getAttribute('aria-label')).toBe('ابدأ مقال جديد');
    expect(host.classList).toContain('block');
    expect(card.querySelector('rd-avatar')).not.toBeNull();

    const prompt = card.querySelector<HTMLAnchorElement>('[data-start-post-prompt]')!;
    expect(prompt.textContent!.trim()).toBe('ابدأ مقال جديد…');
    expect(prompt.getAttribute('href')).toBe('/write/new');

    const actions = [...card.querySelectorAll<HTMLAnchorElement>('[data-start-post-action]')];
    expect(actions.map((a) => a.textContent!.trim())).toEqual(['صورة', 'PDF', 'مقال']);
    for (const action of actions) expect(action.getAttribute('href')).toBe('/write/new');
  });

  it('guests and accounts that cannot write: nothing, and no space taken', () => {
    let { host } = render({ guest: true });
    expect(host.querySelector('[data-start-post]')).toBeNull();
    expect(host.classList).toContain('hidden');

    ({ host } = render({ permissions: ['articles.read'] }));
    expect(host.querySelector('[data-start-post]')).toBeNull();
  });

  it('English labels', () => {
    const { host } = render({ lang: 'en' });
    expect(host.querySelector('[data-start-post-prompt]')!.textContent!.trim()).toBe('Start a post…');
    expect([...host.querySelectorAll('[data-start-post-action]')].map((a) => a.textContent!.trim())).toEqual(['Photo', 'PDF', 'Article']);
  });
});

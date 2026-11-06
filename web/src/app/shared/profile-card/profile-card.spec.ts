import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testProfile } from '../../../testing/profile-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ProfileDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { ProfileCard } from './profile-card';

describe('ProfileCard (the hover card)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => http?.verify());

  async function render(username: string, options: { guest?: boolean } = {}) {
    const setup = setupSocialTesting({ guest: options.guest });
    http = setup.http;
    const fixture = TestBed.createComponent(ProfileCard);
    fixture.componentRef.setInput('username', username);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    };
    const respond = async (profile: ProfileDto | { status: number; code: string }) => {
      const req = setup.http.expectOne(`${TEST_API}/users/${username.replace(/^@/, '')}`);
      if ('code' in profile) req.flush(problem(profile.status, profile.code), { status: profile.status, statusText: 'Error' });
      else req.flush(profile);
      await stable();
    };
    const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
    return { fixture, root, http: setup.http, $, stable, respond };
  }

  it('shows a skeleton, then the person: photo and name open the profile, @username, title, "Follows you", stats, Follow', async () => {
    const t = await render('karim');
    expect(t.root.getAttribute('role')).toBe('dialog');
    expect(t.root.hasAttribute('aria-modal')).toBe(false); // non-modal: it never takes the focus
    expect(t.root.getAttribute('aria-busy')).toBe('true');
    expect(t.$('[data-profile-card-loading]')).not.toBeNull();
    expect(t.root.getAttribute('aria-label')).toBe('@karim');

    await t.respond(testProfile());
    expect(t.$('[data-profile-card-loading]')).toBeNull();
    expect(t.root.hasAttribute('aria-busy')).toBe(false);
    expect(t.root.getAttribute('aria-label')).toBe('Karim Hassan');

    const name = t.$('[data-profile-card-name]')!;
    expect(name.textContent).toContain('Karim Hassan');
    expect(name.getAttribute('href')).toBe('/@karim');
    expect(name.querySelector('svg[aria-label="كاتب موثّق"]')).not.toBeNull();
    const photo = t.root.querySelector('a[aria-hidden="true"] rd-avatar')!.closest('a')!;
    expect(photo.getAttribute('href')).toBe('/@karim');
    expect(photo.getAttribute('tabindex')).toBe('-1');

    const handle = t.$('[data-profile-card-username]')!;
    expect(handle.textContent!.trim()).toBe('@karim');
    expect(handle.getAttribute('dir')).toBe('ltr');
    const headline = t.$('[data-profile-card-headline]')!;
    expect(headline.textContent!.trim()).toBe('Frontend lead | Angular و performance');
    expect(headline.getAttribute('dir')).toBe('auto');
    expect(headline.classList).toContain('line-clamp-2');
    expect(t.$('[data-profile-card-follows-you]')!.textContent!.trim()).toBe('يتابعك');
    // "N followers · M articles" with the Arabic plural forms (340 and 12 take the "many" form).
    expect(t.$('[data-profile-card-stats]')!.textContent!.replace(/\s+/g, ' ').trim()).toBe('340 متابِعًا · 12 مقالًا');

    const follow = t.$<HTMLButtonElement>('[data-profile-card-action] [data-follow]')!;
    expect(follow.textContent).toContain('متابعة');
    expect(follow.getAttribute('aria-pressed')).toBe('false');
    expect(follow.classList).toContain('w-full');
    expect(follow.classList).toContain('rd-btn-primary');
    expect(t.$('[data-profile-card-view]')).toBeNull();
  });

  it('no title line without a title, and no "Follows you" when they don’t', async () => {
    const t = await render('karim');
    await t.respond(testProfile({ headline: null, followsYou: false }));
    expect(t.$('[data-profile-card-headline]')).toBeNull();
    expect(t.$('[data-profile-card-follows-you]')).toBeNull();
  });

  it('the stats take each plural form, with compact numbers', async () => {
    const t = await render('karim');
    await t.respond(testProfile({ stats: { articles: 2, followers: 1, following: 0, totalReads: 0 } }));
    expect(t.$('[data-profile-card-followers]')!.textContent!.trim()).toBe('متابِع واحد');
    expect(t.$('[data-profile-card-articles]')!.textContent!.trim()).toBe('مقالان');
    t.fixture.destroy();

    const big = TestBed.createComponent(ProfileCard);
    big.componentRef.setInput('username', 'nour');
    big.detectChanges();
    t.http.expectOne(`${TEST_API}/users/nour`).flush(testProfile({ username: 'nour', stats: { articles: 5, followers: 12_400, following: 0, totalReads: 0 } }));
    await flushMicrotasks();
    big.detectChanges();
    const root = big.nativeElement as HTMLElement;
    const compact = new Intl.NumberFormat('ar-EG-u-nu-latn', { notation: 'compact', maximumFractionDigits: 1 }).format(12_400);
    expect(root.querySelector('[data-profile-card-followers]')!.textContent!.trim()).toBe(`${compact} متابِع`);
    expect(root.querySelector('[data-profile-card-articles]')!.textContent!.trim()).toBe('5 مقالات');
  });

  it('Follow uses the shared follow store, and the follower count moves with it', async () => {
    const t = await render('karim');
    await t.respond(testProfile());
    t.$('[data-follow]')!.click();
    await t.stable();
    expect(t.$('[data-profile-card-followers]')!.textContent!.trim()).toBe('341 متابِعًا');
    const req = t.http.expectOne(`${TEST_API}/users/writer-1/follow`);
    expect(req.request.method).toBe('PUT');
    req.flush({ isFollowing: true, followerCount: 341 });
    await t.stable();
    expect(t.$('[data-follow]')!.getAttribute('aria-pressed')).toBe('true');
    expect(t.$('[data-follow]')!.textContent).toContain('تتابعه');
  });

  it('guests get the sign-in prompt from Follow', async () => {
    const t = await render('karim', { guest: true });
    await t.respond(testProfile({ isFollowing: false, followsYou: false }));
    t.$('[data-follow]')!.click();
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
  });

  it('your own card offers "View profile" instead of Follow', async () => {
    const t = await render('mona');
    await t.respond(testProfile({ id: 'user-1', username: 'mona', displayName: 'Mona Adel', isMe: true, followsYou: false }));
    expect(t.$('[data-follow]')).toBeNull();
    const view = t.$('[data-profile-card-view]')!;
    expect(view.textContent!.trim()).toBe('عرض الملف الشخصي');
    expect(view.getAttribute('href')).toBe('/@mona');
  });

  it('one short line when the profile can’t load', async () => {
    const t = await render('ghost');
    await t.respond({ status: 404, code: 'user.not_found' });
    expect(t.$('[data-profile-card-error]')!.textContent!.trim()).toBe('تعذّر تحميل الملف الشخصي.');
    expect(t.$('[data-follow]')).toBeNull();
    expect(t.root.getAttribute('aria-label')).toBe('@ghost');
  });

  it('a card shown again draws at once from the cache', async () => {
    const t = await render('karim');
    await t.respond(testProfile());
    t.fixture.destroy();

    const again = TestBed.createComponent(ProfileCard);
    again.componentRef.setInput('username', '@Karim');
    again.detectChanges();
    const root = again.nativeElement as HTMLElement;
    expect(root.querySelector('[data-profile-card-loading]')).toBeNull();
    expect(root.querySelector('[data-profile-card-name]')!.textContent).toContain('Karim Hassan');
    t.http.expectNone(`${TEST_API}/users/karim`);
  });
});

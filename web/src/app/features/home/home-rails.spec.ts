import { Component, Type, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testPathCard, testProgress } from '../../../testing/paths-testing';
import { testProfile } from '../../../testing/profile-testing';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { translocoTesting } from '../../../testing/transloco-testing';
import { provideRouter } from '@angular/router';
import { provideAppIcons } from '../../shared/ui/icons';
import { ReadingStatsDto, StreakDto, UserSummaryDto } from '../../core/api/models';
import { SessionStore } from '../../core/auth/session.store';
import { StreakStore } from '../reading/streak.store';
import { HomeColumns } from './home-columns';
import { HomeEndRail } from './home-end-rail';
import { HomeLayout } from './home-layout';
import { HomeStore } from './home.store';
import { HomeStartRail } from './home-start-rail';

function writer(id: string, patch: Partial<UserSummaryDto> = {}): UserSummaryDto {
  return { id, displayName: `Writer ${id}`, username: `writer${id}`, avatarUrl: null, isVerified: false, bio: null, isFollowing: false, followsYou: false, ...patch };
}

const STREAK: StreakDto = { current: 5, longest: 9, readToday: true, freezeAvailable: true, freezePending: false, today: '2026-11-05' };
const STATS: ReadingStatsDto = {
  streak: STREAK,
  totalArticles: 20,
  minutesRead: 140,
  articlesThisWeek: 3,
  minutesThisWeek: 27,
  articlesThisMonth: 11,
  topFields: [],
};

@Component({ selector: 'rd-host', template: '<rd-home-columns><p data-centre>feed</p></rd-home-columns>', imports: [HomeColumns] })
class ColumnsHost {}

describe('Home columns', () => {
  let http: HttpTestingController;
  const active = signal(true);
  const footerInStart = signal(false);
  const streak = signal<StreakDto | null>(null);
  const stats = signal<ReadingStatsDto | null>(null);
  const refreshIfStale = vi.fn(() => Promise.resolve());

  afterEach(() => http?.verify());

  function setup(options: { guest?: boolean; permissions?: string[]; layout?: boolean } = {}) {
    TestBed.resetTestingModule();
    active.set(true);
    footerInStart.set(false);
    streak.set(null);
    stats.set(null);
    refreshIfStale.mockClear();
    const testing = setupSocialTesting({
      guest: options.guest,
      providers: [
        HomeStore,
        ...(options.layout === false ? [] : [{ provide: HomeLayout, useValue: { wide: signal(true), active, footerInStart } }]),
        { provide: StreakStore, useValue: { streak, stats, refreshIfStale } },
      ],
    });
    http = testing.http;
    const session = TestBed.inject(SessionStore);
    if (options.permissions) session.setMe({ ...session.me()!, permissions: options.permissions });
    return testing;
  }

  function render<T>(component: Type<T>) {
    const fixture = TestBed.createComponent(component);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      // Path covers without an image ask for the fields' icons once.
      http.match(`${TEST_API}/fields`).forEach((r) => r.flush([]));
      await flushMicrotasks();
      fixture.detectChanges();
    };
    return { fixture, root, stable };
  }

  describe('start column', () => {
    it('signed in: the profile card with your fields, the reading card and the shortcuts', async () => {
      setup();
      streak.set(STREAK);
      const { root, stable } = render(HomeStartRail);

      const card = root.querySelector<HTMLAnchorElement>('[data-home-profile-card]')!;
      expect(card.getAttribute('href')).toBe('/@mona');
      expect(card.textContent).toContain('Mona Adel');
      expect(card.textContent).toContain('@mona');
      // The fields' line keeps its height while they load.
      expect(card.querySelectorAll('[data-home-profile-fields] .rd-skeleton').length).toBe(2);
      const expertise = ['software', 'ai', 'design', 'medicine'].map((slug, i) => ({ id: `f${i}`, slug, name: slug.toUpperCase(), icon: 'Code', color: 'primary' }));
      http.expectOne(`${TEST_API}/users/mona`).flush(testProfile({ username: 'mona', expertise }));
      await stable();
      expect([...card.querySelectorAll('[data-home-profile-field]')].map((f) => f.textContent!.trim())).toEqual(['SOFTWARE', 'AI', 'DESIGN']);

      // Reading: the streak now, this week's numbers once the stats arrive; each row opens your profile.
      expect(refreshIfStale).toHaveBeenCalled();
      const row = (id: string) => root.querySelector<HTMLAnchorElement>(`[data-home-reading-row="${id}"]`)!;
      expect(row('streak').textContent).toContain('السلسلة الحالية');
      expect(row('streak').textContent).toContain('5 أيام');
      expect(row('articles').querySelector('.rd-skeleton')).not.toBeNull();
      stats.set(STATS);
      await stable();
      expect(row('articles').textContent).toContain('مقالات الأسبوع ده');
      expect(row('articles').textContent).toContain('3');
      expect(row('minutes').textContent).toContain('27');
      expect(row('minutes').getAttribute('href')).toBe('/@mona');

      const shortcuts = [...root.querySelectorAll<HTMLAnchorElement>('[data-home-shortcut]')];
      expect(shortcuts.map((a) => [a.textContent!.trim(), a.getAttribute('href')])).toEqual([
        ['المحفوظات', '/saved'],
        ['مساراتي', '/paths?tab=mine'],
        ['مقالاتي', '/write'],
      ]);
      expect(root.querySelector('[data-home-guest]')).toBeNull();
    });

    it('a verified writer gets the badge; without fields, the bio; without articles.create, no "My articles"', async () => {
      setup({ permissions: ['articles.read'] });
      TestBed.inject(SessionStore).patchMe({ isVerified: true, bio: 'بكتب عن الـ backend' });
      const { root, stable } = render(HomeStartRail);
      http.expectOne(`${TEST_API}/users/mona`).flush(testProfile({ username: 'mona', expertise: [] }));
      await stable();
      expect(root.querySelector('[data-home-profile-card] svg[aria-label="كاتب موثّق"]')).not.toBeNull();
      expect(root.querySelector('[data-home-profile-fields]')!.textContent).toContain('بكتب عن الـ backend');
      expect(root.querySelector('[data-home-shortcut="myArticles"]')).toBeNull();
    });

    it('guests: one card with Sign in and Create account; nothing is loaded', () => {
      setup({ guest: true });
      const { root } = render(HomeStartRail);
      const guest = root.querySelector('[data-home-guest]')!;
      expect(guest.textContent).toContain('اقرا كل يوم واتعلم أكتر');
      expect([...guest.querySelectorAll('a')].map((a) => a.getAttribute('href'))).toEqual(['/auth/sign-in', '/auth/sign-up']);
      expect(root.querySelector('[data-home-profile-card]')).toBeNull();
      expect(refreshIfStale).not.toHaveBeenCalled();
    });

    it('before the session is known (and on the server): the guest card holds the place, invisible', () => {
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        imports: [translocoTesting()],
        providers: [provideRouter([]), provideAppIcons(), { provide: HomeLayout, useValue: { wide: signal(true), active, footerInStart } }],
      });
      // A fresh session store is "unknown", like every page during SSR.
      const fixture = TestBed.createComponent(HomeStartRail);
      fixture.detectChanges();
      const placeholder = (fixture.nativeElement as HTMLElement).querySelector('rd-home-guest-card')!;
      expect(placeholder.classList).toContain('invisible');
      expect(placeholder.getAttribute('aria-hidden')).toBe('true');
      expect(placeholder.hasAttribute('inert')).toBe(true);
      expect((fixture.nativeElement as HTMLElement).querySelector('[data-home-profile-card]')).toBeNull();
      http = undefined!;
    });

    it('narrow screens (the columns are hidden): no request', () => {
      setup();
      active.set(false);
      render(HomeStartRail);
      http.expectNone(`${TEST_API}/users/mona`);
      expect(refreshIfStale).not.toHaveBeenCalled();
    });

    it('the footer links come under its cards only when the end column has none', async () => {
      setup({ guest: true });
      const { root, stable } = render(HomeStartRail);
      expect(root.querySelector('[data-home-footer]')).toBeNull();
      footerInStart.set(true);
      await stable();
      expect(root.lastElementChild!.tagName.toLowerCase()).toBe('rd-home-footer');
      expect(root.querySelector('[data-home-guest]')).not.toBeNull();
    });
  });

  describe('end column', () => {
    it('signed in: three suggested writers with "+ Follow", then the first path you are not in, then the footer', async () => {
      setup();
      const { root, stable } = render(HomeEndRail);
      expect(root.querySelector('[data-home-suggestions-loading]')).not.toBeNull();
      // Nothing under the loading card yet: it would move when the card fills in.
      expect(root.querySelector('rd-home-suggested-path')).toBeNull();
      expect(root.querySelector('rd-home-footer')).toBeNull();

      http.expectOne((r) => r.url === `${TEST_API}/users/suggested` && r.params.get('limit') === '10').flush([
        writer('1', { isVerified: true, bio: 'Backend و .NET' }),
        writer('2'),
        writer('3'),
        writer('4'),
      ]);
      await stable();
      const rows = root.querySelectorAll('[data-home-suggestion]');
      expect(rows.length).toBe(3);
      expect(rows[0].textContent).toContain('Writer 1');
      expect(rows[0].textContent).toContain('Backend و .NET');
      expect(rows[0].querySelector('svg[aria-label="كاتب موثّق"]')).not.toBeNull();
      expect(rows[1].textContent).toContain('@writer2');
      expect(root.querySelector('[data-home-suggestions-all]')!.getAttribute('href')).toBe('/explore');

      // Follow: optimistic, "✓ Following" after.
      const follow = rows[1].querySelector<HTMLButtonElement>('[data-follow]')!;
      expect(follow.textContent).toContain('متابعة');
      follow.click();
      await stable();
      expect(follow.getAttribute('aria-pressed')).toBe('true');
      expect(follow.textContent).toContain('بتتابعه');
      http.expectOne({ method: 'PUT', url: `${TEST_API}/users/2/follow` }).flush({ isFollowing: true, followerCount: 1 });

      // The path: the first one you haven't enrolled in.
      expect(root.querySelector('[data-rail-path-loading]')).not.toBeNull();
      http.expectOne(`${TEST_API}/paths`).flush([
        testPathCard({ ...testProgress(2, { enrolled: true }) }),
        testPathCard({ id: 'p2', slug: 'ai', title: 'AI from scratch', articleCount: 6, readingTimeMinutes: 40 }),
      ]);
      await stable();
      const path = root.querySelector<HTMLAnchorElement>('[data-rail-path]')!;
      expect(path.getAttribute('href')).toBe('/paths/ai');
      expect(path.textContent).toContain('AI from scratch');
      expect(root.querySelector('[data-rail-path-meta]')!.textContent).toContain('6 مقالات · 40 دقيقة');
      expect(path.textContent).toContain('ابدأ');

      const footer = [...root.querySelectorAll<HTMLAnchorElement>('[data-home-footer] a')];
      expect(footer.map((a) => a.textContent!.trim())).toEqual(['عن ReadIn', 'الخصوصية', 'الشروط', 'المساعدة والتواصل']);
      expect(footer[1].getAttribute('href')).toMatch(/^https:\/\/.+\/privacy$/);
      expect(footer[3].getAttribute('href')).toMatch(/^mailto:/);
      expect(root.textContent).toContain('ReadIn ©');
    });

    it('nobody to suggest: no card, the path comes first', async () => {
      setup();
      const { root, stable } = render(HomeEndRail);
      http.expectOne((r) => r.url === `${TEST_API}/users/suggested`).flush([]);
      await stable();
      expect(root.querySelector('[data-home-suggestions]')).toBeNull();
      expect(root.querySelector('[data-home-suggestions-loading]')).toBeNull();
      http.expectOne(`${TEST_API}/paths`).flush([testPathCard()]);
      await stable();
      expect(root.querySelector('[data-rail-path]')!.getAttribute('href')).toBe('/paths/aspnet-core-basics');
    });

    it('guests: no suggestions; the first path; enrolled in all of them signed in: no path card', async () => {
      setup({ guest: true });
      let rendered = render(HomeEndRail);
      http.expectNone(`${TEST_API}/users/suggested`);
      http.expectOne(`${TEST_API}/paths`).flush([testPathCard(), testPathCard({ id: 'p2', slug: 'ai' })]);
      await rendered.stable();
      expect(rendered.root.querySelector('[data-rail-path]')!.getAttribute('href')).toBe('/paths/aspnet-core-basics');
      expect(rendered.root.querySelector('[data-home-footer]')).not.toBeNull();
      expect(footerInStart()).toBe(false);

      // No card left in the end column: the footer goes under the start column's cards, not alone at the top here.
      setup();
      rendered = render(HomeEndRail);
      http.expectOne((r) => r.url === `${TEST_API}/users/suggested`).flush([]);
      await rendered.stable();
      http.expectOne(`${TEST_API}/paths`).flush([testPathCard({ ...testProgress(1, { enrolled: true }) })]);
      await rendered.stable();
      expect(rendered.root.querySelector('[data-home-suggested-path]')).toBeNull();
      expect(rendered.root.querySelector('[data-home-footer]')).toBeNull();
      expect(footerInStart()).toBe(true);
    });

    it('the path fails to load (a guest): no card, and the footer goes to the start column', async () => {
      setup({ guest: true });
      const { root, stable } = render(HomeEndRail);
      http.expectOne(`${TEST_API}/paths`).flush({ code: 'server.error' }, { status: 500, statusText: 'Server Error' });
      await stable();
      expect(root.querySelector('[data-home-suggested-path]')).toBeNull();
      expect(root.querySelector('[data-rail-path-loading]')).toBeNull();
      expect(root.querySelector('[data-home-footer]')).toBeNull();
      expect(footerInStart()).toBe(true);
    });

    it('suggestions but no path: the footer stays under the suggestions', async () => {
      setup();
      const { root, stable } = render(HomeEndRail);
      http.expectOne((r) => r.url === `${TEST_API}/users/suggested`).flush([writer('1')]);
      await stable();
      http.expectOne(`${TEST_API}/paths`).flush([]);
      await stable();
      expect(root.querySelector('[data-home-suggestions]')).not.toBeNull();
      expect(root.querySelector('[data-home-footer]')).not.toBeNull();
      expect(footerInStart()).toBe(false);
    });
  });

  it('the columns: the page in the middle, the start and end columns as labeled asides', async () => {
    setup({ guest: true, layout: false });
    const { fixture, root, stable } = render(ColumnsHost);
    expect(root.querySelector('.home-main [data-centre]')).not.toBeNull();
    expect(root.querySelector('aside[data-home-start]')!.getAttribute('aria-label')).toBe('حسابك');
    expect(root.querySelector('aside[data-home-end]')!.getAttribute('aria-label')).toBe('اقتراحات ليك');
    await fixture.whenStable();
    await stable();
    http.match(`${TEST_API}/paths`).forEach((r) => r.flush([]));
  });
});

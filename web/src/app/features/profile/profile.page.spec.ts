import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Meta, Title } from '@angular/platform-browser';
import { NEVER } from 'rxjs';
import { testPathCard, testProgress } from '../../../testing/paths-testing';
import { testProfile } from '../../../testing/profile-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ProfileDto } from '../../core/api/models';
import { ReadingApi } from '../../core/api/reading.api';
import { ProfilesApi } from '../../core/api/profiles.api';
import { profileAvatar } from './profile-header';
import { ProfilePage } from './profile.page';

const isProfile = (username: string) => (r: { url: string }) => r.url === `${TEST_API}/users/${username}`;
const isArticles = (username: string) => (r: { url: string }) => r.url === `${TEST_API}/users/${username}/articles`;
const isReposts = (username: string) => (r: { url: string }) => r.url === `${TEST_API}/users/${username}/reposts`;

describe('ProfilePage (F14)', () => {
  let http: HttpTestingController;

  afterEach(() => http.verify());

  async function render(profile: ProfileDto | { status: number; code: string }, options: { guest?: boolean; articles?: number } = {}) {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({
      guest: options.guest,
      // The stats views load their own data; here they get an empty answer.
      providers: [
        { provide: ReadingApi, useValue: { stats: () => NEVER, heatmap: () => NEVER } },
        { provide: ProfilesApi, useFactory: () => stubStats(new ProfilesApi()) },
      ],
    }));
    const username = 'username' in profile ? profile.username : 'ghost';
    const fixture = TestBed.createComponent(ProfilePage);
    fixture.componentRef.setInput('username', username);
    fixture.detectChanges();
    const articles = Array.from({ length: options.articles ?? 2 }, (_, i) => testCard({ id: `a${i}`, slug: `a${i}`, title: `Article ${i}` }));
    http.expectOne(isArticles(username)).flush({ items: articles, nextCursor: null });
    const req = http.expectOne(isProfile(username));
    if ('status' in profile) req.flush(problem(profile.status, profile.code), { status: profile.status, statusText: 'Error' });
    else req.flush(profile);
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    };
    await stable();
    /** Renders without waiting for the app to be stable: a list loading through PendingTasks waits for its answer. */
    const settle = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await flushMicrotasks();
    };
    return { fixture, root, stable, settle, tabs: () => [...root.querySelectorAll('[data-profile-tab]')].map((t) => t.getAttribute('data-profile-tab')) };
  }

  /** Reading stats never answer in these tests: the card and heatmap stay on their skeletons. */
  function stubStats(api: ProfilesApi): ProfilesApi {
    return Object.assign(api, { stats: () => NEVER, heatmap: () => NEVER });
  }

  it('someone else: name, verified, title, @handle LTR, Follows you, Follow, bio in its own direction, link icons, stats', async () => {
    const { root } = await render(testProfile());
    const header = root.querySelector('[data-profile-header]')!;
    expect(header.querySelector('[data-profile-name]')!.textContent).toContain('Karim Hassan');
    expect(header.querySelector('[data-profile-name] svg')!.getAttribute('aria-label')).toBe('كاتب موثّق');
    // The title in full, aligned with the name, isolated in its own direction (it starts with an English word).
    expect(header.querySelector('[data-profile-headline]')!.textContent!.trim()).toBe('Frontend lead | Angular و performance');
    expect(header.querySelector('[data-profile-headline]')!.getAttribute('dir')).toBeNull();
    expect(header.querySelector('[data-profile-headline] rd-bdi-text')!.getAttribute('dir')).toBe('ltr');
    expect(header.querySelector('[data-profile-username]')!.getAttribute('dir')).toBe('ltr');
    expect(header.querySelector('[data-profile-username]')!.textContent).toBe('@karim');
    expect(header.querySelector('[data-profile-settings]')).toBeNull();
    expect(header.querySelector('[data-follows-you]')!.textContent).toContain('يتابعك');
    expect(header.querySelector('[data-profile-follow] [data-follow]')).not.toBeNull();
    expect(header.querySelector('[data-edit-profile]')).toBeNull();
    expect(header.querySelector('[data-profile-bio]')!.getAttribute('dir')).toBe('ltr');
    // Icons in the saved order, each named for its platform, opening in a new tab.
    const links = [...header.querySelectorAll<HTMLAnchorElement>('[data-profile-link]')];
    expect(links.map((a) => a.getAttribute('href'))).toEqual(['https://github.com/karim', 'https://karim.dev/']);
    expect(links.map((a) => a.getAttribute('aria-label'))).toEqual(['GitHub', 'الموقع']);
    expect(links.every((a) => a.target === '_blank' && a.rel.split(' ').includes('noopener') && a.rel.split(' ').includes('me'))).toBe(true);
    expect(links[0].querySelector('rd-link-icon svg')!.getAttribute('aria-hidden')).toBe('true');
    expect(header.querySelector('#' + links[0].getAttribute('aria-describedby'))!.textContent).toContain('يُفتح في علامة تبويب جديدة');
    expect(header.querySelector('[data-stat="followers"]')!.getAttribute('href')).toBe('/@karim/followers');
    expect(header.querySelector('[data-stat="following"]')!.getAttribute('href')).toBe('/@karim/following');
    expect(header.querySelector('[data-stat="reads"]')!.textContent).toContain('5.1');
    // Private stats: no reading section; no Saved tab.
    expect(root.querySelector('[data-profile-reading]')).toBeNull();
    expect(TestBed.inject(Title).getTitle()).toBe('Karim Hassan (@karim) — ReadIn');
    expect(TestBed.inject(Meta).getTag('property="og:type"')!.content).toBe('profile');
  });

  it('following moves the followers count at once', async () => {
    const { root, stable } = await render(testProfile());
    (root.querySelector('[data-profile-follow] [data-follow]') as HTMLElement).click();
    await stable();
    expect(root.querySelector('[data-stat="followers"]')!.textContent).toContain('341');
    http.expectOne(`${TEST_API}/users/writer-1/follow`).flush({ isFollowing: true, followerCount: 341 });
    await stable();
  });

  it('tabs: Articles / Categories / Reposts / Paths / About for someone else, with arrow keys mirrored in RTL', async () => {
    const { root, tabs, stable, settle } = await render(testProfile());
    expect(tabs()).toEqual(['articles', 'categories', 'reposts', 'paths', 'about']);
    expect(root.querySelectorAll('[data-profile-articles] rd-post-card')).toHaveLength(2);

    const articles = root.querySelector<HTMLElement>('[data-profile-tab="articles"]')!;
    articles.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowLeft', bubbles: true })); // RTL: the next tab
    await stable();
    expect(root.querySelector('[data-profile-tab="categories"]')!.getAttribute('aria-selected')).toBe('true');
    // Categories (F31, its own deferred chunk): their public list, with "مقالات أخرى" last.
    await stable();
    http.expectOne(`${TEST_API}/users/karim/categories`).flush({ items: [{ id: 'c1', slug: 'angular', name: 'Angular', articleCount: 3, sortOrder: 1 }], uncategorizedCount: 2 });
    await stable();
    const cards = [...root.querySelectorAll('[data-profile-categories] [data-category-card]')];
    expect(cards.map((c) => c.getAttribute('data-category-card'))).toEqual(['angular', '_other']);
    expect(cards[1].textContent).toContain('مقالات أخرى');

    root.querySelector<HTMLElement>('[data-profile-tab="categories"]')!.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowLeft', bubbles: true }));
    await settle();
    expect(root.querySelector('[data-profile-tab="reposts"]')!.getAttribute('aria-selected')).toBe('true');
    http.expectOne(isReposts('karim')).flush({ items: [], nextCursor: null });
    await stable();
    expect(root.querySelector('[data-profile-reposts] [data-reposts-empty]')!.textContent).toContain('لا توجد إعادات نشر بعد');

    root.querySelector<HTMLElement>('[data-profile-tab="reposts"]')!.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowLeft', bubbles: true }));
    await stable();
    expect(root.querySelector('[data-profile-tab="paths"]')!.getAttribute('aria-selected')).toBe('true');
    // Private reading stats: their paths are private too (no request).
    expect(root.querySelector('[data-profile-paths] [data-paths-private]')!.textContent).toContain('هذه المسارات خاصة');
    http.expectNone((r) => r.url.endsWith('/paths'));

    (root.querySelector('[data-profile-tab="about"]') as HTMLElement).click();
    await stable();
    const about = root.querySelector('[data-profile-about]')!;
    expect(about.querySelector('[data-profile-expertise]')!.textContent).toContain('البرمجيات');
    expect(about.querySelector('[data-profile-joined]')!.textContent).toContain('2026');
  });

  it('your own profile: Edit profile, a Saved tab, reading stats with the public switch', async () => {
    const { root, tabs, stable } = await render(testProfile({ id: 'user-1', username: 'mona', isMe: true, followsYou: false, readingStatsVisible: true }), { articles: 0 });
    expect(root.querySelector('[data-edit-profile]')!.getAttribute('href')).toBe('/settings/profile');
    // Narrow screens have no side nav: Settings (and Delete account at its end) is one tap away.
    expect(root.querySelector('[data-profile-settings]')!.getAttribute('href')).toBe('/settings');
    expect(root.querySelector('[data-profile-follow]')).toBeNull();
    expect(root.querySelector('[data-follows-you]')).toBeNull();
    expect(tabs()).toEqual(['articles', 'categories', 'reposts', 'saved', 'paths', 'about']);
    expect(root.querySelector('[data-profile-reading] [data-public-stats] [role="switch"]')).not.toBeNull();
    expect(root.querySelector('[data-articles-empty]')!.textContent).toContain('لم تنشر أي مقالات بعد');

    (root.querySelector('[data-profile-tab="saved"]') as HTMLElement).click();
    await stable();
    http.expectOne((r) => r.url === `${TEST_API}/me/saved`).flush({ items: [], nextCursor: null });
    await stable();
    expect(root.querySelector('[data-profile-saved] [data-saved-empty]')).not.toBeNull();
  });

  it('Reposts tab (F29): the reposted articles as post cards, newest first, then the next page; your own empty state', async () => {
    const { root, stable, settle } = await render(testProfile());
    (root.querySelector('[data-profile-tab="reposts"]') as HTMLElement).click();
    await settle();
    expect(root.querySelector('[data-profile-reposts] [aria-busy="true"]')).not.toBeNull();
    const label = { user: { id: 'writer-1', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true }, othersCount: 0, repostedAt: '2026-11-04T09:00:00Z' };
    const first = http.expectOne(isReposts('karim'));
    expect(first.request.params.get('limit')).toBe('20');
    first.flush({
      items: [testCard({ id: 'r1', slug: 'r1', title: 'Newest repost', repostedBy: label }), testCard({ id: 'r2', slug: 'r2', title: 'Older repost', repostedBy: label })],
      nextCursor: 'c2',
    });
    await stable();
    const titles = () => [...root.querySelectorAll('[data-profile-reposts] rd-post-card')].map((c) => c.textContent);
    expect(titles()).toEqual([expect.stringContaining('Newest repost'), expect.stringContaining('Older repost')]);
    expect(root.querySelector('[data-reposts-end]')).toBeNull();

    const own = await render(testProfile({ id: 'user-1', username: 'mona', isMe: true, readingStatsVisible: true }));
    (own.root.querySelector('[data-profile-tab="reposts"]') as HTMLElement).click();
    await own.settle();
    http.expectOne(isReposts('mona')).flush({ items: [], nextCursor: null });
    await own.stable();
    expect(own.root.querySelector('[data-reposts-empty]')!.textContent).toContain('عندما تعيد نشر مقال أعجبك، سيظهر هنا ولدى متابعيك.');
  });

  it('a failed Reposts tab offers a retry', async () => {
    const { root, stable, settle } = await render(testProfile());
    (root.querySelector('[data-profile-tab="reposts"]') as HTMLElement).click();
    await settle();
    http.expectOne(isReposts('karim')).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await stable();
    (root.querySelector('[data-profile-reposts] rd-error-state button') as HTMLElement).click();
    await settle();
    http.expectOne(isReposts('karim')).flush({ items: [testCard({ id: 'r1', slug: 'r1' })], nextCursor: null });
    await stable();
    expect(root.querySelectorAll('[data-profile-reposts] rd-post-card')).toHaveLength(1);
    expect(root.querySelector('[data-reposts-end]')).not.toBeNull();
  });

  it('no title and no links: neither line is shown', async () => {
    const { root } = await render(testProfile({ headline: null, links: [] }));
    expect(root.querySelector('[data-profile-headline]')).toBeNull();
    expect(root.querySelector('[data-profile-links]')).toBeNull();
  });

  it('the session already knows it is you before the personalized copy arrives', async () => {
    const { root } = await render(testProfile({ id: 'user-1', username: 'mona', isMe: false, readingStatsVisible: false }));
    expect(root.querySelector('[data-edit-profile]')).not.toBeNull();
    expect(root.querySelector('[data-profile-reading]')).not.toBeNull();
  });

  it('public reading stats show for guests, without the switch', async () => {
    const { root } = await render(testProfile({ readingStatsVisible: true }), { guest: true });
    expect(root.querySelector('[data-profile-reading] rd-reading-stats-card')).not.toBeNull();
    expect(root.querySelector('[data-public-stats]')).toBeNull();
    expect(root.querySelector('[data-follows-you]')).not.toBeNull(); // as the API said
  });

  it('an unknown user is a not-found state', async () => {
    const { root } = await render({ status: 404, code: 'user.not_found' });
    expect(root.querySelector('[data-profile-not-found]')!.textContent).toContain('هذا المستخدم غير موجود');
  });

  it('Paths tab with public stats: their enrolled paths with progress and completion badges (F09)', async () => {
    const { root, stable } = await render(testProfile({ readingStatsVisible: true }));
    (root.querySelector('[data-profile-tab="paths"]') as HTMLElement).click();
    await stable();
    http.expectOne(`${TEST_API}/users/karim/paths`).flush([
      testPathCard({ ...testProgress(1, { enrolled: true }) }),
      testPathCard({ id: 'p2', slug: 'ai', title: 'AI from scratch', ...testProgress(4, { completed: true }) }),
    ]);
    await flushMicrotasks();
    TestBed.tick();
    // Covers without an image ask for the fields' icons.
    http.match(`${TEST_API}/fields`).forEach((r) => r.flush([]));
    await stable();
    const cards = root.querySelectorAll('[data-profile-paths] [data-path-card]');
    expect(cards).toHaveLength(2);
    expect(cards[0].querySelector('[data-path-progress]')!.textContent).toContain('1/4');
    expect(cards[1].querySelector('[data-path-completed]')).not.toBeNull();
  });

  it('Paths tab: empty on your own profile leads to /paths; a 403 shows the private state', async () => {
    const own = await render(testProfile({ id: 'user-1', username: 'mona', isMe: true, readingStatsVisible: true }));
    (own.root.querySelector('[data-profile-tab="paths"]') as HTMLElement).click();
    await own.stable();
    http.expectOne(`${TEST_API}/users/mona/paths`).flush([]);
    await own.stable();
    expect(own.root.querySelector('[data-paths-empty]')!.textContent).toContain('ستظهر هنا المسارات التي تبدؤها.');
    expect(own.root.querySelector('[data-browse-paths]')!.getAttribute('href')).toBe('/paths');

    const other = await render(testProfile({ readingStatsVisible: true }));
    (other.root.querySelector('[data-profile-tab="paths"]') as HTMLElement).click();
    await other.stable();
    http.expectOne(`${TEST_API}/users/karim/paths`).flush(problem(403, 'profile.stats_private'), { status: 403, statusText: 'Forbidden' });
    await other.stable();
    expect(other.root.querySelector('[data-paths-private]')).not.toBeNull();
  });

  it('a failed load offers a retry', async () => {
    const { root, stable } = await render({ status: 500, code: 'server.error' });
    (root.querySelector('rd-error-state button') as HTMLElement).click();
    await flushMicrotasks();
    TestBed.tick();
    http.expectOne(isProfile('ghost')).flush(testProfile({ username: 'ghost' }));
    await stable();
    expect(root.querySelector('[data-profile-header]')).not.toBeNull();
  });
});

describe('profileAvatar', () => {
  it('uses the 256 px variant with a srcset up to 512, or the plain URL', () => {
    expect(profileAvatar({ avatarUrl: null, avatarVariants: null })).toBeNull();
    expect(profileAvatar({ avatarUrl: 'https://x/old.webp', avatarVariants: null })).toEqual({ src: 'https://x/old.webp', srcset: null });
    expect(profileAvatar({ avatarUrl: 'https://x/a_256', avatarVariants: { '64': 'https://x/a_64', '128': 'https://x/a_128', '256': 'https://x/a_256', '512': 'https://x/a_512' } })).toEqual({
      src: 'https://x/a_256',
      srcset: 'https://x/a_128 128w, https://x/a_256 256w, https://x/a_512 512w',
    });
  });
});

import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto, ArticlePreviewDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { FollowStore } from '../../core/social/follow.store';
import { MuteStore, keepMutedContent } from '../../core/social/mute.store';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { FeedMemory } from './feed-memory';
import { PostCard } from './post-card';

const PREVIEW = `${TEST_API}/articles/a1/preview`;

function preview(patch: Partial<ArticlePreviewDto> = {}): ArticlePreviewDto {
  return {
    id: 'a1',
    language: 'en',
    content: {
      version: 1,
      language: 'en',
      blocks: [
        { id: 'p1', type: 'paragraph', dir: 'auto', content: [{ type: 'text', text: 'Four circles on a whiteboard explain most of Clean Architecture.' }] },
        { id: 'e1', type: 'embed', provider: 'youtube', url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' },
      ],
    },
    isComplete: false,
    ...patch,
  };
}

/** jsdom has neither matchMedia nor IntersectionObserver: wide screens and "on screen" are what the test says. */
function stubViewport(wide: boolean): void {
  vi.stubGlobal('matchMedia', (query: string) => ({
    matches: query.includes('min-width') ? wide : false,
    media: query,
    addEventListener: () => undefined,
    removeEventListener: () => undefined,
  }));
}

async function render(article: ArticleCardDto, options: { guest?: boolean; lang?: 'ar' | 'en'; wide?: boolean; label?: string } = {}) {
  stubViewport(options.wide ?? true);
  const { http } = setupSocialTesting({ guest: options.guest });
  await TestBed.inject(LanguageService).setLanguage(options.lang ?? 'ar');
  const fixture = TestBed.createComponent(PostCard);
  fixture.componentRef.setInput('article', article);
  if (options.label) fixture.componentRef.setInput('label', options.label);
  fixture.detectChanges();
  await fixture.whenStable();
  // Signed in, the reading tracker's streak store asks for your stats once (F08); not this card's business.
  for (const req of http.match((r) => r.url === `${TEST_API}/me/stats`)) req.flush(null, { status: 503, statusText: 'Unavailable' });
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    for (let i = 0; i < 3; i++) {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    }
  };
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  const $$ = (selector: string) => [...root.querySelectorAll<HTMLElement>(selector)];
  return { fixture, root, http, stable, $, $$ };
}

describe('PostCard (F34)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => {
    TestBed.resetTestingModule();
    sessionStorage.clear();
  });

  afterEach(() => {
    http?.verify();
    http = null;
    vi.unstubAllGlobals();
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
  });

  describe('header', () => {
    it('shows the writer (photo and name open the profile), the field, the time since publishing and the reading time', async () => {
      const t = await render(testCard(), { guest: true });
      http = t.http;
      expect(t.$('[data-card-author]')!.getAttribute('href')).toBe('/@karim');
      expect(t.$('[data-card-author]')!.textContent).toContain('Karim Hassan');
      expect(t.$('[data-card-author] svg[aria-label="كاتب موثّق"]')).not.toBeNull();
      expect(t.$('[data-card-avatar]')!.getAttribute('href')).toBe('/@karim');
      expect(t.$('[data-card-avatar] rd-avatar')!.textContent!.trim()).toBe('K');
      const meta = t.$('[data-card-meta]')!;
      expect(meta.textContent).toContain('البرمجيات');
      expect(meta.querySelector('time')!.getAttribute('datetime')).toBe('2026-11-02T08:00:00Z');
      expect(meta.textContent).toContain('4 دقائق للقراءة');
    });

    it('guests see Follow, which asks them to sign in and remembers the card to come back to', async () => {
      const t = await render(testCard(), { guest: true });
      http = t.http;
      t.$('[data-card-follow] [data-follow]')!.click();
      expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
      expect(TestBed.inject(FeedMemory).pendingReturn()).toMatchObject({ articleId: 'a1', comments: false });
    });

    it('no Follow when you follow the writer or wrote the article; it stays after you follow, to undo', async () => {
      const following = await render(testCard({ isFollowingAuthor: true }));
      expect(following.$('[data-card-follow]')).toBeNull();
      following.http.verify();

      TestBed.resetTestingModule();
      const own = await render(testCard({ author: { id: 'user-1', displayName: 'Mona Adel', username: 'mona', avatarUrl: null, isVerified: false } }));
      expect(own.$('[data-card-follow]')).toBeNull();
      own.http.verify();

      TestBed.resetTestingModule();
      const t = await render(testCard());
      http = t.http;
      const follow = t.$('[data-card-follow] [data-follow]')!;
      follow.click();
      await t.stable();
      t.http.expectOne(`${TEST_API}/users/writer-1/follow`).flush({ isFollowing: true, followerCount: 1 });
      await t.stable();
      expect(TestBed.inject(FollowStore).isFollowing('writer-1', false)).toBe(true);
      expect(t.$('[data-card-follow] [data-follow]')!.getAttribute('aria-pressed')).toBe('true');
    });

    it('a deleted account’s article says “Deleted user”: no profile link and no Follow (SPEC §9.6)', async () => {
      const t = await render(testCard({ author: null }), { guest: true, lang: 'en' });
      http = t.http;
      expect(t.$('[data-deleted-author]')!.textContent!.trim()).toBe('Deleted user');
      expect(t.$('rd-avatar[data-generic-avatar]')).not.toBeNull();
      expect(t.root.querySelector('a[href^="/@"]')).toBeNull();
      expect(t.$('[data-card-follow]')).toBeNull();
      expect(t.$('[data-card-save]')).not.toBeNull();
    });

    it('a label above the card: Home’s daily article', async () => {
      const t = await render(testCard(), { guest: true, label: 'feedCard.todayLabel' });
      http = t.http;
      expect(t.$('[data-card-label]')!.textContent!.trim()).toBe('مقال اليوم');
    });

    it('the writer’s title on one line under the name, in its own direction, above the meta line (F14)', async () => {
      const author = { id: 'writer-1', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true, headline: 'Frontend lead | React & Angular' };
      const t = await render(testCard({ author }), { guest: true });
      http = t.http;
      const headline = t.$('[data-card-headline]')!;
      expect(headline.textContent!.trim()).toBe('Frontend lead | React & Angular');
      // Placed in the UI's direction; the text laid out and cut ("…") in its own direction (§14), so a title in the
      // other script keeps its beginning.
      expect(headline.hasAttribute('dir')).toBe(false);
      expect(headline.classList).toContain('flex');
      expect(headline.classList).not.toContain('truncate');
      const text = headline.querySelector('bdi')!;
      expect(text.getAttribute('dir')).toBe('auto');
      expect(text.classList).toContain('truncate');
      expect(text.classList).toContain('min-w-0');
      expect(headline.getAttribute('title')).toBe('Frontend lead | React & Angular');
      // Name, then the title, then field · time · reading time.
      expect(headline.compareDocumentPosition(t.$('[data-card-meta]')!) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
      expect(t.$('[data-card-author]')!.compareDocumentPosition(headline) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    });

    it('no title line without a title (null, blank or an older API)', async () => {
      for (const headline of [null, '   ', undefined]) {
        TestBed.resetTestingModule();
        const author = { id: 'writer-1', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true, headline };
        const t = await render(testCard({ author }), { guest: true });
        expect(t.$('[data-card-headline]')).toBeNull();
        t.http.verify();
      }
    });

    it('a repost label: "أعاد نشره {name}", the name a link to the profile in its own direction (F29)', async () => {
      const reposter = { id: 'u-readin', displayName: 'ReadIn', username: 'readin', avatarUrl: null, isVerified: true };
      const t = await render(testCard({ repostedBy: { user: reposter, othersCount: 0, repostedAt: '2026-11-03T10:00:00Z' } }), { guest: true });
      http = t.http;
      const label = t.$('[data-card-repost-label]')!;
      expect(label.textContent!.replace(/\s+/g, ' ').trim()).toBe('أعاد نشره ReadIn');
      const name = label.querySelector('[data-card-reposter]')!;
      expect(name.getAttribute('href')).toBe('/@readin');
      expect(name.getAttribute('dir')).toBe('auto');
    });

    it('several reposters: "{name} و N غيره" / "{name} and N others", with plurals', async () => {
      const reposter = { id: 'u-karim', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true };
      const label = async (othersCount: number, lang: 'ar' | 'en') => {
        TestBed.resetTestingModule();
        const t = await render(testCard({ repostedBy: { user: reposter, othersCount, repostedAt: '2026-11-03T12:00:00Z' } }), { guest: true, lang });
        const text = t.$('[data-card-repost-label]')!.textContent!.replace(/\s+/g, ' ').trim();
        t.http.verify();
        return text;
      };
      expect(await label(1, 'ar')).toBe('أعاد نشره Karim Hassan وشخص آخر');
      expect(await label(3, 'ar')).toBe('أعاد نشره Karim Hassan و3 آخرون');
      expect(await label(1, 'en')).toBe('Karim Hassan and 1 other reposted this');
      expect(await label(4, 'en')).toBe('Karim Hassan and 4 others reposted this');
      expect(await label(0, 'en')).toBe('Karim Hassan reposted this');
    });

    it('Today’s label wins over a repost label', async () => {
      const reposter = { id: 'u-readin', displayName: 'ReadIn', username: 'readin', avatarUrl: null, isVerified: true };
      const t = await render(testCard({ repostedBy: { user: reposter, othersCount: 0, repostedAt: '2026-11-03T10:00:00Z' } }), { guest: true, label: 'feedCard.todayLabel' });
      http = t.http;
      expect(t.$('[data-card-repost-label]')).toBeNull();
      expect(t.$$('[data-card-label]')).toHaveLength(1);
    });

    describe('the reposter’s thoughts (F29 caption)', () => {
      const reposter = { id: 'u-karim', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true };
      const labeled = (caption: string | null | undefined, user = reposter) =>
        testCard({ repostedBy: { user, othersCount: 0, repostedAt: '2026-11-03T12:00:00Z', ...(caption === undefined ? {} : { caption }) } });

      it('under the label line and above the card’s header: plain text, never HTML, in its own direction, line breaks kept', async () => {
        const caption = 'أحسن مقال قريته عن الـ Clean Architecture.\n<b>مش HTML</b> <img src=x onerror=alert(1)>';
        const t = await render(labeled(caption), { guest: true });
        http = t.http;
        const box = t.$('[data-card-repost]')!;
        const text = t.$('[data-card-repost-caption]')!;
        expect(box.contains(t.$('[data-card-repost-label]'))).toBe(true);
        expect(box.contains(text)).toBe(true);
        expect(t.$('[data-card-repost-label]')!.compareDocumentPosition(text) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
        expect(text.compareDocumentPosition(t.$('header')!) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
        // The label keeps its own text; the thoughts are their own block.
        expect(t.$('[data-card-repost-label]')!.textContent!.replace(/\s+/g, ' ').trim()).toBe('أعاد نشره Karim Hassan');
        expect(text.textContent!.trim()).toBe(caption);
        expect(text.querySelector('b, img')).toBeNull();
        expect(text.getAttribute('dir')).toBe('rtl');
        expect(text.classList).toContain('rd-card-text'); // white-space: pre-line
        expect(text.classList).toContain('excerpt'); // cut at 4 lines
        expect(t.$('[data-card-caption-more]')).toBeNull(); // short enough
      });

      it('an English caption reads left to right in the Arabic UI', async () => {
        const t = await render(labeled('Worth a read before your next project.'), { guest: true });
        http = t.http;
        expect(t.$('[data-card-repost-caption]')!.getAttribute('dir')).toBe('ltr');
      });

      it('no thoughts (null, missing or only spaces): the label line alone', async () => {
        for (const caption of [null, undefined, '   ']) {
          TestBed.resetTestingModule();
          const t = await render(labeled(caption), { guest: true });
          expect(t.$('[data-card-repost-label]')).not.toBeNull();
          expect(t.$('[data-card-repost-caption]')).toBeNull();
          t.http.verify();
        }
      });

      it('longer than 4 lines: "… اقرأ المزيد" at the end, which shows them all', async () => {
        // jsdom lays nothing out: the caption says it is taller than its box.
        vi.stubGlobal(
          'ResizeObserver',
          class {
            constructor(private readonly callback: () => void) {}
            observe(el: HTMLElement) {
              if (el.hasAttribute('data-card-repost-caption')) {
                Object.defineProperty(el, 'scrollHeight', { configurable: true, get: () => (el.classList.contains('excerpt') ? 300 : 108) });
                Object.defineProperty(el, 'clientHeight', { configurable: true, value: 108 });
              }
              queueMicrotask(() => this.callback());
            }
            unobserve = () => undefined;
            disconnect = () => undefined;
          },
        );
        const t = await render(labeled('سطر\n'.repeat(8).trim()), { guest: true });
        http = t.http;
        await t.stable();
        const more = t.$('[data-card-caption-more]')!;
        expect(more.textContent!.trim()).toBe('… قراءة المزيد');
        expect(more.getAttribute('aria-label')).toBe('عرض رأي Karim Hassan كاملًا');
        expect(more.getAttribute('aria-expanded')).toBe('false');
        expect(more.getAttribute('aria-controls')).toBe(t.$('[data-card-repost-caption]')!.id);
        more.click();
        await t.stable();
        const text = t.$('[data-card-repost-caption]')!;
        expect(text.classList).not.toContain('excerpt');
        expect(text.hasAttribute('data-expanded')).toBe(true);
        expect(t.$('[data-card-caption-more]')).toBeNull();
        expect(document.activeElement).toBe(text);
      });

      it('your own Reposts tab: thoughts you edit or clear here show at once', async () => {
        const me = { id: 'user-1', displayName: 'Mona Adel', username: 'mona', avatarUrl: null, isVerified: false };
        const article = labeled('Old thoughts', me);
        const t = await render(article);
        http = t.http;
        expect(t.$('[data-card-repost-caption]')!.textContent!.trim()).toBe('Old thoughts');
        const store = TestBed.inject(ArticleSocialStore);
        store.applyRepost(article, { repostCount: 1, isReposted: true, caption: 'New thoughts' });
        await t.stable();
        expect(t.$('[data-card-repost-caption]')!.textContent!.trim()).toBe('New thoughts');
        store.applyRepost(article, { repostCount: 1, isReposted: true, caption: null });
        await t.stable();
        expect(t.$('[data-card-repost-caption]')).toBeNull();
      });

      it('someone else’s thoughts never take yours', async () => {
        const article = labeled('Karim’s thoughts');
        const t = await render(article);
        http = t.http;
        TestBed.inject(ArticleSocialStore).applyRepost(article, { repostCount: 1, isReposted: true, caption: 'Mine' });
        await t.stable();
        expect(t.$('[data-card-repost-caption]')!.textContent!.trim()).toBe('Karim’s thoughts');
      });
    });
  });

  describe('text', () => {
    it('the title opens the reader; the card is no longer one big link', async () => {
      const t = await render(testCard(), { guest: true });
      http = t.http;
      const title = t.$('[data-card-title]')!;
      expect(title.getAttribute('href')).toBe('/en/a/clean-architecture');
      expect(title.classList).toContain('line-clamp-3');
      expect(t.$('article')!.getAttribute('aria-labelledby')).toBe(t.$('h3')!.id);
      expect(t.$$('a[href="/en/a/clean-architecture"]')).toHaveLength(1);
    });

    it('the excerpt in its own direction, with "… Read more" isolated at its end', async () => {
      const t = await render(testCard({ excerpt: 'الـ Transformer بيبص على الجملة كلها مرة واحدة.', language: 'ar-EG' }), { guest: true, lang: 'en' });
      http = t.http;
      const excerpt = t.$('[data-card-excerpt]')!;
      expect(excerpt.getAttribute('dir')).toBe('rtl');
      expect(excerpt.getAttribute('lang')).toBe('ar-EG');
      const more = t.$('[data-card-read-more]')!;
      expect(more.tagName).toBe('BUTTON');
      expect(more.getAttribute('aria-expanded')).toBe('false');
      expect(more.getAttribute('aria-label')).toBe('Read more of “Clean Architecture on one whiteboard”');
      // Its own isolate in the UI's direction, so it never mixes with the text around it (§14.2).
      expect(more.querySelector('bdi')!.getAttribute('dir')).toBe('ltr');
      expect(more.textContent!.trim()).toBe('… Read more');
    });

    it('no "Read more" when the excerpt is the whole article', async () => {
      const t = await render(testCard({ hasMore: false, excerpt: 'Short and complete.' }), { guest: true });
      http = t.http;
      expect(t.$('[data-card-excerpt]')!.textContent).toContain('Short and complete.');
      expect(t.$('[data-card-read-more]')).toBeNull();
    });

    it('an article not backfilled yet: no text, but "Read more"', async () => {
      const t = await render(testCard({ excerpt: null }), { guest: true });
      http = t.http;
      expect(t.$('[data-card-excerpt]')).toBeNull();
      expect(t.$('[data-card-read-more]')).not.toBeNull();
    });

    it('"Read more" loads the preview once and shows it with the reader’s renderer; "Show less" folds it back', async () => {
      const t = await render(testCard(), { guest: true });
      http = t.http;
      t.$('[data-card-read-more]')!.click();
      await t.stable();
      const req = t.http.expectOne((r) => r.url === PREVIEW);
      expect(req.request.params.get('lang')).toBe('en');
      expect(t.$('[data-card-preview-loading]')).not.toBeNull();
      req.flush(preview());
      await t.stable();

      expect(t.$('[data-card-excerpt]')).toBeNull();
      const content = t.$('[data-card-preview]')!;
      expect(content.tagName).toBe('RD-RDOC');
      expect(content.textContent).toContain('Four circles on a whiteboard');
      // Embeds show as a link, never a player.
      expect(content.querySelector('iframe')).toBeNull();
      expect(content.querySelector('[data-block-type="embed"] a')!.getAttribute('href')).toContain('youtube.com');
      expect(t.$('[data-card-read-full]')!.getAttribute('href')).toBe('/en/a/clean-architecture');
      // Focus stays in the card, on its text.
      expect(document.activeElement).toBe(t.$('[data-card-text]'));
      const less = t.$('[data-card-show-less]')!;
      expect(less.getAttribute('aria-expanded')).toBe('true');
      expect(less.textContent).toContain('عرض أقل');

      less.click();
      await t.stable();
      expect(t.$('[data-card-preview]')).toBeNull();
      expect(document.activeElement).toBe(t.$('[data-card-read-more]'));

      // The second time, the preview is already there.
      t.$('[data-card-read-more]')!.click();
      await t.stable();
      t.http.expectNone((r) => r.url === PREVIEW);
      expect(t.$('[data-card-preview]')).not.toBeNull();
    });

    it('the whole article in the card: no "Read the full article"', async () => {
      const t = await render(testCard(), { guest: true });
      http = t.http;
      t.$('[data-card-excerpt]')!.click(); // the text expands too
      await t.stable();
      t.http.expectOne((r) => r.url === PREVIEW).flush(preview({ isComplete: true }));
      await t.stable();
      expect(t.$('[data-card-preview]')).not.toBeNull();
      expect(t.$('[data-card-read-full]')).toBeNull();
    });

    it('a failed preview keeps the excerpt and offers a retry', async () => {
      const t = await render(testCard(), { guest: true });
      http = t.http;
      t.$('[data-card-read-more]')!.click();
      await t.stable();
      t.http.expectOne((r) => r.url === PREVIEW).flush(null, { status: 500, statusText: 'Error' });
      await t.stable();
      const error = t.$('[data-card-preview-error]')!;
      expect(error.getAttribute('role')).toBe('alert');
      expect(error.textContent).toContain('تعذّر تحميل بقية المقال.');
      expect(t.$('rd-card-preview')!.textContent).toContain('Four circles on a whiteboard');

      error.querySelector('button')!.click();
      await t.stable();
      t.http.expectOne((r) => r.url === PREVIEW).flush(preview());
      await t.stable();
      expect(t.$('[data-card-preview]')).not.toBeNull();
    });
  });

  describe('media, tags and counts', () => {
    it('no attachments and no cover: no image at all (the old placeholder is gone)', async () => {
      const t = await render(testCard(), { guest: true });
      http = t.http;
      expect(t.$('img')).toBeNull();
      expect(t.root.textContent).not.toContain('</>');
    });

    it('the cover at full width, 16:9; attachments win over it', async () => {
      const withCover = await render(testCard({ coverUrl: 'https://cdn.example/cover.webp' }), { guest: true });
      const cover = withCover.$('[data-card-cover]')!;
      expect(cover.tagName).toBe('BUTTON');
      expect(cover.querySelector('img')!.classList).toContain('aspect-video');
      withCover.http.verify();

      TestBed.resetTestingModule();
      const image = { assetId: 'img-1', order: 0, caption: null, altText: 'Whiteboard', width: 1600, height: 1200, blurHash: null, variants: [] };
      const t = await render(testCard({ coverUrl: 'https://cdn.example/cover.webp', attachments: { kind: 'images', images: [image], document: null } }), {
        guest: true,
      });
      http = t.http;
      expect(t.$('rd-article-attachments')).not.toBeNull();
      expect(t.$('[data-card-cover]')).toBeNull();
    });

    it('up to 3 tags, each a link to its tag page (F32), then a plain "+N"', async () => {
      const tags = [
        { slug: 'csharp', name: 'C#' },
        { slug: 'dotnet-2', name: '.NET' },
        { slug: 'الذكاء-الاصطناعي', name: 'الذكاء الاصطناعي' },
      ];
      const t = await render(testCard({ tags, tagCount: 5 }), { guest: true });
      http = t.http;
      const chips = t.$$('[data-card-tags] li');
      expect(chips.map((c) => c.textContent!.trim())).toEqual(['#C#', '#.NET', '#الذكاء الاصطناعي', '+2وسمان آخران']);
      const links = t.$$('[data-card-tags] a');
      // The slug from the server, never one made from the name; an Arabic one is percent-encoded.
      expect(links.map((a) => a.getAttribute('href'))).toEqual(['/tags/csharp', '/tags/dotnet-2', `/tags/${encodeURIComponent('الذكاء-الاصطناعي')}`]);
      expect(links.every((a) => a.getAttribute('dir') === 'auto')).toBe(true);
      expect(chips[3].querySelector('a')).toBeNull();
    });

    it('the action bar has no counts row: up to 3 reaction emojis open who reacted, on the other side', async () => {
      const t = await render(testCard(), { guest: true });
      http = t.http;
      expect(t.$('[data-card-counts]')).toBeNull();
      const summary = t.$('[data-card-actions] [data-reactions-summary]')!;
      expect(summary.textContent!.replace(/\s/g, '')).toBe('💡❤️🔥');
      expect(summary.getAttribute('aria-label')).toBe('12 تفاعلًا، عرض من تفاعل');
      expect(summary.classList).toContain('ms-auto');
    });

    it('a count of 0 shows no number, and no reaction emojis', async () => {
      const t = await render(testCard({ reactionCount: 0, reactions: { insightful: 0, love: 0, fire: 0, mindBlown: 0 }, commentCount: 0, repostCount: 0 }), {
        guest: true,
        lang: 'en',
      });
      http = t.http;
      expect(t.$('[data-react-count]')).toBeNull();
      expect(t.$('[data-card-comment-count]')).toBeNull();
      expect(t.$('[data-repost-count]')).toBeNull();
      expect(t.$('[data-reactions-summary]')).toBeNull();
      expect(t.$('[data-react]')!.getAttribute('aria-label')).toBe('React');
      expect(t.$('[data-card-comment]')!.getAttribute('aria-label')).toBe('Comment');
      expect(t.$('[data-repost]')!.getAttribute('aria-label')).toBe('Repost');
    });
  });

  describe('action bar', () => {
    it('icons only: React, Comment, Repost, then Share, each named with its count (§26)', async () => {
      const t = await render(testCard({ repostCount: 5 }), { guest: true, lang: 'en' });
      http = t.http;
      const bar = t.$('[data-card-actions]')!;
      expect(bar.getAttribute('role')).toBe('group');
      const buttons = [...bar.querySelectorAll('button')];
      // No text labels: only the counts beside the icons, and the reaction emojis on the other side.
      expect(buttons.map((b) => b.textContent!.replace(/\s/g, ''))).toEqual(['12', '3', '5', '', '💡❤️🔥']);
      expect(buttons.map((b) => b.getAttribute('aria-label'))).toEqual(['React, 12', 'Comment, 3', 'Repost, 5', 'Share', '12 reactions, see who reacted']);
      expect(bar.querySelector('[data-react]')!.getAttribute('aria-keyshortcuts')).toBe('ArrowUp');
      expect(bar.querySelector('[data-react]')!.getAttribute('aria-pressed')).toBe('false');
      expect(bar.querySelector('[data-react] svg')).not.toBeNull(); // the 💡 line icon until you react
    });

    it('Arabic names: "تفاعل، 12", "تعليق، 3", "إعادة نشر، 5", "مشاركة"', async () => {
      const t = await render(testCard({ repostCount: 5 }), { guest: true });
      http = t.http;
      expect(t.$('[data-react]')!.getAttribute('aria-label')).toBe('تفاعل، 12');
      expect(t.$('[data-card-comment]')!.getAttribute('aria-label')).toBe('تعليق، 3');
      expect(t.$('[data-repost]')!.getAttribute('aria-label')).toBe('إعادة نشر، 5');
      expect(t.$('[data-card-share]')!.getAttribute('aria-label')).toBe('مشاركة');
    });

    it('a tap reacts 💡 at once and the icon shows it; ArrowUp opens the four reactions', async () => {
      const t = await render(testCard());
      http = t.http;
      const react = t.$('[data-card-actions] [data-react]')!;
      react.click();
      await t.stable();
      expect(react.getAttribute('data-my-reaction')).toBe('insightful');
      expect(react.getAttribute('aria-pressed')).toBe('true');
      expect(react.querySelector('[data-react-icon]')!.textContent!.trim()).toBe('💡');
      expect(react.getAttribute('aria-label')).toBe('تفاعلت: مفيد، 13');
      const req = t.http.expectOne(`${TEST_API}/articles/a1/reaction`);
      expect(req.request.body).toEqual({ type: 'insightful' });
      req.flush({ reactions: { insightful: 7, love: 3, fire: 2, mindBlown: 1 }, total: 13, myReaction: 'insightful' });
      await t.stable();
      expect(t.$('[data-react-count]')!.textContent!.trim()).toBe('13');

      react.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowUp', bubbles: true }));
      await t.stable();
      expect(t.$$('[data-card-actions] [data-reaction-picker] [role="menuitemradio"]')).toHaveLength(4);
    });

    it('Repost toggles at once and rolls back with the error when the API refuses (F29)', async () => {
      const t = await render(testCard({ repostCount: 2 }));
      http = t.http;
      const repost = t.$('[data-repost]')!;
      /** A tap opens the Repost menu (a CDK overlay on the document): "إعادة النشر", or "إلغاء إعادة النشر" once reposted. */
      const pick = async (action: 'repost' | 'undo') => {
        repost.click();
        await t.stable();
        document.querySelector<HTMLElement>(`[data-repost-menu] [data-repost-action="${action}"]`)!.click();
        await t.stable();
      };
      expect(repost.getAttribute('aria-pressed')).toBe('false');
      await pick('repost');
      expect(repost.getAttribute('aria-pressed')).toBe('true');
      expect(t.$('[data-repost-count]')!.textContent!.trim()).toBe('3');
      const put = t.http.expectOne(`${TEST_API}/articles/a1/repost`);
      expect(put.request.method).toBe('PUT');
      put.flush({ repostCount: 3, isReposted: true });
      await t.stable();

      // Undo, refused: back to reposted, with the translated error.
      await pick('undo');
      expect(repost.getAttribute('aria-pressed')).toBe('false');
      expect(t.$('[data-repost-count]')!.textContent!.trim()).toBe('2');
      const del = t.http.expectOne(`${TEST_API}/articles/a1/repost`);
      expect(del.request.method).toBe('DELETE');
      del.flush({ code: 'rate_limited', status: 429, title: 'Too many requests' }, { status: 429, statusText: 'Too Many Requests' });
      await t.stable();
      expect(repost.getAttribute('aria-pressed')).toBe('true');
      expect(t.$('[data-repost-count]')!.textContent!.trim()).toBe('3');
      expect(TestBed.inject(ToastService).toasts().at(-1)!.message).toBe('طلبات كثيرة جدًا. انتظر قليلًا ثم حاول مرة أخرى.');
    });

    it('on your own article Repost is disabled with the hint and never sends', async () => {
      const own = testCard({ author: { id: 'user-1', displayName: 'Mona Adel', username: 'mona', avatarUrl: null, isVerified: false } });
      const t = await render(own);
      http = t.http;
      const repost = t.$('[data-repost]')!;
      expect(repost.getAttribute('aria-disabled')).toBe('true');
      expect(repost.getAttribute('aria-pressed')).toBeNull();
      expect(repost.getAttribute('title')).toBe('لا يمكنك إعادة نشر مقالك');
      expect(t.$(`#${repost.getAttribute('aria-describedby')}`)!.textContent).toContain('لا يمكنك إعادة نشر مقالك');
      repost.click();
      await t.stable();
      t.http.expectNone(`${TEST_API}/articles/a1/repost`);
      expect(TestBed.inject(ToastService).toasts().at(-1)!.message).toBe('لا يمكنك إعادة نشر مقالك');
    });

    it('guests get the sign-in prompt for Repost and nothing is sent; the card is remembered', async () => {
      const t = await render(testCard(), { guest: true });
      http = t.http;
      t.$('[data-repost]')!.click();
      await t.stable();
      expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
      t.http.expectNone(`${TEST_API}/articles/a1/repost`);
      expect(TestBed.inject(FeedMemory).pendingReturn()).toMatchObject({ articleId: 'a1', comments: false });
    });

    it('Comment opens the comments in place on wide screens, with the top 2 and "Show all comments"', async () => {
      const t = await render(testCard());
      http = t.http;
      const comment = t.$('[data-card-comment]')!;
      expect(comment.getAttribute('aria-expanded')).toBe('false');
      comment.click();
      await t.stable();
      expect(comment.getAttribute('aria-expanded')).toBe('true');
      const section = t.$('[data-card-comments]')!;
      expect(comment.getAttribute('aria-controls')).toBe(section.id);
      const author = { id: 'u-2', displayName: 'Nour', username: 'nour', avatarUrl: null, isVerified: false };
      const item = (id: string) => ({
        id,
        articleId: 'a1',
        parentId: null,
        body: `Comment ${id}`,
        author,
        isArticleAuthor: false,
        mentions: [],
        likeCount: 0,
        likedByMe: false,
        replyCount: 0,
        isPinned: false,
        createdAt: '2026-11-03T10:00:00Z',
        editedAt: null,
        isDeleted: false,
        isHidden: false,
        canEdit: false,
        canDelete: false,
        canPin: false,
        canReport: true,
        canModerate: false,
      });
      t.http.expectOne((r) => r.url === `${TEST_API}/articles/a1/comments`).flush({ items: [item('c1'), item('c2'), item('c3')], nextCursor: null, total: 3 });
      await t.stable();
      expect(section.querySelectorAll('rd-comment-thread')).toHaveLength(2);
      expect(section.querySelector('[data-new-comment]')).not.toBeNull();
      expect(section.querySelector('[data-comments-sort]')).toBeNull();
      (section.querySelector('[data-show-all-comments]') as HTMLElement).click();
      await t.stable();
      expect(section.querySelectorAll('rd-comment-thread')).toHaveLength(3);
      expect(section.querySelector('[data-show-all-comments]')).toBeNull();
    });

    it('on phones the comments open in a bottom sheet', async () => {
      const t = await render(testCard(), { wide: false });
      http = t.http;
      t.$('[data-card-comment]')!.click();
      await t.stable();
      t.http.expectOne((r) => r.url === `${TEST_API}/articles/a1/comments`).flush({ items: [], nextCursor: null, total: 0 });
      await t.stable();
      expect(t.$('[data-card-comments]')).toBeNull();
      const dialog = t.$('rd-bottom-sheet section[role="dialog"]')!;
      expect(dialog.querySelector('[data-comments-sort]')).not.toBeNull();
      expect(dialog.getAttribute('aria-labelledby')).toBe(dialog.querySelector('[data-comments-title]')!.id);
    });

    it('guests get the sign-in prompt for Comment, and come back to the card with its comments', async () => {
      const t = await render(testCard(), { guest: true });
      http = t.http;
      t.$('[data-card-comment]')!.click();
      await t.stable();
      expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
      expect(t.$('[data-card-comments]')).toBeNull();
      expect(TestBed.inject(FeedMemory).pendingReturn()).toMatchObject({ articleId: 'a1', comments: true });
    });

    it('Share uses the share sheet with the article’s link', async () => {
      const share = vi.fn().mockResolvedValue(undefined);
      vi.stubGlobal('navigator', { ...navigator, share });
      const t = await render(testCard(), { guest: true });
      http = t.http;
      t.$('[data-card-share]')!.click();
      await t.stable();
      expect(share).toHaveBeenCalledWith({ title: 'Clean Architecture on one whiteboard', url: expect.stringMatching(/\/en\/a\/clean-architecture$/) });
    });
  });

  describe('counting as read (F04 rule, C7)', () => {
    /** Every card is on screen as soon as it is observed. */
    class OnScreen {
      constructor(private readonly callback: IntersectionObserverCallback) {}
      observe(target: Element): void {
        queueMicrotask(() => this.callback([{ isIntersecting: true, target } as IntersectionObserverEntry], this as unknown as IntersectionObserver));
      }
      disconnect(): void {
        /* nothing to stop */
      }
    }

    const PROGRESS = `${TEST_API}/articles/a1/progress`;

    async function expanded(isComplete: boolean) {
      vi.stubGlobal('IntersectionObserver', OnScreen);
      const t = await render(testCard());
      await t.stable();
      t.$('[data-card-read-more]')!.click();
      await t.stable();
      t.http.expectOne((r) => r.url === PREVIEW).flush(preview({ isComplete }));
      await t.stable();
      return t;
    }

    it('an article shown whole in the card reports reading progress, without a position for the reader', async () => {
      const t = await expanded(true);
      http = t.http;
      const req = t.http.expectOne((r) => r.url === PROGRESS && r.method === 'PUT');
      expect(req.request.body).toMatchObject({ language: 'en', lastPosition: null, activeSecondsDelta: 0 });
      req.flush({ percent: 100, completed: false, completedNow: false, streak: null, milestone: null });
      await t.stable();
      // The result updates the streak store (F08), which asks for your stats once.
      for (const stats of t.http.match((r) => r.url === `${TEST_API}/me/stats`)) stats.flush(null, { status: 503, statusText: 'Unavailable' });
    });

    it('a cut-off article never counts from the card', async () => {
      const t = await expanded(false);
      http = t.http;
      t.http.expectNone((r) => r.url === PROGRESS);
    });
  });

  describe('mutes (F28)', () => {
    it('leaves the list when you mute its writer, and comes back in place on Undo', async () => {
      const t = await render(testCard());
      http = t.http;
      const host = t.fixture.nativeElement as HTMLElement;
      expect(host.style.display).toBe('');

      void TestBed.inject(MuteStore).muteAuthor({ id: 'writer-1', displayName: 'Karim Hassan' });
      await t.stable();
      expect(host.style.display).toBe('none');
      t.http.expectOne(`${TEST_API}/users/writer-1/mute`).flush({ isMuted: true, isFollowing: false, followerCount: 40, followRemoved: false });
      await t.stable();

      TestBed.inject(ToastService).toasts()[0].action!.run();
      await t.stable();
      expect(host.style.display).toBe('');
      t.http.expectOne(`${TEST_API}/users/writer-1/mute`).flush({ isMuted: false, isFollowing: false, followerCount: 40, followRemoved: false });
      await t.stable();
    });

    it("a toggle in the card's own topics sheet folds the card only once the sheet closes", async () => {
      const t = await render(testCard());
      http = t.http;
      const host = t.fixture.nativeElement as HTMLElement;
      t.$('[data-article-menu]')!.click();
      await t.stable();
      (document.querySelector('[data-article-menu-panel] [data-menu-action="muteTopics"]') as HTMLElement).click();
      await t.stable();
      // The sheet is its own lazy chunk.
      for (let i = 0; i < 50 && !t.$('[data-mute-topics-sheet]'); i++) {
        await new Promise((resolve) => setTimeout(resolve, 10));
        await t.stable();
      }
      t.$('[data-mute-topics-sheet] [data-mute-field="f1"] [role="switch"]')!.click();
      await t.stable();
      t.http.expectOne(`${TEST_API}/me/mutes/fields/f1`).flush({ fieldIds: ['f1'], topicIds: [] });
      await t.stable();

      // The field is muted, but the card (with its sheet inside) stays while the sheet is open: toggling back stays possible.
      expect(TestBed.inject(MuteStore).hides(testCard(), { applies: true })).toBe(true);
      expect(host.style.display).toBe('');
      expect(t.$('[data-mute-topics-sheet]')).not.toBeNull();

      t.$('[data-mute-topics-done]')!.click();
      await t.stable();
      expect(t.$('[data-mute-topics-sheet]')).toBeNull();
      expect(host.style.display).toBe('none');
      document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
    });

    it('a card that arrives muted is never shown; the writer\'s own pages keep it', async () => {
      const t = await render(testCard({ isAuthorMuted: true }));
      http = t.http;
      expect((t.fixture.nativeElement as HTMLElement).style.display).toBe('none');

      TestBed.resetTestingModule();
      stubViewport(true);
      setupSocialTesting({ providers: [keepMutedContent()] });
      const own = TestBed.createComponent(PostCard);
      own.componentRef.setInput('article', testCard({ isAuthorMuted: true }));
      own.detectChanges();
      await own.whenStable();
      expect((own.nativeElement as HTMLElement).style.display).toBe('');
      expect((own.nativeElement as HTMLElement).querySelector('[data-card-title]')).not.toBeNull();
      http = null;
    });
  });
});

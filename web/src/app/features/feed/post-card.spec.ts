import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto, ArticlePreviewDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { FollowStore } from '../../core/social/follow.store';
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
      expect(meta.textContent).toContain('4 دقايق قراءة');
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
      expect(t.$('[data-card-label]')!.textContent!.trim()).toBe('مقال النهارده');
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
      expect(error.textContent).toContain('معرفناش نحمّل باقي المقال.');
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

    it('up to 3 tags as plain chips (not links), then "+N"', async () => {
      const t = await render(testCard({ tags: ['architecture', 'dotnet', 'ذكاء'], tagCount: 5 }), { guest: true });
      http = t.http;
      const chips = t.$$('[data-card-tags] li');
      expect(chips.map((c) => c.textContent!.trim())).toEqual(['#architecture', '#dotnet', '#ذكاء', '+2تاجين كمان']);
      expect(chips[2].getAttribute('dir')).toBe('auto');
      expect(t.$('[data-card-tags] a')).toBeNull();
    });

    it('the top reactions with the total, and the comment count', async () => {
      const t = await render(testCard(), { guest: true });
      http = t.http;
      const summary = t.$('[data-reactions-summary]')!;
      expect(summary.textContent).toContain('💡❤️🔥');
      expect(summary.getAttribute('aria-label')).toBe('12 تفاعل، شوف مين اتفاعل');
      expect(t.$('[data-card-comment-count]')!.textContent!.trim()).toBe('3 تعليقات');
    });

    it('no counts row while nothing has reactions or comments', async () => {
      const t = await render(testCard({ reactionCount: 0, reactions: { insightful: 0, love: 0, fire: 0, mindBlown: 0 }, commentCount: 0 }), { guest: true });
      http = t.http;
      expect(t.$('[data-card-counts]')).toBeNull();
      expect(t.$('[data-card-actions]')).not.toBeNull();
    });
  });

  describe('action bar', () => {
    it('React, Comment and Share are real buttons with labels; no Repost', async () => {
      const t = await render(testCard(), { guest: true, lang: 'en' });
      http = t.http;
      const bar = t.$('[data-card-actions]')!;
      expect(bar.getAttribute('role')).toBe('group');
      expect([...bar.querySelectorAll('button')].map((b) => b.textContent!.trim())).toEqual(['💡React', 'Comment', 'Share']);
      expect(bar.querySelector('[data-react]')!.getAttribute('aria-label')).toBe('React: Insightful');
      expect(bar.querySelector('[data-react]')!.getAttribute('aria-keyshortcuts')).toBe('ArrowUp');
    });

    it('a tap reacts 💡 at once (the reader’s store); ArrowUp opens the four reactions', async () => {
      const t = await render(testCard());
      http = t.http;
      const react = t.$('[data-card-actions] [data-react]')!;
      react.click();
      await t.stable();
      expect(react.getAttribute('data-my-reaction')).toBe('insightful');
      expect(react.textContent).toContain('مفيد');
      const req = t.http.expectOne(`${TEST_API}/articles/a1/reaction`);
      expect(req.request.body).toEqual({ type: 'insightful' });
      req.flush({ reactions: { insightful: 7, love: 3, fire: 2, mindBlown: 1 }, total: 13, myReaction: 'insightful' });
      await t.stable();
      expect(t.$('[data-reaction-total]')!.textContent!.trim()).toBe('13');

      react.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowUp', bubbles: true }));
      await t.stable();
      expect(t.$$('[data-card-actions] [data-reaction-picker] [role="menuitemradio"]')).toHaveLength(4);
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
});

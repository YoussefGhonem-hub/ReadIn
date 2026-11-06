import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { CommentDto, CommentPageDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { CommentEvent, RealtimeService } from '../../core/realtime/realtime.service';
import { MuteStore } from '../../core/social/mute.store';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { CommentsSection } from './comments-section';
import { MENTION_DEBOUNCE_MS } from './comment-composer';

const LIST = `${TEST_API}/articles/a1/comments`;

function dto(id: string, patch: Partial<CommentDto> = {}): CommentDto {
  return {
    id,
    articleId: 'a1',
    parentId: null,
    body: `Comment ${id}`,
    author: { id: `u-${id}`, displayName: `User ${id}`, username: `user_${id}`, avatarUrl: null, isVerified: false },
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
    ...patch,
  };
}

const MINE = { id: 'user-1', displayName: 'Mona Adel', username: 'mona', avatarUrl: null, isVerified: false };

async function render(page: Partial<CommentPageDto>, options: { guest?: boolean } = {}) {
  const listeners: ((event: CommentEvent) => void)[] = [];
  const realtime = { watchCommentEvents: (_id: string, next: (event: CommentEvent) => void) => (listeners.push(next), () => undefined) };
  const { http } = setupSocialTesting({ guest: options.guest, providers: [{ provide: RealtimeService, useValue: realtime }] });
  const fixture = TestBed.createComponent(CommentsSection);
  fixture.componentRef.setInput('article', testCard());
  fixture.detectChanges();
  await fixture.whenStable();
  http.expectOne((r) => r.url === LIST && r.method === 'GET').flush({ items: [], nextCursor: null, total: 0, ...page });
  await flushMicrotasks();
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  await stable();
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  const $$ = (selector: string) => [...root.querySelectorAll<HTMLElement>(selector)];
  return { fixture, root, http, $, $$, stable, emit: (event: CommentEvent) => listeners.forEach((l) => l(event)) };
}

function type(field: HTMLTextAreaElement, value: string): void {
  field.value = value;
  field.setSelectionRange(value.length, value.length);
  field.dispatchEvent(new Event('input'));
}

function key(target: Element, key: string): void {
  target.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true }));
}

describe('CommentsSection (F11)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => http?.verify());

  it('shows the total, the badges, placeholders and only the resolved mentions as links', async () => {
    const t = await render({
      total: 5,
      items: [
        dto('p', { isPinned: true, isArticleAuthor: true, body: 'شكراً و@user_x و @ghost', mentions: [{ userId: 'u-x', username: 'user_x' }] }),
        dto('gone', { isDeleted: true, body: null, author: null, replyCount: 1, replies: [dto('r1', { parentId: 'gone', author: null, body: 'from a deleted account' })] }),
        dto('mine', { author: MINE, isHidden: true, canEdit: true, canDelete: true, canReport: false, editedAt: '2026-11-03T11:00:00Z' }),
      ],
    });
    http = t.http;
    expect(t.$('[data-comments-title]')!.textContent!.trim()).toBe('التعليقات (5)');

    const pinned = t.$('[data-comment="p"]')!;
    expect(pinned.querySelector('[data-writer-badge]')!.textContent).toBe('الكاتب');
    expect(pinned.querySelector('[data-pinned]')!.textContent).toContain('مثبّت');
    const body = pinned.querySelector('[data-comment-body]')!;
    // Its own direction from the text, ignoring @handles (an Arabic comment that starts with a mention stays RTL).
    expect(body.getAttribute('dir')).toBe('rtl');
    const links = [...body.querySelectorAll('a[data-mention]')];
    expect(links.map((a) => [a.textContent, a.getAttribute('href')])).toEqual([['@user_x', '/@user_x']]);
    expect(body.textContent).toContain('@ghost'); // not resolved: plain text

    expect(t.$('[data-comment="gone"] [data-comment-placeholder]')!.textContent).toContain('تم حذف هذا التعليق');
    const orphan = t.$('[data-comment="r1"]')!;
    expect(orphan.querySelector('[data-comment-author]')!.textContent!.trim()).toBe('مستخدم محذوف');
    expect(orphan.querySelector('[data-deleted-user-avatar]')).not.toBeNull();
    expect(orphan.querySelector('a[href^="/@"]')).toBeNull(); // no profile link

    const own = t.$('[data-comment="mine"]')!;
    expect(own.querySelector('[data-hidden-notice]')).not.toBeNull();
    expect(own.querySelector('[data-edited]')!.textContent).toBe('معدّل');
  });

  it('a comment by a writer you muted collapses until "عرض", here only; its replies stay (F28)', async () => {
    const t = await render({
      total: 3,
      items: [
        dto('m', { isAuthorMuted: true, replyCount: 1, replies: [dto('r', { parentId: 'm' })] }),
        dto('ok'),
      ],
    });
    http = t.http;
    const muted = t.$('[data-comment="m"]')!;
    expect(muted.querySelector('[data-comment-muted]')!.textContent).toContain('تعليق من شخص كتمته');
    expect(muted.querySelector('[data-comment-body]')).toBeNull();
    expect(muted.querySelector('[data-comment-author]')).toBeNull();
    expect(t.$('[data-comment="r"] [data-comment-body]')!.textContent).toContain('Comment r');
    expect(t.$('[data-comment="ok"] [data-comment-muted]')).toBeNull();
    expect(t.$('[data-comments-title]')!.textContent!.trim()).toBe('التعليقات (3)');

    const show = muted.querySelector<HTMLButtonElement>('[data-comment-reveal]')!;
    expect(show.textContent!.trim()).toBe('عرض');
    show.click();
    await t.stable();
    expect(muted.querySelector('[data-comment-muted]')).toBeNull();
    expect(muted.querySelector('[data-comment-body]')!.textContent).toContain('Comment m');
  });

  it('muting a writer from elsewhere collapses their comments at once (F28)', async () => {
    const t = await render({ total: 1, items: [dto('x')] });
    http = t.http;
    void TestBed.inject(MuteStore).muteAuthor({ id: 'u-x', displayName: 'User x' });
    await t.stable();
    expect(t.$('[data-comment="x"] [data-comment-muted]')).not.toBeNull();
    t.http.expectOne(`${TEST_API}/users/u-x/mute`).flush({ isMuted: true, isFollowing: false, followerCount: 0, followRemoved: false });
    await t.stable();
  });

  it('guests see a sign-in prompt instead of the composer, and actions ask them to sign in', async () => {
    const t = await render({ total: 1, items: [dto('c1', { canReport: false })] }, { guest: true });
    http = t.http;
    expect(t.$('[data-new-comment]')).toBeNull();
    expect(t.$('[data-comments-guest]')).not.toBeNull();
    const prompt = TestBed.inject(AuthPromptService);
    t.$('[data-like]')!.click();
    expect(prompt.isOpen()).toBe(true);
    prompt.close();
    t.$('[data-reply]')!.click();
    expect(prompt.isOpen()).toBe(true);
    await t.stable();
    expect(t.$('[data-like]')!.getAttribute('aria-pressed')).toBe('false');
  });

  it('shows the empty state', async () => {
    const t = await render({ total: 0, items: [] });
    http = t.http;
    expect(t.root.textContent).toContain('لا توجد تعليقات بعد');
  });

  it('the composer: send is off while empty, the counter shows for the last 200 characters', async () => {
    const t = await render({ total: 0, items: [] });
    http = t.http;
    const field = t.$<HTMLTextAreaElement>('[data-new-comment] textarea')!;
    expect(field.getAttribute('dir')).toBe('auto');
    expect(field.getAttribute('maxlength')).toBe('2000');
    const send = t.$<HTMLButtonElement>('[data-new-comment] [data-comment-send]')!;
    expect(send.disabled).toBe(true);
    type(field, '   ');
    await t.stable();
    expect(send.disabled).toBe(true);

    type(field, 'x'.repeat(1800));
    await t.stable();
    expect(t.$('[data-comment-counter]')).toBeNull();
    type(field, 'x'.repeat(1850));
    await t.stable();
    expect(t.$('[data-comment-counter]')!.textContent).toBe('تبقّى 150 حرفًا');
    expect(send.disabled).toBe(false);
  });

  it('posting shows the comment at once; a failure brings your text back with the reason', async () => {
    const t = await render({ total: 1, items: [dto('c1')] });
    http = t.http;
    const field = t.$<HTMLTextAreaElement>('[data-new-comment] textarea')!;
    type(field, 'Nice one');
    await t.stable();
    t.$('[data-new-comment] [data-comment-send]')!.click();
    await t.stable();
    expect(t.$('[data-pending]')!.textContent).toContain('Nice one');
    expect(field.value).toBe('');

    t.http.expectOne((r) => r.url === LIST && r.method === 'POST').flush(problem(429, 'rate_limited'), { status: 429, statusText: 'Too Many' });
    await t.stable();
    expect(t.$('[data-pending]')).toBeNull();
    expect(field.value).toBe('Nice one');
    expect(t.$('[data-comment-error]')!.textContent).toBe('أنت تعلّق بسرعة كبيرة. انتظر دقيقة ثم حاول مرة أخرى.');
  });

  it('suggests people while typing an @handle and inserts the picked one from the keyboard', async () => {
    const t = await render({ total: 0, items: [] });
    http = t.http;
    const field = t.$<HTMLTextAreaElement>('[data-new-comment] textarea')!;
    type(field, 'شكراً @ka');
    await new Promise((resolve) => setTimeout(resolve, MENTION_DEBOUNCE_MS + 30));
    const req = t.http.expectOne((r) => r.url === `${TEST_API}/users/mention-suggestions`);
    expect(req.request.params.get('q')).toBe('ka');
    req.flush([
      { id: 'k1', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true },
      { id: 'k2', displayName: 'Kamal', username: 'kamal', avatarUrl: null, isVerified: false },
    ]);
    await t.stable();
    expect(field.getAttribute('aria-expanded')).toBe('true');
    expect(t.$$('[role="option"]').length).toBe(2);

    key(field, 'ArrowDown');
    await t.stable();
    expect(field.getAttribute('aria-activedescendant')).toBe(t.$$('[role="option"]')[1].id);
    key(field, 'Enter');
    await t.stable();
    expect(field.value).toBe('شكراً @kamal ');
    expect(t.$('[data-mention-list]')).toBeNull();
  });

  it('live comments wait behind the "new comments" pill until it is pressed', async () => {
    const t = await render({ total: 1, items: [dto('c1')] });
    http = t.http;
    t.emit({ id: 'e1', type: 'comment.created', commentId: 'c2', parentId: null, at: 1 });
    t.http.expectOne(`${TEST_API}/comments/c2`).flush(dto('c2'));
    await t.stable();
    const pill = t.$('[data-new-comments]')!;
    expect(pill.textContent!.trim()).toBe('تعليق جديد');
    pill.click();
    await t.stable();
    expect(t.$('[data-new-comments]')).toBeNull();
    expect(t.$$('[data-thread]').map((el) => el.getAttribute('data-thread'))).toEqual(['c2', 'c1']);
  });

  it('your comment menu offers edit and delete; deleting asks first', async () => {
    const t = await render({ total: 1, items: [dto('m1', { author: MINE, canEdit: true, canDelete: true, canReport: false })] });
    http = t.http;
    t.$('[data-comment-menu]')!.click();
    await t.stable();
    const actions = [...document.querySelectorAll('[data-menu-action]')].map((el) => el.getAttribute('data-menu-action'));
    expect(actions).toEqual(['edit', 'delete']);
    (document.querySelector('[data-menu-action="delete"]') as HTMLElement).click();
    await t.stable();
    expect(t.$('[data-delete-comment-sheet]')).not.toBeNull();
    t.$('[data-confirm-delete]')!.click();
    const req = t.http.expectOne(`${TEST_API}/comments/m1`);
    expect(req.request.method).toBe('DELETE');
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.$('[data-delete-comment-sheet]')).toBeNull();
    expect(t.$('[data-comment="m1"]')).toBeNull();
  });

  it("Mute commenter sits right before Report, collapses their comments, and the toast's Undo brings them back", async () => {
    const t = await render({ total: 2, items: [dto('c1'), dto('c2', { author: { id: 'u-c1', displayName: 'User c1', username: 'user_c1', avatarUrl: null, isVerified: false } })] });
    http = t.http;
    t.$('[data-comment="c1"] [data-comment-menu]')!.click();
    await t.stable();
    const actions = [...document.querySelectorAll('[data-comment-menu-panel] [data-menu-action]')].map((el) => el.getAttribute('data-menu-action'));
    expect(actions).toEqual(['muteCommenter', 'report']);
    expect(document.querySelector('[data-menu-action="muteCommenter"]')!.textContent!.trim()).toBe('كتم صاحب التعليق');
    (document.querySelector('[data-menu-action="muteCommenter"]') as HTMLElement).click();
    await t.stable();

    // Both of their comments collapse at once.
    expect(t.$$('[data-comment-muted]')).toHaveLength(2);
    const put = t.http.expectOne(`${TEST_API}/users/u-c1/mute`);
    expect(put.request.method).toBe('PUT');
    put.flush({ isMuted: true, isFollowing: false, followerCount: 3, followRemoved: false });
    await t.stable();
    const [toast] = TestBed.inject(ToastService).toasts();
    expect(toast.message).toContain('User c1');
    expect(toast.action!.label).toBe('تراجع');

    toast.action!.run();
    await t.stable();
    expect(t.$$('[data-comment-muted]')).toHaveLength(0);
    const undo = t.http.expectOne(`${TEST_API}/users/u-c1/mute`);
    expect(undo.request.method).toBe('DELETE');
    undo.flush({ isMuted: false, isFollowing: false, followerCount: 3, followRemoved: false });
    await t.stable();
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
  });

  it("your own comments and a deleted user's have no Mute commenter", async () => {
    const t = await render({ total: 2, items: [dto('m1', { author: MINE, canEdit: true, canDelete: true, canReport: false }), dto('d1', { author: null })] });
    http = t.http;
    t.$('[data-comment="m1"] [data-comment-menu]')!.click();
    await t.stable();
    expect([...document.querySelectorAll('[data-comment-menu-panel] [data-menu-action]')].map((el) => el.getAttribute('data-menu-action'))).toEqual(['edit', 'delete']);
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
    t.$('[data-comment="d1"] [data-comment-menu]')!.click();
    await t.stable();
    expect([...document.querySelectorAll('[data-comment-menu-panel] [data-menu-action]')].map((el) => el.getAttribute('data-menu-action'))).toEqual(['report']);
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
  });

  it('reporting sends the reason and thanks you', async () => {
    const t = await render({ total: 1, items: [dto('c1')] });
    http = t.http;
    t.$('[data-comment-menu]')!.click();
    await t.stable();
    (document.querySelector('[data-menu-action="report"]') as HTMLElement).click();
    await t.stable();
    expect(t.$<HTMLButtonElement>('[data-report-submit]')!.disabled).toBe(true);
    t.$<HTMLInputElement>('[data-reason="spam"]')!.click();
    await t.stable();
    t.$('[data-report-submit]')!.click();
    const req = t.http.expectOne(`${TEST_API}/reports`);
    expect(req.request.body).toEqual({ targetType: 'comment', targetId: 'c1', reason: 'spam' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.$('[data-report-sheet]')).toBeNull();
    expect(TestBed.inject(ToastService).toasts().map((toast) => toast.message)).toEqual(['شكرًا، سنراجع البلاغ']);
  });

  describe('replies in pages (like Facebook and LinkedIn)', () => {
    const replies = (from: number, to: number) => Array.from({ length: to - from + 1 }, (_, i) => dto(`r${from + i}`, { parentId: 'c1' }));
    const shownIds = (t: { $$: (selector: string) => HTMLElement[] }) => t.$$('[data-replies] [data-comment]').map((el) => el.getAttribute('data-comment'));

    it('the first reply shows; "show N more replies" shows up to 5 more per tap; "Hide replies" folds back', async () => {
      const t = await render({ total: 9, items: [dto('c1', { replyCount: 8, replies: replies(1, 2) })] });
      http = t.http;
      expect(shownIds(t)).toEqual(['r1']);
      const more = t.$<HTMLButtonElement>('[data-more-replies]')!;
      expect(more.textContent!.trim()).toBe('عرض 7 ردود إضافية');
      expect(t.$('[data-hide-replies]')).toBeNull(); // one reply shows

      more.focus();
      more.click();
      await t.stable();
      expect(shownIds(t)).toEqual(['r1', 'r2']); // the loaded one at once
      expect(more.getAttribute('aria-busy')).toBe('true');
      const req = t.http.expectOne((r) => r.url === `${TEST_API}/comments/c1/replies`);
      expect(req.request.params.get('limit')).toBe('5');
      expect(req.request.params.get('cursor')).toBeNull();
      req.flush({ items: replies(1, 5), nextCursor: 'p2' });
      await t.stable();
      expect(shownIds(t)).toEqual(['r1', 'r2', 'r3', 'r4', 'r5']);
      expect(t.$('[data-more-replies]')!.textContent!.trim()).toBe('عرض 3 ردود إضافية');
      const hide = t.$<HTMLButtonElement>('[data-hide-replies]')!;
      expect(hide.textContent!.trim()).toBe('إخفاء الردود');

      t.$('[data-more-replies]')!.click();
      await t.stable();
      t.http.expectOne((r) => r.url === `${TEST_API}/comments/c1/replies` && r.params.get('cursor') === 'p2').flush({ items: replies(6, 8), nextCursor: null });
      await t.stable();
      await t.stable();
      expect(shownIds(t)).toHaveLength(8);
      expect(t.$('[data-more-replies]')).toBeNull();
      expect(document.activeElement).toBe(t.$('[data-hide-replies]')); // the pressed button is gone: focus moves on

      t.$('[data-hide-replies]')!.click();
      await t.stable();
      await t.stable();
      expect(shownIds(t)).toEqual(['r1']);
      expect(t.$('[data-more-replies]')!.textContent!.trim()).toBe('عرض 7 ردود إضافية');
      expect(t.$('[data-hide-replies]')).toBeNull();
      expect(document.activeElement).toBe(t.$('[data-more-replies]'));

      // From memory: no request.
      t.$('[data-more-replies]')!.click();
      await t.stable();
      expect(shownIds(t)).toEqual(['r1', 'r2', 'r3', 'r4', 'r5', 'r6']);
    });

    it('a live reply shows at once at the end while older ones are hidden, highlighted on its bubble', async () => {
      const t = await render({ total: 4, items: [dto('c1', { replyCount: 3, replies: replies(1, 2) })] });
      http = t.http;
      t.emit({ id: 'e1', type: 'reply.created', commentId: 'r9', parentId: 'c1', at: 1 });
      t.http.expectOne(`${TEST_API}/comments/r9`).flush(dto('r9', { parentId: 'c1' }));
      await t.stable();
      expect(shownIds(t)).toEqual(['r1', 'r9']);
      // The pager sits between the replies that show and the new one, and never counts a reply that shows.
      const children = [...t.$('[data-replies]')!.children].map((el) => el.getAttribute('data-comment') ?? (el.hasAttribute('data-replies-pager') ? 'pager' : el.tagName));
      expect(children).toEqual(['r1', 'pager', 'r9']);
      expect(t.$('[data-more-replies]')!.textContent!.trim()).toBe('عرض ردّين إضافيين');
      expect(t.$('[data-hide-replies]')).not.toBeNull();
      const bubble = t.$('[data-comment="r9"] [data-comment-bubble]')!;
      expect(bubble.classList).toContain('bg-highlight');
      expect(bubble.classList).not.toContain('bg-surface-variant');
      expect(t.$('[data-comment="r9"]')!.classList).not.toContain('bg-highlight');
    });

    it('your reply shows at once at the end of a folded thread; replying keeps the thread as it is', async () => {
      const t = await render({ total: 6, items: [dto('c1', { replyCount: 5, replies: replies(1, 2) })] });
      http = t.http;
      t.$('[data-comment="r1"] [data-reply]')!.click();
      await t.stable();
      const field = t.$<HTMLTextAreaElement>('[data-reply-composer] textarea')!;
      type(field, '@user_r1 agreed');
      await t.stable();
      t.$('[data-reply-composer] [data-comment-send]')!.click();
      await t.stable();
      t.http.expectOne(`${TEST_API}/comments/r1/replies`).flush(dto('m1', { parentId: 'c1', author: MINE, body: '@user_r1 agreed' }));
      await t.stable();
      expect(shownIds(t)).toEqual(['r1', 'm1']);
      expect(t.$('[data-more-replies]')!.textContent!.trim()).toBe('عرض 4 ردود إضافية');
    });

    it('a thread with replies but none included offers them straight away', async () => {
      const t = await render({ total: 3, items: [dto('c1', { replyCount: 2 })] });
      http = t.http;
      expect(shownIds(t)).toEqual([]);
      expect(t.$('[data-more-replies]')!.textContent!.trim()).toBe('عرض ردّين إضافيين');
      t.$('[data-more-replies]')!.click();
      await t.stable();
      t.http.expectOne((r) => r.url === `${TEST_API}/comments/c1/replies`).flush({ items: replies(1, 2), nextCursor: null });
      await t.stable();
      expect(shownIds(t)).toEqual(['r1', 'r2']);
    });

    it('replies that fail to load say so and try again', async () => {
      const t = await render({ total: 7, items: [dto('c1', { replyCount: 6, replies: replies(1, 2) })] });
      http = t.http;
      t.$('[data-more-replies]')!.click();
      await t.stable();
      t.http.expectOne((r) => r.url === `${TEST_API}/comments/c1/replies`).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
      await t.stable();
      const retry = t.$('[data-more-replies]')!;
      expect(retry.textContent!.trim()).toBe('تعذّر تحميل الردود. حاول مرة أخرى');
      retry.click();
      await t.stable();
      t.http.expectOne((r) => r.url === `${TEST_API}/comments/c1/replies`).flush({ items: replies(1, 5), nextCursor: 'p2' });
      await t.stable();
      expect(shownIds(t)).toHaveLength(5);
      expect(t.$('[data-more-replies]')!.textContent!.trim()).toBe('عرض رد إضافي');
    });
  });

  describe('on a post card (F34)', () => {
    async function renderOnCard(variant: 'card' | 'sheet', page: Partial<CommentPageDto>) {
      const realtime = { watchCommentEvents: () => () => undefined };
      const { http: backend } = setupSocialTesting({ providers: [{ provide: RealtimeService, useValue: realtime }] });
      const create = async () => {
        const fixture = TestBed.createComponent(CommentsSection);
        fixture.componentRef.setInput('article', testCard());
        fixture.componentRef.setInput('variant', variant);
        fixture.componentRef.setInput('titleId', 'card-comments-title-7');
        fixture.detectChanges();
        await fixture.whenStable();
        backend.expectOne((r) => r.url === LIST && r.method === 'GET').flush({ items: [], nextCursor: null, total: 0, ...page });
        for (let i = 0; i < 3; i++) {
          await flushMicrotasks();
          fixture.detectChanges();
          await fixture.whenStable();
        }
        const root = fixture.nativeElement as HTMLElement;
        return { fixture, root, $: <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector) };
      };
      return { http: backend, create };
    }

    beforeEach(() => sessionStorage.clear());

    it('in place: the composer and the top 2 threads, then "Show all comments" lists the rest', async () => {
      const t = await renderOnCard('card', { total: 3, items: [dto('c1'), dto('c2'), dto('c3')] });
      http = t.http;
      const { $, root } = await t.create();
      const title = $('[data-comments-title]')!;
      expect(title.id).toBe('card-comments-title-7');
      expect(title.classList).toContain('sr-only');
      expect($('[data-comments-sort]')).toBeNull();
      expect(root.querySelectorAll('rd-comment-thread')).toHaveLength(2);
      $('[data-show-all-comments]')!.click();
      await flushMicrotasks();
      TestBed.tick();
      expect(root.querySelectorAll('rd-comment-thread')).toHaveLength(3);
      expect($('[data-show-all-comments]')).toBeNull();
    });

    it('the sheet is the full section, titled by its own id', async () => {
      const t = await renderOnCard('sheet', { total: 1, items: [dto('c1')] });
      http = t.http;
      const { $ } = await t.create();
      expect($('#card-comments-title-7')!.textContent!.trim()).toBe('التعليقات (1)');
      expect($('[data-comments-sort]')).not.toBeNull();
    });

    it('your unsent text waits for you when the comments open again', async () => {
      const t = await renderOnCard('card', { total: 0, items: [] });
      http = t.http;
      const first = await t.create();
      type(first.$<HTMLTextAreaElement>('[data-new-comment] textarea')!, 'لسه بكتب about DI');
      TestBed.tick();
      first.fixture.destroy();

      const again = await t.create();
      expect(again.$<HTMLTextAreaElement>('[data-new-comment] textarea')!.value).toBe('لسه بكتب about DI');
    });
  });
});

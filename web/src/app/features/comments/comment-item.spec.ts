import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { CommentDto, CommentPageDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { RealtimeService } from '../../core/realtime/realtime.service';
import { FollowStore } from '../../core/social/follow.store';
import { CommentsSection } from './comments-section';

const LIST = `${TEST_API}/articles/a1/comments`;
const NOUR = { id: 'u-nour', displayName: 'Nour Fawzy', username: 'nour_f', avatarUrl: null, isVerified: true, headline: 'Product designer | UX writing' };
const MINE = { id: 'user-1', displayName: 'Mona Adel', username: 'mona', avatarUrl: null, isVerified: false, headline: null };

function dto(id: string, patch: Partial<CommentDto> = {}): CommentDto {
  return {
    id,
    articleId: 'a1',
    parentId: null,
    body: `Comment ${id}`,
    author: NOUR,
    isArticleAuthor: false,
    mentions: [],
    likeCount: 2,
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
    isFollowingAuthor: false,
    ...patch,
  };
}

async function render(page: Partial<CommentPageDto>, options: { guest?: boolean } = {}) {
  const realtime = { watchCommentEvents: () => () => undefined };
  const { http } = setupSocialTesting({ guest: options.guest, providers: [{ provide: RealtimeService, useValue: realtime }] });
  const fixture = TestBed.createComponent(CommentsSection);
  fixture.componentRef.setInput('article', testCard());
  fixture.detectChanges();
  await fixture.whenStable();
  http.expectOne((r) => r.url === LIST && r.method === 'GET').flush({ items: [], nextCursor: null, total: 0, ...page });
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  await stable();
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  const $$ = (selector: string) => [...root.querySelectorAll<HTMLElement>(selector)];
  return { fixture, root, http, $, $$, stable };
}

describe('A comment row (F11)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => http?.verify());

  it('the writer’s title under the name instead of the @username; avatar and name open the profile', async () => {
    const t = await render({ total: 1, items: [dto('c1')] });
    http = t.http;
    const row = t.$('[data-comment="c1"]')!;
    const headline = row.querySelector<HTMLElement>('[data-comment-headline]')!;
    expect(headline.textContent!.trim()).toBe('Product designer | UX writing');
    // Placed in the UI's direction; the text laid out and cut ("…") in its own direction, so it keeps its beginning.
    expect(headline.hasAttribute('dir')).toBe(false);
    expect(headline.classList).toContain('flex');
    expect(headline.classList).not.toContain('truncate');
    expect(headline.querySelector('bdi')!.getAttribute('dir')).toBe('auto');
    expect(headline.querySelector('bdi')!.classList).toContain('truncate');
    expect(headline.querySelector('bdi')!.classList).toContain('min-w-0');
    expect(row.textContent).not.toContain('@nour_f');
    expect(row.querySelector('[data-comment-author]')!.getAttribute('href')).toBe('/@nour_f');
    expect(row.querySelector('a[aria-hidden="true"] rd-avatar')!.closest('a')!.getAttribute('href')).toBe('/@nour_f');
    expect(row.querySelector('[data-comment-author] svg[aria-label="كاتب موثّق"]')).not.toBeNull();
  });

  it('no title line without a title', async () => {
    const t = await render({ total: 1, items: [dto('c1', { author: { ...NOUR, headline: null } })] });
    http = t.http;
    expect(t.$('[data-comment="c1"] [data-comment-headline]')).toBeNull();
  });

  it('the actions in one tidy row under the bubble: Like and Reply; "· متابعة" after the name, the time and "⋯" at the end', async () => {
    const t = await render({ total: 1, items: [dto('c1')] });
    http = t.http;
    const row = t.$('[data-comment="c1"]')!;
    const actions = row.querySelector('[data-comment-actions]')!;
    expect([...actions.querySelectorAll('button')].map((b) => b.hasAttribute('data-like') || b.hasAttribute('data-reply'))).toEqual([true, true]);
    expect(row.querySelector('[data-comment-bubble] [data-comment-actions]')).toBeNull(); // under the bubble, not in it
    // "· متابعة" as text right after the name and its badges, in the header's start group.
    const follow = row.querySelector<HTMLElement>('[data-comment-follow] [data-follow]')!;
    expect(follow.textContent).toContain('متابعة');
    expect(follow.querySelector('svg')).toBeNull();
    expect(follow.classList).toContain('text-primary');
    const start = row.querySelector('[data-comment-author]')!.parentElement!;
    expect(start.querySelector(':scope > [data-comment-follow]')).not.toBeNull();
    expect(row.querySelector('[data-comment-follow]')!.previousElementSibling!.textContent!.trim()).toBe('·');
    // The time and "⋯" at the end of the header.
    const meta = row.querySelector('[data-comment-meta]')!;
    expect(meta.querySelector('time')).not.toBeNull();
    expect(meta.querySelector(':scope > [data-comment-menu]')).not.toBeNull();
    expect(row.querySelector('[data-comment-menu]')!.getAttribute('aria-label')).toBe('خيارات التعليق');
  });

  it('a compact row: the avatar, then a bubble with the header, the title and the text; text actions under it', async () => {
    const t = await render({
      total: 2,
      items: [dto('c1', { replyCount: 1, replies: [dto('r1', { parentId: 'c1', author: { ...NOUR, id: 'u-ali', username: 'ali', headline: null }, likeCount: 0, likedByMe: false })] })],
    });
    http = t.http;
    const row = t.$('[data-comment="c1"]')!;
    // 32 px for a comment, 24 px for a reply.
    expect(row.querySelector<HTMLElement>('rd-avatar')!.style.width).toBe('32px');
    expect(t.$<HTMLElement>('[data-comment="r1"] rd-avatar')!.style.width).toBe('24px');

    const bubble = row.querySelector<HTMLElement>('[data-comment-bubble]')!;
    expect(bubble.classList).toContain('bubble');
    expect(bubble.classList).toContain('bg-surface-variant');
    for (const part of ['[data-comment-author]', '[data-comment-headline]', '[data-comment-body]', '[data-comment-menu]']) {
      expect(bubble.querySelector(part)).not.toBeNull();
    }
    expect(bubble.querySelector('[data-comment-body]')!.classList).toContain('text-sm');

    // Like as text, with a heart and the count when there are likes; Reply as text.
    const like = row.querySelector<HTMLButtonElement>('[data-like]')!;
    expect(like.textContent).toContain('إعجاب');
    expect(like.getAttribute('aria-pressed')).toBe('false');
    expect(like.querySelector('[data-like-count]')!.textContent!.trim()).toBe('2');
    expect(like.querySelector('[data-like-count] svg')).not.toBeNull();
    expect(row.querySelector('[data-reply]')!.textContent!.trim()).toBe('رد');
    // No likes, no heart.
    expect(t.$('[data-comment="r1"] [data-like-count]')).toBeNull();

    like.click();
    await t.stable();
    expect(like.getAttribute('aria-pressed')).toBe('true');
    expect(like.classList).toContain('text-primary');
    t.http.expectOne(`${TEST_API}/comments/c1/like`).flush({ likeCount: 3, liked: true });
    await t.stable();
    expect(like.querySelector('[data-like-count]')!.textContent!.trim()).toBe('3');
  });

  it('while it posts, "جارٍ النشر…" stands in for the actions', async () => {
    const t = await render({ total: 0, items: [] });
    http = t.http;
    const field = t.$<HTMLTextAreaElement>('[data-new-comment] textarea')!;
    field.value = 'Nice one';
    field.dispatchEvent(new Event('input'));
    await t.stable();
    t.$('[data-new-comment] [data-comment-send]')!.click();
    await t.stable();
    const pending = t.$('[data-pending]')!;
    expect(pending.querySelector('[data-comment-actions]')!.textContent!.trim()).toBe('جارٍ النشر…');
    expect(pending.querySelector('[data-like]')).toBeNull();
    expect(pending.querySelector('[data-reply]')).toBeNull();
    expect(pending.querySelector('[data-comment-menu]')).toBeNull();
    expect(pending.querySelector('time')).toBeNull();
    t.http.expectOne((r) => r.url === `${TEST_API}/articles/a1/comments` && r.method === 'POST').flush(dto('m1', { author: MINE, body: 'Nice one', likeCount: 0 }));
    await t.stable();
    expect(t.$('[data-pending]')).toBeNull();
    expect(t.$('[data-comment="m1"] [data-like]')).not.toBeNull();
  });

  it('deleted and hidden-for-you comments are one italic line in a compact bubble', async () => {
    const t = await render({
      total: 2,
      items: [
        dto('gone', { isDeleted: true, body: null, author: null, replyCount: 1, replies: [dto('r1', { parentId: 'gone' })] }),
        dto('hid', { isHidden: true, body: null, author: null, replyCount: 1, replies: [dto('r2', { parentId: 'hid' })] }),
      ],
    });
    http = t.http;
    const gone = t.$('[data-comment="gone"] [data-comment-placeholder]')!;
    const line = gone.querySelector('p')!;
    expect(line.textContent!.trim()).toBe('تم حذف هذا التعليق');
    expect(line.classList).toContain('italic');
    expect(line.classList).toContain('bubble');
    expect(gone.querySelector<HTMLElement>('[aria-hidden="true"]')!.style.width).toBe('32px');
    expect(t.$('[data-comment="hid"] [data-comment-placeholder] p')!.textContent!.trim()).toBe('أخفى المشرفون هذا التعليق');
  });

  it('Follow shows only when you don’t follow them and it isn’t you', async () => {
    const t = await render({
      total: 3,
      items: [dto('c1'), dto('c2', { author: { ...NOUR, id: 'u-ali', username: 'ali' }, isFollowingAuthor: true }), dto('c3', { author: MINE, canEdit: true, canDelete: true, canReport: false })],
    });
    http = t.http;
    expect(t.$('[data-comment="c1"] [data-comment-follow]')).not.toBeNull();
    expect(t.$('[data-comment="c2"] [data-comment-follow]')).toBeNull();
    expect(t.$('[data-comment="c3"] [data-comment-follow]')).toBeNull();
  });

  it('following from a row uses the follow store: every row of that writer changes, the button stays to undo', async () => {
    const t = await render({ total: 2, items: [dto('c1'), dto('c2')] });
    http = t.http;
    t.$('[data-comment="c1"] [data-follow]')!.click();
    await t.stable();
    const req = t.http.expectOne(`${TEST_API}/users/u-nour/follow`);
    expect(req.request.method).toBe('PUT');
    req.flush({ isFollowing: true, followerCount: 10 });
    await t.stable();
    expect(TestBed.inject(FollowStore).isFollowing('u-nour', false)).toBe(true);
    for (const id of ['c1', 'c2']) expect(t.$(`[data-comment="${id}"] [data-follow]`)!.getAttribute('aria-pressed')).toBe('true');
  });

  it('guests see Follow, which asks them to sign in', async () => {
    const t = await render({ total: 1, items: [dto('c1', { isFollowingAuthor: false })] }, { guest: true });
    http = t.http;
    t.$('[data-comment="c1"] [data-follow]')!.click();
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
  });

  it('Reply puts "@username " in the reply box with the caret after it; ✕ "إلغاء الرد" cancels', async () => {
    const t = await render({ total: 1, items: [dto('c1')] });
    http = t.http;
    t.$('[data-comment="c1"] [data-reply]')!.click();
    await t.stable();
    await t.stable();
    const box = t.$('[data-reply-composer]')!;
    const field = box.querySelector<HTMLTextAreaElement>('textarea')!;
    expect(field.value).toBe('@nour_f ');
    expect(document.activeElement).toBe(field);
    expect(field.selectionStart).toBe('@nour_f '.length);
    expect(field.selectionEnd).toBe('@nour_f '.length);
    // The reply box looks the same: your avatar, the emoji and send icons inside the field.
    expect(box.querySelector('[data-composer-avatar]')).not.toBeNull();
    expect(box.querySelector('[data-comment-field] [data-comment-emoji]')).not.toBeNull();
    expect(box.querySelector('[data-comment-field] [data-comment-send]')!.getAttribute('aria-label')).toBe('نشر الرد');
    const cancel = box.querySelector<HTMLButtonElement>('[data-comment-cancel]')!;
    expect(cancel.getAttribute('aria-label')).toBe('إلغاء الرد');
    expect(cancel.textContent!.trim()).toBe('');
    cancel.click();
    await t.stable();
    expect(t.$('[data-reply-composer]')).toBeNull();
  });

  it('the reply is sent with the mention, which can be deleted like any text', async () => {
    const t = await render({ total: 1, items: [dto('c1')] });
    http = t.http;
    t.$('[data-comment="c1"] [data-reply]')!.click();
    await t.stable();
    await t.stable();
    const field = t.$<HTMLTextAreaElement>('[data-reply-composer] textarea')!;
    field.value = '@nour_f عندك حق';
    field.dispatchEvent(new Event('input'));
    await t.stable();
    t.$('[data-reply-composer] [data-comment-send]')!.click();
    await t.stable();
    const req = t.http.expectOne(`${TEST_API}/comments/c1/replies`);
    expect(req.request.body).toEqual({ body: '@nour_f عندك حق' });
    req.flush(dto('r1', { parentId: 'c1', body: '@nour_f عندك حق', author: MINE, mentions: [{ userId: 'u-nour', username: 'nour_f' }] }));
    await t.stable();
    expect(t.$('[data-comment="r1"] a[data-mention]')!.getAttribute('href')).toBe('/@nour_f');
  });

  it('replying to yourself (or to a deleted account) adds no mention', async () => {
    const t = await render({
      total: 2,
      items: [dto('c1', { author: MINE, canEdit: true, canDelete: true, canReport: false }), dto('c2', { author: null, isFollowingAuthor: false })],
    });
    http = t.http;
    t.$('[data-comment="c1"] [data-reply]')!.click();
    await t.stable();
    expect(t.$<HTMLTextAreaElement>('[data-reply-composer] textarea')!.value).toBe('');

    t.$('[data-comment="c2"] [data-reply]')!.click();
    await t.stable();
    expect(t.$<HTMLTextAreaElement>('[data-reply-composer] textarea')!.value).toBe('');
  });

  it('replying to a reply mentions that reply’s writer', async () => {
    const ali = { ...NOUR, id: 'u-ali', displayName: 'علي جمال', username: 'ali_g', headline: null };
    const t = await render({ total: 2, items: [dto('c1', { replyCount: 1, replies: [dto('r1', { parentId: 'c1', author: ali })] })] });
    http = t.http;
    t.$('[data-comment="r1"] [data-reply]')!.click();
    await t.stable();
    expect(t.$<HTMLTextAreaElement>('[data-reply-composer] textarea')!.value).toBe('@ali_g ');
  });
});

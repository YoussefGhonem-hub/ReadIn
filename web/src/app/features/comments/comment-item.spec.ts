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

  it('the actions in one tidy row: Like and Reply; "متابعة" and "⋯" on the other side of the name', async () => {
    const t = await render({ total: 1, items: [dto('c1')] });
    http = t.http;
    const row = t.$('[data-comment="c1"]')!;
    const actions = row.querySelector('[data-comment-actions]')!;
    expect([...actions.querySelectorAll('button')].map((b) => b.hasAttribute('data-like') || b.hasAttribute('data-reply'))).toEqual([true, true]);
    const follow = row.querySelector('[data-comment-follow] [data-follow]')!;
    expect(follow.textContent).toContain('متابعة');
    // Follow and the menu side by side, at the end of the name's line.
    expect(row.querySelector('[data-comment-follow]')!.parentElement!.querySelector(':scope > [data-comment-menu]')).not.toBeNull();
    expect(row.querySelector('[data-comment-menu]')!.getAttribute('aria-label')).toBe('خيارات التعليق');
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

import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { CommentDto, CommentPageDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { CommentEvent, RealtimeService } from '../../core/realtime/realtime.service';
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

    expect(t.$('[data-comment="gone"] [data-comment-placeholder]')!.textContent).toContain('التعليق ده اتمسح');
    const orphan = t.$('[data-comment="r1"]')!;
    expect(orphan.querySelector('[data-comment-author]')!.textContent!.trim()).toBe('مستخدم محذوف');
    expect(orphan.querySelector('[data-deleted-user-avatar]')).not.toBeNull();
    expect(orphan.querySelector('a[href^="/@"]')).toBeNull(); // no profile link

    const own = t.$('[data-comment="mine"]')!;
    expect(own.querySelector('[data-hidden-notice]')).not.toBeNull();
    expect(own.querySelector('[data-edited]')!.textContent).toBe('متعدّل');
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
    expect(t.root.textContent).toContain('لسه مفيش تعليقات');
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
    expect(t.$('[data-comment-counter]')!.textContent).toBe('فاضل 150 حرف');
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
    expect(t.$('[data-comment-error]')!.textContent).toBe('بتعلّق بسرعة أوي. استنى دقيقة وجرّب تاني.');
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
    expect(TestBed.inject(ToastService).toasts().map((toast) => toast.message)).toEqual(['شكراً، هنراجعه.']);
  });
});

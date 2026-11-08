import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { CommentDto, CommentPageDto } from '../../core/api/models';
import { RealtimeService } from '../../core/realtime/realtime.service';
import { BlockStore } from '../../core/social/block.store';
import { CommentsSection } from './comments-section';

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

async function render(page: Partial<CommentPageDto>) {
  const realtime = { watchCommentEvents: () => () => undefined };
  const { http } = setupSocialTesting({ providers: [{ provide: RealtimeService, useValue: realtime }] });
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
  const pick = async (commentId: string, action: string) => {
    $(`[data-comment="${commentId}"] [data-comment-menu]`)!.click();
    await stable();
    (document.querySelector(`[data-menu-action="${action}"]`) as HTMLElement).click();
    await stable();
  };
  return { fixture, root, http, $, $$, stable, pick };
}

const placeholderText = (el: Element) => el.querySelector('[data-comment-placeholder]')?.textContent!.trim() ?? null;

describe('Comments: Block and the reported collapse (F36, F22 store)', () => {
  let http: HttpTestingController;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => {
    http.verify();
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
  });

  it('a comment the API marks unavailable is a placeholder; its replies stay', async () => {
    const t = await render({
      total: 2,
      items: [dto('c1', { isUnavailable: true, body: null, replyCount: 1, replies: [dto('r1', { parentId: 'c1' })] })],
    });
    http = t.http;
    expect(placeholderText(t.$('[data-comment="c1"]')!)).toBe('هذا التعليق غير متاح');
    expect(t.$('[data-comment="r1"] [data-comment-body]')!.textContent).toContain('Comment r1');
  });

  it("Block commenter asks first; then all of that person's comments become placeholders", async () => {
    const author = dto('c1').author!;
    const t = await render({ total: 3, items: [dto('c1'), dto('c2', { author }), dto('c3')] });
    http = t.http;
    await t.pick('c1', 'blockCommenter');
    expect(t.$('#block-dialog-title')!.textContent!.replace(/\s+/g, ' ').trim()).toBe('هل تريد حظر @user_c1؟');
    expect(t.$$('[data-comment-placeholder]')).toHaveLength(0);
    t.$('[data-block-confirm]')!.click();
    await t.stable();
    // Shown at once, before the API answers.
    expect(placeholderText(t.$('[data-comment="c1"]')!)).toBe('هذا التعليق غير متاح');
    expect(placeholderText(t.$('[data-comment="c2"]')!)).toBe('هذا التعليق غير متاح');
    expect(placeholderText(t.$('[data-comment="c3"]')!)).toBeNull();
    const put = t.http.expectOne(`${TEST_API}/users/u-c1/block`);
    expect(put.request.method).toBe('PUT');
    put.flush({ userId: 'u-c1', isBlocked: true, followRemoved: false });
    await t.stable();
    expect(t.$('[data-block-dialog]')).toBeNull();

    // Unblocked elsewhere (Settings, a profile): the comments come back.
    const unblock = TestBed.inject(BlockStore).unblock({ id: 'u-c1', displayName: 'User c1', username: 'user_c1' });
    t.http.expectOne(`${TEST_API}/users/u-c1/block`).flush({ userId: 'u-c1', isBlocked: false, followRemoved: false });
    await unblock;
    await t.stable();
    expect(t.$$('[data-comment-placeholder]')).toHaveLength(0);
  });

  it('a comment you reported is collapsed for you, with «عرض» to read it', async () => {
    const t = await render({ total: 2, items: [dto('c1', { reportedByMe: true }), dto('c2')] });
    http = t.http;
    const c1 = t.$('[data-comment="c1"]')!;
    expect(c1.querySelector('[data-comment-reported]')!.textContent).toContain('أبلغت عن هذا المحتوى، ولن يظهر لك بعد الآن.');
    expect(c1.querySelector('[data-comment-body]')).toBeNull();
    expect(t.$('[data-comment="c2"] [data-comment-reported]')).toBeNull();
    (c1.querySelector('[data-reported-show]') as HTMLElement).click();
    await t.stable();
    expect(t.$('[data-comment="c1"] [data-comment-reported]')).toBeNull();
    expect(t.$('[data-comment="c1"] [data-comment-body]')!.textContent).toContain('Comment c1');
  });

  it('reporting a comment now collapses it at once; "Also block" hides the rest of theirs too', async () => {
    const author = dto('c1').author!;
    const t = await render({ total: 3, items: [dto('c1'), dto('c2', { author }), dto('c3')] });
    http = t.http;
    await t.pick('c1', 'report');
    expect(t.$('[data-also-block]')!.textContent).toContain('@user_c1');
    t.$<HTMLInputElement>('[data-reason="harassment"]')!.click();
    t.$<HTMLInputElement>('[data-also-block] input')!.click();
    await t.stable();
    t.$('[data-report-submit]')!.click();
    const req = t.http.expectOne(`${TEST_API}/reports`);
    expect(req.request.body).toEqual({ targetType: 'comment', targetId: 'c1', reason: 'harassment', alsoBlock: true });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    // Blocked: their comments are placeholders (that wins over the collapse); others stay.
    expect(placeholderText(t.$('[data-comment="c1"]')!)).toBe('هذا التعليق غير متاح');
    expect(placeholderText(t.$('[data-comment="c2"]')!)).toBe('هذا التعليق غير متاح');
    expect(t.$('[data-comment="c3"] [data-comment-body]')).not.toBeNull();
  });
});

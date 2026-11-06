import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { CommentDto, CommentPageDto } from '../../core/api/models';
import { CommentEvent, CommentEventType } from '../../core/realtime/realtime.service';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { CommentThread, CommentsStore, hiddenReplies } from './comments.store';

const LIST = `${TEST_API}/articles/a1/comments`;
const comment = (id: string) => `${TEST_API}/comments/${id}`;

/** A visible top-level comment by someone else (`u-{id}`), as a signed-in reader sees it. */
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

/** Yours (`user-1`, the signed-in test account). */
function mine(id: string, patch: Partial<CommentDto> = {}): CommentDto {
  return dto(id, {
    author: { id: 'user-1', displayName: 'Mona Adel', username: 'mona', avatarUrl: null, isVerified: false },
    canEdit: true,
    canDelete: true,
    canReport: false,
    ...patch,
  });
}

let eventSeq = 0;
function event(type: CommentEventType, commentId: string, parentId: string | null = null): CommentEvent {
  return { id: `k${++eventSeq}`, type, commentId, parentId, at: Date.now() };
}

const ids = (threads: readonly CommentThread[]) => threads.map((t) => t.comment.id);

describe('CommentsStore (F11, F27)', () => {
  let http: HttpTestingController;
  let store: CommentsStore;
  let social: ArticleSocialStore;
  let toasts: ToastService;
  const article = testCard(); // 3 comments

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http, toasts } = setupSocialTesting({ providers: [CommentsStore] }));
    store = TestBed.inject(CommentsStore);
    social = TestBed.inject(ArticleSocialStore);
    store.setArticle(article);
  });

  afterEach(() => http.verify());

  function expectList(sort: 'top' | 'new', cursor: string | null = null): TestRequest {
    return http.expectOne((req) => req.url === LIST && req.params.get('sort') === sort && req.params.get('cursor') === cursor);
  }

  /** The first page, in `sort` (switching to it loads it). */
  async function load(page: Partial<CommentPageDto>, sort: 'top' | 'new' = 'top'): Promise<void> {
    const body = { items: [], nextCursor: null, total: 0, ...page };
    if (sort === store.sort()) {
      const done = store.load();
      expectList(sort).flush(body);
      await done;
    } else {
      store.setSort(sort);
      expectList(sort).flush(body);
      await flushMicrotasks();
    }
  }

  describe('pages', () => {
    it('loads the first page with the pinned comment first and confirms the total', async () => {
      await load({ items: [dto('p', { isPinned: true }), dto('c1'), dto('c2')], nextCursor: 'n1', total: 9 });
      expect(store.status()).toBe('loaded');
      expect(ids(store.threads())).toEqual(['p', 'c1', 'c2']);
      expect(store.nextCursor()).toBe('n1');
      expect(store.total()).toBe(9);
      expect(social.state(article).commentCount).toBe(9); // the action bar shows it too
    });

    it('merges the next page without duplicates ("top" pages by offset)', async () => {
      await load({ items: [dto('c1'), dto('c2')], nextCursor: 'n1', total: 4 });
      const more = store.loadMore();
      expectList('top', 'n1').flush({ items: [dto('c2', { likeCount: 5 }), dto('c3')], nextCursor: null, total: 4 });
      await more;
      expect(ids(store.threads())).toEqual(['c1', 'c2', 'c3']);
      expect(store.threads()[1].comment.likeCount).toBe(0); // the copy already shown stays
      expect(store.nextCursor()).toBeNull();
    });

    it('a failed next page keeps the cursor to try again', async () => {
      await load({ items: [dto('c1')], nextCursor: 'n1', total: 2 });
      const more = store.loadMore();
      expectList('top', 'n1').flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
      await more;
      expect(store.moreFailed()).toBe(true);
      expect(store.nextCursor()).toBe('n1');
    });

    it('a new sort reloads from the first page', async () => {
      await load({ items: [dto('c1')], total: 1 });
      store.setSort('new');
      expect(store.status()).toBe('loading');
      expectList('new').flush({ items: [dto('c9'), dto('c1')], nextCursor: null, total: 2 });
      await flushMicrotasks();
      expect(ids(store.threads())).toEqual(['c9', 'c1']);
    });

    it('shows an error state when the first page fails', async () => {
      const done = store.load();
      expectList('top').flush(problem(404, 'article.not_found'), { status: 404, statusText: 'Not Found' });
      await done;
      expect(store.status()).toBe('error');
    });

    it('loads the rest of a thread\'s replies after the 2 included ones', async () => {
      await load({ items: [dto('c1', { replyCount: 4, replies: [dto('r1', { parentId: 'c1' }), dto('r2', { parentId: 'c1' })] })], total: 5 });
      expect(hiddenReplies(store.threads()[0])).toBe(2);

      const done = store.loadReplies('c1');
      const req = http.expectOne((r) => r.url === `${comment('c1')}/replies`);
      expect(req.request.params.get('cursor')).toBeNull();
      req.flush({ items: [dto('r1', { parentId: 'c1' }), dto('r2', { parentId: 'c1' }), dto('r3', { parentId: 'c1' }), dto('r4', { parentId: 'c1' })], nextCursor: null });
      await done;
      const thread = store.threads()[0];
      expect(thread.replies.map((r) => r.id)).toEqual(['r1', 'r2', 'r3', 'r4']);
      expect(thread.repliesComplete).toBe(true);
      expect(hiddenReplies(thread)).toBe(0);
    });
  });

  describe('your comments', () => {
    it('a new comment shows at once under the pinned one, then the server copy replaces it', async () => {
      await load({ items: [dto('p', { isPinned: true }), dto('c1')], total: 3 });
      const done = store.post('  Great article  ');
      const pending = store.threads()[1].comment;
      expect(pending.pending).toBe(true);
      expect(pending.body).toBe('Great article');
      expect(pending.author?.username).toBe('mona');

      const req = http.expectOne(LIST);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({ body: 'Great article' });
      req.flush(mine('new1', { body: 'Great article' }));
      await done;

      expect(ids(store.threads())).toEqual(['p', 'new1', 'c1']);
      expect(store.threads()[1].comment.pending).toBeUndefined();
      expect(store.threads()[1].comment.key).toBe(pending.key); // same row, no re-render
      expect(store.total()).toBe(4);
    });

    it('a failed comment leaves the list and rejects with the error', async () => {
      await load({ items: [dto('c1')], total: 1 });
      const done = store.post('again');
      http.expectOne(LIST).flush(problem(409, 'comment.duplicate'), { status: 409, statusText: 'Conflict' });
      await expect(done).rejects.toMatchObject({ code: 'comment.duplicate' });
      expect(ids(store.threads())).toEqual(['c1']);
      expect(store.total()).toBe(1);
    });

    it('a reply shows at the end of its thread and the server copy replaces it', async () => {
      await load({ items: [dto('c1', { replyCount: 1, replies: [dto('r1', { parentId: 'c1' })] })], total: 2 });
      const done = store.reply('c1', 'r1', '@user_r1 agreed');
      let thread = store.threads()[0];
      expect(thread.replies.map((r) => r.pending ?? false)).toEqual([false, true]);
      expect(thread.comment.replyCount).toBe(2);

      const req = http.expectOne(`${comment('r1')}/replies`); // replying to a reply: the server joins the thread
      expect(req.request.body).toEqual({ body: '@user_r1 agreed' });
      req.flush(mine('r2', { parentId: 'c1', body: '@user_r1 agreed', mentions: [{ userId: 'u-r1', username: 'user_r1' }] }));
      await done;

      thread = store.threads()[0];
      expect(thread.replies.map((r) => r.id)).toEqual(['r1', 'r2']);
      expect(thread.comment.replyCount).toBe(2);
      expect(store.total()).toBe(3);
    });

    it('a failed reply is rolled back', async () => {
      await load({ items: [dto('c1')], total: 1 });
      const done = store.reply('c1', 'c1', 'hi');
      http.expectOne(`${comment('c1')}/replies`).flush(problem(409, 'comment.not_available'), { status: 409, statusText: 'Conflict' });
      await expect(done).rejects.toMatchObject({ code: 'comment.not_available' });
      expect(store.threads()[0].replies).toEqual([]);
      expect(store.threads()[0].comment.replyCount).toBe(0);
    });

    it('deleting your comment leaves a placeholder only when it has replies', async () => {
      await load({ items: [mine('m1', { replyCount: 1, replies: [dto('r1', { parentId: 'm1' })] }), mine('m2')], total: 3 });
      let done = store.remove('m1');
      http.expectOne(comment('m1')).flush(null, { status: 204, statusText: 'No Content' });
      await done;
      expect(store.threads()[0].comment).toEqual(expect.objectContaining({ isDeleted: true, body: null, author: null, canDelete: false }));
      expect(store.threads()[0].replies.map((r) => r.id)).toEqual(['r1']);

      done = store.remove('m2');
      http.expectOne(comment('m2')).flush(null, { status: 204, statusText: 'No Content' });
      await done;
      expect(ids(store.threads())).toEqual(['m1']);
      expect(store.total()).toBe(1);
    });

    it('editing replaces the comment and keeps its replies', async () => {
      await load({ items: [mine('m1', { replyCount: 1, replies: [dto('r1', { parentId: 'm1' })] })], total: 2 });
      const done = store.edit('m1', 'better text');
      const req = http.expectOne(comment('m1'));
      expect(req.request.method).toBe('PATCH');
      req.flush(mine('m1', { body: 'better text', editedAt: '2026-11-03T11:00:00Z', replyCount: 1 }));
      await done;
      expect(store.threads()[0].comment.body).toBe('better text');
      expect(store.threads()[0].comment.editedAt).not.toBeNull();
      expect(store.threads()[0].replies.map((r) => r.id)).toEqual(['r1']);
    });

    it('pinning moves the comment to the top and unpins the previous one', async () => {
      await load({ items: [dto('p', { isPinned: true, canPin: true }), dto('c1', { canPin: true })], total: 2 });
      const done = store.togglePin('c1');
      const req = http.expectOne(`${comment('c1')}/pin`);
      expect(req.request.method).toBe('POST');
      req.flush(dto('c1', { isPinned: true, canPin: true }));
      await done;
      expect(ids(store.threads())).toEqual(['c1', 'p']);
      expect(store.threads().map((t) => t.comment.isPinned)).toEqual([true, false]);
    });

    it('a moderator hides a comment: it stays for them, marked hidden, and leaves the count', async () => {
      await load({ items: [dto('c1', { canModerate: true })], total: 1 });
      const done = store.moderate('c1', 'hide');
      const req = http.expectOne(`${TEST_API}/moderation/actions`);
      expect(req.request.body).toEqual({ action: 'hide', targetType: 'comment', targetId: 'c1' });
      req.flush(null, { status: 204, statusText: 'No Content' });
      await done;
      expect(store.threads()[0].comment.isHidden).toBe(true);
      expect(store.total()).toBe(0);
    });
  });

  describe('likes', () => {
    it('likes at once and takes the count the server confirms', async () => {
      await load({ items: [dto('c1', { likeCount: 2 })], total: 1 });
      const done = store.toggleLike('c1');
      expect(store.threads()[0].comment).toEqual(expect.objectContaining({ likedByMe: true, likeCount: 3 }));
      const req = http.expectOne(`${comment('c1')}/like`);
      expect(req.request.method).toBe('PUT');
      req.flush({ likeCount: 5, liked: true }); // others liked it meanwhile
      await done;
      expect(store.threads()[0].comment).toEqual(expect.objectContaining({ likedByMe: true, likeCount: 5 }));
    });

    it('rolls back and shows the translated error when the API refuses', async () => {
      await load({ items: [dto('c1', { likeCount: 2 })], total: 1 });
      const done = store.toggleLike('c1');
      http.expectOne(`${comment('c1')}/like`).flush(problem(409, 'comment.not_available'), { status: 409, statusText: 'Conflict' });
      await done;
      expect(store.threads()[0].comment).toEqual(expect.objectContaining({ likedByMe: false, likeCount: 2 }));
      expect(toasts.toasts().map((t) => t.message)).toEqual(['تم حذف هذا التعليق أو إخفاؤه.']);
    });

    it('quick taps send one request at a time, then the latest wish', async () => {
      await load({ items: [dto('c1', { likeCount: 2 })], total: 1 });
      const first = store.toggleLike('c1'); // like
      const second = store.toggleLike('c1'); // unlike while the like is on its way
      expect(store.threads()[0].comment).toEqual(expect.objectContaining({ likedByMe: false, likeCount: 2 }));
      http.expectOne((r) => r.url === `${comment('c1')}/like` && r.method === 'PUT').flush({ likeCount: 3, liked: true });
      await flushMicrotasks();
      expect(store.threads()[0].comment).toEqual(expect.objectContaining({ likedByMe: false, likeCount: 2 }));
      http.expectOne((r) => r.url === `${comment('c1')}/like` && r.method === 'DELETE').flush({ likeCount: 2, liked: false });
      await Promise.all([first, second]);
      expect(store.threads()[0].comment).toEqual(expect.objectContaining({ likedByMe: false, likeCount: 2 }));
    });
  });

  describe('live events (F27)', () => {
    it('in "Newest" with the top on screen, a new comment is fetched and inserted at the top, highlighted', async () => {
      await load({ items: [dto('c1')], total: 1 }, 'new');
      store.setSort('new'); // already "new": no reload
      http.expectNone((r) => r.url === LIST);
      const done = store.applyEvent(event('comment.created', 'c2'));
      http.expectOne(comment('c2')).flush(dto('c2'));
      await done;
      expect(ids(store.threads())).toEqual(['c2', 'c1']);
      expect(store.highlighted().has('c2')).toBe(true);
      expect(store.incomingCount()).toBe(0);
    });

    it('otherwise new comments wait behind the pill, deduped, and the pill inserts them newest first', async () => {
      await load({ items: [dto('p', { isPinned: true }), dto('c1')], total: 2 }); // "top"
      let done = store.applyEvent(event('comment.created', 'c2'));
      http.expectOne(comment('c2')).flush(dto('c2'));
      await done;
      await store.applyEvent(event('comment.created', 'c2')); // a retried write repeats the event: no request
      done = store.applyEvent(event('comment.created', 'c3'));
      http.expectOne(comment('c3')).flush(dto('c3'));
      await done;
      expect(store.incomingCount()).toBe(2);
      expect(ids(store.threads())).toEqual(['p', 'c1']);

      store.showIncoming();
      expect(ids(store.threads())).toEqual(['p', 'c3', 'c2', 'c1']);
      expect(store.incomingCount()).toBe(0);
      expect(store.highlighted().has('c3')).toBe(true);
    });

    it('when the user scrolled away in "Newest", the pill counts too', async () => {
      await load({ items: [dto('c1')], total: 1 }, 'new');
      store.nearTop = () => false;
      const done = store.applyEvent(event('comment.created', 'c2'));
      http.expectOne(comment('c2')).flush(dto('c2'));
      await done;
      expect(store.incomingCount()).toBe(1);
    });

    it('a new reply goes into its thread; replies of threads not loaded are ignored', async () => {
      await load({ items: [dto('c1', { replyCount: 1, replies: [dto('r1', { parentId: 'c1' })] })], total: 2 });
      const done = store.applyEvent(event('reply.created', 'r2', 'c1'));
      http.expectOne(comment('r2')).flush(dto('r2', { parentId: 'c1' }));
      await done;
      expect(store.threads()[0].replies.map((r) => r.id)).toEqual(['r1', 'r2']);
      expect(store.threads()[0].comment.replyCount).toBe(2);
      expect(store.highlighted().has('r2')).toBe(true);

      await store.applyEvent(event('reply.created', 'x1', 'elsewhere'));
      http.expectNone(comment('x1'));
    });

    it('a new reply in a thread with unloaded replies goes after "show more"', async () => {
      await load({ items: [dto('c1', { replyCount: 3, replies: [dto('r1', { parentId: 'c1' }), dto('r2', { parentId: 'c1' })] })], total: 4 });
      const done = store.applyEvent(event('reply.created', 'r9', 'c1'));
      http.expectOne(comment('r9')).flush(dto('r9', { parentId: 'c1' }));
      await done;
      const thread = store.threads()[0];
      expect(thread.tail.map((r) => r.id)).toEqual(['r9']);
      expect(hiddenReplies(thread)).toBe(1);
    });

    it('edits, likes and pins refetch the comment and replace it in place, keeping its replies', async () => {
      await load({ items: [dto('c1', { replyCount: 1, replies: [dto('r1', { parentId: 'c1' })] }), dto('c2')], total: 3 });
      let done = store.applyEvent(event('comment.updated', 'c1'));
      http.expectOne(comment('c1')).flush(dto('c1', { body: 'edited', editedAt: '2026-11-03T11:00:00Z', replyCount: 1 }));
      await done;
      expect(store.threads()[0].comment.body).toBe('edited');
      expect(store.threads()[0].replies.map((r) => r.id)).toEqual(['r1']);

      done = store.applyEvent(event('comment.liked', 'r1', 'c1'));
      http.expectOne(comment('r1')).flush(dto('r1', { parentId: 'c1', likeCount: 7 }));
      await done;
      expect(store.threads()[0].replies[0].likeCount).toBe(7);

      await store.applyEvent(event('comment.updated', 'unknown'));
      http.expectNone(comment('unknown'));
    });

    it('a deleted comment becomes a placeholder when it has replies and disappears otherwise', async () => {
      await load({ items: [dto('c1', { replyCount: 1, replies: [dto('r1', { parentId: 'c1' })] }), dto('c2')], total: 3 });
      let done = store.applyEvent(event('comment.deleted', 'c1'));
      http.expectOne(comment('c1')).flush(dto('c1', { isDeleted: true, body: null, author: null, replyCount: 1 }));
      await done;
      expect(store.threads()[0].comment.isDeleted).toBe(true);

      done = store.applyEvent(event('comment.deleted', 'c2'));
      http.expectOne(comment('c2')).flush(dto('c2', { isDeleted: true, body: null, author: null }));
      await done;
      expect(ids(store.threads())).toEqual(['c1']);

      done = store.applyEvent(event('comment.updated', 'r1', 'c1')); // hidden by a moderator: gone for readers
      http.expectOne(comment('r1')).flush(dto('r1', { parentId: 'c1', isHidden: true, body: null, author: null }));
      await done;
      expect(store.threads()[0].replies).toEqual([]);
      expect(store.threads()[0].comment.replyCount).toBe(0);
    });

    it('your own new comment is not shown twice when its event comes before the response', async () => {
      await load({ items: [dto('c1')], total: 1 }, 'new');
      store.nearTop = () => false;
      const posting = store.post('mine');
      const live = store.applyEvent(event('comment.created', 'm1'));
      http.expectOne(comment('m1')).flush(mine('m1', { body: 'mine' }));
      await live;
      expect(store.incomingCount()).toBe(0); // its POST brings it

      http.expectOne(LIST).flush(mine('m1', { body: 'mine' }));
      await posting;
      expect(ids(store.threads())).toEqual(['m1', 'c1']);

      await store.applyEvent(event('comment.created', 'm1')); // the echo: already shown
      http.expectNone(comment('m1'));
      expect(ids(store.threads())).toEqual(['m1', 'c1']);
    });

    it('skips refetches for a comment while your own change to it is on its way', async () => {
      await load({ items: [dto('c1', { likeCount: 1 })], total: 1 });
      const liking = store.toggleLike('c1');
      await store.applyEvent(event('comment.liked', 'c1'));
      http.expectNone(comment('c1'));
      http.expectOne(`${comment('c1')}/like`).flush({ likeCount: 2, liked: true });
      await liking;
      expect(store.threads()[0].comment).toEqual(expect.objectContaining({ likedByMe: true, likeCount: 2 }));
    });

    it('a comment that no longer exists is removed', async () => {
      await load({ items: [dto('c1'), dto('c2')], total: 2 });
      const done = store.applyEvent(event('comment.updated', 'c2'));
      http.expectOne(comment('c2')).flush(problem(404, 'comment.not_found'), { status: 404, statusText: 'Not Found' });
      await done;
      expect(ids(store.threads())).toEqual(['c1']);
    });

    it('follows the live comment count for the total', async () => {
      await load({ items: [dto('c1')], total: 1 });
      social.applyLive(article, { reactions: null, reactionCount: null, saveCount: null, commentCount: 6 });
      expect(store.total()).toBe(6);
    });

    it('ignores events until the first page is loaded', async () => {
      await store.applyEvent(event('comment.created', 'c1'));
      http.expectNone(comment('c1'));
    });
  });
});

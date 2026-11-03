import { DestroyRef, Injectable, computed, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { CommentsApi } from '../../core/api/comments.api';
import { ModerationApi } from '../../core/api/moderation.api';
import { ArticleCardDto, AuthorDto, CommentDto, CommentSort, ModerationAction } from '../../core/api/models';
import { SessionStore } from '../../core/auth/session.store';
import { CommentEvent } from '../../core/realtime/realtime.service';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { CommentErrors } from './comment-errors';
import { isPlaceholder } from './comment-text';

export const COMMENTS_PAGE_SIZE = 20;
export const REPLIES_PAGE_SIZE = 50;
/** How long a comment that just arrived live stays highlighted. */
export const HIGHLIGHT_MS = 2500;

/** A comment as the list shows it. */
export interface CommentView extends Omit<CommentDto, 'replies'> {
  /** Stable render key: a pending comment keeps it when the server's copy replaces it. */
  key: string;
  /** Shown at once while its POST is on the way. */
  pending?: boolean;
}

/** A top-level comment with its replies (one indented level, SPEC F11). */
export interface CommentThread {
  comment: CommentView;
  /** Loaded replies, oldest first, without gaps: the 2 the list included, then the pages of "show more". */
  replies: CommentView[];
  /** Replies added here (yours or live ones) while older replies are still unloaded; shown after "show more". */
  tail: CommentView[];
  repliesCursor: string | null;
  /** Every reply is in `replies`. */
  repliesComplete: boolean;
  repliesLoading: boolean;
  repliesFailed: boolean;
}

export type CommentsStatus = 'idle' | 'loading' | 'loaded' | 'error';

/** The one inline composer open in the list: a reply in a thread, or editing a comment. */
export type ComposerTarget = { kind: 'reply'; threadId: string; targetId: string; prefill: string } | { kind: 'edit'; commentId: string };

/** A sheet about one comment: report it, or confirm deleting it (yours, or as a moderator). */
export interface CommentDialog {
  kind: 'report' | 'delete' | 'moderatorDelete';
  comment: CommentView;
}

/** Replies of a thread that "show N more replies" would load. */
export function hiddenReplies(thread: CommentThread): number {
  return thread.repliesComplete ? 0 : Math.max(0, thread.comment.replyCount - thread.replies.length - thread.tail.length);
}

/** A server copy as the list shows it (replies live in the thread). */
function toView(dto: CommentDto, key?: string): CommentView {
  const view: CommentView & Pick<CommentDto, 'replies'> = { ...dto, key: key ?? dto.id };
  delete view.replies;
  return view;
}

function toThread(dto: CommentDto, key?: string): CommentThread {
  const replies = (dto.replies ?? []).map((reply) => toView(reply));
  return {
    comment: toView(dto, key),
    replies,
    tail: [],
    repliesCursor: null,
    repliesComplete: dto.replyCount <= replies.length,
    repliesLoading: false,
    repliesFailed: false,
  };
}

function pendingThread(comment: CommentView): CommentThread {
  return { comment, replies: [], tail: [], repliesCursor: null, repliesComplete: true, repliesLoading: false, repliesFailed: false };
}

/** New top-level comments go to the top, under the pinned one. */
function insertTop(threads: CommentThread[], thread: CommentThread): CommentThread[] {
  const at = threads[0]?.comment.isPinned ? 1 : 0;
  return [...threads.slice(0, at), thread, ...threads.slice(at)];
}

function placeholderOf(comment: CommentView): CommentView {
  return {
    ...comment,
    body: null,
    author: null,
    isArticleAuthor: false,
    mentions: [],
    likeCount: 0,
    likedByMe: false,
    isPinned: false,
    editedAt: null,
    isDeleted: true,
    isHidden: false,
    canEdit: false,
    canDelete: false,
    canPin: false,
    canReport: false,
    canModerate: false,
  };
}

/**
 * Comments of one article (F11) and their live updates (F27), provided by the comments section.
 *
 * - Pages: `top` or `new`, cursor pages merged without duplicates; replies of a thread load on demand.
 * - Your actions: a new comment or reply shows at once (pending) and the server's copy replaces it; likes are
 *   optimistic (one request at a time per comment, the latest wish wins) and roll back with a translated toast.
 * - Live events carry no content: new comments are fetched (`GET /comments/{id}`) and either inserted at the top
 *   (newest first, list top on screen) or kept for the "N new comments" pill; replies go into their thread; other
 *   events refetch the comment and replace it in place. Events are deduped by comment id, and events for a comment
 *   with one of your own changes on its way are skipped (the change's response is fresher).
 * - The total is the article's live `commentCount` (ArticleSocialStore), which REST pages and your own changes confirm.
 */
@Injectable()
export class CommentsStore {
  private readonly api = inject(CommentsApi);
  private readonly moderation = inject(ModerationApi);
  private readonly session = inject(SessionStore);
  private readonly social = inject(ArticleSocialStore);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(CommentErrors);

  private readonly _article = signal<ArticleCardDto | null>(null);
  private readonly _sort = signal<CommentSort>('top');
  private readonly _status = signal<CommentsStatus>('idle');
  private readonly _threads = signal<CommentThread[]>([]);
  private readonly _nextCursor = signal<string | null>(null);
  private readonly _loadingMore = signal(false);
  private readonly _moreFailed = signal(false);
  private readonly _incoming = signal<CommentDto[]>([]);
  private readonly _highlighted = signal<ReadonlySet<string>>(new Set());
  private readonly _composer = signal<ComposerTarget | null>(null);
  private readonly _dialog = signal<CommentDialog | null>(null);

  readonly sort = this._sort.asReadonly();
  readonly status = this._status.asReadonly();
  readonly threads = this._threads.asReadonly();
  readonly nextCursor = this._nextCursor.asReadonly();
  readonly loadingMore = this._loadingMore.asReadonly();
  readonly moreFailed = this._moreFailed.asReadonly();
  readonly highlighted = this._highlighted.asReadonly();
  readonly composer = this._composer.asReadonly();
  /** The report or delete sheet, for one comment. */
  readonly dialog = this._dialog.asReadonly();
  /** New top-level comments waiting behind the "N new comments" pill. */
  readonly incomingCount = computed(() => this._incoming().length);
  /** The article's comment count: live, confirmed by REST pages and your own changes. */
  readonly total = computed(() => {
    const article = this._article();
    return article ? this.social.state(article).commentCount : 0;
  });

  /** Whether the top of the list is on screen. Set by the section; live comments wait for the pill otherwise. */
  nearTop: () => boolean = () => true;

  private generation = 0;
  private pendingSeq = 0;
  /** Your comments and replies on their way (thread id or null), so their live echo isn't shown twice. */
  private readonly pendingPosts: (string | null)[] = [];
  /** Comments with one of your own requests on its way: live refetches would race with them. */
  private readonly busy = new Map<string, number>();
  /** Ids of created events already handled (a retried write can repeat an event). */
  private readonly createdSeen = new Set<string>();
  /** Running refetches; `true` when another event asked for a fresh copy meanwhile. */
  private readonly refreshing = new Map<string, boolean>();
  /** Like state the server last confirmed, for comments with a like request running. */
  private readonly likeServer = new Map<string, { liked: boolean; likeCount: number }>();
  private readonly liking = new Set<string>();
  private readonly timers = new Set<ReturnType<typeof setTimeout>>();

  constructor() {
    inject(DestroyRef).onDestroy(() => {
      this.generation++;
      this.timers.forEach(clearTimeout);
      this.timers.clear();
    });
  }

  /** The article whose comments these are (a fresher copy of it keeps the total right); `load()` reads its comments. */
  setArticle(article: ArticleCardDto): void {
    this._article.set(article);
  }

  setSort(sort: CommentSort): void {
    if (sort === this._sort()) return;
    this._sort.set(sort);
    void this.load();
  }

  /** The first page (again): after the section shows up, a new sort, or another account. */
  async load(): Promise<void> {
    const article = this._article();
    if (!article) return;
    const generation = ++this.generation;
    this._status.set('loading');
    this._threads.set([]);
    this._incoming.set([]);
    this._nextCursor.set(null);
    this._moreFailed.set(false);
    this._composer.set(null);
    this._dialog.set(null);
    this.createdSeen.clear();
    try {
      const page = await firstValueFrom(this.api.list(article.id, { sort: this._sort(), limit: COMMENTS_PAGE_SIZE }));
      if (generation !== this.generation) return;
      const seen = new Set<string>();
      this._threads.set(page.items.filter((c) => !seen.has(c.id) && !!seen.add(c.id)).map((c) => toThread(c)));
      this._nextCursor.set(page.nextCursor);
      this._status.set('loaded');
      this.confirmTotal(page.total);
    } catch {
      if (generation === this.generation) this._status.set('error');
    }
  }

  /** The next page, merged without duplicates ("top" pages by offset, so one can repeat). */
  async loadMore(): Promise<void> {
    const article = this._article();
    const cursor = this._nextCursor();
    if (!article || !cursor || this._status() !== 'loaded' || this._loadingMore()) return;
    const generation = this.generation;
    this._loadingMore.set(true);
    this._moreFailed.set(false);
    try {
      const page = await firstValueFrom(this.api.list(article.id, { sort: this._sort(), cursor, limit: COMMENTS_PAGE_SIZE }));
      if (generation !== this.generation) return;
      const known = this.knownIds();
      const fresh = page.items.filter((c) => !known.has(c.id) && !!known.add(c.id));
      const listed = new Set(page.items.map((c) => c.id));
      this._threads.update((list) => [...list, ...fresh.map((c) => toThread(c))]);
      this._incoming.update((list) => list.filter((c) => !listed.has(c.id)));
      this._nextCursor.set(page.nextCursor);
    } catch {
      if (generation === this.generation) this._moreFailed.set(true);
    } finally {
      if (generation === this.generation) this._loadingMore.set(false);
    }
  }

  /** "Show N more replies": the next replies page of a thread, oldest first. */
  async loadReplies(threadId: string): Promise<void> {
    const thread = this.thread(threadId);
    if (!thread || thread.repliesLoading || thread.repliesComplete) return;
    const generation = this.generation;
    this.patchThread(threadId, (t) => ({ ...t, repliesLoading: true, repliesFailed: false }));
    try {
      const page = await firstValueFrom(this.api.replies(threadId, { cursor: thread.repliesCursor, limit: REPLIES_PAGE_SIZE }));
      if (generation !== this.generation) return;
      this.patchThread(threadId, (t) => {
        const seen = new Set(t.replies.map((r) => r.id));
        let replies = [...t.replies, ...page.items.filter((r) => !seen.has(r.id) && !!seen.add(r.id)).map((r) => toView(r))];
        let tail = t.tail.filter((r) => !seen.has(r.id));
        const complete = page.nextCursor === null;
        if (complete) {
          replies = [...replies, ...tail];
          tail = [];
        }
        return { ...t, replies, tail, repliesCursor: page.nextCursor, repliesComplete: complete, repliesLoading: false };
      });
    } catch {
      if (generation === this.generation) this.patchThread(threadId, (t) => ({ ...t, repliesLoading: false, repliesFailed: true }));
    }
  }

  // ── Your comments ──

  /** Posts a top-level comment. It shows at once at the top; the server's copy replaces it. Rejects with the API error. */
  async post(body: string): Promise<void> {
    const article = this._article();
    const me = this.me();
    const text = body.trim();
    if (!article || !me || !text) return;
    const pending = this.pendingComment(article, null, text, me);
    const before = this.total();
    this.pendingPosts.push(null);
    this._threads.update((list) => insertTop(list, pendingThread(pending)));
    try {
      const created = await firstValueFrom(this.api.create(article.id, text));
      this.createdSeen.add(created.id);
      this._incoming.update((list) => list.filter((c) => c.id !== created.id));
      this._threads.update((list) => {
        const rest = list.filter((t) => t.comment.id !== created.id); // a live copy that came first
        const index = rest.findIndex((t) => t.comment.key === pending.key);
        if (index < 0) return insertTop(rest, toThread(created));
        return rest.map((t, i) => (i === index ? toThread(created, pending.key) : t));
      });
      this.adjustTotal(before, 1);
    } catch (error) {
      this._threads.update((list) => list.filter((t) => t.comment.key !== pending.key));
      throw error;
    } finally {
      this.pendingPosts.splice(this.pendingPosts.indexOf(null), 1);
    }
  }

  /**
   * Replies in a thread. `targetId` is the comment you reply to (the thread's comment or one of its replies: the server
   * joins a reply to a reply to the same thread). Shows at once at the end of the thread. Rejects with the API error.
   */
  async reply(threadId: string, targetId: string, body: string): Promise<void> {
    const article = this._article();
    const me = this.me();
    const text = body.trim();
    if (!article || !me || !text || !this.thread(threadId)) return;
    const pending = this.pendingComment(article, threadId, text, me);
    const before = this.total();
    this.pendingPosts.push(threadId);
    this.addReply(threadId, pending);
    try {
      const created = await firstValueFrom(this.api.reply(targetId, text));
      this.createdSeen.add(created.id);
      this.patchThread(threadId, (t) => {
        const duplicate = [...t.replies, ...t.tail].some((r) => r.id === created.id);
        const swap = (list: CommentView[]) =>
          list.filter((r) => r.id !== created.id).map((r) => (r.key === pending.key ? toView(created, pending.key) : r));
        return {
          ...t,
          replies: swap(t.replies),
          tail: swap(t.tail),
          comment: duplicate ? { ...t.comment, replyCount: Math.max(0, t.comment.replyCount - 1) } : t.comment,
        };
      });
      this.adjustTotal(before, 1);
    } catch (error) {
      this.patchThread(threadId, (t) => ({
        ...t,
        replies: t.replies.filter((r) => r.key !== pending.key),
        tail: t.tail.filter((r) => r.key !== pending.key),
        comment: { ...t.comment, replyCount: Math.max(0, t.comment.replyCount - 1) },
      }));
      throw error;
    } finally {
      this.pendingPosts.splice(this.pendingPosts.indexOf(threadId), 1);
    }
  }

  /** Edits your comment (shows "edited"). Rejects with the API error. */
  async edit(commentId: string, body: string): Promise<void> {
    const text = body.trim();
    if (!text) return;
    await this.whileBusy(commentId, async () => this.replace(await firstValueFrom(this.api.update(commentId, text))));
  }

  /** Deletes your comment: a top-level comment with replies stays as a placeholder. Rejects with the API error. */
  async remove(commentId: string): Promise<void> {
    const comment = this.find(commentId);
    if (!comment) return;
    const before = this.total();
    await this.whileBusy(commentId, async () => {
      await firstValueFrom(this.api.delete(commentId));
      this.drop(comment);
      if (!comment.isHidden && !isPlaceholder(comment)) this.adjustTotal(before, -1);
    });
  }

  /** Likes or unlikes at once; one request per comment at a time, the latest wish wins, a failure rolls back. */
  async toggleLike(commentId: string): Promise<void> {
    const comment = this.find(commentId);
    if (!comment || comment.pending || isPlaceholder(comment)) return;
    if (!this.likeServer.has(commentId)) this.likeServer.set(commentId, { liked: comment.likedByMe, likeCount: comment.likeCount });
    const wish = !comment.likedByMe;
    this.patchComment(commentId, (c) => ({ ...c, likedByMe: wish, likeCount: Math.max(0, c.likeCount + (wish ? 1 : -1)) }));
    if (this.liking.has(commentId)) return; // the running loop sends the newest wish when its request ends
    this.liking.add(commentId);
    this.mark(commentId, 1);
    try {
      for (;;) {
        const current = this.find(commentId);
        const server = this.likeServer.get(commentId)!;
        if (!current) return;
        const target = current.likedByMe;
        if (target === server.liked) {
          this.patchComment(commentId, (c) => ({ ...c, likeCount: server.likeCount }));
          return;
        }
        try {
          const result = await firstValueFrom(target ? this.api.like(commentId) : this.api.unlike(commentId));
          this.likeServer.set(commentId, { liked: result.liked, likeCount: result.likeCount });
          this.patchComment(commentId, (c) => {
            const liked = c.likedByMe === target ? result.liked : c.likedByMe; // a newer wish stays on top
            return { ...c, likedByMe: liked, likeCount: Math.max(0, result.likeCount + (liked === result.liked ? 0 : liked ? 1 : -1)) };
          });
        } catch (error) {
          if (this.find(commentId)?.likedByMe !== target) continue; // a newer wish replaces this one
          this.patchComment(commentId, (c) => ({ ...c, likedByMe: server.liked, likeCount: server.likeCount }));
          this.toasts.error(this.errors.message(error));
          return;
        }
      }
    } finally {
      this.liking.delete(commentId);
      this.likeServer.delete(commentId);
      this.mark(commentId, -1);
    }
  }

  /** Pins (the article's author) or unpins a top-level comment; pinning moves it to the top. Rejects with the API error. */
  async togglePin(commentId: string): Promise<void> {
    const comment = this.find(commentId);
    if (!comment || comment.parentId) return;
    await this.whileBusy(commentId, async () =>
      this.replace(await firstValueFrom(comment.isPinned ? this.api.unpin(commentId) : this.api.pin(commentId))),
    );
  }

  /** Moderator hide / unhide / delete (audited). Rejects with the API error. */
  async moderate(commentId: string, action: ModerationAction): Promise<void> {
    const comment = this.find(commentId);
    if (!comment) return;
    const before = this.total();
    const visible = !comment.isHidden && !isPlaceholder(comment);
    await this.whileBusy(commentId, async () => {
      await firstValueFrom(this.moderation.moderateComment(commentId, action));
      if (action === 'delete') {
        this.drop(comment);
        if (visible) this.adjustTotal(before, -1);
      } else {
        const hidden = action === 'hide';
        this.patchComment(commentId, (c) => ({ ...c, isHidden: hidden, canPin: hidden ? false : c.canPin }));
        if (visible === hidden) this.adjustTotal(before, hidden ? -1 : 1);
      }
    });
  }

  // ── Inline composer and sheets ──

  openDialog(dialog: CommentDialog): void {
    this._dialog.set(dialog);
  }

  closeDialog(): void {
    this._dialog.set(null);
  }

  /** Opens the reply composer; replying to a reply pre-fills its author's @handle. */
  openReply(threadId: string, target: CommentView): void {
    const me = this.session.me()?.id;
    const handle = target.parentId && target.author && target.author.id !== me ? `@${target.author.username} ` : '';
    this._composer.set({ kind: 'reply', threadId, targetId: target.id, prefill: handle });
  }

  openEdit(commentId: string): void {
    this._composer.set({ kind: 'edit', commentId });
  }

  closeComposer(): void {
    this._composer.set(null);
  }

  // ── Live (F27) ──

  /** Applies one live comment event of this article. */
  async applyEvent(event: CommentEvent): Promise<void> {
    if (this._status() !== 'loaded') return; // the page being loaded is fresher
    const { commentId } = event;
    if (event.type === 'comment.created' || event.type === 'reply.created') {
      if (this.createdSeen.has(commentId) || this.isKnown(commentId)) return;
      if (event.type === 'reply.created' && event.parentId && !this.thread(event.parentId)) return; // thread not loaded
      this.createdSeen.add(commentId);
      const generation = this.generation;
      let dto: CommentDto;
      try {
        dto = await firstValueFrom(this.api.get(commentId));
      } catch {
        this.createdSeen.delete(commentId);
        return;
      }
      if (generation !== this.generation || this.isKnown(dto.id) || isPlaceholder(dto) || this.isOwnPending(dto)) return;
      if (dto.parentId) {
        if (!this.thread(dto.parentId)) return;
        this.addReply(dto.parentId, toView(dto));
        this.highlight(dto.id);
      } else if (this._sort() === 'new' && this.nearTop()) {
        this._threads.update((list) => insertTop(list, toThread(dto)));
        this.highlight(dto.id);
      } else {
        this._incoming.update((list) => [dto, ...list]);
      }
      return;
    }
    if (!this.isKnown(commentId) || this.busy.has(commentId)) return;
    await this.refresh(commentId);
  }

  /** The pill: puts the waiting comments at the top (newest first) and highlights them. */
  showIncoming(): void {
    const incoming = this._incoming();
    if (!incoming.length) return;
    this._incoming.set([]);
    const known = this.knownIds();
    let threads = this._threads();
    for (const dto of [...incoming].reverse()) {
      if (known.has(dto.id)) continue;
      threads = insertTop(threads, toThread(dto));
      this.highlight(dto.id);
    }
    this._threads.set(threads);
  }

  // ── Internals ──

  /** Refetches a comment and replaces it; coalesces events that arrive while a refetch runs. */
  private async refresh(commentId: string): Promise<void> {
    if (this.refreshing.has(commentId)) {
      this.refreshing.set(commentId, true);
      return;
    }
    const generation = this.generation;
    this.refreshing.set(commentId, false);
    try {
      for (;;) {
        try {
          const dto = await firstValueFrom(this.api.get(commentId));
          if (generation === this.generation && !this.busy.has(commentId)) this.replace(dto);
        } catch (error) {
          const comment = this.find(commentId);
          if (generation === this.generation && comment && isApiError(error) && error.status === 404) this.drop(comment);
        }
        if (!this.refreshing.get(commentId)) return;
        this.refreshing.set(commentId, false);
      }
    } finally {
      this.refreshing.delete(commentId);
    }
  }

  /**
   * Puts the server's copy in place. A placeholder disappears unless it is a top-level comment that still has replies
   * (as in the lists); a newly pinned comment moves to the top and the previous pinned one is unpinned.
   */
  private replace(dto: CommentDto): void {
    if (dto.parentId === null) {
      const remove = isPlaceholder(dto) && dto.replyCount === 0;
      this._incoming.update((list) => (remove ? list.filter((c) => c.id !== dto.id) : list.map((c) => (c.id === dto.id ? dto : c))));
      this._threads.update((list) => {
        const index = list.findIndex((t) => t.comment.id === dto.id);
        if (index < 0) return list;
        if (remove) return list.filter((_, i) => i !== index);
        const current = list[index];
        const thread: CommentThread = { ...current, comment: toView(dto, current.comment.key) };
        if (dto.isPinned && !current.comment.isPinned) {
          const others = list.filter((_, i) => i !== index).map((t) => (t.comment.isPinned ? { ...t, comment: { ...t.comment, isPinned: false } } : t));
          return [thread, ...others];
        }
        return list.map((t, i) => (i === index ? thread : t));
      });
      return;
    }
    this.patchThread(dto.parentId, (t) => {
      if (![...t.replies, ...t.tail].some((r) => r.id === dto.id)) return t;
      if (isPlaceholder(dto)) {
        return {
          ...t,
          replies: t.replies.filter((r) => r.id !== dto.id),
          tail: t.tail.filter((r) => r.id !== dto.id),
          comment: { ...t.comment, replyCount: Math.max(0, t.comment.replyCount - 1) },
        };
      }
      const swap = (list: CommentView[]) => list.map((r) => (r.id === dto.id ? toView(dto, r.key) : r));
      return { ...t, replies: swap(t.replies), tail: swap(t.tail) };
    });
  }

  /** A deleted comment: a top-level one with replies becomes a placeholder, anything else leaves the list. */
  private drop(comment: CommentView): void {
    if (comment.parentId === null) {
      this._incoming.update((list) => list.filter((c) => c.id !== comment.id));
      this._threads.update((list) =>
        list.flatMap((t) => {
          if (t.comment.id !== comment.id) return [t];
          return t.comment.replyCount > 0 ? [{ ...t, comment: placeholderOf(t.comment) }] : [];
        }),
      );
      return;
    }
    this.replace({ ...placeholderOf(comment), parentId: comment.parentId });
  }

  private addReply(threadId: string, reply: CommentView): void {
    this.patchThread(threadId, (t) => ({
      ...t,
      replies: t.repliesComplete ? [...t.replies, reply] : t.replies,
      tail: t.repliesComplete ? t.tail : [...t.tail, reply],
      comment: { ...t.comment, replyCount: t.comment.replyCount + 1 },
    }));
  }

  private pendingComment(article: ArticleCardDto, parentId: string | null, body: string, me: AuthorDto): CommentView {
    const key = `pending-${++this.pendingSeq}`;
    return {
      key,
      id: key,
      pending: true,
      articleId: article.id,
      parentId,
      body,
      author: me,
      isArticleAuthor: me.id === article.author.id,
      mentions: [],
      likeCount: 0,
      likedByMe: false,
      replyCount: 0,
      isPinned: false,
      createdAt: new Date().toISOString(),
      editedAt: null,
      isDeleted: false,
      isHidden: false,
      canEdit: false,
      canDelete: false,
      canPin: false,
      canReport: false,
      canModerate: false,
    };
  }

  /** Your own comment whose POST is still on its way: its response brings it. */
  private isOwnPending(dto: CommentDto): boolean {
    const me = this.session.me()?.id;
    return !!me && dto.author?.id === me && this.pendingPosts.includes(dto.parentId);
  }

  private me(): AuthorDto | null {
    const me = this.session.isAuthenticated() ? this.session.me() : null;
    return me ? { id: me.id, displayName: me.displayName, username: me.username, avatarUrl: me.avatarUrl, isVerified: me.isVerified } : null;
  }

  private async whileBusy(commentId: string, work: () => Promise<void>): Promise<void> {
    this.mark(commentId, 1);
    try {
      await work();
    } finally {
      this.mark(commentId, -1);
    }
  }

  private mark(commentId: string, delta: number): void {
    const count = (this.busy.get(commentId) ?? 0) + delta;
    if (count > 0) this.busy.set(commentId, count);
    else this.busy.delete(commentId);
  }

  private highlight(commentId: string): void {
    this._highlighted.update((set) => new Set(set).add(commentId));
    const timer = setTimeout(() => {
      this.timers.delete(timer);
      this._highlighted.update((set) => {
        const next = new Set(set);
        next.delete(commentId);
        return next;
      });
    }, HIGHLIGHT_MS);
    this.timers.add(timer);
  }

  /** REST knows the article's current count: it replaces the live/confirmed one. */
  private confirmTotal(total: number): void {
    const article = this._article();
    if (article) this.social.applyLive(article, { reactions: null, reactionCount: null, saveCount: null, commentCount: Math.max(0, total) });
  }

  /** Your own change moves the total, unless the live counter already did meanwhile (never counted twice). */
  private adjustTotal(before: number, delta: number): void {
    if (this.total() === before) this.confirmTotal(before + delta);
  }

  private thread(threadId: string): CommentThread | null {
    return this._threads().find((t) => t.comment.id === threadId) ?? null;
  }

  private patchThread(threadId: string, update: (thread: CommentThread) => CommentThread): void {
    this._threads.update((list) => list.map((t) => (t.comment.id === threadId ? update(t) : t)));
  }

  private find(commentId: string): CommentView | null {
    for (const t of this._threads()) {
      if (t.comment.id === commentId) return t.comment;
      const reply = t.replies.find((r) => r.id === commentId) ?? t.tail.find((r) => r.id === commentId);
      if (reply) return reply;
    }
    const incoming = this._incoming().find((c) => c.id === commentId);
    return incoming ? toView(incoming) : null;
  }

  private patchComment(commentId: string, update: (comment: CommentView) => CommentView): void {
    const apply = (list: CommentView[]) => (list.some((r) => r.id === commentId) ? list.map((r) => (r.id === commentId ? update(r) : r)) : list);
    this._threads.update((list) =>
      list.map((t) => {
        if (t.comment.id === commentId) return { ...t, comment: update(t.comment) };
        const replies = apply(t.replies);
        const tail = apply(t.tail);
        return replies === t.replies && tail === t.tail ? t : { ...t, replies, tail };
      }),
    );
  }

  private isKnown(commentId: string): boolean {
    return this.find(commentId) !== null;
  }

  private knownIds(): Set<string> {
    const ids = new Set<string>();
    for (const t of this._threads()) {
      ids.add(t.comment.id);
      for (const r of t.replies) ids.add(r.id);
      for (const r of t.tail) ids.add(r.id);
    }
    for (const c of this._incoming()) ids.add(c.id);
    return ids;
  }
}

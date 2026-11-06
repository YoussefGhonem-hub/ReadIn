import { Injectable, Injector, PLATFORM_ID, computed, effect, inject, signal, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { firstValueFrom } from 'rxjs';
import { RealtimeApi } from '../api/realtime.api';
import { SessionStore } from '../auth/session.store';
import { LIVE_CONNECTOR, LiveConnection, Unsubscribe } from './live-connection';
import { UnreadLive } from './unread-live';

export type { Unsubscribe } from './live-connection';

export type RealtimeState = 'disconnected' | 'connecting' | 'connected';

export type ReactionType = 'insightful' | 'love' | 'fire' | 'mindBlown';
export const REACTION_TYPES: readonly ReactionType[] = ['insightful', 'love', 'fire', 'mindBlown'];

/**
 * Live counters of one article (`/live/articles/{id}`). They are totals, not deltas, so the user's own optimistic
 * changes are never counted twice. A field is null until the API has published it; callers keep the REST value then.
 */
export interface LiveArticleCounts {
  reactions: Record<ReactionType, number> | null;
  reactionCount: number | null;
  commentCount: number | null;
  saveCount: number | null;
  /** F29. Optional for callers that only confirm other counters (left out = unknown). */
  repostCount?: number | null;
}

export type CommentEventType =
  | 'comment.created'
  | 'comment.updated'
  | 'comment.deleted'
  | 'reply.created'
  | 'comment.liked'
  | 'comment.pinned';

const COMMENT_EVENT_TYPES = new Set<string>([
  'comment.created',
  'comment.updated',
  'comment.deleted',
  'reply.created',
  'comment.liked',
  'comment.pinned',
]);

/** A signal that a comment changed. It never carries the text: the comment is fetched from the REST API. */
export interface CommentEvent {
  id: string;
  type: CommentEventType;
  commentId: string;
  parentId: string | null;
  at: number;
}

/** Article and user ids become RTDB path segments, so anything outside a GUID's alphabet is refused. */
const SAFE_ID = /^[A-Za-z0-9_-]{1,64}$/;

/**
 * Live updates from the Firebase Realtime Database (SPEC §21.2, F27): article counters, comment events, the
 * "new articles" signal and the signed-in user's unread-notification badge. The database carries signals only;
 * content always comes from the REST API, and everything keeps working through REST when it is unavailable.
 * Browser only: during SSR every listener is a no-op.
 */
@Injectable({ providedIn: 'root' })
export class RealtimeService {
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly connector = inject(LIVE_CONNECTOR);
  private readonly session = inject(SessionStore);
  private readonly api = inject(RealtimeApi);
  private readonly injector = inject(Injector);

  private connection: Promise<LiveConnection | null> | null = null;
  /** Custom-token sign-ins and sign-outs run one after another, so a quick account switch cannot interleave them. */
  private authQueue: Promise<unknown> = Promise.resolve();
  private readonly userId = computed(() => (this.session.isAuthenticated() ? (this.session.me()?.id ?? null) : null));

  private readonly _state = signal<RealtimeState>('disconnected');
  /** The badge's live count, in a store of its own: the badge is in the initial bundle, this service isn't. */
  private readonly _unreadNotifications = inject(UnreadLive).count;
  private readonly _unreadLive = inject(UnreadLive).live;
  readonly state = this._state.asReadonly();
  /** `/live/users/{id}/unreadNotifications`; 0 for guests and until the first value arrives. */
  readonly unreadNotifications = this._unreadNotifications.asReadonly();
  /**
   * True once the signed-in user's badge has a value from the Realtime Database. Until then (connecting, no custom
   * token, SDK blocked) the badge comes from `GET /me/notifications/unread-count` (NotificationBadge).
   */
  readonly unreadLive = this._unreadLive.asReadonly();

  /** Follows the signed-in user's badge. Called once from an app initializer. */
  init(): void {
    if (!this.isBrowser) return;
    let generation = 0;
    effect(
      (onCleanup) => {
        const userId = this.userId();
        const current = ++generation;
        untracked(() => {
          this._unreadNotifications.set(0);
          this._unreadLive.set(false);
        });
        if (!userId) return;

        const isCurrent = () => current === generation;
        let stop: Unsubscribe | null = null;
        void this.followUser(userId, isCurrent).then((unsubscribe) => {
          if (isCurrent()) stop = unsubscribe;
          else unsubscribe?.();
        });
        onCleanup(() => {
          generation++;
          stop?.();
          // Signing out of ReadIn also signs out of Firebase (SPEC §21.2).
          void this.connection?.then((connection) => connection && this.enqueue(() => connection.signOut()));
        });
      },
      { injector: this.injector },
    );
  }

  /** Live counters of an article. Returns the function that stops listening. */
  watchArticle(articleId: string, next: (counts: LiveArticleCounts) => void): Unsubscribe {
    if (!SAFE_ID.test(articleId)) return noop;
    const base = `live/articles/${articleId}`;
    const counts: LiveArticleCounts = { reactions: null, reactionCount: null, commentCount: null, saveCount: null, repostCount: null };
    const emit = () => next({ ...counts, reactions: counts.reactions && { ...counts.reactions } });
    // Separate listeners, so the article's event list is never downloaded with its counters.
    return this.listen((connection) => [
      connection.onValue(`${base}/reactions`, (value) => {
        counts.reactions = toReactions(value);
        counts.reactionCount = counts.reactions && REACTION_TYPES.reduce((sum, type) => sum + counts.reactions![type], 0);
        emit();
      }),
      connection.onValue(`${base}/commentCount`, (value) => {
        counts.commentCount = toCount(value);
        emit();
      }),
      connection.onValue(`${base}/saveCount`, (value) => {
        counts.saveCount = toCount(value);
        emit();
      }),
      connection.onValue(`${base}/repostCount`, (value) => {
        counts.repostCount = toCount(value);
        emit();
      }),
    ]);
  }

  /** Comment events of an article from now on (older ones are skipped). */
  watchCommentEvents(articleId: string, next: (event: CommentEvent) => void): Unsubscribe {
    if (!SAFE_ID.test(articleId)) return noop;
    return this.listen(async (connection) => {
      const since = await connection.serverTime();
      return [
        connection.onChildAddedSince(`live/articles/${articleId}/events`, 'at', since, (key, value) => {
          const event = toCommentEvent(key, value);
          if (event) next(event);
        }),
      ];
    });
  }

  /** `/live/feed/latestPublishedAt` as epoch ms, or null when unknown. */
  watchLatestPublished(next: (publishedAt: number | null) => void): Unsubscribe {
    return this.listen((connection) => [connection.onValue('live/feed/latestPublishedAt', (value) => next(toTimestamp(value)))]);
  }

  private async followUser(userId: string, isCurrent: () => boolean): Promise<Unsubscribe | null> {
    if (!SAFE_ID.test(userId)) return null;
    const connection = await this.connect();
    if (!connection || !isCurrent()) return null;
    try {
      const { token } = await firstValueFrom(this.api.token());
      if (!isCurrent()) return null;
      await this.enqueue(() => connection.signIn(token));
    } catch {
      return null; // no token (offline, older API): the badge waits for the next sign-in, REST still works
    }
    if (!isCurrent()) return null;
    return connection.onValue(`live/users/${userId}/unreadNotifications`, (value) => {
      if (!isCurrent()) return;
      this._unreadNotifications.set(toCount(value) ?? 0);
      this._unreadLive.set(true);
    });
  }

  /**
   * The notification center was opened (`POST /me/notifications/seen`): the badge shows 0 at once. The API then
   * publishes 0 too, or a higher count when something new arrived meanwhile, which replaces this.
   */
  clearUnreadNotifications(): void {
    this._unreadNotifications.set(0);
  }

  /** Subscribes once connected. The returned function also works before that, and is a no-op during SSR. */
  private listen(subscribe: (connection: LiveConnection) => Unsubscribe[] | Promise<Unsubscribe[]>): Unsubscribe {
    if (!this.isBrowser) return noop;
    let stopped = false;
    let stops: Unsubscribe[] = [];
    void this.connect()
      .then(async (connection) => {
        if (!connection || stopped) return;
        const created = await subscribe(connection);
        if (stopped) created.forEach((stop) => stop());
        else stops = created;
      })
      .catch(() => undefined);
    return () => {
      stopped = true;
      stops.forEach((stop) => stop());
      stops = [];
    };
  }

  private connect(): Promise<LiveConnection | null> {
    if (!this.connection) {
      this._state.set('connecting');
      this.connection = this.connector().then(
        (connection) => {
          connection.onConnectedChange((connected) => this._state.set(connected ? 'connected' : 'connecting'));
          return connection;
        },
        () => {
          this._state.set('disconnected'); // SDK blocked or failed to load: REST only
          return null;
        },
      );
    }
    return this.connection;
  }

  private enqueue<T>(operation: () => Promise<T>): Promise<T> {
    const result = this.authQueue.then(operation, operation);
    this.authQueue = result.catch(() => undefined);
    return result;
  }
}

const noop: Unsubscribe = () => undefined;

function toCount(value: unknown): number | null {
  return typeof value === 'number' && Number.isFinite(value) && value >= 0 ? Math.floor(value) : null;
}

function toTimestamp(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? null : parsed;
  }
  return null;
}

function toReactions(value: unknown): Record<ReactionType, number> | null {
  if (!value || typeof value !== 'object') return null;
  const source = value as Record<string, unknown>;
  return Object.fromEntries(REACTION_TYPES.map((type) => [type, toCount(source[type]) ?? 0])) as Record<ReactionType, number>;
}

function toCommentEvent(key: string, value: unknown): CommentEvent | null {
  if (!value || typeof value !== 'object') return null;
  const { type, commentId, parentId, at } = value as Record<string, unknown>;
  if (typeof type !== 'string' || !COMMENT_EVENT_TYPES.has(type) || typeof commentId !== 'string') return null;
  return {
    id: key,
    type: type as CommentEventType,
    commentId,
    parentId: typeof parentId === 'string' ? parentId : null,
    at: toTimestamp(at) ?? 0,
  };
}

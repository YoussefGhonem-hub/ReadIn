import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Observable, of, throwError } from 'rxjs';
import { MeDto } from '../api/models';
import { RealtimeApi, RealtimeTokenDto } from '../api/realtime.api';
import { SessionStore } from '../auth/session.store';
import { LIVE_CONNECTOR, LiveConnection, Unsubscribe } from './live-connection';
import { CommentEvent, LiveArticleCounts, RealtimeService } from './realtime.service';

type Listener = (value: unknown) => void;
interface ChildListener {
  path: string;
  orderBy: string;
  since: number;
  next: (key: string, value: unknown) => void;
}

/** In-memory stand-in for the Realtime Database. */
class FakeConnection implements LiveConnection {
  private readonly values = new Map<string, Set<Listener>>();
  readonly children: ChildListener[] = [];
  readonly signIn = vi.fn<(token: string) => Promise<void>>(async () => undefined);
  readonly signOut = vi.fn(async () => undefined);
  serverNow = 1_700_000_000_000;

  onValue(path: string, next: Listener): Unsubscribe {
    const listeners = this.values.get(path) ?? new Set<Listener>();
    listeners.add(next);
    this.values.set(path, listeners);
    return () => listeners.delete(next);
  }

  onChildAddedSince(path: string, orderBy: string, since: number, next: ChildListener['next']): Unsubscribe {
    const entry = { path, orderBy, since, next };
    this.children.push(entry);
    return () => this.children.splice(this.children.indexOf(entry), 1);
  }

  serverTime(): Promise<number> {
    return Promise.resolve(this.serverNow);
  }

  onConnectedChange(next: (connected: boolean) => void): Unsubscribe {
    next(true);
    return () => undefined;
  }

  listenerCount(path: string): number {
    return this.values.get(path)?.size ?? 0;
  }

  emit(path: string, value: unknown): void {
    this.values.get(path)?.forEach((listener) => listener(value));
  }
}

const flush = () => new Promise<void>((resolve) => setTimeout(resolve, 0));

function setup(options: { connection?: FakeConnection | null; token?: () => Observable<RealtimeTokenDto>; platform?: string } = {}) {
  const connection = options.connection === undefined ? new FakeConnection() : options.connection;
  const connector = vi.fn(() => (connection ? Promise.resolve(connection) : Promise.reject(new Error('SDK blocked'))));
  const api = { token: vi.fn(options.token ?? (() => of({ token: 'custom-token' }))) };
  TestBed.configureTestingModule({
    providers: [
      { provide: LIVE_CONNECTOR, useValue: connector },
      { provide: RealtimeApi, useValue: api },
      { provide: PLATFORM_ID, useValue: options.platform ?? 'browser' },
    ],
  });
  return { service: TestBed.inject(RealtimeService), session: TestBed.inject(SessionStore), connection: connection!, connector, api };
}

function signIn(session: SessionStore, id = 'user-1'): void {
  session.setMe({ id, displayName: 'Mona' } as MeDto);
}

describe('RealtimeService', () => {
  beforeEach(() => TestBed.resetTestingModule());

  describe('article counters', () => {
    it('combines the counters, totals the reactions and keeps unknown fields null', async () => {
      const { service, connection } = setup();
      const seen: LiveArticleCounts[] = [];
      service.watchArticle('a1', (counts) => seen.push(counts));
      await flush();

      connection.emit('live/articles/a1/commentCount', 7);
      expect(seen.at(-1)).toEqual({ reactions: null, reactionCount: null, commentCount: 7, saveCount: null, repostCount: null });

      connection.emit('live/articles/a1/reactions', { insightful: 3, love: 2, fire: 1 });
      expect(seen.at(-1)).toEqual({
        reactions: { insightful: 3, love: 2, fire: 1, mindBlown: 0 },
        reactionCount: 6,
        commentCount: 7,
        saveCount: null,
        repostCount: null,
      });

      // F29: the repost counter, like the others.
      connection.emit('live/articles/a1/repostCount', 3);
      expect(seen.at(-1)?.repostCount).toBe(3);
    });

    it('listens to the counters only, never the whole article node with its events', async () => {
      const { service, connection } = setup();
      service.watchArticle('a1', () => undefined);
      await flush();

      expect(connection.listenerCount('live/articles/a1')).toBe(0);
      expect(connection.listenerCount('live/articles/a1/reactions')).toBe(1);
      expect(connection.listenerCount('live/articles/a1/commentCount')).toBe(1);
      expect(connection.listenerCount('live/articles/a1/saveCount')).toBe(1);
      expect(connection.listenerCount('live/articles/a1/repostCount')).toBe(1);
    });

    it('ignores malformed values instead of showing them', async () => {
      const { service, connection } = setup();
      const seen: LiveArticleCounts[] = [];
      service.watchArticle('a1', (counts) => seen.push(counts));
      await flush();

      connection.emit('live/articles/a1/commentCount', 'many');
      connection.emit('live/articles/a1/saveCount', -4);
      expect(seen.at(-1)?.commentCount).toBeNull();
      expect(seen.at(-1)?.saveCount).toBeNull();
    });

    it('stops listening, also when stopped before the connection is open', async () => {
      const { service, connection } = setup();
      const stopEarly = service.watchArticle('a1', () => undefined);
      stopEarly();
      await flush();
      expect(connection.listenerCount('live/articles/a1/commentCount')).toBe(0);

      const stop = service.watchArticle('a2', () => undefined);
      await flush();
      expect(connection.listenerCount('live/articles/a2/commentCount')).toBe(1);
      stop();
      expect(connection.listenerCount('live/articles/a2/commentCount')).toBe(0);
    });

    it('refuses ids that are not safe path segments', async () => {
      const { service, connector } = setup();
      service.watchArticle('a1/../../users/u2', () => undefined);
      service.watchCommentEvents('a.b', () => undefined);
      await flush();
      expect(connector).not.toHaveBeenCalled();
    });
  });

  describe('comment events', () => {
    it('asks for events from the server time on and passes valid ones on', async () => {
      const { service, connection } = setup();
      const events: CommentEvent[] = [];
      service.watchCommentEvents('a1', (event) => events.push(event));
      await flush();

      const [listener] = connection.children;
      expect(listener).toMatchObject({ path: 'live/articles/a1/events', orderBy: 'at', since: connection.serverNow });

      listener.next('-Nx1', { type: 'reply.created', commentId: 'c2', parentId: 'c1', at: connection.serverNow + 5 });
      listener.next('-Nx2', { type: 'comment.exploded', commentId: 'c3', at: 1 });
      listener.next('-Nx3', { type: 'comment.created', at: 1 });

      expect(events).toEqual([{ id: '-Nx1', type: 'reply.created', commentId: 'c2', parentId: 'c1', at: connection.serverNow + 5 }]);
    });
  });

  describe('feed', () => {
    it('reads the latest publish time as epoch ms', async () => {
      const { service, connection } = setup();
      const seen: (number | null)[] = [];
      service.watchLatestPublished((at) => seen.push(at));
      await flush();

      connection.emit('live/feed/latestPublishedAt', 1_700_000_000_123);
      connection.emit('live/feed/latestPublishedAt', '2026-11-03T08:00:00Z');
      connection.emit('live/feed/latestPublishedAt', null);
      expect(seen).toEqual([1_700_000_000_123, Date.parse('2026-11-03T08:00:00Z'), null]);
    });
  });

  describe('unread badge', () => {
    it('signs in with a custom token and follows the user once signed in to ReadIn', async () => {
      const { service, session, connection, api } = setup();
      service.init();
      TestBed.tick();
      expect(api.token).not.toHaveBeenCalled();

      signIn(session);
      TestBed.tick();
      await flush();

      expect(connection.signIn).toHaveBeenCalledWith('custom-token');
      expect(connection.listenerCount('live/users/user-1/unreadNotifications')).toBe(1);
      connection.emit('live/users/user-1/unreadNotifications', 4);
      expect(service.unreadNotifications()).toBe(4);
    });

    it('stops, clears the badge and signs out of Firebase when the user signs out', async () => {
      const { service, session, connection } = setup();
      service.init();
      signIn(session);
      TestBed.tick();
      await flush();
      connection.emit('live/users/user-1/unreadNotifications', 2);

      session.setGuest();
      TestBed.tick();
      await flush();

      expect(service.unreadNotifications()).toBe(0);
      expect(connection.listenerCount('live/users/user-1/unreadNotifications')).toBe(0);
      expect(connection.signOut).toHaveBeenCalled();
    });

    it('does not re-authenticate when only the profile changes', async () => {
      const { service, session, api } = setup();
      service.init();
      signIn(session);
      TestBed.tick();
      await flush();

      session.patchMe({ displayName: 'Mona A.' });
      TestBed.tick();
      await flush();
      expect(api.token).toHaveBeenCalledTimes(1);
    });

    it('says when the badge is live, and clears it at once when the center opens (F17)', async () => {
      const { service, session, connection } = setup();
      service.init();
      signIn(session);
      TestBed.tick();
      await flush();
      expect(service.unreadLive()).toBe(false); // nothing from the database yet: the REST fallback counts

      connection.emit('live/users/user-1/unreadNotifications', 3);
      expect(service.unreadLive()).toBe(true);
      service.clearUnreadNotifications();
      expect(service.unreadNotifications()).toBe(0);
      connection.emit('live/users/user-1/unreadNotifications', 1); // something new after "seen"
      expect(service.unreadNotifications()).toBe(1);

      session.setGuest();
      TestBed.tick();
      expect(service.unreadLive()).toBe(false);
    });

    it('keeps the badge at 0 when no token can be issued', async () => {
      const { service, session, connection } = setup({ token: () => throwError(() => new Error('404')) });
      service.init();
      signIn(session);
      TestBed.tick();
      await flush();

      expect(connection.signIn).not.toHaveBeenCalled();
      expect(connection.listenerCount('live/users/user-1/unreadNotifications')).toBe(0);
      expect(service.unreadNotifications()).toBe(0);
      expect(service.unreadLive()).toBe(false); // so the badge comes from GET /me/notifications/unread-count
    });
  });

  it('falls back to REST only when the SDK cannot load', async () => {
    const { service } = setup({ connection: null });
    const next = vi.fn();
    service.watchArticle('a1', next);
    await flush();
    expect(service.state()).toBe('disconnected');
    expect(next).not.toHaveBeenCalled();
  });

  it('never connects during SSR', async () => {
    const { service, session, connector } = setup({ platform: 'server' });
    service.init();
    signIn(session);
    service.watchArticle('a1', () => undefined);
    await flush();
    expect(connector).not.toHaveBeenCalled();
  });
});

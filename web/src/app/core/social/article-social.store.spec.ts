import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { testMe } from '../../../testing/auth-testing';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { ArticleReactionsDto, ReactionCountsDto } from '../api/models';
import { SessionStore } from '../auth/session.store';
import { LiveArticleCounts } from '../realtime/realtime.service';
import { ArticleSocialStore } from './article-social.store';

const REACTION_URL = `${TEST_API}/articles/a1/reaction`;
const SAVE_URL = `${TEST_API}/me/saved/a1`;
const REPOST_URL = `${TEST_API}/articles/a1/repost`;

function result(reactions: ReactionCountsDto, myReaction: ArticleReactionsDto['myReaction']): ArticleReactionsDto {
  return { reactions, total: Object.values(reactions).reduce((a, b) => a + b, 0), myReaction };
}

function live(patch: Partial<LiveArticleCounts>): LiveArticleCounts {
  return { reactions: null, reactionCount: null, commentCount: null, saveCount: null, ...patch };
}

describe('ArticleSocialStore (F10, F13, F27, F29)', () => {
  let http: HttpTestingController;
  let store: ArticleSocialStore;
  let toasts: ToastService;
  const article = testCard();

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http, toasts } = setupSocialTesting());
    store = TestBed.inject(ArticleSocialStore);
    TestBed.tick();
  });

  afterEach(() => http.verify());

  it('shows the DTO values until something changes', () => {
    expect(store.state(article)).toEqual({
      reactions: { insightful: 6, love: 3, fire: 2, mindBlown: 1 },
      reactionCount: 12,
      myReaction: null,
      isSaved: false,
      saveCount: 4,
      commentCount: 3,
      repostCount: 0,
      isReposted: false,
    });
  });

  it('a tap reacts 💡 at once, then takes the counts the server confirms', async () => {
    const done = store.tap(article);
    expect(store.state(article).myReaction).toBe('insightful');
    expect(store.state(article).reactions.insightful).toBe(7);
    expect(store.state(article).reactionCount).toBe(13);

    const req = http.expectOne(REACTION_URL);
    expect(req.request.method).toBe('PUT');
    expect(req.request.body).toEqual({ type: 'insightful' });
    req.flush(result({ insightful: 8, love: 3, fire: 2, mindBlown: 1 }, 'insightful')); // someone else reacted too
    await done;

    expect(store.state(article).reactions.insightful).toBe(8);
    expect(store.state(article).reactionCount).toBe(14);
  });

  it('tapping your reaction removes it; picking another one moves it', async () => {
    const mine = testCard({ myReaction: 'love', reactions: { insightful: 6, love: 4, fire: 2, mindBlown: 1 }, reactionCount: 13 });

    const pick = store.pick(mine, 'fire');
    expect(store.state(mine).reactions).toEqual({ insightful: 6, love: 3, fire: 3, mindBlown: 1 });
    expect(store.state(mine).reactionCount).toBe(13);
    http.expectOne(REACTION_URL).flush(result({ insightful: 6, love: 3, fire: 3, mindBlown: 1 }, 'fire'));
    await pick;

    const tap = store.tap(mine);
    expect(store.state(mine).myReaction).toBeNull();
    expect(store.state(mine).reactionCount).toBe(12);
    const req = http.expectOne(REACTION_URL);
    expect(req.request.method).toBe('DELETE');
    req.flush(result({ insightful: 6, love: 3, fire: 2, mindBlown: 1 }, null));
    await tap;
    expect(store.state(mine).myReaction).toBeNull();
  });

  it('rolls back and shows the translated error when the API refuses', async () => {
    const done = store.pick(article, 'mindBlown');
    expect(store.state(article).myReaction).toBe('mindBlown');
    http.expectOne(REACTION_URL).flush(problem(404, 'article.not_found'), { status: 404, statusText: 'Not Found' });
    await done;

    expect(store.state(article)).toEqual(expect.objectContaining({ myReaction: null, reactionCount: 12, reactions: { insightful: 6, love: 3, fire: 2, mindBlown: 1 } }));
    expect(toasts.toasts().map((t) => t.message)).toEqual(['المقال ده مش موجود']);
  });

  it('quick taps coalesce: one request at a time, then the latest wish', async () => {
    const first = store.tap(article); // 💡
    const second = store.pick(article, 'love'); // changed while the first is on its way
    const third = store.pick(article, 'fire');
    expect(store.state(article).myReaction).toBe('fire');
    expect(store.state(article).reactions).toEqual({ insightful: 6, love: 3, fire: 3, mindBlown: 1 });

    const one = http.expectOne(REACTION_URL);
    expect(one.request.body).toEqual({ type: 'insightful' });
    one.flush(result({ insightful: 7, love: 3, fire: 2, mindBlown: 1 }, 'insightful'));
    await flushMicrotasks();
    // The confirmed 💡 is shown as moved to 🔥, the wish still on its way.
    expect(store.state(article).reactions).toEqual({ insightful: 6, love: 3, fire: 3, mindBlown: 1 });

    const two = http.expectOne(REACTION_URL);
    expect(two.request.body).toEqual({ type: 'fire' });
    two.flush(result({ insightful: 6, love: 3, fire: 3, mindBlown: 1 }, 'fire'));
    await Promise.all([first, second, third]);
    expect(store.state(article).myReaction).toBe('fire');
    http.expectNone(REACTION_URL);
  });

  it('a failed request with a newer wish waiting sends the newer one instead of rolling back', async () => {
    void store.tap(article);
    void store.pick(article, 'love');
    http.expectOne(REACTION_URL).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await flushMicrotasks();
    const retry = http.expectOne(REACTION_URL);
    expect(retry.request.body).toEqual({ type: 'love' });
    retry.flush(result({ insightful: 6, love: 4, fire: 2, mindBlown: 1 }, 'love'));
    await flushMicrotasks();
    expect(store.state(article).myReaction).toBe('love');
    expect(toasts.toasts()).toEqual([]);
  });

  it("takes the server's answer when it differs from what was sent, and sends nothing more", async () => {
    const done = store.tap(article);
    http.expectOne(REACTION_URL).flush(result({ insightful: 6, love: 4, fire: 2, mindBlown: 1 }, 'love')); // e.g. another tab
    await done;
    expect(store.state(article)).toEqual(expect.objectContaining({ myReaction: 'love', reactionCount: 13 }));
    expect(store.state(article).reactions.love).toBe(4);
    http.expectNone(REACTION_URL);
  });

  describe('live counters (F27)', () => {
    it('replace the counts, never add to them', () => {
      store.applyLive(article, live({ reactions: { insightful: 9, love: 3, fire: 2, mindBlown: 1 }, commentCount: 5, saveCount: 7 }));
      expect(store.state(article)).toEqual(expect.objectContaining({ reactionCount: 15, commentCount: 5, saveCount: 7 }));
      expect(store.state(article).reactions.insightful).toBe(9);
    });

    it("don't count your own reaction twice when its echo arrives", async () => {
      const done = store.tap(article);
      http.expectOne(REACTION_URL).flush(result({ insightful: 7, love: 3, fire: 2, mindBlown: 1 }, 'insightful'));
      await done;

      // The publisher recomputed the counters after the commit: the same numbers come back.
      store.applyLive(article, live({ reactions: { insightful: 7, love: 3, fire: 2, mindBlown: 1 } }));
      expect(store.state(article).reactionCount).toBe(13);
      expect(store.state(article).myReaction).toBe('insightful');
    });

    it('an echo of what the server already said keeps an optimistic reaction that is still on its way', () => {
      void store.tap(article);
      store.applyLive(article, live({ reactions: { insightful: 6, love: 3, fire: 2, mindBlown: 1 }, commentCount: 3 }));
      expect(store.state(article).reactions.insightful).toBe(7);
      http.expectOne(REACTION_URL);
    });

    it('fields arrive one at a time; each replaces only itself', () => {
      void store.toggleSave(article);
      store.applyLive(article, live({ commentCount: 8 }));
      expect(store.state(article)).toEqual(expect.objectContaining({ commentCount: 8, isSaved: true, saveCount: 5 }));
      http.expectOne(SAVE_URL);
    });
  });

  describe('save (F13)', () => {
    it('toggles at once and keeps the confirmed count', async () => {
      const done = store.toggleSave(article);
      expect(store.state(article)).toEqual(expect.objectContaining({ isSaved: true, saveCount: 5 }));
      const req = http.expectOne(SAVE_URL);
      expect(req.request.method).toBe('PUT');
      req.flush({ isSaved: true, saveCount: 6 });
      await done;
      expect(store.state(article)).toEqual(expect.objectContaining({ isSaved: true, saveCount: 6 }));
    });

    it('announces confirmed unsaves (they also leave every collection)', async () => {
      const saved = testCard({ isSaved: true, saveCount: 5 });
      const unsaved: string[] = [];
      store.unsaved$.subscribe((id) => unsaved.push(id));
      const done = store.toggleSave(saved);
      http.expectOne(SAVE_URL).flush({ isSaved: false, saveCount: 4 });
      await done;
      expect(unsaved).toEqual(['a1']);
    });

    it('rolls back on failure', async () => {
      const done = store.toggleSave(article);
      http.expectOne(SAVE_URL).error(new ProgressEvent('error'));
      await done;
      expect(store.state(article)).toEqual(expect.objectContaining({ isSaved: false, saveCount: 4 }));
      expect(toasts.toasts()[0].kind).toBe('error');
    });
  });

  describe('repost (F29)', () => {
    const reposts = testCard({ repostCount: 3, isReposted: false });

    it('toggles at once and keeps the count the server confirms', async () => {
      const done = store.toggleRepost(reposts);
      expect(store.state(reposts)).toEqual(expect.objectContaining({ isReposted: true, repostCount: 4 }));
      const req = http.expectOne(REPOST_URL);
      expect(req.request.method).toBe('PUT');
      req.flush({ repostCount: 5, isReposted: true }); // someone else reposted too
      await done;
      expect(store.state(reposts)).toEqual(expect.objectContaining({ isReposted: true, repostCount: 5 }));

      const undo = store.toggleRepost(reposts);
      expect(store.state(reposts)).toEqual(expect.objectContaining({ isReposted: false, repostCount: 4 }));
      const del = http.expectOne(REPOST_URL);
      expect(del.request.method).toBe('DELETE');
      del.flush({ repostCount: 4, isReposted: false });
      await undo;
      expect(store.state(reposts)).toEqual(expect.objectContaining({ isReposted: false, repostCount: 4 }));
    });

    it('rolls back with the translated error (your own article: repost.own_article)', async () => {
      const done = store.toggleRepost(reposts);
      http.expectOne(REPOST_URL).flush(problem(400, 'repost.own_article'), { status: 400, statusText: 'Bad Request' });
      await done;
      expect(store.state(reposts)).toEqual(expect.objectContaining({ isReposted: false, repostCount: 3 }));
      expect(toasts.toasts().map((t) => t.message)).toEqual(['مينفعش تعيد نشر مقالك.']);
    });

    it('quick taps coalesce into the latest wish: back where it started sends nothing more', async () => {
      const first = store.toggleRepost(reposts);
      void store.toggleRepost(reposts);
      expect(store.state(reposts)).toEqual(expect.objectContaining({ isReposted: false, repostCount: 3 }));
      http.expectOne(REPOST_URL).flush({ repostCount: 4, isReposted: true });
      await flushMicrotasks();
      const undo = http.expectOne(REPOST_URL);
      expect(undo.request.method).toBe('DELETE');
      undo.flush({ repostCount: 3, isReposted: false });
      await first;
      expect(store.state(reposts)).toEqual(expect.objectContaining({ isReposted: false, repostCount: 3 }));
      http.expectNone(REPOST_URL);
    });

    it('the live repostCount replaces the number, never adds to it', async () => {
      const done = store.toggleRepost(reposts);
      http.expectOne(REPOST_URL).flush({ repostCount: 4, isReposted: true });
      await done;
      store.applyLive(reposts, live({ repostCount: 4 })); // the echo of your own repost
      expect(store.state(reposts).repostCount).toBe(4);
      store.applyLive(reposts, live({ repostCount: 9 }));
      expect(store.state(reposts)).toEqual(expect.objectContaining({ repostCount: 9, isReposted: true }));
    });

    it('cards from an API older than F29 count 0 and are not reposted', () => {
      const old = testCard();
      delete old.repostCount;
      delete old.isReposted;
      expect(store.state(old)).toEqual(expect.objectContaining({ repostCount: 0, isReposted: false }));
    });
  });

  it('a fresh copy from the API replaces local state, unless an action is on its way', async () => {
    store.applyLive(article, live({ commentCount: 9 }));
    store.absorb([testCard({ commentCount: 10, isSaved: true, saveCount: 5 })]);
    expect(store.state(article)).toEqual(expect.objectContaining({ commentCount: 10, isSaved: true }));

    void store.tap(article);
    store.absorb([testCard()]);
    expect(store.state(article).myReaction).toBe('insightful');
    http.expectOne(REACTION_URL).flush(result({ insightful: 7, love: 3, fire: 2, mindBlown: 1 }, 'insightful'));
    await flushMicrotasks();
  });

  it('forgets personal state when the account changes', () => {
    store.applyLive(article, live({ commentCount: 9 }));
    void store.toggleSave(article);
    http.expectOne(SAVE_URL);
    TestBed.inject(SessionStore).setMe(testMe({ id: 'user-2' }));
    TestBed.tick();
    expect(store.state(article)).toEqual(expect.objectContaining({ isSaved: false, commentCount: 3 }));
  });
});

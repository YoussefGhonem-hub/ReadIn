import { Injectable, computed, effect, inject, signal, untracked } from '@angular/core';
import { Observable, Subject, firstValueFrom } from 'rxjs';
import { ArticleCardDto, ArticleReactionsDto, REACTION_TYPES, ReactionCountsDto, ReactionType, RepostStateDto, SaveStateDto } from '../api/models';
import { ReactionsApi } from '../api/reactions.api';
import { RepostsApi } from '../api/reposts.api';
import { SavedApi } from '../api/saved.api';
import { SessionStore } from '../auth/session.store';
import { ErrorMessages } from '../i18n/error-messages';
import { LiveArticleCounts } from '../realtime/realtime.service';
import { ToastService } from '../../shared/ui/toast/toast.service';

/** What the UI shows about an article's reactions, saves, comments and reposts (F10, F13, F27, F29). */
export interface ArticleSocialState {
  reactions: ReactionCountsDto;
  reactionCount: number;
  myReaction: ReactionType | null;
  isSaved: boolean;
  saveCount: number;
  commentCount: number;
  repostCount: number;
  isReposted: boolean;
}

interface Entry {
  /** The last values the server confirmed: REST responses and live counters. */
  server: ArticleSocialState;
  /** What the UI shows: `server` plus the user's actions that are still on their way. */
  view: ArticleSocialState;
}

type Channel = 'reaction' | 'save' | 'repost';
const CHANNELS: readonly Channel[] = ['reaction', 'save', 'repost'];

const ZERO: ReactionCountsDto = { insightful: 0, love: 0, fire: 0, mindBlown: 0 };

export function sumReactions(reactions: ReactionCountsDto): number {
  return REACTION_TYPES.reduce((sum, type) => sum + (reactions[type] ?? 0), 0);
}

export function socialStateOf(article: ArticleCardDto): ArticleSocialState {
  const reactions = { ...ZERO, ...article.reactions };
  return {
    reactions,
    reactionCount: article.reactionCount ?? sumReactions(reactions),
    myReaction: article.myReaction ?? null,
    isSaved: !!article.isSaved,
    saveCount: article.saveCount ?? 0,
    commentCount: article.commentCount ?? 0,
    repostCount: article.repostCount ?? 0,
    isReposted: !!article.isReposted,
  };
}

/** Moves the viewer's reaction from `from` to `to` in a copy of the counts (never below zero). */
function moveReaction(state: ArticleSocialState, from: ReactionType | null, to: ReactionType | null): Pick<ArticleSocialState, 'reactions' | 'reactionCount'> {
  if (from === to) return { reactions: state.reactions, reactionCount: state.reactionCount };
  const reactions = { ...state.reactions };
  let reactionCount = state.reactionCount;
  if (from) {
    reactions[from] = Math.max(0, reactions[from] - 1);
    reactionCount = Math.max(0, reactionCount - 1);
  }
  if (to) {
    reactions[to] += 1;
    reactionCount += 1;
  }
  return { reactions, reactionCount };
}

function sameReactions(a: ReactionCountsDto, b: ReactionCountsDto): boolean {
  return REACTION_TYPES.every((type) => a[type] === b[type]);
}

/**
 * Reactions, saves and reposts (F29) of the articles on screen, shared by feed cards, the reader and the Saved page, so
 * an action in one place shows everywhere. Actions are optimistic: the UI changes at once, one request per article and
 * kind runs at a time (quick taps coalesce into the latest wish), and a failure rolls back to what the server last
 * confirmed and shows the translated error. Live counters (F27) **replace** the numbers, never add to them, so the
 * user's own action is never counted twice.
 */
@Injectable({ providedIn: 'root' })
export class ArticleSocialStore {
  private readonly reactionsApi = inject(ReactionsApi);
  private readonly savedApi = inject(SavedApi);
  private readonly repostsApi = inject(RepostsApi);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly session = inject(SessionStore);

  private readonly entries = signal<ReadonlyMap<string, Entry>>(new Map());
  /** Your repost's caption per article, as the server last answered it (F29); absent when not known here. */
  private readonly captions = signal<ReadonlyMap<string, string | null>>(new Map());
  private readonly inFlight = new Set<string>();
  private readonly unsavedSubject = new Subject<string>();

  /** Ids of articles the server confirmed as unsaved (they also left every collection). */
  readonly unsaved$: Observable<string> = this.unsavedSubject.asObservable();

  constructor() {
    // Personal state belongs to one account: drop it when the user signs out or switches accounts.
    const userId = computed(() => (this.session.isAuthenticated() ? (this.session.me()?.id ?? null) : null));
    let previous: string | null | undefined;
    effect(() => {
      const current = userId();
      if (previous !== undefined && previous !== current) {
        untracked(() => {
          this.entries.set(new Map());
          this.captions.set(new Map());
        });
      }
      previous = current;
    });
  }

  /** The state to show for `article`: its DTO values, with the user's actions and live counters on top. */
  state(article: ArticleCardDto): ArticleSocialState {
    return this.entries().get(article.id)?.view ?? socialStateOf(article);
  }

  /**
   * Your repost's caption (F29) as the server last answered it in this session (a repost, an edit, an undo or the
   * dialog's `GET`): `null` for none, `undefined` when nothing here knows it yet.
   */
  myCaption(articleId: string): string | null | undefined {
    const captions = this.captions();
    return captions.has(articleId) ? (captions.get(articleId) ?? null) : undefined;
  }

  /** Fresh copies from the API replace local state, except while one of the user's actions is still on its way. */
  absorb(articles: readonly ArticleCardDto[]): void {
    const current = this.entries();
    const stale = articles.filter((a) => current.has(a.id) && !this.busy(a.id));
    if (!stale.length) return;
    const next = new Map(current);
    for (const article of stale) {
      const fresh = socialStateOf(article);
      next.set(article.id, { server: fresh, view: fresh });
    }
    this.entries.set(next);
  }

  /** The reaction button: 💡 when you haven't reacted; removes your reaction when you have. */
  tap(article: ArticleCardDto): Promise<void> {
    return this.setReaction(article, this.state(article).myReaction ? null : 'insightful');
  }

  /** The picker: picks `type`, or removes it when it is already your reaction. */
  pick(article: ArticleCardDto, type: ReactionType): Promise<void> {
    return this.setReaction(article, this.state(article).myReaction === type ? null : type);
  }

  setReaction(article: ArticleCardDto, type: ReactionType | null): Promise<void> {
    const { view } = this.ensure(article);
    if (view.myReaction === type) return Promise.resolve();
    this.patch(article.id, (entry) => ({ ...entry, view: { ...view, ...moveReaction(view, view.myReaction, type), myReaction: type } }));
    return this.syncReaction(article.id);
  }

  toggleSave(article: ArticleCardDto): Promise<void> {
    return this.setSaved(article, !this.state(article).isSaved);
  }

  setSaved(article: ArticleCardDto, isSaved: boolean): Promise<void> {
    const { view } = this.ensure(article);
    if (view.isSaved === isSaved) return Promise.resolve();
    this.patch(article.id, (entry) => ({ ...entry, view: { ...view, isSaved, saveCount: Math.max(0, view.saveCount + (isSaved ? 1 : -1)) } }));
    return this.syncSave(article.id);
  }

  /** The Repost button (F29): reposts, or undoes your repost. */
  toggleRepost(article: ArticleCardDto): Promise<void> {
    return this.setReposted(article, !this.state(article).isReposted);
  }

  setReposted(article: ArticleCardDto, isReposted: boolean): Promise<void> {
    const { view } = this.ensure(article);
    if (view.isReposted === isReposted) return Promise.resolve();
    this.patch(article.id, (entry) => ({ ...entry, view: { ...view, isReposted, repostCount: Math.max(0, view.repostCount + (isReposted ? 1 : -1)) } }));
    return this.syncRepost(article.id);
  }

  /**
   * The caption dialog (F29): reposts with your thoughts, or only sets them when you already reposted (`""` clears
   * them). Not optimistic: the dialog waits for the answer and stays open on an error, which this rethrows (no toast);
   * once the server confirms, the new state and count show everywhere.
   */
  async repostWithCaption(article: ArticleCardDto, caption: string): Promise<RepostStateDto> {
    this.ensure(article);
    const result = await firstValueFrom(this.repostsApi.repost(article.id, caption));
    this.applyRepost(article, result);
    return result;
  }

  /** Your repost as the server answered it (the dialog's `GET`, or saved thoughts): its state, count and caption. */
  applyRepost(article: ArticleCardDto, result: RepostStateDto): void {
    this.ensure(article);
    // A toggle still on its way keeps its wish on screen; its own answer settles the rest.
    const toggling = this.busy(article.id, 'repost');
    this.patch(article.id, (entry) => {
      const server = { ...entry.server, isReposted: result.isReposted, repostCount: result.repostCount };
      return { server, view: toggling ? entry.view : { ...entry.view, isReposted: server.isReposted, repostCount: server.repostCount } };
    });
    this.rememberCaption(article.id, result);
  }

  /** Adding to a collection saves the article first if needed (server side). */
  confirmSaved(article: ArticleCardDto): void {
    const { server } = this.ensure(article);
    if (server.isSaved || this.busy(article.id, 'save')) return;
    const saved = { isSaved: true, saveCount: server.saveCount + 1 };
    this.patch(article.id, (entry) => ({ server: { ...entry.server, ...saved }, view: { ...entry.view, ...saved } }));
  }

  /**
   * Live counters (F27) replace the counts the server last confirmed, field by field, and only when they differ, so
   * an echo of what the UI already shows changes nothing and the user's own action is never counted twice.
   */
  applyLive(article: ArticleCardDto, live: LiveArticleCounts): void {
    const base = this.entries().get(article.id)?.server ?? socialStateOf(article);
    const changes: Partial<ArticleSocialState> = {};
    if (live.reactions && !sameReactions(live.reactions, base.reactions)) {
      changes.reactions = { ...live.reactions };
      changes.reactionCount = sumReactions(live.reactions);
    }
    if (live.commentCount !== null && live.commentCount !== base.commentCount) changes.commentCount = live.commentCount;
    if (live.saveCount !== null && live.saveCount !== base.saveCount) changes.saveCount = live.saveCount;
    if (live.repostCount != null && live.repostCount !== base.repostCount) changes.repostCount = live.repostCount;
    if (!Object.keys(changes).length) return;
    this.ensure(article);
    this.patch(article.id, (entry) => ({ server: { ...entry.server, ...changes }, view: { ...entry.view, ...changes } }));
  }

  /** True while a request of `channel` (or any) is running for the article. */
  busy(articleId: string, channel?: Channel): boolean {
    return channel ? this.inFlight.has(`${channel}:${articleId}`) : CHANNELS.some((c) => this.inFlight.has(`${c}:${articleId}`));
  }

  private async syncReaction(id: string): Promise<void> {
    const key = `reaction:${id}`;
    if (this.inFlight.has(key)) return; // the running loop sends the newest wish when its request ends
    this.inFlight.add(key);
    try {
      for (;;) {
        const entry = this.entries().get(id);
        if (!entry) return;
        const target = entry.view.myReaction;
        if (target === entry.server.myReaction) {
          this.patch(id, (e) => ({ ...e, view: { ...e.view, reactions: e.server.reactions, reactionCount: e.server.reactionCount } }));
          return;
        }
        try {
          const result = await firstValueFrom(target ? this.reactionsApi.react(id, target) : this.reactionsApi.unreact(id));
          this.confirmReactions(id, result, target);
        } catch (error) {
          if (this.entries().get(id)?.view.myReaction !== target) continue; // a newer wish replaces this one
          this.patch(id, (e) => ({
            ...e,
            view: { ...e.view, reactions: e.server.reactions, reactionCount: e.server.reactionCount, myReaction: e.server.myReaction },
          }));
          this.toasts.error(this.errors.forError(error));
          return;
        }
      }
    } finally {
      this.inFlight.delete(key);
    }
  }

  /** `sent` is the wish the request carried: the server's answer wins over it, a newer wish stays on top. */
  private confirmReactions(id: string, result: ArticleReactionsDto, sent: ReactionType | null): void {
    this.patch(id, (entry) => {
      const server: ArticleSocialState = {
        ...entry.server,
        reactions: { ...ZERO, ...result.reactions },
        reactionCount: result.total,
        myReaction: result.myReaction,
      };
      const wish = entry.view.myReaction === sent ? server.myReaction : entry.view.myReaction;
      return { server, view: { ...entry.view, ...moveReaction(server, server.myReaction, wish), myReaction: wish } };
    });
  }

  private async syncSave(id: string): Promise<void> {
    const key = `save:${id}`;
    if (this.inFlight.has(key)) return;
    this.inFlight.add(key);
    try {
      for (;;) {
        const entry = this.entries().get(id);
        if (!entry) return;
        const target = entry.view.isSaved;
        if (target === entry.server.isSaved) {
          this.patch(id, (e) => ({ ...e, view: { ...e.view, saveCount: e.server.saveCount } }));
          return;
        }
        try {
          const result = await firstValueFrom(target ? this.savedApi.save(id) : this.savedApi.unsave(id));
          this.confirmSave(id, result, target);
          if (!result.isSaved) this.unsavedSubject.next(id);
        } catch (error) {
          if (this.entries().get(id)?.view.isSaved !== target) continue;
          this.patch(id, (e) => ({ ...e, view: { ...e.view, isSaved: e.server.isSaved, saveCount: e.server.saveCount } }));
          this.toasts.error(this.errors.forError(error));
          return;
        }
      }
    } finally {
      this.inFlight.delete(key);
    }
  }

  private confirmSave(id: string, result: SaveStateDto, sent: boolean): void {
    this.patch(id, (entry) => {
      const server = { ...entry.server, isSaved: result.isSaved, saveCount: result.saveCount };
      const isSaved = entry.view.isSaved === sent ? server.isSaved : entry.view.isSaved;
      const pending = isSaved === server.isSaved ? 0 : isSaved ? 1 : -1;
      return { server, view: { ...entry.view, isSaved, saveCount: Math.max(0, server.saveCount + pending) } };
    });
  }

  /** Like saves: one request at a time, the newest wish wins, a failure rolls back to the server's state with the error. */
  private async syncRepost(id: string): Promise<void> {
    const key = `repost:${id}`;
    if (this.inFlight.has(key)) return;
    this.inFlight.add(key);
    try {
      for (;;) {
        const entry = this.entries().get(id);
        if (!entry) return;
        const target = entry.view.isReposted;
        if (target === entry.server.isReposted) {
          this.patch(id, (e) => ({ ...e, view: { ...e.view, repostCount: e.server.repostCount } }));
          return;
        }
        try {
          const result = await firstValueFrom(target ? this.repostsApi.repost(id) : this.repostsApi.unrepost(id));
          this.confirmRepost(id, result, target);
        } catch (error) {
          if (this.entries().get(id)?.view.isReposted !== target) continue;
          this.patch(id, (e) => ({ ...e, view: { ...e.view, isReposted: e.server.isReposted, repostCount: e.server.repostCount } }));
          this.toasts.error(this.errors.forError(error));
          return;
        }
      }
    } finally {
      this.inFlight.delete(key);
    }
  }

  private confirmRepost(id: string, result: RepostStateDto, sent: boolean): void {
    this.patch(id, (entry) => {
      const server = { ...entry.server, isReposted: result.isReposted, repostCount: result.repostCount };
      const isReposted = entry.view.isReposted === sent ? server.isReposted : entry.view.isReposted;
      const pending = isReposted === server.isReposted ? 0 : isReposted ? 1 : -1;
      return { server, view: { ...entry.view, isReposted, repostCount: Math.max(0, server.repostCount + pending) } };
    });
    this.rememberCaption(id, result);
  }

  /** An answer from an API older than repost captions has none: what was known stays. */
  private rememberCaption(id: string, result: RepostStateDto): void {
    if (result.caption === undefined) return;
    this.captions.update((map) => new Map(map).set(id, result.caption ?? null));
  }

  private ensure(article: ArticleCardDto): Entry {
    const existing = this.entries().get(article.id);
    if (existing) return existing;
    const state = socialStateOf(article);
    const entry = { server: state, view: state };
    this.entries.update((map) => new Map(map).set(article.id, entry));
    return entry;
  }

  private patch(id: string, update: (entry: Entry) => Entry): void {
    const entry = this.entries().get(id);
    if (entry) this.entries.update((map) => new Map(map).set(id, update(entry)));
  }
}

import { DestroyRef, Injectable, computed, effect, inject, signal, untracked } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { firstValueFrom } from 'rxjs';
import { ArticleCardDto, CollectionDto, SavedArticleDto } from '../api/models';
import { SavedApi } from '../api/saved.api';
import { SessionStore } from '../auth/session.store';
import { ErrorMessages } from '../i18n/error-messages';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { ArticleSocialStore } from './article-social.store';

export type CollectionsStatus = 'idle' | 'loading' | 'loaded' | 'error';

/** 1–60 characters after trimming (contract: `POST /me/collections`). */
export const COLLECTION_NAME_MAX = 60;

const byName = new Intl.Collator(undefined, { sensitivity: 'base', numeric: true });

function sorted(list: CollectionDto[]): CollectionDto[] {
  return [...list].sort((a, b) => byName.compare(a.name, b.name));
}

/**
 * The signed-in user's collections (F13) and which saved articles are in which, shared by the Saved page and the
 * "add to collection" sheet. Membership comes from the API (`SavedArticleDto.collectionIds` on the Saved list,
 * `ArticleDetailsDto.collectionIds` in the reader) and from changes made in this session.
 */
@Injectable({ providedIn: 'root' })
export class CollectionsStore {
  private readonly api = inject(SavedApi);
  private readonly social = inject(ArticleSocialStore);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly session = inject(SessionStore);

  private readonly _collections = signal<CollectionDto[]>([]);
  private readonly _status = signal<CollectionsStatus>('idle');
  private readonly membership = signal<ReadonlyMap<string, ReadonlySet<string>>>(new Map());
  private readonly pending = new Map<string, number>();
  private loading: Promise<void> | null = null;

  readonly collections = this._collections.asReadonly();
  readonly status = this._status.asReadonly();

  constructor() {
    const userId = computed(() => (this.session.isAuthenticated() ? (this.session.me()?.id ?? null) : null));
    let previous: string | null | undefined;
    effect(() => {
      const current = userId();
      if (previous !== undefined && previous !== current) untracked(() => this.reset());
      previous = current;
    });
    // Unsaving removes the article from every collection (server side).
    this.social.unsaved$.pipe(takeUntilDestroyed(inject(DestroyRef))).subscribe((articleId) => this.forgetArticle(articleId));
  }

  /** Loads the list once (again with `force`). Errors leave `status` at `error`. */
  load(force = false): Promise<void> {
    if (this.loading) return this.loading;
    if (!force && this._status() === 'loaded') return Promise.resolve();
    this._status.set('loading');
    this.loading = firstValueFrom(this.api.collections())
      .then(
        (list) => {
          this._collections.set(sorted(list));
          this._status.set('loaded');
        },
        () => this._status.set('error'),
      )
      .finally(() => (this.loading = null));
    return this.loading;
  }

  /** The collections `articleId` is in, or null when unknown (no API copy seen in this session). */
  collectionsOf(articleId: string): ReadonlySet<string> | null {
    return this.membership().get(articleId) ?? null;
  }

  /** Learns membership from a page of `GET /me/saved`. */
  learn(items: readonly SavedArticleDto[]): void {
    this.learnMany(items.map((item) => [item.article.id, item.collectionIds]));
  }

  /** Learns one article's membership (`ArticleDetailsDto.collectionIds`), unless a change to it is on its way. */
  learnArticle(articleId: string, collectionIds: readonly string[] | null | undefined): void {
    if (collectionIds) this.learnMany([[articleId, collectionIds]]);
  }

  private learnMany(entries: readonly (readonly [string, readonly string[]])[]): void {
    const fresh = entries.filter(([articleId]) => !this.pending.has(articleId));
    if (!fresh.length) return;
    const next = new Map(this.membership());
    for (const [articleId, ids] of fresh) next.set(articleId, new Set(ids));
    this.membership.set(next);
  }

  /** Throws the ApiError (`collection.name_taken`, `collection.limit`, validation) for the form to show. */
  async create(name: string): Promise<CollectionDto> {
    const created = await firstValueFrom(this.api.createCollection(name.trim()));
    this._collections.update((list) => sorted([...list.filter((c) => c.id !== created.id), created]));
    return created;
  }

  /** Throws the ApiError for the form to show. */
  async rename(id: string, name: string): Promise<CollectionDto> {
    const renamed = await firstValueFrom(this.api.renameCollection(id, name.trim()));
    this._collections.update((list) => sorted(list.map((c) => (c.id === id ? renamed : c))));
    return renamed;
  }

  /** Throws the ApiError for the dialog to show. The articles stay saved. */
  async remove(id: string): Promise<void> {
    await firstValueFrom(this.api.deleteCollection(id));
    this._collections.update((list) => list.filter((c) => c.id !== id));
    this.membership.update((map) => new Map([...map].map(([articleId, ids]) => [articleId, new Set([...ids].filter((c) => c !== id))])));
  }

  /** Optimistic; rolls back and shows the error on failure. The API saves the article first if needed. */
  async addArticle(collectionId: string, article: ArticleCardDto): Promise<boolean> {
    if (this.collectionsOf(article.id)?.has(collectionId)) return true;
    const before = this.collectionsOf(article.id);
    const delta = this.setMembership(article.id, collectionId, true);
    this.track(article.id, 1);
    try {
      await firstValueFrom(this.api.addToCollection(collectionId, article.id));
      this.social.confirmSaved(article);
      return true;
    } catch (error) {
      this.restore(article.id, collectionId, before, delta);
      this.toasts.error(this.errors.forError(error));
      return false;
    } finally {
      this.track(article.id, -1);
    }
  }

  /** Optimistic; rolls back and shows the error on failure. The article stays saved. */
  async removeArticle(collectionId: string, articleId: string): Promise<boolean> {
    const before = this.collectionsOf(articleId);
    const delta = this.setMembership(articleId, collectionId, false);
    this.track(articleId, 1);
    try {
      await firstValueFrom(this.api.removeFromCollection(collectionId, articleId));
      return true;
    } catch (error) {
      this.restore(articleId, collectionId, before, delta);
      this.toasts.error(this.errors.forError(error));
      return false;
    } finally {
      this.track(articleId, -1);
    }
  }

  /** Counts the membership changes on their way per article, so an older API copy can't undo them. */
  private track(articleId: string, delta: 1 | -1): void {
    const count = (this.pending.get(articleId) ?? 0) + delta;
    if (count > 0) this.pending.set(articleId, count);
    else this.pending.delete(articleId);
  }

  /** Returns the change made to the collection's article count. */
  private setMembership(articleId: string, collectionId: string, member: boolean): number {
    const known = this.collectionsOf(articleId);
    const ids = new Set(known ?? []);
    const wasMember = ids.has(collectionId);
    if (member) ids.add(collectionId);
    else ids.delete(collectionId);
    this.membership.update((map) => new Map(map).set(articleId, ids));
    // Unknown membership counts as "not in it" (the API's PUT is idempotent).
    const delta = member === wasMember ? 0 : member ? 1 : -1;
    this.adjustCount(collectionId, delta);
    return delta;
  }

  private restore(articleId: string, collectionId: string, before: ReadonlySet<string> | null, delta: number): void {
    this.membership.update((map) => {
      const next = new Map(map);
      if (before) next.set(articleId, before);
      else next.delete(articleId);
      return next;
    });
    this.adjustCount(collectionId, -delta);
  }

  private forgetArticle(articleId: string): void {
    const ids = this.collectionsOf(articleId);
    if (!ids) return;
    for (const id of ids) this.adjustCount(id, -1);
    this.membership.update((map) => new Map(map).set(articleId, new Set()));
  }

  private adjustCount(collectionId: string, delta: number): void {
    if (!delta) return;
    this._collections.update((list) => list.map((c) => (c.id === collectionId ? { ...c, articleCount: Math.max(0, c.articleCount + delta) } : c)));
  }

  private reset(): void {
    this._collections.set([]);
    this._status.set('idle');
    this.membership.set(new Map());
  }
}

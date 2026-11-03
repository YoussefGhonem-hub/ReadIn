import { PendingTasks, inject } from '@angular/core';
import { patchState, signalStore, withMethods, withState } from '@ngrx/signals';
import { firstValueFrom } from 'rxjs';
import { ContentApi } from '../../core/api/content.api';
import { FollowsApi } from '../../core/api/follows.api';
import { ArticleCardDto, FieldDto, UserSummaryDto } from '../../core/api/models';
import { TaxonomyApi } from '../../core/api/taxonomy.api';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { FollowStore } from '../../core/social/follow.store';

export type LoadStatus = 'idle' | 'loading' | 'loaded' | 'error';

interface HomeState {
  fields: FieldDto[];
  today: ArticleCardDto | null;
  todayStatus: LoadStatus;
  items: ArticleCardDto[];
  nextCursor: string | null;
  feedStatus: LoadStatus;
  loadingMore: boolean;
  loadMoreFailed: boolean;
  selectedField: string | null;
  /** The Following tab (F12): articles by people you follow. */
  following: ArticleCardDto[];
  followingCursor: string | null;
  followingStatus: LoadStatus;
  followingLoadingMore: boolean;
  followingMoreFailed: boolean;
  /** Writers to follow, shown when the Following feed is empty. */
  suggested: UserSummaryDto[];
  suggestedStatus: LoadStatus;
}

const PAGE_SIZE = 20;
const SUGGESTED_LIMIT = 10;

/** Home (F03) feature state: today's pick, field chips, the cursor-paginated For-you feed and the Following tab. */
export const HomeStore = signalStore(
  withState<HomeState>({
    fields: [],
    today: null,
    todayStatus: 'idle',
    items: [],
    nextCursor: null,
    feedStatus: 'idle',
    loadingMore: false,
    loadMoreFailed: false,
    selectedField: null,
    following: [],
    followingCursor: null,
    followingStatus: 'idle',
    followingLoadingMore: false,
    followingMoreFailed: false,
    suggested: [],
    suggestedStatus: 'idle',
  }),
  withMethods(
    (
      store,
      content = inject(ContentApi),
      taxonomy = inject(TaxonomyApi),
      followsApi = inject(FollowsApi),
      social = inject(ArticleSocialStore),
      follows = inject(FollowStore),
      tasks = inject(PendingTasks),
    ) => {
      // PendingTasks keeps SSR waiting until state is patched, not just until the HTTP call ends.
      const loadFields = () =>
        tasks.run(async () => {
          try {
            patchState(store, { fields: await firstValueFrom(taxonomy.fields()) });
          } catch {
            /* chips are optional; the feed still works */
          }
        });

      const loadToday = () =>
        tasks.run(async () => {
          patchState(store, { todayStatus: 'loading' });
          try {
            patchState(store, { today: await firstValueFrom(content.today()), todayStatus: 'loaded' });
          } catch {
            patchState(store, { today: null, todayStatus: 'error' });
          }
        });

      const loadFeed = () =>
        tasks.run(async () => {
          const field = store.selectedField();
          patchState(store, { feedStatus: 'loading', items: [], nextCursor: null, loadMoreFailed: false });
          try {
            const page = await firstValueFrom(content.forYou({ field, limit: PAGE_SIZE }));
            if (store.selectedField() !== field) return; // a newer filter won
            social.absorb(page.items);
            patchState(store, { items: page.items, nextCursor: page.nextCursor, feedStatus: 'loaded' });
          } catch {
            if (store.selectedField() === field) patchState(store, { feedStatus: 'error' });
          }
        });

      const loadSuggested = async () => {
        patchState(store, { suggestedStatus: 'loading' });
        try {
          const suggested = await firstValueFrom(followsApi.suggested(SUGGESTED_LIMIT));
          for (const user of suggested) follows.absorb(user.id, user.isFollowing);
          patchState(store, { suggested, suggestedStatus: 'loaded' });
        } catch {
          patchState(store, { suggested: [], suggestedStatus: 'error' });
        }
      };

      /** Browser only (the tab needs a signed-in user). An empty feed brings the suggested writers. */
      const loadFollowing = async () => {
        patchState(store, { followingStatus: 'loading', following: [], followingCursor: null, followingMoreFailed: false });
        try {
          const page = await firstValueFrom(content.following({ limit: PAGE_SIZE }));
          social.absorb(page.items);
          patchState(store, { following: page.items, followingCursor: page.nextCursor, followingStatus: 'loaded' });
          if (!page.items.length && store.suggestedStatus() !== 'loaded') await loadSuggested();
        } catch {
          patchState(store, { followingStatus: 'error' });
        }
      };

      return {
        init(): Promise<unknown> {
          return Promise.all([loadFields(), loadToday(), loadFeed()]);
        },
        refresh(): Promise<unknown> {
          return Promise.all([loadToday(), loadFeed()]);
        },
        retryFeed: loadFeed,
        loadFollowing,
        loadSuggested,
        /** Loads the Following tab the first time it is opened. */
        openFollowing(): Promise<void> {
          return store.followingStatus() === 'idle' ? loadFollowing() : Promise.resolve();
        },
        selectField(slug: string | null): void {
          if (store.selectedField() === slug) return;
          patchState(store, { selectedField: slug });
          void loadFeed();
        },
        async loadMore(): Promise<void> {
          const cursor = store.nextCursor();
          if (!cursor || store.loadingMore() || store.feedStatus() !== 'loaded') return;
          const field = store.selectedField();
          patchState(store, { loadingMore: true, loadMoreFailed: false });
          try {
            const page = await firstValueFrom(content.forYou({ field, cursor, limit: PAGE_SIZE }));
            if (store.selectedField() !== field) return;
            const seen = new Set(store.items().map((i) => i.id));
            social.absorb(page.items);
            patchState(store, {
              items: [...store.items(), ...page.items.filter((i) => !seen.has(i.id))],
              nextCursor: page.nextCursor,
            });
          } catch {
            patchState(store, { loadMoreFailed: true });
          } finally {
            patchState(store, { loadingMore: false });
          }
        },
        async loadMoreFollowing(): Promise<void> {
          const cursor = store.followingCursor();
          if (!cursor || store.followingLoadingMore() || store.followingStatus() !== 'loaded') return;
          patchState(store, { followingLoadingMore: true, followingMoreFailed: false });
          try {
            const page = await firstValueFrom(content.following({ cursor, limit: PAGE_SIZE }));
            const seen = new Set(store.following().map((i) => i.id));
            social.absorb(page.items);
            patchState(store, {
              following: [...store.following(), ...page.items.filter((i) => !seen.has(i.id))],
              followingCursor: page.nextCursor,
            });
          } catch {
            patchState(store, { followingMoreFailed: true });
          } finally {
            patchState(store, { followingLoadingMore: false });
          }
        },
      };
    },
  ),
);

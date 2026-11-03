import { PendingTasks, inject } from '@angular/core';
import { patchState, signalStore, withMethods, withState } from '@ngrx/signals';
import { firstValueFrom } from 'rxjs';
import { ContentApi } from '../../core/api/content.api';
import { ArticleCardDto, FieldDto } from '../../core/api/models';
import { TaxonomyApi } from '../../core/api/taxonomy.api';

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
}

const PAGE_SIZE = 20;

/** Home (F03) feature state: today's pick, field chips and the cursor-paginated For-you feed. */
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
  }),
  withMethods((store, content = inject(ContentApi), taxonomy = inject(TaxonomyApi), tasks = inject(PendingTasks)) => {
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
          patchState(store, { items: page.items, nextCursor: page.nextCursor, feedStatus: 'loaded' });
        } catch {
          if (store.selectedField() === field) patchState(store, { feedStatus: 'error' });
        }
      });

    return {
      init(): Promise<unknown> {
        return Promise.all([loadFields(), loadToday(), loadFeed()]);
      },
      refresh(): Promise<unknown> {
        return Promise.all([loadToday(), loadFeed()]);
      },
      retryFeed: loadFeed,
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
    };
  }),
);

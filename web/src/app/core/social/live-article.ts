import { computed, effect, inject, untracked } from '@angular/core';
import { ArticleCardDto } from '../api/models';
import { RealtimeService } from '../realtime/realtime.service';
import { ArticleSocialStore } from './article-social.store';

/**
 * Feeds the live counters of `article()` (`/live/articles/{id}`, F27) into ArticleSocialStore while `active()` is
 * true: the reader while it is open, a feed card while it is on screen. The values replace the counts, never add to
 * them. Browser only (RealtimeService is a no-op during SSR); without the Realtime Database the REST values stay.
 * Must run in an injection context.
 */
export function bindLiveCounters(article: () => ArticleCardDto | null | undefined, active: () => boolean = () => true): void {
  const realtime = inject(RealtimeService);
  const social = inject(ArticleSocialStore);
  const articleId = computed(() => (active() ? (article()?.id ?? null) : null));
  effect((onCleanup) => {
    const id = articleId();
    if (!id) return;
    onCleanup(
      realtime.watchArticle(id, (counts) => {
        const current = untracked(article);
        if (current?.id === id) social.applyLive(current, counts);
      }),
    );
  });
}

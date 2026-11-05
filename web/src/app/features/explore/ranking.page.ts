import { ChangeDetectionStrategy, Component, computed, effect, inject, input, untracked } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ExploreApi, ExploreRanking } from '../../core/api/explore.api';
import { AppHistory } from '../../core/platform/app-history';
import { reloadOnSessionChange } from '../paths/session-change';
import { CardPages } from './card-pages';
import { CardPagesList } from './card-pages-list';

/** Cards per page of a ranking. */
export const RANKING_PAGE_SIZE = 20;

/** Where each ranking's texts are. */
const TEXTS: Record<ExploreRanking, string> = { trending: 'explore.lists.trending', 'most-saved': 'explore.lists.mostSaved' };

/**
 * A ranking in full (F15 "See all"): `/explore/trending` (the most engaging articles of the last 7 days) and
 * `/explore/most-saved`, as post cards (F34) with infinite scroll, best first. Server-rendered; signed in, it loads
 * again with your token for your reactions and saves. Kept alive while you read (Back finds it as you left it).
 */
@Component({
  selector: 'rd-ranking-page',
  imports: [TranslocoPipe, LucideDynamicIcon, CardPagesList],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto flex max-w-[640px] flex-col gap-2 px-4 pt-4 lg:pt-8' },
  template: `
    @let key = texts();
    <!-- Back to the page you came from in the app, else Explore (a plain link to Explore without JavaScript) -->
    <a href="/explore" class="rd-icon-btn mb-1" [attr.aria-label]="'common.back' | transloco" data-ranking-back (click)="goBack($event)">
      <svg lucideIcon="ArrowRight" [size]="18" class="ltr:rotate-180" aria-hidden="true"></svg>
    </a>
    <header class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" [attr.data-ranking]="ranking()">
      <h1 class="m-0 text-xl font-bold lg:text-2xl">{{ key + '.title' | transloco }}</h1>
      <p class="m-0 mt-1 text-sm text-text-secondary">{{ key + '.sub' | transloco }}</p>
    </header>
    <rd-card-pages-list
      [pages]="pages"
      [endText]="key + '.end' | transloco"
      [emptyTitle]="key + '.emptyTitle' | transloco"
      [emptyBody]="'explore.lists.emptyBody' | transloco"
      [errorText]="'explore.lists.loadError' | transloco"
    />
  `,
})
export class RankingPage {
  private readonly api = inject(ExploreApi);
  private readonly history = inject(AppHistory);
  protected readonly pages = new CardPages();

  /** From the route's data (explore.routes.ts). */
  readonly ranking = input.required<ExploreRanking>();
  protected readonly texts = computed(() => TEXTS[this.ranking()]);

  constructor() {
    effect(() => {
      const ranking = this.ranking();
      untracked(() => void this.pages.load((cursor) => this.api.ranking(ranking, { cursor, limit: RANKING_PAGE_SIZE })));
    });
    // Your reactions and saves once signed in (the server-rendered copy is anonymous); signing out drops them.
    reloadOnSessionChange(() => void this.pages.refresh());
  }

  protected goBack(event: MouseEvent): void {
    // A new tab or window (a modifier key, another button) opens Explore, like any link.
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    this.history.back('/explore');
  }
}

import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { LanguageService } from '../../core/i18n/language.service';
import { MUTE_SCOPE, MuteStore } from '../../core/social/mute.store';
import { BdiText } from '../../shared/directives/bdi-text';
import { PluralPipe } from '../../shared/pipes/format.pipes';
import { ArticleCard } from '../../shared/ui/article-card';
import { FieldIcon } from '../../shared/ui/field-icon';
import { ArticleCardSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { reloadOnSessionChange } from '../paths/session-change';
import { PathCard, PathCardSkeleton } from '../paths/path-card';
import { fieldColorOf } from '../search/search-query';
import { ExploreStore } from './explore.store';
import { WriterRail } from './writer-rail';

/**
 * Explore (F15), `/explore`, for guests too: the way into Search (F16) on narrow screens (wider ones have the header's
 * box), every field (its page holds the topics), the first articles trending this week and the most saved (compact
 * rows; "See all" opens the whole ranking as post cards), new writers with Follow, and the featured learning paths.
 * One call, server-rendered; a section with nothing in it is left out. Kept alive while you open an article, so Back
 * finds it as you left it (features/feed/feed-route-reuse.ts); the compact rows of what you muted or marked "show
 * less" since then leave at once, like the post cards (F28).
 */
@Component({
  selector: 'rd-explore-page',
  imports: [
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    BdiText,
    PluralPipe,
    ArticleCard,
    ArticleCardSkeleton,
    FieldIcon,
    EmptyState,
    ErrorState,
    PathCard,
    PathCardSkeleton,
    WriterRail,
  ],
  providers: [ExploreStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto flex max-w-[720px] flex-col gap-2 px-4 pt-5 lg:pt-8' },
  template: `
    <!-- Every block is a card on the page, 8px apart; on phones the cards go edge to edge like the post cards. -->
    <header class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" data-explore-header>
      <h1 class="m-0 text-xl font-bold lg:text-2xl">{{ 'explore.title' | transloco }}</h1>
      <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'explore.sub' | transloco }}</p>

      <!-- Search (F16): the header has the box from md up; below it, this opens the search page ready to type. -->
      <a routerLink="/search" class="rd-input mt-4 flex min-h-12 items-center gap-2.5 text-text-secondary no-underline md:hidden" data-explore-search>
        <svg lucideIcon="Search" [size]="20" class="shrink-0" aria-hidden="true"></svg>
        <span class="truncate">{{ 'search.placeholder' | transloco }}</span>
      </a>
    </header>

    @switch (store.status()) {
      @case ('error') {
        <rd-error-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [message]="'explore.loadError' | transloco" (retry)="store.load()" />
      }
      @case ('loaded') {
        @if (store.isEmpty()) {
          <rd-empty-state
            class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0"
            [title]="'explore.empty.title' | transloco"
            [message]="'explore.empty.body' | transloco"
            data-explore-empty
          />
        }

        @if (store.fields().length) {
          <section class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" aria-labelledby="explore-fields" data-explore-fields>
            <h2 id="explore-fields" class="m-0 mb-3 text-lg font-bold">{{ 'explore.fields' | transloco }}</h2>
            <ul class="m-0 grid list-none grid-cols-2 gap-2 p-0 sm:grid-cols-3">
              @for (field of store.fields(); track field.id) {
                @let color = fieldColor(field.color);
                <li>
                  <a
                    [routerLink]="['/f', field.slug]"
                    class="rd-card flex h-full min-h-16 items-center gap-3 p-3 text-inherit no-underline shadow-none transition-colors hover:bg-surface-variant"
                    [attr.data-field-tile]="field.slug"
                  >
                    <span
                      class="grid h-10 w-10 shrink-0 place-items-center rounded-full"
                      [style.background-color]="'color-mix(in srgb, ' + color + ' 14%, transparent)'"
                      [style.color]="color"
                      aria-hidden="true"
                      ><rd-field-icon [name]="field.icon" [size]="20"
                    /></span>
                    <span class="min-w-0 flex-1">
                      <span class="line-clamp-2 block text-sm font-semibold leading-snug text-text-primary"
                        ><rd-bdi-text [text]="lang() === 'ar' ? field.nameAr : field.nameEn"
                      /></span>
                      <span class="block text-xs text-text-secondary" data-field-count>{{ field.articleCount | rdPlural: 'reading.articles' : lang() }}</span>
                    </span>
                  </a>
                </li>
              }
            </ul>
          </section>
        }

        <!-- A list card: the title row with "See all", then the rows. -->
        @if (trending().length) {
          <section class="rd-card p-0 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-labelledby="explore-trending" data-explore-trending>
            <div class="flex items-center justify-between gap-3 px-4 pt-2 lg:px-5">
              <h2 id="explore-trending" class="m-0 flex items-center gap-2 text-lg font-bold">
                <svg lucideIcon="Flame" [size]="20" class="text-accent" aria-hidden="true"></svg>
                {{ 'explore.trending' | transloco }}
              </h2>
              <a routerLink="/explore/trending" class="-me-2 inline-flex min-h-11 shrink-0 items-center gap-1 rounded-md px-2 text-sm font-semibold text-primary no-underline hover:bg-primary-container" data-see-all="trending"
                >{{ 'explore.seeAll' | transloco }}<span class="sr-only"> · {{ 'explore.trending' | transloco }}</span>
                <svg lucideIcon="ChevronRight" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
              </a>
            </div>
            <div>
              @for (article of trending(); track article.id) {
                <rd-article-card class="px-4 lg:px-5" [article]="article" [withAttachments]="false" />
              }
            </div>
          </section>
        }

        @if (mostSaved().length) {
          <section class="rd-card p-0 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-labelledby="explore-most-saved" data-explore-most-saved>
            <div class="flex items-center justify-between gap-3 px-4 pt-2 lg:px-5">
              <h2 id="explore-most-saved" class="m-0 flex items-center gap-2 text-lg font-bold">
                <svg lucideIcon="Bookmark" [size]="20" class="text-primary" aria-hidden="true"></svg>
                {{ 'explore.mostSaved' | transloco }}
              </h2>
              <a routerLink="/explore/most-saved" class="-me-2 inline-flex min-h-11 shrink-0 items-center gap-1 rounded-md px-2 text-sm font-semibold text-primary no-underline hover:bg-primary-container" data-see-all="most-saved"
                >{{ 'explore.seeAll' | transloco }}<span class="sr-only"> · {{ 'explore.mostSaved' | transloco }}</span>
                <svg lucideIcon="ChevronRight" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
              </a>
            </div>
            <div>
              @for (article of mostSaved(); track article.id) {
                <rd-article-card class="px-4 lg:px-5" [article]="article" [withAttachments]="false" />
              }
            </div>
          </section>
        }

        @if (store.newWriters().length) {
          <section class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" aria-labelledby="explore-new-writers" data-explore-new-writers>
            <h2 id="explore-new-writers" class="m-0 mb-1 flex items-center gap-2 text-lg font-bold">
              <svg lucideIcon="Sparkles" [size]="20" class="text-primary" aria-hidden="true"></svg>
              {{ 'explore.newWriters' | transloco }}
            </h2>
            <p class="m-0 mb-2 text-sm text-text-secondary">{{ 'explore.newWritersSub' | transloco }}</p>
            <rd-writer-rail [users]="store.newWriters()" [label]="'explore.newWriters' | transloco" />
          </section>
        }

        @if (store.featuredPaths().length) {
          <section class="rd-card px-4 pb-4 pt-2 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:px-5 lg:pb-5" aria-labelledby="explore-paths" data-explore-paths>
            <div class="mb-2 flex items-center justify-between gap-3">
              <h2 id="explore-paths" class="m-0 flex items-center gap-2 text-lg font-bold">
                <svg lucideIcon="Route" [size]="20" class="text-primary" aria-hidden="true"></svg>
                {{ 'explore.featuredPaths' | transloco }}
              </h2>
              <a routerLink="/paths" class="-me-2 inline-flex min-h-11 shrink-0 items-center gap-1 rounded-md px-2 text-sm font-semibold text-primary no-underline hover:bg-primary-container" data-see-all="paths"
                >{{ 'explore.seeAll' | transloco }}<span class="sr-only"> · {{ 'explore.featuredPaths' | transloco }}</span>
                <svg lucideIcon="ChevronRight" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
              </a>
            </div>
            <ul class="m-0 flex list-none flex-col gap-2 p-0">
              @for (path of store.featuredPaths(); track path.id) {
                <li><rd-path-card [path]="path" /></li>
              }
            </ul>
          </section>
        }
      }
      @default {
        <!-- The cards' shapes while Explore loads: the fields, a list and the paths. -->
        <div class="flex flex-col gap-2" aria-busy="true" data-explore-loading>
          <div class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" aria-hidden="true">
            <div class="rd-skeleton mb-3 h-5 w-24"></div>
            <div class="grid grid-cols-2 gap-2 sm:grid-cols-3">
              @for (i of [1, 2, 3, 4, 5, 6]; track i) {
                <div class="rd-skeleton h-16 rounded-card"></div>
              }
            </div>
          </div>
          <div class="rd-card px-4 pt-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:px-5" aria-hidden="true">
            <div class="rd-skeleton h-5 w-40"></div>
            <div class="mt-1">
              @for (i of [1, 2, 3]; track i) {
                <rd-article-card-skeleton />
              }
            </div>
          </div>
          <div class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" aria-hidden="true">
            <div class="rd-skeleton mb-3 h-5 w-32"></div>
            <rd-path-card-skeleton />
          </div>
        </div>
      }
    }
  `,
})
export class ExplorePage {
  protected readonly store = inject(ExploreStore);
  protected readonly lang = inject(LanguageService).lang;
  protected readonly fieldColor = fieldColorOf;
  private readonly mutes = inject(MuteStore);
  private readonly muteScope = inject(MUTE_SCOPE);
  /** The compact rows still shown: what you muted or marked "show less" in this session leaves (F28). */
  protected readonly trending = computed(() => this.store.trending().filter((a) => !this.mutes.hides(a, this.muteScope)));
  protected readonly mostSaved = computed(() => this.store.mostSaved().filter((a) => !this.mutes.hides(a, this.muteScope)));

  constructor() {
    void this.store.load();
    // Your saves, follows and path progress once signed in (the server-rendered copy is anonymous); signing out drops them.
    reloadOnSessionChange(() => void this.store.refresh());
  }
}

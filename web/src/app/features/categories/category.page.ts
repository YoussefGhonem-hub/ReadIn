import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, RESPONSE_INIT, computed, effect, inject, input, untracked, viewChild } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { LanguageService } from '../../core/i18n/language.service';
import { AppHistory } from '../../core/platform/app-history';
import { keepMutedContent } from '../../core/social/mute.store';
import { PluralPipe } from '../../shared/pipes/format.pipes';
import { Avatar } from '../../shared/ui/avatar';
import { PostCardSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { PostCard } from '../feed/post-card';
import { reloadOnSessionChange } from '../paths/session-change';
import { loadMoreNearEnd } from '../profile/infinite-scroll';
import { CategoryPageStore } from './category-page.store';
import { CategorySeoService } from './category-seo.service';

/**
 * A writer's category page (F31), `/@{username}/c/{slug}` (`_other`: their articles without a category, "مقالات
 * تانية"): server-rendered for guests and crawlers. The writer, the category's name and article count, then its
 * published articles, newest first, as post cards (F34) with infinite scroll. Loading skeletons, an error with Retry,
 * an empty state (`noindex`) and a 404 for an unknown category or writer. Signed in, the list loads again with your
 * token once hydrated, for your reactions and saves.
 */
@Component({
  selector: 'rd-category-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, PluralPipe, Avatar, PostCard, PostCardSkeleton, EmptyState, ErrorState],
  // A writer's own page keeps muted content (F28).
  providers: [CategoryPageStore, keepMutedContent()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[640px] px-4 pt-4 lg:pt-8' },
  template: `
    <!-- Back to the page you came from in the app, else the writer's profile (a plain link without JavaScript) -->
    <a [href]="profilePath()" class="rd-icon-btn mb-3" [attr.aria-label]="'common.back' | transloco" data-category-back (click)="goBack($event)">
      <svg lucideIcon="ArrowRight" [size]="18" class="ltr:rotate-180" aria-hidden="true"></svg>
    </a>

    @switch (store.status()) {
      @case ('loaded') {
        @if (store.category(); as category) {
          <header data-category-header>
            <a
              [routerLink]="profilePath()"
              class="-ms-1 inline-flex min-h-11 max-w-full items-center gap-2 rounded-md px-1 text-sm text-text-secondary no-underline hover:text-text-primary"
              data-category-author
            >
              <rd-avatar [name]="category.author.displayName" [src]="category.author.avatarUrl" [size]="28" />
              <bdi dir="auto" class="truncate font-semibold">{{ category.author.displayName }}</bdi>
              <span aria-hidden="true">·</span>
              <span class="shrink-0">{{ (category.id ? 'categories.page.kicker' : 'categories.page.kickerOther') | transloco }}</span>
            </a>
            <!-- The name keeps its own direction, isolated; the heading lines up with the page like the lines around it. -->
            <h1 class="m-0 mt-1 break-words text-2xl font-bold leading-snug">
              <bdi dir="auto" data-category-name>{{ displayName() }}</bdi>
            </h1>
            <p class="m-0 mt-1 text-sm text-text-secondary" data-category-count>
              {{ category.articleCount ? (category.articleCount | rdPlural: 'reading.articles' : lang()) : ('categories.noArticles' | transloco) }}
            </p>
          </header>

          @if (store.items().length) {
            <section class="flex flex-col gap-3 pt-4" [attr.aria-label]="'categories.page.articles' | transloco: { name: displayName() }" data-category-articles>
              @for (article of store.items(); track article.id) {
                <rd-post-card [article]="article" [priorityMedia]="article.id === firstMediaId()" />
              }
              @if (store.loadingMore()) {
                <rd-post-card-skeleton />
              }
            </section>
            @if (store.loadMoreFailed()) {
              <div class="py-4 text-center">
                <button type="button" class="rd-btn rd-btn-outline" data-category-load-more-retry (click)="store.loadMore()">{{ 'common.retry' | transloco }}</button>
              </div>
            }
            @if (store.nextCursor()) {
              <!-- Only under a loaded list: one on screen beside the skeletons would load page 2 right away. -->
              <div #sentinel class="h-px" aria-hidden="true"></div>
            } @else {
              <p class="py-6 text-center text-sm text-text-secondary" data-category-end>{{ 'categories.page.end' | transloco }}</p>
            }
          } @else {
            <!-- "مقالات تانية" isn't a category: its empty state says so in its own words. -->
            <rd-empty-state
              [title]="(category.id ? 'categories.page.emptyTitle' : 'categories.page.otherEmptyTitle') | transloco"
              [message]="(category.id ? 'categories.page.emptyBody' : 'categories.page.otherEmptyBody') | transloco"
              data-category-empty
            >
              <a [routerLink]="profilePath()" class="rd-btn rd-btn-primary mt-3">{{ 'categories.page.backToProfile' | transloco }}</a>
            </rd-empty-state>
          }
        }
      }
      @case ('notFound') {
        <rd-empty-state [title]="'categories.page.notFoundTitle' | transloco" [message]="'categories.page.notFoundBody' | transloco" data-category-not-found>
          @if (store.notFoundCode() === 'category.not_found') {
            <a [routerLink]="profilePath()" class="rd-btn rd-btn-primary mt-3">{{ 'categories.page.backToProfile' | transloco }}</a>
          } @else {
            <a routerLink="/" class="rd-btn rd-btn-primary mt-3">{{ 'comingSoon.backHome' | transloco }}</a>
          }
        </rd-empty-state>
      }
      @case ('error') {
        <rd-error-state [message]="'categories.page.loadError' | transloco" (retry)="store.load(username(), slug())" />
      }
      @default {
        <div aria-busy="true" data-category-loading>
          <div class="flex items-center gap-2">
            <div class="rd-skeleton h-7 w-7 rounded-full"></div>
            <div class="rd-skeleton h-4 w-28"></div>
          </div>
          <div class="rd-skeleton mt-2 h-8 w-1/2"></div>
          <div class="rd-skeleton mt-2 h-4 w-24"></div>
          <div class="flex flex-col gap-3 pt-4">
            @for (i of [1, 2, 3]; track i) {
              <rd-post-card-skeleton />
            }
          </div>
        </div>
      }
    }
  `,
})
export class CategoryPage {
  protected readonly store = inject(CategoryPageStore);
  private readonly history = inject(AppHistory);
  private readonly transloco = inject(TranslocoService);
  private readonly responseInit = inject(RESPONSE_INIT, { optional: true });
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');
  protected readonly lang = inject(LanguageService).lang;

  /** Route params (`/@{username}/c/{slug}`, component input binding); the slug is already percent-decoded. */
  readonly username = input.required<string>();
  readonly slug = input.required<string>();

  protected readonly profilePath = computed(() => `/@${this.store.category()?.author.username ?? this.username()}`);
  /** The category's name, or "مقالات تانية" / "Other articles" for the uncategorized list (`name: null`). */
  protected readonly displayName = computed(() => {
    this.lang();
    return this.store.category()?.name ?? this.transloco.translate('categories.other');
  });
  /** The first card with an image loads it eagerly (as on Home). */
  protected readonly firstMediaId = computed(() => this.store.items().find((a) => a.attachments || a.coverUrl)?.id ?? null);

  constructor() {
    const seo = inject(CategorySeoService);
    effect(() => {
      const username = this.username();
      const slug = this.slug();
      untracked(() => void this.store.load(username, slug));
    });
    effect(() => {
      const status = this.store.status();
      const category = this.store.category();
      const name = this.displayName();
      if (status === 'loaded' && category) seo.category(category, name);
      else if (status === 'notFound') {
        seo.notFound();
        // A real 404 for crawlers when rendered on the server.
        if (this.responseInit) this.responseInit.status = 404;
      }
    });
    inject(DestroyRef).onDestroy(() => seo.clear());
    loadMoreNearEnd(
      () => this.sentinel()?.nativeElement,
      () => void this.store.loadMore(),
    );
    // Your reactions and saves once signed in (the server-rendered copy is anonymous); signing out drops them.
    reloadOnSessionChange(() => void this.store.refresh());
  }

  protected goBack(event: MouseEvent): void {
    // A new tab or window (a modifier key, another button) opens the profile, like any link.
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    this.history.back(this.profilePath());
  }
}

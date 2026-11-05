import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, RESPONSE_INIT, computed, effect, inject, input, untracked, viewChild } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { LanguageService } from '../../core/i18n/language.service';
import { MUTE_SCOPE, MuteStore } from '../../core/social/mute.store';
import { AppHistory } from '../../core/platform/app-history';
import { PluralPipe } from '../../shared/pipes/format.pipes';
import { PostCardSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { PostCard } from '../feed/post-card';
import { reloadOnSessionChange } from '../paths/session-change';
import { loadMoreNearEnd } from '../profile/infinite-scroll';
import { TagPageStore } from './tag-page.store';
import { TagSeoService } from './tag-seo.service';

/**
 * A tag page (F32), `/tags/{slug}`: server-rendered for guests and crawlers. The tag's name ("#name") and article count,
 * then every published article with the tag, from all writers, newest first, as post cards (F34) with infinite scroll.
 * Loading skeletons, an error with Retry, an empty state (`noindex`) and a 404 for an unknown or hidden tag. Signed
 * in, the list loads again with your token once hydrated, for your reactions and saves.
 */
@Component({
  selector: 'rd-tag-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, PluralPipe, PostCard, PostCardSkeleton, EmptyState, ErrorState],
  providers: [TagPageStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[640px] px-4 pt-4 lg:pt-8' },
  template: `
    <!-- Back to the page you came from in the app, else Home (a plain link to Home without JavaScript) -->
    <a href="/" class="rd-icon-btn mb-3" [attr.aria-label]="'common.back' | transloco" data-tag-back (click)="goBack($event)">
      <svg lucideIcon="ArrowRight" [size]="18" class="ltr:rotate-180" aria-hidden="true"></svg>
    </a>

    @switch (store.status()) {
      @case ('loaded') {
        @if (store.tag(); as tag) {
          <header data-tag-header>
            <p class="m-0 text-xs font-semibold text-text-secondary">{{ 'tags.page.kicker' | transloco }}</p>
            <!-- The name keeps its own direction, isolated; the heading lines up with the page like the lines around it. -->
            <h1 class="m-0 break-words text-2xl font-bold leading-snug"><bdi dir="auto" data-tag-name>#{{ tag.name }}</bdi></h1>
            <p class="m-0 mt-1 text-sm text-text-secondary" data-tag-count>{{ tag.articleCount | rdPlural: 'reading.articles' : lang() }}</p>
          </header>

          @if (store.items().length) {
            <section class="flex flex-col gap-3 pt-4" [attr.aria-label]="'tags.page.articles' | transloco: { name: '#' + tag.name }" data-tag-articles>
              @for (article of store.items(); track article.id) {
                <rd-post-card [article]="article" [priorityMedia]="article.id === firstMediaId()" />
              }
              @if (store.loadingMore()) {
                <rd-post-card-skeleton />
              }
            </section>
            @if (store.loadMoreFailed()) {
              <div class="py-4 text-center">
                <button type="button" class="rd-btn rd-btn-outline" data-tag-load-more-retry (click)="store.loadMore()">{{ 'common.retry' | transloco }}</button>
              </div>
            }
            @if (store.nextCursor()) {
              <!-- Only under a loaded list: one on screen beside the skeletons would load page 2 right away. -->
              <div #sentinel class="h-px" aria-hidden="true"></div>
            } @else if (anyShown()) {
              <p class="py-6 text-center text-sm text-text-secondary" data-tag-end>{{ 'tags.page.end' | transloco }}</p>
            }
          }
          <!-- Muted cards fold away but stay in the list (Undo puts them back): count the ones still shown (F28). -->
          @if (!anyShown() && !store.nextCursor()) {
            <rd-empty-state [title]="'tags.page.emptyTitle' | transloco" [message]="'tags.page.emptyBody' | transloco" data-tag-empty>
              <a routerLink="/" class="rd-btn rd-btn-primary mt-3">{{ 'tags.page.browse' | transloco }}</a>
            </rd-empty-state>
          }
        }
      }
      @case ('notFound') {
        <rd-empty-state [title]="'tags.page.notFoundTitle' | transloco" [message]="'tags.page.notFoundBody' | transloco" data-tag-not-found>
          <a routerLink="/" class="rd-btn rd-btn-primary mt-3">{{ 'comingSoon.backHome' | transloco }}</a>
        </rd-empty-state>
      }
      @case ('error') {
        <rd-error-state [message]="'tags.page.loadError' | transloco" (retry)="store.load(slug())" />
      }
      @default {
        <div aria-busy="true" data-tag-loading>
          <div class="rd-skeleton h-3 w-10"></div>
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
export class TagPage {
  protected readonly store = inject(TagPageStore);
  private readonly history = inject(AppHistory);
  private readonly responseInit = inject(RESPONSE_INIT, { optional: true });
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');
  protected readonly lang = inject(LanguageService).lang;

  /** Route param (`/tags/{slug}`, component input binding), already percent-decoded by the router. */
  readonly slug = input.required<string>();

  /** The first card with an image loads it eagerly (as on Home). */
  protected readonly firstMediaId = computed(() => this.store.items().find((a) => a.attachments || a.coverUrl)?.id ?? null);
  private readonly mutes = inject(MuteStore);
  private readonly muteScope = inject(MUTE_SCOPE);
  /** A card is still shown (not muted away, F28). */
  protected readonly anyShown = computed(() => this.mutes.anyShown(this.store.items(), this.muteScope));

  constructor() {
    const seo = inject(TagSeoService);
    effect(() => {
      const slug = this.slug();
      untracked(() => void this.store.load(slug));
    });
    effect(() => {
      const status = this.store.status();
      const tag = this.store.tag();
      if (status === 'loaded' && tag) seo.tag(tag);
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
    // A new tab or window (a modifier key, another button) opens Home, like any link.
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    this.history.back('/');
  }
}

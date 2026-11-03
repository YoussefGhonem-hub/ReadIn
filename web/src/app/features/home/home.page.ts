import {
  ApplicationRef,
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  Injector,
  afterNextRender,
  computed,
  effect,
  inject,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { Title } from '@angular/platform-browser';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { SessionStore } from '../../core/auth/session.store';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { HydrationWindow } from '../../core/http/hydration-window';
import { LanguageService } from '../../core/i18n/language.service';
import { injectNewArticles } from '../../core/realtime/live-signals';
import { BdiText } from '../../shared/directives/bdi-text';
import { ArticleCard } from '../../shared/ui/article-card';
import { ArticleCardSkeleton, HeroSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { StreakBadge } from '../../shared/ui/streak-badge';
import { StreakStore } from '../reading/streak.store';
import { HomeStore } from './home.store';
import { TodayHero } from './today-hero';

type FeedTab = 'forYou' | 'following';

/** Home — "النهارده" (F03). */
@Component({
  selector: 'rd-home-page',
  imports: [TranslocoPipe, BdiText, ArticleCard, ArticleCardSkeleton, HeroSkeleton, EmptyState, ErrorState, StreakBadge, TodayHero],
  providers: [HomeStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pt-5 lg:pt-8' },
  template: `
    <header class="mb-5 flex items-center justify-between gap-3">
      <div>
        <h1 class="m-0 text-xl font-bold" dir="auto">
          @if (firstName(); as name) {
            {{ 'home.greetingName' | transloco: { greeting: (greetingKey() | transloco), name: name } }}
          } @else {
            {{ greetingKey() | transloco }} 👋
          }
        </h1>
        <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'home.sub' | transloco }}</p>
      </div>
      @if (session.isAuthenticated()) {
        <rd-streak-badge class="lg:hidden" [streak]="streaks.streak()" />
      }
    </header>

    <!-- Today's article -->
    @switch (store.todayStatus()) {
      @case ('loading') {
        <rd-hero-skeleton class="mb-6" />
      }
      @case ('loaded') {
        @if (store.today(); as today) {
          <rd-today-hero class="mb-6" [article]="today" />
        }
      }
    }

    <!-- Field chips -->
    <div class="-mx-4 mb-4 flex gap-2 overflow-x-auto px-4 pb-1" role="toolbar" [attr.aria-label]="'home.filterByField' | transloco">
      <button type="button" class="rd-chip" [attr.aria-pressed]="store.selectedField() === null" (click)="store.selectField(null)">
        {{ 'home.allFields' | transloco }}
      </button>
      @for (field of store.fields(); track field.id) {
        <button
          type="button"
          class="rd-chip"
          [attr.aria-pressed]="store.selectedField() === field.slug"
          (click)="store.selectField(field.slug)"
        >
          <rd-bdi-text [text]="lang() === 'ar' ? field.nameAr : field.nameEn" />
        </button>
      }
    </div>

    <!-- Tabs -->
    <div class="mb-1 flex gap-6 border-b border-border" role="tablist">
      @for (tab of tabs; track tab) {
        <button
          type="button"
          role="tab"
          [attr.aria-selected]="activeTab() === tab"
          class="-mb-px border-b-2 pb-2 text-sm"
          [class]="activeTab() === tab ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary'"
          (click)="selectTab(tab)"
        >
          {{ 'home.tabs.' + tab | transloco }}
        </button>
      }
    </div>

    @if (newArticles.available()) {
      <div class="pointer-events-none sticky top-20 z-20 flex justify-center py-2">
        <button type="button" class="rd-btn rd-btn-primary pointer-events-auto min-h-9 px-4 text-sm shadow-raised" (click)="showNewArticles()">
          {{ 'home.newArticles' | transloco }}
        </button>
      </div>
    }

    @if (activeTab() === 'following') {
      <rd-empty-state [title]="'home.following.title' | transloco" [message]="'home.following.body' | transloco" />
    } @else {
      <section [attr.aria-label]="'home.feedTitle' | transloco" aria-live="polite">
        @switch (store.feedStatus()) {
          @case ('error') {
            <rd-error-state [message]="'home.feedError' | transloco" (retry)="store.retryFeed()" />
          }
          @case ('loaded') {
            @for (article of store.items(); track article.id) {
              <rd-article-card [article]="article" [priorityMedia]="article.id === firstMediaId()" />
            } @empty {
              <rd-empty-state [title]="'home.empty.title' | transloco" [message]="'home.empty.body' | transloco" />
            }
            @if (store.loadingMore()) {
              <rd-article-card-skeleton />
            }
            @if (store.loadMoreFailed()) {
              <div class="py-4 text-center">
                <button type="button" class="rd-btn rd-btn-outline" (click)="store.loadMore()">{{ 'common.retry' | transloco }}</button>
              </div>
            }
            @if (store.items().length > 0 && !store.nextCursor()) {
              <p class="py-6 text-center text-sm text-text-secondary">{{ 'home.endOfFeed' | transloco }}</p>
            }
          }
          @default {
            @for (i of [1, 2, 3, 4]; track i) {
              <rd-article-card-skeleton />
            }
          }
        }
        <div #sentinel class="h-px" aria-hidden="true"></div>
      </section>
    }
  `,
})
export class HomePage {
  protected readonly store = inject(HomeStore);
  protected readonly session = inject(SessionStore);
  private readonly prompt = inject(AuthPromptService);
  private readonly injector = inject(Injector);
  private readonly appRef = inject(ApplicationRef);
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;
  protected readonly streaks = inject(StreakStore);

  protected readonly tabs: FeedTab[] = ['forYou', 'following'];
  protected readonly activeTab = signal<FeedTab>('forYou');
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');
  /** "New articles ↑" once something is published after the feed was loaded (F27). */
  protected readonly newArticles = injectNewArticles();

  /** The first card with attachments gets the eager, high-priority image (the rest lazy-load). */
  protected readonly firstMediaId = computed(() => this.store.items().find((a) => a.attachments)?.id ?? null);
  protected readonly firstName = computed(() => this.session.displayName()?.split(' ')[0] ?? null);
  protected readonly greetingKey = computed(() => {
    const hour = new Date().getHours();
    return hour >= 5 && hour < 12 ? 'home.greeting.morning' : 'home.greeting.evening';
  });

  constructor() {
    const hydrating = inject(HydrationWindow).isOpen;
    void this.store.init();
    inject(Title).setTitle(`ReadIn — ${this.transloco.translate('app.tagline')}`);

    const destroyRef = inject(DestroyRef);
    afterNextRender(() => {
      // Infinite scroll: load the next cursor page when the sentinel approaches the viewport.
      const observer = new IntersectionObserver(
        (entries) => {
          if (entries.some((e) => e.isIntersecting)) void this.store.loadMore();
        },
        { rootMargin: '600px 0px' },
      );
      const observe = () => {
        const el = this.sentinel()?.nativeElement;
        observer.disconnect();
        if (el) observer.observe(el);
      };
      observe();
      this.reobserve = observe;
      destroyRef.onDestroy(() => observer.disconnect());

      if (hydrating) {
        // SSR rendered the public feed (requests are anonymous while hydrating). Once the app is stable and the
        // user is signed in, reload it with their token so "For you" is personalized.
        void this.appRef.whenStable().then(() => {
          const ref = effect(
            () => {
              if (!this.session.isAuthenticated()) return;
              untracked(() => void this.store.refresh());
              ref.destroy();
            },
            { injector: this.injector },
          );
        });
      }
    });
  }

  private reobserve: () => void = () => undefined;

  protected selectTab(tab: FeedTab): void {
    if (tab === 'following' && !this.prompt.requireAuth()) return;
    this.activeTab.set(tab);
    // The sentinel element is recreated when switching back to For you.
    afterNextRender(() => this.reobserve(), { injector: this.injector });
  }

  protected showNewArticles(): void {
    this.newArticles.acknowledge();
    this.activeTab.set('forYou');
    void this.store.refresh();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }
}

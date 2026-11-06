import {
  ApplicationRef,
  ChangeDetectionStrategy,
  Component,
  DOCUMENT,
  ElementRef,
  Injector,
  afterNextRender,
  computed,
  effect,
  inject,
  linkedSignal,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { Title } from '@angular/platform-browser';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { SessionStore } from '../../core/auth/session.store';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { HydrationWindow } from '../../core/http/hydration-window';
import { LanguageService } from '../../core/i18n/language.service';
import { injectNewArticles } from '../../core/realtime/live-signals';
import { MUTE_SCOPE, MuteStore } from '../../core/social/mute.store';
import { BdiText } from '../../shared/directives/bdi-text';
import { PostCardSkeleton } from '../../shared/ui/skeletons';
import { ScrollRow } from '../../shared/ui/scroll-row';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { StreakBadge } from '../../shared/ui/streak-badge';
import { PostCard } from '../feed/post-card';
import { StreakStore } from '../reading/streak.store';
import { ContinueReadingCard } from './continue-reading-card';
import { FollowingFeed } from './following-feed';
import { HomeColumns } from './home-columns';
import { HomeStore } from './home.store';
import { LearningPathCard } from './learning-path-card';
import { StartPostCard } from './start-post-card';
import { loadMoreNearEnd } from '../profile/infinite-scroll';

type FeedTab = 'forYou' | 'following';

/**
 * Home — "النهارده" (F03): today's article and the feeds as post cards (F34), in the middle of three columns from `lg`
 * (home-columns.ts: your profile, reading and shortcuts | the feed | suggestions, a path and the footer links), and in
 * one centered column below it. Signed in, "Start a post" comes before today's article.
 * The page stays alive while you read (app.routes.ts `keepOnBack`), so Back finds it as you left it.
 */
@Component({
  selector: 'rd-home-page',
  imports: [
    TranslocoPipe,
    ScrollRow,
    BdiText,
    PostCard,
    PostCardSkeleton,
    EmptyState,
    ErrorState,
    StreakBadge,
    FollowingFeed,
    ContinueReadingCard,
    LearningPathCard,
    HomeColumns,
    StartPostCard,
  ],
  providers: [HomeStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <rd-home-columns>
    <!-- The greeting on the page; everything under it in cards, 8px apart like the side columns. -->
    <div class="flex flex-col gap-2">
      <header class="mb-3 flex items-center justify-between gap-3">
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
        <!-- From lg the streak is in the start column's reading card. -->
        @if (session.isAuthenticated()) {
          <rd-streak-badge class="lg:hidden" [streak]="streaks.streak()" />
        }
      </header>

      <!-- Start a post (signed in, with articles.create). Keep a static class on it: without one, hydration leaves the
           server-rendered "hidden" (a guest there) next to "block" once you are signed in. -->
      <rd-start-post-card class="shrink-0" />

      <!-- Today's article -->
      @switch (store.todayStatus()) {
        @case ('loading') {
          <rd-post-card-skeleton />
        }
        @case ('loaded') {
          @if (store.today(); as today) {
            <rd-post-card [article]="today" label="feedCard.todayLabel" [priorityMedia]="!!(today.attachments || today.coverUrl)" data-today-card />
          }
        }
      }

      <!-- Continue reading (signed in) and your learning path, or the way to the paths (F03, F09) -->
      @if (continueItem(); as item) {
        <rd-continue-reading-card [item]="item" />
      }
      <rd-learning-path-card [path]="store.activePath()" [loading]="pathLoading()" />

      <!-- The feed's card: the For you / Following tabs, then the field chips that filter For you (the Following feed has
           no field filter). Under the chips the tab row has a line; without them the active tab's line is the card's edge. -->
      <div class="rd-card p-0 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" data-home-feed-bar>
        <div class="flex gap-6 px-4 lg:px-5" [class]="activeTab() === 'forYou' ? 'border-b border-border' : ''" role="tablist">
          @for (tab of tabs; track tab) {
            <button
              type="button"
              role="tab"
              [id]="'home-tab-' + tab"
              [attr.aria-controls]="'home-panel-' + tab"
              [attr.aria-selected]="activeTab() === tab"
              [attr.tabindex]="activeTab() === tab ? 0 : -1"
              [attr.data-home-tab]="tab"
              class="-mb-px min-h-12 border-b-2 text-sm"
              [class]="activeTab() === tab ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary'"
              (click)="selectTab(tab)"
              (keydown)="onTabKey($event)"
            >
              {{ 'home.tabs.' + tab | transloco }}
            </button>
          }
        </div>
        @if (activeTab() === 'forYou') {
          <div class="px-4 py-2 lg:px-5">
            <rd-scroll-row [label]="'home.filterByField' | transloco">
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
            </rd-scroll-row>
          </div>
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
        <section id="home-panel-following" role="tabpanel" aria-labelledby="home-tab-following">
          <rd-following-feed />
        </section>
      } @else {
        <section id="home-panel-forYou" role="tabpanel" aria-labelledby="home-tab-forYou" aria-live="polite">
          @switch (store.feedStatus()) {
            @case ('error') {
              <rd-error-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [message]="'home.feedError' | transloco" (retry)="store.retryFeed()" />
            }
            @case ('loaded') {
              <div class="flex flex-col gap-2" data-feed>
                @for (article of store.items(); track article.id) {
                  <rd-post-card [article]="article" [priorityMedia]="article.id === firstMediaId()" />
                }
                <!-- Muted cards fold away but stay in the list (Undo puts them back): count the ones still shown (F28). -->
                @if (!anyShown() && !store.nextCursor()) {
                  <rd-empty-state
                    class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0"
                    [title]="'home.empty.title' | transloco"
                    [message]="'home.empty.body' | transloco"
                  />
                }
                @if (store.loadingMore()) {
                  <rd-post-card-skeleton />
                }
              </div>
              @if (store.loadMoreFailed()) {
                <div class="py-4 text-center">
                  <button type="button" class="rd-btn rd-btn-outline" (click)="store.loadMore()">{{ 'common.retry' | transloco }}</button>
                </div>
              }
              @if (store.nextCursor()) {
                <!-- Only under a loaded list: one on screen beside the skeletons would load page 2 right away. -->
                <div #sentinel class="h-px" aria-hidden="true"></div>
              } @else if (anyShown()) {
                <p class="py-6 text-center text-sm text-text-secondary">{{ 'home.endOfFeed' | transloco }}</p>
              }
            }
            @default {
              <div class="flex flex-col gap-2">
                @for (i of [1, 2, 3]; track i) {
                  <rd-post-card-skeleton />
                }
              </div>
            }
          }
        </section>
      }
    </div>
    </rd-home-columns>
  `,
})
export class HomePage {
  protected readonly store = inject(HomeStore);
  protected readonly session = inject(SessionStore);
  private readonly prompt = inject(AuthPromptService);
  private readonly injector = inject(Injector);
  private readonly appRef = inject(ApplicationRef);
  private readonly transloco = inject(TranslocoService);
  protected readonly streaks = inject(StreakStore);
  private readonly document = inject(DOCUMENT);
  private readonly language = inject(LanguageService);
  protected readonly lang = this.language.lang;

  protected readonly tabs: FeedTab[] = ['forYou', 'following'];
  protected readonly activeTab = signal<FeedTab>('forYou');
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');
  /** "New articles ↑" once something is published after the feed was loaded (F27). */
  protected readonly newArticles = injectNewArticles();

  /** The first card with attachments gets the eager, high-priority image (the rest lazy-load). */
  protected readonly firstMediaId = computed(() => this.store.items().find((a) => a.attachments || a.coverUrl)?.id ?? null);
  private readonly mutes = inject(MuteStore);
  private readonly muteScope = inject(MUTE_SCOPE);
  /** A card of For you is still shown (not muted away, F28). */
  protected readonly anyShown = computed(() => this.mutes.anyShown(this.store.items(), this.muteScope));
  protected readonly firstName = computed(() => this.session.displayName()?.split(' ')[0] ?? null);
  protected readonly greetingKey = computed(() => {
    const hour = new Date().getHours();
    return hour >= 5 && hour < 12 ? 'home.greeting.morning' : 'home.greeting.evening';
  });
  /**
   * The most recent unfinished article that isn't today's pick (the hero already shows that one). Waits for the first
   * answer about today's pick, so the card doesn't switch articles once it arrives.
   */
  protected readonly continueItem = computed(() => {
    if (!this.session.isAuthenticated() || !this.heroSettled()) return null;
    const heroId = this.store.today()?.id ?? null;
    return this.store.continueReading().find((item) => item.article.id !== heroId) ?? null;
  });
  /** True once today's pick answered (or failed) for the first time; a refresh keeps it. */
  private readonly heroSettled = linkedSignal<string, boolean>({
    source: () => this.store.todayStatus(),
    computation: (status, previous) => !!previous?.value || status === 'loaded' || status === 'error',
  });
  /** Signed in, until `/me/paths/active` answers: a placeholder the size of the path card. */
  protected readonly pathLoading = computed(() => {
    const status = this.store.activePathStatus();
    return this.session.isAuthenticated() && (status === 'idle' || status === 'loading');
  });

  constructor() {
    // Continue reading and the active path follow the session (signing out clears them). Coming back to Home builds
    // a new page and store, so both are fresh after reading.
    effect(() => {
      this.session.isAuthenticated();
      untracked(() => void this.store.loadPersonal());
    });
    // Signing out on the Following tab goes back to For you (the tab needs an account).
    effect(() => {
      if (this.session.isGuest() && untracked(this.activeTab) === 'following') untracked(() => this.activeTab.set('forYou'));
    });
    const hydrating = inject(HydrationWindow).isOpen;
    void this.store.init();
    const title = inject(Title);
    const applyTitle = () => title.setTitle(`ReadIn — ${this.transloco.translate('app.tagline')}`);
    applyTitle();
    // Back from an article puts this same page back (it was kept alive): its tab title comes back with it.
    inject(Router)
      .events.pipe(
        filter((e): e is NavigationEnd => e instanceof NavigationEnd),
        takeUntilDestroyed(),
      )
      .subscribe((e) => {
        if (e.urlAfterRedirects.split(/[?#]/)[0] === '/') applyTitle();
      });

    // Infinite scroll: the next cursor page when the sentinel under the loaded list nears the viewport (it follows the
    // sentinel across states and tabs).
    loadMoreNearEnd(
      () => this.sentinel()?.nativeElement,
      () => void this.store.loadMore(),
    );
    afterNextRender(() => {
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

  /** Arrow keys move between the tabs (mirrored in RTL). */
  protected onTabKey(event: KeyboardEvent): void {
    const rtl = this.language.dir() === 'rtl';
    const next = { ArrowRight: rtl ? -1 : 1, ArrowLeft: rtl ? 1 : -1 }[event.key];
    if (!next) return;
    event.preventDefault();
    const index = (this.tabs.indexOf(this.activeTab()) + next + this.tabs.length) % this.tabs.length;
    const tab = this.tabs[index];
    this.selectTab(tab);
    if (this.activeTab() === tab) afterNextRender(() => this.document.getElementById(`home-tab-${tab}`)?.focus(), { injector: this.injector });
  }

  protected selectTab(tab: FeedTab): void {
    if (tab === 'following' && !this.prompt.requireAuth()) return;
    this.activeTab.set(tab);
    if (tab === 'following') void this.store.openFollowing();
  }

  protected showNewArticles(): void {
    this.newArticles.acknowledge();
    this.activeTab.set('forYou');
    void this.store.refresh();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }
}

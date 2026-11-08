import {
  ApplicationRef,
  ChangeDetectionStrategy,
  Component,
  DOCUMENT,
  DestroyRef,
  Injector,
  RESPONSE_INIT,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  signal,
  untracked,
} from '@angular/core';
import { HttpContext, httpResource } from '@angular/common/http';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { SILENT_ERRORS, isApiError } from '../../core/api/api.config';
import { ProfileDto } from '../../core/api/models';
import { ProfilesApi } from '../../core/api/profiles.api';
import { SessionStore } from '../../core/auth/session.store';
import { HydrationWindow } from '../../core/http/hydration-window';
import { LanguageService } from '../../core/i18n/language.service';
import { FollowStore } from '../../core/social/follow.store';
import { BlockStore, BlockedPersonRef } from '../../core/social/block.store';
import { MuteStore, keepMutedContent } from '../../core/social/mute.store';
import { BlockedState } from '../../shared/blocks/blocked-state';
import { MutedBanner } from '../../shared/mutes/muted-banner';
import { ScrollRow } from '../../shared/ui/scroll-row';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { ManageCategories, ProfileCategories } from '../categories/profile-categories';
import { ReadingHeatmap } from '../reading/reading-heatmap';
import { ReadingStatsCard } from '../reading/reading-stats-card';
import { ProfileArticlesStore } from './profile-articles.store';
import { ProfileHeader } from './profile-header';
import { ProfileReposts } from './profile-reposts';
import { ProfileSeoService } from './profile-seo.service';
import { ProfileAbout, ProfileArticles, ProfilePaths, ProfileSaved } from './profile-tabs';
import { PublicStatsSwitch } from './public-stats-switch';

export type ProfileTab = 'articles' | 'categories' | 'reposts' | 'saved' | 'paths' | 'about';

/**
 * Profile (F14), `/@{username}`: server-rendered with its title and Open Graph tags (SPEC §23). Header and stats row,
 * reading stats when visible (yours always, with the "Show on my public profile" switch), and the tabs Articles /
 * Categories (F31; yours is the manage view when you can write) / Reposts (F29, every profile) / Saved (yours only) /
 * Paths / About. SSR is
 * anonymous: once hydrated and signed in, the profile and its articles load again with your token (Follow state,
 * "Follows you", your reactions and saves).
 */
@Component({
  selector: 'rd-profile-page',
  imports: [
    RouterLink,
    TranslocoPipe,
    ScrollRow,
    EmptyState,
    ErrorState,
    ProfileHeader,
    ProfileArticles,
    ProfileSaved,
    ProfileAbout,
    ProfilePaths,
    ProfileCategories,
    ManageCategories,
    ProfileReposts,
    PublicStatsSwitch,
    ReadingStatsCard,
    ReadingHeatmap,
    MutedBanner, BlockedState],
  // The writer's own page keeps muted content: you opened it on purpose (F28).
  providers: [ProfileArticlesStore, keepMutedContent()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto flex max-w-[720px] flex-col gap-2 px-4 pt-5 lg:pt-8' },
  template: `
    <!-- Cards on the page's canvas, 8px apart: the top card (banner, photo, who they are, actions, stats), the reading
         stats, the tabs, then the tab's content (post cards, or one card). -->
    @if (blockedUser(); as blocked) {
      <!-- F36: you blocked them: the account isn't available, with Unblock (they get a 404 for yours) -->
      <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0">
        <rd-blocked-state kind="account" [user]="blocked" (unblocked)="resource.reload()" />
      </div>
    } @else if (profile(); as p) {
      <rd-profile-header [profile]="p" [isMe]="isMe()" />

      <!-- A writer you muted (F28): their page still opens, with the way to unmute -->
      @if (muted()) {
        <rd-muted-banner [user]="p" />
      }

      @if (statsVisible()) {
        <section
          class="rd-card block p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5"
          aria-labelledby="profile-reading-title"
          data-profile-reading
        >
          <h2 id="profile-reading-title" class="m-0 mb-3 text-base font-semibold">{{ 'profile.readingStats.title' | transloco }}</h2>
          @if (isMe()) {
            <rd-public-stats-switch class="mb-4 border-b border-border pb-2" />
          }
          <rd-reading-stats-card [username]="isMe() ? null : p.username" />
          <rd-reading-heatmap class="mt-5" [username]="isMe() ? null : p.username" />
        </section>
      }

      <!-- The tabs card. The row scrolls sideways on narrow screens without a scrollbar (its edges fade, with arrows
           where there is a mouse) and never up and down; the active tab's line sits on the card's edge. -->
      <div class="rd-card px-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" data-profile-tabs>
        <rd-scroll-row [role]="'tablist'" [label]="'profile.tabs.label' | transloco" [flush]="true">
          @for (t of tabs(); track t) {
            <button
              type="button"
              role="tab"
              [id]="'profile-tab-' + t"
              [attr.aria-controls]="'profile-panel-' + t"
              [attr.aria-selected]="tab() === t"
              [attr.tabindex]="tab() === t ? 0 : -1"
              [attr.data-profile-tab]="t"
              class="min-h-12 shrink-0 border-b-2 px-2 text-sm"
              [class]="tab() === t ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary hover:text-text-primary'"
              (click)="selectTab(t)"
              (keydown)="onTabKey($event)"
            >
              {{ 'profile.tabs.' + t | transloco }}
            </button>
          }
        </rd-scroll-row>
      </div>
      <section [id]="'profile-panel-' + tab()" role="tabpanel" [attr.aria-labelledby]="'profile-tab-' + tab()" tabindex="-1">
        @switch (tab()) {
          @case ('categories') {
            <!-- One card around the categories (their tiles, or the manage list). Its own chunk (with the manage view's
                 drag and drop), loaded when the tab opens. -->
            <div class="rd-card px-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:px-5" data-profile-categories-card>
              @defer (on immediate) {
                @if (canManageCategories()) {
                  <rd-manage-categories [username]="p.username" />
                } @else {
                  <rd-profile-categories [username]="p.username" />
                }
              } @placeholder {
                <div class="grid gap-3 py-4 sm:grid-cols-2" aria-busy="true">
                  @for (i of [1, 2, 3, 4]; track i) {
                    <div class="rd-skeleton h-16 w-full rounded-card"></div>
                  }
                </div>
              }
            </div>
          }
          @case ('reposts') {
            <rd-profile-reposts [username]="p.username" [isMe]="isMe()" />
          }
          @case ('saved') {
            <rd-profile-saved />
          }
          @case ('paths') {
            <rd-profile-paths [username]="p.username" [isMe]="isMe()" [visible]="statsVisible()" />
          }
          @case ('about') {
            <rd-profile-about [profile]="p" [isMe]="isMe()" />
          }
          @default {
            <rd-profile-articles [username]="p.username" [isMe]="isMe()" />
          }
        }
      </section>
    } @else if (notFound()) {
      <rd-empty-state
        class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0"
        [title]="'profile.notFound.title' | transloco"
        [message]="'profile.notFound.body' | transloco"
        data-profile-not-found
      >
        <a routerLink="/" class="rd-btn rd-btn-primary mt-3">{{ 'comingSoon.backHome' | transloco }}</a>
      </rd-empty-state>
    } @else if (resource.status() === 'error') {
      <rd-error-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [message]="'profile.loadError' | transloco" (retry)="resource.reload()" />
    } @else {
      <!-- The top card's shape while the profile loads -->
      <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-busy="true" data-profile-loading>
        <div class="h-20 rounded-t-[calc(var(--rd-radius-card)-1px)] bg-surface-variant max-sm:rounded-none sm:h-24 lg:h-28"></div>
        <div class="flex flex-col gap-2 px-4 pb-5 lg:px-6">
          <div class="-mt-12 w-fit rounded-full bg-surface p-1 lg:-mt-16">
            <div class="rd-skeleton h-24 w-24 rounded-full lg:h-28 lg:w-28"></div>
          </div>
          <div class="rd-skeleton mt-1 h-6 w-1/2"></div>
          <div class="rd-skeleton h-4 w-1/3"></div>
          <div class="rd-skeleton h-4 w-full"></div>
          <div class="rd-skeleton mt-2 h-11 w-32"></div>
        </div>
      </div>
    }
  `,
})
export class ProfilePage {
  private readonly api = inject(ProfilesApi);
  private readonly session = inject(SessionStore);
  private readonly seo = inject(ProfileSeoService);
  private readonly articles = inject(ProfileArticlesStore);
  private readonly language = inject(LanguageService);
  private readonly document = inject(DOCUMENT);
  private readonly injector = inject(Injector);
  private readonly responseInit = inject(RESPONSE_INIT, { optional: true });

  /** Route param (`/@{username}`, component input binding). */
  readonly username = input.required<string>();

  protected readonly resource = httpResource<ProfileDto>(() => ({
    url: this.api.profileUrl(this.username()),
    context: new HttpContext().set(SILENT_ERRORS, true),
  }));
  protected readonly profile = computed(() => (this.resource.hasValue() ? this.resource.value() : null));
  protected readonly notFound = computed(() => {
    const error = this.resource.error();
    return isApiError(error) && error.status === 404;
  });
  private readonly blocks = inject(BlockStore);
  /** F36: the person you blocked (`403 block.blocked` with `blockedUser`, or a block from the "⋯" menu now). */
  protected readonly blockedUser = computed<BlockedPersonRef | null>(() => {
    const error = this.resource.error();
    if (isApiError(error) && error.code === 'block.blocked' && error.problem?.blockedUser) {
      // Shown until the reload after Unblock replaces the error (the unblock itself is optimistic, so the state must not
      // disappear before it can ask for the reload).
      return error.problem.blockedUser;
    }
    const p = this.profile();
    return p && !p.isMe && this.session.isAuthenticated() && this.blocks.isBlocked(p.id) ? { id: p.id, displayName: p.displayName, username: p.username } : null;
  });

  /** The server says so, or the session already knows it (SSR and the first client render are anonymous). */
  protected readonly isMe = computed(() => {
    const p = this.profile();
    return !!p && (p.isMe || (this.session.isAuthenticated() && this.session.me()?.id === p.id));
  });
  protected readonly statsVisible = computed(() => this.isMe() || !!this.profile()?.readingStatsVisible);
  private readonly mutes = inject(MuteStore);
  /** You muted this writer (F28), here or anywhere else in the app. */
  protected readonly muted = computed(() => {
    const p = this.profile();
    return !!p && !this.isMe() && this.session.isAuthenticated() && this.mutes.isAuthorMuted(p.id, p.isMuted ?? false);
  });
  protected readonly tabs = computed<ProfileTab[]>(() =>
    this.isMe() ? ['articles', 'categories', 'reposts', 'saved', 'paths', 'about'] : ['articles', 'categories', 'reposts', 'paths', 'about'],
  );
  /** Your own Categories tab manages them (F31, `GET /me/categories` needs `articles.create`); readers see the public list. */
  protected readonly canManageCategories = computed(() => this.isMe() && this.session.permissions().has('articles.create'));
  protected readonly tab = signal<ProfileTab>('articles');

  constructor() {
    const follows = inject(FollowStore);
    // A new profile (or the same page for another username) starts on Articles.
    effect(() => {
      const username = this.username();
      untracked(() => {
        this.tab.set('articles');
        void this.articles.load(username);
      });
    });
    effect(() => {
      const p = this.profile();
      if (p) {
        this.seo.apply(p);
        untracked(() => follows.absorb(p.id, p.isFollowing));
      } else if (this.notFound()) {
        this.seo.notFound();
        // A real 404 for crawlers when rendered on the server.
        if (this.responseInit) this.responseInit.status = 404;
      }
    });
    // Signing out (or into another account) on your Saved tab goes back to Articles.
    effect(() => {
      if (!this.tabs().includes(this.tab())) untracked(() => this.tab.set('articles'));
    });
    this.personalizeAfterHydration();
    inject(DestroyRef).onDestroy(() => this.seo.clear());
  }

  protected selectTab(tab: ProfileTab): void {
    this.tab.set(tab);
  }

  /** Arrow keys, Home and End move between the tabs (arrows mirror in RTL). */
  protected onTabKey(event: KeyboardEvent): void {
    const tabs = this.tabs();
    const index = tabs.indexOf(this.tab());
    const rtl = this.language.dir() === 'rtl';
    const step = { ArrowRight: rtl ? -1 : 1, ArrowLeft: rtl ? 1 : -1 }[event.key];
    let next: number | null = null;
    if (step) next = (index + step + tabs.length) % tabs.length;
    else if (event.key === 'Home') next = 0;
    else if (event.key === 'End') next = tabs.length - 1;
    if (next === null) return;
    event.preventDefault();
    const tab = tabs[next];
    this.tab.set(tab);
    afterNextRender(() => this.document.getElementById(`profile-tab-${tab}`)?.focus(), { injector: this.injector });
  }

  /**
   * SSR renders the profile anonymously and hydration reuses that response, so Follow state, "Follows you" and your
   * reactions on the cards are missing on a server-rendered page. Once the app is stable and you are signed in, load
   * them again with your token.
   */
  private personalizeAfterHydration(): void {
    if (!inject(HydrationWindow).isOpen) return;
    void inject(ApplicationRef)
      .whenStable()
      .then(() => {
        const ref = effect(
          () => {
            if (!this.session.isAuthenticated()) return;
            untracked(() => {
              this.resource.reload();
              void this.articles.refresh();
            });
            ref.destroy();
          },
          { injector: this.injector },
        );
      });
  }
}

import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, computed, effect, inject, signal, untracked, viewChild } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { FollowsApi } from '../core/api/follows.api';
import { UserSummaryDto } from '../core/api/models';
import { SessionStore } from '../core/auth/session.store';
import { FollowStore } from '../core/social/follow.store';
import { PeopleStore } from '../features/profile/people.store';
import { BdiText } from '../shared/directives/bdi-text';
import { FollowButton } from '../shared/social/follow-button';
import { Avatar } from '../shared/ui/avatar';

/** Following fewer people than this (and no search), the panel adds writers you might like under them. */
export const FEW_FOLLOWING = 5;
/** How many suggestions it asks for. */
export const DOCK_SUGGESTIONS = 5;
/** Remembers whether you left the panel open. */
export const DOCK_STORAGE_KEY = 'rd.followingDock';
export const DOCK_SEARCH_DEBOUNCE_MS = 300;
/** Opening it again after this long reloads the list (you may have followed someone meanwhile). */
export const DOCK_STALE_MS = 30_000;
/** Loads the next page when the list is scrolled this close to its end, in px. */
const LOAD_MORE_EDGE = 120;

/**
 * The people you follow, in a panel docked at the window's bottom corner on wide screens (the shell shows it to
 * signed-in members, not on the editor's pages). Only the header bar shows until you open it; it stays as you left it.
 * Open: a search box (by name or @username), then the people you follow, newest first, each opening their profile,
 * with "Follows you" when they do. Following fewer than {@link FEW_FOLLOWING} people, writers you might like follow
 * (`GET /users/suggested`: their fields overlap your interests), each with a Follow button. No messages: it's a list.
 */
@Component({
  selector: 'rd-following-dock',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, Avatar, BdiText, FollowButton],
  providers: [PeopleStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'fixed bottom-0 end-4 z-30 block w-72', '(keydown.escape)': 'escape()', 'data-following-dock': '' },
  template: `
    <section
      class="flex flex-col overflow-hidden rounded-t-[12px] border border-b-0 border-border bg-surface shadow-[0_-1px_3px_rgb(0_0_0/0.06),0_-6px_20px_rgb(0_0_0/0.08)]"
      aria-labelledby="rd-dock-title"
    >
      <h2 class="m-0">
        <button
          #toggleButton
          type="button"
          class="flex h-12 w-full cursor-pointer items-center gap-2.5 border-0 bg-transparent px-3 text-start text-text-primary outline-offset-[-2px] transition-colors hover:bg-surface-variant"
          [attr.aria-expanded]="open()"
          aria-controls="rd-dock-panel"
          (click)="toggle()"
          data-dock-toggle
        >
          <rd-avatar [name]="session.displayName()" [src]="session.avatarUrl()" [size]="28" />
          <span id="rd-dock-title" class="min-w-0 flex-1 truncate text-sm font-semibold">{{ 'followingDock.title' | transloco }}</span>
          <svg [lucideIcon]="open() ? 'ChevronDown' : 'ChevronUp'" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
        </button>
      </h2>

      @if (open()) {
        <div id="rd-dock-panel" class="flex h-[min(34rem,calc(100vh-9rem))] flex-col border-t border-border" data-dock-panel>
          <div class="p-2">
            <label class="relative block">
              <span class="sr-only">{{ 'followingDock.search' | transloco }}</span>
              <svg lucideIcon="Search" [size]="16" class="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 text-text-secondary" aria-hidden="true"></svg>
              <input
                type="search"
                class="h-9 w-full rounded-sm border border-transparent bg-surface-variant pe-3 ps-9 text-sm text-text-primary outline-offset-0 placeholder:text-text-secondary focus:border-border focus:bg-surface"
                [placeholder]="'followingDock.search' | transloco"
                [value]="typed()"
                (input)="search($any($event.target).value)"
                autocomplete="off"
                data-dock-search
              />
            </label>
          </div>

          <div #scroller class="min-h-0 flex-1 overflow-y-auto overscroll-contain" (scroll)="scrolled()" data-dock-list>
            @switch (people.status()) {
              @case ('loaded') {
                @if (people.items().length) {
                  <ul class="m-0 list-none p-0" [attr.aria-label]="'followingDock.title' | transloco">
                    @for (user of people.items(); track user.id) {
                      <li>
                        <a
                          [routerLink]="'/@' + user.username"
                          class="flex items-center gap-3 border-b border-border px-3 py-2.5 text-text-primary no-underline outline-offset-[-2px] transition-colors hover:bg-surface-variant focus:bg-surface-variant"
                          data-dock-person
                          [attr.data-user]="user.id"
                        >
                          <rd-avatar [name]="user.displayName" [src]="user.avatarUrl" [size]="44" />
                          <span class="min-w-0 flex-1">
                            <span class="flex items-center gap-1 text-sm font-semibold leading-5">
                              <rd-bdi-text class="truncate" [text]="user.displayName" />
                              @if (user.isVerified) {
                                <svg lucideIcon="BadgeCheck" [size]="14" class="shrink-0 text-primary" role="img" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
                              }
                            </span>
                            <!-- The line keeps the page's direction; the bio runs in its own and is cut at its own end. -->
                            <span class="block text-[13px] leading-5 text-text-secondary">
                              @if (user.bio) {
                                <rd-bdi-text class="inline-block max-w-full truncate align-top" [text]="user.bio" />
                              } @else {
                                <bdi dir="ltr" class="inline-block max-w-full truncate align-top">&#64;{{ user.username }}</bdi>
                              }
                            </span>
                          </span>
                          @if (user.followsYou) {
                            <span class="shrink-0 self-start rounded-sm bg-surface-variant px-1.5 text-[11px] font-medium leading-5 text-text-secondary" data-dock-follows-you>{{
                              'profile.followsYou' | transloco
                            }}</span>
                          }
                        </a>
                      </li>
                    }
                  </ul>
                  @if (people.loadingMore()) {
                    <div class="flex justify-center py-3" role="status" data-dock-loading-more>
                      <svg lucideIcon="LoaderCircle" [size]="20" class="animate-spin text-text-secondary" aria-hidden="true"></svg>
                      <span class="sr-only">{{ 'common.loading' | transloco }}</span>
                    </div>
                  } @else if (people.loadMoreFailed()) {
                    <button type="button" [class]="retryClass" (click)="people.loadMore()" data-dock-load-more-retry>
                      <svg lucideIcon="RotateCw" [size]="16" aria-hidden="true"></svg>{{ 'common.retry' | transloco }}
                    </button>
                  }
                } @else {
                  <p class="m-0 px-4 py-6 text-center text-sm text-text-secondary" data-dock-empty>
                    @if (query()) {
                      {{ 'followingDock.noResults' | transloco: { q: query() } }}
                    } @else {
                      {{ 'followingDock.empty' | transloco }}
                    }
                  </p>
                }

                @if (showSuggestions()) {
                  <section aria-labelledby="rd-dock-suggested" class="pb-2 pt-3" data-dock-suggestions>
                    <h3 id="rd-dock-suggested" class="m-0 px-3 text-[13px] font-semibold">{{ 'followingDock.suggested' | transloco }}</h3>
                    <p class="m-0 px-3 text-xs text-text-secondary">{{ 'followingDock.suggestedHint' | transloco }}</p>
                    <ul class="m-0 mt-1 list-none p-0">
                      @for (user of suggestions(); track user.id) {
                        <li class="flex items-center gap-3 py-1.5 pe-1 ps-3" data-dock-suggestion [attr.data-user]="user.id">
                          <a [routerLink]="'/@' + user.username" class="shrink-0" tabindex="-1" aria-hidden="true">
                            <rd-avatar [name]="user.displayName" [src]="user.avatarUrl" [size]="40" />
                          </a>
                          <div class="min-w-0 flex-1">
                            <a [routerLink]="'/@' + user.username" class="flex items-center gap-1 text-sm font-semibold leading-5 text-text-primary no-underline hover:underline">
                              <rd-bdi-text class="truncate" [text]="user.displayName" />
                              @if (user.isVerified) {
                                <svg lucideIcon="BadgeCheck" [size]="14" class="shrink-0 text-primary" role="img" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
                              }
                            </a>
                            <p class="m-0 text-xs leading-5 text-text-secondary">
                              @if (user.bio) {
                                <rd-bdi-text class="inline-block max-w-full truncate align-top" [text]="user.bio" />
                              } @else {
                                <bdi dir="ltr" class="inline-block max-w-full truncate align-top">&#64;{{ user.username }}</bdi>
                              }
                            </p>
                          </div>
                          <rd-follow-button [user]="user" [initial]="user.isFollowing" [compact]="true" />
                        </li>
                      }
                    </ul>
                  </section>
                }
              }
              @case ('error') {
                <div class="flex flex-col items-center gap-2 px-4 py-6 text-center" role="alert" data-dock-error>
                  <p class="m-0 text-sm text-text-secondary">{{ 'followingDock.error' | transloco }}</p>
                  <button type="button" [class]="retryClass" (click)="people.load()">
                    <svg lucideIcon="RotateCw" [size]="16" aria-hidden="true"></svg>{{ 'common.retry' | transloco }}
                  </button>
                </div>
              }
              @default {
                <div aria-hidden="true" data-dock-loading>
                  @for (i of [1, 2, 3, 4, 5]; track i) {
                    <div class="flex items-center gap-3 border-b border-border px-3 py-2.5">
                      <div class="rd-skeleton h-11 w-11 shrink-0 rounded-full"></div>
                      <div class="flex flex-1 flex-col gap-2">
                        <div class="rd-skeleton h-3 w-2/3"></div>
                        <div class="rd-skeleton h-3 w-1/2"></div>
                      </div>
                    </div>
                  }
                </div>
              }
            }
          </div>
        </div>
      }
    </section>
  `,
})
export class FollowingDock {
  protected readonly session = inject(SessionStore);
  protected readonly people = inject(PeopleStore);
  private readonly api = inject(FollowsApi);
  private readonly follows = inject(FollowStore);
  private readonly toggleButton = viewChild<ElementRef<HTMLButtonElement>>('toggleButton');
  private readonly scroller = viewChild<ElementRef<HTMLElement>>('scroller');

  protected readonly open = signal(readOpen());
  /** What's in the search box; {@link query} is what the list was searched for (after the debounce). */
  protected readonly typed = signal('');
  protected readonly query = this.people.query;
  protected readonly suggestions = signal<UserSummaryDto[]>([]);
  private suggestionsStatus: 'idle' | 'loading' | 'loaded' | 'error' = 'idle';
  private loadedAt = 0;
  private searchTimer: ReturnType<typeof setTimeout> | undefined;

  protected readonly retryClass =
    'mx-auto flex min-h-9 cursor-pointer items-center gap-1.5 rounded-sm border-0 bg-transparent px-3 text-sm font-semibold text-primary hover:bg-primary-container';

  /** Few people followed and no search: the list ends with writers you might like. */
  private readonly few = computed(
    () => !this.query() && this.people.status() === 'loaded' && !this.people.nextCursor() && this.people.items().length < FEW_FOLLOWING,
  );
  protected readonly showSuggestions = computed(() => this.few() && this.suggestions().length > 0);

  constructor() {
    const meId = computed(() => this.session.me()?.id ?? null);
    // Opened (or open from the last visit) with a session: load the list; again after a while away.
    effect(() => {
      const id = meId();
      if (!this.open() || !id) return;
      untracked(() => {
        const first = this.people.status() === 'idle';
        if (!first && Date.now() - this.loadedAt <= DOCK_STALE_MS) return;
        this.loadedAt = Date.now();
        void (first ? this.people.open(id, 'following') : this.people.load());
      });
    });
    effect(() => {
      if (this.few()) untracked(() => void this.loadSuggestions());
    });
    inject(DestroyRef).onDestroy(() => clearTimeout(this.searchTimer));
  }

  protected toggle(): void {
    if (this.open()) this.collapse(false);
    else this.setOpen(true);
  }

  /** Escape inside the open panel closes it, and the focus goes to its header. */
  protected escape(): void {
    if (this.open()) this.collapse();
  }

  /** Only the header bar stays (from Escape, the focus goes to it). */
  protected collapse(focus = true): void {
    this.setOpen(false);
    if (focus) this.toggleButton()?.nativeElement.focus();
  }

  protected search(value: string): void {
    this.typed.set(value);
    clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => this.people.setQuery(value), DOCK_SEARCH_DEBOUNCE_MS);
  }

  protected scrolled(): void {
    const el = this.scroller()?.nativeElement;
    if (el && el.scrollHeight - el.scrollTop - el.clientHeight < LOAD_MORE_EDGE) void this.people.loadMore();
  }

  private setOpen(open: boolean): void {
    if (open && this.people.status() !== 'idle' && Date.now() - this.loadedAt > DOCK_STALE_MS) {
      // Back after a while: the effect reloads; start from the whole list.
      clearTimeout(this.searchTimer);
      this.typed.set('');
      this.people.query.set('');
    }
    this.open.set(open);
    try {
      localStorage.setItem(DOCK_STORAGE_KEY, open ? 'open' : 'closed');
    } catch {
      // Storage may be off; the panel just starts closed next time.
    }
  }

  private async loadSuggestions(): Promise<void> {
    if (this.suggestionsStatus !== 'idle') return;
    this.suggestionsStatus = 'loading';
    try {
      const users = await firstValueFrom(this.api.suggested(DOCK_SUGGESTIONS));
      for (const user of users) this.follows.absorb(user.id, user.isFollowing);
      this.suggestions.set(users);
      this.suggestionsStatus = 'loaded';
    } catch {
      this.suggestionsStatus = 'error'; // nothing to suggest is fine: the section just doesn't show
    }
  }
}

function readOpen(): boolean {
  try {
    return typeof localStorage !== 'undefined' && localStorage.getItem(DOCK_STORAGE_KEY) === 'open';
  } catch {
    return false;
  }
}

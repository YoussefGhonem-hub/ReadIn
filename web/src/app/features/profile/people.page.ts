import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  PLATFORM_ID,
  computed,
  effect,
  inject,
  input,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { HttpContext, httpResource } from '@angular/common/http';
import { Title } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { SILENT_ERRORS, isApiError } from '../../core/api/api.config';
import { ProfileDto } from '../../core/api/models';
import { ProfilesApi } from '../../core/api/profiles.api';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { CompactNumberPipe } from '../../shared/pipes/format.pipes';
import { FollowButton } from '../../shared/social/follow-button';
import { UserRow } from '../../shared/social/user-row';
import { Avatar } from '../../shared/ui/avatar';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { loadMoreNearEnd } from './infinite-scroll';
import { PeopleList, PeopleStore } from './people.store';

/** Wait this long after the last keystroke before searching. */
export const PEOPLE_SEARCH_DEBOUNCE_MS = 300;
const LISTS: readonly PeopleList[] = ['followers', 'following'];

/**
 * Followers / Following (F12, F14), `/@{username}/followers` and `/following`: search by name or @username
 * (debounced), infinite scroll, a Follow button per row; a row opens that profile. A header card (back to the profile,
 * the title, the two lists, the search), then a list card. The server renders the header; the list loads in the
 * browser, where your Follow state is known.
 */
@Component({
  selector: 'rd-people-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, CompactNumberPipe, Avatar, UserRow, FollowButton, EmptyState, ErrorState],
  providers: [PeopleStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto flex max-w-[720px] flex-col gap-2 px-4 pt-5 lg:pt-8' },
  template: `
    @if (profile(); as p) {
      <!-- The header card: whose lists (back to the profile), the title, the two lists edge to edge, then the search. -->
      <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 p-0" data-people-header>
        <header class="px-4 pb-1 pt-3 lg:px-5 lg:pt-4">
          <a [routerLink]="'/@' + p.username" class="-ms-1 inline-flex min-h-11 min-w-0 items-center gap-2 rounded-md px-1 text-sm text-text-secondary no-underline hover:text-text-primary" data-back-to-profile>
            <svg lucideIcon="ArrowRight" [size]="18" class="shrink-0 ltr:rotate-180" aria-hidden="true"></svg>
            <span class="sr-only">{{ 'profile.people.backToProfile' | transloco }}:</span>
            <rd-avatar [name]="p.displayName" [src]="p.avatarUrl" [size]="28" />
            <rd-bdi-text class="truncate font-semibold text-text-primary" [text]="p.displayName" />
            <bdi dir="ltr" class="shrink-0">&#64;{{ p.username }}</bdi>
          </a>
          <h1 class="m-0 mt-1 text-xl font-bold lg:text-2xl">{{ 'profile.people.' + list() | transloco }}</h1>
        </header>

        <nav class="flex gap-5 border-b border-border px-4 lg:px-5" [attr.aria-label]="'profile.people.label' | transloco" data-people-lists>
          @for (l of lists; track l) {
            <a
              [routerLink]="['/@' + p.username, l]"
              replaceUrl
              class="-mb-px inline-flex min-h-12 items-center gap-1.5 border-b-2 px-1 text-sm no-underline"
              [class]="l === list() ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary hover:text-text-primary'"
              [attr.aria-current]="l === list() ? 'page' : null"
              [attr.data-people-list]="l"
            >
              {{ 'profile.people.' + l | transloco }}
              <span class="text-xs opacity-80">{{ (l === 'followers' ? p.stats.followers : p.stats.following) | rdCompactNumber: lang() }}</span>
            </a>
          }
        </nav>

        <div class="relative mx-4 my-3 lg:mx-5" role="search">
          <svg lucideIcon="Search" [size]="18" class="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 text-text-secondary" aria-hidden="true"></svg>
          <input
            type="search"
            class="rd-input ps-10"
            dir="auto"
            autocomplete="off"
            enterkeyhint="search"
            data-people-search
            [attr.aria-label]="'profile.people.search' | transloco"
            [placeholder]="'profile.people.search' | transloco"
            [value]="searchText()"
            (input)="onSearchInput($event)"
            (keydown.enter)="searchNow()"
          />
        </div>
      </div>

      <!-- The list card: the people as rows, and the loading, empty and error states in their place. -->
      <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 p-0" [attr.aria-label]="'profile.people.' + list() | transloco" aria-live="polite" data-people>
        @switch (store.status()) {
          @case ('error') {
            <rd-error-state [message]="'profile.people.loadError' | transloco" (retry)="store.load()" />
          }
          @case ('loaded') {
            <ul class="m-0 list-none divide-y divide-border p-0">
              @for (user of store.items(); track user.id) {
                <li class="px-4 lg:px-5" data-person [attr.data-user]="user.id">
                  <rd-user-row [user]="user" [bio]="user.bio" [note]="user.followsYou ? ('profile.followsYou' | transloco) : null">
                    <rd-follow-button [user]="user" [initial]="user.isFollowing" />
                  </rd-user-row>
                </li>
              }
            </ul>
            @if (!store.items().length) {
              @if (store.query()) {
                <rd-empty-state [title]="'profile.people.noResults' | transloco: { q: store.query() }" [message]="'profile.people.noResultsBody' | transloco" data-people-no-results />
              } @else {
                <rd-empty-state [title]="(list() === 'followers' ? 'profile.people.emptyFollowers' : 'profile.people.emptyFollowing') | transloco" data-people-empty />
              }
            }
            @if (store.loadingMore()) {
              <div class="flex items-center gap-3 border-t border-border px-4 py-3 lg:px-5" aria-hidden="true">
                <div class="rd-skeleton h-10 w-10 shrink-0 rounded-full"></div>
                <div class="flex flex-1 flex-col gap-2"><div class="rd-skeleton h-3 w-1/2"></div><div class="rd-skeleton h-3 w-1/3"></div></div>
              </div>
            }
            @if (store.loadMoreFailed()) {
              <div class="border-t border-border py-4 text-center">
                <button type="button" class="rd-btn rd-btn-outline" (click)="store.loadMore()">{{ 'common.retry' | transloco }}</button>
              </div>
            }
            @if (store.nextCursor()) {
              <!-- Only under a loaded list: one on screen beside the skeletons would load page 2 right away. -->
              <div #sentinel class="h-px" aria-hidden="true"></div>
            } @else if (store.items().length > 0) {
              <p class="m-0 border-t border-border py-6 text-center text-sm text-text-secondary">{{ 'profile.people.end' | transloco }}</p>
            }
          }
          @default {
            <div class="flex flex-col gap-3 px-4 py-3 lg:px-5" aria-busy="true">
              @for (i of [1, 2, 3, 4, 5]; track i) {
                <div class="flex items-center gap-3 py-1" aria-hidden="true">
                  <div class="rd-skeleton h-10 w-10 shrink-0 rounded-full"></div>
                  <div class="flex flex-1 flex-col gap-2"><div class="rd-skeleton h-3 w-1/2"></div><div class="rd-skeleton h-3 w-1/3"></div></div>
                  <div class="rd-skeleton h-11 w-24"></div>
                </div>
              }
            </div>
          }
        }
      </section>
    } @else if (notFound()) {
      <rd-empty-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [title]="'profile.notFound.title' | transloco" [message]="'profile.notFound.body' | transloco" data-profile-not-found>
        <a routerLink="/" class="rd-btn rd-btn-primary mt-3">{{ 'comingSoon.backHome' | transloco }}</a>
      </rd-empty-state>
    } @else if (resource.status() === 'error') {
      <rd-error-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [message]="'profile.loadError' | transloco" (retry)="resource.reload()" />
    } @else {
      <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 flex flex-col gap-3 p-4 lg:p-5" aria-busy="true">
        <div class="rd-skeleton h-5 w-1/2"></div>
        <div class="rd-skeleton h-8 w-1/3"></div>
        <div class="rd-skeleton h-11 w-full"></div>
      </div>
    }
  `,
})
export class PeoplePage {
  private readonly api = inject(ProfilesApi);
  private readonly transloco = inject(TranslocoService);
  private readonly title = inject(Title);
  protected readonly store = inject(PeopleStore);
  protected readonly lang = inject(LanguageService).lang;
  protected readonly lists = LISTS;
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');

  /** Route params (`/@{username}/{list}`). */
  readonly username = input.required<string>();
  readonly list = input<PeopleList>('followers');

  protected readonly resource = httpResource<ProfileDto>(() => ({
    url: this.api.profileUrl(this.username()),
    context: new HttpContext().set(SILENT_ERRORS, true),
  }));
  protected readonly profile = computed(() => (this.resource.hasValue() ? this.resource.value() : null));
  protected readonly notFound = computed(() => {
    const error = this.resource.error();
    return isApiError(error) && error.status === 404;
  });
  protected readonly searchText = signal('');
  private searchTimer: ReturnType<typeof setTimeout> | null = null;

  constructor() {
    const isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
    effect(() => {
      const p = this.profile();
      const list = this.list();
      if (p) this.title.setTitle(`${this.transloco.translate(list === 'followers' ? 'profile.people.titleFollowers' : 'profile.people.titleFollowing', { name: p.displayName })} — ReadIn`);
      if (!p || !isBrowser) return;
      untracked(() => {
        this.cancelSearch();
        this.searchText.set('');
        void this.store.open(p.id, list);
      });
    });
    loadMoreNearEnd(
      () => this.sentinel()?.nativeElement,
      () => void this.store.loadMore(),
    );
    inject(DestroyRef).onDestroy(() => this.cancelSearch());
  }

  protected onSearchInput(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    this.searchText.set(value);
    this.cancelSearch();
    // Clearing the box (or its ✕) searches at once; typing waits for a pause.
    if (!value) this.store.setQuery('');
    else this.searchTimer = setTimeout(() => this.store.setQuery(value), PEOPLE_SEARCH_DEBOUNCE_MS);
  }

  protected searchNow(): void {
    this.cancelSearch();
    this.store.setQuery(this.searchText());
  }

  private cancelSearch(): void {
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = null;
  }
}

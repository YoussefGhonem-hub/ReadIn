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
 * (debounced), infinite scroll, a Follow button per row; a row opens that profile. The server renders the header; the
 * list loads in the browser, where your Follow state is known.
 */
@Component({
  selector: 'rd-people-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, CompactNumberPipe, Avatar, UserRow, FollowButton, EmptyState, ErrorState],
  providers: [PeopleStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pt-5 lg:pt-8' },
  template: `
    @if (profile(); as p) {
      <header class="mb-4">
        <a [routerLink]="'/@' + p.username" class="-ms-1 inline-flex min-h-11 min-w-0 items-center gap-2 rounded-md px-1 text-sm text-text-secondary no-underline hover:text-text-primary" data-back-to-profile>
          <svg lucideIcon="ArrowRight" [size]="18" class="shrink-0 ltr:rotate-180" aria-hidden="true"></svg>
          <span class="sr-only">{{ 'profile.people.backToProfile' | transloco }}:</span>
          <rd-avatar [name]="p.displayName" [src]="p.avatarUrl" [size]="28" />
          <rd-bdi-text class="truncate font-semibold text-text-primary" [text]="p.displayName" />
          <bdi dir="ltr" class="shrink-0">&#64;{{ p.username }}</bdi>
        </a>
        <h1 class="m-0 mt-2 text-2xl font-bold">{{ 'profile.people.' + list() | transloco }}</h1>
      </header>

      <nav class="mb-4 flex gap-5 border-b border-border" [attr.aria-label]="'profile.people.label' | transloco" data-people-lists>
        @for (l of lists; track l) {
          <a
            [routerLink]="['/@' + p.username, l]"
            replaceUrl
            class="-mb-px inline-flex min-h-11 items-center gap-1.5 border-b-2 px-1 text-sm no-underline"
            [class]="l === list() ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary'"
            [attr.aria-current]="l === list() ? 'page' : null"
            [attr.data-people-list]="l"
          >
            {{ 'profile.people.' + l | transloco }}
            <span class="text-xs opacity-80">{{ (l === 'followers' ? p.stats.followers : p.stats.following) | rdCompactNumber: lang() }}</span>
          </a>
        }
      </nav>

      <div class="relative mb-2" role="search">
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

      <section [attr.aria-label]="'profile.people.' + list() | transloco" aria-live="polite" data-people>
        @switch (store.status()) {
          @case ('error') {
            <rd-error-state [message]="'profile.people.loadError' | transloco" (retry)="store.load()" />
          }
          @case ('loaded') {
            <ul class="m-0 list-none divide-y divide-border p-0">
              @for (user of store.items(); track user.id) {
                <li data-person [attr.data-user]="user.id">
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
              <div class="flex items-center gap-3 py-3" aria-hidden="true">
                <div class="rd-skeleton h-10 w-10 shrink-0 rounded-full"></div>
                <div class="flex flex-1 flex-col gap-2"><div class="rd-skeleton h-3 w-1/2"></div><div class="rd-skeleton h-3 w-1/3"></div></div>
              </div>
            }
            @if (store.loadMoreFailed()) {
              <div class="py-4 text-center">
                <button type="button" class="rd-btn rd-btn-outline" (click)="store.loadMore()">{{ 'common.retry' | transloco }}</button>
              </div>
            }
            @if (store.items().length > 0 && !store.nextCursor()) {
              <p class="py-6 text-center text-sm text-text-secondary">{{ 'profile.people.end' | transloco }}</p>
            }
          }
          @default {
            <div class="flex flex-col gap-3 py-2" aria-busy="true">
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
        <div #sentinel class="h-px" aria-hidden="true"></div>
      </section>
    } @else if (notFound()) {
      <rd-empty-state [title]="'profile.notFound.title' | transloco" [message]="'profile.notFound.body' | transloco" data-profile-not-found>
        <a routerLink="/" class="rd-btn rd-btn-primary mt-3">{{ 'comingSoon.backHome' | transloco }}</a>
      </rd-empty-state>
    } @else if (resource.status() === 'error') {
      <rd-error-state [message]="'profile.loadError' | transloco" (retry)="resource.reload()" />
    } @else {
      <div class="flex flex-col gap-3" aria-busy="true">
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

import {
  ChangeDetectionStrategy,
  Component,
  DOCUMENT,
  DestroyRef,
  ElementRef,
  Injector,
  PLATFORM_ID,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { NgTemplateOutlet, isPlatformBrowser } from '@angular/common';
import { Meta } from '@angular/platform-browser';
import { ActivatedRoute, NavigationCancel, NavigationEnd, NavigationError, NavigationStart, Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { isApiError } from '../../core/api/api.config';
import { SearchType } from '../../core/api/models';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { isolate } from '../../shared/directives/bidi';
import { PluralPipe } from '../../shared/pipes/format.pipes';
import { FollowButton } from '../../shared/social/follow-button';
import { UserRow } from '../../shared/social/user-row';
import { ArticleCard } from '../../shared/ui/article-card';
import { FieldIcon } from '../../shared/ui/field-icon';
import { ArticleCardSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { tagLink } from '../../shared/ui/tag-link';
import { loadMoreNearEnd } from '../profile/infinite-scroll';
import { RecentSearches } from './recent-searches';
import { SearchFilterBar, SearchFilterPatch } from './search-filters';
import { provideSearchIcons } from './search-icons';
import {
  INPUT_MAX_LENGTH,
  MIN_TYPED_LENGTH,
  SEARCH_DEBOUNCE_MS,
  SEARCH_TYPES,
  SearchUrl,
  cleanSearchQuery,
  fieldColorOf,
  parseType,
  searchQueryParams,
  searchRequestOf,
  topicRoute,
} from './search-query';
import { SearchStore } from './search.store';

/** The page's path, for its `noindex` (search results are never indexed). */
const SEARCH_PATH = /^\/search(?:[?#]|$)/;

/**
 * Search (F16), `/search?q=&type=&field=&lang=&time=`: a search box (as you type from 2 characters, 300 ms after the
 * last key; Enter from 1), tabs for Articles, Writers, Topics and Tags, and on Articles the field, language and
 * reading-time filters. Articles show as compact rows (F34) that say when only the attached PDF matched; writers with
 * Follow; topics open the field page (F15); tags the tag page (F32). Loading skeletons, an empty state with a tip,
 * an error with Retry and infinite scroll. With no query: your recent searches on this device.
 *
 * Everything is in the URL (typing replaces the entry, so Back leaves the page), and the page stays alive while you
 * open a result: Back brings it back as you left it (features/feed/feed-route-reuse.ts). Server-rendered without
 * results (they are personal, and the rate limit counts per IP): the browser searches once hydrated. `noindex`.
 */
@Component({
  selector: 'rd-search-page',
  imports: [
    NgTemplateOutlet,
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    BdiText,
    PluralPipe,
    ArticleCard,
    ArticleCardSkeleton,
    UserRow,
    FollowButton,
    FieldIcon,
    EmptyState,
    ErrorState,
    SearchFilterBar,
  ],
  providers: [SearchStore, provideSearchIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  // Opening a result (any link in the results, also by keyboard) keeps the query in your recent searches.
  host: { class: 'mx-auto block max-w-[720px] px-4 pt-4 lg:pt-8', '(click)': 'onResultsClick($event)' },
  // The box has its own ✕ on the side of the page's direction; the browser's sits wherever the typed text starts.
  styles: `
    input::-webkit-search-cancel-button {
      display: none;
    }
  `,
  template: `
    <h1 class="sr-only">{{ 'nav.search' | transloco }}</h1>
    <form role="search" class="relative" (submit)="$event.preventDefault(); submit()">
      <svg lucideIcon="Search" [size]="20" class="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 text-text-secondary" aria-hidden="true"></svg>
      <!-- Empty, the placeholder follows the page; typed, the text keeps its own direction (both sides padded for either). -->
      <input
        #box
        id="search-input"
        type="search"
        class="rd-input min-h-12 px-11 text-base"
        [attr.dir]="text() ? 'auto' : null"
        autocomplete="off"
        autocapitalize="off"
        spellcheck="false"
        enterkeyhint="search"
        data-search-input
        [maxLength]="inputMaxLength"
        [attr.aria-label]="'search.label' | transloco"
        [placeholder]="'search.placeholder' | transloco"
        [value]="text()"
        (input)="onInput($event)"
      />
      @if (text()) {
        <button
          type="button"
          class="absolute end-1 top-1/2 grid h-10 w-10 -translate-y-1/2 place-items-center rounded-md text-text-secondary hover:bg-surface-variant hover:text-text-primary"
          [attr.aria-label]="'search.clear' | transloco"
          data-search-clear
          (click)="clearBox()"
        >
          <svg lucideIcon="X" [size]="18" aria-hidden="true"></svg>
        </button>
      }
    </form>

    @if (request(); as r) {
      <div class="-mx-4 mt-3 flex gap-5 overflow-x-auto border-b border-border px-4" role="tablist" [attr.aria-label]="'search.tabs.label' | transloco" data-search-tabs>
        @for (t of types; track t) {
          <button
            type="button"
            role="tab"
            [id]="'search-tab-' + t"
            aria-controls="search-panel"
            [attr.aria-selected]="r.type === t"
            [attr.tabindex]="r.type === t ? 0 : -1"
            [attr.data-search-tab]="t"
            class="-mb-px min-h-11 shrink-0 border-b-2 px-1 text-sm"
            [class]="r.type === t ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary'"
            (click)="selectType(t)"
            (keydown)="onTabKey($event)"
          >
            {{ 'search.tabs.' + t | transloco }}
          </button>
        }
      </div>
      @if (r.type === 'articles') {
        <rd-search-filters [request]="r" (changed)="setFilters($event)" />
      }

      <section
        id="search-panel"
        role="tabpanel"
        class="block"
        [class.pt-2]="r.type !== 'articles'"
        [attr.aria-labelledby]="'search-tab-' + r.type"
        [attr.aria-busy]="store.status() === 'loading' || null"
        [attr.data-status]="store.status()"
        data-search-results
      >
        @switch (store.status()) {
          @case ('loaded') {
            @if (store.count()) {
              @switch (r.type) {
                @case ('articles') {
                  <div>
                    @for (result of store.articles(); track result.article.id) {
                      <rd-article-card [article]="result.article" [withAttachments]="false" data-search-article [attr.data-article]="result.article.id" [attr.data-matched-in]="result.matchedIn">
                        @if (result.matchedIn === 'attachment') {
                          <p rdCardFooter class="m-0 ms-[84px] mt-1.5 flex items-center gap-1.5 text-xs font-semibold text-primary" data-in-attachment>
                            <svg lucideIcon="FileText" [size]="14" class="shrink-0" aria-hidden="true"></svg>
                            {{ 'search.inAttachment' | transloco }}
                          </p>
                        }
                      </rd-article-card>
                    }
                  </div>
                }
                @case ('users') {
                  <ul class="m-0 list-none divide-y divide-border p-0">
                    @for (user of store.users(); track user.id) {
                      <li data-search-user [attr.data-user]="user.username">
                        <rd-user-row [user]="user" [bio]="user.bio" [note]="user.followsYou ? ('profile.followsYou' | transloco) : null">
                          <rd-follow-button [user]="user" [initial]="user.isFollowing" />
                        </rd-user-row>
                      </li>
                    }
                  </ul>
                }
                @case ('topics') {
                  <ul class="m-0 list-none divide-y divide-border p-0">
                    @for (topic of store.topics(); track topic.kind + ':' + topic.id) {
                      @let route = topicRoute(topic);
                      @let color = fieldColor(topic.color);
                      <li>
                        <a
                          [routerLink]="route.commands"
                          [queryParams]="route.queryParams"
                          class="flex min-h-14 items-center gap-3 rounded-md py-2 text-inherit no-underline hover:bg-surface-variant"
                          data-search-topic
                          [attr.data-kind]="topic.kind"
                        >
                          <span
                            class="grid h-10 w-10 shrink-0 place-items-center rounded-full"
                            [style.background-color]="'color-mix(in srgb, ' + color + ' 14%, transparent)'"
                            [style.color]="color"
                            aria-hidden="true"
                            ><rd-field-icon [name]="topic.icon" [size]="20"
                          /></span>
                          <span class="min-w-0 flex-1">
                            <span class="block truncate font-semibold text-text-primary"><rd-bdi-text [text]="uiLang() === 'ar' ? topic.nameAr : topic.nameEn" /></span>
                            <span class="block text-xs text-text-secondary">
                              {{ topic.kind === 'field' ? ('search.topic.field' | transloco) : ('search.topic.inField' | transloco: { field: isolate(topic.fieldName) }) }}
                              · {{ topic.articleCount | rdPlural: 'reading.articles' : uiLang() }}
                            </span>
                          </span>
                          <svg lucideIcon="ChevronRight" [size]="18" class="rd-flip-rtl shrink-0 text-text-secondary" aria-hidden="true"></svg>
                        </a>
                      </li>
                    }
                  </ul>
                }
                @case ('tags') {
                  <ul class="m-0 list-none divide-y divide-border p-0">
                    @for (tag of store.tags(); track tag.slug) {
                      <li>
                        <a
                          [routerLink]="tagLink(tag)"
                          class="flex min-h-12 items-center gap-3 rounded-md py-2 text-inherit no-underline hover:bg-surface-variant"
                          data-search-tag
                          [attr.data-tag]="tag.slug"
                        >
                          <!-- The row follows the page; only the name keeps its own direction (an English tag starts on the page's side). -->
                          <span class="min-w-0 flex-1 truncate font-semibold text-text-primary"><bdi dir="auto">#{{ tag.name }}</bdi></span>
                          <span class="shrink-0 text-xs text-text-secondary">{{ tag.articleCount | rdPlural: 'reading.articles' : uiLang() }}</span>
                        </a>
                      </li>
                    }
                  </ul>
                }
              }
              @if (store.loadingMore()) {
                <ng-container *ngTemplateOutlet="skeleton; context: { $implicit: r.type, count: 1 }" />
              }
              @if (store.loadMoreFailed()) {
                <div class="py-4 text-center">
                  <button type="button" class="rd-btn rd-btn-outline" data-search-load-more-retry (click)="store.loadMore()">{{ 'common.retry' | transloco }}</button>
                </div>
              }
              @if (store.nextCursor()) {
                <!-- Only under a loaded list: one on screen beside the skeletons would load page 2 right away. -->
                <div #sentinel class="h-px" aria-hidden="true"></div>
              } @else {
                <p class="m-0 py-6 text-center text-sm text-text-secondary" data-search-end>{{ 'search.end' | transloco }}</p>
              }
            } @else if (store.hasFilters()) {
              <rd-empty-state [title]="'search.empty.filteredTitle' | transloco" [message]="'search.empty.filteredBody' | transloco: { q: isolate(r.q) }" data-search-empty="filtered">
                <button type="button" class="rd-btn rd-btn-outline mt-3" (click)="setFilters({ field: null, lang: null, time: null })">{{ 'search.filters.clear' | transloco }}</button>
              </rd-empty-state>
            } @else {
              <rd-empty-state [title]="'search.empty.title' | transloco: { q: isolate(r.q) }" [message]="'search.empty.body' | transloco" data-search-empty />
            }
          }
          @case ('invalid') {
            <rd-empty-state [title]="'search.invalid' | transloco" data-search-invalid />
          }
          @case ('error') {
            <rd-error-state [message]="errorMessage()" (retry)="store.load()" data-search-error />
          }
          @default {
            <ng-container *ngTemplateOutlet="skeleton; context: { $implicit: r.type, count: 4 }" />
          }
        }
      </section>
      <p class="sr-only" aria-live="polite" data-search-announce>{{ announcement() }}</p>
    } @else if (ready()) {
      <!-- No query: your recent searches, or where to start. Only in the browser: they live on this device. -->
      @if (recent.items().length) {
        <section class="pt-4" aria-labelledby="recent-searches-title" data-recent-searches>
          <div class="flex items-center justify-between gap-2">
            <h2 id="recent-searches-title" class="m-0 text-sm font-semibold text-text-secondary">{{ 'search.recent.title' | transloco }}</h2>
            <button type="button" class="rd-btn rd-btn-ghost min-h-11 px-2 text-sm" data-recent-clear (click)="clearRecent()">{{ 'search.recent.clearAll' | transloco }}</button>
          </div>
          <ul class="m-0 list-none p-0">
            @for (item of recent.items(); track item) {
              <li class="flex items-center gap-1" [attr.data-recent]="item">
                <button
                  type="button"
                  class="flex min-h-11 min-w-0 flex-1 items-center gap-3 rounded-md px-2 text-start text-text-primary hover:bg-surface-variant"
                  data-recent-open
                  (click)="openRecent(item)"
                >
                  <svg lucideIcon="History" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
                  <bdi dir="auto" class="truncate">{{ item }}</bdi>
                </button>
                <button
                  type="button"
                  class="grid h-11 w-11 shrink-0 place-items-center rounded-md text-text-secondary hover:bg-surface-variant hover:text-text-primary"
                  [attr.aria-label]="'search.recent.remove' | transloco: { q: isolate(item) }"
                  data-recent-remove
                  (click)="removeRecent(item)"
                >
                  <svg lucideIcon="X" [size]="18" aria-hidden="true"></svg>
                </button>
              </li>
            }
          </ul>
        </section>
      } @else {
        <section class="flex flex-col items-center gap-2 px-6 py-12 text-center" data-search-start>
          <span class="mb-2 grid h-14 w-14 place-items-center rounded-card bg-primary-container text-on-primary-container" aria-hidden="true">
            <svg lucideIcon="Search" [size]="26"></svg>
          </span>
          <h2 class="m-0 text-lg font-semibold">{{ 'search.idle.title' | transloco }}</h2>
          <p class="m-0 max-w-sm text-sm text-text-secondary">{{ 'search.idle.body' | transloco }}</p>
          <p class="m-0 max-w-sm text-sm text-text-secondary">{{ 'search.idle.tip' | transloco }}</p>
        </section>
      }
    }

    <ng-template #skeleton let-type let-count="count">
      <div aria-hidden="true" data-search-loading>
        @for (i of rows(count); track i) {
          @if (type === 'articles') {
            <rd-article-card-skeleton />
          } @else {
            <div class="flex items-center gap-3 border-t border-border py-3 first:border-t-0">
              @if (type !== 'tags') {
                <div class="rd-skeleton h-10 w-10 shrink-0 rounded-full"></div>
              }
              <div class="flex flex-1 flex-col gap-2">
                <div class="rd-skeleton h-3 w-1/2"></div>
                <div class="rd-skeleton h-3 w-1/3"></div>
              </div>
              @if (type === 'users') {
                <div class="rd-skeleton h-11 w-24"></div>
              }
            </div>
          }
        }
      </div>
    </ng-template>
  `,
})
export class SearchPage {
  protected readonly store = inject(SearchStore);
  protected readonly recent = inject(RecentSearches);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly transloco = inject(TranslocoService);
  private readonly messages = inject(ErrorMessages);
  private readonly injector = inject(Injector);
  private readonly document = inject(DOCUMENT);
  private readonly language = inject(LanguageService);
  protected readonly uiLang = this.language.lang;
  private readonly box = viewChild<ElementRef<HTMLInputElement>>('box');
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');

  /** Query parameters (component input binding). */
  readonly q = input<string>();
  readonly type = input<string>();
  readonly field = input<string>();
  readonly lang = input<string>();
  readonly time = input<string>();

  protected readonly types = SEARCH_TYPES;
  protected readonly inputMaxLength = INPUT_MAX_LENGTH;
  protected readonly topicRoute = topicRoute;
  protected readonly tagLink = tagLink;
  protected readonly isolate = isolate;
  protected readonly fieldColor = fieldColorOf;

  /** The search the URL asks for (null: no query). */
  protected readonly request = computed(() =>
    searchRequestOf({ q: this.q(), type: this.type(), field: this.field(), lang: this.lang(), time: this.time() }),
  );
  /** What the box shows: the URL's query, or what you are typing. */
  protected readonly text = signal('');
  /** In the browser after the first render: recent searches can show (the server has none). */
  protected readonly ready = signal(false);

  protected readonly errorMessage = computed(() => {
    this.uiLang();
    const error = this.store.error();
    return isApiError(error) && (error.code === 'rate_limited' || error.code === 'search.filter_invalid')
      ? this.messages.forError(error)
      : this.transloco.translate('search.loadError');
  });
  /** Said politely to screen readers when results arrive. */
  protected readonly announcement = computed(() => {
    this.uiLang();
    const request = this.request();
    if (!request || this.store.status() !== 'loaded') return '';
    if (!this.store.count()) return this.transloco.translate(this.store.hasFilters() ? 'search.empty.filteredTitle' : 'search.empty.title', { q: isolate(request.q) });
    return this.transloco.translate('search.results', { q: isolate(request.q) });
  });

  private timer: ReturnType<typeof setTimeout> | null = null;
  /** The query this page last put in the URL while you typed: its echo must not overwrite the box. */
  private sentQuery: string | null = null;

  constructor() {
    const isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

    effect(() => {
      const request = this.request();
      untracked(() => this.store.open(request));
    });
    // The box follows the URL (Back, a recent search, the header box), not the echo of what you are typing.
    effect(() => {
      const q = this.q() ?? '';
      untracked(() => {
        if (this.sentQuery !== null && cleanSearchQuery(q) === this.sentQuery) {
          this.sentQuery = null;
          return;
        }
        this.sentQuery = null;
        this.cancelTimer();
        this.text.set(q);
        const box = this.box()?.nativeElement;
        if (box && box.value !== q) box.value = q;
      });
    });

    // Your follow, reaction and save state: the results again when you sign in or out.
    const session = inject(SessionStore);
    const viewer = computed(() => (session.isResolved() ? (session.isAuthenticated() ? (session.me()?.id ?? 'user') : 'guest') : null));
    let shownFor: string | null = null;
    effect(() => {
      const current = viewer();
      untracked(() => {
        if (current === null) return;
        if (shownFor !== null && shownFor !== current) void this.store.refresh();
        shownFor = current;
      });
    });

    loadMoreNearEnd(
      () => this.sentinel()?.nativeElement,
      () => void this.store.loadMore(),
    );
    this.keepNoindex();

    const destroyRef = inject(DestroyRef);
    destroyRef.onDestroy(() => this.cancelTimer());
    if (isBrowser) {
      afterNextRender(() => {
        this.ready.set(true);
        // An empty search page is for typing.
        if (!this.request()) this.box()?.nativeElement.focus();
      });
    }
  }

  protected rows(count: number): number[] {
    return Array.from({ length: count }, (_, i) => i);
  }

  protected onInput(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    this.text.set(value);
    this.cancelTimer();
    const q = cleanSearchQuery(value);
    // Emptying the box (or its ✕) goes back to your recent searches at once; typing waits for a pause.
    if (!q) return this.go({ q: null }, true);
    if (q.length < MIN_TYPED_LENGTH) return;
    this.timer = setTimeout(() => this.go({ q }, true), SEARCH_DEBOUNCE_MS);
  }

  /** The ✕: back to your recent searches, ready to type. */
  protected clearBox(): void {
    this.cancelTimer();
    this.text.set('');
    const box = this.box()?.nativeElement;
    if (box) {
      box.value = '';
      box.focus();
    }
    this.go({ q: null }, true);
  }

  /** Enter: searches what is typed now (from 1 character) and keeps it in your recent searches. */
  protected submit(): void {
    this.cancelTimer();
    const q = cleanSearchQuery(this.text());
    if (!q) return;
    this.recent.add(q);
    if (q === this.request()?.q) {
      if (this.store.status() === 'error') void this.store.load();
      return;
    }
    this.go({ q }, true);
  }

  protected selectType(type: SearchType): void {
    if (type !== this.request()?.type) this.go({ type });
  }

  /** Arrow keys, Home and End move between the tabs (arrows mirror in RTL). */
  protected onTabKey(event: KeyboardEvent): void {
    const index = SEARCH_TYPES.indexOf(this.request()?.type ?? 'articles');
    const rtl = this.language.dir() === 'rtl';
    const step = { ArrowRight: rtl ? -1 : 1, ArrowLeft: rtl ? 1 : -1 }[event.key];
    let next: number | null = null;
    if (step) next = (index + step + SEARCH_TYPES.length) % SEARCH_TYPES.length;
    else if (event.key === 'Home') next = 0;
    else if (event.key === 'End') next = SEARCH_TYPES.length - 1;
    if (next === null) return;
    event.preventDefault();
    const type = SEARCH_TYPES[next];
    this.selectType(type);
    afterNextRender(() => this.document.getElementById(`search-tab-${type}`)?.focus(), { injector: this.injector });
  }

  protected setFilters(patch: SearchFilterPatch): void {
    this.go(patch);
  }

  protected openRecent(query: string): void {
    this.recent.add(query);
    this.go({ q: cleanSearchQuery(query) });
  }

  protected removeRecent(query: string): void {
    this.recent.remove(query);
    // Focus stays in the list: on the next search, or the box when none is left.
    afterNextRender(
      () => {
        const next = this.document.querySelector<HTMLElement>('[data-recent-open]');
        (next ?? this.box()?.nativeElement)?.focus();
      },
      { injector: this.injector },
    );
  }

  protected clearRecent(): void {
    this.recent.clear();
    afterNextRender(() => this.box()?.nativeElement.focus(), { injector: this.injector });
  }

  /** A result opened from this search: the query goes to the top of your recent searches. */
  protected onResultsClick(event: MouseEvent): void {
    const request = this.request();
    if (request && (event.target as Element | null)?.closest?.('[data-search-results] a[href]')) this.recent.add(request.q);
  }

  /** The URL with `patch` applied, replacing this history entry (so Back leaves the search). */
  private go(patch: SearchUrl, typed = false): void {
    // The URL's own values, kept as they are (an unknown field slug stays chosen).
    const current: SearchUrl = {
      q: this.request()?.q ?? null,
      type: parseType(this.type()),
      field: this.field() || null,
      lang: (this.lang() || null) as SearchUrl['lang'],
      time: (this.time() || null) as SearchUrl['time'],
    };
    const next: SearchUrl = { ...current, ...patch };
    if (typed) this.sentQuery = next.q ?? '';
    void this.router.navigate([], { relativeTo: this.route, queryParams: searchQueryParams(next), replaceUrl: true });
  }

  private cancelTimer(): void {
    if (this.timer) clearTimeout(this.timer);
    this.timer = null;
  }

  /**
   * `noindex` while this page is shown, also when Back brings it back alive. Taken away as soon as you leave it, before
   * the next page sets its own.
   */
  private keepNoindex(): void {
    const meta = inject(Meta);
    const set = (on: boolean) => (on ? meta.updateTag({ name: 'robots', content: 'noindex' }, 'name="robots"') : meta.removeTag('name="robots"'));
    set(true);
    let shown = true;
    const subscription = this.router.events.subscribe((event) => {
      if (event instanceof NavigationStart && shown && !SEARCH_PATH.test(event.url)) {
        shown = false;
        set(false);
      } else if (event instanceof NavigationEnd || event instanceof NavigationCancel || event instanceof NavigationError) {
        const onSearch = SEARCH_PATH.test(this.router.url);
        if (onSearch && !shown) set(true);
        shown = onSearch;
      }
    });
    inject(DestroyRef).onDestroy(() => subscription.unsubscribe());
  }
}

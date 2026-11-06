import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, computed, inject, signal, viewChild } from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import { Router } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { SearchArticleDto, SearchSuggestionsDto, SearchTopicDto, TagDto, UserSummaryDto } from '../../core/api/models';
import { SearchApi } from '../../core/api/search.api';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { isolate } from '../../shared/directives/bidi';
import { PluralPipe, ReadingTimePipe } from '../../shared/pipes/format.pipes';
import { articleLink } from '../../shared/ui/article-link';
import { Avatar } from '../../shared/ui/avatar';
import { FieldIcon } from '../../shared/ui/field-icon';
import { tagLink } from '../../shared/ui/tag-link';
import { VerifiedBadge } from '../../shared/ui/verified-badge';
import { RecentSearches } from './recent-searches';
import { provideSearchIcons } from './search-icons';
import { INPUT_MAX_LENGTH, MIN_TYPED_LENGTH, SEARCH_DEBOUNCE_MS, cleanSearchQuery, fieldColorOf, isSearchable, topicRoute } from './search-query';

type HeaderOption =
  | { kind: 'recent'; key: string; q: string }
  | { kind: 'article'; key: string; result: SearchArticleDto }
  | { kind: 'user'; key: string; user: UserSummaryDto }
  | { kind: 'topic'; key: string; topic: SearchTopicDto }
  | { kind: 'tag'; key: string; tag: TagDto }
  | { kind: 'all'; key: string; q: string };

interface OptionGroup {
  id: 'recent' | 'articles' | 'users' | 'topics' | 'tags' | 'all';
  /** A heading inside the list (the suggestion types); recent searches have theirs above it. */
  label: string | null;
  options: { option: HeaderOption; index: number }[];
}

/**
 * The header's search box (F16), on wide screens; narrow ones have the search icon instead. Focused and empty, it
 * lists your recent searches (Delete or ✕ removes one). As you type (from 2 characters, 300 ms after the last key)
 * it suggests the first 3 articles, writers, topics and tags (`GET /search/suggest`), then "See all results"; Enter
 * opens the chosen suggestion, or the search page for what is typed (from 1 character). A combobox with a listbox,
 * driven from the keyboard. Loaded lazily by the top bar.
 */
@Component({
  selector: 'rd-header-search',
  imports: [NgTemplateOutlet, TranslocoPipe, LucideDynamicIcon, BdiText, PluralPipe, ReadingTimePipe, Avatar, FieldIcon, VerifiedBadge],
  providers: [provideSearchIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'relative block', 'data-header-search': '' },
  // Its own ✕ on the side of the page's direction; the browser's sits wherever the typed text starts.
  styles: `
    input::-webkit-search-cancel-button {
      display: none;
    }
  `,
  template: `
    <form role="search" class="relative" (submit)="$event.preventDefault()">
      <svg lucideIcon="Search" [size]="18" class="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 text-text-secondary" aria-hidden="true"></svg>
      <!-- Empty, the placeholder follows the page; typed, the text keeps its own direction (both sides padded for either). -->
      <input
        #field
        id="header-search"
        type="search"
        class="rd-input h-10 min-h-10 px-10 text-sm placeholder:text-text-secondary"
        [attr.dir]="text() ? 'auto' : null"
        autocomplete="off"
        autocapitalize="off"
        spellcheck="false"
        enterkeyhint="search"
        role="combobox"
        aria-autocomplete="list"
        [attr.aria-expanded]="open()"
        [attr.aria-controls]="open() ? listId : null"
        [attr.aria-activedescendant]="open() && active() >= 0 ? listId + '-' + active() : null"
        [attr.aria-label]="'search.label' | transloco"
        [placeholder]="'search.headerPlaceholder' | transloco"
        [maxLength]="inputMaxLength"
        [value]="text()"
        data-header-search-input
        (input)="onInput($event)"
        (keydown)="onKeydown($event)"
        (focus)="listOpen.set(true)"
        (blur)="close()"
      />
      @if (text()) {
        <button
          type="button"
          tabindex="-1"
          class="absolute end-1 top-1/2 grid h-8 w-8 -translate-y-1/2 place-items-center rounded-md text-text-secondary hover:bg-surface-variant hover:text-text-primary"
          [attr.aria-label]="'search.clear' | transloco"
          data-header-search-clear
          (mousedown)="$event.preventDefault()"
          (click)="clearBox()"
        >
          <svg lucideIcon="X" [size]="16" aria-hidden="true"></svg>
        </button>
      }
    </form>
    @if (open()) {
      <!-- mousedown keeps the focus in the box, so a click picks an option instead of closing the list first. -->
      <div
        class="absolute start-0 top-full z-40 mt-2 w-[min(34rem,calc(100vw-2rem))] overflow-hidden rounded-card border border-border bg-surface-raised shadow-raised"
        data-header-search-popup
        (mousedown)="$event.preventDefault()"
      >
        @if (mode() === 'recent') {
          <div class="flex items-center justify-between gap-2 ps-3 pe-1 pt-1">
            <span class="text-xs font-semibold text-text-secondary">{{ 'search.recent.title' | transloco }}</span>
            <button type="button" tabindex="-1" class="min-h-9 rounded-md px-2 text-xs font-semibold text-primary hover:bg-surface-variant" data-header-recent-clear (click)="clearRecent()">
              {{ 'search.recent.clearAll' | transloco }}
            </button>
          </div>
        } @else if (pending() || (settled() && !hasSuggestions())) {
          <p class="m-0 px-3 pt-2 text-xs text-text-secondary" data-header-search-status>
            {{ (pending() ? 'search.suggest.searching' : 'search.suggest.none') | transloco }}
          </p>
        }
        <div [id]="listId" role="listbox" class="max-h-[70vh] overflow-y-auto p-1" [attr.aria-label]="(mode() === 'recent' ? 'search.recent.title' : 'search.suggest.label') | transloco" data-header-search-list>
          @for (group of groups(); track group.id) {
            @if (group.label) {
              <div role="group" [attr.aria-labelledby]="listId + '-' + group.id" [attr.data-group]="group.id">
                <div [id]="listId + '-' + group.id" class="px-2 pb-1 pt-2 text-xs font-semibold text-text-secondary">{{ group.label | transloco }}</div>
                @for (entry of group.options; track entry.option.key) {
                  <ng-container *ngTemplateOutlet="optionTpl; context: { $implicit: entry }" />
                }
              </div>
            } @else {
              @for (entry of group.options; track entry.option.key) {
                <ng-container *ngTemplateOutlet="optionTpl; context: { $implicit: entry }" />
              }
            }
          }
        </div>
      </div>
    }

    <ng-template #optionTpl let-entry>
      @let option = asOption(entry.option);
      <div
        role="option"
        [id]="listId + '-' + entry.index"
        [attr.aria-selected]="entry.index === active()"
        class="flex min-h-11 cursor-pointer items-center gap-3 rounded-md px-2 py-1.5 text-sm text-text-primary"
        [class.bg-surface-variant]="entry.index === active()"
        [attr.data-option]="option.kind"
        tabindex="-1"
        (mousemove)="active.set(entry.index)"
        (click)="choose(option)"
        (keydown.enter)="choose(option)"
      >
        @switch (option.kind) {
          @case ('recent') {
            <svg lucideIcon="History" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
            <bdi dir="auto" class="min-w-0 flex-1 truncate" [attr.data-recent-option]="option.q">{{ option.q }}</bdi>
            <button
              type="button"
              tabindex="-1"
              class="-me-1 grid h-9 w-9 shrink-0 place-items-center rounded-md text-text-secondary hover:bg-surface hover:text-text-primary"
              [attr.aria-label]="'search.recent.remove' | transloco: { q: isolate(option.q) }"
              data-header-recent-remove
              (click)="$event.stopPropagation(); removeRecent(option.q)"
            >
              <svg lucideIcon="X" [size]="16" aria-hidden="true"></svg>
            </button>
          }
          @case ('article') {
            <span class="grid h-9 w-9 shrink-0 place-items-center rounded-md bg-primary-container text-on-primary-container" aria-hidden="true">
              <svg lucideIcon="FileText" [size]="18"></svg>
            </span>
            <span class="min-w-0 flex-1">
              <span class="block truncate font-semibold"><rd-bdi-text [text]="option.result.article.title" /></span>
              <span class="block truncate text-xs text-text-secondary">
                @if (option.result.matchedIn === 'attachment') {
                  {{ 'search.inAttachment' | transloco }}
                } @else {
                  @if (option.result.article.author; as author) {
                    <rd-bdi-text [text]="author.displayName" /> ·
                  }
                  {{ option.result.article.readingTimeMinutes | rdReadingTime: lang() }}
                }
              </span>
            </span>
          }
          @case ('user') {
            <rd-avatar [name]="option.user.displayName" [src]="option.user.avatarUrl" [size]="36" />
            <span class="min-w-0 flex-1">
              <span class="flex items-center gap-1 font-semibold">
                <rd-bdi-text class="truncate" [text]="option.user.displayName" />
                @if (option.user.isVerified) {
                  <rd-verified-badge [size]="14" />
                }
              </span>
              <span class="block text-xs text-text-secondary"><bdi dir="ltr">&#64;{{ option.user.username }}</bdi></span>
            </span>
          }
          @case ('topic') {
            @let color = fieldColor(option.topic.color);
            <span
              class="grid h-9 w-9 shrink-0 place-items-center rounded-full"
              [style.background-color]="'color-mix(in srgb, ' + color + ' 14%, transparent)'"
              [style.color]="color"
              aria-hidden="true"
              ><rd-field-icon [name]="option.topic.icon" [size]="18"
            /></span>
            <span class="min-w-0 flex-1">
              <span class="block truncate font-semibold"><rd-bdi-text [text]="lang() === 'ar' ? option.topic.nameAr : option.topic.nameEn" /></span>
              <span class="block truncate text-xs text-text-secondary">
                {{ option.topic.kind === 'field' ? ('search.topic.field' | transloco) : ('search.topic.inField' | transloco: { field: isolate(option.topic.fieldName) }) }}
              </span>
            </span>
          }
          @case ('tag') {
            <span class="grid h-9 w-9 shrink-0 place-items-center rounded-md bg-surface-variant font-bold text-text-secondary" aria-hidden="true">#</span>
            <!-- The row follows the page; only the name keeps its own direction. -->
            <span class="min-w-0 flex-1 truncate font-semibold"><bdi dir="auto">#{{ option.tag.name }}</bdi></span>
            <span class="shrink-0 text-xs text-text-secondary">{{ option.tag.articleCount | rdPlural: 'reading.articles' : lang() }}</span>
          }
          @case ('all') {
            <span class="grid h-9 w-9 shrink-0 place-items-center rounded-md text-primary" aria-hidden="true">
              <svg lucideIcon="Search" [size]="18"></svg>
            </span>
            <span class="min-w-0 flex-1 font-semibold text-primary" data-header-search-all>
              {{ 'search.suggest.seeAll' | transloco: { q: isolate(option.q) } }}
            </span>
          }
        }
      </div>
    </ng-template>
  `,
})
export class HeaderSearch {
  private readonly api = inject(SearchApi);
  private readonly router = inject(Router);
  protected readonly recent = inject(RecentSearches);
  protected readonly lang = inject(LanguageService).lang;
  private readonly field = viewChild.required<ElementRef<HTMLInputElement>>('field');

  protected readonly listId = 'header-search-list';
  protected readonly inputMaxLength = INPUT_MAX_LENGTH;
  protected readonly fieldColor = fieldColorOf;
  protected readonly isolate = isolate;

  protected readonly text = signal('');
  protected readonly listOpen = signal(false);
  protected readonly active = signal(-1);
  /** The last suggestions, and the cleaned query they are for. */
  private readonly results = signal<SearchSuggestionsDto | null>(null);
  private readonly lookedUp = signal<string | null>(null);

  private readonly cleaned = computed(() => cleanSearchQuery(this.text()));
  protected readonly mode = computed<'recent' | 'suggest'>(() => (this.cleaned() ? 'suggest' : 'recent'));
  /** Suggestions are on their way for what is typed. */
  protected readonly pending = computed(() => {
    const q = this.cleaned();
    return q.length >= MIN_TYPED_LENGTH && isSearchable(q) && this.lookedUp() !== q;
  });
  protected readonly settled = computed(() => this.cleaned().length >= MIN_TYPED_LENGTH && this.lookedUp() === this.cleaned());
  protected readonly hasSuggestions = computed(() => {
    const r = this.results();
    return !!r && r.articles.length + r.users.length + r.topics.length + r.tags.length > 0;
  });

  protected readonly groups = computed<OptionGroup[]>(() => {
    const q = this.cleaned();
    let index = 0;
    const entries = (options: HeaderOption[]) => options.map((option) => ({ option, index: index++ }));
    if (!q) {
      const recent = this.recent.items().map((item): HeaderOption => ({ kind: 'recent', key: `recent:${item}`, q: item }));
      return recent.length ? [{ id: 'recent', label: null, options: entries(recent) }] : [];
    }
    const groups: OptionGroup[] = [];
    // The suggestions for what was last looked up stay while the next ones load, so the list doesn't jump.
    const r = q.length >= MIN_TYPED_LENGTH ? this.results() : null;
    if (r) {
      const add = (id: OptionGroup['id'], label: string, options: HeaderOption[]) => {
        if (options.length) groups.push({ id, label, options: entries(options) });
      };
      add('articles', 'search.tabs.articles', r.articles.map((result) => ({ kind: 'article', key: `a:${result.article.id}`, result })));
      add('users', 'search.tabs.users', r.users.map((user) => ({ kind: 'user', key: `u:${user.id}`, user })));
      add('topics', 'search.tabs.topics', r.topics.map((topic) => ({ kind: 'topic', key: `t:${topic.kind}:${topic.id}`, topic })));
      add('tags', 'search.tabs.tags', r.tags.map((tag) => ({ kind: 'tag', key: `g:${tag.slug}`, tag })));
    }
    if (isSearchable(q)) groups.push({ id: 'all', label: null, options: entries([{ kind: 'all', key: 'all', q }]) });
    return groups;
  });
  private readonly options = computed(() => this.groups().flatMap((g) => g.options.map((e) => e.option)));
  protected readonly open = computed(() => this.listOpen() && this.options().length > 0);

  private timer: ReturnType<typeof setTimeout> | null = null;
  private lookup = 0;

  constructor() {
    inject(DestroyRef).onDestroy(() => this.cancel());
  }

  /** The template's option, typed (ng-template contexts are `any`). */
  protected asOption(option: HeaderOption): HeaderOption {
    return option;
  }

  protected onInput(event: Event): void {
    this.text.set((event.target as HTMLInputElement).value);
    this.listOpen.set(true);
    this.active.set(-1);
    this.suggest();
  }

  protected onKeydown(event: KeyboardEvent): void {
    const options = this.options();
    switch (event.key) {
      case 'ArrowDown':
        if (!options.length) return;
        event.preventDefault();
        if (!this.open()) this.listOpen.set(true); // closed with Escape: opens again
        this.active.set((this.active() + 1) % options.length);
        return;
      case 'ArrowUp':
        if (!this.open()) return;
        event.preventDefault();
        this.active.set((this.active() - 1 + options.length) % options.length);
        return;
      case 'Enter': {
        if (event.isComposing) return;
        event.preventDefault();
        const option = this.open() ? options[this.active()] : undefined;
        if (option) this.choose(option);
        else if (isSearchable(this.cleaned())) this.openSearch(this.cleaned());
        return;
      }
      case 'Escape':
        if (this.open()) {
          event.preventDefault();
          this.close();
        } else if (this.text()) {
          event.preventDefault();
          this.reset();
        }
        return;
      case 'Delete': {
        // Recent searches show only while the box is empty, so Delete has nothing else to do then.
        const option = this.open() ? options[this.active()] : undefined;
        if (option?.kind !== 'recent') return;
        event.preventDefault();
        this.removeRecent(option.q);
        return;
      }
    }
  }

  protected choose(option: HeaderOption): void {
    switch (option.kind) {
      case 'recent':
      case 'all':
        return this.openSearch(option.q);
      case 'article':
        return this.leaveFor(articleLink(option.result.article));
      case 'user':
        return this.leaveFor(['/@' + option.user.username]);
      case 'topic': {
        const route = topicRoute(option.topic);
        return this.leaveFor(route.commands, route.queryParams);
      }
      case 'tag':
        return this.leaveFor(tagLink(option.tag));
    }
  }

  protected removeRecent(query: string): void {
    const index = this.options().findIndex((o) => o.kind === 'recent' && o.q === query);
    this.recent.remove(query);
    const left = this.options().length;
    this.active.set(left ? Math.min(index, left - 1) : -1);
  }

  protected clearRecent(): void {
    this.recent.clear();
    this.active.set(-1);
  }

  /** The ✕: empty again, with your recent searches (focus stays in the box). */
  protected clearBox(): void {
    this.reset();
    this.listOpen.set(true);
  }

  protected close(): void {
    this.listOpen.set(false);
    this.active.set(-1);
  }

  /** The search page for `q` (Enter, "See all results", a recent search). */
  private openSearch(q: string): void {
    this.recent.add(q);
    this.done();
    void this.router.navigate(['/search'], { queryParams: { q } });
  }

  /** A suggestion's page; what was typed becomes a recent search. */
  private leaveFor(commands: string[], queryParams: Record<string, string> = {}): void {
    this.recent.add(this.cleaned());
    this.done();
    void this.router.navigate(commands, { queryParams });
  }

  private done(): void {
    this.reset();
    this.field().nativeElement.blur();
  }

  private reset(): void {
    this.cancel();
    this.text.set('');
    this.field().nativeElement.value = '';
    this.results.set(null);
    this.lookedUp.set(null);
    this.active.set(-1);
  }

  private suggest(): void {
    this.cancel();
    const q = this.cleaned();
    if (q.length < MIN_TYPED_LENGTH || !isSearchable(q)) {
      this.results.set(null);
      this.lookedUp.set(null);
      return;
    }
    const lookup = ++this.lookup;
    this.timer = setTimeout(async () => {
      this.timer = null;
      let found: SearchSuggestionsDto | null = null;
      try {
        found = await firstValueFrom(this.api.suggest(q));
      } catch {
        // Suggestions are optional: "See all results" still works (also when rate limited).
      }
      if (lookup !== this.lookup) return;
      this.results.set(found);
      this.lookedUp.set(q);
      this.active.set(-1);
    }, SEARCH_DEBOUNCE_MS);
  }

  private cancel(): void {
    if (this.timer) clearTimeout(this.timer);
    this.timer = null;
    this.lookup++;
  }
}

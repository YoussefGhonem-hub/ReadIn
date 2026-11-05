import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, afterNextRender, computed, inject, signal, viewChild } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleCardDto, CollectionDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { CollectionsStore } from '../../core/social/collections.store';
import { BdiText } from '../../shared/directives/bdi-text';
import { PluralPipe, RelativeTimePipe } from '../../shared/pipes/format.pipes';
import { CollectionNameSheet, CollectionPickerSheet, DeleteCollectionSheet } from '../../shared/social/collection-sheets';
import { ArticleCard } from '../../shared/ui/article-card';
import { ArticleCardSkeleton } from '../../shared/ui/skeletons';
import { ScrollRow } from '../../shared/ui/scroll-row';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { SavedStore } from './saved.store';

/** Wait this long after the last keystroke before searching. */
export const SEARCH_DEBOUNCE_MS = 300;

/**
 * Saved (F13): your saved articles, newest first, with title search, field chips and collections (create, rename,
 * delete, filter by one, add/remove an article). Signed-in only (authGuard), rendered in the browser.
 */
@Component({
  selector: 'rd-saved-page',
  imports: [
    RouterLink,
    TranslocoPipe,
    ScrollRow,
    LucideDynamicIcon,
    BdiText,
    PluralPipe,
    RelativeTimePipe,
    ArticleCard,
    ArticleCardSkeleton,
    EmptyState,
    ErrorState,
    CollectionPickerSheet,
    CollectionNameSheet,
    DeleteCollectionSheet,
  ],
  providers: [SavedStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pt-5 lg:pt-8' },
  template: `
    <header class="mb-4">
      <h1 class="m-0 text-2xl font-bold">{{ 'saved.title' | transloco }}</h1>
      <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'saved.sub' | transloco }}</p>
    </header>

    <!-- Search (debounced) -->
    <div class="relative mb-4" role="search">
      <svg lucideIcon="Search" [size]="18" class="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 text-text-secondary" aria-hidden="true"></svg>
      <input
        id="saved-search"
        type="search"
        class="rd-input ps-10"
        dir="auto"
        autocomplete="off"
        enterkeyhint="search"
        data-saved-search
        [attr.aria-label]="'saved.search' | transloco"
        [placeholder]="'saved.search' | transloco"
        [value]="searchText()"
        (input)="onSearchInput($event)"
        (keydown.enter)="searchNow()"
      />
    </div>

    <!-- Collections -->
    <h2 class="m-0 mb-2 text-sm font-semibold">{{ 'saved.collections' | transloco }}</h2>
    <rd-scroll-row [label]="'saved.collections' | transloco" data-collection-chips>
      <button type="button" class="rd-chip" [attr.aria-pressed]="!store.collection()" (click)="store.setCollection(null)">
        {{ 'saved.allSaved' | transloco }}
      </button>
      @for (c of collections.collections(); track c.id) {
        <button type="button" class="rd-chip" [attr.aria-pressed]="store.collection() === c.id" [attr.data-collection-chip]="c.id" (click)="store.setCollection(c.id)">
          <svg lucideIcon="Folder" [size]="14" aria-hidden="true"></svg>
          <rd-bdi-text [text]="c.name" />
          <span class="opacity-80" aria-hidden="true">{{ c.articleCount }}</span>
          <span class="sr-only">{{ c.articleCount | rdPlural: 'collections.articleCount' : lang() }}</span>
        </button>
      }
      <button type="button" class="rd-chip border-dashed" data-new-collection-chip (click)="openCreate()">
        <svg lucideIcon="Plus" [size]="14" aria-hidden="true"></svg>
        {{ 'collections.new' | transloco }}
      </button>
    </rd-scroll-row>

    @if (selectedCollection(); as c) {
      <div class="rd-card mt-3 flex items-center gap-2 p-2 ps-3 shadow-none" data-collection-header>
        <svg lucideIcon="Folder" [size]="18" class="shrink-0 text-primary" aria-hidden="true"></svg>
        <div class="min-w-0 flex-1">
          <span class="block truncate font-semibold"><rd-bdi-text [text]="c.name" /></span>
          <span class="text-xs text-text-secondary">{{ c.articleCount | rdPlural: 'collections.articleCount' : lang() }}</span>
        </div>
        <button type="button" class="rd-icon-btn h-11 w-11 border-0" data-rename-collection [attr.aria-label]="'collections.rename' | transloco" (click)="openRename(c)">
          <svg lucideIcon="Pencil" [size]="18" aria-hidden="true"></svg>
        </button>
        <button type="button" class="rd-icon-btn h-11 w-11 border-0 text-error hover:text-error" data-delete-collection [attr.aria-label]="'collections.delete' | transloco" (click)="deleting.set(c)">
          <svg lucideIcon="Trash2" [size]="18" aria-hidden="true"></svg>
        </button>
      </div>
    }

    <!-- Fields -->
    <rd-scroll-row class="mt-3" [label]="'saved.filterByField' | transloco" data-field-chips>
      <button type="button" class="rd-chip" [attr.aria-pressed]="!store.field()" (click)="store.setField(null)">{{ 'saved.allFields' | transloco }}</button>
      @for (field of store.fields(); track field.id) {
        <button type="button" class="rd-chip" [attr.aria-pressed]="store.field() === field.slug" [attr.data-field-chip]="field.slug" (click)="store.setField(field.slug)">
          <rd-bdi-text [text]="lang() === 'ar' ? field.nameAr : field.nameEn" />
        </button>
      }
    </rd-scroll-row>

    <section class="mt-2" [attr.aria-label]="'saved.title' | transloco" aria-live="polite" data-saved-list>
      @switch (store.status()) {
        @case ('error') {
          <rd-error-state [message]="'saved.loadError' | transloco" (retry)="store.load()" />
        }
        @case ('loaded') {
          @for (item of store.visible(); track item.article.id) {
            <rd-article-card [article]="item.article" data-saved-item [attr.data-article]="item.article.id">
              <div rdCardFooter class="relative z-10 mt-2 flex items-center justify-between gap-2 text-xs text-text-secondary">
                <span>{{ 'saved.savedAt' | transloco: { time: (item.savedAt | rdRelativeTime: lang()) } }}</span>
                <button type="button" class="rd-btn rd-btn-ghost min-h-11 gap-1.5 px-2 text-xs" data-item-collections (click)="picking.set(item.article)">
                  <svg lucideIcon="FolderPlus" [size]="16" aria-hidden="true"></svg>
                  {{ 'collections.manage' | transloco }}
                  @if (memberCount(item.article.id); as count) {
                    <span class="rd-tag">{{ count }}</span>
                  }
                </button>
              </div>
            </rd-article-card>
          } @empty {
            @if (!store.hasFilters()) {
              <rd-empty-state [title]="'saved.empty.title' | transloco" [message]="'saved.empty.body' | transloco" data-saved-empty>
                <a routerLink="/" class="rd-btn rd-btn-primary mt-3">{{ 'saved.browse' | transloco }}</a>
              </rd-empty-state>
            } @else if (store.collection() && !store.field() && !store.query()) {
              <rd-empty-state [title]="'saved.emptyCollection.title' | transloco" [message]="'saved.emptyCollection.body' | transloco" data-collection-empty />
            } @else {
              <rd-empty-state [title]="'saved.noResults.title' | transloco" [message]="'saved.noResults.body' | transloco" data-saved-no-results>
                <button type="button" class="rd-btn rd-btn-outline mt-3" (click)="clearFilters()">{{ 'saved.clearFilters' | transloco }}</button>
              </rd-empty-state>
            }
          }
          @if (store.loadingMore()) {
            <rd-article-card-skeleton />
          }
          @if (store.loadMoreFailed()) {
            <div class="py-4 text-center">
              <button type="button" class="rd-btn rd-btn-outline" (click)="store.loadMore()">{{ 'common.retry' | transloco }}</button>
            </div>
          }
        }
        @default {
          @for (i of [1, 2, 3]; track i) {
            <rd-article-card-skeleton />
          }
        }
      }
      <div #sentinel class="h-px" aria-hidden="true"></div>
    </section>

    <rd-collection-picker-sheet [open]="!!picking()" [article]="picking()" (closed)="picking.set(null)" />
    <rd-collection-name-sheet [open]="naming() !== null" [collection]="renaming()" (done)="onNamed($event)" (closed)="naming.set(null)" />
    <rd-delete-collection-sheet [open]="!!deleting()" [collection]="deleting()" (deleted)="onDeleted($event)" (closed)="deleting.set(null)" />
  `,
})
export class SavedPage {
  protected readonly store = inject(SavedStore);
  protected readonly collections = inject(CollectionsStore);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;
  private readonly sentinel = viewChild.required<ElementRef<HTMLElement>>('sentinel');

  protected readonly searchText = signal('');
  /** The article whose collections are being edited. */
  protected readonly picking = signal<ArticleCardDto | null>(null);
  /** 'create', or the collection being renamed; null when the sheet is closed. */
  protected readonly naming = signal<'create' | CollectionDto | null>(null);
  protected readonly renaming = computed(() => {
    const naming = this.naming();
    return naming && naming !== 'create' ? naming : null;
  });
  protected readonly deleting = signal<CollectionDto | null>(null);
  protected readonly selectedCollection = computed(() => this.collections.collections().find((c) => c.id === this.store.collection()) ?? null);

  private searchTimer: ReturnType<typeof setTimeout> | null = null;

  constructor() {
    inject(Title).setTitle(`${this.transloco.translate('saved.title')} — ReadIn`);
    void this.store.init();

    const destroyRef = inject(DestroyRef);
    destroyRef.onDestroy(() => this.cancelSearch());
    afterNextRender(() => {
      const observer = new IntersectionObserver(
        (entries) => {
          if (entries.some((e) => e.isIntersecting)) void this.store.loadMore();
        },
        { rootMargin: '600px 0px' },
      );
      observer.observe(this.sentinel().nativeElement);
      destroyRef.onDestroy(() => observer.disconnect());
    });
  }

  /** How many collections the article is in (known from the list and this session's changes). */
  protected memberCount(articleId: string): number {
    return this.collections.collectionsOf(articleId)?.size ?? 0;
  }

  protected onSearchInput(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    this.searchText.set(value);
    this.cancelSearch();
    // Clearing the box (or its ✕) searches at once; typing waits for a pause.
    if (!value) this.store.setQuery('');
    else this.searchTimer = setTimeout(() => this.store.setQuery(value), SEARCH_DEBOUNCE_MS);
  }

  protected searchNow(): void {
    this.cancelSearch();
    this.store.setQuery(this.searchText());
  }

  protected clearFilters(): void {
    this.cancelSearch();
    this.searchText.set('');
    this.store.clearFilters();
  }

  protected openCreate(): void {
    this.naming.set('create');
  }

  protected openRename(collection: CollectionDto): void {
    this.naming.set(collection);
  }

  protected onNamed(collection: CollectionDto): void {
    const created = this.naming() === 'create';
    this.naming.set(null);
    this.toasts.success(this.transloco.translate(created ? 'collections.created' : 'collections.renamed'));
    if (created) this.store.setCollection(collection.id);
  }

  protected onDeleted(collection: CollectionDto): void {
    this.deleting.set(null);
    this.toasts.success(this.transloco.translate('collections.deleted'));
    if (this.store.collection() === collection.id) this.store.setCollection(null);
  }

  private cancelSearch(): void {
    if (this.searchTimer) clearTimeout(this.searchTimer);
    this.searchTimer = null;
  }
}

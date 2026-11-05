import { LiveAnnouncer } from '@angular/cdk/a11y';
import { CdkDrag, CdkDragDrop, CdkDragHandle, CdkDropList } from '@angular/cdk/drag-drop';
import { NgTemplateOutlet } from '@angular/common';
import { ChangeDetectionStrategy, Component, ElementRef, Injector, afterNextRender, computed, effect, inject, input, signal, untracked, viewChild } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { WriterCategoriesApi } from '../../core/api/categories.api';
import { WriterCategoryDto, WriterCategoryListDto } from '../../core/api/models';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { isolate } from '../../shared/directives/bidi';
import { PluralPipe } from '../../shared/pipes/format.pipes';
import { translatePlural } from '../../shared/pipes/intl';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { CategoryNameForm } from './category-name-form';
import { MAX_CATEGORIES, OTHER_CATEGORY_SLUG, categoryLink } from './category-rules';
import { MyCategoriesStore, categoryErrorCode } from './my-categories.store';

/** A card of the Categories tab: a category, or the uncategorized list ("مقالات تانية") last. */
@Component({
  selector: 'rd-category-card',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, PluralPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <a
      [routerLink]="link()"
      class="rd-card flex min-h-16 items-center gap-3 px-4 py-3 text-text-primary no-underline shadow-none hover:border-primary"
      [attr.data-category-card]="slug()"
    >
      <span class="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-primary-container text-on-primary-container" aria-hidden="true">
        <svg [lucideIcon]="slug() === other ? 'Layers' : 'Folder'" [size]="20"></svg>
      </span>
      <span class="min-w-0 flex-1">
        <!-- The name keeps its own direction (mixed Arabic and English), isolated; the line follows the page, like the count. -->
        <span class="block truncate font-semibold"><bdi dir="auto" data-category-card-name>{{ name() ?? ('categories.other' | transloco) }}</bdi></span>
        <span class="block text-sm text-text-secondary" data-category-card-count>{{ count() | rdPlural: 'reading.articles' : lang() }}</span>
      </span>
      <svg lucideIcon="ChevronRight" [size]="18" class="shrink-0 text-text-secondary rd-flip-rtl" aria-hidden="true"></svg>
    </a>
  `,
})
export class CategoryCard {
  protected readonly lang = inject(LanguageService).lang;
  protected readonly other = OTHER_CATEGORY_SLUG;

  readonly username = input.required<string>();
  readonly slug = input.required<string>();
  /** Null: the uncategorized list. */
  readonly name = input<string | null>(null);
  readonly count = input(0);
  protected readonly link = computed(() => categoryLink(this.username(), this.slug()));
}

/**
 * The profile's Categories tab (F31), for everyone including guests: one card per category with its published-article
 * count, in the writer's order, then "مقالات تانية" for the articles without one. Empty categories never show here, and a
 * writer without categories gets the empty state ("مقالات تانية" alone would only repeat the Articles tab). Loaded in
 * the browser when the tab opens.
 */
@Component({
  selector: 'rd-profile-categories',
  imports: [TranslocoPipe, EmptyState, ErrorState, CategoryCard],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block py-4', 'data-profile-categories': '' },
  template: `
    @switch (status()) {
      @case ('error') {
        <rd-error-state [message]="'categories.tab.loadError' | transloco" (retry)="load()" />
      }
      @case ('loaded') {
        @let list = data()!;
        @if (list.items.length) {
          <ul class="m-0 grid list-none gap-3 p-0 sm:grid-cols-2" [attr.aria-label]="'categories.tab.label' | transloco" data-category-list>
            @for (category of list.items; track category.id) {
              <li><rd-category-card [username]="username()" [slug]="category.slug" [name]="category.name" [count]="category.articleCount" /></li>
            }
            @if (list.uncategorizedCount) {
              <li><rd-category-card [username]="username()" [slug]="other" [count]="list.uncategorizedCount" /></li>
            }
          </ul>
        } @else {
          <rd-empty-state [title]="'categories.tab.emptyTitle' | transloco" [message]="'categories.tab.emptyBody' | transloco" data-categories-empty />
        }
      }
      @default {
        <div class="grid gap-3 sm:grid-cols-2" aria-busy="true" data-categories-loading>
          @for (i of [1, 2, 3, 4]; track i) {
            <div class="rd-skeleton h-16 w-full rounded-card"></div>
          }
        </div>
      }
    }
  `,
})
export class ProfileCategories {
  private readonly api = inject(WriterCategoriesApi);

  readonly username = input.required<string>();

  protected readonly other = OTHER_CATEGORY_SLUG;
  protected readonly status = signal<'loading' | 'loaded' | 'error'>('loading');
  protected readonly data = signal<WriterCategoryListDto | null>(null);
  private generation = 0;

  constructor() {
    effect(() => {
      this.username();
      untracked(() => void this.load());
    });
  }

  /** `GET /users/{username}/categories`. */
  protected async load(): Promise<void> {
    const generation = ++this.generation;
    this.status.set('loading');
    try {
      const list = await firstValueFrom(this.api.list(this.username()));
      if (generation !== this.generation) return;
      this.data.set(list);
      this.status.set('loaded');
    } catch {
      if (generation === this.generation) this.status.set('error');
    }
  }
}

/**
 * Your own Categories tab (F31, the manage view): every category with its count, empty ones too (marked: visitors don't
 * see them); create one, rename it in place, reorder by dragging or with the move buttons (keyboard), and delete it
 * after a confirmation that says how many articles it has (they stay published, without a category). "مقالات تانية"
 * comes last, once there is a category; before that, the empty view ("رتّب مقالاتك") holds the create field.
 */
@Component({
  selector: 'rd-manage-categories',
  imports: [
    NgTemplateOutlet,
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    CdkDropList,
    CdkDrag,
    CdkDragHandle,
    PluralPipe,
    BottomSheet,
    EmptyState,
    ErrorState,
    CategoryNameForm,
    CategoryCard,
  ],
  providers: [MyCategoriesStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: `
    .cdk-drag-preview {
      box-shadow: var(--rd-elevation-card);
    }
    .cdk-drag-placeholder {
      opacity: 0.4;
    }
    .cdk-drag-animating,
    .cdk-drop-list-dragging .cdk-drag:not(.cdk-drag-placeholder) {
      transition: transform 200ms ease;
    }
    @media (prefers-reduced-motion: reduce) {
      .cdk-drag-animating,
      .cdk-drop-list-dragging .cdk-drag:not(.cdk-drag-placeholder) {
        transition: none;
      }
    }
  `,
  host: { class: 'block py-4', 'data-manage-categories': '' },
  template: `
    <!-- "＋ قسم جديد": above the list, or inside the empty view when there is none yet -->
    <ng-template #createTemplate>
      <rd-category-name-form
        #createForm
        class="mb-4 w-full text-start"
        inputId="category-new"
        [label]="'categories.manage.newLabel' | transloco"
        [submitLabel]="'categories.manage.create' | transloco"
        [existing]="store.items()"
        [busy]="creating()"
        [serverError]="createError()"
        data-category-create
        (edited)="createError.set(null)"
        (submitted)="create($event)"
      />
    </ng-template>

    @switch (store.status()) {
      @case ('error') {
        <rd-error-state [message]="'categories.tab.loadError' | transloco" (retry)="store.load()" />
      }
      @case ('loaded') {
        @if (store.items().length) {
          <p class="m-0 mb-4 text-sm text-text-secondary" data-categories-hint>{{ 'categories.manage.hint' | transloco }}</p>
          @if (atLimit()) {
            <p class="rd-alert rd-alert-info m-0 mb-4" data-category-limit>{{ 'categories.manage.limit' | transloco: { max: max } }}</p>
          } @else {
            <ng-container [ngTemplateOutlet]="createTemplate" />
          }

          <ol class="m-0 flex list-none flex-col gap-2 p-0" cdkDropList cdkDropListLockAxis="y" [attr.aria-label]="'categories.manage.listLabel' | transloco" data-category-list (cdkDropListDropped)="onDrop($event)">
            @for (category of store.items(); track category.id; let i = $index; let first = $first; let last = $last) {
              <li cdkDrag [cdkDragData]="category.id" [cdkDragDisabled]="!!renaming()" class="rd-card flex items-center gap-1 p-2 shadow-none" [attr.data-category-row]="category.id">
                @if (renaming() === category.id) {
                  <rd-category-name-form
                    class="min-w-0 flex-1 ps-1"
                    [inputId]="'category-rename-' + category.id"
                    [label]="'categories.manage.renameLabel' | transloco: { name: isolate(category.name) }"
                    [hideLabel]="true"
                    [submitLabel]="'common.save' | transloco"
                    [initial]="category.name"
                    [existing]="store.items()"
                    [exceptId]="category.id"
                    [busy]="saving()"
                    [serverError]="renameError()"
                    [cancellable]="true"
                    [autofocus]="true"
                    (edited)="renameError.set(null)"
                    (submitted)="rename(category, $event)"
                    (cancelled)="stopRenaming(category.id)"
                  />
                } @else {
                  <span cdkDragHandle class="grid h-10 w-6 shrink-0 cursor-grab place-items-center text-text-secondary" aria-hidden="true" data-category-drag>
                    <svg lucideIcon="GripVertical" [size]="18"></svg>
                  </span>
                  <a [routerLink]="link(category.slug)" class="min-w-0 flex-1 rounded-md px-1 py-1 text-text-primary no-underline hover:underline" data-category-link>
                    <span class="block truncate font-semibold"><bdi dir="auto" data-category-name>{{ category.name }}</bdi></span>
                    <!-- Readers never see an empty category; its row says so instead of "0 articles". -->
                    <span class="block text-xs text-text-secondary" data-category-count [attr.data-category-empty]="category.articleCount ? null : ''">{{
                      category.articleCount ? (category.articleCount | rdPlural: 'reading.articles' : lang()) : ('categories.manage.emptyCategory' | transloco)
                    }}</span>
                  </a>
                  <button
                    type="button"
                    class="rd-icon-btn shrink-0 border-transparent bg-transparent disabled:cursor-default disabled:opacity-40"
                    [disabled]="first"
                    [attr.aria-label]="'categories.manage.moveUp' | transloco: { name: isolate(category.name) }"
                    data-move="up"
                    (click)="move(category, i, i - 1)"
                  >
                    <svg lucideIcon="ChevronUp" [size]="18" aria-hidden="true"></svg>
                  </button>
                  <button
                    type="button"
                    class="rd-icon-btn shrink-0 border-transparent bg-transparent disabled:cursor-default disabled:opacity-40"
                    [disabled]="last"
                    [attr.aria-label]="'categories.manage.moveDown' | transloco: { name: isolate(category.name) }"
                    data-move="down"
                    (click)="move(category, i, i + 1)"
                  >
                    <svg lucideIcon="ChevronDown" [size]="18" aria-hidden="true"></svg>
                  </button>
                  <button
                    type="button"
                    class="rd-icon-btn shrink-0 border-transparent bg-transparent"
                    [attr.aria-label]="'categories.manage.rename' | transloco: { name: isolate(category.name) }"
                    data-category-rename
                    (click)="startRenaming(category.id)"
                  >
                    <svg lucideIcon="Pencil" [size]="18" aria-hidden="true"></svg>
                  </button>
                  <button
                    type="button"
                    class="rd-icon-btn shrink-0 border-transparent bg-transparent text-error"
                    [attr.aria-label]="'categories.manage.delete' | transloco: { name: isolate(category.name) }"
                    data-category-delete
                    (click)="confirmDelete.set(category)"
                  >
                    <svg lucideIcon="Trash2" [size]="18" aria-hidden="true"></svg>
                  </button>
                }
              </li>
            }
          </ol>
          <p class="m-0 mt-2 text-xs text-text-secondary">{{ 'categories.manage.dragHint' | transloco }}</p>

          <!-- "مقالات تانية" only after at least one category, as visitors see it -->
          @if (store.uncategorizedCount()) {
            <rd-category-card class="mt-4" [username]="username()" [slug]="other" [count]="store.uncategorizedCount()" />
          }
        } @else {
          <rd-empty-state [title]="'categories.manage.emptyTitle' | transloco" [message]="'categories.manage.emptyBody' | transloco" data-categories-empty>
            <div class="mt-3 w-full max-w-md">
              <ng-container [ngTemplateOutlet]="createTemplate" />
            </div>
          </rd-empty-state>
        }
      }
      @default {
        <div class="flex flex-col gap-2" aria-busy="true" data-categories-loading>
          <div class="rd-skeleton h-11 w-full"></div>
          @for (i of [1, 2, 3]; track i) {
            <div class="rd-skeleton h-14 w-full rounded-card"></div>
          }
        </div>
      }
    }

    <rd-bottom-sheet [open]="!!confirmDelete()" role="alertdialog" labelledBy="category-delete-title" describedBy="category-delete-body" [dismissible]="!deleting()" (closed)="confirmDelete.set(null)">
      @if (confirmDelete(); as c) {
        <div class="flex flex-col gap-3 pt-1" data-category-delete-sheet>
          <h2 id="category-delete-title" class="m-0 pe-10 text-xl font-semibold">{{ 'categories.manage.deleteTitle' | transloco: { name: isolate(c.name) } }}</h2>
          <p id="category-delete-body" class="m-0 text-sm text-text-secondary" data-category-delete-body>{{ deleteBody(c) }}</p>
          @if (deleteError()) {
            <p class="rd-alert rd-alert-error m-0" role="alert">{{ deleteError() }}</p>
          }
          <div class="mt-2 flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="deleting()" (click)="confirmDelete.set(null)">{{ 'common.cancel' | transloco }}</button>
            <button type="button" class="rd-btn flex-1 bg-error text-on-error" [disabled]="deleting()" [attr.aria-busy]="deleting()" data-category-delete-confirm (click)="remove(c)">
              @if (deleting()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ 'categories.manage.deleteConfirm' | transloco }}
            </button>
          </div>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class ManageCategories {
  protected readonly store = inject(MyCategoriesStore);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ErrorMessages);
  private readonly toasts = inject(ToastService);
  private readonly announcer = inject(LiveAnnouncer);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly injector = inject(Injector);
  protected readonly lang = inject(LanguageService).lang;
  private readonly createForm = viewChild<CategoryNameForm>('createForm');

  /** Your username: the links to your category pages. */
  readonly username = input.required<string>();

  protected readonly max = MAX_CATEGORIES;
  protected readonly other = OTHER_CATEGORY_SLUG;
  protected readonly isolate = isolate;
  protected readonly atLimit = computed(() => this.store.items().length >= MAX_CATEGORIES);
  protected readonly creating = signal(false);
  protected readonly createError = signal<string | null>(null);
  protected readonly renaming = signal<string | null>(null);
  protected readonly saving = signal(false);
  protected readonly renameError = signal<string | null>(null);
  protected readonly confirmDelete = signal<WriterCategoryDto | null>(null);
  protected readonly deleting = signal(false);
  protected readonly deleteError = signal<string | null>(null);

  constructor() {
    void this.store.load();
    effect(() => {
      this.confirmDelete();
      untracked(() => this.deleteError.set(null));
    });
  }

  protected link(slug: string): string[] {
    return categoryLink(this.username(), slug);
  }

  protected async create(name: string): Promise<void> {
    if (this.creating()) return;
    this.creating.set(true);
    this.createError.set(null);
    try {
      const created = await this.store.create(name);
      this.createForm()?.reset();
      void this.announcer.announce(this.transloco.translate('categories.manage.created', { name: created.name }), 'polite');
    } catch (error) {
      this.createError.set(categoryErrorCode(error));
    } finally {
      this.creating.set(false);
      afterNextRender(() => this.createForm()?.focus(), { injector: this.injector });
    }
  }

  protected startRenaming(id: string): void {
    this.renameError.set(null);
    this.renaming.set(id);
  }

  /** Back to the row, with focus on its Rename button. */
  protected stopRenaming(id: string): void {
    this.renaming.set(null);
    this.focusRow(id, '[data-category-rename]');
  }

  protected async rename(category: WriterCategoryDto, name: string): Promise<void> {
    if (this.saving()) return;
    this.saving.set(true);
    this.renameError.set(null);
    try {
      await this.store.rename(category.id, name);
      this.stopRenaming(category.id);
    } catch (error) {
      this.renameError.set(categoryErrorCode(error));
    } finally {
      this.saving.set(false);
    }
  }

  protected onDrop(event: CdkDragDrop<unknown>): void {
    if (event.previousIndex === event.currentIndex) return;
    const category = this.store.items()[event.previousIndex];
    void this.reorder(category, event.previousIndex, event.currentIndex);
  }

  /** The move buttons: the category moves and focus stays on the same button of its row (or the other one at an end). */
  protected async move(category: WriterCategoryDto, from: number, to: number): Promise<void> {
    const direction = to < from ? 'up' : 'down';
    const done = this.reorder(category, from, to);
    this.focusRow(category.id, `[data-move="${direction}"]:not(:disabled)`, `[data-move="${direction === 'up' ? 'down' : 'up'}"]`);
    await done;
  }

  /** Shown at once; moves made quickly one after the other each send the whole order, and the last answer wins. */
  private async reorder(category: WriterCategoryDto, from: number, to: number): Promise<void> {
    const total = this.store.items().length;
    void this.announcer.announce(this.transloco.translate('categories.manage.moved', { name: category.name, position: to + 1, total }), 'polite');
    const ok = await this.store.move(from, to);
    if (!ok) this.toasts.error(this.transloco.translate('categories.manage.moveFailed'));
  }

  protected deleteBody(category: WriterCategoryDto): string {
    this.lang();
    if (!category.articleCount) return this.transloco.translate('categories.manage.deleteBodyEmpty');
    return translatePlural(this.transloco, 'categories.manage.deleteBody', category.articleCount, this.lang());
  }

  protected async remove(category: WriterCategoryDto): Promise<void> {
    if (this.deleting()) return;
    this.deleting.set(true);
    this.deleteError.set(null);
    try {
      await this.store.remove(category.id);
      this.deleting.set(false);
      this.confirmDelete.set(null);
      this.toasts.success(this.transloco.translate('categories.manage.deleted', { name: category.name }));
    } catch (error) {
      this.deleteError.set(this.errors.forError(error));
    } finally {
      this.deleting.set(false);
    }
  }

  private focusRow(id: string, selector: string, fallback?: string): void {
    afterNextRender(
      () => {
        const row = this.host.nativeElement.querySelector(`[data-category-row="${CSS.escape(id)}"]`);
        const target = row?.querySelector<HTMLElement>(selector) ?? (fallback ? row?.querySelector<HTMLElement>(fallback) : null);
        target?.focus();
      },
      { injector: this.injector },
    );
  }
}

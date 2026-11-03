import { ChangeDetectionStrategy, Component, DOCUMENT, computed, effect, inject, input, output, signal, untracked } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { isApiError } from '../../core/api/api.config';
import { ArticleCardDto, CollectionDto } from '../../core/api/models';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { COLLECTION_NAME_MAX, CollectionsStore } from '../../core/social/collections.store';
import { BdiText } from '../directives/bdi-text';
import { PluralPipe } from '../pipes/format.pipes';
import { BottomSheet } from '../ui/bottom-sheet';
import { ErrorState } from '../ui/states';
import { ToastService } from '../ui/toast/toast.service';

/** Translation key of a local name problem, or null (1–60 characters after trimming). */
export function collectionNameProblem(name: string): string | null {
  const trimmed = name.trim();
  if (!trimmed) return 'collections.nameRequired';
  if (trimmed.length > COLLECTION_NAME_MAX) return 'collections.nameTooLong';
  return null;
}

/** The API's generic validation codes on `name`, shown with the collection-name messages. */
const NAME_CODES: Readonly<Record<string, string>> = {
  'validation.required': 'collections.nameRequired',
  'validation.max_length': 'collections.nameTooLong',
};

/** The translated message of a create/rename failure: the first validation code of `name`, else the error code. */
export function collectionErrorMessage(error: unknown, errors: ErrorMessages, transloco: TranslocoService): string {
  if (!isApiError(error)) return errors.forError(error);
  const [code] = error.validationErrors['name'] ?? error.validationErrors['Name'] ?? [];
  if (code && NAME_CODES[code]) return transloco.translate(NAME_CODES[code]);
  return code ? errors.forCode(code, error.problem?.title) : errors.forCode(error.code, error.problem?.title);
}

/** Create or rename a collection (F13). Emits the saved collection; API errors show under the field. */
@Component({
  selector: 'rd-collection-name-sheet',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open()" labelledBy="collection-name-title" [dismissible]="!busy()" (closed)="close()">
      <form class="flex flex-col gap-4 pt-1" novalidate data-collection-name-form (submit)="submit($event)">
        <h2 id="collection-name-title" class="m-0 pe-10 text-xl font-semibold">
          {{ (collection() ? 'collections.renameTitle' : 'collections.new') | transloco }}
        </h2>
        <div>
          <label class="rd-label" for="collection-name">{{ 'collections.name' | transloco }}</label>
          <input
            id="collection-name"
            class="rd-input"
            dir="auto"
            autocomplete="off"
            [attr.maxlength]="max"
            [placeholder]="'collections.namePlaceholder' | transloco"
            [value]="name()"
            (input)="onInput($event)"
            [attr.aria-invalid]="!!error()"
            [attr.aria-describedby]="error() ? 'collection-name-error' : null"
          />
          @if (error()) {
            <p id="collection-name-error" class="rd-field-error" role="alert">{{ error() }}</p>
          }
        </div>
        <button type="submit" class="rd-btn rd-btn-primary w-full" [disabled]="busy()" [attr.aria-busy]="busy()" data-submit>
          @if (busy()) {
            <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
          }
          {{ (collection() ? 'common.save' : 'collections.create') | transloco }}
        </button>
      </form>
    </rd-bottom-sheet>
  `,
})
export class CollectionNameSheet {
  private readonly store = inject(CollectionsStore);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);

  readonly open = input(false);
  /** The collection to rename; null creates a new one. */
  readonly collection = input<CollectionDto | null>(null);
  readonly done = output<CollectionDto>();
  readonly closed = output<void>();

  protected readonly max = COLLECTION_NAME_MAX;
  protected readonly name = signal('');
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);

  constructor() {
    effect(() => {
      if (!this.open()) return;
      const current = this.collection();
      untracked(() => {
        this.name.set(current?.name ?? '');
        this.error.set(null);
      });
    });
  }

  protected onInput(event: Event): void {
    this.name.set((event.target as HTMLInputElement).value);
    this.error.set(null);
  }

  protected close(): void {
    if (!this.busy()) this.closed.emit();
  }

  protected async submit(event: Event): Promise<void> {
    event.preventDefault();
    if (this.busy()) return;
    const problem = collectionNameProblem(this.name());
    if (problem) {
      this.error.set(this.transloco.translate(problem));
      return;
    }
    const current = this.collection();
    if (current && current.name === this.name().trim()) {
      this.closed.emit();
      return;
    }
    this.busy.set(true);
    try {
      const saved = current ? await this.store.rename(current.id, this.name()) : await this.store.create(this.name());
      this.busy.set(false);
      this.done.emit(saved);
    } catch (error) {
      this.error.set(collectionErrorMessage(error, this.errors, this.transloco));
    } finally {
      this.busy.set(false);
    }
  }
}

/** "Delete this collection?" The articles stay saved. */
@Component({
  selector: 'rd-delete-collection-sheet',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet, BdiText],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet
      [open]="open() && !!collection()"
      role="alertdialog"
      labelledBy="delete-collection-title"
      describedBy="delete-collection-body"
      [dismissible]="!busy()"
      (closed)="close()"
    >
      @if (collection(); as c) {
        <div class="flex flex-col gap-3 pt-1" data-delete-collection>
          <h2 id="delete-collection-title" class="m-0 pe-10 text-xl font-semibold">
            <rd-bdi-text [text]="'collections.deleteTitle' | transloco: { name: c.name }" />
          </h2>
          <p id="delete-collection-body" class="m-0 text-sm text-text-secondary">{{ 'collections.deleteBody' | transloco }}</p>
          @if (error()) {
            <p class="rd-alert rd-alert-error" role="alert">{{ error() }}</p>
          }
          <div class="mt-2 flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="close()">{{ 'common.cancel' | transloco }}</button>
            <button type="button" class="rd-btn flex-1 bg-error text-on-error" [disabled]="busy()" [attr.aria-busy]="busy()" data-confirm-delete (click)="confirm()">
              @if (busy()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ 'collections.delete' | transloco }}
            </button>
          </div>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class DeleteCollectionSheet {
  private readonly store = inject(CollectionsStore);
  private readonly errors = inject(ErrorMessages);

  readonly open = input(false);
  readonly collection = input<CollectionDto | null>(null);
  readonly deleted = output<CollectionDto>();
  readonly closed = output<void>();

  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);

  constructor() {
    effect(() => {
      if (this.open()) untracked(() => this.error.set(null));
    });
  }

  protected close(): void {
    if (!this.busy()) this.closed.emit();
  }

  protected async confirm(): Promise<void> {
    const collection = this.collection();
    if (!collection || this.busy()) return;
    this.busy.set(true);
    try {
      await this.store.remove(collection.id);
      this.busy.set(false);
      this.deleted.emit(collection);
    } catch (error) {
      this.error.set(this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }
}

/**
 * "Add to collection" (F13): tick the collections an article belongs to, or create a new one (the article goes
 * straight into it). Adding saves the article if it wasn't saved yet. Every change is optimistic.
 */
@Component({
  selector: 'rd-collection-picker-sheet',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet, BdiText, PluralPipe, ErrorState],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open() && !!article()" labelledBy="collection-picker-title" describedBy="collection-picker-body" (closed)="closed.emit()">
      <div class="flex flex-col pt-1" data-collection-picker>
        <h2 id="collection-picker-title" class="m-0 pe-10 text-xl font-semibold">{{ 'collections.title' | transloco }}</h2>
        <p id="collection-picker-body" class="m-0 mt-1 text-sm text-text-secondary">{{ 'collections.body' | transloco }}</p>

        @switch (store.status()) {
          @case ('error') {
            <rd-error-state [message]="'collections.loadError' | transloco" (retry)="store.load(true)" />
          }
          @case ('loaded') {
            <ul class="m-0 mt-3 flex list-none flex-col gap-1 p-0" data-collection-list>
              @for (c of store.collections(); track c.id) {
                <li>
                  <label class="flex min-h-12 cursor-pointer items-center gap-3 rounded-md px-2 hover:bg-surface-variant" [attr.data-collection]="c.id">
                    <input
                      type="checkbox"
                      class="h-5 w-5 shrink-0 accent-primary"
                      [checked]="isIn(c.id)"
                      [disabled]="pending().has(c.id)"
                      (change)="toggle(c, $event)"
                    />
                    <svg lucideIcon="Folder" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
                    <span class="min-w-0 flex-1">
                      <span class="block truncate font-semibold"><rd-bdi-text [text]="c.name" /></span>
                      <span class="block text-xs text-text-secondary">{{ c.articleCount | rdPlural: 'collections.articleCount' : lang() }}</span>
                    </span>
                  </label>
                </li>
              } @empty {
                <li class="py-4 text-center text-sm text-text-secondary">{{ 'collections.empty' | transloco }}</li>
              }
            </ul>
          }
          @default {
            <div class="mt-3 flex flex-col gap-2" aria-hidden="true">
              @for (i of [1, 2, 3]; track i) {
                <div class="rd-skeleton h-12"></div>
              }
            </div>
          }
        }

        @if (creating()) {
          <form class="mt-3 flex flex-col" novalidate data-new-collection-form (submit)="create($event)">
            <label class="rd-label" for="new-collection-name">{{ 'collections.name' | transloco }}</label>
            <div class="flex gap-2">
              <input
                id="new-collection-name"
                class="rd-input"
                dir="auto"
                autocomplete="off"
                [attr.maxlength]="max"
                [placeholder]="'collections.namePlaceholder' | transloco"
                [value]="name()"
                (input)="onInput($event)"
                [attr.aria-invalid]="!!error()"
                [attr.aria-describedby]="error() ? 'new-collection-error' : null"
              />
              <button type="submit" class="rd-btn rd-btn-primary shrink-0" [disabled]="busy()" [attr.aria-busy]="busy()" data-create-collection>
                {{ 'collections.create' | transloco }}
              </button>
            </div>
            @if (error()) {
              <p id="new-collection-error" class="rd-field-error" role="alert">{{ error() }}</p>
            }
          </form>
        } @else if (store.status() === 'loaded') {
          <button type="button" class="rd-btn rd-btn-ghost mt-2 justify-start text-primary" data-new-collection (click)="startCreate()">
            <svg lucideIcon="FolderPlus" [size]="18" aria-hidden="true"></svg>
            {{ 'collections.new' | transloco }}
          </button>
        }

        <button type="button" class="rd-btn rd-btn-outline mt-4 w-full" data-collections-done (click)="closed.emit()">{{ 'collections.done' | transloco }}</button>
      </div>
    </rd-bottom-sheet>
  `,
})
export class CollectionPickerSheet {
  protected readonly store = inject(CollectionsStore);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly toasts = inject(ToastService);
  private readonly document = inject(DOCUMENT);
  protected readonly lang = inject(LanguageService).lang;

  readonly open = input(false);
  readonly article = input<ArticleCardDto | null>(null);
  readonly closed = output<void>();

  protected readonly max = COLLECTION_NAME_MAX;
  protected readonly pending = signal<ReadonlySet<string>>(new Set());
  protected readonly creating = signal(false);
  protected readonly name = signal('');
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  private readonly membership = computed(() => {
    const article = this.article();
    return article ? this.store.collectionsOf(article.id) : null;
  });

  constructor() {
    effect(() => {
      if (!this.open()) return;
      untracked(() => {
        this.creating.set(false);
        this.name.set('');
        this.error.set(null);
        void this.store.load();
      });
    });
  }

  protected isIn(collectionId: string): boolean {
    return this.membership()?.has(collectionId) ?? false;
  }

  protected async toggle(collection: CollectionDto, event: Event): Promise<void> {
    const article = this.article();
    const checkbox = event.target as HTMLInputElement;
    if (!article || this.pending().has(collection.id)) return;
    this.setPending(collection.id, true);
    try {
      const done = checkbox.checked ? await this.store.addArticle(collection.id, article) : await this.store.removeArticle(collection.id, article.id);
      if (!done) checkbox.checked = this.isIn(collection.id);
    } finally {
      this.setPending(collection.id, false);
    }
  }

  protected startCreate(): void {
    this.creating.set(true);
    queueMicrotask(() => this.document.getElementById('new-collection-name')?.focus());
  }

  protected onInput(event: Event): void {
    this.name.set((event.target as HTMLInputElement).value);
    this.error.set(null);
  }

  /** Creates the collection and puts the article in it. */
  protected async create(event: Event): Promise<void> {
    event.preventDefault();
    const article = this.article();
    if (!article || this.busy()) return;
    const problem = collectionNameProblem(this.name());
    if (problem) {
      this.error.set(this.transloco.translate(problem));
      return;
    }
    this.busy.set(true);
    try {
      const created = await this.store.create(this.name());
      this.creating.set(false);
      this.name.set('');
      this.toasts.success(this.transloco.translate('collections.created'));
      await this.store.addArticle(created.id, article);
    } catch (error) {
      this.error.set(collectionErrorMessage(error, this.errors, this.transloco));
    } finally {
      this.busy.set(false);
    }
  }

  private setPending(id: string, on: boolean): void {
    this.pending.update((set) => {
      const next = new Set(set);
      if (on) next.add(id);
      else next.delete(id);
      return next;
    });
  }
}

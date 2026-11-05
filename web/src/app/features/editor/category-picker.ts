import { ChangeDetectionStrategy, Component, ElementRef, Injector, afterNextRender, computed, inject, input, output, signal, viewChild } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { CategoryNameForm } from '../categories/category-name-form';
import { MAX_CATEGORIES } from '../categories/category-rules';
import { MyCategoriesStore, categoryErrorCode } from '../categories/my-categories.store';

/** The select's value for "＋ قسم جديد" (never a category id). */
const NEW = '__new';

/**
 * The editor's optional **القسم** picker (F31): your own categories (`GET /me/categories`), "No category", and
 * "＋ قسم جديد" to create one on the spot (`POST /me/categories`, then it is picked). Picking applies at once
 * (the editor sends `PUT /articles/{id}/category`); it is not part of the draft, so it needs no Update.
 */
@Component({
  selector: 'rd-category-picker',
  imports: [TranslocoPipe, LucideDynamicIcon, CategoryNameForm],
  providers: [MyCategoriesStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-category-picker': '' },
  template: `
    <label class="rd-label" for="ed-category">{{ 'editor.meta.category' | transloco }}</label>
    <select
      #select
      id="ed-category"
      class="rd-input"
      data-category-select
      [disabled]="store.status() !== 'loaded'"
      [attr.aria-describedby]="'ed-category-hint'"
      [attr.aria-busy]="busy()"
      (change)="onChange($event)"
    >
      <option value="" [selected]="!value()">{{ 'editor.meta.categoryNone' | transloco }}</option>
      @for (category of store.items(); track category.id) {
        <option dir="auto" [value]="category.id" [selected]="category.id === value()">{{ category.name }}</option>
      }
      @if (store.status() === 'loaded' && store.items().length < max) {
        <option [value]="newValue" data-category-new-option>{{ 'editor.meta.categoryNew' | transloco }}</option>
      }
    </select>

    @if (creating()) {
      <rd-category-name-form
        class="mt-2"
        inputId="ed-category-new"
        [label]="'editor.meta.categoryNewLabel' | transloco"
        [submitLabel]="'categories.manage.create' | transloco"
        [existing]="store.items()"
        [busy]="createBusy()"
        [serverError]="createError()"
        [cancellable]="true"
        [autofocus]="true"
        [stacked]="true"
        data-category-create
        (edited)="createError.set(null)"
        (submitted)="create($event)"
        (cancelled)="stopCreating()"
      />
    }

    @if (store.status() === 'error') {
      <p class="m-0 mt-1 text-xs text-error" role="alert" data-category-load-error>
        {{ 'editor.meta.categoryLoadError' | transloco }}
        <button type="button" class="font-semibold underline" (click)="store.load()">{{ 'common.retry' | transloco }}</button>
      </p>
    } @else if (errorMessage()) {
      <p class="m-0 mt-1 text-xs text-error" role="alert" data-category-error>{{ errorMessage() }}</p>
    }
    <p id="ed-category-hint" class="rd-field-hint flex items-center gap-1.5" aria-live="polite" data-category-hint>
      @if (busy()) {
        <svg lucideIcon="LoaderCircle" [size]="14" class="animate-spin" aria-hidden="true"></svg>
        {{ 'editor.meta.categorySaving' | transloco }}
      } @else {
        {{ 'editor.meta.categoryHint' | transloco }}
      }
    </p>
  `,
})
export class CategoryPicker {
  protected readonly store = inject(MyCategoriesStore);
  private readonly errors = inject(ErrorMessages);
  private readonly injector = inject(Injector);
  private readonly select = viewChild<ElementRef<HTMLSelectElement>>('select');

  /** The article's category (null: none). */
  readonly value = input<string | null>(null);
  /** A change is on its way to the server. */
  readonly busy = input(false);
  /** Why the last change was refused (a contract code). */
  readonly error = input<string | null>(null);
  readonly changed = output<string | null>();

  protected readonly max = MAX_CATEGORIES;
  protected readonly newValue = NEW;
  protected readonly creating = signal(false);
  protected readonly createBusy = signal(false);
  protected readonly createError = signal<string | null>(null);
  protected readonly errorMessage = computed(() => {
    const code = this.error();
    return code ? this.errors.forCode(code) : '';
  });

  constructor() {
    void this.store.load();
  }

  protected onChange(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    if (value === NEW) {
      // The select keeps showing the current category while you name the new one.
      this.resetSelect();
      this.createError.set(null);
      this.creating.set(true);
      return;
    }
    this.creating.set(false);
    this.changed.emit(value || null);
  }

  protected stopCreating(): void {
    this.creating.set(false);
    afterNextRender(() => this.select()?.nativeElement.focus(), { injector: this.injector });
  }

  /** Creates the category, then picks it. */
  protected async create(name: string): Promise<void> {
    if (this.createBusy()) return;
    this.createBusy.set(true);
    this.createError.set(null);
    try {
      const created = await this.store.create(name);
      this.creating.set(false);
      this.changed.emit(created.id);
      afterNextRender(() => this.select()?.nativeElement.focus(), { injector: this.injector });
    } catch (error) {
      this.createError.set(categoryErrorCode(error));
    } finally {
      this.createBusy.set(false);
    }
  }

  private resetSelect(): void {
    const select = this.select()?.nativeElement;
    if (select) select.value = this.value() ?? '';
  }
}

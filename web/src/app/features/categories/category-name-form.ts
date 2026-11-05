import { ChangeDetectionStrategy, Component, ElementRef, afterNextRender, computed, effect, inject, input, output, signal, untracked, viewChild } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { CATEGORY_NAME_MAX, categoryNameProblem, categoryNameTaken, cleanCategoryName } from './category-rules';

/**
 * One line to name a category (F31): create (the manage view, the editor's "＋ قسم جديد") or rename. The name keeps
 * its own direction (`dir="auto"`, mixed Arabic and English). The contract's checks run as you type, with an inline
 * message: 1–40 characters after cleaning, a letter or digit, and not the name of another of your categories (case
 * and Arabic spelling ignored). Emits the cleaned name; the parent sends it and passes back a refused request's code.
 */
@Component({
  selector: 'rd-category-name-form',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <form class="flex flex-col gap-1" novalidate (submit)="submit($event)" data-category-name-form>
      <label class="rd-label" [class.sr-only]="hideLabel()" [attr.for]="inputId()">{{ label() }}</label>
      <!-- The buttons go under the field where there is no room beside it (always when stacked: the editor's aside). -->
      <div class="flex flex-wrap items-start gap-2">
        <input
          #field
          [id]="inputId()"
          [class]="stacked() ? 'rd-input min-w-0 basis-full' : 'rd-input min-w-0 flex-1 basis-40'"
          dir="auto"
          autocomplete="off"
          enterkeyhint="done"
          [value]="value()"
          [placeholder]="'categories.manage.namePlaceholder' | transloco"
          [disabled]="busy()"
          [attr.aria-invalid]="message() ? true : null"
          [attr.aria-describedby]="inputId() + '-hint'"
          data-category-name-input
          (input)="onInput($event)"
          (keydown.escape)="cancel($event)"
        />
        <div class="ms-auto flex shrink-0 gap-2">
          <button type="submit" class="rd-btn rd-btn-primary" [disabled]="!canSubmit()" [attr.aria-busy]="busy()" data-category-name-submit>
            @if (busy()) {
              <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
            }
            {{ submitLabel() }}
          </button>
          @if (cancellable()) {
            <button type="button" class="rd-btn rd-btn-ghost" [disabled]="busy()" data-category-name-cancel (click)="cancelled.emit()">
              {{ 'common.cancel' | transloco }}
            </button>
          }
        </div>
      </div>
      <p [id]="inputId() + '-hint'" class="m-0 flex justify-between gap-2 text-xs" aria-live="polite">
        <span [class]="message() ? 'text-error' : 'text-text-secondary'" data-category-name-error>{{ message() }}</span>
        <span class="shrink-0 tabular-nums" [class]="tooLong() ? 'text-error' : 'text-text-secondary'" dir="ltr">{{ length() }}/{{ max }}</span>
      </p>
    </form>
  `,
})
export class CategoryNameForm {
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;
  private readonly field = viewChild<ElementRef<HTMLInputElement>>('field');

  readonly inputId = input.required<string>();
  readonly label = input.required<string>();
  readonly hideLabel = input(false);
  readonly submitLabel = input.required<string>();
  /** The name to start from (rename). */
  readonly initial = input('');
  /** Your categories, to catch a name you already use; `exceptId` is the one being renamed. */
  readonly existing = input<readonly { id: string; name: string }[]>([]);
  readonly exceptId = input<string | null>(null);
  readonly busy = input(false);
  /** The code of the last refused request (`category.name_taken`, `category.limit`, …), until the name changes. */
  readonly serverError = input<string | null>(null);
  readonly cancellable = input(false);
  readonly autofocus = input(false);
  /** The field on its own line, the buttons under it (a narrow column). */
  readonly stacked = input(false);

  readonly submitted = output<string>();
  readonly cancelled = output<void>();
  /** The name changed: the parent drops its server error. */
  readonly edited = output<void>();

  protected readonly max = CATEGORY_NAME_MAX;
  protected readonly value = signal('');
  private readonly cleaned = computed(() => cleanCategoryName(this.value()));
  protected readonly length = computed(() => this.cleaned().length);
  protected readonly tooLong = computed(() => this.length() > this.max);
  /** What is wrong with the name as typed: a rule's message key, or `taken`; null when it is fine (or still empty). */
  private readonly problem = computed<string | null>(() => {
    const name = this.cleaned();
    const problem = categoryNameProblem(name);
    if (problem) return problem === 'empty' ? null : `categories.manage.rules.${problem}`;
    const unchanged = this.exceptId() !== null && name === cleanCategoryName(this.initial());
    return !unchanged && categoryNameTaken(this.existing(), name, this.exceptId()) ? 'taken' : null;
  });
  protected readonly message = computed(() => {
    this.lang();
    const problem = this.problem();
    if (problem === 'taken') return this.errors.forCode('category.name_taken');
    if (problem) return this.transloco.translate(problem, { max: this.max });
    const code = this.serverError();
    return code ? this.errors.forCode(code) : '';
  });
  protected readonly canSubmit = computed(() => {
    if (this.busy() || this.problem() || categoryNameProblem(this.cleaned())) return false;
    // Renaming to the same spelling changes nothing.
    return this.exceptId() === null || this.cleaned() !== cleanCategoryName(this.initial());
  });

  constructor() {
    effect(() => {
      const initial = this.initial();
      untracked(() => this.value.set(initial));
    });
    afterNextRender(() => {
      if (this.autofocus()) {
        const input = this.field()?.nativeElement;
        input?.focus();
        input?.select();
      }
    });
  }

  /** Empties the field (after a create). */
  reset(): void {
    this.value.set('');
    const input = this.field()?.nativeElement;
    if (input) input.value = '';
  }

  focus(): void {
    this.field()?.nativeElement.focus();
  }

  protected onInput(event: Event): void {
    this.value.set((event.target as HTMLInputElement).value);
    this.edited.emit();
  }

  protected submit(event: Event): void {
    event.preventDefault();
    if (this.canSubmit()) this.submitted.emit(this.cleaned());
  }

  protected cancel(event: Event): void {
    if (!this.cancellable()) return;
    event.preventDefault();
    this.cancelled.emit();
  }
}

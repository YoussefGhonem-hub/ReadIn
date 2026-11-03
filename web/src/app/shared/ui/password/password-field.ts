import { ChangeDetectionStrategy, Component, ElementRef, computed, forwardRef, input, signal, viewChild } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { DEFAULT_PASSWORD_POLICY, PasswordPolicy, PasswordStrength, passwordChecklist, passwordStrength } from './password-rules';

const STRENGTH_LEVEL: Record<PasswordStrength, number> = { empty: 0, weak: 1, fair: 2, good: 3, strong: 4 };
const STRENGTH_COLOR: Record<PasswordStrength, string> = {
  empty: 'bg-border',
  weak: 'bg-error',
  fair: 'bg-callout-warning-accent',
  good: 'bg-primary',
  strong: 'bg-success',
};

/**
 * Password field (SPEC §9.4): show/hide toggle, always LTR, password-manager autofill hints (`current-password` /
 * `new-password`). With `showStrength`, a strength meter and the live rules checklist from `GET /auth/config`.
 * Rule *errors* (too common, contains the phone number…) are shown by the form, which knows the context.
 */
@Component({
  selector: 'rd-password-field',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => PasswordField), multi: true }],
  host: { class: 'block' },
  template: `
    <div class="rd-field-group" dir="ltr" [class.is-invalid]="invalid()" [class.is-disabled]="disabled()">
      <input
        #field
        class="rd-field-input"
        dir="ltr"
        [type]="visible() ? 'text' : 'password'"
        [id]="inputId()"
        [value]="value()"
        [attr.autocomplete]="autocomplete()"
        [attr.maxlength]="policy().maxLength"
        [attr.aria-invalid]="invalid() || null"
        [attr.aria-describedby]="describedByIds()"
        [disabled]="disabled()"
        autocapitalize="off"
        autocorrect="off"
        spellcheck="false"
        (input)="onInput($event)"
        (blur)="onTouched()"
      />
      <button
        type="button"
        class="rd-field-addon"
        [attr.aria-label]="(visible() ? 'password.hide' : 'password.show') | transloco"
        [attr.aria-pressed]="visible()"
        [attr.aria-controls]="inputId()"
        [disabled]="disabled()"
        (click)="visible.set(!visible())"
      >
        <svg [lucideIcon]="visible() ? 'EyeOff' : 'Eye'" [size]="18" aria-hidden="true"></svg>
      </button>
    </div>
    @if (showStrength()) {
      <div [id]="inputId() + '-strength'" class="mt-2">
        <div class="flex gap-1" aria-hidden="true">
          @for (bar of bars; track bar) {
            <span class="h-1 flex-1 rounded-chip transition-colors" [class]="bar <= level() ? barColor() : 'bg-border'"></span>
          }
        </div>
        @if (value()) {
          <p class="m-0 mt-1 text-xs text-text-secondary" aria-live="polite">
            {{ 'password.strength.label' | transloco }}: <strong class="font-semibold text-text-primary">{{ 'password.strength.' + strength() | transloco }}</strong>
          </p>
        }
      </div>
      <ul [id]="inputId() + '-rules'" class="m-0 mt-2 flex list-none flex-wrap gap-x-4 gap-y-1 p-0 text-xs" [attr.aria-label]="'password.rules.title' | transloco">
        @for (item of checklist(); track item.rule) {
          <li class="flex items-center gap-1.5" [class]="item.met ? 'text-success' : 'text-text-secondary'" [attr.data-rule]="item.rule" [attr.data-met]="item.met">
            <svg [lucideIcon]="item.met ? 'CircleCheck' : 'Circle'" [size]="14" aria-hidden="true"></svg>
            <span>{{ 'password.rules.' + item.rule | transloco: { min: policy().minLength } }}</span>
            <span class="rd-visually-hidden">{{ (item.met ? 'password.rules.met' : 'password.rules.notMet') | transloco }}</span>
          </li>
        }
      </ul>
    }
  `,
})
export class PasswordField implements ControlValueAccessor {
  readonly inputId = input.required<string>();
  readonly autocomplete = input<'current-password' | 'new-password'>('current-password');
  readonly invalid = input(false);
  readonly describedBy = input<string | null>(null);
  /** Strength meter + rules checklist (new passwords). */
  readonly showStrength = input(false);
  readonly policy = input<PasswordPolicy>(DEFAULT_PASSWORD_POLICY);
  /** The account's number (E.164), so the meter counts "contains your number" as weak. */
  readonly phone = input<string | null>(null);

  private readonly field = viewChild.required<ElementRef<HTMLInputElement>>('field');
  protected readonly value = signal('');
  protected readonly visible = signal(false);
  protected readonly disabled = signal(false);
  protected readonly bars = [1, 2, 3, 4];

  protected readonly checklist = computed(() => passwordChecklist(this.value(), this.policy()));
  protected readonly strength = computed(() => passwordStrength(this.value(), this.policy(), this.phone()));
  protected readonly level = computed(() => STRENGTH_LEVEL[this.strength()]);
  protected readonly barColor = computed(() => STRENGTH_COLOR[this.strength()]);
  protected readonly describedByIds = computed(() => {
    const ids = [this.describedBy(), this.showStrength() ? `${this.inputId()}-rules ${this.inputId()}-strength` : null].filter(Boolean);
    return ids.length ? ids.join(' ') : null;
  });

  private onChange: (value: string) => void = () => undefined;
  protected onTouched: () => void = () => undefined;

  focus(): void {
    this.field().nativeElement.focus();
  }

  writeValue(value: string | null): void {
    this.value.set(value ?? '');
  }

  registerOnChange(fn: (value: string) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(disabled: boolean): void {
    this.disabled.set(disabled);
  }

  protected onInput(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    this.value.set(value);
    this.onChange(value);
  }
}

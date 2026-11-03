import { ChangeDetectionStrategy, Component, ElementRef, computed, forwardRef, input, signal, viewChildren } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { digitsOnly } from '../../utils/digits';
import { DEFAULT_PIN_LENGTH } from './pin-rules';

/**
 * Recovery PIN input (SPEC §9.4): `length` boxes (from `GET /auth/config`), always LTR, numeric keyboard, masked with
 * a show/hide toggle, paste support, Arabic-Indic/Persian digits converted. The value is the digits typed so far.
 * Pair it with a label pointing at `{idPrefix}-0` (and `labelledBy` for the group).
 */
@Component({
  selector: 'rd-pin-input',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => PinInput), multi: true }],
  host: { class: 'block' },
  template: `
    <div class="flex flex-wrap items-center gap-2" dir="ltr" role="group" [attr.aria-labelledby]="labelledBy()" [attr.aria-describedby]="describedBy()">
      @for (index of indexes(); track index) {
        <input
          #box
          class="rd-pin-box"
          [id]="idPrefix() + '-' + index"
          [type]="visible() ? 'text' : 'password'"
          inputmode="numeric"
          pattern="[0-9]*"
          autocomplete="off"
          dir="ltr"
          [value]="digits()[index] ?? ''"
          [attr.aria-label]="'pin.digit' | transloco: { n: index + 1, total: length() }"
          [attr.aria-invalid]="invalid() || null"
          [disabled]="disabled()"
          (focus)="selectBox($event)"
          (input)="onInput(index, $event)"
          (keydown)="onKeydown(index, $event)"
          (paste)="onPaste(index, $event)"
          (blur)="onTouched()"
        />
      }
      <button
        type="button"
        class="rd-icon-btn ms-1 h-11 w-11"
        [attr.aria-label]="(visible() ? 'pin.hide' : 'pin.show') | transloco"
        [attr.aria-pressed]="visible()"
        [disabled]="disabled()"
        (click)="visible.set(!visible())"
      >
        <svg [lucideIcon]="visible() ? 'EyeOff' : 'Eye'" [size]="18" aria-hidden="true"></svg>
      </button>
    </div>
  `,
})
export class PinInput implements ControlValueAccessor {
  readonly idPrefix = input.required<string>();
  readonly length = input(DEFAULT_PIN_LENGTH);
  readonly labelledBy = input<string | null>(null);
  readonly describedBy = input<string | null>(null);
  readonly invalid = input(false);

  private readonly boxes = viewChildren<ElementRef<HTMLInputElement>>('box');
  protected readonly indexes = computed(() => Array.from({ length: this.length() }, (_, i) => i));
  protected readonly digits = signal<string[]>([]);
  protected readonly visible = signal(false);
  protected readonly disabled = signal(false);

  private onChange: (value: string) => void = () => undefined;
  protected onTouched: () => void = () => undefined;

  /** Focuses the first empty box (or the last one when the PIN is complete). */
  focus(): void {
    const boxes = this.boxes();
    const firstEmpty = this.indexes().find((i) => !this.digits()[i]);
    boxes[firstEmpty ?? boxes.length - 1]?.nativeElement.focus();
  }

  writeValue(value: string | null): void {
    this.digits.set(digitsOnly(value ?? '').slice(0, this.length()).split(''));
    this.syncBoxes();
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

  protected selectBox(event: FocusEvent): void {
    (event.target as HTMLInputElement).select();
  }

  protected onInput(index: number, event: Event): void {
    const box = event.target as HTMLInputElement;
    const previous = this.digits()[index] ?? '';
    let typed = digitsOnly(box.value);
    // Typing over a filled box whose text wasn't selected leaves both digits: keep the new one.
    if (previous && typed.length === 2 && typed.includes(previous)) typed = typed.replace(previous, '');
    if (!typed) {
      this.setDigits(index, '');
      this.syncBoxes();
      return;
    }
    this.fill(index, typed);
  }

  protected onPaste(index: number, event: ClipboardEvent): void {
    const pasted = digitsOnly(event.clipboardData?.getData('text') ?? '');
    event.preventDefault();
    if (!pasted) return;
    // A whole PIN fills from the first box; a few digits go where the caret is.
    this.fill(pasted.length >= this.length() ? 0 : index, pasted);
  }

  protected onKeydown(index: number, event: KeyboardEvent): void {
    const last = this.length() - 1;
    switch (event.key) {
      case 'Backspace':
        if (!this.digits()[index] && index > 0) {
          event.preventDefault();
          this.setDigits(index - 1, '');
          this.syncBoxes();
          this.focusBox(index - 1);
        }
        return;
      case 'Delete':
        event.preventDefault();
        this.setDigits(index, '');
        this.syncBoxes();
        return;
      case 'ArrowLeft':
        event.preventDefault();
        return this.focusBox(Math.max(0, index - 1));
      case 'ArrowRight':
        event.preventDefault();
        return this.focusBox(Math.min(last, index + 1));
      case 'Home':
        event.preventDefault();
        return this.focusBox(0);
      case 'End':
        event.preventDefault();
        return this.focusBox(last);
    }
  }

  private fill(start: number, typed: string): void {
    const next = [...this.digits()];
    let position = start;
    for (const digit of typed) {
      if (position > this.length() - 1) break;
      next[position++] = digit;
    }
    this.digits.set(next);
    this.emit();
    this.syncBoxes();
    this.focusBox(Math.min(position, this.length() - 1));
  }

  private setDigits(index: number, digit: string): void {
    const next = [...this.digits()];
    next[index] = digit;
    this.digits.set(next);
    this.emit();
  }

  private emit(): void {
    const value = this.indexes()
      .map((i) => this.digits()[i] ?? '')
      .join('');
    this.onChange(value);
  }

  /** Bindings skip unchanged values, so a rejected keystroke (a letter) is cleared here. */
  private syncBoxes(): void {
    this.boxes().forEach((box, i) => {
      const digit = this.digits()[i] ?? '';
      if (box.nativeElement.value !== digit) box.nativeElement.value = digit;
    });
  }

  private focusBox(index: number): void {
    this.boxes()[index]?.nativeElement.focus();
  }
}

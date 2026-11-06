import {
  ChangeDetectionStrategy,
  Component,
  ComponentRef,
  DestroyRef,
  ElementRef,
  Injector,
  PLATFORM_ID,
  ViewEncapsulation,
  computed,
  forwardRef,
  inject,
  input,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { AbstractControl, ControlValueAccessor, NG_VALIDATORS, NG_VALUE_ACCESSOR, ValidationErrors, Validator } from '@angular/forms';
import {
  OverlayRef,
  createBlockScrollStrategy,
  createFlexibleConnectedPositionStrategy,
  createGlobalPositionStrategy,
  createOverlayRef,
  createRepositionScrollStrategy,
} from '@angular/cdk/overlay';
import { ComponentPortal } from '@angular/cdk/portal';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { LanguageService } from '../../../core/i18n/language.service';
import { digitsOnly } from '../../utils/digits';
import { Country, countryByIso, countryName, defaultCountry, flagUrl, rememberCountry } from './countries';
import { CountryPicker } from './country-picker';
import { PhoneState, cleanPhoneText, examplePlaceholder, isValidMobileNumber, parsePhoneInput, phoneStateFromE164 } from './phone-number';

/** Below this width the country picker is a bottom sheet. */
const SHEET_QUERY = '(max-width: 639.98px)';

/**
 * Phone number field + country picker (SPEC §9.4). Always LTR. The value is the E.164 number ('' while empty);
 * invalid or incomplete numbers fail validation with `phoneInvalid`. Typing "+…" or pasting an international number
 * switches the country; Arabic-Indic and Persian digits are converted; the trunk prefix is stripped; the number is
 * grouped as you type. Pair it with `<label [for]="inputId">`.
 */
@Component({
  selector: 'rd-phone-field',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  // Its classes' rules (not in the global stylesheet, so they stay out of the initial bundle).
  encapsulation: ViewEncapsulation.None,
  styleUrl: './flag.css',
  providers: [
    { provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => PhoneField), multi: true },
    { provide: NG_VALIDATORS, useExisting: forwardRef(() => PhoneField), multi: true },
  ],
  host: { class: 'block' },
  template: `
    <div class="rd-field-group" dir="ltr" [class.is-invalid]="invalid()" [class.is-disabled]="disabled()">
      <button
        #trigger
        type="button"
        class="rd-field-addon border-0 border-e border-solid border-border"
        aria-haspopup="dialog"
        [attr.aria-expanded]="pickerOpen()"
        [attr.aria-label]="'phone.country' | transloco: { country: countryLabel(), dial: country().dialCode }"
        [disabled]="disabled()"
        (click)="openPicker()"
      >
        <img class="rd-flag" [src]="flag()" alt="" width="22" height="16" />
        <span class="font-latin text-text-primary">+{{ country().dialCode }}</span>
        <svg lucideIcon="ChevronDown" [size]="14" aria-hidden="true"></svg>
      </button>
      <input
        #field
        class="rd-field-input"
        type="tel"
        inputmode="tel"
        dir="ltr"
        [id]="inputId()"
        [value]="displayText()"
        [placeholder]="placeholder()"
        [attr.autocomplete]="autocomplete()"
        [attr.aria-invalid]="invalid() || null"
        [attr.aria-describedby]="describedBy()"
        [disabled]="disabled()"
        (input)="onInput($event)"
        (paste)="onPaste($event)"
        (blur)="markTouched()"
      />
    </div>
  `,
})
export class PhoneField implements ControlValueAccessor, Validator {
  readonly inputId = input.required<string>();
  /** `tel-national` (the dial code is separate); `username` on sign in, so password managers pair it. */
  readonly autocomplete = input('tel-national');
  readonly invalid = input(false);
  readonly describedBy = input<string | null>(null);
  /** The selected country changed (picker, pasted number). */
  readonly countryChange = output<string>();

  private readonly language = inject(LanguageService);
  private readonly injector = inject(Injector);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly field = viewChild.required<ElementRef<HTMLInputElement>>('field');
  private readonly trigger = viewChild.required<ElementRef<HTMLButtonElement>>('trigger');

  protected readonly state = signal<PhoneState>(parsePhoneInput('', this.isBrowser ? defaultCountry() : 'EG'));
  /** "+9" while an international number is too short to know its country. */
  private readonly pendingText = signal<string | null>(null);
  protected readonly disabled = signal(false);
  protected readonly pickerOpen = signal(false);

  protected readonly country = computed<Country>(() => countryByIso(this.state().country) ?? countryByIso('EG')!);
  protected readonly countryLabel = computed(() => countryName(this.country(), this.language.lang()));
  protected readonly flag = computed(() => flagUrl(this.country().iso2));
  protected readonly placeholder = computed(() => examplePlaceholder(this.country().iso2));
  protected readonly displayText = computed(() => this.pendingText() ?? this.state().display);

  private overlay: OverlayRef | null = null;
  private onChange: (value: string) => void = () => undefined;
  private onTouched: () => void = () => undefined;

  constructor() {
    inject(DestroyRef).onDestroy(() => this.closePicker(false));
  }

  /** ISO code of the selected country. */
  get selectedCountry(): string {
    return this.state().country;
  }

  focus(): void {
    this.field().nativeElement.focus();
  }

  writeValue(value: string | null): void {
    this.pendingText.set(null);
    this.state.set(value ? phoneStateFromE164(value, this.state().country) : parsePhoneInput('', this.state().country));
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

  validate(control: AbstractControl): ValidationErrors | null {
    const value = control.value as string | null;
    if (!value) return null; // `Validators.required` decides about empty fields
    return isValidMobileNumber(value) ? null : { phoneInvalid: true };
  }

  protected markTouched(): void {
    this.onTouched();
  }

  protected onInput(event: Event): void {
    const element = event.target as HTMLInputElement;
    const raw = element.value;
    const caret = element.selectionStart ?? raw.length;
    this.apply(raw, element, caret >= raw.length ? null : digitsOnly(raw.slice(0, caret)).length);
  }

  /** A pasted international number replaces the whole value (and switches the country). */
  protected onPaste(event: ClipboardEvent): void {
    const text = event.clipboardData?.getData('text') ?? '';
    if (!cleanPhoneText(text).startsWith('+')) return;
    event.preventDefault();
    this.apply(text, event.target as HTMLInputElement, null);
  }

  private apply(raw: string, element: HTMLInputElement, digitsBeforeCaret: number | null): void {
    const previous = this.state();
    const next = parsePhoneInput(raw, previous.country);
    this.pendingText.set(next.pending ? next.display : null);
    this.state.set(next);
    const shown = this.displayText();
    // Bindings don't rewrite the DOM when the formatted text didn't change (e.g. a letter was typed), so do it here.
    element.value = shown;
    if (digitsBeforeCaret !== null) {
      const position = caretAfterDigits(shown, digitsBeforeCaret);
      element.setSelectionRange(position, position);
    }
    if (next.country !== previous.country) {
      rememberCountry(next.country);
      this.countryChange.emit(next.country);
    }
    this.onChange(next.e164);
  }

  protected openPicker(): void {
    if (!this.isBrowser || this.overlay) return;
    const sheet = window.matchMedia(SHEET_QUERY).matches;
    const origin = this.host.nativeElement;
    this.overlay = createOverlayRef(this.injector, {
      hasBackdrop: true,
      backdropClass: sheet ? 'rd-overlay-scrim' : 'cdk-overlay-transparent-backdrop',
      direction: this.language.dir(),
      width: sheet ? '100%' : Math.max(origin.getBoundingClientRect().width, 320),
      maxWidth: sheet ? '100%' : 'calc(100vw - 32px)',
      scrollStrategy: sheet ? createBlockScrollStrategy(this.injector) : createRepositionScrollStrategy(this.injector),
      positionStrategy: sheet
        ? createGlobalPositionStrategy(this.injector).bottom('0').centerHorizontally()
        : createFlexibleConnectedPositionStrategy(this.injector, origin)
            .withPositions([
              { originX: 'start', originY: 'bottom', overlayX: 'start', overlayY: 'top', offsetY: 6 },
              { originX: 'start', originY: 'top', overlayX: 'start', overlayY: 'bottom', offsetY: -6 },
            ])
            .withViewportMargin(16)
            .withFlexibleDimensions(true)
            .withPush(true),
    });
    const ref: ComponentRef<CountryPicker> = this.overlay.attach(new ComponentPortal(CountryPicker, null, this.injector));
    ref.setInput('selected', this.state().country);
    ref.setInput('sheet', sheet);
    ref.instance.picked.subscribe((country) => this.selectCountry(country));
    ref.instance.closed.subscribe(() => this.closePicker(true));
    this.overlay.backdropClick().subscribe(() => this.closePicker(true));
    this.pickerOpen.set(true);
  }

  private selectCountry(country: Country): void {
    const previous = this.state().country;
    this.closePicker(false);
    // Keep the digits typed so far; they are re-read as a national number of the new country.
    const next = parsePhoneInput(this.state().national, country.iso2);
    this.pendingText.set(null);
    this.state.set({ ...next, country: country.iso2 });
    rememberCountry(country.iso2);
    if (country.iso2 !== previous) this.countryChange.emit(country.iso2);
    this.onChange(next.e164);
    this.focus();
  }

  private closePicker(restoreFocus: boolean): void {
    if (!this.overlay) return;
    this.overlay.dispose();
    this.overlay = null;
    this.pickerOpen.set(false);
    if (restoreFocus) this.trigger().nativeElement.focus();
  }
}

/** Index in `text` right after its `count`-th digit (end of text when there are fewer). */
export function caretAfterDigits(text: string, count: number): number {
  if (count <= 0) return 0;
  let seen = 0;
  for (let i = 0; i < text.length; i++) {
    if (/\d/.test(text[i]) && ++seen === count) return i + 1;
  }
  return text.length;
}

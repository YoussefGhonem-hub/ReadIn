import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormControl, ReactiveFormsModule, Validators } from '@angular/forms';
import { translocoTesting } from '../../../testing/transloco-testing';
import { provideAppIcons } from './icons';
import { PasswordField } from './password/password-field';
import { PhoneField } from './phone/phone-field';
import { PinInput } from './pin/pin-input';

@Component({
  imports: [ReactiveFormsModule, PhoneField, PasswordField, PinInput],
  template: `
    <rd-phone-field inputId="phone" [formControl]="phone" />
    <rd-password-field inputId="password" autocomplete="new-password" [formControl]="password" [showStrength]="strength()" />
    <rd-pin-input idPrefix="pin" [length]="4" [formControl]="pin" />
  `,
})
class Host {
  readonly phone = new FormControl('', { nonNullable: true, validators: Validators.required });
  readonly password = new FormControl('', { nonNullable: true });
  readonly pin = new FormControl('', { nonNullable: true });
  readonly strength = signal(true);
}

function setup() {
  localStorage.setItem('readin.phoneCountry', 'EG');
  TestBed.configureTestingModule({ imports: [Host, translocoTesting()], providers: [provideAppIcons()] });
  const fixture = TestBed.createComponent(Host);
  fixture.detectChanges();
  const root = fixture.nativeElement as HTMLElement;
  return { fixture, host: fixture.componentInstance, root };
}

function type(input: HTMLInputElement, value: string): void {
  input.value = value;
  input.dispatchEvent(new Event('input'));
}

function paste(input: HTMLInputElement, text: string): ClipboardEvent {
  const event = new Event('paste', { cancelable: true }) as ClipboardEvent;
  Object.defineProperty(event, 'clipboardData', { value: { getData: () => text } });
  input.dispatchEvent(event);
  return event;
}

describe('credential fields (SPEC §9.4)', () => {
  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => localStorage.removeItem('readin.phoneCountry'));

  describe('phone field', () => {
    it('is LTR, starts from the remembered country and emits E.164', () => {
      const { host, root, fixture } = setup();
      const input = root.querySelector<HTMLInputElement>('#phone')!;
      expect(root.querySelector('rd-phone-field .rd-field-group')!.getAttribute('dir')).toBe('ltr');
      expect(root.querySelector('rd-phone-field button')!.textContent).toContain('+20');

      type(input, '٠١٠٠١٢٣٤٥٦٧');
      fixture.detectChanges();
      expect(host.phone.value).toBe('+201001234567');
      expect(input.value).toBe('10 01234567');
      expect(host.phone.valid).toBe(true);
    });

    it('fails validation for a number that is not a mobile number', () => {
      const { host, root } = setup();
      type(root.querySelector<HTMLInputElement>('#phone')!, '0223456789');
      expect(host.phone.hasError('phoneInvalid')).toBe(true);
    });

    it('switches the country when an international number is pasted', () => {
      const { host, root, fixture } = setup();
      const input = root.querySelector<HTMLInputElement>('#phone')!;
      const event = paste(input, '+966 50 123 4567');
      fixture.detectChanges();
      expect(event.defaultPrevented).toBe(true);
      expect(host.phone.value).toBe('+966501234567');
      expect(root.querySelector('rd-phone-field button')!.textContent).toContain('+966');
      expect(localStorage.getItem('readin.phoneCountry')).toBe('SA');
    });

    it('shows a value written by the form', () => {
      const { host, root, fixture } = setup();
      host.phone.setValue('+12025550101');
      fixture.detectChanges();
      expect(root.querySelector<HTMLInputElement>('#phone')!.value).toBe('202 555 0101');
      expect(root.querySelector('rd-phone-field button')!.textContent).toContain('+1');
    });
  });

  describe('password field', () => {
    it('toggles visibility, stays LTR and shows the live rules', () => {
      const { host, root, fixture } = setup();
      const input = root.querySelector<HTMLInputElement>('#password')!;
      expect(input.type).toBe('password');
      expect(input.getAttribute('autocomplete')).toBe('new-password');
      expect(input.dir).toBe('ltr');

      type(input, 'abc');
      fixture.detectChanges();
      expect(host.password.value).toBe('abc');
      const met = [...root.querySelectorAll('[data-rule]')].map((li) => `${li.getAttribute('data-rule')}:${li.getAttribute('data-met')}`);
      expect(met).toEqual(['length:false', 'letter:true', 'digit:false']);

      root.querySelector<HTMLButtonElement>('rd-password-field button')!.click();
      fixture.detectChanges();
      expect(input.type).toBe('text');
      expect(root.querySelector('rd-password-field button')!.getAttribute('aria-pressed')).toBe('true');
    });
  });

  describe('PIN input', () => {
    function boxes(root: HTMLElement): HTMLInputElement[] {
      return [...root.querySelectorAll<HTMLInputElement>('rd-pin-input input')];
    }

    it('renders one masked, numeric, LTR box per digit', () => {
      const { root } = setup();
      expect(boxes(root)).toHaveLength(4);
      expect(boxes(root).every((b) => b.type === 'password' && b.inputMode === 'numeric')).toBe(true);
      expect(root.querySelector('rd-pin-input [role="group"]')!.getAttribute('dir')).toBe('ltr');
    });

    it('moves on as digits are typed, converting Arabic-Indic digits and refusing letters', () => {
      const { host, root, fixture } = setup();
      const [first, second] = boxes(root);
      type(first, '٤');
      type(second, 'x');
      fixture.detectChanges();
      expect(host.pin.value).toBe('4');
      expect(second.value).toBe('');
      type(second, '8');
      expect(host.pin.value).toBe('48');
    });

    it('spreads a pasted PIN over the boxes', () => {
      const { host, root, fixture } = setup();
      const event = paste(boxes(root)[2], ' ٤٨٢٩ ');
      fixture.detectChanges();
      expect(event.defaultPrevented).toBe(true);
      expect(host.pin.value).toBe('4829');
      expect(boxes(root).map((b) => b.value)).toEqual(['4', '8', '2', '9']);
    });

    it('goes back with Backspace on an empty box', () => {
      const { host, root, fixture } = setup();
      host.pin.setValue('48');
      fixture.detectChanges();
      const third = boxes(root)[2];
      third.dispatchEvent(new KeyboardEvent('keydown', { key: 'Backspace', cancelable: true }));
      fixture.detectChanges();
      expect(host.pin.value).toBe('4');
      expect(document.activeElement === boxes(root)[1] || !document.body.contains(boxes(root)[1])).toBe(true);
    });

    it('can show the digits', () => {
      const { root, fixture } = setup();
      root.querySelector<HTMLButtonElement>('rd-pin-input button')!.click();
      fixture.detectChanges();
      expect(boxes(root).every((b) => b.type === 'text')).toBe(true);
    });
  });
});

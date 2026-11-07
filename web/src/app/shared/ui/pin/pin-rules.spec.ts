import { normalizePin, pinViolations } from './pin-rules';

describe('recovery PIN rules (SPEC §9.4, ADR 0009)', () => {
  it('accepts any digits of the configured length', () => {
    expect(pinViolations('4829')).toEqual([]);
    expect(pinViolations('7305', 4)).toEqual([]);
  });

  it.each([
    ['one repeated digit', '7777'],
    ['one repeated digit (1111)', '1111'],
    ['two repeated pairs', '5566'],
    ['an ascending run', '3456'],
    ['an ascending run (1234)', '1234'],
    ['a descending run', '9876'],
    ['a common PIN', '1212'],
    ['a common PIN (2580)', '2580'],
    ['a year from 1950', '1950'],
    ['a year (1990)', '1990'],
    ['a year up to 2030', '2030'],
  ])('accepts %s (no weak-PIN rule any more)', (_kind, pin) => {
    expect(pinViolations(pin)).toEqual([]);
  });

  it('accepts years outside 1950–2030', () => {
    expect(pinViolations('1949')).toEqual([]);
    expect(pinViolations('2031')).toEqual([]);
  });

  it('accepts the last digits of the phone number', () => {
    // The phone number +201001234583 ends in 4583: still a valid PIN.
    expect(pinViolations('4583')).toEqual([]);
  });

  it('accepts the first digits of the password', () => {
    // The password "ab8306cd9" starts with the digits 8306: still a valid PIN.
    expect(pinViolations('8306')).toEqual([]);
  });

  it('checks the length and digits', () => {
    expect(pinViolations('482')).toEqual(['pin.length']);
    expect(pinViolations('')).toEqual(['pin.length']);
    expect(pinViolations('48a9')).toEqual(['pin.digits_only']);
    expect(pinViolations('482917', 6)).toEqual([]);
    expect(pinViolations('4829', 6)).toEqual(['pin.length']);
  });

  it('accepts any 6 digits when the length is 6', () => {
    expect(pinViolations('199500', 6)).toEqual([]);
    expect(pinViolations('123456', 6)).toEqual([]);
  });

  it('converts Arabic-Indic and Persian digits', () => {
    expect(normalizePin(' ٤٨٢٩ ')).toBe('4829');
    expect(normalizePin('۴۸۲۹')).toBe('4829');
    expect(pinViolations('٤٨٢٩')).toEqual([]);
    expect(pinViolations('١٢٣٤')).toEqual([]);
  });
});

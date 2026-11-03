import { isWeakPin, normalizePin, pinViolations } from './pin-rules';

describe('recovery PIN rules (SPEC §9.4, ADR 0009)', () => {
  it('accepts a PIN that is none of the weak kinds', () => {
    expect(pinViolations('4829')).toEqual([]);
    expect(pinViolations('7305', 4, { phoneE164: '+201001234567', password: 'Nile river 2026' })).toEqual([]);
  });

  it.each([
    ['one repeated digit', '7777'],
    ['an ascending run', '3456'],
    ['a descending run', '9876'],
    ['a common PIN', '1212'],
    ['a common PIN (2580)', '2580'],
    ['a year from 1950', '1950'],
    ['a year up to 2030', '2030'],
  ])('rejects %s', (_kind, pin) => {
    expect(pinViolations(pin)).toEqual(['pin.weak']);
  });

  it('accepts years outside 1950–2030', () => {
    expect(isWeakPin('1949')).toBe(false);
    expect(isWeakPin('2031')).toBe(false);
  });

  it('rejects the last digits of the phone number', () => {
    expect(isWeakPin('4583', { phoneE164: '+201001234583' })).toBe(true);
    expect(isWeakPin('4583', { phoneE164: '+201001234567' })).toBe(false);
  });

  it('rejects the first digits of the password', () => {
    expect(isWeakPin('8306', { password: 'ab8306cd9' })).toBe(true);
    expect(isWeakPin('8306', { password: 'ab83' })).toBe(false); // fewer digits than the PIN
    expect(isWeakPin('8306', { password: 'x9x8306' })).toBe(false); // not the first digits
  });

  it('checks the length and digits first', () => {
    expect(pinViolations('482')).toEqual(['pin.length']);
    expect(pinViolations('')).toEqual(['pin.length']);
    expect(pinViolations('48a9')).toEqual(['pin.digits_only']);
    expect(pinViolations('482917', 6)).toEqual([]);
    expect(pinViolations('4829', 6)).toEqual(['pin.length']);
  });

  it('applies the common-PIN and year lists to 4 digits only, like the API', () => {
    expect(isWeakPin('199500')).toBe(false);
    expect(isWeakPin('123456')).toBe(true); // still a run
  });

  it('converts Arabic-Indic and Persian digits', () => {
    expect(normalizePin(' ٤٨٢٩ ')).toBe('4829');
    expect(normalizePin('۴۸۲۹')).toBe('4829');
    expect(pinViolations('٤٨٢٩')).toEqual([]);
    expect(pinViolations('١٢٣٤')).toEqual(['pin.weak']);
  });
});

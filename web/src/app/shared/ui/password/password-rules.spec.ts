import { DEFAULT_PASSWORD_POLICY, containsPhoneNumber, passwordChecklist, passwordStrength, passwordViolations } from './password-rules';

describe('password rules (SPEC §9.4)', () => {
  it('accepts 8–128 characters with a letter and a digit', () => {
    expect(passwordViolations('Nile river 2026')).toEqual([]);
    expect(passwordViolations('qwmz7xkp')).toEqual([]);
    expect(passwordViolations('abcdefg1')).toEqual(['password.too_common']);
  });

  it('reports every rule that fails, in the API order', () => {
    expect(passwordViolations('')).toEqual(['password.too_short']);
    expect(passwordViolations('abc')).toEqual(['password.too_short', 'password.digit_required']);
    expect(passwordViolations('12345678')).toEqual(['password.letter_required']);
    expect(passwordViolations('abcdefgh')).toEqual(['password.digit_required']);
    expect(passwordViolations(`${'a'.repeat(128)}1`)).toEqual(['password.too_long']);
  });

  it('counts Arabic letters and Arabic-Indic digits', () => {
    expect(passwordViolations('كلمةسرطويلة٢٠٢٦')).toEqual([]);
  });

  it('rejects common passwords (case-insensitively), only once the other rules pass', () => {
    expect(passwordViolations('Password1')).toEqual(['password.too_common']);
    expect(passwordViolations('QWERTY123')).toEqual(['password.too_common']);
  });

  it('rejects a password that contains the phone number', () => {
    const phone = '+201001234567';
    expect(passwordViolations('mona1001234567', DEFAULT_PASSWORD_POLICY, phone)).toEqual(['password.contains_phone']);
    expect(passwordViolations('x201001234567y', DEFAULT_PASSWORD_POLICY, phone)).toEqual(['password.contains_phone']);
    expect(passwordViolations('mona١٠٠١٢٣٤٥٦٧', DEFAULT_PASSWORD_POLICY, phone)).toEqual(['password.contains_phone']);
    expect(passwordViolations('mona01001234', DEFAULT_PASSWORD_POLICY, phone)).toEqual([]);
    expect(containsPhoneNumber('anything', null)).toBe(false);
  });

  it('follows the policy from GET /auth/config', () => {
    const relaxed = { minLength: 6, maxLength: 20, requireLetter: false, requireDigit: false };
    expect(passwordViolations('secret', relaxed)).toEqual([]);
    expect(passwordChecklist('secret', relaxed)).toEqual([{ rule: 'length', met: true }]);
  });

  it('drives the live checklist', () => {
    expect(passwordChecklist('abc')).toEqual([
      { rule: 'length', met: false },
      { rule: 'letter', met: true },
      { rule: 'digit', met: false },
    ]);
  });

  it('estimates strength for the meter', () => {
    expect(passwordStrength('')).toBe('empty');
    expect(passwordStrength('abc')).toBe('weak');
    expect(passwordStrength('Password1')).toBe('weak'); // too common
    expect(passwordStrength('mona1001234567', DEFAULT_PASSWORD_POLICY, '+201001234567')).toBe('weak');
    expect(passwordStrength('nile2026')).toBe('fair');
    expect(passwordStrength('nileriver2026')).toBe('good');
    expect(passwordStrength('Nile river 2026')).toBe('strong');
    expect(passwordStrength('Cairo Tower 1961! by the Nile')).toBe('strong');
  });
});

import COMMON_PASSWORDS_TEXT from '../../../../../../shared/security/common-passwords.txt';
import { digitsOnly } from '../../utils/digits';
import { nationalNumberOf } from '../phone/phone-number';

/** Password rules from `GET /auth/config` (SPEC §9.4); the API re-checks everything. */
export interface PasswordPolicy {
  minLength: number;
  maxLength: number;
  requireLetter: boolean;
  requireDigit: boolean;
}

export const DEFAULT_PASSWORD_POLICY: PasswordPolicy = { minLength: 8, maxLength: 128, requireLetter: true, requireDigit: true };

export type PasswordCode =
  | 'password.too_short'
  | 'password.too_long'
  | 'password.letter_required'
  | 'password.digit_required'
  | 'password.too_common'
  | 'password.contains_phone';

/** `shared/security/common-passwords.txt`: common passwords that would otherwise pass the rules (lower-cased). */
const COMMON_PASSWORDS = new Set(
  COMMON_PASSWORDS_TEXT.split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean),
);

const LETTER = /\p{L}/u;
const DIGIT = /\p{Nd}/u;

/** True when the password's digits contain the phone number (national number of 6+ digits, or the full E.164). */
export function containsPhoneNumber(password: string, phoneE164: string | null | undefined): boolean {
  if (!phoneE164) return false;
  const digits = digitsOnly(password);
  const national = nationalNumberOf(phoneE164) ?? '';
  return national.length >= 6 && (digits.includes(national) || digits.includes(phoneE164.replace(/^\+/, '')));
}

/** Mirrors the API's `PasswordRules.Check`: the codes a password violates, in the API's order. */
export function passwordViolations(password: string, policy: PasswordPolicy = DEFAULT_PASSWORD_POLICY, phoneE164?: string | null): PasswordCode[] {
  if (!password) return ['password.too_short'];
  const codes: PasswordCode[] = [];
  if (password.length < policy.minLength) codes.push('password.too_short');
  if (password.length > policy.maxLength) codes.push('password.too_long');
  if (policy.requireLetter && !LETTER.test(password)) codes.push('password.letter_required');
  if (policy.requireDigit && !DIGIT.test(password)) codes.push('password.digit_required');
  if (codes.length === 0 && COMMON_PASSWORDS.has(password.toLowerCase())) codes.push('password.too_common');
  if (containsPhoneNumber(password, phoneE164)) codes.push('password.contains_phone');
  return codes;
}

export type PasswordRule = 'length' | 'letter' | 'digit';

/** The live checklist under a new password: "8+ characters", "a letter", "a digit". */
export function passwordChecklist(password: string, policy: PasswordPolicy = DEFAULT_PASSWORD_POLICY): { rule: PasswordRule; met: boolean }[] {
  const items: { rule: PasswordRule; met: boolean }[] = [
    { rule: 'length', met: password.length >= policy.minLength && password.length <= policy.maxLength },
  ];
  if (policy.requireLetter) items.push({ rule: 'letter', met: LETTER.test(password) });
  if (policy.requireDigit) items.push({ rule: 'digit', met: DIGIT.test(password) });
  return items;
}

export type PasswordStrength = 'empty' | 'weak' | 'fair' | 'good' | 'strong';

/**
 * A simple strength estimate for the meter: anything that breaks a rule is weak; then length and variety
 * (upper/lower case, symbols, 12+ and 16+ characters) move it up.
 */
export function passwordStrength(password: string, policy: PasswordPolicy = DEFAULT_PASSWORD_POLICY, phoneE164?: string | null): PasswordStrength {
  if (!password) return 'empty';
  if (passwordViolations(password, policy, phoneE164).length > 0) return 'weak';
  let score = 0;
  if (password.length >= 12) score++;
  if (password.length >= 16) score++;
  if (/\p{Lu}/u.test(password) && /\p{Ll}/u.test(password)) score++;
  if (/[^\p{L}\p{Nd}]/u.test(password)) score++;
  if (new Set(password).size >= 8) score++;
  return score <= 1 ? 'fair' : score <= 3 ? 'good' : 'strong';
}

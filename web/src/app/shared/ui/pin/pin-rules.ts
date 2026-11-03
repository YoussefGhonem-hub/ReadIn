import COMMON_PINS_TEXT from '../../../../../../shared/security/common-pins.txt';
import { digitsOnly, toAsciiDigits } from '../../utils/digits';

/** Recovery PIN rules (SPEC §9.4, ADR 0009). Mirrors the API's `RecoveryPinRules`; the API re-checks everything. */
export type PinCode = 'pin.length' | 'pin.digits_only' | 'pin.weak';

export const DEFAULT_PIN_LENGTH = 4;

/** `shared/security/common-pins.txt`: the 100 most common 4-digit PINs. */
const COMMON_PINS = new Set(
  COMMON_PINS_TEXT.split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean),
);

/** Arabic-Indic/Persian digits → ASCII, surrounding spaces removed. */
export function normalizePin(pin: string | null | undefined): string {
  return pin ? toAsciiDigits(pin).trim() : '';
}

function isRun(pin: string, step: 1 | -1): boolean {
  for (let i = 1; i < pin.length; i++) {
    if (pin.charCodeAt(i) - pin.charCodeAt(i - 1) !== step) return false;
  }
  return true;
}

/**
 * Weak PINs: one repeated digit, an ascending/descending run, a common PIN, a year 1950–2030 (4 digits only), the last
 * digits of the phone number, or the first digits of the password.
 */
export function isWeakPin(pin: string, context: { phoneE164?: string | null; password?: string | null } = {}): boolean {
  if (new Set(pin).size === 1) return true;
  if (isRun(pin, 1) || isRun(pin, -1)) return true;
  if (pin.length === 4) {
    if (COMMON_PINS.has(pin)) return true;
    const year = Number(pin);
    if (year >= 1950 && year <= 2030) return true;
  }
  if (context.phoneE164 && context.phoneE164.endsWith(pin)) return true;
  if (context.password) {
    const passwordDigits = digitsOnly(context.password);
    if (passwordDigits.length >= pin.length && passwordDigits.startsWith(pin)) return true;
  }
  return false;
}

/** The codes a PIN violates (empty when it's fine). `pin` is normalized first. */
export function pinViolations(
  rawPin: string,
  length: number = DEFAULT_PIN_LENGTH,
  context: { phoneE164?: string | null; password?: string | null } = {},
): PinCode[] {
  const pin = normalizePin(rawPin);
  if (!/^\d*$/.test(pin)) return ['pin.digits_only'];
  if (pin.length !== length) return ['pin.length'];
  return isWeakPin(pin, context) ? ['pin.weak'] : [];
}

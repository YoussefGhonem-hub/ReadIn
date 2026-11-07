import { toAsciiDigits } from '../../utils/digits';

/**
 * Recovery PIN rules (SPEC §9.4, ADR 0009): any digits of the configured length. Mirrors the API's `RecoveryPinRules`;
 * the API re-checks everything.
 */
export type PinCode = 'pin.length' | 'pin.digits_only';

export const DEFAULT_PIN_LENGTH = 4;

/** Arabic-Indic/Persian digits → ASCII, surrounding spaces removed. */
export function normalizePin(pin: string | null | undefined): string {
  return pin ? toAsciiDigits(pin).trim() : '';
}

/** The codes a PIN violates (empty when it's fine). `pin` is normalized first. */
export function pinViolations(rawPin: string, length: number = DEFAULT_PIN_LENGTH): PinCode[] {
  const pin = normalizePin(rawPin);
  if (!/^\d*$/.test(pin)) return ['pin.digits_only'];
  if (pin.length !== length) return ['pin.length'];
  return [];
}

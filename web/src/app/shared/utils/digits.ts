/**
 * Arabic-Indic (٠-٩) and Persian (۰-۹) digits → ASCII 0-9 (SPEC §9.4). Phone numbers, passwords and PINs are typed
 * with whatever keyboard the user has; the API always receives Western digits (SPEC §14.2 rule 4).
 */
export function toAsciiDigits(value: string): string {
  // U+0660 and U+06F0 both end in 0, so the low nibble is the digit.
  return value.replace(/[٠-٩۰-۹]/g, (digit) => String(digit.charCodeAt(0) & 0xf));
}

/** Only the ASCII digits of `value`, after converting Arabic-Indic and Persian digits. */
export function digitsOnly(value: string): string {
  return toAsciiDigits(value).replace(/\D/g, '');
}

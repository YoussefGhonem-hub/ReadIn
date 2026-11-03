import { AsYouType, CountryCode, Metadata, isValidPhoneNumber, parsePhoneNumberFromString } from 'libphonenumber-js/mobile';
import { toAsciiDigits } from '../../utils/digits';
import { COUNTRIES, countryByIso } from './countries';

/**
 * Phone number rules shared by every phone field (SPEC §9.4), on top of libphonenumber-js with the **mobile**
 * metadata, so only mobile numbers are valid (like the API). The field shows the national significant number next to
 * the country's dial code and always emits E.164.
 */
export interface PhoneState {
  /** ISO 3166-1 alpha-2 of the selected country. */
  country: string;
  /** National significant number digits: no trunk prefix ("0" in Egypt), no dial code. */
  national: string;
  /** What the input shows: the national number grouped as you type, e.g. "100 123 4567". */
  display: string;
  /** `+{dial}{national}`, or '' when nothing was typed. */
  e164: string;
  /** A valid mobile number for the country. */
  valid: boolean;
}

/** E.164 allows at most 15 digits, dial code included. */
const MAX_DIGITS = 15;

/**
 * ASCII digits only, keeping a leading "+" (Arabic-Indic/Persian digits converted). A leading "00" (international
 * dialing prefix) becomes "+", so pasting "0020 100…" works like "+20 100…".
 */
export function cleanPhoneText(raw: string): string {
  const text = toAsciiDigits(raw).trim();
  const digits = text.replace(/\D/g, '');
  if (text.startsWith('+')) return `+${digits}`;
  if (digits.startsWith('00')) return `+${digits.slice(2)}`;
  return digits;
}

type MetadataWithCallingCodes = Metadata & { getCountryCodesForCallingCode?(callingCode: string): string[] | undefined };

/** The main country of a calling code ("+1" → US, "+44" → GB), as libphonenumber orders them. */
export function mainCountryFor(callingCode: string): string | undefined {
  try {
    const main = (new Metadata() as MetadataWithCallingCodes).getCountryCodesForCallingCode?.(callingCode)?.[0];
    if (main && countryByIso(main)) return main;
  } catch {
    /* unknown calling code */
  }
  return COUNTRIES.find((c) => c.dialCode === callingCode)?.iso2;
}

export function dialCodeOf(country: string): string {
  return countryByIso(country)?.dialCode ?? '';
}

/** Groups the national number the way libphonenumber formats it internationally, without the dial code. */
export function formatNationalDisplay(country: string, national: string): string {
  if (!national) return '';
  const dial = dialCodeOf(country);
  const formatted = new AsYouType().input(`+${dial}${national}`);
  const prefix = `+${dial}`;
  return formatted.startsWith(prefix) ? formatted.slice(prefix.length).trim() : national;
}

export function isValidMobileNumber(e164: string): boolean {
  try {
    return /^\+\d{4,15}$/.test(e164) && isValidPhoneNumber(e164);
  } catch {
    return false;
  }
}

function build(country: string, rawNational: string): PhoneState {
  const dial = dialCodeOf(country);
  const national = rawNational.slice(0, Math.max(0, MAX_DIGITS - dial.length));
  const e164 = national ? `+${dial}${national}` : '';
  const valid = !!national && isValidMobileNumber(e164);
  // A valid number may belong to another country with the same dial code (+1 268… is Antigua): show its flag.
  const owner = valid ? parsePhoneNumberFromString(e164)?.country : undefined;
  const resolved = owner && owner !== country && countryByIso(owner)?.dialCode === dial ? owner : country;
  return { country: resolved, national, display: formatNationalDisplay(resolved, national), e164, valid };
}

/**
 * Parses what the user typed or pasted into the field while `country` is selected:
 * - an international number ("+966…", "00966…") switches the country;
 * - a national number has its trunk prefix stripped ("0100…" → "100…" for Egypt);
 * - Arabic-Indic and Persian digits are converted.
 * Returns `pending: true` while an international number is too short to know its country ("+9").
 */
export function parsePhoneInput(raw: string, country: string): PhoneState & { pending?: boolean } {
  const text = cleanPhoneText(raw);
  if (text.startsWith('+')) {
    const typer = new AsYouType();
    typer.input(text.slice(0, MAX_DIGITS + 1));
    const callingCode = typer.getCallingCode();
    if (!callingCode) return { country, national: '', display: text, e164: '', valid: false, pending: true };
    const detected = typer.getCountry() ?? typer.getNumber()?.country;
    const target =
      detected && countryByIso(detected)
        ? detected
        : dialCodeOf(country) === callingCode
          ? country
          : (mainCountryFor(callingCode) ?? country);
    return build(target, typer.getNumber()?.nationalNumber ?? '');
  }

  const typer = new AsYouType(country as CountryCode);
  typer.input(text);
  return build(country, typer.getNumber()?.nationalNumber ?? '');
}

/** State for a stored E.164 value (e.g. when a form is pre-filled). */
export function phoneStateFromE164(e164: string | null | undefined, fallbackCountry: string): PhoneState {
  if (!e164) return build(fallbackCountry, '');
  const parsed = parsePhoneNumberFromString(e164);
  if (!parsed) return parsePhoneInput(e164, fallbackCountry);
  const country = parsed.country ?? mainCountryFor(parsed.countryCallingCode) ?? fallbackCountry;
  return build(country, parsed.nationalNumber);
}

/** "+20 100 123 4567": how a full number is shown to its owner (confirm dialog, settings). Always render it LTR. */
export function formatPhoneForDisplay(e164: string | null | undefined): string {
  if (!e164) return '';
  return parsePhoneNumberFromString(e164)?.formatInternational() ?? e164;
}

/** The national significant number of an E.164 number ("1001234567" for "+201001234567"). */
export function nationalNumberOf(e164: string | null | undefined): string | null {
  if (!e164) return null;
  return parsePhoneNumberFromString(e164)?.nationalNumber ?? e164.replace(/^\+/, '');
}

/** Placeholder for the field: the country's example mobile number, without trunk prefix ("100 123 4567"). */
export function examplePlaceholder(country: string): string {
  const example = countryByIso(country)?.exampleNational ?? '';
  if (!example) return '';
  const national = parsePhoneNumberFromString(example, country as CountryCode)?.nationalNumber;
  return national ? formatNationalDisplay(country, national) : example;
}

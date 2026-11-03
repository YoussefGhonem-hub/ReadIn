import { browserRegion, countryByIso, defaultCountry, flagUrl, foldSearchText, rememberCountry, searchCountries, sortedCountries } from './countries';
import {
  cleanPhoneText,
  examplePlaceholder,
  formatPhoneForDisplay,
  isValidMobileNumber,
  mainCountryFor,
  nationalNumberOf,
  parsePhoneInput,
  phoneStateFromE164,
} from './phone-number';
import { caretAfterDigits } from './phone-field';

describe('phone numbers (SPEC §9.4)', () => {
  describe('parsePhoneInput', () => {
    it('strips the trunk prefix and emits E.164', () => {
      const state = parsePhoneInput('01001234567', 'EG');
      expect(state).toMatchObject({ country: 'EG', national: '1001234567', e164: '+201001234567', valid: true });
      expect(state.display).toBe('10 01234567');
    });

    it('converts Arabic-Indic and Persian digits', () => {
      expect(parsePhoneInput('٠١٠٠١٢٣٤٥٦٧', 'EG').e164).toBe('+201001234567');
      expect(parsePhoneInput('۰۱۰۰۱۲۳۴۵۶۷', 'EG').e164).toBe('+201001234567');
    });

    it('ignores spaces, dashes and letters', () => {
      expect(parsePhoneInput('010-0123 4567x', 'EG').e164).toBe('+201001234567');
    });

    it('switches the country for an international number, with "+" or "00"', () => {
      expect(parsePhoneInput('+966 50 123 4567', 'EG')).toMatchObject({ country: 'SA', e164: '+966501234567', valid: true });
      expect(parsePhoneInput('00971501234567', 'EG')).toMatchObject({ country: 'AE', e164: '+971501234567', valid: true });
    });

    it('waits while an international number is too short to know the country', () => {
      const state = parsePhoneInput('+9', 'EG');
      expect(state).toMatchObject({ country: 'EG', e164: '', valid: false, pending: true, display: '+9' });
    });

    it('keeps the selected country when it shares the calling code', () => {
      expect(parsePhoneInput('+1', 'CA').country).toBe('CA');
      expect(parsePhoneInput('+1', 'EG').country).toBe('US');
    });

    it('accepts mobile numbers only', () => {
      expect(parsePhoneInput('0223456789', 'EG').valid).toBe(false); // Cairo landline
      expect(parsePhoneInput('0100123', 'EG').valid).toBe(false); // too short
      expect(parsePhoneInput('2025550101', 'US').valid).toBe(true); // the seed users' fictional range
    });

    it('shows the flag of the number that matched within a shared calling code', () => {
      expect(parsePhoneInput('2684641234', 'US')).toMatchObject({ country: 'AG', e164: '+12684641234' });
    });

    it('is empty for no digits', () => {
      expect(parsePhoneInput('', 'EG')).toEqual({ country: 'EG', national: '', display: '', e164: '', valid: false });
      expect(parsePhoneInput('0', 'EG').e164).toBe('');
    });

    it('never exceeds 15 digits', () => {
      const state = parsePhoneInput('1'.repeat(30), 'EG');
      expect(state.e164.length).toBeLessThanOrEqual(16);
    });
  });

  it('cleans pasted text', () => {
    expect(cleanPhoneText(' +20 (100) 123-4567 ')).toBe('+201001234567');
    expect(cleanPhoneText('0020100')).toBe('+20100');
    expect(cleanPhoneText('١٢٣')).toBe('123');
  });

  it('validates E.164 mobile numbers', () => {
    expect(isValidMobileNumber('+201001234567')).toBe(true);
    expect(isValidMobileNumber('201001234567')).toBe(false);
    expect(isValidMobileNumber('+20223456789')).toBe(false);
    expect(isValidMobileNumber('')).toBe(false);
  });

  it('restores a stored number', () => {
    expect(phoneStateFromE164('+966501234567', 'EG')).toMatchObject({ country: 'SA', national: '501234567', valid: true });
    expect(phoneStateFromE164(null, 'EG')).toMatchObject({ country: 'EG', e164: '' });
  });

  it('formats for display and finds the national number', () => {
    expect(formatPhoneForDisplay('+201001234567')).toBe('+20 10 01234567');
    expect(formatPhoneForDisplay(null)).toBe('');
    expect(nationalNumberOf('+201001234567')).toBe('1001234567');
  });

  it('uses the example mobile number without trunk prefix as placeholder', () => {
    expect(examplePlaceholder('EG')).toBe('10 01234567');
    expect(examplePlaceholder('US')).toBe('201 555 0123');
  });

  it('knows the main country of a calling code', () => {
    expect(mainCountryFor('1')).toBe('US');
    expect(mainCountryFor('44')).toBe('GB');
    expect(mainCountryFor('20')).toBe('EG');
  });

  it('keeps the caret after the same digit when reformatting', () => {
    expect(caretAfterDigits('10 01234567', 3)).toBe(4);
    expect(caretAfterDigits('10 01234567', 0)).toBe(0);
    expect(caretAfterDigits('10', 5)).toBe(2);
  });
});

describe('countries (shared/countries/countries.json)', () => {
  it('lists the pinned Arab countries first, Egypt on top, then the rest by name', () => {
    const ar = sortedCountries('ar');
    expect(ar.slice(0, 3).map((c) => c.iso2)).toEqual(['EG', 'SA', 'AE']);
    const en = sortedCountries('en');
    const rest = en.slice(18).map((c) => c.nameEn);
    expect(rest).toEqual([...rest].sort((a, b) => a.localeCompare(b, 'en', { sensitivity: 'base' })));
    expect(en).toHaveLength(ar.length);
  });

  it('searches by Arabic name, English name, ISO code and dial code', () => {
    const all = sortedCountries('en');
    expect(searchCountries(all, 'مصر')[0].iso2).toBe('EG');
    expect(searchCountries(all, 'الامارات')[0].iso2).toBe('AE'); // without the hamza
    expect(searchCountries(all, 'egy')[0].iso2).toBe('EG');
    expect(searchCountries(all, 'sa')[0].iso2).toBe('SA');
    expect(searchCountries(all, '+966').map((c) => c.iso2)).toEqual(['SA']);
    expect(searchCountries(all, '00971').map((c) => c.iso2)).toEqual(['AE']);
    expect(searchCountries(all, '٩٦٦').map((c) => c.iso2)).toEqual(['SA']);
    expect(searchCountries(all, 'cote')[0].iso2).toBe('CI');
    expect(searchCountries(all, '')).toHaveLength(all.length);
    expect(searchCountries(all, 'zzzz')).toEqual([]);
  });

  it('folds Arabic and Latin text for matching', () => {
    expect(foldSearchText('  Côte  d’Ivoire ')).toBe('cote d ivoire');
    expect(foldSearchText('أَلْجَزَائِر')).toBe('الجزاير');
  });

  it('defaults to the last used country, then the browser region, then Egypt', () => {
    localStorage.removeItem('readin.phoneCountry');
    expect(defaultCountry(['en'])).toBe('EG');
    expect(defaultCountry(['ar-SA', 'en-US'])).toBe('SA');
    rememberCountry('kw');
    expect(defaultCountry(['ar-SA'])).toBe('KW');
    localStorage.removeItem('readin.phoneCountry');
    expect(browserRegion(['xx', 'fr-FR'])).toBe('FR');
  });

  it('has an SVG flag for every country', () => {
    expect(flagUrl('EG')).toBe('/flags/eg.svg');
    expect(flagUrl('AC')).toBe('/flags/sh-ac.svg');
    expect(countryByIso('eg')?.dialCode).toBe('20');
  });
});

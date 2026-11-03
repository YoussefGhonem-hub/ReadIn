import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/phone/countries.dart';
import 'package:readin/core/phone/phone_numbers.dart';
import 'package:readin/core/storage/key_value_store.dart';

void main() {
  group('normalizeNational', () {
    test('converts Arabic-Indic and Persian digits and drops separators', () {
      expect(PhoneNumbers.normalizeNational('١٠٠ ١٢٣-٤٥٦٧', 'EG'), '1001234567');
      expect(PhoneNumbers.normalizeNational('۱۰۰ (۱۲۳) ۴۵۶۷', 'EG'), '1001234567');
    });

    test('strips the trunk prefix people type', () {
      expect(PhoneNumbers.normalizeNational('01001234567', 'EG'), '1001234567');
      expect(PhoneNumbers.normalizeNational('0', 'EG'), '');
      expect(PhoneNumbers.normalizeNational('0501234567', 'SA'), '501234567');
      expect(PhoneNumbers.normalizeNational('1 202 555 0101', 'US'), '2025550101');
    });

    test('caps the length at the longest national number', () {
      expect(PhoneNumbers.normalizeNational('100123456789999', 'EG'), '1001234567');
    });
  });

  group('formatNational', () {
    test('formats as you type', () {
      expect(PhoneNumbers.formatNational('1001234567', 'EG'), '10 01234567'); // libphonenumber's Egyptian format
      expect(PhoneNumbers.formatNational('100', 'EG'), '10 0');
      expect(PhoneNumbers.formatNational('2025550101', 'US'), '(202) 555-0101');
      expect(PhoneNumbers.formatNational('', 'EG'), '');
    });
  });

  group('toE164', () {
    test('accepts valid mobile numbers only', () {
      expect(PhoneNumbers.toE164('1001234567', 'EG'), '+201001234567');
      expect(PhoneNumbers.toE164('501234567', 'SA'), '+966501234567');
      expect(PhoneNumbers.toE164('2025550101', 'US'), '+12025550101'); // seed users (SPEC §18.3)
      expect(PhoneNumbers.toE164('234567890', 'EG'), isNull); // Cairo landline
      expect(PhoneNumbers.toE164('100123', 'EG'), isNull);
      expect(PhoneNumbers.toE164('', 'EG'), isNull);
    });
  });

  group('parseInternational', () {
    test('switches the country for pasted international numbers', () {
      expect(PhoneNumbers.parseInternational('+966 50 123 4567'), (iso2: 'SA', national: '501234567'));
      expect(PhoneNumbers.parseInternational('00201001234567'), (iso2: 'EG', national: '1001234567'));
      expect(PhoneNumbers.parseInternational('+١ ٢٠٢ ٥٥٥ ٠١٠١'), (iso2: 'US', national: '2025550101'));
      expect(PhoneNumbers.looksInternational('  +20'), isTrue);
      expect(PhoneNumbers.looksInternational('0020'), isTrue);
      expect(PhoneNumbers.looksInternational('0100'), isFalse);
    });
  });

  test('formats a stored number for its owner', () {
    expect(PhoneNumbers.formatE164('+201001234567'), '+20 10 01234567');
    expect(PhoneNumbers.formatE164('+12025550101'), '+1 202-555-0101');
    expect(PhoneNumbers.nationalNumber('+201001234567'), '1001234567');
  });

  test('every country in shared/countries is known to the metadata', () {
    expect([for (final c in Countries.all) if (!PhoneNumbers.supports(c.iso2)) c.iso2], isEmpty);
  });

  group('Countries', () {
    test('pinned first in the SPEC order, then sorted by name in the UI language', () {
      final ar = Countries.ordered('ar');
      final en = Countries.ordered('en');
      expect(ar.take(3).map((c) => c.iso2), ['EG', 'SA', 'AE']);
      expect(en.take(18).map((c) => c.iso2), Countries.pinned);
      expect(en[18].nameEn, 'Afghanistan');
      expect(ar.length, Countries.all.length);
    });

    test('searches by Arabic name, English name, ISO code and dial code', () {
      expect(Countries.search('مصر', 'ar').first.iso2, 'EG');
      expect(Countries.search('germ', 'en').single.iso2, 'DE');
      expect(Countries.search('fr', 'en').map((c) => c.iso2), contains('FR'));
      expect(Countries.search('+966', 'en').map((c) => c.iso2), ['SA']);
      expect(Countries.search('٩٦٦', 'ar').map((c) => c.iso2), ['SA']);
      expect(Countries.search('zzzz', 'en'), isEmpty);
    });

    test('default country: last used, then the device region, then Egypt', () async {
      final store = InMemoryKeyValueStore();
      final memory = PhoneCountryMemory(store);
      expect(memory.initial(deviceRegion: 'XX'), 'EG');
      expect(memory.initial(deviceRegion: 'SA'), 'SA');
      await memory.remember('AE');
      expect(memory.initial(deviceRegion: 'SA'), 'AE');
    });
  });
}

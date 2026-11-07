import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/phone/countries.dart';
import 'package:readin/core/security/credential_rules.dart';

import '../helpers/test_app.dart';

/// `lib/core/phone/country_list.g.dart` and `lib/core/security/common_secrets.g.dart` are copies of `shared/` that
/// the app compiles in (`node tools/countries/build.mjs --mobile`). These fail when a copy is stale.
void main() {
  test('the country list matches shared/countries/countries.json', () {
    final json = readSharedJson('countries/countries.json');
    expect(Countries.defaultIso2, json['defaultCountry']);
    expect(Countries.pinned, json['pinned']);
    final countries = (json['countries'] as List).cast<Map<String, dynamic>>();
    expect(
      [for (final c in Countries.all) [c.iso2, c.dialCode, c.nameAr, c.nameEn, c.exampleNational]],
      [for (final c in countries) [c['iso2'], c['dialCode'], c['nameAr'], c['nameEn'], c['exampleNational']]],
    );
  });

  List<String> lines(String path) =>
      File('../shared/$path').readAsLinesSync().map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  test('no weak-PIN list is compiled in, and every 4-digit PIN passes (user decision, 2026-11-07)', () {
    final generated = File('lib/core/security/common_secrets.g.dart').readAsStringSync();
    expect(generated, isNot(contains('common-pins')));
    expect(generated, isNot(contains('_commonPins')));
    expect(generated, contains('const Set<String> _commonPasswords = {'));
    // Covers the once-"common" PINs (1234, 1111, 0000, 1212, 2580, 6969…) and every other 4-digit PIN.
    for (var i = 0; i < 10000; i++) {
      final pin = i.toString().padLeft(4, '0');
      expect(RecoveryPinRules.check(pin), isEmpty, reason: pin);
    }
  });

  test('the common-password list matches shared/security/common-passwords.txt', () {
    expect(PasswordRules.commonPasswords, lines('security/common-passwords.txt').toSet());
    expect(PasswordRules.isCommon('a-password-nobody-uses-7'), isFalse);
  });
}

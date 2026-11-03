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

  test('the weak-PIN list matches shared/security/common-pins.txt', () {
    final pins = lines('security/common-pins.txt');
    expect(pins, hasLength(100));
    expect(RecoveryPinRules.commonPins, pins.toSet());
    for (final pin in pins) {
      expect(RecoveryPinRules.isWeak(pin), isTrue, reason: pin);
    }
  });

  test('the common-password list matches shared/security/common-passwords.txt', () {
    expect(PasswordRules.commonPasswords, lines('security/common-passwords.txt').toSet());
    expect(PasswordRules.isCommon('a-password-nobody-uses-7'), isFalse);
  });
}

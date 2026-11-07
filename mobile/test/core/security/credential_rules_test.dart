import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/security/credential_rules.dart';

void main() {
  test('converts Arabic-Indic and Persian digits', () {
    expect(toAsciiDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    expect(toAsciiDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    expect(toAsciiDigits('PIN ١٢٣٤!'), 'PIN 1234!');
    expect(digitsOnly('+٢٠ (١٠٠) ١٢٣-٤٥٦٧'), '201001234567');
  });

  group('PasswordRules', () {
    test('accepts 8–128 characters with a letter and a digit', () {
      expect(PasswordRules.check('reading4life'), isEmpty);
      expect(PasswordRules.check('قراءة2026يومية'), isEmpty); // Arabic letters count as letters
      expect(PasswordRules.check('abcdefg٧'), isEmpty); // Arabic-Indic digits count as digits
    });

    test('reports each broken rule with the API code', () {
      expect(PasswordRules.check(''), [CredentialCodes.passwordTooShort]);
      expect(PasswordRules.check('abc1'), [CredentialCodes.passwordTooShort]);
      expect(PasswordRules.check('a1' * 65), [CredentialCodes.passwordTooLong]);
      expect(PasswordRules.check('12345678'), [CredentialCodes.passwordLetterRequired]);
      expect(PasswordRules.check('abcdefgh'), [CredentialCodes.passwordDigitRequired]);
      expect(PasswordRules.check('abc'), [
        CredentialCodes.passwordTooShort,
        CredentialCodes.passwordDigitRequired,
      ]);
    });

    test('rejects common passwords (shared/security/common-passwords.txt)', () {
      expect(PasswordRules.check('password1'), [CredentialCodes.passwordTooCommon]);
      expect(PasswordRules.check('PASSWORD1'), [CredentialCodes.passwordTooCommon]);
    });

    test('rejects passwords containing the phone number', () {
      expect(PasswordRules.check('me1001234567x', phoneE164: '+201001234567'), [CredentialCodes.passwordContainsPhone]);
      expect(PasswordRules.check('x201001234567', phoneE164: '+201001234567'), [CredentialCodes.passwordContainsPhone]);
      expect(PasswordRules.check('reading4life', phoneE164: '+201001234567'), isEmpty);
    });

    test('follows the policy from /auth/config', () {
      const policy = PasswordPolicy(minLength: 12, requireDigit: false);
      expect(PasswordRules.check('abcdefghij', policy: policy), [CredentialCodes.passwordTooShort]);
      expect(PasswordRules.check('abcdefghijkl', policy: policy), isEmpty);
    });

    test('strength grows with length and variety', () {
      expect(PasswordRules.strength(''), PasswordStrength.empty);
      expect(PasswordRules.strength('abc1'), PasswordStrength.weak);
      expect(PasswordRules.strength('password1'), PasswordStrength.weak); // common
      expect(PasswordRules.strength('reading4ever'), PasswordStrength.good);
      expect(PasswordRules.strength('Reading4ever!2026'), PasswordStrength.strong);
    });
  });

  group('RecoveryPinRules', () {
    test('accepts any digits of the configured length', () {
      expect(RecoveryPinRules.check('4831'), isEmpty);
      expect(RecoveryPinRules.check('483192', length: 6), isEmpty);
    });

    test('digits only, then the length', () {
      expect(RecoveryPinRules.check('48a1'), [CredentialCodes.pinDigitsOnly]);
      expect(RecoveryPinRules.check('483'), [CredentialCodes.pinLength]);
      expect(RecoveryPinRules.check('48319'), [CredentialCodes.pinLength]);
      expect(RecoveryPinRules.normalize(' ٤٨٣١ '), '4831');
    });

    test('accepts the PINs once rejected as weak (user decision, 2026-11-07)', () {
      // Repeated digits, ascending/descending runs, years 1950–2030 and once-"common" PINs all pass.
      for (final pin in ['1111', '0000', '1234', '6789', '9876', '3210', '1989', '2024', '1950', '2030', '6969', '2580', '5566']) {
        expect(RecoveryPinRules.check(pin), isEmpty, reason: pin);
      }
      // The last digits of the phone number and the first digits of the password are no longer checked.
      expect(RecoveryPinRules.check('4567'), isEmpty); // ends +201001234567
      expect(RecoveryPinRules.check('8264'), isEmpty); // ends +201001238264
      expect(RecoveryPinRules.check('7391'), isEmpty); // starts the digits of 'abc7391xyz'
      expect(RecoveryPinRules.check('1949'), isEmpty);
      expect(RecoveryPinRules.check('2031'), isEmpty);
    });

    test('longer PINs: any digits of the configured length, still digits only', () {
      expect(RecoveryPinRules.check('198906', length: 6), isEmpty);
      expect(RecoveryPinRules.check('111111', length: 6), isEmpty);
      expect(RecoveryPinRules.check('123456', length: 6), isEmpty);
      expect(RecoveryPinRules.check('1234', length: 6), [CredentialCodes.pinLength]);
      expect(RecoveryPinRules.check('12345a', length: 6), [CredentialCodes.pinDigitsOnly]);
    });

    test('Arabic-Indic and Persian digits pass once normalized', () {
      expect(RecoveryPinRules.check(RecoveryPinRules.normalize('١١١١')), isEmpty);
      expect(RecoveryPinRules.check(RecoveryPinRules.normalize('۱۲۳۴')), isEmpty);
      expect(RecoveryPinRules.check(RecoveryPinRules.normalize('١٢٣')), [CredentialCodes.pinLength]);
    });
  });
}

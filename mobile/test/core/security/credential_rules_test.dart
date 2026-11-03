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
    test('accepts a non-guessable PIN of the configured length', () {
      expect(RecoveryPinRules.check('4831'), isEmpty);
      expect(RecoveryPinRules.check('483192', length: 6), isEmpty);
    });

    test('digits only, then the length', () {
      expect(RecoveryPinRules.check('48a1'), [CredentialCodes.pinDigitsOnly]);
      expect(RecoveryPinRules.check('483'), [CredentialCodes.pinLength]);
      expect(RecoveryPinRules.check('48319'), [CredentialCodes.pinLength]);
      expect(RecoveryPinRules.normalize(' ٤٨٣١ '), '4831');
    });

    test('rejects weak PINs (SPEC §9.4)', () {
      for (final pin in ['1111', '0000', '1234', '6789', '9876', '3210', '1989', '2024', '1950', '2030', '6969']) {
        expect(RecoveryPinRules.isWeak(pin), isTrue, reason: pin);
      }
      expect(RecoveryPinRules.isWeak('4567', phoneE164: '+201001234567'), isTrue); // ascending run
      expect(RecoveryPinRules.isWeak('8264', phoneE164: '+201001238264'), isTrue); // last digits of the number
      expect(RecoveryPinRules.isWeak('7391', password: 'abc7391xyz'), isTrue); // first digits of the password
      expect(RecoveryPinRules.isWeak('7391', password: 'abc17391'), isFalse);
      expect(RecoveryPinRules.isWeak('1949'), isFalse);
      expect(RecoveryPinRules.isWeak('2031'), isFalse);
      expect(RecoveryPinRules.isWeak('4831'), isFalse);
      expect(RecoveryPinRules.check('2580'), [CredentialCodes.pinWeak]); // common-pins.txt
    });

    test('years and the common list only apply to 4-digit PINs', () {
      expect(RecoveryPinRules.isWeak('198906'), isFalse);
      expect(RecoveryPinRules.isWeak('111111'), isTrue);
      expect(RecoveryPinRules.isWeak('123456'), isTrue);
    });
  });
}

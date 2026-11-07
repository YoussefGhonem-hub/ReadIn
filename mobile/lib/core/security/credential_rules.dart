import 'package:flutter/foundation.dart';

import '../phone/phone_numbers.dart';

part 'common_secrets.g.dart';

/// Converts Arabic-Indic (٠-٩) and Persian (۰-۹) digits to ASCII; everything else is kept (SPEC §9.4).
String toAsciiDigits(String input) {
  final buffer = StringBuffer();
  for (final c in input.runes) {
    if (c >= 0x0660 && c <= 0x0669) {
      buffer.writeCharCode(0x30 + c - 0x0660);
    } else if (c >= 0x06F0 && c <= 0x06F9) {
      buffer.writeCharCode(0x30 + c - 0x06F0);
    } else {
      buffer.writeCharCode(c);
    }
  }
  return buffer.toString();
}

/// Only the ASCII digits of [input], after converting Arabic-Indic and Persian digits.
String digitsOnly(String input) => toAsciiDigits(input).replaceAll(RegExp(r'[^0-9]'), '');

/// Password rules from `GET /auth/config` (SPEC §9.4); the defaults match the API's.
class PasswordPolicy {
  const PasswordPolicy({this.minLength = 8, this.maxLength = 128, this.requireLetter = true, this.requireDigit = true});

  final int minLength;
  final int maxLength;
  final bool requireLetter;
  final bool requireDigit;

  @override
  bool operator ==(Object other) =>
      other is PasswordPolicy &&
      other.minLength == minLength &&
      other.maxLength == maxLength &&
      other.requireLetter == requireLetter &&
      other.requireDigit == requireDigit;

  @override
  int get hashCode => Object.hash(minLength, maxLength, requireLetter, requireDigit);
}

/// Validation codes shared with the API (docs/api/contract-v1.md); the UI translates them.
abstract final class CredentialCodes {
  static const phoneInvalid = 'phone.invalid';
  static const passwordTooShort = 'password.too_short';
  static const passwordTooLong = 'password.too_long';
  static const passwordLetterRequired = 'password.letter_required';
  static const passwordDigitRequired = 'password.digit_required';
  static const passwordTooCommon = 'password.too_common';
  static const passwordContainsPhone = 'password.contains_phone';
  static const pinLength = 'pin.length';
  static const pinDigitsOnly = 'pin.digits_only';

  // Client-only.
  static const required = 'field.required';
  static const passwordMismatch = 'password.mismatch';
  static const pinMismatch = 'pin.mismatch';
}

/// How strong a password looks, for the meter under the field. The server decides what is accepted.
enum PasswordStrength { empty, weak, fair, good, strong }

/// Same checks as the API's `PasswordRules` (SPEC §9.4).
abstract final class PasswordRules {
  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _symbol = RegExp(r'[^\p{L}\p{N}]', unicode: true);

  static bool hasLetter(String password) => _letter.hasMatch(password);

  static bool hasDigit(String password) => digitsOnly(password).isNotEmpty;

  static bool isCommon(String password) => _commonPasswords.contains(password.toLowerCase());

  @visibleForTesting
  static Set<String> get commonPasswords => _commonPasswords;

  /// The violated rules, as API codes, in the order the API reports them.
  static List<String> check(String password, {PasswordPolicy policy = const PasswordPolicy(), String? phoneE164}) {
    if (password.isEmpty) return const [CredentialCodes.passwordTooShort];
    final errors = <String>[
      if (password.length < policy.minLength) CredentialCodes.passwordTooShort,
      if (password.length > policy.maxLength) CredentialCodes.passwordTooLong,
      if (policy.requireLetter && !hasLetter(password)) CredentialCodes.passwordLetterRequired,
      if (policy.requireDigit && !hasDigit(password)) CredentialCodes.passwordDigitRequired,
    ];
    if (errors.isEmpty && isCommon(password)) errors.add(CredentialCodes.passwordTooCommon);
    if (phoneE164 != null && containsPhone(password, phoneE164)) errors.add(CredentialCodes.passwordContainsPhone);
    return errors;
  }

  /// True when the password's digits contain the national number (6+ digits) or the whole number without "+".
  static bool containsPhone(String password, String phoneE164) {
    final digits = digitsOnly(password);
    final national = PhoneNumbers.nationalNumber(phoneE164);
    return national.length >= 6 && (digits.contains(national) || digits.contains(phoneE164.replaceFirst('+', '')));
  }

  static PasswordStrength strength(String password, {PasswordPolicy policy = const PasswordPolicy()}) {
    if (password.isEmpty) return PasswordStrength.empty;
    if (password.length < policy.minLength || isCommon(password)) return PasswordStrength.weak;
    var score = 0;
    if (hasLetter(password)) score++;
    if (hasDigit(password)) score++;
    if (_symbol.hasMatch(password)) score++;
    if (RegExp('[a-z]').hasMatch(password) && RegExp('[A-Z]').hasMatch(password)) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;
    return switch (score) {
      <= 1 => PasswordStrength.weak,
      2 => PasswordStrength.fair,
      3 || 4 => PasswordStrength.good,
      _ => PasswordStrength.strong,
    };
  }
}

/// Same checks as the API's `RecoveryPinRules` (SPEC §9.4, ADR 0009): any digits of the configured length.
abstract final class RecoveryPinRules {
  static const defaultLength = 4;

  /// Converts Arabic-Indic and Persian digits and trims, like the API.
  static String normalize(String pin) => toAsciiDigits(pin.trim());

  /// [pin] already normalized: digits only, then exactly [length] of them.
  static List<String> check(String pin, {int length = defaultLength}) {
    if (!RegExp(r'^[0-9]*$').hasMatch(pin)) return const [CredentialCodes.pinDigitsOnly];
    if (pin.length != length) return const [CredentialCodes.pinLength];
    return const [];
  }
}

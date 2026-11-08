import '../../../../core/errors/failure.dart';
import '../../../../core/security/credential_rules.dart';

enum FormStatus { idle, submitting, success }

/// Field keys of the auth forms. Server validation errors arrive keyed by the request's camelCase property names
/// (`phoneNumber`, `recoveryPin`, `newPassword`…); [FormErrors.fromFailure] maps them onto these.
abstract final class Fields {
  static const phone = 'phoneNumber';
  static const password = 'password';
  static const confirmPassword = 'confirmPassword';
  static const currentPassword = 'currentPassword';
  static const pin = 'pin';
  static const confirmPin = 'confirmPin';
  static const displayName = 'displayName';
  static const username = 'username';

  /// The sign-up Terms checkbox (F37).
  static const terms = 'acceptTerms';
}

/// Field errors (field → error code) plus an error for the whole form, from a failed call.
typedef FormErrors = ({Map<String, String> fields, Failure? general});

extension FailureToFormErrors on Failure {
  /// Splits this failure: validation codes go to their field (renamed by [fieldNames]); codes listed in [codeFields]
  /// (e.g. `auth.wrong_password` → current password) go to that field; anything else is a form-level error.
  FormErrors toFormErrors({Map<String, String> fieldNames = const {}, Map<String, String> codeFields = const {}}) {
    if (codeFields[code] case final field?) return (fields: {field: code}, general: null);
    if (fieldErrors.isEmpty) return (fields: const {}, general: this);
    final fields = <String, String>{};
    for (final MapEntry(:key, :value) in fieldErrors.entries) {
      if (value.isEmpty) continue;
      fields[fieldNames[key] ?? key] = value.first;
    }
    return (fields: fields, general: fields.isEmpty ? this : null);
  }
}

/// Client-side checks shared by the forms; the server re-checks everything (SPEC §9.4).
abstract final class Validate {
  static String? phone({required bool empty, required String? e164}) =>
      empty ? CredentialCodes.required : (e164 == null ? CredentialCodes.phoneInvalid : null);

  static String? required(String value) => value.isEmpty ? CredentialCodes.required : null;

  static String? newPassword(String password, PasswordPolicy policy, {String? phoneE164}) {
    final errors = PasswordRules.check(password, policy: policy, phoneE164: phoneE164);
    return errors.isEmpty ? null : errors.first;
  }

  static String? confirmation(String value, String original, String mismatchCode) =>
      value.isEmpty ? CredentialCodes.required : (value != original ? mismatchCode : null);

  static String? newPin(String pin, int length) {
    final errors = RecoveryPinRules.check(RecoveryPinRules.normalize(pin), length: length);
    return errors.isEmpty ? null : errors.first;
  }

  /// A PIN being verified: empty is "required", then digits only and the length.
  static String? existingPin(String pin, int length) {
    final value = RecoveryPinRules.normalize(pin);
    if (value.isEmpty) return CredentialCodes.required;
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return CredentialCodes.pinDigitsOnly;
    return value.length == length ? null : CredentialCodes.pinLength;
  }

  /// Live PIN feedback once every box is filled; nothing while typing.
  static String? livePin(String pin, int length) => RecoveryPinRules.normalize(pin).length < length ? null : newPin(pin, length);

  static Map<String, String> collect(Map<String, String?> checks) => {
        for (final MapEntry(:key, :value) in checks.entries) key: ?value,
      };
}

import 'package:equatable/equatable.dart';

import '../../../../core/security/credential_rules.dart';
import 'external_credential.dart';

/// `GET /auth/config`: drives the PIN boxes, the password rules (SPEC §9.4) and the Google / Apple buttons. The defaults
/// match the API's, so the forms work before the config arrives or while offline; the server re-checks everything anyway.
class AuthConfig extends Equatable {
  const AuthConfig({
    this.pinLength = RecoveryPinRules.defaultLength,
    this.password = const PasswordPolicy(),
    this.externalProviders = const [],
  });

  final int pinLength;
  final PasswordPolicy password;

  /// Providers configured on the server; their buttons stay hidden otherwise (and while the config is unknown).
  final List<ExternalProvider> externalProviders;

  static const defaults = AuthConfig();

  @override
  List<Object?> get props => [pinLength, password, externalProviders];
}

/// `GET /users/username-available`.
class UsernameAvailability extends Equatable {
  const UsernameAvailability({required this.username, required this.valid, required this.available});

  final String username;

  /// False when the handle breaks the format rules (3–30 of a–z, 0–9, _).
  final bool valid;
  final bool available;

  @override
  List<Object?> get props => [username, valid, available];
}

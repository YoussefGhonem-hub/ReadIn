import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/security/credential_rules.dart';
import '../../domain/entities/auth_config.dart';
import '../../domain/entities/external_credential.dart';
import '../../domain/entities/me.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

/// `MeDto` (docs/api/contract-v1.md).
@freezed
abstract class MeModel with _$MeModel {
  const MeModel._();

  const factory MeModel({
    required String id,
    String? phoneNumber,
    String? email,
    required String displayName,
    required String username,
    String? avatarUrl,
    String? bio,
    // The API writes nulls, e.g. `{ "gitHub": null }`.
    @Default(<String, String?>{}) Map<String, String?> links,
    @Default('ar') String uiLanguage,
    @Default('ar-EG') String articleLanguage,
    @Default('system') String theme,
    @Default('UTC') String timeZone,
    @Default('08:00') String reminderTime,
    @Default(false) bool isVerified,
    @Default(false) bool onboardingCompleted,
    @Default(false) bool mustChangePassword,
    @Default(false) bool mustSetRecoveryPin,
    @Default(true) bool isProfileComplete,
    @Default(true) bool hasRecoveryPin,
    // Added with Google/Apple sign in; older APIs leave them out.
    @Default(true) bool hasPassword,
    @Default(<ExternalLoginModel>[]) List<ExternalLoginModel> externalLogins,
    @Default(<String>[]) List<String> roles,
    @Default(<String>[]) List<String> permissions,
    @Default(InterestsModel()) InterestsModel interests,
  }) = _MeModel;

  factory MeModel.fromJson(Map<String, dynamic> json) => _$MeModelFromJson(json);

  Me toEntity() => Me(
        id: id,
        phoneNumber: phoneNumber,
        email: email,
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        bio: bio,
        links: {
          for (final entry in links.entries)
            if (entry.value case final value? when value.isNotEmpty) entry.key: value,
        },
        uiLanguage: uiLanguage,
        articleLanguage: articleLanguage,
        theme: theme,
        timeZone: timeZone,
        reminderTime: reminderTime,
        isVerified: isVerified,
        onboardingCompleted: onboardingCompleted,
        mustChangePassword: mustChangePassword,
        mustSetRecoveryPin: mustSetRecoveryPin,
        isProfileComplete: isProfileComplete,
        hasRecoveryPin: hasRecoveryPin,
        hasPassword: hasPassword,
        externalLogins: [for (final login in externalLogins) login.toEntity()],
        roles: roles,
        permissions: permissions,
        interestFieldIds: interests.fieldIds,
        interestTopicIds: interests.topicIds,
      );
}

/// `{ provider, email, linkedAt }` in `MeDto.externalLogins`.
@freezed
abstract class ExternalLoginModel with _$ExternalLoginModel {
  const ExternalLoginModel._();

  const factory ExternalLoginModel({required String provider, String? email, DateTime? linkedAt}) = _ExternalLoginModel;

  factory ExternalLoginModel.fromJson(Map<String, dynamic> json) => _$ExternalLoginModelFromJson(json);

  ExternalLogin toEntity() => ExternalLogin(provider: provider, email: email, linkedAt: linkedAt);
}

@freezed
abstract class InterestsModel with _$InterestsModel {
  const factory InterestsModel({
    @Default(<String>[]) List<String> fieldIds,
    @Default(<String>[]) List<String> topicIds,
  }) = _InterestsModel;

  factory InterestsModel.fromJson(Map<String, dynamic> json) => _$InterestsModelFromJson(json);
}

/// `SessionDto`: the refresh token rotates on every refresh, so the newest one is always the one to keep.
@freezed
abstract class SessionModel with _$SessionModel {
  const factory SessionModel({
    required String accessToken,
    required DateTime accessTokenExpiresAt,
    String? refreshToken,
    required DateTime refreshTokenExpiresAt,
    required MeModel user,
  }) = _SessionModel;

  factory SessionModel.fromJson(Map<String, dynamic> json) => _$SessionModelFromJson(json);
}

/// `AuthConfigDto`.
@freezed
abstract class AuthConfigModel with _$AuthConfigModel {
  const AuthConfigModel._();

  const factory AuthConfigModel({
    @Default(RecoveryPinRules.defaultLength) int pinLength,
    @Default(PasswordRulesModel()) PasswordRulesModel password,
    // Added with Google/Apple sign in; older APIs leave it out.
    @Default(<String>[]) List<String> externalProviders,
  }) = _AuthConfigModel;

  factory AuthConfigModel.fromJson(Map<String, dynamic> json) => _$AuthConfigModelFromJson(json);

  AuthConfig toEntity() => AuthConfig(
        pinLength: pinLength,
        password: PasswordPolicy(
          minLength: password.minLength,
          maxLength: password.maxLength,
          requireLetter: password.requireLetter,
          requireDigit: password.requireDigit,
        ),
        externalProviders: [
          for (final name in externalProviders) ?ExternalProvider.values.asNameMap()[name], // unknown ones are skipped
        ],
      );
}

@freezed
abstract class PasswordRulesModel with _$PasswordRulesModel {
  const factory PasswordRulesModel({
    @Default(8) int minLength,
    @Default(128) int maxLength,
    @Default(true) bool requireLetter,
    @Default(true) bool requireDigit,
  }) = _PasswordRulesModel;

  factory PasswordRulesModel.fromJson(Map<String, dynamic> json) => _$PasswordRulesModelFromJson(json);
}

/// `POST /auth/recovery/verify-pin` → `{ resetToken, expiresAt }`.
@freezed
abstract class ResetTokenModel with _$ResetTokenModel {
  const factory ResetTokenModel({required String resetToken, required DateTime expiresAt}) = _ResetTokenModel;

  factory ResetTokenModel.fromJson(Map<String, dynamic> json) => _$ResetTokenModelFromJson(json);
}

/// `GET /users/username-available` → `{ username, valid, available }`.
@freezed
abstract class UsernameAvailabilityModel with _$UsernameAvailabilityModel {
  const UsernameAvailabilityModel._();

  const factory UsernameAvailabilityModel({required String username, required bool valid, required bool available}) =
      _UsernameAvailabilityModel;

  factory UsernameAvailabilityModel.fromJson(Map<String, dynamic> json) => _$UsernameAvailabilityModelFromJson(json);

  UsernameAvailability toEntity() => UsernameAvailability(username: username, valid: valid, available: available);
}

// ── Requests ─────────────────────────────────────────────────────────

/// `RegisterRequest`.
class RegisterRequest {
  const RegisterRequest({
    required this.phoneNumber,
    required this.password,
    required this.recoveryPin,
    this.uiLanguage,
    this.timeZone,
  });

  final String phoneNumber;
  final String password;
  final String recoveryPin;
  final String? uiLanguage;
  final String? timeZone;

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'password': password,
        'recoveryPin': recoveryPin,
        'uiLanguage': ?uiLanguage,
        'timeZone': ?timeZone,
      };
}

/// `LoginRequest`.
class LoginRequest {
  const LoginRequest({required this.phoneNumber, required this.password});

  final String phoneNumber;
  final String password;

  Map<String, dynamic> toJson() => {'phoneNumber': phoneNumber, 'password': password};
}

/// `RefreshRequest` (mobile sends the token in the body).
class RefreshRequest {
  const RefreshRequest(this.refreshToken);

  final String refreshToken;

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

/// `VerifyPinRequest`.
class VerifyPinRequest {
  const VerifyPinRequest({required this.phoneNumber, required this.pin});

  final String phoneNumber;
  final String pin;

  Map<String, dynamic> toJson() => {'phoneNumber': phoneNumber, 'pin': pin};
}

class ResetPasswordRequest {
  const ResetPasswordRequest({required this.resetToken, required this.newPassword});

  final String resetToken;
  final String newPassword;

  Map<String, dynamic> toJson() => {'resetToken': resetToken, 'newPassword': newPassword};
}

class CompleteProfileRequest {
  const CompleteProfileRequest({required this.displayName, required this.username, this.avatarUrl});

  final String displayName;
  final String username;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => {'displayName': displayName, 'username': username, 'avatarUrl': ?avatarUrl};
}

class SetRecoveryPinRequest {
  const SetRecoveryPinRequest(this.pin);

  final String pin;

  Map<String, dynamic> toJson() => {'pin': pin};
}

class ChangeRecoveryPinRequest {
  const ChangeRecoveryPinRequest({required this.currentPassword, required this.newPin});

  final String currentPassword;
  final String newPin;

  Map<String, dynamic> toJson() => {'currentPassword': currentPassword, 'newPin': newPin};
}

class ChangePasswordRequest {
  const ChangePasswordRequest({required this.currentPassword, required this.newPassword});

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => {'currentPassword': currentPassword, 'newPassword': newPassword};
}

class ChangePhoneRequest {
  const ChangePhoneRequest({required this.newPhoneNumber, required this.currentPassword});

  final String newPhoneNumber;
  final String currentPassword;

  Map<String, dynamic> toJson() => {'newPhoneNumber': newPhoneNumber, 'currentPassword': currentPassword};
}

/// `{ password?, external? }`: accounts without a password confirm with a fresh Google/Apple token.
class DeleteAccountRequest {
  const DeleteAccountRequest({this.password, this.external});

  final String? password;
  final ExternalCredential? external;

  Map<String, dynamic> toJson() => {'password': ?password, 'external': ?external?.toJson()};
}

/// `ExternalCredential`: the provider, its ID token and, for Apple, the raw nonce.
extension ExternalCredentialJson on ExternalCredential {
  Map<String, dynamic> toJson() => {'provider': provider.name, 'idToken': idToken, 'nonce': ?nonce};
}

/// `ExternalSignInRequest`: [createAccount] or [link] answer `auth.external_not_linked`.
class ExternalSignInRequest {
  const ExternalSignInRequest({
    required this.credential,
    this.uiLanguage,
    this.timeZone,
    this.linkPhoneNumber,
    this.linkPassword,
    this.createAccount = false,
  });

  final ExternalCredential credential;
  final String? uiLanguage;
  final String? timeZone;
  final String? linkPhoneNumber;
  final String? linkPassword;
  final bool createAccount;

  Map<String, dynamic> toJson() => {
        ...credential.toJson(),
        'displayName': ?credential.displayName,
        'uiLanguage': ?uiLanguage,
        'timeZone': ?timeZone,
        if (linkPhoneNumber != null) 'link': {'phoneNumber': linkPhoneNumber, 'password': linkPassword},
        if (createAccount) 'createAccount': true,
      };
}

/// `POST /me/external-logins`: confirmed with the password or a fresh token of an already linked provider.
class LinkExternalLoginRequest {
  const LinkExternalLoginRequest({required this.credential, this.password, this.external});

  final ExternalCredential credential;
  final String? password;
  final ExternalCredential? external;

  Map<String, dynamic> toJson() => {
        'credential': credential.toJson(),
        'password': ?password,
        'external': ?external?.toJson(),
      };
}

/// `POST /me/phone-sign-in`: a Google/Apple-only account adds phone + password + PIN.
class AddPhoneSignInRequest {
  const AddPhoneSignInRequest({
    required this.phoneNumber,
    required this.password,
    required this.recoveryPin,
    required this.external,
  });

  final String phoneNumber;
  final String password;
  final String recoveryPin;
  final ExternalCredential external;

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'password': password,
        'recoveryPin': recoveryPin,
        'external': external.toJson(),
      };
}

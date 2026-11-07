import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/phone/countries.dart';
import '../../../../core/phone/phone_numbers.dart';
import '../../../../core/security/credential_rules.dart';
import '../../domain/entities/auth_config.dart';
import '../../domain/entities/external_credential.dart';
import '../../domain/entities/me.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'form_support.dart';

/// State of the account security forms: set / change PIN, change password, change number, add phone + password.
class AccountFormState extends Equatable {
  const AccountFormState({
    this.config = AuthConfig.defaults,
    this.status = FormStatus.idle,
    this.errors = const {},
    this.failure,
    this.confirming = false,
  });

  final AuthConfig config;
  final FormStatus status;
  final Map<String, String> errors;
  final Failure? failure;

  /// Change number: the confirm-number dialog is open.
  final bool confirming;

  bool get submitting => status == FormStatus.submitting;

  AccountFormState copyWith({
    AuthConfig? config,
    FormStatus? status,
    Map<String, String>? errors,
    Failure? Function()? failure,
    bool? confirming,
  }) =>
      AccountFormState(
        config: config ?? this.config,
        status: status ?? this.status,
        errors: errors ?? this.errors,
        failure: failure != null ? failure() : this.failure,
        confirming: confirming ?? this.confirming,
      );

  @override
  List<Object?> get props => [config, status, errors, failure, confirming];
}

/// `auth.wrong_password` belongs to the current password field; the lockout it can cause is a form error.
const _currentPasswordCodes = {FailureCodes.authWrongPassword: Fields.currentPassword};

abstract class _AccountFormCubit extends Cubit<AccountFormState> {
  _AccountFormCubit(this._config) : super(const AccountFormState());

  final GetAuthConfig _config;

  Future<void> loadConfig() async {
    final config = await _config();
    if (!isClosed) emit(state.copyWith(config: config));
  }

  /// Shows [errors], or runs [call] and maps its failure onto the fields.
  Future<void> _submit(
    Map<String, String> errors,
    Future<Result<Object?>> Function() call, {
    Map<String, String> fieldNames = const {},
    Map<String, String> codeFields = _currentPasswordCodes,
  }) async {
    if (errors.isNotEmpty) return emit(state.copyWith(errors: errors, failure: () => null, confirming: false));
    emit(state.copyWith(status: FormStatus.submitting, errors: const {}, failure: () => null, confirming: false));
    final result = await call();
    if (isClosed) return;
    if (result.failureOrNull case final failure?) {
      final split = failure.toFormErrors(fieldNames: fieldNames, codeFields: codeFields);
      return emit(state.copyWith(status: FormStatus.idle, errors: split.fields, failure: () => split.general));
    }
    emit(state.copyWith(status: FormStatus.success));
  }

  /// "Confirm it's you" without a password: a linked provider's sheet, with the form busy meanwhile. Null when the
  /// sheet was closed or failed (the failure is shown).
  Future<ExternalCredential?> _confirmWithLinkedProvider(ConfirmWithLinkedProvider confirmWith, Me me) async {
    emit(state.copyWith(status: FormStatus.submitting, errors: const {}, failure: () => null, confirming: false));
    final result = await confirmWith(me);
    if (isClosed) return null;
    final credential = result.valueOrNull;
    if (credential == null) emit(state.copyWith(status: FormStatus.idle, failure: () => result.failureOrNull));
    return credential;
  }

  /// Live PIN check once every box is filled; clears the PIN error while typing.
  void _livePin(String pin) {
    final error = Validate.livePin(pin, state.config.pinLength);
    final errors = {...state.errors}..remove(Fields.pin);
    if (error != null) errors[Fields.pin] = error;
    emit(state.copyWith(errors: errors));
  }

  Map<String, String> _pinErrors(String pin, String confirmPin) {
    final normalized = RecoveryPinRules.normalize(pin);
    return Validate.collect({
      Fields.pin: Validate.newPin(normalized, state.config.pinLength),
      Fields.confirmPin: Validate.confirmation(RecoveryPinRules.normalize(confirmPin), normalized, CredentialCodes.pinMismatch),
    });
  }
}

/// Mandatory "set recovery PIN" (`mustSetRecoveryPin`, SPEC §9.2). Success updates the session; the router moves on.
@injectable
class SetRecoveryPinCubit extends _AccountFormCubit {
  SetRecoveryPinCubit(super.config, this._setPin);

  final SetRecoveryPin _setPin;

  void pinChanged(String pin) => _livePin(pin);

  Future<void> submit({required String pin, required String confirmPin}) async {
    if (state.submitting) return;
    await _submit(_pinErrors(pin, confirmPin), () => _setPin(RecoveryPinRules.normalize(pin)));
  }
}

/// Settings → "تغيير الـ PIN": current password + new PIN + confirm.
@injectable
class ChangeRecoveryPinCubit extends _AccountFormCubit {
  ChangeRecoveryPinCubit(super.config, this._changePin);

  final ChangeRecoveryPin _changePin;

  void pinChanged(String pin) => _livePin(pin);

  Future<void> submit({
    required String currentPassword,
    required String pin,
    required String confirmPin,
  }) async {
    if (state.submitting) return;
    final errors = {
      ...Validate.collect({Fields.currentPassword: Validate.required(currentPassword)}),
      ..._pinErrors(pin, confirmPin),
    };
    await _submit(
      errors,
      () => _changePin(currentPassword: currentPassword, newPin: RecoveryPinRules.normalize(pin)),
      fieldNames: const {'newPin': Fields.pin},
    );
  }
}

/// "تغيير كلمة السر" from Settings, and the mandatory screen after an Admin reset (`mustChangePassword`).
@injectable
class ChangePasswordCubit extends _AccountFormCubit {
  ChangePasswordCubit(super.config, this._changePassword);

  final ChangePassword _changePassword;

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    String? phoneE164,
  }) async {
    if (state.submitting) return;
    final errors = Validate.collect({
      Fields.currentPassword: Validate.required(currentPassword),
      Fields.password: Validate.newPassword(newPassword, state.config.password, phoneE164: phoneE164),
      Fields.confirmPassword: Validate.confirmation(confirmPassword, newPassword, CredentialCodes.passwordMismatch),
    });
    await _submit(
      errors,
      () => _changePassword(currentPassword: currentPassword, newPassword: newPassword),
      fieldNames: const {'newPassword': Fields.password},
    );
  }
}

/// Settings → "تغيير الرقم": new number + current password, then the confirm-number dialog.
@injectable
class ChangePhoneCubit extends _AccountFormCubit {
  ChangePhoneCubit(super.config, this._changePhone, this._countries);

  final ChangePhoneNumber _changePhone;
  final PhoneCountryMemory _countries;
  String? _phone;
  String _password = '';

  /// Validates, then opens the confirm-number dialog.
  void review({
    required String? phoneE164,
    required bool phoneEmpty,
    required String currentPassword,
    String? currentPhone,
  }) {
    if (state.submitting) return;
    final errors = Validate.collect({
      Fields.phone: Validate.phone(empty: phoneEmpty, e164: phoneE164) ??
          (phoneE164 == currentPhone ? FailureCodes.authPhoneUnchanged : null),
      Fields.currentPassword: Validate.required(currentPassword),
    });
    if (errors.isNotEmpty) return emit(state.copyWith(errors: errors, failure: () => null));
    _phone = phoneE164;
    _password = currentPassword;
    emit(state.copyWith(errors: const {}, failure: () => null, confirming: true));
  }

  void cancelConfirmation() => emit(state.copyWith(confirming: false));

  Future<void> confirm() async {
    final phone = _phone;
    if (state.submitting || phone == null) return;
    await _submit(
      const {},
      () => _changePhone(newPhoneNumber: phone, currentPassword: _password),
      fieldNames: const {'newPhoneNumber': Fields.phone},
      codeFields: const {
        ..._currentPasswordCodes,
        FailureCodes.authPhoneTaken: Fields.phone,
        FailureCodes.authPhoneUnchanged: Fields.phone,
      },
    );
    if (state.status == FormStatus.success) {
      if (PhoneNumbers.split(phone) case final parts?) await _countries.remember(parts.iso2);
    }
  }
}

/// Settings → "ضيف رقم تليفون وكلمة سر" for Google / Apple-only accounts (F18): number, password and PIN, the
/// confirm-number dialog, then a fresh token of a linked provider. The session gets fresh tokens.
@injectable
class AddPhoneSignInCubit extends _AccountFormCubit {
  AddPhoneSignInCubit(super.config, this._add, this._confirmWith, this._countries);

  final AddPhoneSignIn _add;
  final ConfirmWithLinkedProvider _confirmWith;
  final PhoneCountryMemory _countries;

  // Kept out of the state on purpose (never logged or compared).
  String? _phone;
  String _password = '';
  String _pin = '';

  void pinChanged(String pin) => _livePin(pin);

  /// Validates, then opens the confirm-number dialog.
  void review({
    required String? phoneE164,
    required bool phoneEmpty,
    required String password,
    required String confirmPassword,
    required String pin,
    required String confirmPin,
  }) {
    if (state.submitting) return;
    final normalized = RecoveryPinRules.normalize(pin);
    final errors = Validate.collect({
      Fields.phone: Validate.phone(empty: phoneEmpty, e164: phoneE164),
      Fields.password: Validate.newPassword(password, state.config.password, phoneE164: phoneE164),
      Fields.confirmPassword: Validate.confirmation(confirmPassword, password, CredentialCodes.passwordMismatch),
      Fields.pin: Validate.newPin(normalized, state.config.pinLength),
      Fields.confirmPin: Validate.confirmation(RecoveryPinRules.normalize(confirmPin), normalized, CredentialCodes.pinMismatch),
    });
    if (errors.isNotEmpty) return emit(state.copyWith(errors: errors, failure: () => null));
    _phone = phoneE164;
    _password = password;
    _pin = normalized;
    emit(state.copyWith(errors: const {}, failure: () => null, confirming: true));
  }

  void cancelConfirmation() => emit(state.copyWith(confirming: false));

  /// "صح": a linked provider confirms it's the owner, then `POST /me/phone-sign-in`.
  Future<void> confirm(Me me) async {
    final phone = _phone;
    if (state.submitting || phone == null) return;
    final external = await _confirmWithLinkedProvider(_confirmWith, me);
    if (external == null) return;
    await _submit(
      const {},
      () => _add(phoneNumber: phone, password: _password, recoveryPin: _pin, external: external),
      fieldNames: const {'recoveryPin': Fields.pin},
      codeFields: const {FailureCodes.authPhoneTaken: Fields.phone},
    );
    if (state.status == FormStatus.success) {
      if (PhoneNumbers.split(phone) case final parts?) await _countries.remember(parts.iso2);
    }
  }
}

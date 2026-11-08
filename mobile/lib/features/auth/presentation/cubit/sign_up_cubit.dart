import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/current_locale.dart';
import '../../../../core/phone/countries.dart';
import '../../../../core/phone/phone_numbers.dart';
import '../../../../core/security/credential_rules.dart';
import '../../domain/entities/auth_config.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'form_support.dart';

enum SignUpStep { credentials, pin }

class SignUpState extends Equatable {
  const SignUpState({
    this.step = SignUpStep.credentials,
    this.config = AuthConfig.defaults,
    this.status = FormStatus.idle,
    this.errors = const {},
    this.failure,
    this.phone,
    this.confirming = false,
  });

  final SignUpStep step;
  final AuthConfig config;
  final FormStatus status;
  final Map<String, String> errors;
  final Failure? failure;

  /// The E.164 number accepted in step 1.
  final String? phone;

  /// Step 3: the "confirm your number" dialog is open.
  final bool confirming;

  bool get submitting => status == FormStatus.submitting;

  /// `auth.phone_taken`: show the Sign in action next to the error.
  bool get phoneTaken => errors[Fields.phone] == FailureCodes.authPhoneTaken;

  SignUpState copyWith({
    SignUpStep? step,
    AuthConfig? config,
    FormStatus? status,
    Map<String, String>? errors,
    Failure? Function()? failure,
    String? phone,
    bool? confirming,
  }) =>
      SignUpState(
        step: step ?? this.step,
        config: config ?? this.config,
        status: status ?? this.status,
        errors: errors ?? this.errors,
        failure: failure != null ? failure() : this.failure,
        phone: phone ?? this.phone,
        confirming: confirming ?? this.confirming,
      );

  @override
  List<Object?> get props => [step, config, status, errors, failure, phone, confirming];
}

/// Create account (SPEC §9.2): 1. phone + password → 2. recovery PIN → 3. confirm the number, then `POST /auth/register`.
/// On success the session starts and the router continues to Complete profile.
@injectable
class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this._register, this._config, this._locale, this._countries) : super(const SignUpState());

  final Register _register;
  final GetAuthConfig _config;
  final CurrentLocale _locale;
  final PhoneCountryMemory _countries;

  // Kept out of the state on purpose (never logged or compared).
  String _password = '';
  String _pin = '';

  Future<void> loadConfig() async {
    final config = await _config();
    if (!isClosed) emit(state.copyWith(config: config));
  }

  /// Step 1 → 2.
  void submitCredentials({
    required String? phoneE164,
    required bool phoneEmpty,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
  }) {
    if (state.submitting) return;
    final errors = Validate.collect({
      Fields.phone: Validate.phone(empty: phoneEmpty, e164: phoneE164),
      Fields.password: Validate.newPassword(password, state.config.password, phoneE164: phoneE164),
      Fields.confirmPassword: Validate.confirmation(confirmPassword, password, CredentialCodes.passwordMismatch),
      // F37: the Terms checkbox (the API refuses a sign up without it, `auth.terms_required`).
      Fields.terms: acceptedTerms ? null : FailureCodes.authTermsRequired,
    });
    if (errors.isNotEmpty) return emit(state.copyWith(errors: errors, failure: () => null));
    _password = password;
    emit(state.copyWith(step: SignUpStep.pin, phone: phoneE164, errors: const {}, failure: () => null));
  }

  /// Live PIN check once every box is filled; clears the PIN error while typing.
  void pinChanged(String pin) {
    final error = Validate.livePin(pin, state.config.pinLength);
    final errors = {...state.errors}..remove(Fields.pin);
    if (error != null) errors[Fields.pin] = error;
    emit(state.copyWith(errors: errors));
  }

  /// Step 2 → the confirm-number dialog.
  void submitPin({required String pin, required String confirmPin}) {
    if (state.submitting) return;
    final normalized = RecoveryPinRules.normalize(pin);
    final errors = Validate.collect({
      Fields.pin: Validate.newPin(normalized, state.config.pinLength),
      Fields.confirmPin: Validate.confirmation(RecoveryPinRules.normalize(confirmPin), normalized, CredentialCodes.pinMismatch),
    });
    if (errors.isNotEmpty) return emit(state.copyWith(errors: errors, failure: () => null));
    _pin = normalized;
    emit(state.copyWith(errors: const {}, failure: () => null, confirming: true));
  }

  /// "تعديل": back to step 1 to fix the number.
  void editNumber() => emit(state.copyWith(step: SignUpStep.credentials, confirming: false));

  /// The dialog was dismissed without an answer.
  void cancelConfirmation() => emit(state.copyWith(confirming: false));

  void back() => emit(state.copyWith(step: SignUpStep.credentials, errors: const {}, failure: () => null));

  /// "صح، اعمل الحساب".
  Future<void> register() async {
    final phone = state.phone;
    if (state.submitting || phone == null) return;
    emit(state.copyWith(confirming: false, status: FormStatus.submitting, failure: () => null));
    final result = await _register(
      phoneNumber: phone,
      password: _password,
      recoveryPin: _pin,
      uiLanguage: _locale.languageCode,
    );
    if (result.failureOrNull case final failure?) {
      final split = failure.toFormErrors(
        fieldNames: const {'recoveryPin': Fields.pin},
        codeFields: const {FailureCodes.authPhoneTaken: Fields.phone},
      );
      final backToCredentials = split.fields.keys.any((k) => k == Fields.phone || k == Fields.password);
      return emit(state.copyWith(
        status: FormStatus.idle,
        step: backToCredentials ? SignUpStep.credentials : state.step,
        errors: split.fields,
        failure: () => split.general,
      ));
    }
    if (PhoneNumbers.split(phone) case final parts?) await _countries.remember(parts.iso2);
    emit(state.copyWith(status: FormStatus.success));
  }
}

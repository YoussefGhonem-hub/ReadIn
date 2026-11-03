import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/security/credential_rules.dart';
import '../../domain/entities/auth_config.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'form_support.dart';

enum ForgotStep { verify, newPassword, done }

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.step = ForgotStep.verify,
    this.config = AuthConfig.defaults,
    this.status = FormStatus.idle,
    this.errors = const {},
    this.failure,
    this.phone,
  });

  final ForgotStep step;
  final AuthConfig config;
  final FormStatus status;
  final Map<String, String> errors;
  final Failure? failure;

  /// The verified number, pre-filled on Sign in afterwards.
  final String? phone;

  bool get submitting => status == FormStatus.submitting;

  ForgotPasswordState copyWith({
    ForgotStep? step,
    AuthConfig? config,
    FormStatus? status,
    Map<String, String>? errors,
    Failure? Function()? failure,
    String? phone,
  }) =>
      ForgotPasswordState(
        step: step ?? this.step,
        config: config ?? this.config,
        status: status ?? this.status,
        errors: errors ?? this.errors,
        failure: failure != null ? failure() : this.failure,
        phone: phone ?? this.phone,
      );

  @override
  List<Object?> get props => [step, config, status, errors, failure, phone];
}

/// Forgot password (SPEC §9.2, ADR 0009): phone + recovery PIN → a 10-minute reset token → new password. An expired
/// token sends the user back to step 1.
@injectable
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._verify, this._reset, this._config) : super(const ForgotPasswordState());

  final VerifyRecoveryPin _verify;
  final ResetPassword _reset;
  final GetAuthConfig _config;
  String? _resetToken;

  Future<void> loadConfig() async {
    final config = await _config();
    if (!isClosed) emit(state.copyWith(config: config));
  }

  Future<void> submitVerification({required String? phoneE164, required bool phoneEmpty, required String pin}) async {
    if (state.submitting) return;
    final errors = Validate.collect({
      Fields.phone: Validate.phone(empty: phoneEmpty, e164: phoneE164),
      Fields.pin: Validate.existingPin(pin, state.config.pinLength),
    });
    if (errors.isNotEmpty) return emit(state.copyWith(errors: errors, failure: () => null));

    emit(state.copyWith(status: FormStatus.submitting, errors: const {}, failure: () => null));
    final result = await _verify(phoneNumber: phoneE164!, pin: RecoveryPinRules.normalize(pin));
    result.fold(
      (failure) {
        final split = failure.toFormErrors();
        emit(state.copyWith(status: FormStatus.idle, errors: split.fields, failure: () => split.general));
      },
      (token) {
        _resetToken = token;
        emit(state.copyWith(status: FormStatus.idle, step: ForgotStep.newPassword, phone: phoneE164));
      },
    );
  }

  Future<void> submitNewPassword({required String password, required String confirmPassword}) async {
    final token = _resetToken;
    if (state.submitting || token == null) return;
    final errors = Validate.collect({
      Fields.password: Validate.newPassword(password, state.config.password, phoneE164: state.phone),
      Fields.confirmPassword: Validate.confirmation(confirmPassword, password, CredentialCodes.passwordMismatch),
    });
    if (errors.isNotEmpty) return emit(state.copyWith(errors: errors, failure: () => null));

    emit(state.copyWith(status: FormStatus.submitting, errors: const {}, failure: () => null));
    final result = await _reset(resetToken: token, newPassword: password);
    if (result.failureOrNull case final failure?) {
      if (failure.code == FailureCodes.authResetTokenInvalid) {
        _resetToken = null; // expired or used: start again
        return emit(state.copyWith(status: FormStatus.idle, step: ForgotStep.verify, failure: () => failure));
      }
      final split = failure.toFormErrors(fieldNames: const {'newPassword': Fields.password});
      return emit(state.copyWith(status: FormStatus.idle, errors: split.fields, failure: () => split.general));
    }
    _resetToken = null;
    emit(state.copyWith(status: FormStatus.success, step: ForgotStep.done));
  }

  void restart() {
    _resetToken = null;
    emit(state.copyWith(step: ForgotStep.verify, errors: const {}, failure: () => null));
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/phone/countries.dart';
import '../../../../core/phone/phone_numbers.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'form_support.dart';

class SignInState extends Equatable {
  const SignInState({this.status = FormStatus.idle, this.errors = const {}, this.failure});

  final FormStatus status;
  final Map<String, String> errors;

  /// Wrong number or password (one generic message, SPEC §9.5), locked out, suspended, offline…
  final Failure? failure;

  bool get submitting => status == FormStatus.submitting;

  @override
  List<Object?> get props => [status, errors, failure];
}

/// Sign in with phone + password (SPEC §9.2). On success the session changes and the router applies the guards.
@injectable
class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._signIn, this._countries) : super(const SignInState());

  final SignIn _signIn;
  final PhoneCountryMemory _countries;

  Future<void> submit({required String? phoneE164, required bool phoneEmpty, required String password}) async {
    if (state.submitting) return;
    final errors = Validate.collect({
      Fields.phone: Validate.phone(empty: phoneEmpty, e164: phoneE164),
      Fields.password: Validate.required(password),
    });
    if (errors.isNotEmpty) return emit(SignInState(errors: errors));

    emit(const SignInState(status: FormStatus.submitting));
    final result = await _signIn(phoneNumber: phoneE164!, password: password);
    if (result.failureOrNull case final failure?) {
      final split = failure.toFormErrors();
      return emit(SignInState(errors: split.fields, failure: split.general));
    }
    if (PhoneNumbers.split(phoneE164) case final parts?) await _countries.remember(parts.iso2);
    emit(const SignInState(status: FormStatus.success));
  }
}

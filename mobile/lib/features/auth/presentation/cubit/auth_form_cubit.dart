import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/usecases/auth_usecases.dart';

enum AuthFormStatus { idle, submitting, success, failure }

class AuthFormState extends Equatable {
  const AuthFormState({this.status = AuthFormStatus.idle, this.failure});

  final AuthFormStatus status;
  final Failure? failure;

  bool get submitting => status == AuthFormStatus.submitting;

  @override
  List<Object?> get props => [status, failure];
}

/// Email/password sign-in, sign-up and password reset (F01).
@injectable
class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit(this._signIn, this._signUp, this._reset) : super(const AuthFormState());

  final SignInWithEmail _signIn;
  final SignUpWithEmail _signUp;
  final SendPasswordReset _reset;

  Future<void> signIn({required String email, required String password}) =>
      _run(() => _signIn(email: email, password: password));

  Future<void> signUp({required String displayName, required String email, required String password}) =>
      _run(() => _signUp(displayName: displayName, email: email, password: password));

  Future<void> sendReset(String email) => _run(() => _reset(email));

  Future<void> _run(Future<Result<void>> Function() action) async {
    if (state.submitting) return;
    emit(const AuthFormState(status: AuthFormStatus.submitting));
    final result = await action();
    emit(result.fold(
      (failure) => AuthFormState(status: AuthFormStatus.failure, failure: failure),
      (_) => const AuthFormState(status: AuthFormStatus.success),
    ));
  }
}

import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/me.dart';
import '../repositories/auth_repository.dart';

@injectable
class WatchAuthState {
  const WatchAuthState(this._auth);

  final AuthRepository _auth;

  Stream<String?> call() => _auth.watchUid();
}

@injectable
class SignInWithEmail {
  const SignInWithEmail(this._auth);

  final AuthRepository _auth;

  Future<Result<void>> call({required String email, required String password}) =>
      _auth.signInWithEmail(email: email.trim(), password: password);
}

@injectable
class SignUpWithEmail {
  const SignUpWithEmail(this._auth);

  final AuthRepository _auth;

  Future<Result<void>> call({required String displayName, required String email, required String password}) =>
      _auth.signUpWithEmail(displayName: displayName.trim(), email: email.trim(), password: password);
}

@injectable
class SendPasswordReset {
  const SendPasswordReset(this._auth);

  final AuthRepository _auth;

  Future<Result<void>> call(String email) => _auth.sendPasswordReset(email.trim());
}

@injectable
class SignOut {
  const SignOut(this._auth);

  final AuthRepository _auth;

  Future<void> call() => _auth.signOut();
}

@injectable
class SyncAccount {
  const SyncAccount(this._accounts);

  final AccountRepository _accounts;

  Future<Result<Me>> call({required String uiLanguage}) => _accounts.sync(uiLanguage: uiLanguage);
}

@injectable
class GetMe {
  const GetMe(this._accounts);

  final AccountRepository _accounts;

  Future<Result<Me>> call() => _accounts.getMe();
}

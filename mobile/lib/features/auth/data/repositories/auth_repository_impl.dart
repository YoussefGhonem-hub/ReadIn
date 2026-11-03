import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/platform/time_zone_service.dart';
import '../../domain/entities/me.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/account_api.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../models/me_model.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._firebase);

  final FirebaseAuthDataSource _firebase;

  @override
  bool get isAvailable => _firebase.isAvailable;

  @override
  Stream<String?> watchUid() => _firebase.watchUid();

  @override
  Future<Result<void>> signInWithEmail({required String email, required String password}) =>
      _firebase.signIn(email, password);

  @override
  Future<Result<void>> signUpWithEmail({required String displayName, required String email, required String password}) =>
      _firebase.signUp(displayName, email, password);

  @override
  Future<Result<void>> sendPasswordReset(String email) => _firebase.sendPasswordReset(email);

  @override
  Future<void> signOut() => _firebase.signOut();
}

@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._api, this._timeZone);

  final AccountApi _api;
  final TimeZoneService _timeZone;

  @override
  Future<Result<Me>> sync({required String uiLanguage}) async {
    final timeZone = await _timeZone.current();
    return guardApi(() async =>
        (await _api.sync(SyncUserRequest(uiLanguage: uiLanguage, timeZone: timeZone))).toEntity());
  }

  @override
  Future<Result<Me>> getMe() => guardApi(() async => (await _api.getMe()).toEntity());
}

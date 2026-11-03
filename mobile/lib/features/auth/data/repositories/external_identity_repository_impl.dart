import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/external_credential.dart';
import '../../domain/repositories/external_identity_repository.dart';
import '../datasources/apple_sign_in_data_source.dart';
import '../datasources/google_sign_in_data_source.dart';

@LazySingleton(as: ExternalIdentityRepository)
class ExternalIdentityRepositoryImpl implements ExternalIdentityRepository {
  ExternalIdentityRepositoryImpl(this._google, this._apple);

  final GoogleSignInDataSource _google;
  final AppleSignInDataSource _apple;

  @override
  bool supports(ExternalProvider provider) => switch (provider) {
        ExternalProvider.google => true,
        ExternalProvider.apple => _apple.isSupported,
      };

  @override
  Future<Result<ExternalCredential?>> obtain(ExternalProvider provider) async {
    try {
      return Ok(await switch (provider) {
        ExternalProvider.google => _google.signInWithGoogle(),
        ExternalProvider.apple => _apple.signInWithApple(),
      });
    } on Exception catch (e) {
      return Err(Failure(FailureCodes.authExternalProviderFailed, message: '$e'));
    }
  }

  @override
  Future<void> forget() => _google.signOut();
}

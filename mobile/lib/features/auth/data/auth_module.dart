import 'package:injectable/injectable.dart';

import '../../../core/network/request_context.dart';
import 'datasources/firebase_auth_data_source.dart';

/// Exposes the Firebase data source to `core/network` through the
/// [IdTokenProvider] abstraction, so core never imports Firebase Auth.
@module
abstract class AuthModule {
  @lazySingleton
  IdTokenProvider idTokenProvider(FirebaseAuthDataSource firebase) => firebase;
}

import 'package:injectable/injectable.dart';

import '../../../core/network/request_context.dart';
import 'datasources/auth_session_store.dart';

/// Exposes the session store to `core/network` through [SessionTokenProvider], so core never imports the auth feature.
@module
abstract class AuthModule {
  @lazySingleton
  SessionTokenProvider sessionTokens(AuthSessionStore store) => store;
}

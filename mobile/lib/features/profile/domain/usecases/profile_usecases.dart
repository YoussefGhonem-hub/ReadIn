import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../../../auth/domain/entities/me.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

@injectable
class GetProfile {
  const GetProfile(this._repository);

  final ProfileRepository _repository;

  Future<Result<UserProfile>> call(String username) => _repository.getProfile(username);
}

/// The Articles tab of a profile.
@injectable
class GetUserArticles {
  const GetUserArticles(this._repository);

  final ProfileRepository _repository;

  static const pageSize = 20;

  Future<Result<CursorPage<ArticleCard>>> call(String username, {String? cursor}) =>
      _repository.getArticles(username, cursor: cursor, limit: pageSize);
}

/// The Reposts tab of a profile (F29).
@injectable
class GetUserReposts {
  const GetUserReposts(this._repository);

  final ProfileRepository _repository;

  static const pageSize = 20;

  Future<Result<CursorPage<ArticleCard>>> call(String username, {String? cursor}) =>
      _repository.getReposts(username, cursor: cursor, limit: pageSize);
}

/// Saves the edited profile, then refetches `GET /me` so the session (and every screen) shows it.
@injectable
class UpdateProfile {
  const UpdateProfile(this._repository, this._accounts);

  final ProfileRepository _repository;
  final AccountRepository _accounts;

  Future<Result<void>> call(ProfileUpdate update) async {
    final result = await _repository.updateProfile(update);
    if (result.isOk) await _accounts.getMe(); // saved either way; a failed refetch is retried by the next /me
    return result;
  }
}

/// Settings → Privacy and the own profile (F14, F18): "show my reading stats on my public profile" and "who can mention
/// me". Sends the whole [PrivacySettings], then refetches `GET /me` so the session has it.
@injectable
class SetPrivacy {
  const SetPrivacy(this._repository, this._accounts);

  final ProfileRepository _repository;
  final AccountRepository _accounts;

  Future<Result<void>> call(PrivacySettings privacy) async {
    final result = await _repository.setPrivacy(privacy);
    if (result.isOk) await _accounts.getMe();
    return result;
  }
}

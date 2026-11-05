import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../../../auth/domain/entities/me.dart';
import '../entities/profile.dart';

abstract interface class ProfileRepository {
  /// `GET /users/{username}` (guests allowed; case-insensitive, a leading `@` is ignored). `404 user.not_found` for
  /// deleted or suspended users.
  Future<Result<UserProfile>> getProfile(String username);

  /// `GET /users/{username}/articles`: published articles, newest first, with the viewer's reaction and save.
  Future<Result<CursorPage<ArticleCard>>> getArticles(String username, {String? cursor, int limit = 20});

  /// `GET /users/{username}/reposts` (F29): the articles the user reposted, newest repost first.
  Future<Result<CursorPage<ArticleCard>>> getReposts(String username, {String? cursor, int limit = 20});

  /// `PATCH /me` → `204`. `409 user.username_taken`, `400 profile.avatar_invalid`, `400 profile.expertise_invalid`,
  /// validation codes per field.
  Future<Result<void>> updateProfile(ProfileUpdate update);

  /// `PUT /me/privacy` with the whole [privacy] object → `204`.
  Future<Result<void>> setPrivacy(PrivacySettings privacy);
}

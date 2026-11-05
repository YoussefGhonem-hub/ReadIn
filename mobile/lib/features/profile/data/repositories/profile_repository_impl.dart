import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../article/domain/entities/article.dart';
import '../../../auth/domain/entities/me.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_api.dart';
import '../models/profile_models.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);

  final ProfileApi _api;

  /// Handles are matched case-insensitively and a leading `@` is ignored; sending the bare lower-case handle keeps
  /// one cache key per profile.
  static String handle(String username) {
    final trimmed = username.trim();
    return (trimmed.startsWith('@') ? trimmed.substring(1) : trimmed).toLowerCase();
  }

  @override
  Future<Result<UserProfile>> getProfile(String username) =>
      guardApi(() async => (await _api.getProfile(handle(username))).toEntity());

  @override
  Future<Result<CursorPage<ArticleCard>>> getArticles(String username, {String? cursor, int limit = 20}) => guardApi(() async {
        final page = await _api.getArticles(handle(username), cursor, limit);
        return CursorPage(items: [for (final m in page.items) m.toEntity()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<CursorPage<ArticleCard>>> getReposts(String username, {String? cursor, int limit = 20}) => guardApi(() async {
        final page = await _api.getReposts(handle(username), cursor, limit);
        return CursorPage(items: [for (final m in page.items) m.toEntity()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<void>> updateProfile(ProfileUpdate update) => guardApi(() => _api.updateProfile(UpdateProfileRequest(update)));

  @override
  Future<Result<void>> setPrivacy(PrivacySettings privacy) => guardApi(() => _api.setPrivacy(PrivacyRequest(privacy)));
}

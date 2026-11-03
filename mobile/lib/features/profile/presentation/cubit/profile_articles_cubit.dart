import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../../../home/presentation/cubit/feed_cubit.dart';
import '../../domain/usecases/profile_usecases.dart';

/// The Articles tab of a profile (F14): published articles, newest first, with pull to refresh and infinite scroll.
@injectable
class ProfileArticlesCubit extends ArticleFeedCubit {
  ProfileArticlesCubit(this._getArticles, @factoryParam String username) : _username = username;

  final GetUserArticles _getArticles;
  final String _username;

  @override
  Future<Result<CursorPage<ArticleCard>>> fetch({String? fieldSlug, String? cursor}) => _getArticles(_username, cursor: cursor);
}

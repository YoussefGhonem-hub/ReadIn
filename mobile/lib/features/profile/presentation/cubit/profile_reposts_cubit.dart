import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../../../home/presentation/cubit/feed_cubit.dart';
import '../../domain/usecases/profile_usecases.dart';

/// The Reposts tab of a profile (F29): what the user reposted, newest repost first, with pull to refresh and infinite
/// scroll. It loads the first time the tab is shown ([ensureLoaded]).
@injectable
class ProfileRepostsCubit extends ArticleFeedCubit {
  ProfileRepostsCubit(this._getReposts, @factoryParam String username) : _username = username;

  final GetUserReposts _getReposts;
  final String _username;

  @override
  Future<Result<CursorPage<ArticleCard>>> fetch({String? fieldSlug, String? cursor}) => _getReposts(_username, cursor: cursor);
}

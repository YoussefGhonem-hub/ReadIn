import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/article.dart';
import '../../domain/usecases/get_related_articles.dart';

/// "Related articles" at the end of the reader (F04): the cards for the article and version being read. A failed
/// request leaves the list empty, like an article with none: the section just hides.
@injectable
class RelatedArticlesCubit extends Cubit<List<ArticleCard>> {
  RelatedArticlesCubit(this._getRelated) : super(const []);

  final GetRelatedArticles _getRelated;

  // Only the newest request may answer: switching the version again drops an older answer.
  int _request = 0;

  /// Loads the cards for [articleId] in [language]. The cards shown stay until the new ones arrive.
  Future<void> load(String articleId, {required String language}) async {
    final request = ++_request;
    final result = await _getRelated(articleId, language: language);
    if (isClosed || request != _request) return;
    emit(result.fold((_) => const [], (cards) => cards));
  }
}

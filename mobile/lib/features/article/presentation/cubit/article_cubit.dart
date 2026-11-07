import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/article.dart';
import '../../domain/usecases/get_article.dart';

enum ArticleStatus { loading, ready, failure }

class ArticleState extends Equatable {
  const ArticleState({this.status = ArticleStatus.loading, this.article, this.failure, this.switchingLanguage = false});

  final ArticleStatus status;
  final ArticleDetails? article;
  final Failure? failure;

  /// True while a language toggle is reloading (keeps the current article visible).
  final bool switchingLanguage;

  ArticleState copyWith({ArticleStatus? status, ArticleDetails? article, Failure? failure, bool? switchingLanguage}) =>
      ArticleState(
        status: status ?? this.status,
        article: article ?? this.article,
        failure: failure,
        switchingLanguage: switchingLanguage ?? this.switchingLanguage,
      );

  @override
  List<Object?> get props => [status, article, failure, switchingLanguage];
}

/// Article reader (F04): loads `GET /articles/{slug}?lang=` and switches
/// between the `ar-EG` and `en` versions.
@injectable
class ArticleCubit extends Cubit<ArticleState> {
  ArticleCubit(this._getArticle) : super(const ArticleState());

  final GetArticle _getArticle;
  String? _slug;

  Future<void> load(String slug, {required String preferredLanguage}) async {
    _slug = slug;
    emit(const ArticleState());
    final result = await _getArticle(slug, language: preferredLanguage);
    emit(result.fold(
      (failure) => ArticleState(status: ArticleStatus.failure, failure: failure),
      (article) => ArticleState(status: ArticleStatus.ready, article: article),
    ));
  }

  Future<void> switchLanguage(String language) async {
    final current = state.article;
    if (_slug == null || current == null || current.card.language == language) return;
    emit(state.copyWith(switchingLanguage: true));
    final result = await _getArticle(_slug!, language: language);
    emit(result.fold(
      (failure) => state.copyWith(switchingLanguage: false, failure: failure),
      (article) => ArticleState(status: ArticleStatus.ready, article: article),
    ));
  }

  Future<void> retry(String preferredLanguage) async {
    if (_slug != null) await load(_slug!, preferredLanguage: preferredLanguage);
  }

  /// Loads the version on screen again and keeps showing it meanwhile: a highlight found its text changed by the author
  /// (F30, `highlight.text_mismatch`). A failure keeps the version shown.
  Future<void> reloadVersion() async {
    final current = state.article;
    if (_slug == null || current == null) return;
    final result = await _getArticle(_slug!, language: current.card.language);
    if (isClosed || state.article?.card.language != current.card.language) return;
    result.fold((_) {}, (article) => emit(ArticleState(status: ArticleStatus.ready, article: article)));
  }

  /// A moderator hid the article ([moderation]) or showed it again (null) from the reader's menu (F22).
  void setModeration(ArticleModeration? moderation) {
    final article = state.article;
    if (article == null || isClosed) return;
    emit(state.copyWith(article: article.withModeration(moderation)));
  }

  /// The SuperAdmin featured the article on Explore, or stopped featuring it, from the reader's menu (F23).
  void setFeatured(bool featured) {
    final article = state.article;
    if (article == null || isClosed) return;
    emit(state.copyWith(article: article.withFeatured(featured)));
  }
}

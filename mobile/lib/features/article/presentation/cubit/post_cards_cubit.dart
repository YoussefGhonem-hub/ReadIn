import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/article.dart';
import '../../domain/usecases/get_article_preview.dart';

enum PreviewStatus { idle, loading, ready, failure }

/// What one post card shows besides its article (F34): expanded or not, and the preview "Read more" loaded.
class PostCardView extends Equatable {
  const PostCardView({this.expanded = false, this.status = PreviewStatus.idle, this.preview, this.failure, this.hidden = false});

  final bool expanded;
  final PreviewStatus status;

  /// Loaded by the first expansion; kept when the card collapses, so expanding again shows it at once.
  final ArticlePreview? preview;
  final Failure? failure;

  /// A moderator hid the article from this card's menu (F22): the menu offers "unhide" next.
  final bool hidden;

  PostCardView copyWith({bool? expanded, PreviewStatus? status, ArticlePreview? preview, Failure? Function()? failure, bool? hidden}) =>
      PostCardView(
        expanded: expanded ?? this.expanded,
        status: status ?? this.status,
        preview: preview ?? this.preview,
        failure: failure != null ? failure() : this.failure,
        hidden: hidden ?? this.hidden,
      );

  @override
  List<Object?> get props => [expanded, status, preview, failure, hidden];
}

class PostCardsState extends Equatable {
  const PostCardsState([this.cards = const {}]);

  final Map<String, PostCardView> cards;

  PostCardView of(String articleId) => cards[articleId] ?? const PostCardView();

  @override
  List<Object?> get props => [cards];
}

typedef PreviewLoader = Future<Result<ArticlePreview>> Function(String articleId, {required String language});

/// The post cards of one list (a Home feed, a profile's articles, related articles): which are expanded and the
/// previews they loaded (F34). The list's screen owns it, so a card scrolled away and built again, or a list left for
/// the reader or a profile and come back to, shows the same. Pull to refresh [reset]s it.
@injectable
class PostCardsCubit extends Cubit<PostCardsState> {
  PostCardsCubit(GetArticlePreview getPreview) : this.withLoader(getPreview.call);

  PostCardsCubit.withLoader(this._load) : super(const PostCardsState());

  final PreviewLoader _load;

  /// Incremented by [reset], so a preview requested before it is dropped.
  int _generation = 0;

  /// Expands [card]; the first expansion loads its preview (a failed one loads again).
  Future<void> expand(ArticleCard card) async {
    final current = state.of(card.id);
    _put(card.id, current.copyWith(expanded: true));
    if (current.status == PreviewStatus.ready || current.status == PreviewStatus.loading) return;
    await _fetch(card);
  }

  /// The preview failed: try again.
  Future<void> retry(ArticleCard card) async {
    if (state.of(card.id).status == PreviewStatus.loading) return;
    await _fetch(card);
  }

  void collapse(String articleId) {
    final current = state.of(articleId);
    if (current.expanded) _put(articleId, current.copyWith(expanded: false));
  }

  void setHidden(String articleId, {required bool hidden}) => _put(articleId, state.of(articleId).copyWith(hidden: hidden));

  /// Pull to refresh: every card shows collapsed again.
  void reset() {
    _generation++;
    if (state.cards.isNotEmpty) emit(const PostCardsState());
  }

  Future<void> _fetch(ArticleCard card) async {
    final generation = _generation;
    _put(card.id, state.of(card.id).copyWith(status: PreviewStatus.loading, failure: () => null));
    final result = await _load(card.id, language: card.language);
    if (isClosed || generation != _generation) return;
    result.fold(
      (failure) => _put(card.id, state.of(card.id).copyWith(status: PreviewStatus.failure, failure: () => failure)),
      (preview) => _put(card.id, state.of(card.id).copyWith(status: PreviewStatus.ready, preview: preview)),
    );
  }

  void _put(String articleId, PostCardView view) {
    if (!isClosed) emit(PostCardsState({...state.cards, articleId: view}));
  }
}

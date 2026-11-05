import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../../../home/presentation/cubit/feed_cubit.dart';
import '../../domain/entities/tag.dart';
import '../../domain/usecases/tag_usecases.dart';

enum TagStatus { loading, ready, failure }

class TagState extends Equatable {
  const TagState({this.status = TagStatus.loading, this.tag, this.failure});

  final TagStatus status;
  final ArticleTag? tag;
  final Failure? failure;

  /// Unknown or hidden (`404 tag.not_found`).
  bool get notFound => status == TagStatus.failure && isTagNotFound(failure);

  @override
  List<Object?> get props => [status, tag, failure];
}

/// `404 tag.not_found`: the tag is unknown or hidden by moderators.
bool isTagNotFound(Failure? failure) => failure?.code == FailureCodes.tagNotFound || failure?.statusCode == 404;

/// The tag page's header (F32): `GET /tags/{slug}`, the name and the article count.
@injectable
class TagCubit extends Cubit<TagState> {
  TagCubit(this._getTag) : super(const TagState());

  final GetTag _getTag;
  String? _slug;

  /// Incremented on every load so an older answer is dropped.
  int _generation = 0;

  Future<void> load(String slug) async {
    _slug = slug;
    final generation = ++_generation;
    emit(const TagState());
    final result = await _getTag(slug);
    if (generation != _generation || isClosed) return;
    emit(result.fold(
      (failure) => TagState(status: TagStatus.failure, failure: failure),
      (tag) => TagState(status: TagStatus.ready, tag: tag),
    ));
  }

  /// Pull to refresh: the header stays until the new one arrives; a failed refresh keeps it.
  Future<void> refresh() async {
    final slug = _slug;
    if (slug == null) return;
    if (state.tag == null) return load(slug);
    final generation = ++_generation;
    final result = await _getTag(slug);
    if (generation != _generation || isClosed) return;
    if (result case Ok(value: final tag)) emit(TagState(status: TagStatus.ready, tag: tag));
  }
}

/// The tag page's articles (F32): every published article with the tag, from all writers, newest first, with pull to
/// refresh and infinite scroll.
@injectable
class TagArticlesCubit extends ArticleFeedCubit {
  TagArticlesCubit(this._getArticles, @factoryParam String slug) : _slug = slug;

  final GetTagArticles _getArticles;
  final String _slug;

  @override
  Future<Result<CursorPage<ArticleCard>>> fetch({String? fieldSlug, String? cursor}) => _getArticles(_slug, cursor: cursor);
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/admin_content.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_user_cubit.dart' show AdminPageStatus;

class AdminArticleState extends Equatable {
  const AdminArticleState({this.status = AdminPageStatus.loading, this.article, this.failure, this.featuring = false});

  final AdminPageStatus status;
  final AdminArticleRow? article;
  final Failure? failure;

  /// Feature / Unfeature in flight.
  final bool featuring;

  @override
  List<Object?> get props => [status, article, failure, featuring];
}

/// An article in the console's Content (F23, "Open in console"): its numbers, its state, and featuring.
@injectable
class AdminArticleCubit extends Cubit<AdminArticleState> {
  AdminArticleCubit(this._get, this._setFeatured, @factoryParam this.articleId) : super(const AdminArticleState());

  final GetAdminArticle _get;
  final SetArticleFeatured _setFeatured;
  final String articleId;

  Future<Failure?> load() async {
    final result = await _get(articleId);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        if (state.article == null) emit(AdminArticleState(status: AdminPageStatus.failure, failure: failure));
        return failure;
      },
      (article) {
        emit(AdminArticleState(status: AdminPageStatus.ready, article: article));
        return null;
      },
    );
  }

  /// Feature it on Explore, or stop: null when it worked (the article is read again).
  Future<Failure?> setFeatured(bool featured) async {
    final article = state.article;
    if (article == null || state.featuring) return const Failure(FailureCodes.requestCancelled);
    emit(AdminArticleState(status: state.status, article: article, featuring: true));
    final result = await _setFeatured(articleId, featured: featured);
    if (isClosed) return result.failureOrNull;
    if (result.isOk) {
      emit(AdminArticleState(
        status: state.status,
        article: article.copyWith(featuredAt: () => featured ? (article.featuredAt ?? DateTime.now().toUtc()) : null),
      ));
      await load();
    } else {
      emit(AdminArticleState(status: state.status, article: article));
    }
    return result.failureOrNull;
  }

  /// A moderator hid or unhid it from this page: read it again.
  Future<void> refresh() => load();
}

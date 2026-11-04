import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/learning_path.dart';
import '../../domain/usecases/path_usecases.dart';

/// [none]: the article is in no published path (204), or the call failed: the block renders nothing.
enum ArticlePathStatus { loading, none, ready }

class ArticlePathState extends Equatable {
  const ArticlePathState({this.status = ArticlePathStatus.loading, this.articlePath, this.joining = false});

  final ArticlePathStatus status;
  final ArticlePath? articlePath;

  /// "Join path" is in flight.
  final bool joining;

  @override
  List<Object?> get props => [status, articlePath, joining];
}

/// The reader's "Next in path" block (F04, F09): `GET /articles/{id}/path`, loaded when the block is first laid out,
/// and "Join path" (`PUT /me/paths/{id}`, then the block reloads).
@injectable
class ArticlePathCubit extends Cubit<ArticlePathState> {
  ArticlePathCubit(this._getArticlePath, this._enrollment) : super(const ArticlePathState());

  final GetArticlePath _getArticlePath;
  final SetPathEnrollment _enrollment;
  String? _articleId;

  Future<void> load(String articleId) async {
    _articleId = articleId;
    final result = await _getArticlePath(articleId);
    if (isClosed || articleId != _articleId) return;
    final articlePath = result.valueOrNull;
    emit(articlePath == null
        ? const ArticlePathState(status: ArticlePathStatus.none)
        : ArticlePathState(status: ArticlePathStatus.ready, articlePath: articlePath));
  }

  /// Enrolls in the block's path, then reloads the block (progress and badge). Returns the failure to show, if any.
  Future<Failure?> join() async {
    final current = state.articlePath;
    final articleId = _articleId;
    if (current == null || articleId == null || state.joining) return null;
    emit(ArticlePathState(status: state.status, articlePath: current, joining: true));
    final enrolled = await _enrollment.enroll(current.path.id);
    if (isClosed) return enrolled.failureOrNull;
    switch (enrolled) {
      case Err(:final failure):
        emit(ArticlePathState(status: state.status, articlePath: current));
        return failure;
      case Ok(value: final path):
        final reloaded = await _getArticlePath(articleId);
        if (isClosed) return null;
        // A failed reload still shows the enrollment the PUT returned.
        emit(ArticlePathState(status: ArticlePathStatus.ready, articlePath: reloaded.valueOrNull ?? current.withPath(path)));
        return null;
    }
  }
}

import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/platform/share_service.dart';
import '../../domain/usecases/download_article_pdf.dart';

/// One "Download PDF": the article, the version to print (`ar-EG` | `en`) and where its share sheet is anchored (iPad).
class ArticlePdfRequest extends Equatable {
  const ArticlePdfRequest(this.articleId, this.language, {this.origin});

  final String articleId;
  final String language;

  /// The tapped item's rect: "Try again" opens the share sheet from the same place.
  final Rect? origin;

  @override
  List<Object?> get props => [articleId, language, origin];
}

class ArticlePdfState extends Equatable {
  const ArticlePdfState({this.building = const {}, this.failure, this.failed, this.failureSeq = 0});

  /// Articles whose PDF is being built: their item shows "Preparing the PDF…", disabled, with a spinner.
  final Set<String> building;

  /// The last failed download, to explain once; [failureSeq] changes with every one.
  final Failure? failure;
  final ArticlePdfRequest? failed;
  final int failureSeq;

  bool isBuilding(String articleId) => building.contains(articleId);

  @override
  List<Object?> get props => [building, failure, failed, failureSeq];
}

/// "Download PDF" (SPEC F33) in the reader's "⋯" menu (any article, for every member) and in My articles: the API builds
/// the file (up to about 90 s), the app saves it to a temporary file and opens the system share sheet to save or send
/// it. A second tap while it builds does nothing.
@injectable
class ArticlePdfCubit extends Cubit<ArticlePdfState> {
  ArticlePdfCubit(this._download, this._share) : super(const ArticlePdfState());

  final DownloadArticlePdf _download;
  final ShareService _share;

  /// [origin] anchors the share sheet on iPad.
  Future<void> download(String articleId, {required String language, Rect? origin}) async {
    if (state.isBuilding(articleId)) return;
    emit(_next(building: {...state.building, articleId}));
    final result = await _download(articleId, language: language);
    if (isClosed) return;
    final building = {...state.building}..remove(articleId);
    switch (result) {
      case Err(:final failure):
        emit(ArticlePdfState(
          building: building,
          failure: failure,
          failed: ArticlePdfRequest(articleId, language, origin: origin),
          failureSeq: state.failureSeq + 1,
        ));
      case Ok(:final value):
        emit(_next(building: building));
        try {
          await _share.shareFile(value.path, mimeType: 'application/pdf', fileName: value.fileName, origin: origin);
        } on Object {
          // A dismissed or missing share sheet: nothing to say.
        }
    }
  }

  /// "Try again" on the last failure: the same version, with the share sheet anchored where the first tap was (iPad
  /// needs an anchor, and the snackbar's button has none to give), unless [origin] says otherwise.
  Future<void> retry({Rect? origin}) async {
    final failed = state.failed;
    if (failed != null) await download(failed.articleId, language: failed.language, origin: origin ?? failed.origin);
  }

  ArticlePdfState _next({required Set<String> building}) =>
      ArticlePdfState(building: building, failure: state.failure, failed: state.failed, failureSeq: state.failureSeq);
}

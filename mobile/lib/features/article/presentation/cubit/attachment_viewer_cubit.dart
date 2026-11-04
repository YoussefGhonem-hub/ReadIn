import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/config/app_links.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/models/transfer.dart';
import '../../../../core/platform/share_service.dart';
import '../../../media/domain/entities/media.dart';
import '../../../media/domain/usecases/media_usecases.dart';
import '../../domain/usecases/get_article.dart';

enum DownloadStatus { idle, downloading, failed }

class AttachmentViewerState extends Equatable {
  const AttachmentViewerState({
    this.document,
    this.loadingPages = false,
    this.pagesFailure,
    this.download = DownloadStatus.idle,
    this.downloadProgress,
    this.downloadFailure,
  });

  /// The PDF being viewed (null for images).
  final DocumentAttachment? document;

  /// Feed cards carry at most 10 pages; the rest load with the article.
  final bool loadingPages;
  final Failure? pagesFailure;
  final DownloadStatus download;
  final double? downloadProgress;
  final Failure? downloadFailure;

  AttachmentViewerState copyWith({
    DocumentAttachment? document,
    bool? loadingPages,
    Failure? Function()? pagesFailure,
    DownloadStatus? download,
    double? Function()? downloadProgress,
    Failure? Function()? downloadFailure,
  }) =>
      AttachmentViewerState(
        document: document ?? this.document,
        loadingPages: loadingPages ?? this.loadingPages,
        pagesFailure: pagesFailure != null ? pagesFailure() : this.pagesFailure,
        download: download ?? this.download,
        downloadProgress: downloadProgress != null ? downloadProgress() : this.downloadProgress,
        downloadFailure: downloadFailure != null ? downloadFailure() : this.downloadFailure,
      );

  @override
  List<Object?> get props => [document, loadingPages, pagesFailure, download, downloadProgress, downloadFailure];
}

/// Full-screen viewer actions (F26): loads the remaining PDF pages, downloads
/// the original (with auth headers) and opens the share sheet, and shares the
/// article link.
@injectable
class AttachmentViewerCubit extends Cubit<AttachmentViewerState> {
  AttachmentViewerCubit(this._getArticle, this._download, this._share) : super(const AttachmentViewerState());

  final GetArticle _getArticle;
  final DownloadDocument _download;
  final ShareService _share;

  String _slug = '';
  String _language = 'ar-EG';
  String _title = '';
  TransferToken? _token;

  void start({required String slug, required String language, required String title, DocumentAttachment? document}) {
    _slug = slug;
    _language = language;
    _title = title;
    if (document == null) return;
    emit(AttachmentViewerState(document: document));
    if (!document.hasAllPages) _loadAllPages();
  }

  Future<void> _loadAllPages() async {
    emit(state.copyWith(loadingPages: true, pagesFailure: () => null));
    final result = await _getArticle(_slug, language: _language);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(loadingPages: false, pagesFailure: () => failure)),
      (article) {
        final full = article.card.attachments?.document;
        final current = state.document;
        final pages = full != null && current != null && full.assetId == current.assetId && full.pages.length > current.pages.length
            ? full.pages
            : current?.pages;
        emit(state.copyWith(loadingPages: false, document: current?.copyWith(pages: pages)));
      },
    );
  }

  Future<void> shareLink({Rect? origin}) async {
    try {
      await _share.shareLink(AppLinks.article(_slug, language: _language), subject: _title, origin: origin);
    } on Object {
      // The share sheet is best effort.
    }
  }

  /// Downloads the original PDF to a temp file, then opens the share sheet.
  Future<void> downloadAndShare({Rect? origin}) async {
    final doc = state.document;
    if (doc == null || !doc.canDownload || state.download == DownloadStatus.downloading) return;
    final token = _token = TransferToken();
    emit(state.copyWith(download: DownloadStatus.downloading, downloadProgress: () => null, downloadFailure: () => null));
    final fileName = pdfFileName(doc.title);
    final result = await _download(
      doc.downloadUrl,
      fileName: fileName,
      token: token,
      onProgress: (received, total) {
        if (!isClosed && total > 0) emit(state.copyWith(downloadProgress: () => (received / total).clamp(0.0, 1.0)));
      },
    );
    if (isClosed || token.isCancelled) return;
    await result.fold(
      (failure) async => emit(state.copyWith(download: DownloadStatus.failed, downloadProgress: () => null, downloadFailure: () => failure)),
      (path) async {
        emit(state.copyWith(download: DownloadStatus.idle, downloadProgress: () => null));
        try {
          await _share.shareFile(path, mimeType: 'application/pdf', fileName: fileName, origin: origin);
        } on Object {
          // Dismissed or unavailable share sheet.
        }
      },
    );
  }

  @override
  Future<void> close() {
    _token?.cancel();
    return super.close();
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/media/media_viewer.dart';
import '../../../media/domain/entities/media.dart';
import '../../../media/presentation/media_items.dart';
import '../../domain/entities/article.dart';
import '../cubit/attachment_viewer_cubit.dart';

/// Opens the full-screen viewer on a post's images.
Future<void> openImageViewer(
  BuildContext context, {
  required ArticleCard article,
  required List<ImageAttachment> images,
  required int index,
}) =>
    MediaViewerPage.open(
      context,
      (_) => BlocProvider(
        create: (_) => getIt<AttachmentViewerCubit>()..start(slug: article.slug, language: article.language, title: article.title),
        child: ImageViewerView(images: images, initialIndex: index),
      ),
    );

/// Opens the full-screen document viewer; pages beyond the feed's first 10
/// are loaded with the article.
Future<void> openDocumentViewer(
  BuildContext context, {
  required ArticleCard article,
  required DocumentAttachment document,
  required int index,
}) =>
    MediaViewerPage.open(
      context,
      (_) => BlocProvider(
        create: (_) => getIt<AttachmentViewerCubit>()
          ..start(slug: article.slug, language: article.language, title: article.title, document: document),
        child: DocumentViewerView(document: document, initialIndex: index),
      ),
    );

class ImageViewerView extends StatelessWidget {
  const ImageViewerView({super.key, required this.images, this.initialIndex = 0});

  final List<ImageAttachment> images;
  final int initialIndex;

  @override
  Widget build(BuildContext context) => MediaViewerPage(
        items: [for (final i in images) MediaItems.image(i)],
        kind: MediaViewerKind.images,
        initialIndex: initialIndex,
        actions: const [ViewerShareAction()],
      );
}

class DocumentViewerView extends StatelessWidget {
  const DocumentViewerView({super.key, required this.document, this.initialIndex = 0});

  /// Shown until the cubit has the (possibly fuller) document.
  final DocumentAttachment document;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttachmentViewerCubit, AttachmentViewerState>(
      listenWhen: (a, b) => a.download != b.download && b.download == DownloadStatus.failed,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(localizeFailure(context.l10n, state.downloadFailure!)))),
      builder: (context, state) {
        final doc = state.document ?? document;
        return MediaViewerPage(
          items: [for (final p in doc.pages) MediaItems.pageView(p)],
          kind: MediaViewerKind.document,
          initialIndex: initialIndex,
          totalCount: state.pagesFailure != null ? doc.pages.length : doc.pageCount,
          title: doc.title,
          actions: [
            if (doc.canDownload) const ViewerDownloadAction(),
            const ViewerShareAction(),
          ],
        );
      },
    );
  }
}

Rect? _originOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// "تحميل" / "Download": the original PDF, then the share sheet.
class ViewerDownloadAction extends StatelessWidget {
  const ViewerDownloadAction({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AttachmentViewerCubit>().state;
    if (state.download == DownloadStatus.downloading) {
      return Semantics(
        label: l10n.viewerDownloading,
        liveRegion: true,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, value: state.downloadProgress),
            ),
          ),
        ),
      );
    }
    return IconButton(
      key: const ValueKey('viewer-download'),
      tooltip: l10n.viewerDownload,
      icon: const Icon(Icons.download_rounded),
      onPressed: () => context.read<AttachmentViewerCubit>().downloadAndShare(origin: _originOf(context)),
    );
  }
}

/// The download icon in a PDF's title strip on a card or under the article (SPEC F26): shown only when the caller may
/// download it (`canDownload`: allowed by the writer, or the owner / a moderator). A tap downloads the original PDF
/// (with the session's headers) and opens the system share sheet, where it can be saved to Files / Downloads or sent,
/// as the full-screen viewer's "تحميل" does. A spinner shows the progress; a failure shows a message. The download's
/// cubit is made on the first tap, so a card costs nothing until then.
class DocumentDownloadButton extends StatefulWidget {
  const DocumentDownloadButton({super.key, required this.article, required this.document, this.color, this.createCubit});

  final ArticleCard article;
  final DocumentAttachment document;

  /// The icon's color (the strip's text color).
  final Color? color;

  /// Makes the cubit on the first tap; defaults to the app's (tests pass their own).
  final AttachmentViewerCubit Function()? createCubit;

  static const buttonKey = ValueKey('pdf-strip-download');

  @override
  State<DocumentDownloadButton> createState() => _DocumentDownloadButtonState();
}

class _DocumentDownloadButtonState extends State<DocumentDownloadButton> {
  AttachmentViewerCubit? _cubit;
  StreamSubscription<AttachmentViewerState>? _changes;
  AttachmentViewerState _state = const AttachmentViewerState();

  AttachmentViewerCubit _ensureCubit() {
    final existing = _cubit;
    if (existing != null) return existing;
    final article = widget.article;
    final cubit = (widget.createCubit?.call() ?? getIt<AttachmentViewerCubit>())
      ..start(slug: article.slug, language: article.language, title: article.title, document: widget.document, loadPages: false);
    _state = cubit.state;
    _changes = cubit.stream.listen(_onState);
    return _cubit = cubit;
  }

  void _onState(AttachmentViewerState state) {
    if (!mounted) return;
    final failed = state.download == DownloadStatus.failed && _state.download != DownloadStatus.failed;
    setState(() => _state = state);
    if (failed && state.downloadFailure != null) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(localizeFailure(context.l10n, state.downloadFailure!))));
    }
  }

  Future<void> _download() async {
    final origin = _originOf(context);
    await _ensureCubit().downloadAndShare(origin: origin);
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    unawaited(_cubit?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!widget.document.canDownload) return const SizedBox.shrink();
    if (_state.download == DownloadStatus.downloading) {
      return Semantics(
        label: l10n.viewerDownloading,
        liveRegion: true,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, value: _state.downloadProgress, color: widget.color),
            ),
          ),
        ),
      );
    }
    return IconButton(
      key: DocumentDownloadButton.buttonKey,
      tooltip: l10n.pdfStripDownload,
      icon: const Icon(Icons.download_rounded),
      color: widget.color,
      iconSize: 22,
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      onPressed: () => unawaited(_download()),
    );
  }
}

/// "مشاركة" / "Share": the article link.
class ViewerShareAction extends StatelessWidget {
  const ViewerShareAction({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        key: const ValueKey('viewer-share'),
        tooltip: context.l10n.share,
        icon: const Icon(Icons.ios_share_rounded),
        onPressed: () => context.read<AttachmentViewerCubit>().shareLink(origin: _originOf(context)),
      );
}

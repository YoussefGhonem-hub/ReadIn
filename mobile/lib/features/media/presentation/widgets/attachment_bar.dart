import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/media/media_image.dart';
import '../../../../shared/media/media_item.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../domain/entities/media.dart';
import '../cubit/attachments_cubit.dart';

/// Composer attachment bar (SPEC F26): "📷 Images" / "📄 PDF document"
/// actions (mutually exclusive), the reorderable image grid with alt text and
/// captions, or the PDF card with processing status and preview. Reads the
/// [AttachmentsCubit] from context.
class AttachmentBar extends StatelessWidget {
  const AttachmentBar({super.key, this.enabled = true});

  /// False while publishing.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttachmentsCubit, AttachmentsState>(
      listenWhen: (a, b) => b.notice != null && a.noticeSeq != b.noticeSeq,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(localizeFailure(context.l10n, state.notice!)))),
      builder: (context, state) {
        final l10n = context.l10n;
        final cubit = context.read<AttachmentsCubit>();
        final mixHint = (state.document != null) || state.images.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    key: const ValueKey('attach-images'),
                    emoji: '📷',
                    label: l10n.attachImages,
                    onPressed: enabled && state.canAddImages ? cubit.pickImages : null,
                  ),
                ),
                const SizedBox(width: ReadInSpace.s2),
                Expanded(
                  child: _ActionButton(
                    key: const ValueKey('attach-pdf'),
                    emoji: '📄',
                    label: l10n.attachPdf,
                    onPressed: enabled && state.canAddDocument ? cubit.pickPdf : null,
                  ),
                ),
              ],
            ),
            if (mixHint) ...[const SizedBox(height: ReadInSpace.s2), Text(l10n.attachMixHint, style: context.textTheme.bodySmall)],
            if (state.images.isNotEmpty) ...[
              const SizedBox(height: ReadInSpace.s3),
              Row(
                children: [
                  Expanded(child: Text(l10n.attachReorderHint, style: context.textTheme.bodySmall)),
                  const SizedBox(width: ReadInSpace.s2),
                  Text(l10n.attachImagesLimit(state.images.length), style: context.textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: ReadInSpace.s2),
              _ImageGrid(images: state.images, enabled: enabled),
            ],
            if (state.document != null) ...[
              const SizedBox(height: ReadInSpace.s3),
              _DocumentCard(document: state.document!, enabled: enabled),
            ],
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({super.key, required this.emoji, required this.label, required this.onPressed});

  final String emoji;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Text(emoji)),
        const SizedBox(width: ReadInSpace.s2),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

// ── Images ──────────────────────────────────────────────────

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.images, required this.enabled});

  final List<ImageDraft> images;
  final bool enabled;

  static const columns = 3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = ((constraints.maxWidth - ReadInSpace.s2 * (columns - 1)) / columns).floorToDouble();
        return Wrap(
          spacing: ReadInSpace.s2,
          runSpacing: ReadInSpace.s2,
          children: [
            for (final (i, image) in images.indexed)
              SizedBox.square(
                key: ValueKey('image-cell-${image.localId}'),
                dimension: cell,
                child: _ReorderableCell(image: image, index: i, total: images.length, size: cell, enabled: enabled),
              ),
          ],
        );
      },
    );
  }
}

/// Long-press and drag onto another cell to reorder; screen readers get
/// "Move earlier / Move later" custom actions instead.
class _ReorderableCell extends StatelessWidget {
  const _ReorderableCell({required this.image, required this.index, required this.total, required this.size, required this.enabled});

  final ImageDraft image;
  final int index;
  final int total;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AttachmentsCubit>();
    final l10n = context.l10n;
    final tile = _ImageTile(
      image: image,
      index: index,
      enabled: enabled,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
    );
    final label = [
      l10n.imageDetailsTitle(index + 1, total),
      if (!image.hasAltText) l10n.altTextMissing,
      if (image.phase == UploadPhase.uploading) l10n.uploadProgress(progressPercent(image.progress)),
      if (image.phase == UploadPhase.failed) l10n.uploadFailed,
      if (image.phase == UploadPhase.cancelled) l10n.uploadCancelled,
    ].join(l10n.listSeparator);

    final uploading = image.phase == UploadPhase.preparing || image.phase == UploadPhase.uploading;
    return Semantics(
      label: label,
      button: true,
      onTapHint: l10n.editImageDetails,
      customSemanticsActions: !enabled
          ? null
          : {
              if (index > 0) CustomSemanticsAction(label: l10n.moveEarlier): () => cubit.move(image.localId, -1),
              if (index < total - 1) CustomSemanticsAction(label: l10n.moveLater): () => cubit.move(image.localId, 1),
              if (uploading) CustomSemanticsAction(label: l10n.cancelUpload): () => cubit.cancel(image.localId),
              if (image.phase.isProblem) CustomSemanticsAction(label: l10n.retry): () => cubit.retry(image.localId),
              CustomSemanticsAction(label: l10n.removeAttachment): () => cubit.remove(image.localId),
            },
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => enabled && details.data != image.localId,
        onAcceptWithDetails: (details) {
          final from = cubit.state.images.indexWhere((i) => i.localId == details.data);
          if (from >= 0) cubit.reorder(from, index);
        },
        builder: (context, candidates, _) => LongPressDraggable<String>(
          data: image.localId,
          maxSimultaneousDrags: enabled ? 1 : 0,
          hapticFeedbackOnStart: true,
          feedback: Material(
            color: Colors.transparent,
            elevation: 6,
            borderRadius: BorderRadius.circular(ReadInRadius.md),
            child: SizedBox.square(dimension: size, child: tile),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: tile),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : ReadInMotion.fast,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ReadInRadius.md),
              border: Border.all(color: candidates.isNotEmpty ? context.colors.primary : Colors.transparent, width: 2),
            ),
            child: GestureDetector(
              onTap: enabled ? () => showImageDetailsSheet(context, image.localId) : null,
              child: ExcludeSemantics(child: tile),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.image, required this.index, required this.enabled, required this.cacheWidth});

  final ImageDraft image;
  final int index;
  final bool enabled;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<AttachmentsCubit>();
    final asset = image.asset;
    final busy = image.phase.isBusy;

    return ClipRRect(
      borderRadius: BorderRadius.circular(ReadInRadius.md),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (asset != null && asset.variants.isNotEmpty)
            MediaImage(
              sources: [for (final v in asset.variants) ImageSource(width: v.width, height: v.height, url: v.url)],
              blurHash: asset.blurHash,
            )
          else
            Image(
              image: MediaImages.fileProvider(image.file.path, cacheWidth),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (context, _, _) => ColoredBox(color: colors.surfaceVariant),
            ),
          if (busy || image.phase.isProblem) ColoredBox(color: colors.scrim),
          if (busy)
            Center(
              child: SizedBox.square(
                dimension: 36,
                child: CircularProgressIndicator(
                  value: image.phase == UploadPhase.uploading ? image.progress : null,
                  strokeWidth: 3,
                  color: colors.onPrimary,
                  backgroundColor: colors.onPrimary.withValues(alpha: 0.25),
                ),
              ),
            ),
          if (image.phase.isProblem)
            Center(
              child: _RoundIconButton(
                icon: Icons.refresh_rounded,
                tooltip: l10n.retry,
                onPressed: enabled ? () => cubit.retry(image.localId) : null,
              ),
            ),
          PositionedDirectional(
            top: ReadInSpace.s1,
            start: ReadInSpace.s1,
            child: _CornerBadge(text: '${index + 1}'),
          ),
          PositionedDirectional(
            top: ReadInSpace.s1,
            end: ReadInSpace.s1,
            child: _RoundIconButton(
              icon: Icons.close_rounded,
              small: true,
              tooltip: busy && image.phase != UploadPhase.processing ? l10n.cancelUpload : l10n.removeAttachment,
              onPressed: !enabled
                  ? null
                  : busy && image.phase != UploadPhase.processing
                  ? () => cubit.cancel(image.localId)
                  : () => cubit.remove(image.localId),
            ),
          ),
          if (!image.hasAltText)
            PositionedDirectional(
              bottom: ReadInSpace.s1,
              start: ReadInSpace.s1,
              end: ReadInSpace.s1,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: colors.error, borderRadius: BorderRadius.circular(ReadInRadius.chip)),
                  child: Text(
                    l10n.altTextBadgeMissing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(color: colors.onError, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            )
          else
            PositionedDirectional(
              bottom: ReadInSpace.s1,
              start: ReadInSpace.s1,
              child: _CornerBadge(text: l10n.altTextAdded),
            ),
        ],
      ),
    );
  }
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: colors.surface.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(ReadInRadius.chip)),
      child: Text(
        text,
        textDirection: TextDirection.ltr,
        style: context.textTheme.labelSmall?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.tooltip, required this.onPressed, this.small = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = small ? 28.0 : 40.0;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        enabled: onPressed != null,
        excludeSemantics: true,
        child: Material(
          color: colors.surface.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Icon(icon, size: small ? 16 : 22, color: colors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alt text (required), caption (optional), move earlier/later and remove.
Future<void> showImageDetailsSheet(BuildContext context, String localId) {
  final cubit = context.read<AttachmentsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _ImageDetailsSheet(localId: localId),
    ),
  );
}

class _ImageDetailsSheet extends StatefulWidget {
  const _ImageDetailsSheet({required this.localId});

  final String localId;

  @override
  State<_ImageDetailsSheet> createState() => _ImageDetailsSheetState();
}

class _ImageDetailsSheetState extends State<_ImageDetailsSheet> {
  late final ImageDraft _initial = context.read<AttachmentsCubit>().state.images.firstWhere((i) => i.localId == widget.localId);
  late final _alt = TextEditingController(text: _initial.altText);
  late final _caption = TextEditingController(text: _initial.caption);

  @override
  void dispose() {
    _alt.dispose();
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AttachmentsCubit>();
    return BlocBuilder<AttachmentsCubit, AttachmentsState>(
      builder: (context, state) {
        final index = state.images.indexWhere((i) => i.localId == widget.localId);
        if (index < 0) return const SizedBox.shrink();
        final image = state.images[index];
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.imageDetailsTitle(index + 1, state.images.length), style: context.textTheme.titleMedium),
                  const SizedBox(height: ReadInSpace.s3),
                  SizedBox(
                    height: 160,
                    child: _ImageTile(image: image, index: index, enabled: false, cacheWidth: 600),
                  ),
                  const SizedBox(height: ReadInSpace.s4),
                  BidiTextField(
                    controller: _alt,
                    maxLength: AttachmentLimits.maxAltText,
                    counterWithin: AttachmentLimits.counterWithin,
                    minLines: 1,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: l10n.altTextLabel,
                      helperText: l10n.altTextHint,
                      errorText: image.hasAltText ? null : l10n.altTextMissing,
                    ),
                    onChanged: (v) => cubit.setAltText(widget.localId, v),
                  ),
                  const SizedBox(height: ReadInSpace.s2),
                  BidiTextField(
                    controller: _caption,
                    maxLength: AttachmentLimits.maxCaption,
                    counterWithin: AttachmentLimits.counterWithin,
                    minLines: 1,
                    maxLines: 6,
                    decoration: InputDecoration(labelText: l10n.captionLabel),
                    onChanged: (v) => cubit.setCaption(widget.localId, v),
                  ),
                  const SizedBox(height: ReadInSpace.s2),
                  Wrap(
                    spacing: ReadInSpace.s2,
                    runSpacing: ReadInSpace.s2,
                    children: [
                      OutlinedButton.icon(
                        onPressed: index > 0 ? () => cubit.move(widget.localId, -1) : null,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(l10n.moveEarlier),
                      ),
                      OutlinedButton.icon(
                        onPressed: index < state.images.length - 1 ? () => cubit.move(widget.localId, 1) : null,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(l10n.moveLater),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          cubit.remove(widget.localId);
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(l10n.removeAttachment),
                        style: TextButton.styleFrom(foregroundColor: context.colors.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: ReadInSpace.s3),
                  FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.done)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── PDF ─────────────────────────────────────────────────────

class _DocumentCard extends StatefulWidget {
  const _DocumentCard({required this.document, required this.enabled});

  final DocumentDraft document;
  final bool enabled;

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  late final _title = TextEditingController(text: widget.document.title);

  @override
  void didUpdateWidget(_DocumentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.localId != widget.document.localId) _title.text = widget.document.title;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final colors = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<AttachmentsCubit>();
    final uploading = doc.phase == UploadPhase.preparing || doc.phase == UploadPhase.uploading;

    // A Material (not a colored box) so the switch tile's ink stays visible.
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ReadInRadius.card),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ReadInSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(ReadInRadius.sm)),
                  child: const ExcludeSemantics(child: Text('📄', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: ReadInSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Bidi.isolateOppositeRuns(doc.file.name, Directionality.of(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall,
                      ),
                      Text(
                        [
                          if (doc.file.sizeBytes != null) formatFileSize(l10n, doc.file.sizeBytes!),
                          if (doc.pageCount != null) l10n.pdfPageCount(doc.pageCount!),
                        ].join(' · '),
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: uploading ? l10n.cancelUpload : l10n.removeAttachment,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: !widget.enabled
                      ? null
                      : uploading
                      ? () => cubit.cancel(doc.localId)
                      : () => cubit.remove(doc.localId),
                ),
              ],
            ),
            const SizedBox(height: ReadInSpace.s3),
            ..._status(context, doc),
            const SizedBox(height: ReadInSpace.s4),
            BidiTextField(
              controller: _title,
              enabled: widget.enabled,
              maxLength: AttachmentLimits.maxDocumentTitle,
              counterWithin: AttachmentLimits.counterWithin,
              // Long titles wrap, but a title is one line: Enter finishes instead of adding a line break.
              maxLines: 3,
              minLines: 1,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\r\n]'))],
              decoration: InputDecoration(labelText: l10n.pdfTitleLabel, errorText: doc.hasTitle ? null : l10n.attachNeedDocTitle),
              onChanged: cubit.setDocumentTitle,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: doc.allowDownload,
              onChanged: widget.enabled ? cubit.setAllowDownload : null,
              title: Text(l10n.pdfAllowDownload, style: context.textTheme.bodyMedium),
              subtitle: Text(l10n.pdfAllowDownloadHint, style: context.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _status(BuildContext context, DocumentDraft doc) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<AttachmentsCubit>();
    final meta = context.textTheme.bodySmall;
    switch (doc.phase) {
      case UploadPhase.preparing || UploadPhase.uploading:
        return [
          LinearProgressIndicator(value: doc.phase == UploadPhase.uploading ? doc.progress : null, minHeight: 4),
          const SizedBox(height: ReadInSpace.s2),
          Text(doc.phase == UploadPhase.uploading ? l10n.uploadProgress(progressPercent(doc.progress)) : l10n.uploadPreparing, style: meta),
        ];
      case UploadPhase.processing:
        final total = doc.pageCount ?? 0;
        return [
          Row(
            children: [
              const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: ReadInSpace.s2),
              Expanded(
                child: Semantics(liveRegion: true, child: Text(l10n.pdfPreparingPages, style: context.textTheme.labelLarge)),
              ),
              if (total > 0) Text(l10n.pdfPagesReady(doc.pagesReady, total), style: meta),
            ],
          ),
          const SizedBox(height: ReadInSpace.s2),
          LinearProgressIndicator(value: total > 0 ? doc.pagesReady / total : null, minHeight: 4),
          if (doc.pages.isNotEmpty) ...[const SizedBox(height: ReadInSpace.s3), _PagePreview(pages: doc.pages, total: total)],
        ];
      case UploadPhase.ready:
        return [_PagePreview(pages: doc.pages, total: doc.pageCount ?? doc.pages.length)];
      case UploadPhase.failed || UploadPhase.cancelled:
        return [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: colors.error, size: 20),
              const SizedBox(width: ReadInSpace.s2),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    doc.phase == UploadPhase.cancelled
                        ? l10n.uploadCancelled
                        : localizeFailure(l10n, doc.failure ?? const Failure(FailureCodes.mediaProcessingFailed)),
                    style: context.textTheme.bodyMedium?.copyWith(color: colors.error),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ReadInSpace.s2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: widget.enabled ? () => cubit.remove(doc.localId) : null, child: Text(l10n.removeAttachment)),
              const SizedBox(width: ReadInSpace.s2),
              FilledButton.tonal(
                onPressed: widget.enabled ? () => cubit.retry(doc.localId) : null,
                style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ];
    }
  }
}

/// The first rendered pages, as small thumbs.
class _PagePreview extends StatelessWidget {
  const _PagePreview({required this.pages, required this.total});

  final List<MediaPage> pages;
  final int total;

  static const maxPages = 5;
  static const height = 104.0;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final shown = pages.take(maxPages).toList();
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shown.length,
        separatorBuilder: (_, _) => const SizedBox(width: ReadInSpace.s2),
        itemBuilder: (context, i) {
          final page = shown[i];
          return Semantics(
            label: context.l10n.viewerPageOf(page.pageNo, total),
            image: true,
            excludeSemantics: true,
            child: Container(
              width: height * page.aspectRatio,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ReadInRadius.sm),
                border: Border.all(color: colors.border),
              ),
              child: MediaImage(
                sources: [
                  ImageSource(width: MediaPage.thumbWidth, height: (MediaPage.thumbWidth / page.aspectRatio).round(), url: page.thumbUrl),
                ],
                blurHash: page.blurHash,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// "2.4 MB" / "2.4 ميجا" with Western digits.
String formatFileSize(AppLocalizations l10n, int bytes) {
  if (bytes >= 1024 * 1024) return l10n.fileSizeMb((bytes / (1024 * 1024)).toStringAsFixed(1));
  return l10n.fileSizeKb((bytes / 1024).ceil().toString());
}

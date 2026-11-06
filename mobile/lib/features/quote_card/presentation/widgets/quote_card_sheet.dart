import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/highlights/rdoc_highlight_text.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/quote_card.dart';
import '../cubit/quote_card_cubit.dart';

/// What a refused or failed card says (the F24 contract's table, the same texts as web), and whether it offers "Try
/// again". Nothing for a cancelled request. Other API codes (e.g. `403 user.suspended`) keep their usual message.
({String message, bool retry})? describeQuoteCardFailure(AppLocalizations l10n, Failure failure) => switch (failure.code) {
      FailureCodes.requestCancelled => null,
      // A malformed body is a client bug: the generic message.
      FailureCodes.validationFailed => (message: l10n.errServer, retry: false),
      FailureCodes.articleNotFound => (message: l10n.errQuoteCardNotFound, retry: false),
      FailureCodes.quoteHidden => (message: l10n.errQuoteCardHidden, retry: false),
      FailureCodes.quoteTextMismatch => (message: l10n.errQuoteCardTextMismatch, retry: false),
      FailureCodes.quoteBlockNotAllowed => (message: l10n.errQuoteCardBlockNotAllowed, retry: false),
      FailureCodes.quoteTooShort => (message: l10n.errQuoteCardTooShort, retry: false),
      FailureCodes.quoteTooLong => (message: l10n.errQuoteCardTooLong, retry: false),
      FailureCodes.quoteLimit => (message: l10n.errQuoteCardLimit, retry: true),
      FailureCodes.quoteBusy => (message: l10n.errQuoteCardBusy, retry: true),
      FailureCodes.networkOffline => (message: l10n.errQuoteCardOffline, retry: true),
      FailureCodes.quoteFailed || FailureCodes.serverError || FailureCodes.networkTimeout =>
        (message: l10n.errQuoteCardFailed, retry: true),
      _ => switch (localizeFailure(l10n, failure)) {
          // A code the app has no message for is "any other failure" in the contract.
          final usual when usual == l10n.errServer => (message: l10n.errQuoteCardFailed, retry: true),
          final usual => (message: usual, retry: false),
        },
    };

/// The quote card sheet for [range] of [article] (the version on screen). It starts on the app's theme, square.
/// [onTextChanged] runs when the API says the text changed meanwhile (`quote.text_mismatch`): the reader loads the
/// article again.
Future<void> showQuoteCardSheet(
  BuildContext context, {
  required ArticleCard article,
  required HighlightRange range,
  VoidCallback? onTextChanged,
}) {
  final theme = Theme.of(context).brightness == Brightness.dark ? QuoteCardTheme.dark : QuoteCardTheme.light;
  final source = QuoteCardSource(
    articleId: article.id,
    language: article.language,
    slug: article.slug,
    title: article.title,
    range: range,
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => BlocProvider(
      create: (_) => getIt<QuoteCardCubit>()..open(source, theme: theme),
      child: QuoteCardSheet(onTextChanged: onTextChanged),
    ),
  );
}

/// The sheet's content, under a [QuoteCardCubit]: the preview, the theme and format switches, Share, Save and Copy link.
class QuoteCardSheet extends StatelessWidget {
  const QuoteCardSheet({super.key, this.onTextChanged});

  final VoidCallback? onTextChanged;

  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<QuoteCardCubit>();
    return BlocListener<QuoteCardCubit, QuoteCardState>(
      // The article changed under the selection: the reader loads it again (the sheet says so).
      listenWhen: (a, b) =>
          b.current?.failure?.code == FailureCodes.quoteTextMismatch && a.current?.failure?.code != FailureCodes.quoteTextMismatch,
      listener: (_, _) => onTextChanged?.call(),
      child: BlocBuilder<QuoteCardCubit, QuoteCardState>(
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text(l10n.quoteCardTitle, style: context.textTheme.titleLarge)),
              const SizedBox(height: ReadInSpace.s1),
              Text(l10n.quoteCardHint, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
              const SizedBox(height: ReadInSpace.s4),
              QuoteCardPreview(state: state, quote: cubit.source?.range.text ?? '', onRetry: () => unawaited(cubit.retry())),
              const SizedBox(height: ReadInSpace.s4),
              Semantics(
                container: true,
                label: l10n.quoteCardThemeLabel,
                child: SegmentedButton<QuoteCardTheme>(
                  key: const ValueKey('quote-card-theme'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: QuoteCardTheme.light, label: Text(l10n.themeLight), icon: const Icon(Icons.light_mode_outlined)),
                    ButtonSegment(value: QuoteCardTheme.dark, label: Text(l10n.themeDark), icon: const Icon(Icons.dark_mode_outlined)),
                  ],
                  selected: {state.theme},
                  onSelectionChanged: (v) => unawaited(cubit.setTheme(v.first)),
                ),
              ),
              const SizedBox(height: ReadInSpace.s3),
              Semantics(
                container: true,
                label: l10n.quoteCardFormatLabel,
                child: SegmentedButton<QuoteCardFormat>(
                  key: const ValueKey('quote-card-format'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: QuoteCardFormat.square, label: Text(l10n.quoteCardSquare), icon: const Icon(Icons.crop_square)),
                    ButtonSegment(
                      value: QuoteCardFormat.landscape,
                      label: Text(l10n.quoteCardLandscape),
                      icon: const Icon(Icons.crop_landscape),
                    ),
                  ],
                  selected: {state.format},
                  onSelectionChanged: (v) => unawaited(cubit.setFormat(v.first)),
                ),
              ),
              const SizedBox(height: ReadInSpace.s5),
              Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (button) => FilledButton.icon(
                        key: const ValueKey('quote-card-share'),
                        onPressed: state.canExport ? () => unawaited(cubit.share(origin: _originOf(button))) : null,
                        icon: _ButtonIcon(busy: state.sharing, icon: Icons.ios_share_rounded),
                        label: Text(l10n.quoteCardShare),
                      ),
                    ),
                  ),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('quote-card-save'),
                      onPressed: state.canExport ? () => unawaited(cubit.save()) : null,
                      icon: _ButtonIcon(busy: state.saving, icon: Icons.download_rounded),
                      label: Text(l10n.quoteCardSave),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ReadInSpace.s2),
              // The article's link, as on web; it doesn't wait for the card.
              TextButton.icon(
                key: const ValueKey('quote-card-copy-link'),
                onPressed: () => unawaited(cubit.copyLink()),
                icon: const Icon(Icons.link_rounded, size: 18),
                label: Text(l10n.quoteCardCopyLink),
              ),
              if (state.notice case final notice?) ...[
                const SizedBox(height: ReadInSpace.s2),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    switch (notice) {
                      QuoteCardNotice.saved => l10n.quoteCardSaved,
                      QuoteCardNotice.saveFailed => l10n.quoteCardSaveFailed,
                      QuoteCardNotice.shareFailed => l10n.quoteCardShareFailed,
                      QuoteCardNotice.linkCopied => l10n.quoteCardLinkCopied,
                      QuoteCardNotice.copyFailed => l10n.quoteCardCopyFailed,
                    },
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: notice == QuoteCardNotice.saved || notice == QuoteCardNotice.linkCopied ? colors.success : colors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ButtonIcon extends StatelessWidget {
  const _ButtonIcon({required this.busy, required this.icon});

  final bool busy;
  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, size: 18);
}

/// The card of the chosen look in a box of its shape: the picture, a spinner while the API draws it, or why it failed
/// (with "Try again" when it can help). It never grows past about 40% of the screen's height.
class QuoteCardPreview extends StatelessWidget {
  const QuoteCardPreview({super.key, required this.state, required this.quote, required this.onRetry});

  final QuoteCardState state;

  /// The quoted text, for the picture's screen-reader label.
  final String quote;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final slot = state.current;
    final ratio = state.format.aspectRatio;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.4;
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = constraints.maxWidth;
        var height = width / ratio;
        if (height > maxHeight) {
          height = maxHeight;
          width = height * ratio;
        }
        final failure = slot?.status == QuoteCardSlotStatus.failed ? slot!.failure : null;
        final described = failure == null ? null : describeQuoteCardFailure(l10n, failure);
        final image = slot?.image;
        final Widget content;
        if (image != null) {
          content = Image.memory(
            image.bytes,
            key: ValueKey('quote-card-image-${state.theme.name}-${state.format.name}'),
            width: width,
            height: height,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            // What the picture says, as the web's alt: "Quote card: {quote}".
            semanticLabel: l10n.quoteCardPreview(quote),
            errorBuilder: (context, _, _) => _PreviewMessage(
              message: l10n.errQuoteCardFailed,
              offline: false,
              onRetry: null,
              minHeight: height,
            ),
          );
        } else if (described != null) {
          content = _PreviewMessage(
            message: described.message,
            offline: failure!.code == FailureCodes.networkOffline,
            onRetry: described.retry ? onRetry : null,
            minHeight: height,
          );
        } else {
          content = SizedBox(
            width: width,
            height: height,
            child: Semantics(
              liveRegion: true,
              label: l10n.quoteCardPreparing,
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final radius = BorderRadius.circular(ReadInRadius.md);
        return Center(
          child: Container(
            key: const ValueKey('quote-card-preview'),
            width: width,
            constraints: BoxConstraints(minHeight: height),
            decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: radius),
            // The outline on top, so the card keeps its exact shape.
            foregroundDecoration: BoxDecoration(borderRadius: radius, border: Border.all(color: colors.border)),
            clipBehavior: Clip.antiAlias,
            child: content,
          ),
        );
      },
    );
  }
}

class _PreviewMessage extends StatelessWidget {
  const _PreviewMessage({required this.message, required this.offline, required this.onRetry, required this.minHeight});

  final String message;
  final bool offline;
  final VoidCallback? onRetry;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final retry = onRetry;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.all(ReadInSpace.s4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded, color: colors.textSecondary),
            const SizedBox(height: ReadInSpace.s2),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
              ),
            ),
            if (retry != null) ...[
              const SizedBox(height: ReadInSpace.s2),
              TextButton.icon(
                key: const ValueKey('quote-card-retry'),
                onPressed: retry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.l10n.quoteCardRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

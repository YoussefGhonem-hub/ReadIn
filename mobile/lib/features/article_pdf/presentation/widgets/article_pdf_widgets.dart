import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../cubit/article_pdf_cubit.dart';

/// What a failed "Download PDF" says (the F33 contract's error table, the same texts as web), and whether it offers "Try
/// again". Nothing for a cancelled request. Other API codes (e.g. `403 user.suspended`, or another limiter's
/// `429 rate_limited`) keep their usual message, without "Try again".
({String message, bool retry})? describePdfFailure(AppLocalizations l10n, Failure failure) => switch (failure.code) {
      FailureCodes.requestCancelled => null,
      FailureCodes.articleNotFound => (message: l10n.errArticlePdfNotFound, retry: false),
      FailureCodes.articlePdfHidden => (message: l10n.errArticlePdfHidden, retry: false),
      FailureCodes.articlePdfLimit => (message: l10n.errArticlePdfLimit, retry: true),
      FailureCodes.articlePdfBusy => (message: l10n.errArticlePdfBusy, retry: true),
      FailureCodes.networkOffline => (message: l10n.errArticlePdfOffline, retry: true),
      FailureCodes.articlePdfFailed || FailureCodes.serverError || FailureCodes.networkTimeout =>
        (message: l10n.errArticlePdfFailed, retry: true),
      _ => switch (localizeFailure(l10n, failure)) {
          // A code the app has no message for is "any other failure" in the contract.
          final usual when usual == l10n.errServer => (message: l10n.errArticlePdfFailed, retry: true),
          final usual => (message: usual, retry: false),
        },
    };

/// Shows each failed "Download PDF" of the [ArticlePdfCubit] above once, with "Try again" when it can help.
class ArticlePdfFeedback extends StatelessWidget {
  const ArticlePdfFeedback({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<ArticlePdfCubit, ArticlePdfState>(
        listenWhen: (a, b) => a.failureSeq != b.failureSeq && b.failure != null,
        listener: (context, state) {
          final l10n = context.l10n;
          final shown = describePdfFailure(l10n, state.failure!);
          if (shown == null) return;
          final cubit = context.read<ArticlePdfCubit>();
          showActionMessage(
            context,
            shown.message,
            action: shown.retry ? SnackBarAction(label: l10n.pdfRetry, onPressed: cubit.retry) : null,
          );
        },
        child: child,
      );
}

/// "Download PDF" for one article from [context]'s [ArticlePdfCubit]: with two published versions ([languages], the
/// source language first) it asks which one first; with one it goes straight on. The share sheet is anchored on
/// [context]'s widget (iPad).
Future<void> downloadArticlePdf(BuildContext context, {required String articleId, required List<String> languages}) async {
  if (languages.isEmpty) return;
  final cubit = context.read<ArticlePdfCubit>();
  if (cubit.state.isBuilding(articleId)) return;
  final origin = _originOf(context);
  final language = languages.length == 1 ? languages.single : await showPdfLanguageSheet(context, languages);
  if (language == null) return;
  await cubit.download(articleId, language: language, origin: origin);
}

Rect? _originOf(BuildContext context) {
  final box = context.findRenderObject();
  return box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
}

/// "Which version?": the article's published languages in the order given; null when dismissed.
Future<String?> showPdfLanguageSheet(BuildContext context, List<String> languages) => showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => PdfLanguageSheet(languages: languages),
    );

class PdfLanguageSheet extends StatelessWidget {
  const PdfLanguageSheet({super.key, required this.languages});

  final List<String> languages;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.pdfLanguageTitle, style: context.textTheme.titleLarge)),
          const SizedBox(height: ReadInSpace.s3),
          Text(l10n.pdfLanguageBody, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: ReadInSpace.s5),
          for (final (i, language) in languages.indexed) ...[
            if (i > 0) const SizedBox(height: ReadInSpace.s3),
            OutlinedButton.icon(
              key: ValueKey('pdf-language-$language'),
              onPressed: () => Navigator.of(context).pop(language),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(language == 'en' ? l10n.articleVersionEnglish : l10n.articleVersionArabic),
            ),
          ],
        ],
      ),
    );
  }
}

/// "تحميل PDF" / "Download PDF"; while [building], "بنجهز الـ PDF…" with a spinner, disabled.
class ArticlePdfButton extends StatelessWidget {
  const ArticlePdfButton({super.key, required this.building, required this.onPressed});

  final bool building;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextButton.icon(
      onPressed: building ? null : onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2),
      ),
      icon: building
          ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
      label: Text(building ? l10n.pdfPreparing : l10n.pdfDownload),
    );
  }
}

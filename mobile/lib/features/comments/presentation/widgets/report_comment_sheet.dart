import 'package:flutter/material.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../domain/entities/comment.dart';
import '../../domain/usecases/comment_usecases.dart';

/// Sends a report; null on success.
typedef SubmitReport = Future<Failure?> Function(ReportReason reason, String? details);

/// "Report comment" (F11, stored for the F22 queue): a reason and optional details (≤ 500). True once sent.
Future<bool> showReportCommentSheet(BuildContext context, {required SubmitReport onSubmit}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: ReportCommentView(onSubmit: onSubmit),
    ),
  );
  return sent ?? false;
}

class ReportCommentView extends StatefulWidget {
  const ReportCommentView({super.key, required this.onSubmit});

  final SubmitReport onSubmit;

  @override
  State<ReportCommentView> createState() => _ReportCommentViewState();
}

class _ReportCommentViewState extends State<ReportCommentView> {
  final _details = TextEditingController();
  ReportReason? _reason;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await widget.onSubmit(reason, _details.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = localizeCommentFailure(context.l10n, failure);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    String label(ReportReason reason) => switch (reason) {
          ReportReason.spam => l10n.commentsReportSpam,
          ReportReason.misinformation => l10n.commentsReportMisinformation,
          ReportReason.harassment => l10n.commentsReportHarassment,
          ReportReason.copyright => l10n.commentsReportCopyright,
          ReportReason.other => l10n.commentsReportOther,
        };
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.commentsReportTitle, style: context.textTheme.titleLarge)),
          const SizedBox(height: ReadInSpace.s2),
          Text(l10n.commentsReportBody, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: ReadInSpace.s3),
          RadioGroup<ReportReason>(
            groupValue: _reason,
            onChanged: (reason) {
              if (!_busy) setState(() => _reason = reason);
            },
            child: Column(
              children: [
                for (final reason in ReportReason.values)
                  RadioListTile<ReportReason>(value: reason, title: Text(label(reason)), contentPadding: EdgeInsets.zero),
              ],
            ),
          ),
          const SizedBox(height: ReadInSpace.s2),
          BidiTextField(
            controller: _details,
            enabled: !_busy,
            minLines: 2,
            maxLines: 4,
            maxLength: ReportComment.maxDetailsLength,
            counterWithin: 100,
            decoration: InputDecoration(labelText: l10n.commentsReportDetails, errorText: _error),
          ),
          const SizedBox(height: ReadInSpace.s4),
          FilledButton(
            onPressed: _reason == null || _busy ? null : _submit,
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.commentsReportSubmit),
          ),
        ],
      ),
    );
  }
}

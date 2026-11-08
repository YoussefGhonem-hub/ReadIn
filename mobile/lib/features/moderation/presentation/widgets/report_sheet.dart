import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../../blocks/presentation/cubit/blocks_cubit.dart';
import '../../../blocks/presentation/widgets/block_actions.dart';
import '../../domain/entities/moderation.dart';
import '../../domain/usecases/moderation_usecases.dart';
import '../cubit/report_cubit.dart';
import '../cubit/reported_content_cubit.dart';
import 'moderation_labels.dart';

/// Who wrote what is reported (the article's or comment's author, the reposter, or the user): the sheet's «حظر
/// @username أيضًا» checkbox blocks them in the same step (F36).
class ReportAuthor {
  const ReportAuthor(this.id, this.username);

  final String id;
  final String username;
}

/// The report sheet (F22), one for articles, comments, users and reposts: a reason, optional details (≤ 500), «حظر
/// @username أيضًا» when [author] is someone else (off by default, F36) and Send. Guests get the sign-in prompt
/// instead. Says "Thanks, we'll review it" once sent; true then. The reported article, comment or repost collapses for
/// the viewer at once ([ReportedContentCubit]), and a block made with it applies at once too ([BlocksCubit]).
Future<bool> showReportSheet(
  BuildContext context, {
  required ModerationTargetRef target,
  ReportCubit Function()? cubit,
  ReportAuthor? author,
}) async {
  if (!requireAccount(context)) return false;
  final myId = context.read<SessionCubit?>()?.state.me?.id;
  final blockable = author != null && author.id != myId ? author : null;
  final reported = context.read<ReportedContentCubit?>();
  final blocks = context.read<BlocksCubit?>();
  final result = await showModalBottomSheet<ReportSent>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => cubit?.call() ?? getIt<ReportCubit>(),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: ReportSheetView(target: target, author: blockable),
      ),
    ),
  );
  if (result == null) return false;
  reported?.markReported(target);
  if (result.alsoBlocked && blockable != null) blocks?.markBlocked(blockable.id);
  if (context.mounted) {
    showActionMessage(
      context,
      result.alsoBlocked && blockable != null
          ? context.l10n.reportThanksBlocked(BlockActions.handle(blockable.username))
          : context.l10n.reportThanks,
    );
  }
  return true;
}

/// How the sheet closed once its report was sent: with the author blocked too, or not.
class ReportSent {
  const ReportSent({this.alsoBlocked = false});

  final bool alsoBlocked;
}

/// The sheet's content once a [ReportCubit] is provided; pops a [ReportSent] when the report is sent.
class ReportSheetView extends StatefulWidget {
  const ReportSheetView({super.key, required this.target, this.author});

  final ModerationTargetRef target;

  /// Someone else who wrote it: «حظر @username أيضًا».
  final ReportAuthor? author;

  @override
  State<ReportSheetView> createState() => _ReportSheetViewState();
}

class _ReportSheetViewState extends State<ReportSheetView> {
  final _details = TextEditingController();
  bool _alsoBlock = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return BlocConsumer<ReportCubit, ReportState>(
      listenWhen: (a, b) => !a.sent && b.sent,
      listener: (context, _) => Navigator.of(context).pop(ReportSent(alsoBlocked: _alsoBlock)),
      builder: (context, state) {
        final cubit = context.read<ReportCubit>();
        final failure = state.failure;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text(l10n.reportTitle(widget.target.type), style: context.textTheme.titleLarge)),
              const SizedBox(height: ReadInSpace.s2),
              Text(l10n.reportBody, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
              const SizedBox(height: ReadInSpace.s3),
              RadioGroup<ReportReason>(
                groupValue: state.reason,
                onChanged: (reason) {
                  if (reason != null) cubit.choose(reason);
                },
                child: Column(
                  children: [
                    for (final reason in ReportReason.values)
                      RadioListTile<ReportReason>(
                        value: reason,
                        enabled: !state.sending,
                        title: Text(l10n.reportReason(reason)),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: ReadInSpace.s2),
              BidiTextField(
                controller: _details,
                enabled: !state.sending,
                minLines: 2,
                maxLines: 4,
                maxLength: SubmitReport.maxDetailsLength,
                decoration: InputDecoration(
                  labelText: l10n.reportDetails,
                  errorText: failure == null ? null : localizeActionFailure(l10n, failure),
                  errorMaxLines: 3,
                ),
              ),
              if (widget.author case final author?)
                CheckboxListTile(
                  key: const ValueKey('report-also-block'),
                  value: _alsoBlock,
                  onChanged: state.sending ? null : (on) => setState(() => _alsoBlock = on ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.reportAlsoBlock(BlockActions.handle(author.username))),
                  subtitle: Text(l10n.reportAlsoBlockHint, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                ),
              const SizedBox(height: ReadInSpace.s4),
              FilledButton(
                onPressed: state.canSend ? () => cubit.send(widget.target, details: _details.text, alsoBlock: _alsoBlock) : null,
                child: state.sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.reportSubmit),
              ),
            ],
          ),
        );
      },
    );
  }
}

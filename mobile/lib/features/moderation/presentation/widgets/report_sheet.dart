import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../domain/entities/moderation.dart';
import '../../domain/usecases/moderation_usecases.dart';
import '../cubit/report_cubit.dart';
import 'moderation_labels.dart';

/// The report sheet (F22), one for articles, comments and users: a reason, optional details (≤ 500) and Send. Guests
/// get the sign-in prompt instead. Says "Thanks, we'll review it" once sent; true then.
Future<bool> showReportSheet(BuildContext context, {required ModerationTargetRef target, ReportCubit Function()? cubit}) async {
  if (!requireAccount(context)) return false;
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => cubit?.call() ?? getIt<ReportCubit>(),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: ReportSheetView(target: target),
      ),
    ),
  );
  if (sent != true) return false;
  if (context.mounted) showActionMessage(context, context.l10n.reportThanks);
  return true;
}

/// The sheet's content once a [ReportCubit] is provided; pops `true` when the report is sent.
class ReportSheetView extends StatefulWidget {
  const ReportSheetView({super.key, required this.target});

  final ModerationTargetRef target;

  @override
  State<ReportSheetView> createState() => _ReportSheetViewState();
}

class _ReportSheetViewState extends State<ReportSheetView> {
  final _details = TextEditingController();

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
      listener: (context, _) => Navigator.of(context).pop(true),
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
              const SizedBox(height: ReadInSpace.s4),
              FilledButton(
                onPressed: state.canSend ? () => cubit.send(widget.target, details: _details.text) : null,
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

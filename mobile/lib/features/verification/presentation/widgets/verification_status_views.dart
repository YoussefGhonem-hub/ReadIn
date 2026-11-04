import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../domain/entities/verification.dart';
import '../cubit/verification_cubit.dart';

/// I'm a verified writer.
class VerificationApprovedView extends StatelessWidget {
  const VerificationApprovedView({super.key, required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final request = status.request;
    final decidedAt = request?.decidedAt;
    return _StatusList(
      children: [
        _StatusHeader(
          icon: Icons.verified_rounded,
          background: colors.calloutTip,
          foreground: colors.success,
          title: l10n.verificationApprovedTitle,
          body: l10n.verificationApprovedBody,
          date: decidedAt == null ? null : l10n.verificationApprovedOn(_date(context, decidedAt)),
        ),
        if (request != null) ...[
          const SizedBox(height: ReadInSpace.s5),
          VerificationRequestSummary(request: request),
        ],
      ],
    );
  }
}

/// My request waits for a review: when it was sent, what it says, and "Withdraw" (confirmed first).
class VerificationPendingView extends StatelessWidget {
  const VerificationPendingView({super.key, required this.request, this.withdrawing = false});

  final VerificationRequest request;
  final bool withdrawing;

  static const withdrawKey = ValueKey('verification-withdraw');

  Future<void> _withdraw(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<VerificationCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.verificationWithdrawTitle),
        content: Text(l10n.verificationWithdrawBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            key: const ValueKey('verification-withdraw-confirm'),
            style: FilledButton.styleFrom(backgroundColor: dialog.colors.error, foregroundColor: dialog.colors.onError),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.verificationWithdrawConfirm),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    final failure = await cubit.withdraw();
    if (!context.mounted) return;
    if (failure == null) {
      showActionMessage(context, l10n.verificationWithdrawn);
    } else {
      showActionFailure(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return _StatusList(
      children: [
        _StatusHeader(
          icon: Icons.hourglass_top_rounded,
          background: colors.calloutInfo,
          foreground: colors.calloutInfoAccent,
          title: l10n.verificationPendingTitle,
          body: l10n.verificationPendingBody,
          date: l10n.verificationSubmittedOn(_date(context, request.submittedAt)),
        ),
        const SizedBox(height: ReadInSpace.s5),
        VerificationRequestSummary(request: request),
        const SizedBox(height: ReadInSpace.s5),
        OutlinedButton.icon(
          key: withdrawKey,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.error,
            side: BorderSide(color: colors.error.withValues(alpha: 0.6)),
            minimumSize: const Size.fromHeight(48),
          ),
          icon: withdrawing
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.error))
              : const Icon(Icons.undo_rounded, size: 20),
          label: Text(l10n.verificationWithdraw),
          onPressed: withdrawing ? null : () => unawaited(_withdraw(context)),
        ),
      ],
    );
  }
}

/// My latest request wasn't approved: the reviewer's reason, what I sent, and "Request again" when I may.
class VerificationRejectedView extends StatelessWidget {
  const VerificationRejectedView({super.key, required this.request, required this.canRequest});

  final VerificationRequest request;
  final bool canRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final decidedAt = request.decidedAt;
    final reason = request.rejectionReason?.trim() ?? '';
    return _StatusList(
      children: [
        _StatusHeader(
          icon: Icons.unpublished_outlined,
          background: colors.calloutWarning,
          foreground: colors.calloutWarningAccent,
          title: l10n.verificationRejectedTitle,
          body: canRequest ? l10n.verificationRejectedBody : null,
          date: decidedAt == null ? null : l10n.verificationRejectedOn(_date(context, decidedAt)),
        ),
        if (reason.isNotEmpty) ...[
          const SizedBox(height: ReadInSpace.s5),
          _Reason(reason: reason),
        ],
        const SizedBox(height: ReadInSpace.s4),
        VerificationRequestSummary(request: request),
        if (canRequest) ...[
          const SizedBox(height: ReadInSpace.s5),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(l10n.verificationRequestAgain),
            onPressed: context.read<VerificationCubit>().requestAgain,
          ),
        ],
      ],
    );
  }
}

/// The reviewer's reason, in its own direction, set off like a callout.
class _Reason extends StatelessWidget {
  const _Reason({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(ReadInSpace.s4),
        decoration: BoxDecoration(
          color: colors.calloutWarning,
          borderRadius: BorderRadius.circular(ReadInRadius.md),
          border: BorderDirectional(start: BorderSide(color: colors.calloutWarningAccent, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.verificationRejectedReason,
              style: context.textTheme.labelLarge?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: ReadInSpace.s1),
            Directionality(
              textDirection: Bidi.detect(reason) ?? Directionality.of(context),
              child: BidiText(reason, style: context.textTheme.bodyMedium?.copyWith(height: 1.6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// What a request says: field, job title, link and file in the UI's direction (an opposite-direction run, e.g. a link
/// in Arabic, is isolated), and the note in its own direction, like a comment.
class VerificationRequestSummary extends StatelessWidget {
  const VerificationRequestSummary({super.key, required this.request});

  final VerificationRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final note = request.note?.trim() ?? '';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4, vertical: ReadInSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryRow(icon: Icons.category_outlined, label: l10n.verificationFieldLabel, value: request.field.name),
            _SummaryRow(icon: Icons.work_outline_rounded, label: l10n.verificationJobTitleLabel, value: request.jobTitle),
            if (request.proofUrl case final url?)
              _SummaryRow(icon: Icons.link_rounded, label: l10n.verificationLinkLabel, value: url),
            if (request.proofFileName case final name?)
              _SummaryRow(icon: Icons.attach_file_rounded, label: l10n.verificationFileLabel, value: name),
            if (note.isNotEmpty)
              _SummaryRow(icon: Icons.notes_rounded, label: l10n.verificationNoteSummaryLabel, value: note, ownDirection: true),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.value, this.ownDirection = false});

  final IconData icon;
  final String label;
  final String value;

  /// Free text (the note): laid out in the direction of its first strong character.
  final bool ownDirection;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = BidiText(value, style: context.textTheme.bodyMedium);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.textSecondary),
          const SizedBox(width: ReadInSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary)),
                const SizedBox(height: 2),
                if (ownDirection)
                  Directionality(
                    textDirection: Bidi.detect(value) ?? Directionality.of(context),
                    child: SizedBox(width: double.infinity, child: text),
                  )
                else
                  text,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The big icon, the title, a sentence and a date of a status.
class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    this.body,
    this.date,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String? body;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(ReadInSpace.s4),
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 36, color: foreground),
        ),
        const SizedBox(height: ReadInSpace.s4),
        Semantics(
          header: true,
          child: Text(title, style: context.textTheme.titleLarge, textAlign: TextAlign.center),
        ),
        if (body != null) ...[
          const SizedBox(height: ReadInSpace.s2),
          Text(body!, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary), textAlign: TextAlign.center),
        ],
        if (date != null) ...[
          const SizedBox(height: ReadInSpace.s2),
          Text(date!, style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary), textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _StatusList extends StatelessWidget {
  const _StatusList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s6, ReadInSpace.s5, ReadInSpace.s6),
        children: children,
      );
}

String _date(BuildContext context, DateTime date) => formatDate(date, Localizations.localeOf(context).languageCode);

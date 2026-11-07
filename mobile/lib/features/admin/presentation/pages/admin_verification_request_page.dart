import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/platform/file_save_service.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/utils/link_opener.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/domain/entities/article.dart' show Author;
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../moderation/presentation/widgets/moderation_labels.dart' show embedContent;
import '../../../moderation/presentation/widgets/moderation_widgets.dart' show ModerationUserRow;
import '../../../profile/presentation/profile_routes.dart';
import '../../../profile/presentation/widgets/profile_header.dart' show ProfileBioText;
import '../../domain/entities/admin_verification.dart';
import '../admin_routes.dart';
import '../cubit/admin_user_cubit.dart' show AdminPageStatus;
import '../cubit/verification_review_cubits.dart';
import '../widgets/admin_widgets.dart';
import 'admin_verification_page.dart' show VerificationStatusTag;

/// One verification request in the console (`/admin/verification/{id}`, F19): who asked, the field, the job title,
/// the proof (a link, a private file to save), the note; approve, or reject with a reason; remove the badge later.
class AdminVerificationRequestPage extends StatelessWidget {
  const AdminVerificationRequestPage({super.key, required this.requestId, this.cubit});

  final String requestId;

  /// Test seam; the app takes the cubit from DI.
  final VerificationRequestCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final allowed = context.select((SessionCubit c) => c.state.me?.canManageVerification ?? false);
    if (!allowed) return AdminNoAccessPage(title: context.l10n.adminSectionVerification);
    return BlocProvider(
      create: (_) => (cubit ?? getIt<VerificationRequestCubit>(param1: requestId))..load(),
      child: const AdminVerificationRequestView(),
    );
  }
}

class AdminVerificationRequestView extends StatelessWidget {
  const AdminVerificationRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<VerificationRequestCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminVerificationRequestTitle)),
      body: BlocBuilder<VerificationRequestCubit, VerificationRequestState>(
        builder: (context, state) => switch (state.status) {
          AdminPageStatus.loading => const Center(child: CircularProgressIndicator()),
          AdminPageStatus.failure => ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.load())),
          AdminPageStatus.ready => _Body(request: state.request!, busy: state.busy),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.request, required this.busy});

  final AdminVerificationRequest request;
  final VerificationReviewCommand? busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final user = request.user;
    final canReadUsers = context.select((SessionCubit c) => c.state.me?.can(Permissions.usersRead) ?? false);
    final secondary = context.textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final proofUrl = request.proofUrl;
    final proof = request.proof;
    final decided = request.decidedAt;
    return ListView(
      padding: const EdgeInsets.only(bottom: ReadInSpace.s6),
      children: [
        PageBlock(
          margin: const EdgeInsets.only(top: PageBlock.gap),
          padding: const EdgeInsets.all(PageBlock.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ModerationUserRow(
                user: Author(
                  id: user.id,
                  displayName: user.displayName,
                  username: user.username,
                  avatarUrl: user.avatarUrl,
                  isVerified: user.isVerified,
                  headline: user.headline,
                ),
                avatarSize: 40,
                trailing: VerificationStatusTag(status: request.status),
              ),
              if (user.headline case final headline? when headline.isNotEmpty) ...[
                const SizedBox(height: ReadInSpace.s2),
                ProfileBioText(headline, style: secondary),
              ],
              const SizedBox(height: ReadInSpace.s2),
              Wrap(
                spacing: ReadInSpace.s2,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.person_outline_rounded, size: 18),
                    label: Text(l10n.adminOpenProfile),
                    onPressed: () => unawaited(context.push<void>(ProfileRoutes.of(user.username))),
                  ),
                  if (canReadUsers)
                    TextButton.icon(
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                      label: Text(l10n.adminOpenInConsole),
                      onPressed: () => unawaited(context.push<void>(AdminRoutes.user(user.id))),
                    ),
                ],
              ),
            ],
          ),
        ),
        PageBlock(
          margin: const EdgeInsets.only(top: PageBlock.gap),
          padding: const EdgeInsets.all(PageBlock.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminInfoRow(label: l10n.adminVerificationField, value: request.field.name),
              AdminInfoRow(label: l10n.adminVerificationJobTitle, value: request.jobTitle),
              AdminInfoRow(label: l10n.adminVerificationSubmittedLabel, value: adminDateTime(context, request.submittedAt)),
              if (decided != null) AdminInfoRow(label: l10n.adminVerificationDecidedLabel, value: adminDateTime(context, decided)),
              if (request.decidedBy case final by?) AdminInfoRow(label: l10n.adminVerificationDecidedBy, value: '@$by', ltr: true),
              if (proofUrl != null) ...[
                const SizedBox(height: ReadInSpace.s2),
                Text(l10n.adminVerificationProofLink, style: context.textTheme.labelLarge),
                InkWell(
                  onTap: () => unawaited(openExternalLink(proofUrl)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s1),
                    child: Text(
                      proofUrl,
                      textDirection: TextDirection.ltr,
                      style: context.textTheme.bodyMedium?.copyWith(color: colors.link, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
              if (proof != null) ...[
                const SizedBox(height: ReadInSpace.s2),
                OutlinedButton.icon(
                  key: const ValueKey('verification-proof'),
                  icon: busy == VerificationReviewCommand.proof
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download_rounded),
                  label: Text(l10n.adminVerificationSaveProof(embedContent(proof.fileName))),
                  onPressed: busy != null ? null : () => unawaited(_saveProof(context, proof)),
                ),
              ] else if (request.isPending && proofUrl == null)
                Text(l10n.adminVerificationNoProof, style: secondary),
              if (request.note case final note? when note.isNotEmpty) ...[
                const SizedBox(height: ReadInSpace.s3),
                Text(l10n.adminVerificationNote, style: context.textTheme.labelLarge),
                const SizedBox(height: ReadInSpace.s1),
                ProfileBioText(note, style: context.textTheme.bodyMedium),
              ],
              if (request.rejectionReason case final reason? when reason.isNotEmpty) ...[
                const SizedBox(height: ReadInSpace.s3),
                Text(l10n.adminVerificationReason, style: context.textTheme.labelLarge),
                const SizedBox(height: ReadInSpace.s1),
                ProfileBioText(reason, style: context.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (request.isPending || (request.user.isVerified && !request.isPending))
          PageBlock(
            margin: const EdgeInsets.only(top: PageBlock.gap),
            padding: const EdgeInsets.all(PageBlock.gutter),
            child: request.isPending
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('verification-reject'),
                          style: OutlinedButton.styleFrom(foregroundColor: colors.error),
                          onPressed: busy != null ? null : () => unawaited(_reject(context)),
                          child: Text(l10n.adminVerificationReject),
                        ),
                      ),
                      const SizedBox(width: ReadInSpace.s3),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('verification-approve'),
                          onPressed: busy != null ? null : () => unawaited(_approve(context)),
                          child: busy == VerificationReviewCommand.approve
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(l10n.adminVerificationApprove),
                        ),
                      ),
                    ],
                  )
                : OutlinedButton.icon(
                    key: const ValueKey('verification-remove-badge'),
                    style: OutlinedButton.styleFrom(foregroundColor: colors.error),
                    icon: const Icon(Icons.remove_moderator_outlined),
                    label: Text(l10n.adminRemoveBadge),
                    onPressed: busy != null ? null : () => unawaited(_removeBadge(context)),
                  ),
          ),
      ],
    );
  }

  Future<void> _approve(BuildContext context) async {
    final l10n = context.l10n;
    final name = embedContent(request.user.displayName);
    if (!await confirmAdminAction(context, title: l10n.adminVerificationApproveTitle(name), body: l10n.adminVerificationApproveBody)) {
      return;
    }
    if (!context.mounted) return;
    final failure = await context.read<VerificationRequestCubit>().approve();
    if (!context.mounted) return;
    failure == null ? showActionMessage(context, l10n.adminVerificationApprovedDone) : showActionFailure(context, failure);
  }

  Future<void> _reject(BuildContext context) async {
    final l10n = context.l10n;
    final reason = await showDialog<String>(context: context, builder: (_) => const _RejectDialog());
    if (reason == null || !context.mounted) return;
    final failure = await context.read<VerificationRequestCubit>().reject(reason);
    if (!context.mounted) return;
    failure == null ? showActionMessage(context, l10n.adminVerificationRejectedDone) : showActionFailure(context, failure);
  }

  Future<void> _removeBadge(BuildContext context) async {
    final l10n = context.l10n;
    final name = embedContent(request.user.displayName);
    if (!await confirmAdminAction(context, title: l10n.adminRemoveBadgeTitle(name), body: l10n.adminRemoveBadgeBody)) return;
    if (!context.mounted) return;
    final failure = await context.read<VerificationRequestCubit>().removeBadge();
    if (!context.mounted) return;
    failure == null ? showActionMessage(context, l10n.adminBadgeRemoved) : showActionFailure(context, failure);
  }

  Future<void> _saveProof(BuildContext context, VerificationProofFile proof) async {
    final l10n = context.l10n;
    final result = await context.read<VerificationRequestCubit>().proof();
    if (!context.mounted) return;
    final bytes = result.bytes;
    if (bytes == null) return showActionFailure(context, result.failure);
    try {
      final saved = await getIt<FileSaveService>().save(bytes, fileName: proof.fileName, mimeType: proof.contentType);
      if (saved && context.mounted) showActionMessage(context, l10n.adminVerificationProofSaved);
    } on Object {
      if (context.mounted) showActionMessage(context, l10n.adminVerificationProofSaveFailed);
    }
  }
}

/// "Reject the request?": a reason of 5–500 characters the requester sees on their verification page.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reason.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final valid = _reason.text.trim().length >= VerificationReviewLimits.reasonMin;
    return AlertDialog(
      title: Text(l10n.adminVerificationRejectTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.adminVerificationRejectBody, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: ReadInSpace.s3),
          BidiTextField(
            key: const ValueKey('verification-reject-reason'),
            controller: _reason,
            minLines: 2,
            maxLines: 5,
            maxLength: VerificationReviewLimits.reasonMax,
            counterWithin: 100,
            decoration: InputDecoration(labelText: l10n.adminVerificationReason, helperText: l10n.adminSuspendReasonHint),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
          onPressed: valid ? () => Navigator.of(context).pop(_reason.text.trim()) : null,
          child: Text(l10n.adminConfirm),
        ),
      ],
    );
  }
}

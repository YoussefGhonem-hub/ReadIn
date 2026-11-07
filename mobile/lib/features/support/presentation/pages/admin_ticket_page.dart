import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../admin/presentation/admin_routes.dart';
import '../../../admin/presentation/widgets/admin_widgets.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../moderation/presentation/widgets/moderation_labels.dart' show embedContent;
import '../../../moderation/presentation/widgets/moderation_widgets.dart' show ModerationUserRow;
import '../../../profile/presentation/widgets/profile_header.dart' show ProfileBioText;
import '../../domain/entities/support.dart';
import '../cubit/support_cubits.dart';
import '../widgets/support_widgets.dart';

/// A ticket in the console (`/admin/tickets/{id}`, `support.manage`, F35; a `support_ticket` push lands here): the
/// conversation with internal notes, the member's card, the device details, their reports and moderation history;
/// reply, add an internal note, change the category, close and reopen.
class AdminTicketPage extends StatelessWidget {
  const AdminTicketPage({super.key, required this.ticketId, this.cubit});

  final String ticketId;

  /// Test seam; the app takes the cubit from DI.
  final AdminTicketCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final allowed = context.select((SessionCubit c) => c.state.me?.canManageSupport ?? false);
    if (!allowed) return AdminNoAccessPage(title: context.l10n.adminSectionTickets);
    return BlocProvider(
      create: (_) => (cubit ?? getIt<AdminTicketCubit>(param1: ticketId))..load(),
      child: const AdminTicketView(),
    );
  }
}

/// What the "⋯" of a console ticket offers.
enum AdminTicketAction { category, close, reopen }

class AdminTicketView extends StatefulWidget {
  const AdminTicketView({super.key});

  @override
  State<AdminTicketView> createState() => _AdminTicketViewState();
}

class _AdminTicketViewState extends State<AdminTicketView> {
  /// The composer writes an internal note instead of a reply.
  bool _note = false;

  Future<void> _onAction(AdminTicketAction action, AdminTicket ticket) async {
    final l10n = context.l10n;
    final cubit = context.read<AdminTicketCubit>();
    switch (action) {
      case AdminTicketAction.category:
        final category = await showDialog<SupportCategory>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: Text(l10n.supportChangeCategory),
            children: [
              RadioGroup<SupportCategory>(
                groupValue: ticket.row.category,
                onChanged: (value) => Navigator.of(dialogContext).pop(value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final category in SupportCategory.values)
                      RadioListTile<SupportCategory>(value: category, title: Text(l10n.supportCategory(category))),
                  ],
                ),
              ),
            ],
          ),
        );
        if (category == null || !mounted) return;
        final failure = await cubit.setCategory(category);
        if (mounted) failure == null ? showActionMessage(context, l10n.supportCategoryChanged) : showActionFailure(context, failure);
      case AdminTicketAction.close:
        if (!await confirmAdminAction(context, title: l10n.supportCloseTitle, body: l10n.supportAdminCloseBody)) return;
        final failure = await cubit.closeTicket();
        if (mounted) failure == null ? showActionMessage(context, l10n.supportClosed) : showActionFailure(context, failure);
      case AdminTicketAction.reopen:
        final failure = await cubit.reopenTicket();
        if (mounted) failure == null ? showActionMessage(context, l10n.supportReopened) : showActionFailure(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminTicketCubit>();
    return BlocBuilder<AdminTicketCubit, AdminTicketState>(
      builder: (context, state) {
        final ticket = state.ticket;
        final closed = ticket?.row.status == SupportStatus.closed;
        return Scaffold(
          appBar: AppBar(
            title: Text(ticket == null ? l10n.supportTicketTitle : l10n.supportTicketNumber(ticketNumber(ticket.row.number))),
            actions: [
              if (ticket != null)
                PopupMenuButton<AdminTicketAction>(
                  key: const ValueKey('admin-ticket-menu'),
                  tooltip: l10n.supportTicketMenu,
                  enabled: state.busy == null,
                  onSelected: (action) => unawaited(_onAction(action, ticket)),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: AdminTicketAction.category, child: Text(l10n.supportChangeCategory)),
                    if (closed)
                      PopupMenuItem(value: AdminTicketAction.reopen, child: Text(l10n.supportReopen))
                    else
                      PopupMenuItem(value: AdminTicketAction.close, child: Text(l10n.supportCloseTicket)),
                  ],
                ),
            ],
          ),
          body: switch (state.status) {
            TicketPageStatus.loading => const Center(child: CircularProgressIndicator()),
            TicketPageStatus.failure => ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.load())),
            TicketPageStatus.ready => Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        final failure = await cubit.load();
                        if (context.mounted) showActionFailure(context, failure);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
                        children: [
                          _Head(ticket: ticket!),
                          _MemberCard(ticket: ticket),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final message in ticket.messages) SupportMessageBubble(message: message, adminView: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SupportComposer(
                    hint: _note ? l10n.supportNoteHint : (closed ? l10n.supportReopenToReply : l10n.supportAdminReplyHint),
                    sendLabel: _note ? l10n.supportAddNote : l10n.supportSend,
                    busy: state.busy == TicketCommand.reply || state.busy == TicketCommand.note,
                    leading: Padding(
                      padding: const EdgeInsets.only(bottom: ReadInSpace.s2),
                      child: SegmentedButton<bool>(
                        key: const ValueKey('admin-ticket-mode'),
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(value: false, label: Text(l10n.supportReplyMode), icon: const Icon(Icons.reply_rounded)),
                          ButtonSegment(value: true, label: Text(l10n.supportNoteMode), icon: const Icon(Icons.lock_outline_rounded)),
                        ],
                        selected: {_note},
                        onSelectionChanged: (selection) => setState(() => _note = selection.first),
                      ),
                    ),
                    onSend: (text, _) async {
                      // A closed ticket takes notes only; a reply needs Reopen first.
                      if (closed && !_note) {
                        showActionMessage(context, l10n.supportReopenToReply);
                        return false;
                      }
                      final failure = await cubit.post(text, internal: _note);
                      if (context.mounted) {
                        failure == null
                            ? showActionMessage(context, _note ? l10n.supportNoteAdded : l10n.supportReplySent)
                            : showActionFailure(context, failure);
                      }
                      return failure == null;
                    },
                  ),
                ],
              ),
          },
        );
      },
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.ticket});

  final AdminTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final row = ticket.row;
    final waiting = row.waitingSince;
    final closedAt = row.closedAt;
    return PageBlock(
      margin: const EdgeInsets.only(top: PageBlock.gap),
      padding: const EdgeInsets.all(PageBlock.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.supportCategory(row.category)} · ${adminDateTime(context, row.createdAt)}',
                  style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ),
              SupportStatusTag(status: row.status),
            ],
          ),
          const SizedBox(height: ReadInSpace.s2),
          ProfileBioText(row.subject, style: context.textTheme.titleMedium),
          if (waiting != null) ...[
            const SizedBox(height: ReadInSpace.s1),
            Text(l10n.supportWaiting(adminTime(context, waiting)), style: context.textTheme.bodySmall?.copyWith(color: colors.error)),
          ],
          if (closedAt != null) ...[
            const SizedBox(height: ReadInSpace.s1),
            Text(
              l10n.supportClosedOn(adminDateTime(context, closedAt), switch (ticket.closedBy) {
                SupportClosedBy.member => l10n.supportMember,
                SupportClosedBy.support => l10n.supportTeam,
                SupportClosedBy.auto => l10n.supportClosedAuto,
                null => '—',
              }),
              style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
          if (!ticket.device.isEmpty) ...[
            const Divider(height: ReadInSpace.s5),
            Text(l10n.supportDevice, style: context.textTheme.labelLarge),
            const SizedBox(height: ReadInSpace.s1),
            SupportDeviceCard(device: ticket.device, createdAt: row.createdAt),
          ],
        ],
      ),
    );
  }
}

/// The member: who they are, their account's state, their tickets, reports and warnings; "Open in console".
class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.ticket});

  final AdminTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final member = ticket.member;
    final user = ticket.row.user;
    final canReadUsers = context.select((SessionCubit c) => c.state.me?.can(Permissions.usersRead) ?? false);
    final secondary = context.textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    return PageBlock(
      margin: const EdgeInsets.only(top: PageBlock.gap),
      padding: const EdgeInsets.all(PageBlock.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModerationUserRow(user: user, avatarSize: 36),
          const SizedBox(height: ReadInSpace.s2),
          Wrap(
            spacing: ReadInSpace.s2,
            runSpacing: ReadInSpace.s1,
            children: [
              if (member.suspended)
                InfoTag(
                  label: member.suspendedUntil == null
                      ? l10n.moderationSuspendedForever
                      : l10n.moderationSuspendedUntil(adminDateTime(context, member.suspendedUntil!)),
                  icon: Icons.block_rounded,
                  tone: InfoTagTone.accent,
                ),
              InfoTag(label: l10n.adminJoined(adminDay(context, member.joinedAt)), tone: InfoTagTone.neutral),
              InfoTag(label: l10n.supportMemberTickets(member.ticketCount), tone: InfoTagTone.neutral),
              if (ticket.reportsAgainst case final count? when count > 0)
                InfoTag(label: l10n.adminOpenReports(count), icon: Icons.flag_outlined),
            ],
          ),
          if (ticket.moderation case final history? when history.isNotEmpty) ...[
            const SizedBox(height: ReadInSpace.s3),
            Text(l10n.supportMemberModeration, style: context.textTheme.labelLarge),
            for (final entry in history)
              Padding(
                padding: const EdgeInsets.only(top: ReadInSpace.s1),
                child: Text(
                  [
                    switch (entry.action) {
                      'user.warn' => l10n.moderationLogUserWarn,
                      'user.suspend' => l10n.moderationLogUserSuspend,
                      'user.unsuspend' => l10n.moderationLogUserUnsuspend,
                      _ => l10n.moderationLogOther,
                    },
                    adminTime(context, entry.createdAt),
                    if (entry.note case final note? when note.isNotEmpty) embedContent(note),
                  ].join(' · '),
                  style: secondary,
                ),
              ),
          ],
          if (ticket.reportsFiled case final reports? when reports.isNotEmpty) ...[
            const SizedBox(height: ReadInSpace.s3),
            Text(l10n.supportMemberReports(ticket.reportsFiledTotal), style: context.textTheme.labelLarge),
            for (final report in reports)
              Padding(
                padding: const EdgeInsets.only(top: ReadInSpace.s1),
                child: Text(
                  [
                    if (report.targetLabel case final label? when label.isNotEmpty) embedContent(label),
                    adminTime(context, report.createdAt),
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: secondary,
                ),
              ),
          ],
          if (canReadUsers) ...[
            const SizedBox(height: ReadInSpace.s2),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey('admin-ticket-open-user'),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: Text(l10n.adminOpenInConsole),
                onPressed: () => unawaited(context.push<void>(AdminRoutes.user(user.id))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

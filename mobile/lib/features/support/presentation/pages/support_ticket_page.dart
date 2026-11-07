import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../admin/presentation/widgets/admin_widgets.dart' show adminDateTime, confirmAdminAction;
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../media/domain/repositories/media_picker.dart';
import '../../../profile/presentation/widgets/profile_header.dart' show ProfileBioText;
import '../../domain/entities/support.dart';
import '../cubit/support_cubits.dart';
import '../support_routes.dart';
import '../widgets/support_widgets.dart';

/// A ticket's page for its member (`/settings/support/tickets/{id}`, F35; a `support_reply` push lands here): the
/// conversation, a reply with screenshots, Close, and Reopen within 30 days of closing.
class SupportTicketPage extends StatelessWidget {
  const SupportTicketPage({super.key, required this.ticketId, this.cubit});

  final String ticketId;

  /// Test seam; the app takes the cubit from DI.
  final SupportTicketCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final allowed = context.select((SessionCubit c) => c.state.me?.canContactSupport ?? false);
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyView(icon: Icons.lock_outline_rounded, title: context.l10n.errForbidden),
      );
    }
    return BlocProvider(
      create: (_) => (cubit ?? getIt<SupportTicketCubit>(param1: ticketId))..load(),
      child: const SupportTicketView(),
    );
  }
}

class SupportTicketView extends StatelessWidget {
  const SupportTicketView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SupportTicketCubit>();
    return BlocBuilder<SupportTicketCubit, SupportTicketState>(
      builder: (context, state) {
        final ticket = state.ticket;
        final summary = ticket?.summary;
        return Scaffold(
          appBar: AppBar(
            title: Text(summary == null ? l10n.supportTicketTitle : l10n.supportTicketNumber(ticketNumber(summary.number))),
            actions: [
              if (summary != null && !summary.isClosed)
                PopupMenuButton<String>(
                  key: const ValueKey('support-ticket-menu'),
                  tooltip: l10n.supportTicketMenu,
                  onSelected: (_) => unawaited(_close(context)),
                  itemBuilder: (_) => [PopupMenuItem(value: 'close', child: Text(l10n.supportCloseTicket))],
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
                          if (ticket.summary.isClosed) _ClosedNote(summary: ticket.summary, busy: state.busy),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [for (final message in ticket.messages) SupportMessageBubble(message: message)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!ticket.summary.isClosed)
                    SupportComposer(
                      hint: l10n.supportReplyHint,
                      sendLabel: l10n.supportSend,
                      busy: state.busy == TicketCommand.reply,
                      pickScreenshots: getIt.isRegistered<MediaPicker>() ? (limit) => getIt<MediaPicker>().pickImages(limit: limit) : null,
                      onSend: (text, screenshots) async {
                        final failure = await cubit.reply(text, screenshots: screenshots);
                        if (context.mounted) showActionFailure(context, failure);
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

  Future<void> _close(BuildContext context) async {
    final l10n = context.l10n;
    if (!await confirmAdminAction(context, title: l10n.supportCloseTitle, body: l10n.supportCloseBody)) return;
    if (!context.mounted) return;
    final failure = await context.read<SupportTicketCubit>().closeTicket();
    if (!context.mounted) return;
    failure == null ? showActionMessage(context, l10n.supportClosed) : showActionFailure(context, failure);
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final summary = ticket.summary;
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
                  '${l10n.supportCategory(summary.category)} · ${adminDateTime(context, summary.createdAt)}',
                  style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ),
              SupportStatusTag(status: summary.status),
            ],
          ),
          const SizedBox(height: ReadInSpace.s2),
          ProfileBioText(summary.subject, style: context.textTheme.titleMedium),
          if (summary.status == SupportStatus.open) ...[
            const SizedBox(height: ReadInSpace.s2),
            Text(l10n.supportOpenHint, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// A closed ticket: Reopen within 30 days, or send a new one.
class _ClosedNote extends StatelessWidget {
  const _ClosedNote({required this.summary, required this.busy});

  final SupportTicketSummary summary;
  final TicketCommand? busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return PageBlock(
      margin: const EdgeInsets.only(top: PageBlock.gap),
      padding: const EdgeInsets.all(PageBlock.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: colors.textSecondary),
              const SizedBox(width: ReadInSpace.s2),
              Expanded(
                child: Text(
                  summary.canReopen ? l10n.supportClosedCanReopen : l10n.supportClosedExpired,
                  style: context.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: ReadInSpace.s3),
          if (summary.canReopen)
            OutlinedButton.icon(
              key: const ValueKey('support-reopen'),
              icon: busy == TicketCommand.reopen
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lock_open_rounded),
              label: Text(l10n.supportReopen),
              onPressed: busy != null
                  ? null
                  : () async {
                      final failure = await context.read<SupportTicketCubit>().reopenTicket();
                      if (!context.mounted) return;
                      failure == null ? showActionMessage(context, l10n.supportReopened) : showActionFailure(context, failure);
                    },
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(l10n.supportNewTicket),
              onPressed: () => context.pushReplacement(SupportRoutes.newTicketFrom(SupportRoutes.home)),
            ),
        ],
      ),
    );
  }
}

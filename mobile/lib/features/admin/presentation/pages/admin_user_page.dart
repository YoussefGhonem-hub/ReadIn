import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/phone/phone_numbers.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../moderation/presentation/cubit/moderation_action_cubit.dart';
import '../../../moderation/presentation/moderation_routes.dart';
import '../../../moderation/presentation/widgets/moderation_flows.dart';
import '../../../moderation/presentation/widgets/moderation_labels.dart';
import '../../../moderation/presentation/widgets/moderation_widgets.dart';
import '../../../profile/presentation/profile_routes.dart';
import '../../../profile/presentation/widgets/profile_header.dart' show ProfileBioText, UsernameText;
import '../../../support/domain/entities/support.dart' show AdminTicketRow;
import '../../../support/presentation/widgets/support_widgets.dart' show AdminTicketTile;
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/admin_verification.dart';
import '../admin_routes.dart';
import '../cubit/admin_user_cubit.dart';
import '../widgets/admin_labels.dart';
import '../widgets/admin_widgets.dart';
import 'admin_verification_page.dart' show AdminVerificationTile;

/// A user's console page (`/admin/users/{id}`, `users.read`, F23): profile and stats, sign-in, moderation history,
/// reports, verification, tickets and audit entries (each only with its permission), and the actions this caller may
/// take on the account (`AdminUserDto.actions`).
class AdminUserPage extends StatelessWidget {
  const AdminUserPage({super.key, required this.userId, this.cubit, this.actions});

  final String userId;

  /// Test seams; the app takes the cubits from DI.
  final AdminUserCubit? cubit;
  final ModerationActionCubit? actions;

  @override
  Widget build(BuildContext context) {
    final allowed = context.select((SessionCubit c) => c.state.me?.canReadUsers ?? false);
    if (!allowed) return AdminNoAccessPage(title: context.l10n.adminSectionUsers);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => (cubit ?? getIt<AdminUserCubit>(param1: userId))..load()),
        BlocProvider(create: (_) => actions ?? getIt<ModerationActionCubit>()),
      ],
      child: const AdminUserView(),
    );
  }
}

class AdminUserView extends StatelessWidget {
  const AdminUserView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminUserCubit>();
    return BlocBuilder<AdminUserCubit, AdminUserState>(
      builder: (context, state) {
        final user = state.user;
        return Scaffold(
          appBar: AppBar(title: Text(user == null ? l10n.adminSectionUsers : l10n.adminUserTitle)),
          body: switch (state.status) {
            AdminPageStatus.loading => const Center(child: CircularProgressIndicator()),
            AdminPageStatus.failure => ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.load())),
            AdminPageStatus.ready => RefreshIndicator(
                onRefresh: () async {
                  final failure = await cubit.load();
                  if (context.mounted) showActionFailure(context, failure);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: ReadInSpace.s6),
                  children: [
                    _Header(user: user!, phone: state.phone, revealing: state.busy == AdminUserCommand.revealPhone),
                    _Actions(user: user, busy: state.busy),
                    _Stats(user: user),
                    _Access(user: user),
                    if (user.moderation case final moderation?) _Moderation(moderation: moderation),
                    if (user.reportsAgainst case final reports?)
                      _Reports(title: l10n.adminReportsAgainst(reports.total), reports: reports, showReporter: true),
                    if (user.reportsFiled case final reports?)
                      _Reports(title: l10n.adminReportsFiled(reports.total), reports: reports, showReporter: false),
                    if (user.verification case final verification?) _Verification(section: verification),
                    if (user.tickets case final tickets?) _Tickets(section: tickets),
                    if (user.audit case final audit?) _Audit(section: audit),
                  ],
                ),
              ),
          },
        );
      },
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => PageBlock(
        margin: const EdgeInsets.only(top: PageBlock.gap),
        padding: const EdgeInsets.all(PageBlock.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [if (title != null) AdminSectionTitle(title!), ...children],
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.phone, required this.revealing});

  final AdminUser user;
  final String? phone;
  final bool revealing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final row = user.row;
    final masked = row.phoneMasked;
    return _Block(
      children: [
        Row(
          children: [
            ExcludeSemantics(child: UserAvatar(name: row.displayName, url: row.avatarUrl, size: 56)),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: BidiText(row.displayName, style: context.textTheme.titleLarge)),
                      if (row.isVerified) ...[const SizedBox(width: 4), const VerifiedMark(size: 18)],
                    ],
                  ),
                  UsernameText(row.username, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        if (user.headline case final headline?) ...[
          const SizedBox(height: ReadInSpace.s2),
          ProfileBioText(headline, style: context.textTheme.bodyMedium),
        ],
        const SizedBox(height: ReadInSpace.s3),
        Wrap(
          spacing: ReadInSpace.s2,
          runSpacing: ReadInSpace.s2,
          children: [
            InfoTag(
              label: l10n.accountStatus(row),
              icon: row.suspended ? Icons.block_rounded : Icons.check_circle_outline_rounded,
              tone: row.suspended ? InfoTagTone.accent : InfoTagTone.success,
            ),
            if (row.isSystemAccount) InfoTag(label: l10n.adminSystemAccount, tone: InfoTagTone.neutral),
            if (user.isStaff && !row.isSystemAccount) InfoTag(label: l10n.adminStaff, tone: InfoTagTone.neutral),
            for (final method in row.signInMethods)
              InfoTag(label: l10n.signInMethod(method), icon: signInMethodIcon(method), tone: InfoTagTone.neutral),
          ],
        ),
        if (masked != null) ...[
          const SizedBox(height: ReadInSpace.s2),
          AdminInfoRow(
            label: l10n.adminPhone,
            value: phone == null || phone!.isEmpty ? masked : PhoneNumbers.formatE164(phone!),
            ltr: true,
            // Revealed: Copy (an empty answer means no number, nothing to copy); else Show with users.read.pii.
            trailing: phone != null
                ? phone!.isEmpty
                    ? null
                    : IconButton(
                    tooltip: l10n.adminCopy,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: phone!));
                      if (context.mounted) showActionMessage(context, l10n.copied);
                    },
                  )
                : user.actions.canRevealPhone
                    ? TextButton(
                        key: const ValueKey('admin-reveal-phone'),
                        onPressed: revealing
                            ? null
                            : () async {
                                final failure = await context.read<AdminUserCubit>().revealPhone();
                                if (context.mounted) showActionFailure(context, failure);
                              },
                        child: Text(l10n.adminShowPhone),
                      )
                    : null,
          ),
        ],
      ],
    );
  }
}

/// The account's actions, from `AdminUserDto.actions`.
class _Actions extends StatelessWidget {
  const _Actions({required this.user, required this.busy});

  final AdminUser user;
  final AdminUserCommand? busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final actions = user.actions;
    final row = user.row;
    final cubit = context.read<AdminUserCubit>();
    final canModerate = context.select((SessionCubit c) => c.state.me?.can(Permissions.moderationManage) ?? false);
    Future<void> reloadIf(Future<bool> flow) async {
      if (await flow) await cubit.load();
    }

    Widget item(String key, IconData icon, String label, VoidCallback onTap, {bool danger = false, bool working = false}) => ListTile(
          key: ValueKey('admin-user-$key'),
          contentPadding: EdgeInsets.zero,
          enabled: busy == null,
          leading: working
              ? const SizedBox.square(dimension: 24, child: Padding(padding: EdgeInsets.all(3), child: CircularProgressIndicator(strokeWidth: 2)))
              : Icon(icon, color: danger ? colors.error : null),
          title: Text(label, style: danger ? TextStyle(color: colors.error) : null),
          onTap: onTap,
        );

    final items = <Widget>[
      item('profile', Icons.person_outline_rounded, l10n.adminOpenProfile, () => unawaited(context.push<void>(ProfileRoutes.of(row.username)))),
      // Content filtered to this writer (`writer` on GET /admin/articles, moderation.manage).
      if (canModerate)
        item(
          'articles',
          Icons.article_outlined,
          l10n.adminTheirArticles,
          () => unawaited(context.push<void>(AdminRoutes.contentForWriter(row.id, label: '@${row.username}'))),
        ),
      if (actions.canWarn)
        item('warn', Icons.report_gmailerrorred_rounded, l10n.profileMenuWarn,
            () => unawaited(reloadIf(ModerationFlows.warn(context, userId: row.id, name: row.displayName)))),
      if (actions.canSuspend && !row.suspended)
        item('suspend', Icons.block_rounded, l10n.adminSuspend,
            () => unawaited(reloadIf(ModerationFlows.suspend(context, userId: row.id, name: row.displayName))),
            danger: true),
      if (actions.canSuspend && row.suspended)
        item('unsuspend', Icons.lock_open_rounded, l10n.moderationUnsuspend,
            () => unawaited(reloadIf(ModerationFlows.unsuspend(context, userId: row.id, name: row.displayName)))),
      // Hiding everything follows the protected-account rule of warnings (moderation.manage, not staff).
      if (canModerate && actions.canWarn)
        item('hide-content', Icons.hide_source_rounded, l10n.adminHideContent,
            () => unawaited(reloadIf(ModerationFlows.hideAllContent(context, userId: row.id, name: row.displayName))),
            danger: true),
      if (actions.canRestoreContent)
        item('restore-content', Icons.restore_rounded, l10n.adminRestoreContent(user.moderation?.hiddenWithAccount ?? 0),
            () => unawaited(reloadIf(ModerationFlows.restoreContent(context, userId: row.id, name: row.displayName)))),
      if (actions.canResetPassword)
        item('reset-password', Icons.password_rounded, l10n.adminResetPassword, () => unawaited(_resetPassword(context)),
            working: busy == AdminUserCommand.resetPassword),
      if (actions.canLogoutAll)
        item('logout-all', Icons.devices_other_rounded, l10n.adminLogoutAll, () => unawaited(_logoutAll(context)),
            danger: true, working: busy == AdminUserCommand.logoutAll),
      if (actions.canRemoveBadge)
        item('remove-badge', Icons.remove_moderator_outlined, l10n.adminRemoveBadge, () => unawaited(_removeBadge(context)),
            working: busy == AdminUserCommand.removeBadge),
      if (actions.canClearProfile && user.headline != null)
        item('clear-headline', Icons.badge_outlined, l10n.moderationClearHeadline,
            () => unawaited(reloadIf(ModerationFlows.clearHeadline(context, userId: row.id, name: row.displayName)))),
      if (actions.canClearProfile && user.links.isNotEmpty)
        item('clear-links', Icons.link_off_rounded, l10n.moderationClearLinks,
            () => unawaited(reloadIf(ModerationFlows.clearLinks(context, userId: row.id, name: row.displayName)))),
    ];
    return _Block(title: l10n.moderationActions, children: items);
  }

  Future<void> _resetPassword(BuildContext context) async {
    final l10n = context.l10n;
    final name = embedContent(user.row.displayName);
    if (!await confirmAdminAction(context, title: l10n.adminResetPasswordTitle(name), body: l10n.adminResetPasswordBody)) return;
    if (!context.mounted) return;
    final result = await context.read<AdminUserCubit>().resetPassword();
    if (!context.mounted) return;
    if (result.password case final password?) {
      await showTemporaryPassword(context, password);
    } else {
      showActionFailure(context, result.failure);
    }
  }

  Future<void> _logoutAll(BuildContext context) async {
    final l10n = context.l10n;
    final name = embedContent(user.row.displayName);
    if (!await confirmAdminAction(context, title: l10n.adminLogoutAllTitle(name), body: l10n.adminLogoutAllBody, destructive: true)) {
      return;
    }
    if (!context.mounted) return;
    final failure = await context.read<AdminUserCubit>().logoutAll();
    if (!context.mounted) return;
    failure == null ? showActionMessage(context, l10n.adminLoggedOut) : showActionFailure(context, failure);
  }

  Future<void> _removeBadge(BuildContext context) async {
    final l10n = context.l10n;
    final name = embedContent(user.row.displayName);
    if (!await confirmAdminAction(context, title: l10n.adminRemoveBadgeTitle(name), body: l10n.adminRemoveBadgeBody)) return;
    if (!context.mounted) return;
    final failure = await context.read<AdminUserCubit>().removeBadge();
    if (!context.mounted) return;
    failure == null ? showActionMessage(context, l10n.adminBadgeRemoved) : showActionFailure(context, failure);
  }
}

/// The temporary password after a reset, shown once with Copy (SPEC F23): the user must change it on the next sign in.
Future<void> showTemporaryPassword(BuildContext context, String password) {
  final l10n = context.l10n;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.adminTempPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.adminTempPasswordBody),
          const SizedBox(height: ReadInSpace.s3),
          Container(
            padding: const EdgeInsets.all(ReadInSpace.s3),
            decoration: BoxDecoration(
              color: dialogContext.colors.primaryContainer,
              borderRadius: BorderRadius.circular(ReadInRadius.md),
            ),
            child: SelectableText(
              password,
              key: const ValueKey('admin-temp-password'),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: dialogContext.textTheme.titleLarge?.copyWith(
                fontFamily: ReadInFonts.mono,
                color: dialogContext.colors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: password));
            if (dialogContext.mounted) showActionMessage(dialogContext, l10n.copied);
          },
          child: Text(l10n.adminCopy),
        ),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.done)),
      ],
    ),
  );
}

class _Stats extends StatelessWidget {
  const _Stats({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = user.stats;
    final row = user.row;
    return _Block(
      title: l10n.adminStats,
      children: [
        AdminInfoRow(label: l10n.adminStatArticles, value: adminNumber(row.publishedArticles)),
        AdminInfoRow(label: l10n.adminStatFollowers, value: adminNumber(row.followers)),
        AdminInfoRow(label: l10n.adminStatFollowing, value: adminNumber(stats.following)),
        AdminInfoRow(label: l10n.adminStatTotalReads, value: adminNumber(stats.totalReads)),
        AdminInfoRow(label: l10n.adminStatDrafts, value: adminNumber(stats.drafts)),
        AdminInfoRow(label: l10n.adminStatComments, value: adminNumber(stats.comments)),
        AdminInfoRow(label: l10n.adminStatArticlesRead, value: adminNumber(stats.articlesRead)),
        AdminInfoRow(label: l10n.adminStatStreak, value: l10n.adminStreakValue(stats.currentStreak, stats.longestStreak)),
      ],
    );
  }
}

class _Access extends StatelessWidget {
  const _Access({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final row = user.row;
    final access = user.access;
    final seen = row.lastSeenAt;
    final lockout = access.lockedOutUntil;
    String yesNo(bool value) => value ? l10n.adminYes : l10n.adminNo;
    return _Block(
      title: l10n.adminAccess,
      children: [
        AdminInfoRow(label: l10n.adminJoinedLabel, value: adminDateTime(context, row.joinedAt)),
        AdminInfoRow(label: l10n.adminLastSeenLabel, value: seen == null ? l10n.adminNeverSeen : adminTime(context, seen)),
        if (user.signUpMethod case final method?) AdminInfoRow(label: l10n.adminSignUpMethod, value: l10n.signInMethod(method)),
        AdminInfoRow(label: l10n.adminActiveSessions, value: adminNumber(access.activeSessions)),
        AdminInfoRow(label: l10n.adminHasRecoveryPin, value: yesNo(access.hasRecoveryPin)),
        if (access.recoveryDisabled) AdminInfoRow(label: l10n.adminRecoveryDisabled, value: l10n.adminYes),
        if (access.mustChangePassword) AdminInfoRow(label: l10n.adminMustChangePassword, value: l10n.adminYes),
        if (lockout != null) AdminInfoRow(label: l10n.adminLockedOutUntil, value: adminDateTime(context, lockout)),
        AdminInfoRow(label: l10n.adminUiLanguage, value: user.uiLanguage == 'en' ? l10n.languageEnglish : l10n.languageArabic),
        if (user.row.roles.isNotEmpty) AdminInfoRow(label: l10n.adminRole, value: user.row.roles.join(', '), ltr: true),
      ],
    );
  }
}

class _Moderation extends StatelessWidget {
  const _Moderation({required this.moderation});

  final AdminUserModeration moderation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Block(
      title: l10n.adminModerationHistory(moderation.historyTotal),
      children: [
        AdminInfoRow(label: l10n.adminWarnings, value: adminNumber(moderation.warnings)),
        AdminInfoRow(label: l10n.adminSuspensions, value: adminNumber(moderation.suspensions)),
        AdminInfoRow(label: l10n.adminHiddenArticles, value: adminNumber(moderation.hiddenArticles)),
        AdminInfoRow(label: l10n.adminHiddenComments, value: adminNumber(moderation.hiddenComments)),
        if (moderation.hiddenWithAccount > 0)
          AdminInfoRow(label: l10n.adminHiddenWithAccount, value: adminNumber(moderation.hiddenWithAccount)),
        if (moderation.history.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: ReadInSpace.s2),
            child: Text(l10n.moderationHistoryEmpty, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
          )
        else ...[
          const Divider(),
          for (final entry in moderation.history)
            ModerationLogTile(
              entry: entry,
              padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
              onTap: () => unawaited(context.push<void>(ModerationRoutes.caseOf(entry.ref))),
            ),
        ],
      ],
    );
  }
}

class _Reports extends StatelessWidget {
  const _Reports({required this.title, required this.reports, required this.showReporter});

  final String title;
  final AdminSection<AdminUserReport> reports;
  final bool showReporter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return _Block(
      title: title,
      children: [
        if (reports.items.isEmpty)
          Text(l10n.adminNone, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary))
        else
          for (final report in reports.items)
            InkWell(
              onTap: () => unawaited(context.push<void>(ModerationRoutes.caseOf(report.ref))),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(targetTypeIcon(report.targetType), size: 16, color: colors.textSecondary),
                        const SizedBox(width: ReadInSpace.s1),
                        Expanded(
                          child: Text(
                            '${l10n.reportReason(report.reason)} · ${adminTime(context, report.createdAt)}',
                            style: context.textTheme.labelMedium,
                          ),
                        ),
                        ReportStatusTag(status: report.status),
                      ],
                    ),
                    if (report.targetLabel case final label? when label.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      ProfileBioText(label, maxLines: 2, style: context.textTheme.bodyMedium),
                    ],
                    if (report.details case final details? when details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      ProfileBioText(details, maxLines: 3, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                    ],
                    if (showReporter) ...[
                      const SizedBox(height: ReadInSpace.s1),
                      ModerationUserRow(user: summaryAuthor(report.reporter), avatarSize: 18),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _Verification extends StatelessWidget {
  const _Verification({required this.section});

  final AdminSection<AdminVerificationRequest> section;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Block(
      title: l10n.adminVerificationHistory(section.total),
      children: [
        if (section.items.isEmpty)
          Text(l10n.adminNone, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary))
        else
          for (final request in section.items)
            AdminVerificationTile(
              request: request,
              compact: true,
              onTap: () => unawaited(context.push<void>(AdminRoutes.verificationRequest(request.id))),
            ),
      ],
    );
  }
}

class _Tickets extends StatelessWidget {
  const _Tickets({required this.section});

  final AdminSection<AdminTicketRow> section;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Block(
      title: l10n.adminTicketsOfUser(section.total),
      children: [
        if (section.items.isEmpty)
          Text(l10n.adminNone, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary))
        else
          for (final ticket in section.items)
            AdminTicketTile(ticket: ticket, compact: true, onTap: () => unawaited(context.push<void>(AdminRoutes.ticket(ticket.id)))),
      ],
    );
  }
}

class _Audit extends StatelessWidget {
  const _Audit({required this.section});

  final AdminSection<AdminAuditEntry> section;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return _Block(
      title: l10n.adminAuditOfUser(section.total),
      children: [
        if (section.items.isEmpty)
          Text(l10n.adminNone, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary))
        else
          for (final entry in section.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.auditAction(entry.action), style: context.textTheme.titleSmall),
                  if (entry.details case final details? when details.isNotEmpty)
                    ProfileBioText(details, maxLines: 2, style: context.textTheme.bodySmall),
                  Text(
                    [
                      if (entry.actorName case final actor?) embedContent(actor),
                      adminTime(context, entry.createdAt),
                    ].join(' · '),
                    style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}


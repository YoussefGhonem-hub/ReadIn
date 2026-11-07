import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../profile/presentation/widgets/profile_header.dart' show UsernameText;
import '../../domain/entities/admin_user.dart';
import '../admin_routes.dart';
import '../cubit/admin_list_cubit.dart';
import '../cubit/admin_lists.dart';
import '../widgets/admin_filters.dart';
import '../widgets/admin_labels.dart';
import '../widgets/admin_widgets.dart';

/// The console's Users (`/admin/users`, `users.read`, F23): search by name, `@username` or (with `users.read.pii`) a
/// phone number; filter by status, Verified, sign-in method and open reports; sort; 50 a page.
class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key, this.cubit});

  /// Test seam; the app takes the cubit from DI.
  final AdminUsersCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final allowed = context.select((SessionCubit c) => c.state.me?.canReadUsers ?? false);
    if (!allowed) return AdminNoAccessPage(title: context.l10n.adminSectionUsers);
    return BlocProvider(create: (_) => (cubit ?? getIt<AdminUsersCubit>())..load(), child: const AdminUsersView());
  }
}

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminUsersCubit>();
    final query = context.select((AdminUsersCubit c) => c.state.query);
    final pii = context.select((SessionCubit c) => c.state.me?.can(Permissions.usersReadPii) ?? false);
    void set(AdminUserQuery next) => unawaited(cubit.setQuery(next));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminSectionUsers),
        actions: [
          PopupMenuButton<AdminUserSort>(
            key: const ValueKey('admin-users-sort'),
            tooltip: l10n.adminSort,
            icon: const Icon(Icons.sort_rounded),
            initialValue: query.sort,
            onSelected: (sort) => set(query.copyWith(sort: sort)),
            itemBuilder: (_) => [
              for (final sort in AdminUserSort.values) CheckedPopupMenuItem(value: sort, checked: sort == query.sort, child: Text(l10n.userSort(sort))),
            ],
          ),
        ],
      ),
      body: AdminPagedList<AdminUsersCubit, AdminUserRow, AdminUserQuery>(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminSearchField(
              hint: pii ? l10n.adminUsersSearchHintPii : l10n.adminUsersSearchHint,
              initial: query.q,
              onSearch: (q) => set(query.copyWith(q: q)),
            ),
            AdminChipRow(
              children: [
                // Joined in a period (contract: joinedFrom / joinedTo, both days included).
                AdminPickerChip(
                  key: const ValueKey('admin-users-joined'),
                  label: l10n.adminFilterJoined,
                  value: query.hasJoinedPeriod ? l10n.adminJoinedRange(adminRangeLabel(l10n, query.joinedFrom, query.joinedTo)) : null,
                  onPick: () async {
                    final range = await AdminDatePicker.pickRange(context, adminRangeOf(query.joinedFrom, query.joinedTo));
                    if (range == null) return;
                    final picked = adminRange(range);
                    set(query.copyWith(joinedFrom: () => picked.from, joinedTo: () => picked.to));
                  },
                  onClear: () => set(query.copyWith(joinedFrom: () => null, joinedTo: () => null)),
                ),
                AdminFilterChip(
                  label: l10n.adminFilterSuspended,
                  selected: query.status == AdminUserStatusFilter.suspended,
                  onSelected: (on) => set(query.copyWith(status: () => on ? AdminUserStatusFilter.suspended : null)),
                ),
                AdminFilterChip(
                  label: l10n.adminFilterVerified,
                  selected: query.verified == true,
                  onSelected: (on) => set(query.copyWith(verified: () => on ? true : null)),
                ),
                AdminFilterChip(
                  label: l10n.adminFilterHasReports,
                  selected: query.hasReports,
                  onSelected: (on) => set(query.copyWith(hasReports: on)),
                ),
                for (final method in SignInMethod.values)
                  AdminFilterChip(
                    label: l10n.signInMethod(method),
                    selected: query.method == method,
                    onSelected: (on) => set(query.copyWith(method: () => on ? method : null)),
                  ),
              ],
            ),
          ],
        ),
        countLabel: l10n.adminUsersCount,
        emptyIcon: Icons.person_search_outlined,
        emptyTitle: l10n.adminUsersEmpty,
        itemBuilder: (context, user) => AdminUserTile(
          user: user,
          onTap: () async {
            await context.push<void>(AdminRoutes.user(user.id));
            if (context.mounted) unawaited(context.read<AdminUsersCubit>().refresh());
          },
        ),
      ),
    );
  }
}

/// A user in the console's list: avatar, name ✓ @username, status, joined and last seen, open reports.
class AdminUserTile extends StatelessWidget {
  const AdminUserTile({super.key, required this.user, this.onTap});

  final AdminUserRow user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final secondary = context.textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final seen = user.lastSeenAt;
    return AdminRow(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: UserAvatar(name: user.displayName, url: user.avatarUrl, size: 40)),
          const SizedBox(width: ReadInSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: BidiText(user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall),
                    ),
                    if (user.isVerified) ...[const SizedBox(width: 4), const VerifiedMark(size: 14)],
                    if (user.isSystemAccount) ...[
                      const SizedBox(width: ReadInSpace.s1),
                      InfoTag(label: l10n.adminSystemAccount, tone: InfoTagTone.neutral),
                    ],
                  ],
                ),
                UsernameText(user.username, style: secondary),
                const SizedBox(height: 2),
                Text(
                  [
                    l10n.accountStatus(user),
                    l10n.adminJoined(adminDay(context, user.joinedAt)),
                    seen == null ? l10n.adminNeverSeen : l10n.adminLastSeen(adminTime(context, seen)),
                  ].join(' · '),
                  style: secondary?.copyWith(color: user.suspended ? colors.error : null),
                ),
              ],
            ),
          ),
          if (user.openReports > 0) ...[
            const SizedBox(width: ReadInSpace.s2),
            Tooltip(
              message: l10n.adminOpenReports(user.openReports),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_rounded, size: 16, color: colors.error),
                  const SizedBox(width: 2),
                  Text('${user.openReports}', style: context.textTheme.labelMedium?.copyWith(color: colors.error)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Keeps the generic list type visible to this page's tests.
typedef AdminUsersState = AdminListState<AdminUserRow, AdminUserQuery>;

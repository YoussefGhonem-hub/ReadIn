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
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../profile/presentation/widgets/profile_header.dart' show UsernameText;
import '../../../verification/domain/entities/verification.dart';
import '../../domain/entities/admin_verification.dart';
import '../admin_routes.dart';
import '../cubit/admin_list_cubit.dart' show AdminListStatus;
import '../cubit/verification_review_cubits.dart';
import '../widgets/admin_widgets.dart';

/// The verification queue in the console (`/admin/verification`, `verification.manage`, F19): Pending (oldest
/// first), Approved and Rejected (latest decision first). Each tab loads when first shown and keeps its place.
class AdminVerificationPage extends StatelessWidget {
  const AdminVerificationPage({super.key, this.queueCubit});

  /// Test seam; the app takes the cubits from DI.
  final VerificationQueueCubit Function(VerificationRequestStatus status)? queueCubit;

  static const statuses = [VerificationRequestStatus.pending, VerificationRequestStatus.approved, VerificationRequestStatus.rejected];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allowed = context.select((SessionCubit c) => c.state.me?.canManageVerification ?? false);
    if (!allowed) return AdminNoAccessPage(title: l10n.adminSectionVerification);
    return DefaultTabController(
      length: statuses.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.adminSectionVerification),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.adminVerificationPending),
              Tab(text: l10n.adminVerificationApproved),
              Tab(text: l10n.adminVerificationRejected),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final status in statuses)
              _KeepAlive(
                child: BlocProvider(
                  create: (_) => (queueCubit?.call(status) ?? getIt<VerificationQueueCubit>(param1: status))..load(),
                  child: VerificationQueueView(status: status),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One tab of the queue once its [VerificationQueueCubit] is provided.
class VerificationQueueView extends StatelessWidget {
  const VerificationQueueView({super.key, required this.status});

  final VerificationRequestStatus status;

  static const _loadMoreWithin = 400.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<VerificationQueueCubit>();
    Future<void> refresh() async {
      final failure = await cubit.refresh();
      if (context.mounted) showActionFailure(context, failure);
    }

    return BlocBuilder<VerificationQueueCubit, VerificationQueueState>(
      builder: (context, state) => switch (state.status) {
        AdminListStatus.loading => const AdminListSkeleton(),
        AdminListStatus.failure => ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.load())),
        AdminListStatus.ready when state.items.isEmpty => RefreshIndicator(
            onRefresh: refresh,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: EmptyView(
                    icon: Icons.verified_outlined,
                    title: status == VerificationRequestStatus.pending ? l10n.adminVerificationEmptyPending : l10n.adminVerificationEmpty,
                  ),
                ),
              ),
            ),
          ),
        AdminListStatus.ready => NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < _loadMoreWithin) unawaited(cubit.loadMore());
              return false;
            },
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
                itemCount: state.items.length + (state.hasMore || state.moreFailure != null ? 1 : 0),
                itemBuilder: (context, index) => index < state.items.length
                    ? AdminRow(
                        onTap: () async {
                          await context.push<void>(AdminRoutes.verificationRequest(state.items[index].id));
                          if (context.mounted) unawaited(cubit.refresh());
                        },
                        child: AdminVerificationTile(request: state.items[index]),
                      )
                    : AdminLoadMoreRow(failure: state.moreFailure, onRetry: () => unawaited(cubit.loadMore())),
              ),
            ),
          ),
      },
    );
  }
}

/// A verification request in a list: the requester, the field and job title, and when it was sent or decided.
class AdminVerificationTile extends StatelessWidget {
  const AdminVerificationTile({super.key, required this.request, this.compact = false, this.onTap});

  final AdminVerificationRequest request;

  /// In a user's page: no avatar, the status first.
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final secondary = context.textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final user = request.user;
    final decided = request.decidedAt;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          ExcludeSemantics(child: UserAvatar(name: user.displayName, url: user.avatarUrl, size: 40)),
          const SizedBox(width: ReadInSpace.s3),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact)
                Row(
                  children: [
                    Flexible(child: BidiText(user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall)),
                    if (user.isVerified) ...[const SizedBox(width: 4), const VerifiedMark(size: 14)],
                    const SizedBox(width: ReadInSpace.s1),
                    Flexible(child: UsernameText(user.username, style: secondary)),
                  ],
                ),
              BidiText('${request.field.name} · ${request.jobTitle}', maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                decided == null
                    ? l10n.adminVerificationSubmitted(adminTime(context, request.submittedAt))
                    : l10n.adminVerificationDecided(adminTime(context, decided)),
                style: secondary,
              ),
            ],
          ),
        ),
        const SizedBox(width: ReadInSpace.s2),
        VerificationStatusTag(status: request.status),
      ],
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2), child: content));
  }
}

/// Pending / Approved / Rejected.
class VerificationStatusTag extends StatelessWidget {
  const VerificationStatusTag({super.key, required this.status});

  final VerificationRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InfoTag(
      label: switch (status) {
        VerificationRequestStatus.pending || VerificationRequestStatus.unknown => l10n.adminVerificationTagPending,
        VerificationRequestStatus.approved => l10n.adminVerificationTagApproved,
        VerificationRequestStatus.rejected => l10n.adminVerificationTagRejected,
      },
      tone: switch (status) {
        VerificationRequestStatus.approved => InfoTagTone.success,
        VerificationRequestStatus.rejected => InfoTagTone.accent,
        _ => InfoTagTone.primary,
      },
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

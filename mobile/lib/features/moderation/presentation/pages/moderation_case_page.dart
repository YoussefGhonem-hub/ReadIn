import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/utils/link_opener.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../categories/presentation/category_routes.dart';
import '../../../profile/domain/entities/profile_link.dart';
import '../../../profile/presentation/profile_routes.dart';
import '../../../profile/presentation/widgets/platform_icon.dart';
import '../../domain/entities/moderation.dart';
import '../cubit/moderation_action_cubit.dart';
import '../cubit/moderation_case_cubit.dart';
import '../widgets/moderation_flows.dart';
import '../widgets/moderation_labels.dart';
import '../widgets/moderation_widgets.dart';

/// One case (F22): the target with a link to it, the reports with their reasons, the history, and the actions.
class ModerationCasePage extends StatelessWidget {
  const ModerationCasePage({super.key, required this.target});

  final ModerationTargetRef target;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<ModerationCaseCubit>()..load(target)),
          BlocProvider(create: (_) => getIt<ModerationActionCubit>()),
        ],
        child: ModerationCaseView(type: target.type),
      );
}

/// The case once [ModerationCaseCubit] and [ModerationActionCubit] are provided.
class ModerationCaseView extends StatelessWidget {
  const ModerationCaseView({super.key, required this.type});

  final ModerationTargetType type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allowed = context.select((SessionCubit c) => c.state.me?.isModerator ?? false);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.caseTitle(type))),
      body: !allowed
          ? EmptyView(icon: Icons.lock_outline_rounded, title: l10n.moderationNoAccessTitle, body: l10n.moderationNoAccessBody)
          : BlocBuilder<ModerationCaseCubit, ModerationCaseState>(
              builder: (context, state) => switch (state.status) {
                ModerationCaseStatus.loading => const Center(child: CircularProgressIndicator()),
                ModerationCaseStatus.failure => ErrorView(
                    failure: state.failure!,
                    onRetry: context.read<ModerationCaseCubit>().refresh,
                  ),
                ModerationCaseStatus.ready => _CaseContent(moderationCase: state.moderationCase!),
              },
            ),
    );
  }
}

class _CaseContent extends StatelessWidget {
  const _CaseContent({required this.moderationCase});

  final ModerationCase moderationCase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final c = moderationCase;
    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: ReadInSpace.s5, bottom: ReadInSpace.s2),
          child: Semantics(header: true, child: Text(title, style: context.textTheme.titleMedium)),
        );
    return RefreshIndicator(
      onRefresh: context.read<ModerationCaseCubit>().refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, ReadInSpace.s3, ReadInSpace.s4, ReadInSpace.s8),
        children: [
          _TargetCard(item: c.item),
          // A user's title and links (F14): an abusive one is reported with the user, and cleared here.
          if (c.item.targetType == ModerationTargetType.user && !c.item.target.isDeleted && c.item.target.author != null) ...[
            section(l10n.moderationUserHeadline),
            _CaseHeadline(moderationCase: c),
            section(l10n.moderationUserLinks),
            _CaseLinks(moderationCase: c),
          ],
          section(l10n.moderationActions),
          _CaseActions(moderationCase: c),
          // A user's writer categories (F31): an offensive name is reported with the user, and cleared here.
          if (c.item.targetType == ModerationTargetType.user && c.categories != null) ...[
            section(l10n.moderationCategoriesTitle),
            _CaseCategories(moderationCase: c),
          ],
          section(l10n.moderationReportsTitle(c.reports.length)),
          for (final (i, report) in c.reports.indexed) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            ModerationReportTile(report: report),
          ],
          section(l10n.moderationHistory),
          if (c.history.isEmpty)
            Text(l10n.moderationHistoryEmpty, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary))
          else
            for (final (i, entry) in c.history.indexed) ...[
              if (i > 0) Divider(height: 1, color: colors.border),
              ModerationLogTile(entry: entry, padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3)),
            ],
        ],
      ),
    );
  }
}

/// The target: type, state, status, the preview in full, report count and reasons, and a link to open it.
class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.item});

  final ModerationQueueItem item;

  /// Where the target opens: the article (also for a comment), or the profile. Null when it is gone.
  String? _link() {
    final target = item.target;
    if (target.isDeleted) return null;
    return switch (item.targetType) {
      ModerationTargetType.article => target.slug == null ? null : '/a/${Uri.encodeComponent(target.slug!)}',
      ModerationTargetType.comment => target.articleSlug == null ? null : '/a/${Uri.encodeComponent(target.articleSlug!)}',
      ModerationTargetType.user => target.author == null ? null : ProfileRoutes.of(target.author!.username),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final link = _link();
    return Container(
      padding: const EdgeInsets.all(ReadInSpace.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ReadInRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: ReadInSpace.s2,
            runSpacing: ReadInSpace.s1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(targetTypeIcon(item.targetType), size: 18, color: colors.textSecondary),
                  const SizedBox(width: ReadInSpace.s1),
                  Text(l10n.targetType(item.targetType), style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary)),
                ],
              ),
              ReportStatusTag(status: item.status),
              TargetStateTag(state: item.target.state),
            ],
          ),
          const SizedBox(height: ReadInSpace.s3),
          ModerationTargetPreview(type: item.targetType, target: item.target),
          const SizedBox(height: ReadInSpace.s3),
          Text(
            l10n.moderationReportCount(item.reportCount),
            style: context.textTheme.labelLarge?.copyWith(color: colors.error, fontWeight: FontWeight.w700),
          ),
          if (item.reasons.isNotEmpty) ...[
            const SizedBox(height: ReadInSpace.s2),
            ReasonCounts(reasons: item.reasons),
          ],
          if (link != null) ...[
            const SizedBox(height: ReadInSpace.s2),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => unawaited(context.push<void>(link)),
                icon: Icon(item.targetType == ModerationTargetType.user ? Icons.person_outline_rounded : Icons.open_in_new_rounded, size: 18),
                label: Text(item.targetType == ModerationTargetType.user ? l10n.moderationOpenProfile : l10n.moderationOpenArticle),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "امسح المسمى" / "امسح الروابط": destructive, and waiting while another action runs.
class _ClearButton extends StatelessWidget {
  const _ClearButton({super.key, required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final Future<bool> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final busy = context.select((ModerationActionCubit c) => c.state != null);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        onPressed: busy
            ? null
            : () async {
                final cubit = context.read<ModerationCaseCubit>();
                if (await onPressed()) await cubit.refresh();
              },
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: colors.error,
          side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

/// The user's title in full, in its own direction, with "امسح المسمى" (asks first, optional note); "No title." when
/// there is none.
class _CaseHeadline extends StatelessWidget {
  const _CaseHeadline({required this.moderationCase});

  final ModerationCase moderationCase;

  static const clearKey = ValueKey('case-clear-headline');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final user = moderationCase.item.target.author!;
    final headline = user.headline;
    if (headline == null) {
      return Text(l10n.moderationUserNoHeadline, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary));
    }
    final dir = Bidi.detect(headline) ?? Directionality.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          Bidi.isolateOppositeRuns(headline, dir),
          key: const ValueKey('case-headline'),
          textDirection: dir,
          style: context.textTheme.bodyLarge,
        ),
        const SizedBox(height: ReadInSpace.s2),
        _ClearButton(
          key: clearKey,
          icon: Icons.badge_outlined,
          label: l10n.moderationClearHeadline,
          onPressed: () => ModerationFlows.clearHeadline(context, userId: moderationCase.item.targetId, name: user.displayName),
        ),
      ],
    );
  }
}

/// The user's links in their order: icon, name and address (left to right), each opening in the browser, then
/// "امسح الروابط" (all of them; asks first, optional note); "No links." when there are none.
class _CaseLinks extends StatelessWidget {
  const _CaseLinks({required this.moderationCase});

  final ModerationCase moderationCase;

  static const clearKey = ValueKey('case-clear-links');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final links = moderationCase.item.target.links ?? const <ProfileLink>[];
    final user = moderationCase.item.target.author!;
    if (links.isEmpty) {
      return Text(l10n.moderationUserNoLinks, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, link) in links.indexed)
          Semantics(
            key: ValueKey('case-link-$i'),
            link: true,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 56,
              leading: PlatformIcon(link.platform, color: colors.textPrimary),
              title: Text(Bidi.isolateOppositeRuns(linkPlatformName(l10n, link.platform, label: link.label), Directionality.of(context))),
              // The whole address, so the moderator sees exactly what is linked.
              subtitle: Text(
                Bidi.ltrIsolate(link.url),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => openExternalLink(link.url),
            ),
          ),
        const SizedBox(height: ReadInSpace.s2),
        _ClearButton(
          key: clearKey,
          icon: Icons.link_off_rounded,
          label: l10n.moderationClearLinks,
          onPressed: () => ModerationFlows.clearLinks(context, userId: moderationCase.item.targetId, name: user.displayName),
        ),
      ],
    );
  }
}

/// A user's writer categories (F31), in their order, each opening its category page and with "Clear name" (asks
/// first, with an optional note): the name becomes a neutral placeholder. Names keep their own direction.
class _CaseCategories extends StatelessWidget {
  const _CaseCategories({required this.moderationCase});

  final ModerationCase moderationCase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final categories = moderationCase.categories ?? const [];
    final userId = moderationCase.item.targetId;
    final username = moderationCase.item.target.author?.username;
    final busy = context.select((ModerationActionCubit c) => c.state != null);
    if (categories.isEmpty) {
      return Text(l10n.moderationCategoriesEmpty, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary));
    }
    final dir = Directionality.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, category) in categories.indexed) ...[
          if (i > 0) Divider(height: 1, color: colors.border),
          Padding(
            key: ValueKey('case-category-${category.id}'),
            padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
            child: Row(
              children: [
                ExcludeSemantics(child: Icon(Icons.folder_outlined, size: 20, color: colors.textSecondary)),
                const SizedBox(width: ReadInSpace.s3),
                Expanded(
                  child: _CategoryName(
                    key: ValueKey('case-category-open-${category.id}'),
                    // The category page, like on the web; a deleted account has none.
                    onOpen: username == null ? null : () => unawaited(context.push<void>(CategoryRoutes.of(username, category.slug))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Bidi.isolateOppositeRuns(category.name, Bidi.detect(category.name) ?? dir),
                          textDirection: Bidi.detect(category.name) ?? dir,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(l10n.categoryArticleCount(category.articleCount), style: context.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: ReadInSpace.s2),
                OutlinedButton.icon(
                  key: ValueKey('case-category-clear-${category.id}'),
                  onPressed: busy
                      ? null
                      : () async {
                          final cubit = context.read<ModerationCaseCubit>();
                          if (await ModerationFlows.clearCategory(context, userId: userId, category: category)) await cubit.refresh();
                        },
                  icon: const Icon(Icons.folder_off_outlined, size: 18),
                  label: Text(l10n.moderationClearCategory),
                  style: OutlinedButton.styleFrom(foregroundColor: colors.error, side: BorderSide(color: colors.error.withValues(alpha: 0.5))),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A category's name and count: a link to its page (one tap target with the link role and the "opens the category"
/// hint, reachable by keyboard), or plain text when there is no page to open.
class _CategoryName extends StatelessWidget {
  const _CategoryName({super.key, required this.onOpen, required this.child});

  final VoidCallback? onOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onOpen = this.onOpen;
    if (onOpen == null) return child;
    return MergeSemantics(
      child: Semantics(
        link: true,
        hint: context.l10n.categoryOpenHint,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(ReadInRadius.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Align(alignment: AlignmentDirectional.centerStart, child: child),
          ),
        ),
      ),
    );
  }
}

/// What a moderator can do here. Destructive actions ask first; all wait while one runs.
class _CaseActions extends StatelessWidget {
  const _CaseActions({required this.moderationCase});

  final ModerationCase moderationCase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final item = moderationCase.item;
    final target = item.target;
    final type = item.targetType;
    final ref = item.ref;
    final canSuspend = context.select((SessionCubit c) => c.state.me?.canSuspend ?? false);
    final busy = context.select((ModerationActionCubit c) => c.state != null);
    final author = target.author;
    final isUser = type == ModerationTargetType.user;
    // Warn or suspend the author of content (closing the content's reports too), or the user itself.
    final person = target.isDeleted && isUser ? null : author;
    final resolve = isUser ? null : ref;

    Future<void> act(Future<bool> Function() action) async {
      final cubit = context.read<ModerationCaseCubit>();
      if (await action()) await cubit.refresh();
    }

    Widget button(IconData icon, String label, Future<bool> Function() action, {bool destructive = false}) => OutlinedButton.icon(
          onPressed: busy ? null : () => unawaited(act(action)),
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: destructive
              ? OutlinedButton.styleFrom(foregroundColor: colors.error, side: BorderSide(color: colors.error.withValues(alpha: 0.5)))
              : null,
        );

    final buttons = [
      if (!isUser && !target.isDeleted)
        target.isHidden
            ? button(
                Icons.visibility_outlined,
                type == ModerationTargetType.article ? l10n.articleMenuUnhide : l10n.moderationUnhideComment,
                () => ModerationFlows.unhide(context, ref),
              )
            : button(
                Icons.visibility_off_outlined,
                type == ModerationTargetType.article ? l10n.articleMenuHide : l10n.moderationHideComment,
                () => ModerationFlows.hide(context, ref),
                destructive: true,
              ),
      if (type == ModerationTargetType.comment && !target.isDeleted)
        button(Icons.delete_outline_rounded, l10n.moderationDeleteComment, () => ModerationFlows.deleteComment(context, ref.id), destructive: true),
      if (person != null)
        button(
          Icons.report_gmailerrorred_rounded,
          isUser ? l10n.profileMenuWarn : l10n.moderationWarnAuthor,
          () => ModerationFlows.warn(context, userId: person.id, name: person.displayName, resolveReportsOf: resolve),
        ),
      if (person != null && canSuspend)
        isUser && target.isSuspended
            ? button(
                Icons.lock_open_rounded,
                l10n.moderationUnsuspend,
                () => ModerationFlows.unsuspend(context, userId: person.id, name: person.displayName),
              )
            : button(
                Icons.block_rounded,
                isUser ? l10n.profileMenuSuspend : l10n.moderationSuspendAuthor,
                () => ModerationFlows.suspend(context, userId: person.id, name: person.displayName, resolveReportsOf: resolve),
                destructive: true,
              ),
      if (moderationCase.openReports > 0 || item.status == ReportStatus.open)
        button(Icons.done_all_rounded, l10n.moderationDismiss, () => ModerationFlows.dismiss(context, ref)),
    ];
    return Wrap(spacing: ReadInSpace.s2, runSpacing: ReadInSpace.s2, children: buttons);
  }
}

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
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/presentation/widgets/article_card_tile.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../domain/entities/learning_path.dart';
import '../cubit/path_details_cubit.dart';
import '../widgets/path_widgets.dart';

/// A learning path (F09, guests allowed): header, the primary action (start · continue · read again), "Leave path"
/// in the menu, and the ordered articles with read ticks. The header and the articles are two blocks on the canvas.
class PathPage extends StatelessWidget {
  const PathPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => getIt<PathDetailsCubit>()..load(slug), child: const PathView());
}

enum _PathMenu { leave }

/// The path page once its [PathDetailsCubit] is provided.
class PathView extends StatelessWidget {
  const PathView({super.key});

  /// Opens an article of the path; back here, the ticks and the progress refresh.
  static Future<void> _openArticle(BuildContext context, String slug) async {
    final cubit = context.read<PathDetailsCubit>();
    await context.push<void>('/a/$slug');
    if (!cubit.isClosed) unawaited(cubit.refresh());
  }

  static Future<void> _start(BuildContext context, PathDetails details) async {
    if (!requireAccount(context)) return;
    final result = await context.read<PathDetailsCubit>().enroll();
    if (!context.mounted) return;
    result.fold(
      (failure) => showActionFailure(context, failure),
      (path) {
        final slug = path.progress?.next?.slug ?? details.items.firstOrNull?.article.slug;
        if (slug != null) unawaited(_openArticle(context, slug));
      },
    );
  }

  static Future<void> _leave(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.pathLeaveTitle),
        content: Text(l10n.pathLeaveBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: dialogContext.colors.error, foregroundColor: dialogContext.colors.onError),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.pathLeaveConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final failure = await context.read<PathDetailsCubit>().leave();
    if (!context.mounted) return;
    if (failure != null) {
      showActionFailure(context, failure);
    } else {
      showActionMessage(context, l10n.pathLeft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<SessionCubit, SessionState>(
      listenWhen: (a, b) => a.status != SessionStatus.unknown && (a.isAuthenticated, a.me?.id) != (b.isAuthenticated, b.me?.id),
      // Progress and enrollment are the viewer's.
      listener: (context, _) => context.read<PathDetailsCubit>().refresh(),
      child: BlocBuilder<PathDetailsCubit, PathDetailsState>(
        builder: (context, state) {
          final details = state.details;
          final enrolled = details?.path.isEnrolled ?? false;
          return Scaffold(
            appBar: AppBar(
              actions: [
                if (enrolled)
                  PopupMenuButton<_PathMenu>(
                    tooltip: l10n.pathMenu,
                    enabled: !state.busy,
                    onSelected: (_) => _leave(context),
                    itemBuilder: (_) => [PopupMenuItem(value: _PathMenu.leave, child: Text(l10n.pathLeave))],
                  ),
              ],
            ),
            body: switch (state.status) {
              PathDetailsStatus.loading => const _PathSkeleton(),
              PathDetailsStatus.failure when state.notFound => PageBlock(
                  margin: _blockGap,
                  child: EmptyView(
                    icon: Icons.route_outlined,
                    title: l10n.pathNotFoundTitle,
                    body: l10n.pathNotFoundBody,
                  ),
                ),
              PathDetailsStatus.failure => PageBlock(
                  margin: _blockGap,
                  child: ErrorView(
                    failure: state.failure!,
                    onRetry: () => context.read<PathDetailsCubit>().refresh(),
                  ),
                ),
              PathDetailsStatus.ready => RefreshIndicator(
                  onRefresh: context.read<PathDetailsCubit>().refresh,
                  child: _PathContent(
                    details: details!,
                    busy: state.busy,
                    onStart: () => _start(context, details),
                    onOpen: (slug) => _openArticle(context, slug),
                  ),
                ),
            },
          );
        },
      ),
    );
  }
}

class _PathContent extends StatelessWidget {
  const _PathContent({required this.details, required this.busy, required this.onStart, required this.onOpen});

  final PathDetails details;
  final bool busy;
  final VoidCallback onStart;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final nextId = details.path.progress?.next?.id;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageBlock(
            margin: _blockGap,
            padding: const EdgeInsets.all(PageBlock.gutter),
            child: _PathHeader(details: details, busy: busy, onStart: onStart, onOpen: onOpen),
          ),
        ),
        // The articles in order, in one block under its title; the rows split by their own top lines.
        SliverPadding(
          padding: const EdgeInsets.only(bottom: ReadInSpace.s6),
          sliver: SliverToBoxAdapter(
            child: PageBlock(
              margin: _blockGap,
              padding: const EdgeInsets.fromLTRB(PageBlock.gutter, ReadInSpace.s3, PageBlock.gutter, ReadInSpace.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: ReadInSpace.s2),
                    child: Semantics(
                      header: true,
                      child: Text(context.l10n.pathArticleCount(details.items.length), style: context.textTheme.titleMedium),
                    ),
                  ),
                  for (final item in details.items)
                    _PathItemRow(item: item, isNext: item.article.id == nextId, onTap: () => onOpen(item.article.slug)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PathHeader extends StatelessWidget {
  const _PathHeader({required this.details, required this.busy, required this.onStart, required this.onOpen});

  final PathDetails details;
  final bool busy;
  final VoidCallback onStart;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final path = details.path;
    final progress = path.progress;
    final description = path.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 148, child: PathCover(path: path, radius: ReadInRadius.card, iconSize: 48)),
        const SizedBox(height: ReadInSpace.s4),
        Wrap(
          spacing: ReadInSpace.s2,
          runSpacing: ReadInSpace.s1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InfoTag(label: path.field.nameFor(lang)),
            if (path.isCompleted) const PathCompletedBadge(),
          ],
        ),
        const SizedBox(height: ReadInSpace.s2),
        Semantics(
          header: true,
          child: BidiText(path.title, style: context.textTheme.headlineSmall?.copyWith(height: 1.4)),
        ),
        if (description != null) ...[
          const SizedBox(height: ReadInSpace.s2),
          BidiText(description, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary, height: 1.6)),
        ],
        const SizedBox(height: ReadInSpace.s3),
        PathMeta(path: path),
        if (progress != null) ...[
          const SizedBox(height: ReadInSpace.s3),
          PathProgressRow(progress: progress),
        ],
        const SizedBox(height: ReadInSpace.s4),
        _PrimaryAction(details: details, busy: busy, onStart: onStart, onOpen: onOpen),
      ],
    );
  }
}

/// Guest or not enrolled: "Start path". Enrolled: "Continue: {next}", or "Read again" once every article is read.
class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.details, required this.busy, required this.onStart, required this.onOpen});

  final PathDetails details;
  final bool busy;
  final VoidCallback onStart;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);
    final path = details.path;
    final next = path.progress?.next;
    final first = details.items.firstOrNull;

    if (!signedIn || !path.isEnrolled) {
      return FilledButton.icon(
        onPressed: busy ? null : onStart,
        icon: busy
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.pathStart),
      );
    }
    if (next != null) {
      return FilledButton.icon(
        onPressed: () => onOpen(next.slug),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.pathContinue(isolateTitle(next.title)), maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }
    return OutlinedButton.icon(
      onPressed: first == null ? null : () => onOpen(first.article.slug),
      icon: const Icon(Icons.replay_rounded),
      label: Text(l10n.pathReadAgain),
    );
  }
}

/// One article of the path: its place (a ✓ once read), the article card, and "Up next" on the first unread one.
class _PathItemRow extends StatelessWidget {
  const _PathItemRow({required this.item, required this.isNext, required this.onTap});

  final PathItem item;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Centred on the card's 64 px thumbnail.
        Padding(
          padding: const EdgeInsets.only(top: ReadInSpace.s3 + 18),
          child: _PositionMarker(position: item.position, isRead: item.isRead, isNext: isNext),
        ),
        const SizedBox(width: ReadInSpace.s3),
        Expanded(child: ArticleCardTile(article: item.article, onTap: onTap)),
      ],
    );
    if (!isNext) return row;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: ReadInSpace.s1),
      padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s2, ReadInSpace.s2, ReadInSpace.s2, 0),
      decoration: BoxDecoration(
        color: Color.alphaBlend(colors.primary.withValues(alpha: 0.06), colors.surface),
        borderRadius: BorderRadius.circular(ReadInRadius.md),
        border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 28 + ReadInSpace.s3),
            child: Text(
              context.l10n.pathUpNext,
              style: context.textTheme.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          row,
        ],
      ),
    );
  }
}

class _PositionMarker extends StatelessWidget {
  const _PositionMarker({required this.position, required this.isRead, required this.isNext});

  final int position;
  final bool isRead;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg) = isRead
        ? (colors.success, colors.onPrimary)
        : isNext
            ? (colors.primary, colors.onPrimary)
            : (colors.surfaceVariant, colors.textSecondary);
    return Semantics(
      label: isRead ? '$position, ${context.l10n.pathItemRead}' : '$position',
      container: true,
      excludeSemantics: true,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: isRead
            ? Icon(Icons.check_rounded, size: 18, color: fg)
            : Text('$position', style: context.textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// The canvas above a block.
const _blockGap = EdgeInsets.only(top: PageBlock.gap);

/// The header's block and the articles' block while the path loads.
class _PathSkeleton extends StatelessWidget {
  const _PathSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const PageBlock(
            margin: _blockGap,
            padding: EdgeInsets.all(PageBlock.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonBox(height: 148, radius: ReadInRadius.card),
                SizedBox(height: ReadInSpace.s4),
                Align(alignment: AlignmentDirectional.centerStart, child: SkeletonBox(width: 80)),
                SizedBox(height: ReadInSpace.s3),
                SkeletonBox(height: 24),
                SizedBox(height: ReadInSpace.s2),
                Align(alignment: AlignmentDirectional.centerStart, child: SkeletonBox(width: 220, height: 24)),
                SizedBox(height: ReadInSpace.s4),
                SkeletonBox(height: 44, radius: ReadInRadius.chip),
              ],
            ),
          ),
          PageBlock(
            margin: _blockGap,
            padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s2),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: ReadInSpace.s3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(padding: EdgeInsets.only(top: 18), child: SkeletonBox(width: 28, height: 28, radius: 14)),
                        SizedBox(width: ReadInSpace.s3),
                        SkeletonBox(width: 64, height: 64, radius: ReadInRadius.md),
                        SizedBox(width: ReadInSpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [SkeletonBox(width: 70), SizedBox(height: ReadInSpace.s2), SkeletonBox(), SizedBox(height: ReadInSpace.s2), SkeletonBox(width: 140)],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}

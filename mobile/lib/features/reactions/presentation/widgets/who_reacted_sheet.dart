import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/reactions.dart';
import '../cubit/reactors_cubit.dart';
import 'reaction_visuals.dart';

/// Builds the cubit of one tab: null = every reaction type.
typedef ReactorsCubitFactory = ReactorsCubit Function(ReactionType? type);

/// "Who reacted" (F10): a tab for everyone, then one per reaction type, each paged. Public, guests can open it too.
Future<void> showWhoReactedSheet(
  BuildContext context, {
  required String articleId,
  required ReactionCounts reactions,
  required int total,
  ReactorsCubitFactory? cubitFor,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.75,
        child: WhoReactedView(
          reactions: reactions,
          total: total,
          cubitFor: cubitFor ?? (type) => getIt<ReactorsCubit>()..load(articleId, type: type),
        ),
      ),
    );

class WhoReactedView extends StatelessWidget {
  const WhoReactedView({super.key, required this.reactions, required this.total, required this.cubitFor, this.initialType});

  final ReactionCounts reactions;
  final int total;
  final ReactorsCubitFactory cubitFor;

  /// The tab to open on; null = everyone.
  final ReactionType? initialType;

  static const _types = <ReactionType?>[null, ...ReactionType.values];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: _types.length,
      initialIndex: _types.indexOf(initialType),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s5, 0, ReadInSpace.s2, 0),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(header: true, child: Text(l10n.whoReacted, style: context.textTheme.titleMedium)),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3),
            tabs: [
              for (final type in _types)
                Tab(
                  child: Semantics(
                    label: type == null
                        ? l10n.reactionsCount(total)
                        : l10n.reactionCountSemantics(type.label(l10n), reactions.of(type)),
                    excludeSemantics: true,
                    child: Text(
                      type == null ? '${l10n.filterAll} $total' : '${type.emoji} ${reactions.of(type)}',
                      // Merged into the tab's label style: only the emoji fonts are added.
                      style: TextStyle(
                        fontFamilyFallback: [...?context.textTheme.labelLarge?.fontFamilyFallback, ...emojiFontFallback],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final type in _types)
                  BlocProvider<ReactorsCubit>(create: (_) => cubitFor(type), child: _ReactorsList(type: type)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactorsList extends StatelessWidget {
  const _ReactorsList({required this.type});

  final ReactionType? type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ReactorsCubit, ReactorsState>(
      builder: (context, state) => switch (state.status) {
        ReactorsStatus.loading => const _ReactorsSkeleton(),
        ReactorsStatus.failure => ErrorView(failure: state.failure!, compact: true, onRetry: context.read<ReactorsCubit>().retry),
        ReactorsStatus.ready when state.items.isEmpty => EmptyView(
            icon: Icons.emoji_emotions_outlined,
            title: type == null ? l10n.reactorsEmpty : l10n.reactorsEmptyType(type!.emoji),
          ),
        ReactorsStatus.ready => NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 300) context.read<ReactorsCubit>().loadMore();
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
              itemCount: state.items.length + (state.hasMore || state.loadMoreFailure != null ? 1 : 0),
              itemBuilder: (context, i) => i < state.items.length
                  ? ReactorTile(reactor: state.items[i])
                  : Padding(
                      padding: const EdgeInsets.all(ReadInSpace.s4),
                      child: Center(
                        child: state.loadMoreFailure != null
                            ? ErrorView(failure: state.loadMoreFailure!, compact: true, onRetry: context.read<ReactorsCubit>().loadMore)
                            : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                      ),
                    ),
            ),
          ),
      },
    );
  }
}

/// One person who reacted, with their reaction at the end.
class ReactorTile extends StatelessWidget {
  const ReactorTile({super.key, required this.reactor});

  final Reactor reactor;

  @override
  Widget build(BuildContext context) {
    final user = reactor.user;
    final l10n = context.l10n;
    return MergeSemantics(
      child: ListTile(
        minTileHeight: 56,
        leading: UserAvatar(name: user.displayName, url: user.avatarUrl, size: 40),
        title: Row(
          children: [
            Flexible(child: BidiText(user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (user.isVerified) ...[const SizedBox(width: 4), const VerifiedMark()],
          ],
        ),
        subtitle: Text(Bidi.ltrIsolate('@${user.username}'), style: context.textTheme.bodySmall),
        trailing: Semantics(
          label: reactor.type.label(l10n),
          child: ExcludeSemantics(child: Text(reactor.type.emoji, style: const TextStyle(fontSize: 22, fontFamilyFallback: emojiFontFallback))),
        ),
      ),
    );
  }
}

class _ReactorsSkeleton extends StatelessWidget {
  const _ReactorsSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(ReadInSpace.s4),
        children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
              child: Row(
                children: [
                  const SkeletonBox(width: 40, height: 40, radius: 20),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: i.isEven ? 140 : 110),
                        const SizedBox(height: ReadInSpace.s2),
                        const SkeletonBox(width: 80, height: 12),
                      ],
                    ),
                  ),
                  const SkeletonBox(width: 24, height: 24, radius: 12),
                ],
              ),
            ),
        ],
      );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/rdoc_scope.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/highlight.dart';
import '../cubit/my_highlights_cubit.dart';

/// The reader link of one of your highlights: that version of the article, at the highlight's block (like a block
/// link: no resume).
String highlightLink(HighlightArticle article, String blockId) =>
    '/a/${article.slug}?lang=${Uri.encodeQueryComponent(article.language)}#$blockId';

/// Saved → Highlights (F30, F14): your highlights grouped by article version, newest first, paged by cursor; tapping one
/// opens the article in that version at its block. Needs a [MyHighlightsCubit] above.
class SavedHighlightsList extends StatefulWidget {
  const SavedHighlightsList({super.key, this.leading});

  /// A first sliver, e.g. the room for a pinned tab bar above (the profile).
  final Widget Function(BuildContext context)? leading;

  @override
  State<SavedHighlightsList> createState() => _SavedHighlightsListState();
}

class _SavedHighlightsListState extends State<SavedHighlightsList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final cubit = context.read<MyHighlightsCubit>();
    return BlocBuilder<MyHighlightsCubit, MyHighlightsState>(
      builder: (context, state) => RefreshIndicator(
        onRefresh: cubit.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) unawaited(cubit.loadMore());
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              ?widget.leading?.call(context),
              ...switch (state.status) {
                MyHighlightsStatus.loading => [const SliverToBoxAdapter(child: _HighlightsSkeleton())],
                MyHighlightsStatus.failure => [
                    SliverFillRemaining(hasScrollBody: false, child: ErrorView(failure: state.failure!, onRetry: cubit.load)),
                  ],
                MyHighlightsStatus.ready when state.groups.isEmpty => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyView(
                        icon: Icons.border_color_outlined,
                        title: l10n.highlightSavedEmptyTitle,
                        body: l10n.highlightSavedEmptyBody,
                      ),
                    ),
                  ],
                MyHighlightsStatus.ready => [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, 0),
                      sliver: SliverList.builder(
                        itemCount: state.groups.length + 1,
                        itemBuilder: (context, i) => i < state.groups.length
                            ? HighlightGroupCard(key: ValueKey('highlight-group-${state.groups[i].key}'), group: state.groups[i])
                            : _Footer(state: state),
                      ),
                    ),
                  ],
              },
            ],
          ),
        ),
      ),
    );
  }
}

/// One article version and your highlights on it, newest first.
class HighlightGroupCard extends StatelessWidget {
  const HighlightGroupCard({super.key, required this.group});

  final HighlightGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final article = group.article;
    // The article's own direction, whatever the app's language.
    final direction = RDocScope.directionForLanguage(article.language);
    final author = article.author?.displayName ?? l10n.deletedUser;
    // "Arabic version" / "English version", as on the web.
    final version = article.language == 'en' ? l10n.highlightSavedVersionEn : l10n.highlightSavedVersionAr;
    return Padding(
      padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(ReadInRadius.card),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: direction,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          Bidi.isolateOppositeRuns(article.title, direction),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleSmall?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: ReadInSpace.s1),
                    Row(
                      children: [
                        Flexible(
                          child: BidiText(
                            author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                          ),
                        ),
                        Text(' · ', style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                        Text(version, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ReadInSpace.s2),
              for (final h in group.highlights)
                SavedHighlightTile(
                  key: ValueKey('saved-highlight-${h.id}'),
                  text: h.text,
                  direction: direction,
                  onTap: () => unawaited(context.push(highlightLink(article, h.blockId))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One highlight: its text with the amber mark at its start; tapping opens the article there.
class SavedHighlightTile extends StatelessWidget {
  const SavedHighlightTile({super.key, required this.text, required this.direction, required this.onTap});

  final String text;

  /// The article's direction.
  final TextDirection direction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      onTapHint: context.l10n.highlightSavedOpen,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4, vertical: ReadInSpace.s2),
          child: Directionality(
            textDirection: direction,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3,
                    decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: Text(
                      Bidi.isolateOppositeRuns(text, direction),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final MyHighlightsState state;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (state.loadingMore) {
      child = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5));
    } else if (state.loadMoreFailure != null) {
      child = ErrorView(failure: state.loadMoreFailure!, compact: true, onRetry: context.read<MyHighlightsCubit>().loadMore);
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s5), child: Center(child: child));
  }
}

class _HighlightsSkeleton extends StatelessWidget {
  const _HighlightsSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(ReadInSpace.s5),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: ReadInSpace.s5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 220, height: 18),
                    SizedBox(height: ReadInSpace.s2),
                    SkeletonBox(width: 120, height: 12),
                    SizedBox(height: ReadInSpace.s3),
                    SkeletonBox(),
                    SizedBox(height: ReadInSpace.s2),
                    SkeletonBox(width: 260),
                  ],
                ),
              ),
          ],
        ),
      );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart';
import '../cubit/suggested_writers_cubit.dart';

/// "Add to your feed" in Home's For you feed (F12): suggested writers as a row of cards, each with Follow, and "See
/// all" ([onSeeAll], Explore). For signed-in readers; it shows nothing while loading, on failure, or with no
/// suggestion. Loads the [SuggestedWritersCubit] above the first time it is built.
class SuggestedWritersCarousel extends StatefulWidget {
  const SuggestedWritersCarousel({super.key, required this.onSeeAll, this.margin = EdgeInsets.zero});

  final VoidCallback onSeeAll;

  /// Around the block once it shows (e.g. the gap to the next post card).
  final EdgeInsetsGeometry margin;

  @override
  State<SuggestedWritersCarousel> createState() => _SuggestedWritersCarouselState();
}

class _SuggestedWritersCarouselState extends State<SuggestedWritersCarousel> {
  static const _gutter = PageBlock.gutter;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<SuggestedWritersCubit>().ensureLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SuggestedWritersCubit>().state;
    if (state.status != SuggestedWritersStatus.ready || state.users.isEmpty) return const SizedBox.shrink();
    final title = l10n.suggestedWritersFeedTitle;
    // A full-width block between the post cards, like them (F34).
    return PageBlock(
      key: const ValueKey('feed-suggested-writers'),
      margin: widget.margin,
      padding: const EdgeInsets.only(top: ReadInSpace.s1, bottom: ReadInSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: _gutter, end: ReadInSpace.s1),
            child: ExploreSectionHeader(
              title: title,
              seeAllKey: const ValueKey('feed-suggested-writers-see-all'),
              onSeeAll: widget.onSeeAll,
            ),
          ),
          WriterRail(
            users: state.users,
            label: title,
            keyPrefix: 'feed-writer',
            padding: const EdgeInsets.symmetric(horizontal: _gutter),
          ),
        ],
      ),
    );
  }
}

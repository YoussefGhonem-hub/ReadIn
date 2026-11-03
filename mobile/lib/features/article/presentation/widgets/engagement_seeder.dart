import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/article.dart';
import '../cubit/engagement_cubit.dart';

/// Hands the cards a screen's cubit loads to [EngagementCubit], so the newest counters and viewer state win across
/// screens. Only cards it hasn't seen (new objects from the API) are handed over: a "load more" doesn't overwrite
/// live counters or the viewer's actions on the cards already shown.
class EngagementSeeder<B extends StateStreamable<S>, S> extends StatefulWidget {
  const EngagementSeeder({super.key, required this.cards, required this.child});

  final Iterable<ArticleCard> Function(S state) cards;
  final Widget child;

  @override
  State<EngagementSeeder<B, S>> createState() => _EngagementSeederState<B, S>();
}

class _EngagementSeederState<B extends StateStreamable<S>, S> extends State<EngagementSeeder<B, S>> {
  var _seen = Set<ArticleCard>.identity();

  @override
  void initState() {
    super.initState();
    _seed(context.read<B>().state);
  }

  void _seed(S state) {
    final cards = widget.cards(state).toList();
    final fresh = cards.where((card) => !_seen.contains(card)).toList();
    _seen = Set<ArticleCard>.identity()..addAll(cards);
    if (fresh.isNotEmpty) context.read<EngagementCubit>().seed(fresh);
  }

  @override
  Widget build(BuildContext context) => BlocListener<B, S>(listener: (_, state) => _seed(state), child: widget.child);
}

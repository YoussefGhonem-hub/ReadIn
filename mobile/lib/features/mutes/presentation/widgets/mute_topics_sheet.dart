import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../article/domain/entities/article.dart';
import '../cubit/mutes_cubit.dart';

/// "كتم المواضيع" (F28): the article's field and topic, each with a toggle. On mutes, off unmutes; the cards in it
/// fold away from the lists, or come back, as soon as it changes. The caller asks guests to sign in first.
Future<void> showMuteTopicsSheet(BuildContext context, {required ArticleCard article}) {
  final mutes = context.read<MutesCubit>();
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(value: mutes, child: MuteTopicsSheet(article: article)),
  );
}

/// The content of [showMuteTopicsSheet]. Needs a [MutesCubit] above it.
class MuteTopicsSheet extends StatelessWidget {
  const MuteTopicsSheet({super.key, required this.article});

  final ArticleCard article;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final topic = article.topic;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.muteTopicsTitle, style: context.textTheme.titleMedium)),
          const SizedBox(height: ReadInSpace.s1),
          Text(l10n.muteTopicsBody, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: ReadInSpace.s3),
          _MuteToggle(
            key: const ValueKey('mute-toggle-field'),
            kind: l10n.muteTopicsField,
            name: article.field,
            mutedIn: (state) => state.isFieldMuted(article.field.id, fallback: article.isFieldMuted),
            pendingKey: 'field:${article.field.id}',
            onChanged: (cubit, muted) => cubit.setFieldMuted(article.field.id, muted: muted),
          ),
          if (topic != null)
            _MuteToggle(
              key: const ValueKey('mute-toggle-topic'),
              kind: l10n.muteTopicsTopic,
              name: topic,
              mutedIn: (state) => state.isTopicMuted(topic.id, fallback: article.isTopicMuted),
              pendingKey: 'topic:${topic.id}',
              onChanged: (cubit, muted) => cubit.setTopicMuted(topic.id, muted: muted),
            ),
        ],
      ),
    );
  }
}

/// The name over "Field" / "Topic", and the switch. The screen reader hears "Mute {name}, Field, switch, on".
class _MuteToggle extends StatelessWidget {
  const _MuteToggle({
    super.key,
    required this.kind,
    required this.name,
    required this.mutedIn,
    required this.pendingKey,
    required this.onChanged,
  });

  final String kind;
  final FieldRef name;
  final bool Function(MutesState state) mutedIn;
  final String pendingKey;
  final Future<Failure?> Function(MutesCubit cubit, bool muted) onChanged;

  Future<void> _toggle(BuildContext context, bool muted) async {
    final failure = await onChanged(context.read<MutesCubit>(), muted);
    if (context.mounted) showActionFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (muted, pending) = context.select((MutesCubit c) => (mutedIn(c.state), c.state.isPending(pendingKey)));
    final text = name.nameFor(Localizations.localeOf(context).languageCode);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: muted,
      onChanged: pending ? null : (value) => unawaited(_toggle(context, value)),
      secondary: Icon(muted ? Icons.volume_off_outlined : Icons.volume_up_outlined, color: colors.textSecondary),
      title: Text(
        Bidi.isolateOppositeRuns(text, Directionality.of(context)),
        semanticsLabel: l10n.muteTopicsToggle(text),
        style: context.textTheme.titleSmall,
      ),
      subtitle: Text(kind, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
    );
  }
}

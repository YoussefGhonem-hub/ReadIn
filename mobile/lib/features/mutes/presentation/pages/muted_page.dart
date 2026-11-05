import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/field_style.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../profile/presentation/widgets/profile_link.dart';
import '../../../settings/presentation/widgets/settings_block.dart';
import '../../domain/entities/mutes.dart';
import '../cubit/muted_list_cubit.dart';
import '../cubit/mutes_cubit.dart';

/// Settings → Muted (F18, F28): one list of the writers, fields and topics the viewer muted, each with "إلغاء الكتم".
class MutedPage extends StatelessWidget {
  const MutedPage({super.key});

  /// The web's path. It needs an account: the router sends guests away, as from Your interests.
  static const path = '/settings/muted';

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => getIt<MutedListCubit>()..load(), child: const MutedView());
}

/// The page once its [MutedListCubit] is provided (and the app's [MutesCubit]).
class MutedView extends StatelessWidget {
  const MutedView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<MutedListCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mutePageTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Under the title, as on the web: what a mute does, and that it's private. A white strip under the bar.
          PageBlock(
            padding: const EdgeInsets.fromLTRB(PageBlock.gutter, ReadInSpace.s3, PageBlock.gutter, ReadInSpace.s3),
            child: Text(
              l10n.mutePageSubtitle,
              key: const ValueKey('muted-subtitle'),
              style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
            ),
          ),
          // Settings' look: writers, fields and topics each a white block on the canvas, rows split by dividers.
          Expanded(
            child: BlocBuilder<MutedListCubit, MutedListState>(
              builder: (context, state) => switch (state.status) {
                MutedListStatus.loading => ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [PageBlock(margin: EdgeInsets.only(top: PageBlock.gap), child: _RowsSkeleton())],
                  ),
                MutedListStatus.failure => PageBlock(
                    margin: const EdgeInsets.only(top: PageBlock.gap),
                    child: ErrorView(failure: state.failure!, onRetry: cubit.load),
                  ),
                MutedListStatus.ready when state.mutes.isEmpty => PageBlock(
                    margin: const EdgeInsets.only(top: PageBlock.gap),
                    child: EmptyView(
                      icon: Icons.volume_off_outlined,
                      title: l10n.mutePageEmptyTitle,
                      body: l10n.mutePageEmptyBody,
                    ),
                  ),
                MutedListStatus.ready => RefreshIndicator(
                    onRefresh: cubit.load,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: ReadInSpace.s6),
                      children: [
                        if (state.mutes.users.isNotEmpty)
                          SettingsBlock(
                            title: l10n.mutePageWriters,
                            rows: [
                              for (final user in state.mutes.users) _MutedWriterRow(key: ValueKey('muted-user-${user.id}'), user: user),
                            ],
                          ),
                        if (state.mutes.fields.isNotEmpty)
                          SettingsBlock(
                            title: l10n.mutePageFields,
                            rows: [
                              for (final field in state.mutes.fields)
                                _MutedFieldRow(key: ValueKey('muted-field-${field.id}'), field: field),
                            ],
                          ),
                        if (state.mutes.topics.isNotEmpty)
                          SettingsBlock(
                            title: l10n.mutePageTopics,
                            rows: [
                              for (final topic in state.mutes.topics)
                                _MutedTopicRow(key: ValueKey('muted-topic-${topic.id}'), topic: topic),
                            ],
                          ),
                      ],
                    ),
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "إلغاء الكتم" for one row: off while its request runs; a refusal says why and the row stays.
class _UnmuteButton extends StatelessWidget {
  const _UnmuteButton({required this.name, required this.pendingKey, required this.onPressed});

  final String name;
  final String pendingKey;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pending = context.select((MutesCubit c) => c.state.isPending(pendingKey));
    return Semantics(
      button: true,
      label: l10n.muteUnmuteName(name),
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: pending ? null : () => unawaited(onPressed()),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3),
          foregroundColor: context.colors.textPrimary,
          side: BorderSide(color: context.colors.border),
        ),
        child: Text(l10n.muteUnmute),
      ),
    );
  }
}

class _MutedWriterRow extends StatelessWidget {
  const _MutedWriterRow({super.key, required this.user});

  final UserSummary user;

  Future<void> _unmute(BuildContext context) async {
    final failure = await context.read<MutedListCubit>().unmuteUser(user.id);
    if (!context.mounted) return;
    if (failure != null) return showActionFailure(context, failure);
    showActionMessage(context, context.l10n.muteUnmuted('${Bidi.fsi}${user.displayName}${Bidi.pdi}'));
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
        child: Row(
          children: [
            Expanded(
              child: ProfileLink(
                username: user.username,
                child: Row(
                  children: [
                    UserAvatar(name: user.displayName, url: user.avatarUrl, size: 44),
                    const SizedBox(width: ReadInSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: BidiText(
                                  user.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.labelLarge,
                                ),
                              ),
                              if (user.isVerified) ...[const SizedBox(width: 4), const VerifiedMark()],
                            ],
                          ),
                          Text(Bidi.ltrIsolate('@${user.username}'), maxLines: 1, style: context.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: ReadInSpace.s2),
            _UnmuteButton(name: user.displayName, pendingKey: 'user:${user.id}', onPressed: () => _unmute(context)),
          ],
        ),
      );
}

/// A field's icon in its color, its name and an optional line under it.
class _ContentRow extends StatelessWidget {
  const _ContentRow({required this.field, required this.name, this.subtitle, required this.button});

  final MutedField field;
  final String name;
  final String? subtitle;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = FieldStyle.color(colors, field.color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(ReadInRadius.md)),
            child: Icon(FieldStyle.icon(field.icon), color: color, size: 22),
          ),
          const SizedBox(width: ReadInSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BidiText(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.labelLarge),
                if (subtitle case final line?)
                  BidiText(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: ReadInSpace.s2),
          button,
        ],
      ),
    );
  }
}

class _MutedFieldRow extends StatelessWidget {
  const _MutedFieldRow({super.key, required this.field});

  final MutedField field;

  @override
  Widget build(BuildContext context) {
    final name = field.nameFor(Localizations.localeOf(context).languageCode);
    return _ContentRow(
      field: field,
      name: name,
      button: _UnmuteButton(
        name: name,
        pendingKey: 'field:${field.id}',
        onPressed: () => _unmuteContent(context, name, context.read<MutedListCubit>().unmuteField(field.id)),
      ),
    );
  }
}

class _MutedTopicRow extends StatelessWidget {
  const _MutedTopicRow({super.key, required this.topic});

  final MutedTopic topic;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final name = topic.nameFor(lang);
    return _ContentRow(
      field: topic.field,
      name: name,
      subtitle: context.l10n.mutePageTopicIn(topic.field.nameFor(lang)),
      button: _UnmuteButton(
        name: name,
        pendingKey: 'topic:${topic.id}',
        onPressed: () => _unmuteContent(context, name, context.read<MutedListCubit>().unmuteTopic(topic.id)),
      ),
    );
  }
}

/// Waits for a field or topic unmute and confirms it, or says why it failed.
Future<void> _unmuteContent(BuildContext context, String name, Future<Failure?> request) async {
  final failure = await request;
  if (!context.mounted) return;
  if (failure != null) return showActionFailure(context, failure);
  showActionMessage(context, context.l10n.muteUnmuted('${Bidi.fsi}$name${Bidi.pdi}'));
}

class _RowsSkeleton extends StatelessWidget {
  const _RowsSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s3),
        child: Column(
          children: [
            for (var i = 0; i < 5; i++)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: ReadInSpace.s2),
                child: Row(
                  children: [
                    SkeletonBox(width: 44, height: 44, radius: 22),
                    SizedBox(width: ReadInSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [SkeletonBox(width: 130), SizedBox(height: ReadInSpace.s2), SkeletonBox(width: 90, height: 12)],
                      ),
                    ),
                    SkeletonBox(width: 84, height: 36, radius: ReadInRadius.chip),
                  ],
                ),
              ),
          ],
        ),
      );
}

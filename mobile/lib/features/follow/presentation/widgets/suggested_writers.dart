import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../profile/presentation/widgets/profile_link.dart';
import '../../domain/entities/follow.dart';
import '../cubit/suggested_writers_cubit.dart';
import 'follow_button.dart';

/// "Writers you might like", each with a follow button (F12). Needs a [SuggestedWritersCubit] above it; loads it the
/// first time it is shown.
class SuggestedWritersList extends StatefulWidget {
  const SuggestedWritersList({super.key});

  @override
  State<SuggestedWritersList> createState() => _SuggestedWritersListState();
}

class _SuggestedWritersListState extends State<SuggestedWritersList> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<SuggestedWritersCubit>().ensureLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<SuggestedWritersCubit, SuggestedWritersState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.suggestedWriters, style: context.textTheme.titleMedium)),
          const SizedBox(height: ReadInSpace.s2),
          switch (state.status) {
            SuggestedWritersStatus.loading => const _WritersSkeleton(),
            SuggestedWritersStatus.failure => ErrorView(
                failure: state.failure!,
                compact: true,
                onRetry: context.read<SuggestedWritersCubit>().load,
              ),
            SuggestedWritersStatus.ready when state.users.isEmpty => Padding(
                padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
                child: Text(l10n.suggestedWritersEmpty, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
              ),
            // One row each, split by dividers.
            SuggestedWritersStatus.ready => Column(
                children: [
                  for (final (i, user) in state.users.indexed) ...[if (i > 0) const Divider(), WriterTile(user: user)],
                ],
              ),
          },
        ],
      ),
    );
  }
}

/// Avatar, name, @handle, a line of bio, "follows you" and the follow button. The person opens their profile (F14).
class WriterTile extends StatelessWidget {
  const WriterTile({super.key, required this.user, this.onOpen});

  final UserSummary user;

  /// Runs before the profile opens, e.g. search remembering the query (F16).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meta = context.textTheme.bodySmall;
    final bio = user.bio?.trim() ?? '';
    final bioDir = Bidi.detect(bio) ?? Directionality.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
      child: Row(
        children: [
          Expanded(
            child: ProfileLink(
              username: user.username,
              beforeOpen: onOpen,
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
                        Wrap(
                          spacing: ReadInSpace.s2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(Bidi.ltrIsolate('@${user.username}'), style: meta),
                            if (user.followsYou)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  context.l10n.followsYou,
                                  style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondary),
                                ),
                              ),
                          ],
                        ),
                        if (bio.isNotEmpty)
                          Text(
                            Bidi.isolateOppositeRuns(bio, bioDir),
                            textDirection: bioDir,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: meta,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: ReadInSpace.s2),
          FollowButton(userId: user.id, name: user.displayName, initiallyFollowing: user.isFollowing, dense: true),
        ],
      ),
    );
  }
}

class _WritersSkeleton extends StatelessWidget {
  const _WritersSkeleton();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < 3; i++)
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
      );
}

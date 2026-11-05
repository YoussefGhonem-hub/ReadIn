import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../cubit/mutes_cubit.dart';
import 'mute_actions.dart';

/// "انت كاتم الكاتب ده" with "إلغاء الكتم" (F28), on a muted writer's article (the reader) and profile: a direct link
/// still opens, so the viewer can unmute from here. Follows [MutesCubit], so muting from the reader's menu shows it at
/// once and unmuting hides it. Nothing while the writer isn't muted.
class MutedWriterBanner extends StatelessWidget {
  const MutedWriterBanner({
    super.key,
    required this.userId,
    required this.name,
    required this.initiallyMuted,
    this.padding = EdgeInsets.zero,
  });

  final String userId;

  /// The writer's display name, for the confirmation and the screen reader.
  final String name;

  /// What the screen loaded (`isAuthorMuted`, `ProfileDto.isMuted`) until [MutesCubit] knows better.
  final bool initiallyMuted;

  /// Around the banner when it shows.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final (muted, pending) = context.select(
      (MutesCubit? c) => (
        c?.state.isUserMuted(userId, fallback: initiallyMuted) ?? initiallyMuted,
        c?.state.isPending('user:$userId') ?? false,
      ),
    );
    if (!muted) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: padding,
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s3, ReadInSpace.s3, ReadInSpace.s2, ReadInSpace.s2),
          decoration: BoxDecoration(
            color: colors.calloutInfo,
            borderRadius: BorderRadius.circular(ReadInRadius.md),
            border: BorderDirectional(start: BorderSide(color: colors.calloutInfoAccent, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.volume_off_outlined, size: 20, color: colors.calloutInfoAccent),
              const SizedBox(width: ReadInSpace.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.muteBannerTitle, style: context.textTheme.titleSmall?.copyWith(color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(l10n.muteBannerBody, style: context.textTheme.bodySmall?.copyWith(color: colors.textPrimary)),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Semantics(
                        button: true,
                        label: l10n.muteUnmuteName(name),
                        excludeSemantics: true,
                        child: TextButton(
                          key: const ValueKey('muted-writer-unmute'),
                          onPressed: pending ? null : () => unawaited(MuteActions.unmuteAuthor(context, userId: userId, name: name)),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 44),
                            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2),
                          ),
                          child: Text(l10n.muteUnmute),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

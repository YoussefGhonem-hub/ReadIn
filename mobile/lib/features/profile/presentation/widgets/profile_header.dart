import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/utils/link_opener.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../follow/presentation/widgets/follow_button.dart';
import '../../domain/entities/profile.dart';
import '../profile_routes.dart';
import 'platform_icon.dart';

/// Counters on profiles: the exact number up to 9,999, then compact ("12.5K" / "12.5 ألف"), Western digits.
String formatProfileCount(int value, String languageCode) => westernDigits(
      value < 10000 ? NumberFormat.decimalPattern(languageCode).format(value) : NumberFormat.compact(locale: languageCode).format(value),
    );

/// Bio, names and other user-written text: their own direction, opposite-script runs isolated (SPEC §14.2).
class ProfileBioText extends StatelessWidget {
  const ProfileBioText(this.text, {super.key, this.style, this.maxLines});

  final String text;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final direction = Bidi.detect(text) ?? Directionality.of(context);
    return Text(
      Bidi.isolateOppositeRuns(text, direction),
      textDirection: direction,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: style,
    );
  }
}

/// `@handle`, always left to right (SPEC §14.2), even inside Arabic.
class UsernameText extends StatelessWidget {
  const UsernameText(this.username, {super.key, this.style});

  final String username;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text('@$username', textDirection: TextDirection.ltr, style: style);
}

/// "Follows you".
class FollowsYouChip extends StatelessWidget {
  const FollowsYouChip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: 2),
      decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
      child: Text(context.l10n.followsYou, style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondary)),
    );
  }
}

/// Avatar, name, verified badge, the title (in full), `@username`, "Follows you", bio, links, the follow / edit button
/// and the stats row.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile, this.onEdit});

  final UserProfile profile;

  /// "Edit profile" on the viewer's own profile.
  final VoidCallback? onEdit;

  static const avatarSize = 80.0;

  /// The title line (tests find it by this key).
  static const headlineKey = ValueKey('profile-headline');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final bio = profile.bio;
    final headline = profile.headline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, ReadInSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: UserAvatar(name: profile.displayName, url: profile.avatarFor(avatarSize * 2), size: avatarSize)),
              const SizedBox(width: ReadInSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Row(
                        children: [
                          Flexible(child: BidiText(profile.displayName, style: context.textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis)),
                          if (profile.isVerified) ...[const SizedBox(width: 6), const VerifiedMark(size: 18)],
                        ],
                      ),
                    ),
                    // The title in full, wrapped, in its own direction (F14); none, no line.
                    if (headline != null) ...[
                      const SizedBox(height: 2),
                      ProfileBioText(
                        headline,
                        key: headlineKey,
                        style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 2),
                    UsernameText(profile.username, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
                    if (profile.followsYou) ...[const SizedBox(height: ReadInSpace.s2), const FollowsYouChip()],
                  ],
                ),
              ),
            ],
          ),
          if (bio != null) ...[
            const SizedBox(height: ReadInSpace.s3),
            ProfileBioText(bio, maxLines: 4, style: context.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
          if (profile.links.isNotEmpty) ...[
            const SizedBox(height: ReadInSpace.s2),
            ProfileLinksRow(links: profile.links),
          ],
          const SizedBox(height: ReadInSpace.s4),
          if (profile.isMe)
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(l10n.editProfile),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            )
          else
            SizedBox(
              height: 48,
              child: FollowButton(userId: profile.id, name: profile.displayName, initiallyFollowing: profile.isFollowing),
            ),
          const SizedBox(height: ReadInSpace.s4),
          ProfileStatsRow(profile: profile),
        ],
      ),
    );
  }
}

/// The social links (F14) as a row of icons in the member's order, for everyone including guests. Each is a link
/// named after its platform (or the label of an Other link) that opens in the system browser or the platform's app.
/// The row keeps its order in RTL but the marks never mirror.
class ProfileLinksRow extends StatelessWidget {
  const ProfileLinksRow({super.key, required this.links, this.onOpen = openExternalLink});

  final List<ProfileLink> links;

  /// Opens a link; tests replace it.
  final Future<bool> Function(String url) onOpen;

  static Key keyOf(int index) => ValueKey('profile-link-$index');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Wrap(
      spacing: ReadInSpace.s1,
      runSpacing: ReadInSpace.s1,
      children: [
        for (final (i, link) in links.indexed)
          Builder(builder: (context) {
            final name = linkPlatformName(l10n, link.platform, label: link.label);
            return Semantics(
              key: keyOf(i),
              link: true,
              label: name,
              onTap: () => onOpen(link.url),
              excludeSemantics: true,
              child: IconButton(
                tooltip: name,
                onPressed: () => onOpen(link.url),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: colors.surfaceVariant,
                  foregroundColor: colors.textPrimary,
                ),
                icon: PlatformIcon(link.platform, size: 20, color: colors.textPrimary),
              ),
            );
          }),
      ],
    );
  }
}

/// Articles · followers · following · total reads. Followers and following open the lists.
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final stats = profile.stats;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ReadInRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _StatTile(value: stats.articles, label: l10n.profileStatArticles)),
          Expanded(
            child: _StatTile(
              value: stats.followers,
              label: l10n.profileStatFollowers,
              onTap: () => openFollowList(context, profile, following: false),
            ),
          ),
          Expanded(
            child: _StatTile(
              value: stats.following,
              label: l10n.profileStatFollowing,
              onTap: () => openFollowList(context, profile, following: true),
            ),
          ),
          Expanded(child: _StatTile(value: stats.totalReads, label: l10n.profileStatReads)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.onTap});

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final text = formatProfileCount(value, lang);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3, horizontal: ReadInSpace.s1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1),
            const SizedBox(height: 2),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: onTap != null,
      label: context.l10n.profileStatSemantics(label, text),
      excludeSemantics: true,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(ReadInRadius.card), child: content),
    );
  }
}

/// Header placeholder while the profile loads.
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, ReadInSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SkeletonBox(width: ProfileHeader.avatarSize, height: ProfileHeader.avatarSize, radius: ProfileHeader.avatarSize / 2),
                SizedBox(width: ReadInSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [SkeletonBox(width: 160, height: 20), SizedBox(height: ReadInSpace.s2), SkeletonBox(width: 90)],
                  ),
                ),
              ],
            ),
            SizedBox(height: ReadInSpace.s4),
            SkeletonBox(),
            SizedBox(height: ReadInSpace.s2),
            SkeletonBox(width: 220),
            SizedBox(height: ReadInSpace.s4),
            SkeletonBox(height: 48, radius: ReadInRadius.chip),
            SizedBox(height: ReadInSpace.s4),
            SkeletonBox(height: 64, radius: ReadInRadius.card),
          ],
        ),
      );
}

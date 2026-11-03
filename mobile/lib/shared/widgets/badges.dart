import 'package:flutter/material.dart';

import '../../core/bidi/bidi.dart';
import '../../core/l10n/l10n_x.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens.g.dart';
import 'app_network_image.dart';

/// 🔥 streak pill (accent tokens). Streak data arrives with F08 (Phase 2).
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: context.l10n.streakSemantics(days),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: 6),
        decoration: BoxDecoration(color: colors.accentContainer, borderRadius: BorderRadius.circular(ReadInRadius.chip)),
        child: Text(
          '🔥 ${context.l10n.streakDays(days)}',
          style: context.textTheme.labelMedium?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Small rounded tag: field name, version badge, "Reviewed", "AI-assisted".
class InfoTag extends StatelessWidget {
  const InfoTag({super.key, required this.label, this.icon, this.tone = InfoTagTone.primary});

  final String label;
  final IconData? icon;
  final InfoTagTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg) = switch (tone) {
      InfoTagTone.primary => (colors.primaryContainer, colors.onPrimaryContainer),
      InfoTagTone.success => (colors.calloutTip, colors.success),
      InfoTagTone.accent => (colors.accentContainer, colors.textPrimary),
      InfoTagTone.neutral => (colors.surfaceVariant, colors.textSecondary),
    };
    final dir = Directionality.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Text(
            Bidi.isolateOppositeRuns(label, dir),
            style: context.textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

enum InfoTagTone { primary, success, accent, neutral }

/// ✓ next to verified writers (VerifiedWriter role).
class VerifiedMark extends StatelessWidget {
  const VerifiedMark({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: context.l10n.verifiedWriter,
        child: Icon(Icons.verified_rounded, size: size, color: context.colors.success, semanticLabel: context.l10n.verifiedWriter),
      );
}

/// Initial-letter avatar (or photo), with a subtle border in dark mode.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.url, this.size = 32});

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primaryContainer,
        border: context.isDark ? Border.all(color: colors.border) : null,
        // Same disk-cached provider (and test seam) as every other network image.
        image: url == null ? null : DecorationImage(image: AppNetworkImage.providerFactory(url!), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: url == null
          ? Text(
              initial,
              style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: size * 0.4),
            )
          : null,
    );
  }
}

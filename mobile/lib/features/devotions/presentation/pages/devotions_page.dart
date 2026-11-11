import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/entities/devotions.dart';
import '../devotions_routes.dart';

/// «الركن الخاص» (F38): the SuperAdmin's private corner. Two surahs, the morning and evening adhkar, and their own
/// du'as, one card each.
class DevotionsPage extends StatelessWidget {
  const DevotionsPage({super.key});

  static String surahName(AppLocalizations l10n, int number) =>
      number == 36 ? l10n.devotionsSurahYasin : l10n.devotionsSurahWaqiah;

  /// The number of ayat, from the assets (Ya-Sin 83, Al-Waqi'ah 96).
  static const _ayat = {36: 83, 56: 96};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cards = [
      for (final number in DevotionsRoutes.surahs)
        _Card(
          key: ValueKey('devotions-surah-$number'),
          icon: Icons.menu_book_rounded,
          title: surahName(l10n, number),
          subtitle: l10n.devotionsAyat(_ayat[number]!),
          location: DevotionsRoutes.surah(number),
        ),
      _Card(
        key: const ValueKey('devotions-morning'),
        icon: Icons.wb_sunny_outlined,
        title: l10n.devotionsMorning,
        location: DevotionsRoutes.adhkar(AdhkarSession.morning),
      ),
      _Card(
        key: const ValueKey('devotions-evening'),
        icon: Icons.nights_stay_outlined,
        title: l10n.devotionsEvening,
        location: DevotionsRoutes.adhkar(AdhkarSession.evening),
      ),
      _Card(
        key: const ValueKey('devotions-duas'),
        icon: Icons.volunteer_activism_outlined,
        title: l10n.devotionsDuas,
        subtitle: l10n.devotionsDuasHint,
        location: DevotionsRoutes.duas,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.devotionsTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(ReadInSpace.s4),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(height: ReadInSpace.s3),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.icon, required this.title, this.subtitle, required this.location});

  final IconData icon;
  final String title;
  final String? subtitle;
  final String location;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ReadInRadius.card),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4, vertical: ReadInSpace.s2),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: context.textTheme.titleMedium),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => unawaited(context.push<void>(location)),
      ),
    );
  }
}

/// Settings' row for the private corner, shown only with `devotions.access` (F38).
class DevotionsEntryTile extends StatelessWidget {
  const DevotionsEntryTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      key: const ValueKey('settings-devotions'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.auto_stories_outlined),
      title: Text(l10n.devotionsTitle),
      subtitle: Text(
        l10n.devotionsEntryHint,
        style: context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => unawaited(context.push<void>(DevotionsRoutes.home)),
    );
  }
}

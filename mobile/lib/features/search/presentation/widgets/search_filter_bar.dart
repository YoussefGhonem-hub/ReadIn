import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../domain/entities/search.dart';
import '../cubit/search_cubit.dart';

/// The Articles tab's filters (F16): field, article language and reading time, each a chip that opens its choices,
/// and "Clear filters" once one is set. Needs a [SearchCubit] above.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key});

  static const height = 56.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final (filters, fields) = context.select((SearchCubit c) => (c.state.filters, c.state.fields));
    final cubit = context.read<SearchCubit>();

    final fieldLabel = switch (filters.fieldSlug) {
      null => null,
      final slug => fields.where((f) => f.slug == slug).firstOrNull?.nameFor(lang) ?? slug,
    };
    final languageLabel = switch (filters.language) {
      SearchLanguages.arabic => l10n.articleVersionArabic,
      SearchLanguages.english => l10n.articleVersionEnglish,
      _ => null,
    };
    final readingTimeLabel = filters.readingTime == ReadingTimeFilter.any ? null : readingTimeText(l10n, filters.readingTime);

    Future<void> pickField() async {
      final picked = await _pickOption<String?>(
        context,
        title: l10n.searchFilterField,
        selected: filters.fieldSlug,
        options: [(null, l10n.searchFieldAll), for (final field in fields) (field.slug, field.nameFor(lang))],
      );
      if (picked case (final slug,)) cubit.setFilters(filters.copyWith(fieldSlug: () => slug));
    }

    Future<void> pickLanguage() async {
      final picked = await _pickOption<String?>(
        context,
        title: l10n.searchFilterLanguage,
        selected: filters.language,
        options: [
          (null, l10n.searchLanguageAny),
          (SearchLanguages.arabic, l10n.articleVersionArabic),
          (SearchLanguages.english, l10n.articleVersionEnglish),
        ],
      );
      if (picked case (final language,)) cubit.setFilters(filters.copyWith(language: () => language));
    }

    Future<void> pickReadingTime() async {
      final picked = await _pickOption<ReadingTimeFilter>(
        context,
        title: l10n.searchFilterReadingTime,
        selected: filters.readingTime,
        options: [for (final value in ReadingTimeFilter.values) (value, readingTimeText(l10n, value))],
      );
      if (picked case (final readingTime,)) cubit.setFilters(filters.copyWith(readingTime: readingTime));
    }

    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5, vertical: ReadInSpace.s2),
        children: [
          // Without the fields (still loading, or offline) there is nothing to choose from.
          if (fields.isNotEmpty || fieldLabel != null)
            _FilterChip(
              key: const ValueKey('search-filter-field'),
              name: l10n.searchFilterField,
              value: fieldLabel,
              onTap: () => unawaited(pickField()),
            ),
          _FilterChip(
            key: const ValueKey('search-filter-language'),
            name: l10n.searchFilterLanguage,
            value: languageLabel,
            onTap: () => unawaited(pickLanguage()),
          ),
          _FilterChip(
            key: const ValueKey('search-filter-reading-time'),
            name: l10n.searchFilterReadingTime,
            value: readingTimeLabel,
            onTap: () => unawaited(pickReadingTime()),
          ),
          if (!filters.isEmpty)
            IconButton(
              key: const ValueKey('search-filter-clear'),
              tooltip: l10n.searchClearFilters,
              icon: Icon(Icons.filter_alt_off_outlined, color: context.colors.primary),
              onPressed: () => cubit.setFilters(const ArticleSearchFilters()),
            ),
        ],
      ),
    );
  }
}

/// A reading-time choice as the chips and the sheet show it.
String readingTimeText(AppLocalizations l10n, ReadingTimeFilter value) => switch (value) {
      ReadingTimeFilter.any => l10n.searchReadingTimeAny,
      ReadingTimeFilter.upTo5 => l10n.searchReadingTimeUpTo5,
      ReadingTimeFilter.from5To10 => l10n.searchReadingTime5To10,
      ReadingTimeFilter.over10 => l10n.searchReadingTimeOver10,
    };

/// A filter: its [name] while unset, its [value] once set (highlighted), and a drop-down arrow.
class _FilterChip extends StatelessWidget {
  const _FilterChip({super.key, required this.name, required this.value, required this.onTap});

  final String name;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = value != null;
    final foreground = active ? colors.onPrimaryContainer : colors.textSecondary;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s2),
      child: Semantics(
        button: true,
        selected: active,
        label: active ? context.l10n.searchFilterValue(name, value!) : name,
        excludeSemantics: true,
        onTap: onTap,
        child: FilterChip(
          selected: active,
          showCheckmark: false,
          onSelected: (_) => onTap(),
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s1, vertical: ReadInSpace.s2),
          labelPadding: const EdgeInsetsDirectional.only(start: ReadInSpace.s2),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BidiText(
                value ?? name,
                style: context.textTheme.labelMedium?.copyWith(color: foreground, fontWeight: active ? FontWeight.w600 : FontWeight.w500),
              ),
              Icon(Icons.arrow_drop_down_rounded, size: 20, color: foreground),
            ],
          ),
          side: BorderSide(color: active ? colors.primary : colors.border),
        ),
      ),
    );
  }
}

/// The choices of one filter in a sheet, the current one checked. A record, so "any" (null) differs from closing the
/// sheet (no record).
Future<(T,)?> _pickOption<T>(
  BuildContext context, {
  required String title,
  required T selected,
  required List<(T, String)> options,
}) =>
    showModalBottomSheet<(T,)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final colors = context.colors;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s2),
                child: Semantics(header: true, child: Text(title, style: context.textTheme.titleMedium)),
              ),
              for (final (value, label) in options)
                ListTile(
                  title: BidiText(label),
                  selected: value == selected,
                  selectedColor: colors.primary,
                  trailing: value == selected ? Icon(Icons.check_rounded, color: colors.primary) : null,
                  onTap: () => Navigator.of(context).pop((value,)),
                ),
            ],
          ),
        );
      },
    );

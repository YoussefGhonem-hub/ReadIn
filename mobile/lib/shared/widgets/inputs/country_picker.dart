import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_x.dart';
import '../../../core/phone/countries.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens.g.dart';
import 'country_flag.dart';

/// Full-height bottom sheet to pick the phone number's country (SPEC §9.4): pinned countries first, then the rest by
/// name in the UI language; searchable by Arabic name, English name, ISO code and dial code.
Future<Country?> showCountryPicker(BuildContext context, {Country? selected}) => showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.95, child: CountryPickerSheet(selected: selected)),
    );

class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet({super.key, this.selected});

  final Country? selected;

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final query = _query.text.trim();
    final countries = Countries.search(query, lang);
    final pinnedCount = query.isEmpty ? Countries.pinned.length : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s3, ReadInSpace.s2),
          child: Row(
            children: [
              Expanded(child: Semantics(header: true, child: Text(l10n.countryPickerTitle, style: context.textTheme.titleLarge))),
              IconButton(
                tooltip: l10n.close,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5),
          child: TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.countrySearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.cancel,
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(_query.clear),
                    ),
            ),
          ),
        ),
        const SizedBox(height: ReadInSpace.s2),
        Expanded(
          child: countries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(ReadInSpace.s5),
                    child: Text(
                      l10n.countryNoResults,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: countries.length,
                  separatorBuilder: (_, index) => index == pinnedCount - 1
                      ? const Divider(height: ReadInSpace.s4, indent: ReadInSpace.s5, endIndent: ReadInSpace.s5)
                      : const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    return CountryTile(
                      country: country,
                      selected: country == widget.selected,
                      onTap: () => Navigator.of(context).pop(country),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// One row of the picker: flag, name in the UI language, dial code (LTR) and a check on the selected country.
class CountryTile extends StatelessWidget {
  const CountryTile({super.key, required this.country, required this.onTap, this.selected = false});

  final Country country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final colors = context.colors;
    return Semantics(
      selected: selected,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5),
        leading: CountryFlagIcon(country.iso2),
        title: Text(country.name(lang)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+${country.dialCode}',
              textDirection: TextDirection.ltr,
              style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary, fontFamily: ReadInFonts.latin),
            ),
            if (selected) ...[
              const SizedBox(width: ReadInSpace.s2),
              Icon(Icons.check_rounded, color: colors.primary, semanticLabel: context.l10n.selected),
            ],
          ],
        ),
      ),
    );
  }
}

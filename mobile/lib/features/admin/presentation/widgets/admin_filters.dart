import 'dart:async';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../taxonomy/domain/usecases/taxonomy_usecases.dart';
import '../../domain/entities/paged_list.dart';

/// The date-range picker of the console's period filters, behind a seam so widget tests can answer it.
abstract final class AdminDatePicker {
  static Future<DateTimeRange?> Function(BuildContext context, DateTimeRange? initial) pickRange = _pick;

  static Future<DateTimeRange?> _pick(BuildContext context, DateTimeRange? initial) {
    final today = DateUtils.dateOnly(DateTime.now());
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: today,
      initialDateRange: initial,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
  }
}

/// `YYYY-MM-DD` dates of a picked range (calendar days, as the API reads them in `Admin:TimeZone`).
({String from, String to}) adminRange(DateTimeRange range) => (from: adminDate(range.start), to: adminDate(range.end));

/// The range a `YYYY-MM-DD` pair stands for, to open the picker on it; null when either is missing or malformed.
DateTimeRange? adminRangeOf(String? from, String? to) {
  final start = from == null ? null : DateTime.tryParse(from);
  final end = to == null ? null : DateTime.tryParse(to);
  if (start == null || end == null || end.isBefore(start)) return null;
  return DateTimeRange(start: start, end: end);
}

/// "2026-11-01 to 2026-11-07", the dates kept left to right.
String adminRangeLabel(AppLocalizations l10n, String? from, String? to) =>
    l10n.adminPeriodRange(Bidi.ltrIsolate(from ?? '…'), Bidi.ltrIsolate(to ?? '…'));

/// One choice of a filter sheet: an id and its name in the UI language.
typedef AdminChoice = ({String id, String label});

/// The fields and topics Content can filter on: the app's taxonomy (enabled fields, in display order), names in the
/// UI language.
@injectable
class AdminTaxonomyChoices {
  const AdminTaxonomyChoices(this._fields, this._topics);

  final GetFields _fields;
  final GetTopics _topics;

  Future<Result<List<AdminChoice>>> fields(String languageCode) async => switch (await _fields()) {
        Ok(value: final fields) => Ok([for (final f in fields) (id: f.id, label: f.nameFor(languageCode))]),
        Err(:final failure) => Err(failure),
      };

  /// The topics of the field [fieldId] (the API lists them by the field's slug).
  Future<Result<List<AdminChoice>>> topics(String fieldId, String languageCode) async {
    final fields = await _fields();
    if (fields case Err(:final failure)) return Err(failure);
    final field = fields.valueOrNull!.where((f) => f.id == fieldId).firstOrNull;
    if (field == null) return const Ok([]);
    return switch (await _topics(field.slug)) {
      Ok(value: final topics) => Ok([for (final t in topics) (id: t.id, label: t.nameFor(languageCode))]),
      Err(:final failure) => Err(failure),
    };
  }
}

/// A sheet of choices loaded by [load]: "All" first (picks null), then each choice, the [selected] one checked. Pops
/// with the choice, `(id: '', label: '')` for All, or null when dismissed.
Future<AdminChoice?> showAdminChoiceSheet(
  BuildContext context, {
  required String title,
  required String allLabel,
  required Future<Result<List<AdminChoice>>> Function() load,
  String? selected,
}) =>
    showModalBottomSheet<AdminChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _ChoiceSheet(title: title, allLabel: allLabel, load: load, selected: selected),
    );

/// What [showAdminChoiceSheet] returns for "All".
const AdminChoice adminChoiceAll = (id: '', label: '');

class _ChoiceSheet extends StatefulWidget {
  const _ChoiceSheet({required this.title, required this.allLabel, required this.load, this.selected});

  final String title;
  final String allLabel;
  final Future<Result<List<AdminChoice>>> Function() load;
  final String? selected;

  @override
  State<_ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends State<_ChoiceSheet> {
  late Future<Result<List<AdminChoice>>> _choices = widget.load();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget tile(AdminChoice choice, {required bool selected}) => ListTile(
          key: ValueKey('admin-choice-${choice.id.isEmpty ? 'all' : choice.id}'),
          title: BidiText(choice.id.isEmpty ? widget.allLabel : choice.label),
          trailing: selected ? Icon(Icons.check_rounded, color: colors.primary) : null,
          selected: selected,
          onTap: () => Navigator.of(context).pop(choice),
        );
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s2),
            child: Semantics(header: true, child: Text(widget.title, style: context.textTheme.titleLarge)),
          ),
          Flexible(
            child: FutureBuilder<Result<List<AdminChoice>>>(
              future: _choices,
              builder: (context, snapshot) {
                final result = snapshot.data;
                if (result == null) {
                  return const Padding(padding: EdgeInsets.all(ReadInSpace.s6), child: Center(child: CircularProgressIndicator()));
                }
                return switch (result) {
                  Err(:final failure) => ErrorView(
                      failure: failure,
                      compact: true,
                      onRetry: () => setState(() => _choices = widget.load()),
                    ),
                  Ok(value: final choices) => ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
                      children: [
                        tile(adminChoiceAll, selected: widget.selected == null),
                        for (final choice in choices) tile(choice, selected: choice.id == widget.selected),
                      ],
                    ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A chip that opens a picker: unselected, "Field…"; selected, its value with a ✕ that clears it.
class AdminPickerChip extends StatelessWidget {
  const AdminPickerChip({
    super.key,
    required this.label,
    required this.onPick,
    this.value,
    this.onClear,
  });

  /// "Field…", while nothing is chosen.
  final String label;

  /// What is chosen, e.g. ".NET"; null for nothing.
  final String? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s2),
        child: value == null
            ? ActionChip(label: Text(label), avatar: const Icon(Icons.arrow_drop_down_rounded, size: 18), onPressed: onPick)
            : InputChip(
                label: BidiText(value!),
                selected: true,
                showCheckmark: false,
                onPressed: onPick,
                onDeleted: onClear,
                deleteButtonTooltipMessage: context.l10n.adminRemoveFilter,
              ),
      );
}

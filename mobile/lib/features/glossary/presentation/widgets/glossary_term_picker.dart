import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../domain/entities/glossary_term.dart';
import '../cubit/glossary_search_cubit.dart';

/// What the writer did in the term picker.
sealed class TermPickerResult {
  const TermPickerResult();
}

/// Mark the words as the glossary term [slug] (the RDoc `termId`).
class TermPicked extends TermPickerResult {
  const TermPicked(this.slug);

  final String slug;
}

/// Turn the term back into plain words.
class TermRemoved extends TermPickerResult {
  const TermRemoved();
}

/// The editor's glossary term picker (F21): marks [text] (the selected words) as a glossary term, or changes or removes
/// the term [termId] the writer opened again. It searches the glossary for the words (or the term's id) at once.
/// Completes with null when dismissed.
Future<TermPickerResult?> showGlossaryTermPicker(
  BuildContext context, {
  required String text,
  String? termId,
  GlossarySearchCubit Function()? cubit,
}) =>
    showModalBottomSheet<TermPickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider(
        create: (_) => (cubit?.call() ?? getIt<GlossarySearchCubit>())..search(termId ?? text, now: true),
        child: GlossaryTermPickerView(text: text, termId: termId),
      ),
    );

/// The picker's content: the words being marked, the search field, the matches and the search's state.
class GlossaryTermPickerView extends StatefulWidget {
  const GlossaryTermPickerView({super.key, required this.text, this.termId});

  final String text;
  final String? termId;

  @override
  State<GlossaryTermPickerView> createState() => _GlossaryTermPickerViewState();
}

class _GlossaryTermPickerViewState extends State<GlossaryTermPickerView> {
  late final _query = TextEditingController(text: widget.termId ?? widget.text);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final state = context.watch<GlossarySearchCubit>().state;
    final secondary = context.textTheme.bodySmall?.copyWith(color: colors.textSecondary);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(header: true, child: Text(l10n.formatTerm, style: context.textTheme.titleMedium)),
                const SizedBox(height: ReadInSpace.s2),
                Text.rich(
                  key: const ValueKey('term-picker-for'),
                  TextSpan(
                    style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                    children: [
                      TextSpan(text: '${widget.termId == null ? l10n.termPickerFor : l10n.termPickerCurrent} '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: BidiText(widget.text, style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ReadInSpace.s3),
                TextField(
                  key: const ValueKey('term-search'),
                  controller: _query,
                  autofocus: true,
                  textDirection: TextDirection.ltr,
                  autocorrect: false,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.termSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                  onChanged: context.read<GlossarySearchCubit>().search,
                ),
              ],
            ),
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView(
                key: const ValueKey('term-results'),
                shrinkWrap: true,
                children: [
                  for (final term in state.results)
                    _TermRow(
                      term: term,
                      current: term.slug == widget.termId,
                      onTap: () => Navigator.of(context).pop(TermPicked(term.slug)),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, 0),
            child: Semantics(
              liveRegion: true,
              child: switch (state.status) {
                GlossarySearchStatus.loading => Text(l10n.termSearching, key: const ValueKey('term-status'), style: secondary),
                GlossarySearchStatus.failure => Row(
                    key: const ValueKey('term-status'),
                    children: [
                      Expanded(child: Text(l10n.termSearchError, style: secondary?.copyWith(color: colors.error))),
                      TextButton(onPressed: context.read<GlossarySearchCubit>().retry, child: Text(l10n.retry)),
                    ],
                  ),
                GlossarySearchStatus.idle => Text(l10n.termTypeToSearch, key: const ValueKey('term-status'), style: secondary),
                GlossarySearchStatus.ready => state.results.isEmpty
                    ? Text(l10n.termNoMatches, key: const ValueKey('term-status'), style: secondary)
                    : const SizedBox.shrink(),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: ReadInSpace.s2),
            child: Row(
              children: [
                if (widget.termId != null)
                  TextButton.icon(
                    key: const ValueKey('term-remove'),
                    onPressed: () => Navigator.of(context).pop(const TermRemoved()),
                    icon: const Icon(Icons.format_clear_rounded),
                    label: Text(l10n.termRemove),
                  ),
                const Spacer(),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A match: the English term over the start of its definition, both left to right.
class _TermRow extends StatelessWidget {
  const _TermRow({required this.term, required this.current, required this.onTap});

  final GlossaryTermSummary term;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      key: ValueKey('term-option-${term.slug}'),
      selected: current,
      selectedColor: colors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5),
      title: Text(term.term, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        term.definitionEn,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      ),
      trailing: current ? Icon(Icons.check_rounded, color: colors.primary) : null,
      onTap: onTap,
    );
  }
}

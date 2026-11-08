import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../moderation/presentation/widgets/moderation_widgets.dart' show moderationTime;
import '../cubit/admin_list_cubit.dart';

/// "3 hrs ago", "yesterday", then the date (the moderation clock, frozen in tests).
String adminTime(BuildContext context, DateTime at) => moderationTime(context, at);

/// A whole number with Western digits (SPEC §14.2) and thousands separators: "12,480".
String adminNumber(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// A local date and time with Western digits.
String adminDateTime(BuildContext context, DateTime at) => formatDateTime(at, Localizations.localeOf(context).languageCode);

/// A local date with Western digits.
String adminDay(BuildContext context, DateTime at) => formatDate(at, Localizations.localeOf(context).languageCode);

/// A console page for someone without its permission: they never get a link to it, but a pasted route or an old
/// push can land here (the API would answer `403` anyway).
class AdminNoAccessPage extends StatelessWidget {
  const AdminNoAccessPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyView(icon: Icons.lock_outline_rounded, title: l10n.adminNoAccessTitle, body: l10n.adminNoAccessBody),
    );
  }
}

/// The red count on an entry or a section: "99+" past 99; nothing for 0.
class AdminCountBadge extends StatelessWidget {
  const AdminCountBadge({super.key, required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final value = count ?? 0;
    if (value <= 0) return const SizedBox.shrink();
    final colors = context.colors;
    return Badge(
      label: Text(value > 99 ? '99+' : '$value'),
      backgroundColor: colors.error,
      textColor: colors.onError,
    );
  }
}

/// A section title inside a block, with an optional count: "Reports (3)".
class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: ReadInSpace.s2),
        child: Row(
          children: [
            Expanded(child: Semantics(header: true, child: Text(title, style: context.textTheme.titleMedium))),
            ?trailing,
          ],
        ),
      );
}

/// A label and its value on one line, the value at the end (numbers, dates, handles).
class AdminInfoRow extends StatelessWidget {
  const AdminInfoRow({super.key, required this.label, required this.value, this.ltr = false, this.trailing});

  final String label;
  final String value;

  /// Phone numbers, versions and handles stay left-to-right in the Arabic UI.
  final bool ltr;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(label, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary))),
          const SizedBox(width: ReadInSpace.s3),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: ltr ? TextDirection.ltr : null,
              style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: ReadInSpace.s2), trailing!],
        ],
      ),
    );
  }
}

/// A search box that searches when submitted, with a clear button.
class AdminSearchField extends StatefulWidget {
  const AdminSearchField({super.key, required this.hint, required this.onSearch, this.initial = ''});

  final String hint;
  final String initial;
  final ValueChanged<String> onSearch;

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      key: const ValueKey('admin-search'),
      controller: _controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (value) => widget.onSearch(value.trim()),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: l10n.adminSearchClear,
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _controller.clear();
                  widget.onSearch('');
                },
              ),
      ),
    );
  }
}

/// A paged console list once its [AdminListCubit] is provided: [header] (search, filters) on top, then skeleton, error
/// with retry, empty, pull to refresh, the rows of one page, and the page controls at the bottom ([AdminPager]).
class AdminPagedList<C extends AdminListCubit<T, Q>, T, Q> extends StatelessWidget {
  const AdminPagedList({
    super.key,
    required this.itemBuilder,
    required this.emptyTitle,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyBody,
    this.header,
    this.countLabel,
  });

  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyTitle;
  final String? emptyBody;
  final IconData emptyIcon;
  final Widget? header;

  /// "1,204 users": the total under the header.
  final String Function(int total)? countLabel;

  Future<void> _refresh(BuildContext context) async {
    final failure = await context.read<C>().refresh();
    if (context.mounted) showActionFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<C>();
    final colors = context.colors;
    Future<void> turn(Future<Failure?> Function() to) async {
      final failure = await to();
      if (context.mounted) showActionFailure(context, failure);
    }

    return BlocBuilder<C, AdminListState<T, Q>>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Material(
              color: colors.surface,
              child: Padding(padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, ReadInSpace.s2, ReadInSpace.s4, ReadInSpace.s2), child: header),
            ),
          if (countLabel != null && state.status == AdminListStatus.ready)
            Padding(
              padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, ReadInSpace.s2, ReadInSpace.s4, 0),
              child: Text(countLabel!(state.totalCount), style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary)),
            ),
          if (state.changingPage) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: switch (state.status) {
              AdminListStatus.loading => const AdminListSkeleton(),
              AdminListStatus.failure => ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.load())),
              AdminListStatus.ready when state.items.isEmpty => RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: constraints.maxHeight, child: EmptyView(icon: emptyIcon, title: emptyTitle, body: emptyBody)),
                    ),
                  ),
                ),
              AdminListStatus.ready => RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child: ListView.builder(
                    // A new page starts at its top.
                    key: PageStorageKey('admin-page-${state.page}'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: PageBlock.gap, bottom: ReadInSpace.s4),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) => itemBuilder(context, state.items[index]),
                  ),
                ),
            },
          ),
          if (state.status == AdminListStatus.ready && state.totalCount > 0)
            AdminPager(
              firstRow: state.firstRow,
              lastRow: state.lastRow,
              totalCount: state.totalCount,
              page: state.page,
              totalPages: state.totalPages,
              busy: state.changingPage,
              onPrevious: state.hasPrevious ? () => unawaited(turn(cubit.previousPage)) : null,
              onNext: state.hasNext ? () => unawaited(turn(cubit.nextPage)) : null,
            ),
        ],
      ),
    );
  }
}

/// The page controls under a console list: previous · "1–50 of 1,234" and "Page 1 of 25" · next. A button at an
/// edge (the first or the last page) is disabled.
class AdminPager extends StatelessWidget {
  const AdminPager({
    super.key,
    required this.firstRow,
    required this.lastRow,
    required this.totalCount,
    required this.page,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
    this.busy = false,
  });

  final int firstRow;
  final int lastRow;
  final int totalCount;
  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// A page is loading: both buttons wait.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Material(
      key: const ValueKey('admin-pager'),
      color: colors.surface,
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: ReadInSpace.s1),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('admin-page-previous'),
                tooltip: l10n.adminPagePrevious,
                // Mirrors in Arabic: "previous" points to the start side.
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: busy ? null : onPrevious,
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.adminPageRows(adminNumber(firstRow), adminNumber(lastRow), adminNumber(totalCount)),
                        key: const ValueKey('admin-page-rows'),
                        textAlign: TextAlign.center,
                        style: context.textTheme.labelLarge,
                      ),
                      Text(
                        l10n.adminPageOf(adminNumber(page), adminNumber(totalPages)),
                        key: const ValueKey('admin-page-of'),
                        textAlign: TextAlign.center,
                        style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('admin-page-next'),
                tooltip: l10n.adminPageNext,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: busy ? null : onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The end of a list while the next page loads, or "Couldn't load more" with retry.
class AdminLoadMoreRow extends StatelessWidget {
  const AdminLoadMoreRow({super.key, required this.failure, required this.onRetry});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(ReadInSpace.s4),
        child: Center(
          child: failure == null
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : Column(
                  children: [
                    Text(
                      context.l10n.moderationLoadMoreFailed,
                      style: context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
                    ),
                    TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
                  ],
                ),
        ),
      );
}

class AdminListSkeleton extends StatelessWidget {
  const AdminListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(ReadInSpace.s4),
        children: [
          for (var i = 0; i < 5; i++) ...[
            const Row(
              children: [
                SkeletonBox(width: 40, height: 40, radius: ReadInRadius.chip),
                SizedBox(width: ReadInSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [SkeletonBox(width: 160), SizedBox(height: ReadInSpace.s2), SkeletonBox(width: 220)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ReadInSpace.s5),
          ],
        ],
      );
}

/// A row of a console list: a white block row with a divider under it, tappable.
class AdminRow extends StatelessWidget {
  const AdminRow({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: context.colors.surface,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.colors.border))),
            padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s3),
            child: child,
          ),
        ),
      );
}

/// A filter chip of a console list.
class AdminFilterChip extends StatelessWidget {
  const AdminFilterChip({super.key, required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s2),
        child: FilterChip(label: Text(label), selected: selected, showCheckmark: false, onSelected: onSelected),
      );
}

/// Chips in one scrolling row.
class AdminChipRow extends StatelessWidget {
  const AdminChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: ReadInSpace.s2),
        child: Row(children: children),
      );
}

/// Asks before an admin action: a question with «إلغاء» / «موافق» (SPEC §14.4). True to go ahead.
Future<bool> confirmAdminAction(BuildContext context, {required String title, required String body, bool destructive = false}) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: dialogContext.colors.error, foregroundColor: dialogContext.colors.onError)
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.adminConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

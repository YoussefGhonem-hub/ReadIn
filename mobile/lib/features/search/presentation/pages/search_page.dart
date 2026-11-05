import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/presentation/widgets/engagement_seeder.dart';
import '../../../follow/presentation/widgets/suggested_writers.dart';
import '../../domain/entities/search.dart';
import '../../domain/services/search_query.dart';
import '../cubit/search_cubit.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/search_result_rows.dart';

/// The search screen (F16, guests allowed): the box (searching as you type, Enter at once), the Articles / Writers /
/// Topics / Tags tabs, the Articles tab's filters, and the device's recent searches while nothing is searched.
/// Articles show as the compact row (F34). `/search?q=&type=` opens on a query and a tab.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.initialQuery, this.initialType});

  final String? initialQuery;
  final SearchType? initialType;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<SearchCubit>()..start(query: initialQuery, type: initialType),
        child: SearchView(initialQuery: initialQuery, autofocus: (initialQuery ?? '').trim().isEmpty),
      );
}

/// The search screen once its [SearchCubit] is provided.
class SearchView extends StatefulWidget {
  const SearchView({super.key, this.initialQuery, this.autofocus = false});

  /// The box's text at first.
  final String? initialQuery;

  /// The keyboard comes up at once (opened to type, not from a link with a query).
  final bool autofocus;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> with SingleTickerProviderStateMixin {
  late final _text = TextEditingController(text: widget.initialQuery ?? '');
  final _focus = FocusNode();
  late final SearchCubit _cubit = context.read<SearchCubit>();
  late final TabController _tabs = TabController(
    length: SearchType.values.length,
    vsync: this,
    initialIndex: _cubit.state.type.index,
  );

  @override
  void initState() {
    super.initState();
    // Tapping a tab or swiping to it shows it, and searches it if needed.
    _tabs.addListener(() => _cubit.selectType(SearchType.values[_tabs.index]));
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _clear() {
    _text.clear();
    _cubit.input('');
    _focus.requestFocus();
  }

  /// A recent search: into the box, and searched.
  void _useRecent(String query) {
    _text.value = TextEditingValue(text: query, selection: TextSelection.collapsed(offset: query.length));
    _focus.unfocus();
    _cubit.submit(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        // Opened from a link with no page under it: back goes Home, like the tag page.
        leading: Navigator.of(context).canPop()
            ? null
            : IconButton(
                key: const ValueKey('search-home'),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const BackButtonIcon(),
                onPressed: () => GoRouter.maybeOf(context)?.go('/home'),
              ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s4),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _text,
            builder: (context, value, _) => BidiTextField(
              key: const ValueKey('search-input'),
              controller: _text,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              inputFormatters: [LengthLimitingTextInputFormatter(SearchQuery.maxLength)],
              onChanged: _cubit.input,
              onSubmitted: _cubit.submit,
              style: context.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: l10n.searchFieldHint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: ReadInSpace.s3),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('search-clear'),
                        tooltip: l10n.clearSearch,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _clear,
                      ),
              ),
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.searchTabArticles),
            Tab(text: l10n.searchTabWriters),
            Tab(text: l10n.searchTabTopics),
            Tab(text: l10n.searchTabTags),
          ],
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        buildWhen: (a, b) => a.isIdle != b.isIdle,
        builder: (context, state) => state.isIdle
            ? _IdleView(onPick: _useRecent)
            : TabBarView(
                controller: _tabs,
                children: const [_ArticlesTab(), _WritersTab(), _TopicsTab(), _TagsTab()],
              ),
      ),
    );
  }
}

// ── Idle: recent searches ───────────────────────────────────────────────────

/// Nothing searched yet: the recent searches (tap one to search it again, ✕ to remove it, or clear them all), or a
/// hint when there are none.
class _IdleView extends StatelessWidget {
  const _IdleView({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recent = context.select((SearchCubit c) => c.state.recent);
    final cubit = context.read<SearchCubit>();
    if (recent.isEmpty) {
      return EmptyView(icon: Icons.search_rounded, title: l10n.searchIdleTitle, body: l10n.searchIdleBody);
    }
    return ListView(
      key: const ValueKey('search-recent'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: ReadInSpace.s2, bottom: ReadInSpace.s6),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s5, 0, ReadInSpace.s2, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(header: true, child: Text(l10n.searchRecentTitle, style: context.textTheme.titleSmall)),
              ),
              TextButton(
                key: const ValueKey('search-recent-clear'),
                onPressed: () => unawaited(cubit.clearRecent()),
                child: Text(l10n.searchRecentClearAll),
              ),
            ],
          ),
        ),
        for (final query in recent) _RecentRow(query: query, onPick: onPick),
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.query, required this.onPick});

  final String query;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      key: ValueKey('search-recent-$query'),
      contentPadding: const EdgeInsetsDirectional.only(start: ReadInSpace.s5, end: ReadInSpace.s2),
      leading: ExcludeSemantics(child: Icon(Icons.history_rounded, color: colors.textSecondary)),
      // In its own direction ("dir=auto"), at the start of the row.
      title: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          query,
          textDirection: Bidi.detect(query) ?? Directionality.of(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      onTap: () => onPick(query),
      trailing: IconButton(
        tooltip: context.l10n.searchRecentRemove('${Bidi.fsi}$query${Bidi.pdi}'),
        icon: Icon(Icons.close_rounded, color: colors.textSecondary),
        onPressed: () => unawaited(context.read<SearchCubit>().removeRecent(query)),
      ),
    );
  }
}

// ── Tabs ────────────────────────────────────────────────────────────────────

class _ArticlesTab extends StatelessWidget {
  const _ArticlesTab();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SearchCubit>();
    final results = context.select((SearchCubit c) => c.state.articles);
    final filtered = context.select((SearchCubit c) => !c.state.filters.isEmpty);
    final query = context.select((SearchCubit c) => c.state.query);
    // The rows show the viewer's latest counters across screens (F10, F11).
    return EngagementSeeder<SearchCubit, SearchState>(
      cards: (state) => state.articles.items.map((result) => result.article),
      child: _ResultsList<SearchArticle>(
        type: SearchType.articles,
        results: results,
        header: const SearchFilterBar(),
        skeleton: const _RowsSkeleton(leading: _SkeletonLeading.thumbnail),
        // With filters: say so, and offer to clear them (the query in its own direction, so the quotes stay around it).
        emptyTitle: filtered ? l10n.searchNoResultsFilteredTitle : null,
        emptyTip: filtered ? l10n.searchNoResultsFiltersTip('${Bidi.fsi}$query${Bidi.pdi}') : l10n.searchNoResultsTip,
        emptyAction: filtered
            ? OutlinedButton(
                onPressed: () => cubit.setFilters(const ArticleSearchFilters()),
                child: Text(l10n.searchClearFilters),
              )
            : null,
        itemBuilder: (context, result) => SearchArticleRow(result: result, onOpen: cubit.remember),
      ),
    );
  }
}

class _WritersTab extends StatelessWidget {
  const _WritersTab();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    return _ResultsList(
      type: SearchType.users,
      results: context.select((SearchCubit c) => c.state.users),
      skeleton: const _RowsSkeleton(leading: _SkeletonLeading.avatar),
      emptyTip: context.l10n.searchNoResultsTip,
      itemBuilder: (context, user) => WriterTile(key: ValueKey('search-user-${user.id}'), user: user, onOpen: cubit.remember),
    );
  }
}

class _TopicsTab extends StatelessWidget {
  const _TopicsTab();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    return _ResultsList(
      type: SearchType.topics,
      results: context.select((SearchCubit c) => c.state.topics),
      skeleton: const _RowsSkeleton(leading: _SkeletonLeading.box),
      emptyTip: context.l10n.searchNoResultsTip,
      itemBuilder: (context, topic) => SearchTopicRow(topic: topic, onOpen: cubit.remember),
    );
  }
}

class _TagsTab extends StatelessWidget {
  const _TagsTab();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    return _ResultsList(
      type: SearchType.tags,
      results: context.select((SearchCubit c) => c.state.tags),
      skeleton: const _RowsSkeleton(leading: _SkeletonLeading.box),
      emptyTip: context.l10n.searchNoResultsTip,
      itemBuilder: (context, tag) => SearchTagRow(tag: tag, onOpen: cubit.remember),
    );
  }
}

/// One tab: [header] (the Articles filters), then the skeleton, an error with retry, "no results" ([emptyTitle], by
/// default "no results for «q»") with a tip, or the rows with infinite scroll.
class _ResultsList<T> extends StatelessWidget {
  const _ResultsList({
    super.key,
    required this.type,
    required this.results,
    required this.skeleton,
    required this.itemBuilder,
    required this.emptyTip,
    this.emptyTitle,
    this.header,
    this.emptyAction,
  });

  final SearchType type;
  final SearchResults<T> results;
  final Widget skeleton;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyTip;
  final String? emptyTitle;
  final Widget? header;
  final Widget? emptyAction;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    final query = context.select((SearchCubit c) => c.state.query);
    final header = this.header;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) unawaited(cubit.loadMore());
        return false;
      },
      child: CustomScrollView(
        key: PageStorageKey('search-${type.name}'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          if (header != null) SliverToBoxAdapter(child: header),
          ...switch (results.status) {
            SearchResultsStatus.idle || SearchResultsStatus.loading => [SliverToBoxAdapter(child: skeleton)],
            SearchResultsStatus.failure => [
                SliverFillRemaining(hasScrollBody: false, child: ErrorView(failure: results.failure!, onRetry: cubit.retry)),
              ],
            SearchResultsStatus.ready when results.items.isEmpty => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyView(
                    key: const ValueKey('search-empty'),
                    icon: Icons.search_off_rounded,
                    // The query in its own direction, so the quotes stay around it.
                    title: emptyTitle ?? context.l10n.searchNoResultsTitle('${Bidi.fsi}$query${Bidi.pdi}'),
                    body: emptyTip,
                    action: emptyAction,
                  ),
                ),
              ],
            SearchResultsStatus.ready => [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(ReadInSpace.s5, header == null ? ReadInSpace.s2 : 0, ReadInSpace.s5, 0),
                  sliver: SliverList.builder(
                    itemCount: results.items.length + 1,
                    itemBuilder: (context, i) => i < results.items.length
                        ? itemBuilder(context, results.items[i])
                        : _Footer(loadingMore: results.loadingMore, failure: results.loadMoreFailure, onRetry: cubit.loadMore),
                  ),
                ),
              ],
          },
        ],
      ),
    );
  }
}

/// The load-more spinner, or its error with retry.
class _Footer extends StatelessWidget {
  const _Footer({required this.loadingMore, required this.failure, required this.onRetry});

  final bool loadingMore;
  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = this.failure;
    final Widget child = loadingMore
        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
        : failure != null
            ? ErrorView(failure: failure, compact: true, onRetry: onRetry)
            : const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s4), child: Center(child: child));
  }
}

enum _SkeletonLeading { thumbnail, avatar, box }

/// Static rows while a tab loads (no shimmer, so "reduce motion" is respected).
class _RowsSkeleton extends StatelessWidget {
  const _RowsSkeleton({required this.leading});

  final _SkeletonLeading leading;

  @override
  Widget build(BuildContext context) => Padding(
        key: const ValueKey('search-skeleton'),
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5),
        child: Column(
          children: [
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    switch (leading) {
                      _SkeletonLeading.thumbnail => const SkeletonBox(width: 64, height: 64, radius: ReadInRadius.md),
                      _SkeletonLeading.avatar => const SkeletonBox(width: 44, height: 44, radius: 22),
                      _SkeletonLeading.box => const SkeletonBox(width: 44, height: 44, radius: ReadInRadius.md),
                    },
                    const SizedBox(width: ReadInSpace.s3),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [SkeletonBox(width: 160), SizedBox(height: ReadInSpace.s2), SkeletonBox(width: 100, height: 12)],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

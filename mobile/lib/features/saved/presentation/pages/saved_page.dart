import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../../article/presentation/widgets/article_card_tile.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../home/presentation/widgets/app_top_bar.dart';
import '../../domain/entities/saved.dart';
import '../cubit/collections_cubit.dart';
import '../cubit/saved_list_cubit.dart';
import '../widgets/add_to_collection_sheet.dart';
import '../widgets/collection_dialogs.dart';
import '../widgets/save_button.dart';

/// The Saved tab (F13): saved articles with field chips and search, and collections. Readable offline (F25).
class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);
    if (!signedIn) return const _SavedGuestView();
    return BlocProvider(create: (_) => getIt<SavedListCubit>()..load(), child: const SavedView());
  }
}

/// The Saved tab once its [SavedListCubit] is provided ([CollectionsCubit] and [EngagementCubit] come from the app).
class SavedView extends StatefulWidget {
  const SavedView({super.key, this.initialTab = 0});

  /// 0 = articles, 1 = collections.
  final int initialTab;

  @override
  State<SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<SavedView> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<CollectionsCubit>().load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        // The tabs' top bar, with Saved's own tabs under it.
        appBar: AppTopBar(bottom: TabBar(tabs: [Tab(text: l10n.savedTabArticles), Tab(text: l10n.collections)])),
        body: const TabBarView(children: [SavedArticlesList(), _CollectionsTab()]),
      ),
    );
  }
}

class _SavedGuestView extends StatelessWidget {
  const _SavedGuestView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: const AppTopBar(),
      body: PageBlock(
        margin: _blockGap,
        child: EmptyView(
          icon: Icons.bookmark_border_rounded,
          title: l10n.savedGuestTitle,
          body: l10n.savedGuestBody,
          action: Column(
            children: [
              FilledButton(onPressed: () => context.push('/auth/sign-up'), child: Text(l10n.signUp)),
              const SizedBox(height: ReadInSpace.s2),
              TextButton(onPressed: () => context.push('/auth/sign-in'), child: Text(l10n.signIn)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Articles ────────────────────────────────────────────────────────────────

/// Saved articles with search, field chips, the collection filter, paging and the offline copies. Needs a
/// [SavedListCubit] above it; the Saved tab and the own profile's Saved tab (F14) share it. The search and the filters
/// are a white block under the bar; the rows a block a gap under it, as are the skeleton, the error and the empty state.
class SavedArticlesList extends StatefulWidget {
  const SavedArticlesList({super.key, this.leading});

  /// A first sliver, e.g. the room for a pinned tab bar above (the profile).
  final Widget Function(BuildContext context)? leading;

  @override
  State<SavedArticlesList> createState() => _SavedArticlesListState();
}

class _SavedArticlesListState extends State<SavedArticlesList> with AutomaticKeepAliveClientMixin {
  late final _search = TextEditingController(text: context.read<SavedListCubit>().state.filter.query ?? '');

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    context.read<SavedListCubit>().search('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final cubit = context.read<SavedListCubit>();
    return BlocBuilder<SavedListCubit, SavedListState>(
      builder: (context, state) => RefreshIndicator(
        onRefresh: cubit.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) unawaited(cubit.loadMore());
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              ?widget.leading?.call(context),
              // The header block: the search, the offline note, the collection shown and the field chips.
              SliverToBoxAdapter(
                child: PageBlock(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(PageBlock.gutter, ReadInSpace.s4, PageBlock.gutter, 0),
                        child: BidiTextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onChanged: (text) {
                            cubit.search(text);
                            setState(() {}); // the clear button
                          },
                          decoration: InputDecoration(
                            hintText: l10n.savedSearchHint,
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(tooltip: l10n.clearSearch, icon: const Icon(Icons.close_rounded), onPressed: _clearSearch),
                          ),
                        ),
                      ),
                      if (state.offline) const _OfflineBanner(),
                      if (state.filter.collectionId != null) _CollectionFilterChip(collectionId: state.filter.collectionId!),
                      _FieldChips(state: state),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: PageBlock.gap)),
              ...switch (state.status) {
                SavedListStatus.loading => [const SliverToBoxAdapter(child: PageBlock(child: _SavedSkeleton()))],
                SavedListStatus.failure => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: PageBlock(child: ErrorView(failure: state.failure!, onRetry: cubit.load)),
                    ),
                  ],
                SavedListStatus.ready when state.items.isEmpty => [
                    SliverFillRemaining(hasScrollBody: false, child: PageBlock(child: _SavedEmpty(filter: state.filter))),
                  ],
                // One block of rows (each row a slice of it, so the list stays lazy; the rows draw their own top
                // line), then the footer on the canvas.
                SavedListStatus.ready => [
                    SliverList.builder(
                      itemCount: state.items.length + 1,
                      itemBuilder: (context, i) => i < state.items.length
                          ? PageBlock(
                              padding: EdgeInsets.fromLTRB(
                                PageBlock.gutter,
                                0,
                                PageBlock.gutter,
                                i == state.items.length - 1 ? ReadInSpace.s2 : 0,
                              ),
                              child: _SavedTile(item: state.items[i], collectionId: state.filter.collectionId),
                            )
                          : _Footer(state: state),
                    ),
                  ],
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(PageBlock.gutter, ReadInSpace.s3, PageBlock.gutter, 0),
        padding: const EdgeInsets.all(ReadInSpace.s3),
        decoration: BoxDecoration(color: colors.calloutInfo, borderRadius: BorderRadius.circular(ReadInRadius.md)),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 20, color: colors.calloutInfoAccent),
            const SizedBox(width: ReadInSpace.s2),
            Expanded(child: Text(context.l10n.savedOfflineBanner, style: context.textTheme.bodySmall?.copyWith(color: colors.textPrimary))),
          ],
        ),
      ),
    );
  }
}

class _CollectionFilterChip extends StatelessWidget {
  const _CollectionFilterChip({required this.collectionId});

  final String collectionId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = context.select((CollectionsCubit c) => c.state.byId(collectionId)?.name) ?? '…';
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(PageBlock.gutter, ReadInSpace.s3, PageBlock.gutter, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: InputChip(
          avatar: const Icon(Icons.folder_rounded, size: 18),
          label: BidiText(l10n.collectionFilter(name)),
          deleteButtonTooltipMessage: l10n.clearFilter,
          onDeleted: () => context.read<SavedListCubit>().selectCollection(null),
        ),
      ),
    );
  }
}

class _FieldChips extends StatelessWidget {
  const _FieldChips({required this.state});

  final SavedListState state;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final colors = context.colors;
    final selected = state.filter.fieldSlug;

    Widget chip(String label, String? slug) {
      final isSelected = selected == slug;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s2),
        child: ChoiceChip(
          label: BidiText(label),
          selected: isSelected,
          onSelected: (_) => context.read<SavedListCubit>().selectField(slug),
          selectedColor: colors.primary,
          labelStyle: context.textTheme.labelMedium?.copyWith(
            color: isSelected ? colors.onPrimary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(color: isSelected ? colors.primary : colors.border),
        ),
      );
    }

    if (state.fields.isEmpty) return const SizedBox(height: ReadInSpace.s3);
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s3),
        children: [
          chip(context.l10n.filterAll, null),
          for (final field in state.fields) chip(field.nameFor(lang), field.slug),
        ],
      ),
    );
  }
}

/// A saved article: open, unsave (with undo), add to a collection or take it out of the one shown.
class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.item, required this.collectionId});

  final SavedArticle item;

  /// The collection the list is filtered by.
  final String? collectionId;

  @override
  Widget build(BuildContext context) {
    final article = item.article;
    final engagement = context.select((EngagementCubit c) => c.state.of(article));
    return ArticleCardTile(
      article: engagement.applyTo(article),
      onTap: () => context.push('/a/${article.slug}'),
      actions: [
        SaveToggleButton(article: article),
        _SavedTileMenu(item: item, collectionId: collectionId),
      ],
    );
  }
}

enum _TileAction { addToCollection, removeFromCollection }

class _SavedTileMenu extends StatelessWidget {
  const _SavedTileMenu({required this.item, required this.collectionId});

  final SavedArticle item;
  final String? collectionId;

  Future<void> _removeFromCollection(BuildContext context, String collectionId) async {
    final l10n = context.l10n;
    final collections = context.read<CollectionsCubit>();
    final name = collections.state.byId(collectionId)?.name ?? '';
    final failure = await collections.remove(collectionId, item.article.id);
    if (!context.mounted) return;
    if (failure != null) {
      showActionFailure(context, failure);
    } else {
      showActionMessage(context, l10n.removedFromCollection(name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<_TileAction>(
      tooltip: l10n.moreActions,
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) => switch (action) {
        _TileAction.addToCollection => showAddToCollectionSheet(context, item.article),
        _TileAction.removeFromCollection => _removeFromCollection(context, collectionId!),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _TileAction.addToCollection,
          child: ListTile(leading: const Icon(Icons.playlist_add_rounded), title: Text(l10n.addToCollection)),
        ),
        if (collectionId != null)
          PopupMenuItem(
            value: _TileAction.removeFromCollection,
            child: ListTile(leading: const Icon(Icons.playlist_remove_rounded), title: Text(l10n.removeFromCollection)),
          ),
      ],
    );
  }
}

class _SavedEmpty extends StatelessWidget {
  const _SavedEmpty({required this.filter});

  final SavedFilter filter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (filter.collectionId != null && filter.fieldSlug == null && (filter.query ?? '').isEmpty) {
      return EmptyView(icon: Icons.folder_open_rounded, title: l10n.savedCollectionEmptyTitle, body: l10n.savedCollectionEmptyBody);
    }
    if (!filter.isEmpty) {
      return EmptyView(icon: Icons.search_off_rounded, title: l10n.savedNoResultsTitle, body: l10n.savedNoResultsBody);
    }
    return EmptyView(icon: Icons.bookmark_border_rounded, title: l10n.savedEmptyTitle, body: l10n.savedEmptyBody);
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final SavedListState state;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (state.loadingMore) {
      child = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5));
    } else if (state.loadMoreFailure != null) {
      child = ErrorView(failure: state.loadMoreFailure!, compact: true, onRetry: context.read<SavedListCubit>().loadMore);
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s5), child: Center(child: child));
  }
}

class _SavedSkeleton extends StatelessWidget {
  const _SavedSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: PageBlock.gutters,
        child: Column(
          children: [
            for (var i = 0; i < 4; i++)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: ReadInSpace.s3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 64, height: 64, radius: ReadInRadius.md),
                    SizedBox(width: ReadInSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [SkeletonBox(width: 70), SizedBox(height: ReadInSpace.s2), SkeletonBox(), SizedBox(height: ReadInSpace.s2), SkeletonBox(width: 140)],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

// ── Collections ─────────────────────────────────────────────────────────────

class _CollectionsTab extends StatelessWidget {
  const _CollectionsTab();

  Future<void> _create(BuildContext context) async {
    final l10n = context.l10n;
    final collections = context.read<CollectionsCubit>();
    await showCollectionNameDialog<ArticleCollection>(
      context,
      title: l10n.newCollection,
      action: l10n.createAction,
      submit: (name) async => (await collections.create(name)).fold((f) => (null, f), (c) => (c, null)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final collections = context.read<CollectionsCubit>();
    return BlocBuilder<CollectionsCubit, CollectionsState>(
      builder: (context, state) => switch (state.status) {
        CollectionsStatus.idle || CollectionsStatus.loading => const _CollectionsSkeleton(),
        CollectionsStatus.failure => PageBlock(
            margin: _blockGap,
            child: ErrorView(failure: state.failure!, onRetry: () => collections.load(force: true)),
          ),
        // One block: "New collection", then the collections split by dividers (or the empty state).
        CollectionsStatus.ready => RefreshIndicator(
            onRefresh: () => collections.load(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: ReadInSpace.s6),
              children: [
                PageBlock(
                  margin: _blockGap,
                  padding: const EdgeInsets.only(bottom: ReadInSpace.s1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s3),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: OutlinedButton.icon(
                            onPressed: () => _create(context),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(l10n.newCollection),
                          ),
                        ),
                      ),
                      if (state.items.isEmpty)
                        EmptyView(icon: Icons.folder_open_rounded, title: l10n.collectionsEmptyTitle, body: l10n.collectionsEmptyBody)
                      else
                        for (final collection in state.items) ...[
                          const Divider(indent: PageBlock.gutter, endIndent: PageBlock.gutter),
                          _CollectionTile(collection: collection),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      },
    );
  }
}

enum _CollectionAction { rename, delete }

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.collection});

  final ArticleCollection collection;

  void _open(BuildContext context) {
    unawaited(context.read<SavedListCubit>().selectCollection(collection.id));
    DefaultTabController.of(context).animateTo(0);
  }

  Future<void> _rename(BuildContext context) async {
    final l10n = context.l10n;
    final collections = context.read<CollectionsCubit>();
    await showCollectionNameDialog<bool>(
      context,
      title: l10n.renameCollection,
      action: l10n.save,
      initial: collection.name,
      submit: (name) async {
        final failure = await collections.rename(collection.id, name);
        return (failure == null ? true : null, failure);
      },
    );
  }

  Future<void> _delete(BuildContext context) async {
    final collections = context.read<CollectionsCubit>();
    final list = context.read<SavedListCubit>();
    if (!await confirmDeleteCollection(context, collection.name)) return;
    final Failure? failure = await collections.delete(collection.id);
    if (list.state.filter.collectionId == collection.id) unawaited(list.selectCollection(null));
    if (context.mounted) showActionFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: PageBlock.gutter, end: ReadInSpace.s1),
      minTileHeight: 64,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(ReadInRadius.md)),
        child: Icon(Icons.folder_rounded, color: colors.onPrimaryContainer),
      ),
      title: BidiText(collection.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(l10n.collectionArticles(collection.articleCount), style: context.textTheme.bodySmall),
      onTap: () => _open(context),
      trailing: PopupMenuButton<_CollectionAction>(
        tooltip: l10n.moreActions,
        icon: const Icon(Icons.more_vert_rounded),
        onSelected: (action) => switch (action) {
          _CollectionAction.rename => _rename(context),
          _CollectionAction.delete => _delete(context),
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _CollectionAction.rename,
            child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(l10n.renameAction)),
          ),
          PopupMenuItem(
            value: _CollectionAction.delete,
            child: ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: colors.error),
              title: Text(l10n.deleteAction, style: TextStyle(color: colors.error)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The collections' block while they load.
class _CollectionsSkeleton extends StatelessWidget {
  const _CollectionsSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          PageBlock(
            margin: _blockGap,
            padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s3),
            child: Column(
              children: [
                for (var i = 0; i < 4; i++)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: ReadInSpace.s2),
                    child: Row(
                      children: [
                        SkeletonBox(width: 44, height: 44, radius: ReadInRadius.md),
                        SizedBox(width: ReadInSpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [SkeletonBox(width: 150), SizedBox(height: ReadInSpace.s2), SkeletonBox(width: 70, height: 12)],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}

/// The canvas above a block.
const _blockGap = EdgeInsets.only(top: PageBlock.gap);

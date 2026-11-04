import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/editor_entities.dart';
import '../cubit/my_articles_cubit.dart';
import '../widgets/editor_widgets.dart';

/// Routes of the writing area (F05).
abstract final class EditorRoutes {
  static const myArticles = '/write';
  static const newArticle = '/write/new';

  static String edit(String id) => '/write/$id';
}

/// "My articles" (F05), the Write tab: Drafts / Published, each row with Edit and Delete, and "New article".
class MyArticlesPage extends StatelessWidget {
  const MyArticlesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<MyArticlesCubit>()..ensureLoaded(ArticleLifecycle.draft),
        child: const MyArticlesView(),
      );
}

class MyArticlesView extends StatefulWidget {
  const MyArticlesView({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<MyArticlesView> createState() => _MyArticlesViewState();
}

class _MyArticlesViewState extends State<MyArticlesView> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);

  static const _statuses = [ArticleLifecycle.draft, ArticleLifecycle.published];

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) context.read<MyArticlesCubit>().ensureLoaded(_statuses[_tabs.index]);
    });
    if (widget.initialTab != 0) context.read<MyArticlesCubit>().ensureLoaded(_statuses[widget.initialTab]);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Opens the editor and refreshes the lists when it closes (saved, published or deleted meanwhile).
  Future<void> _open(String location) async {
    final cubit = context.read<MyArticlesCubit>();
    await context.push<Object?>(location);
    if (mounted) await cubit.refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<MyArticlesCubit, MyArticlesState>(
      listenWhen: (a, b) => a.noticeSeq != b.noticeSeq && b.notice != null,
      listener: (context, state) => showActionFailure(context, state.notice),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myArticlesTitle),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            controller: _tabs,
            tabs: [Tab(text: l10n.myArticlesDrafts), Tab(text: l10n.myArticlesPublished)],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('my-articles-new'),
          onPressed: () => _open(EditorRoutes.newArticle),
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.myArticlesNew),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            for (final status in _statuses) _ArticlesTab(status: status, onOpen: (a) => _open(EditorRoutes.edit(a.id)), onNew: () => _open(EditorRoutes.newArticle)),
          ],
        ),
      ),
    );
  }
}

class _ArticlesTab extends StatelessWidget {
  const _ArticlesTab({required this.status, required this.onOpen, required this.onNew});

  final ArticleLifecycle status;
  final ValueChanged<MyArticle> onOpen;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<MyArticlesCubit>();
    return BlocBuilder<MyArticlesCubit, MyArticlesState>(
      buildWhen: (a, b) => a.tab(status) != b.tab(status) || a.deleting != b.deleting,
      builder: (context, state) {
        final tab = state.tab(status);
        if (tab.status == MyArticlesStatus.initial || tab.status == MyArticlesStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (tab.status == MyArticlesStatus.failure) return ErrorView(failure: tab.failure!, onRetry: () => cubit.load(status));
        if (tab.items.isEmpty) {
          final drafts = status == ArticleLifecycle.draft;
          return EmptyView(
            icon: drafts ? Icons.edit_note_rounded : Icons.public_rounded,
            title: drafts ? l10n.myArticlesEmptyDrafts : l10n.myArticlesEmptyPublished,
            body: drafts ? l10n.myArticlesEmptyDraftsBody : l10n.myArticlesEmptyPublishedBody,
            action: drafts ? FilledButton.icon(onPressed: onNew, icon: const Icon(Icons.edit_outlined), label: Text(l10n.myArticlesNew)) : null,
          );
        }
        return RefreshIndicator(
          onRefresh: () => cubit.load(status),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 400) cubit.loadMore(status);
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, ReadInSpace.s9 + ReadInSpace.s5),
              itemCount: tab.items.length + (tab.hasMore || tab.loadMoreFailure != null ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= tab.items.length) {
                  return tab.loadMoreFailure != null
                      ? ErrorView(failure: tab.loadMoreFailure!, compact: true, onRetry: () => cubit.loadMore(status))
                      : const Padding(
                          padding: EdgeInsets.all(ReadInSpace.s4),
                          child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                        );
                }
                final article = tab.items[i];
                return MyArticleTile(
                  key: ValueKey('my-article-${article.id}'),
                  article: article,
                  onEdit: () => onOpen(article),
                  onDelete: () => _confirmDelete(context, article),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, MyArticle article) async {
    final l10n = context.l10n;
    final cubit = context.read<MyArticlesCubit>();
    final ok = await confirmDialog(
      context,
      title: l10n.deleteArticleTitle,
      body: article.isPublished ? l10n.deletePublishedBody : l10n.deleteDraftBody,
      confirm: l10n.deleteAction,
      destructive: true,
    );
    if (!ok) return;
    final deleted = await cubit.delete(article);
    if (deleted && context.mounted) showActionMessage(context, l10n.articleDeleted);
  }
}

/// One row of "My articles": cover, title (or "Untitled"), field, reading time, dates, "Unpublished changes", and
/// Edit / Delete.
class MyArticleTile extends StatelessWidget {
  const MyArticleTile({super.key, required this.article, required this.onEdit, required this.onDelete});

  final MyArticle article;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final untitled = article.title.trim().isEmpty;
    final meta = context.textTheme.bodySmall;
    final published = article.publishedAt;
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(ReadInRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.border))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cover(url: article.coverUrl),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: ReadInSpace.s1,
                    runSpacing: ReadInSpace.s1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (article.field != null) InfoTag(label: article.field!.nameFor(lang)),
                      if (article.hasUnpublishedChanges)
                        InfoTag(label: l10n.unpublishedChanges, icon: Icons.edit_outlined, tone: InfoTagTone.accent),
                    ],
                  ),
                  const SizedBox(height: ReadInSpace.s1),
                  BidiText(
                    untitled ? l10n.untitledArticle : article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      height: 1.5,
                      color: untitled ? colors.textSecondary : null,
                      fontStyle: untitled ? FontStyle.italic : null,
                    ),
                  ),
                  const SizedBox(height: ReadInSpace.s1),
                  Text(
                    [
                      if (article.readingTimeMinutes > 0) l10n.readingTime(article.readingTimeMinutes),
                      if (published != null) l10n.myArticlePublishedOn(formatDate(published.toLocal(), lang)),
                      l10n.myArticleEdited(formatDate(article.savedAt.toLocal(), lang)),
                    ].join(' · '),
                    style: meta,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  key: ValueKey('my-article-edit-${article.id}'),
                  tooltip: l10n.edit,
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  key: ValueKey('my-article-delete-${article.id}'),
                  tooltip: l10n.deleteAction,
                  visualDensity: VisualDensity.compact,
                  color: colors.error,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cover = url;
    return SizedBox(
      width: 72,
      height: 72,
      child: cover != null && cover.isNotEmpty
          ? AppNetworkImage(url: cover, borderRadius: BorderRadius.circular(ReadInRadius.md))
          : DecoratedBox(
              decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(ReadInRadius.md)),
              child: Icon(Icons.article_outlined, color: colors.onPrimaryContainer),
            ),
    );
  }
}

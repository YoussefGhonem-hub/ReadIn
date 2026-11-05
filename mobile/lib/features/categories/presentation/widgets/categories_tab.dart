import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/writer_category.dart';
import '../category_routes.dart';
import '../cubit/category_cubits.dart';
import 'category_dialogs.dart';

/// A profile's **Categories** tab (F31, "الأقسام"), between Articles and the next tab, for everyone including guests.
/// Someone else's profile: one card per category with its name and article count, in the writer's order, then
/// "مقالات تانية"; empty categories are hidden. The own profile of a writer (`articles.create`, as on the web) manages
/// them: every category (empty ones too) with create, rename, reorder (drag, or "Move up / down" in its menu) and
/// delete. Without the permission the own profile shows the public list. A card opens the category page.
///
/// [leading] builds the first sliver (the profile's pinned tab bar leaves room for itself with it).
class ProfileCategoriesTab extends StatefulWidget {
  const ProfileCategoriesTab({super.key, required this.username, required this.isMe, required this.leading});

  final String username;

  /// The signed-in user's own profile; managing also needs `articles.create` (read from the [SessionCubit] above).
  final bool isMe;
  final Widget Function(BuildContext context) leading;

  @override
  State<ProfileCategoriesTab> createState() => _ProfileCategoriesTabState();
}

class _ProfileCategoriesTabState extends State<ProfileCategoriesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final canWrite = context.select((SessionCubit c) => c.state.me?.canWrite ?? false);
    return widget.isMe && canWrite
        ? BlocProvider(
            create: (_) => getIt<MyCategoriesCubit>()..load(),
            child: MyCategoriesView(username: widget.username, leading: widget.leading),
          )
        : BlocProvider(
            create: (_) => getIt<ProfileCategoriesCubit>(param1: widget.username)..load(),
            child: ProfileCategoriesView(username: widget.username, leading: widget.leading),
          );
  }
}

void _open(BuildContext context, String username, String slug) =>
    unawaited(GoRouter.maybeOf(context)?.push<void>(CategoryRoutes.of(username, slug)));

// ── Someone else's categories ───────────────────────────────────────────────

/// The cards of [username]'s categories, once a [ProfileCategoriesCubit] is provided.
class ProfileCategoriesView extends StatelessWidget {
  const ProfileCategoriesView({super.key, required this.username, required this.leading});

  final String username;
  final Widget Function(BuildContext context) leading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ProfileCategoriesCubit>();
    return BlocBuilder<ProfileCategoriesCubit, CategoryListState>(
      builder: (context, state) => RefreshIndicator(
        onRefresh: cubit.refresh,
        child: CustomScrollView(
          key: const PageStorageKey('profile-categories'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            leading(context),
            ...switch (state.status) {
              CategoryLoadStatus.loading => [const SliverToBoxAdapter(child: _CategoriesSkeleton())],
              CategoryLoadStatus.failure => [
                  SliverFillRemaining(hasScrollBody: false, child: ErrorView(failure: state.failure!, onRetry: cubit.load)),
                ],
              // No category with articles readers can see: "مقالات تانية" alone would only repeat the Articles tab.
              CategoryLoadStatus.ready when state.items.isEmpty => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(icon: Icons.folder_open_outlined, title: l10n.categoriesEmptyTitle, body: l10n.categoriesEmptyBody),
                  ),
                ],
              CategoryLoadStatus.ready => [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, ReadInSpace.s4, ReadInSpace.s4, ReadInSpace.s6),
                    sliver: SliverList.list(
                      children: [
                        for (final category in state.items)
                          CategoryCard(
                            key: ValueKey('category-card-${category.slug}'),
                            name: category.name,
                            count: category.articleCount,
                            onTap: () => _open(context, username, category.slug),
                          ),
                        if (state.uncategorizedCount > 0)
                          CategoryCard(
                            key: const ValueKey('category-card-other'),
                            name: l10n.categoriesOther,
                            count: state.uncategorizedCount,
                            other: true,
                            onTap: () => _open(context, username, CategoryRoutes.otherSlug),
                          ),
                      ],
                    ),
                  ),
                ],
            },
          ],
        ),
      ),
    );
  }
}

/// One category on a profile: its icon, name (in its own direction) and article count; it opens the category page.
/// [other] is "مقالات تانية".
class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.name, required this.count, required this.onTap, this.other = false});

  final String name;
  final int count;
  final VoidCallback onTap;
  final bool other;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final dir = Bidi.detect(name) ?? Directionality.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ReadInRadius.card),
      side: BorderSide(color: colors.border),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: ReadInSpace.s3),
      child: Semantics(
        button: true,
        hint: l10n.categoryOpenHint,
        child: Material(
          color: colors.surface,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: shape,
            child: Padding(
              padding: const EdgeInsets.all(ReadInSpace.s4),
              child: Row(
                children: [
                  _CategoryIcon(other: other),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            Bidi.isolateOppositeRuns(name, dir),
                            textDirection: dir,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(l10n.categoryArticleCount(count), style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: ReadInSpace.s2),
                  // Points to the end in either direction (the icon mirrors in RTL).
                  ExcludeSemantics(child: Icon(Icons.chevron_right_rounded, color: colors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({this.other = false});

  final bool other;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: other ? colors.surfaceVariant : colors.primaryContainer,
        borderRadius: BorderRadius.circular(ReadInRadius.md),
      ),
      child: ExcludeSemantics(
        child: Icon(
          other ? Icons.layers_outlined : Icons.folder_outlined,
          size: 22,
          color: other ? colors.textSecondary : colors.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ── The own categories ──────────────────────────────────────────────────────

enum _CategoryAction { rename, moveUp, moveDown, delete }

/// The own Categories tab, once a [MyCategoriesCubit] is provided: "＋ قسم جديد", then every category (empty ones too)
/// with a drag handle and a menu (rename, move up / down, delete), then "مقالات تانية".
class MyCategoriesView extends StatelessWidget {
  const MyCategoriesView({super.key, required this.username, required this.leading});

  final String username;
  final Widget Function(BuildContext context) leading;

  static Future<void> _create(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<MyCategoriesCubit>();
    await showCategoryNameDialog<WriterCategory>(
      context,
      title: l10n.categoryNew,
      action: l10n.createAction,
      existing: cubit.state.items,
      submit: cubit.create,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<MyCategoriesCubit>();
    return BlocBuilder<MyCategoriesCubit, CategoryListState>(
      builder: (context, state) => RefreshIndicator(
        onRefresh: cubit.refresh,
        child: CustomScrollView(
          key: const PageStorageKey('profile-categories'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            leading(context),
            ...switch (state.status) {
              CategoryLoadStatus.loading => [const SliverToBoxAdapter(child: _CategoriesSkeleton())],
              CategoryLoadStatus.failure => [
                  SliverFillRemaining(hasScrollBody: false, child: ErrorView(failure: state.failure!, onRetry: cubit.load)),
                ],
              CategoryLoadStatus.ready when state.items.isEmpty => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(
                      icon: Icons.create_new_folder_outlined,
                      title: l10n.categoriesEmptyOwnTitle,
                      body: l10n.categoriesEmptyOwnBody,
                      action: FilledButton.icon(
                        key: const ValueKey('category-create'),
                        onPressed: () => _create(context),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.categoryNew),
                      ),
                    ),
                  ),
                ],
              CategoryLoadStatus.ready => [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, ReadInSpace.s4, ReadInSpace.s4, ReadInSpace.s3),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            state.full ? l10n.categoriesFull : l10n.categoriesOwnHint,
                            style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                          ),
                          const SizedBox(height: ReadInSpace.s2),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FilledButton.tonalIcon(
                              key: const ValueKey('category-create'),
                              onPressed: state.full ? null : () => _create(context),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(l10n.categoryNew),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4),
                    sliver: SliverReorderableList(
                      itemCount: state.items.length,
                      onReorderItem: (from, to) => _reorder(context, from, to),
                      proxyDecorator: (child, _, _) => Material(
                        color: Colors.transparent,
                        elevation: 6,
                        borderRadius: BorderRadius.circular(ReadInRadius.card),
                        child: child,
                      ),
                      itemBuilder: (context, i) {
                        final category = state.items[i];
                        return MyCategoryRow(
                          key: ValueKey('my-category-${category.id}'),
                          category: category,
                          index: i,
                          count: state.items.length,
                          busy: state.busy,
                          onOpen: () => _open(context, username, category.slug),
                        );
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, 0, ReadInSpace.s4, ReadInSpace.s6),
                    sliver: SliverToBoxAdapter(
                      child: state.uncategorizedCount > 0
                          ? CategoryCard(
                              key: const ValueKey('category-card-other'),
                              name: l10n.categoriesOther,
                              count: state.uncategorizedCount,
                              other: true,
                              onTap: () => _open(context, username, CategoryRoutes.otherSlug),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
            },
          ],
        ),
      ),
    );
  }

  /// A drop: [from] and [to] are the indexes before and after the move.
  static Future<void> _reorder(BuildContext context, int from, int to) async {
    final failure = await context.read<MyCategoriesCubit>().move(from, to);
    if (context.mounted) showActionFailure(context, failure);
  }
}

/// One of the own categories: drag handle, name, article count ("empty: visitors don't see it" at 0) and its menu.
class MyCategoryRow extends StatelessWidget {
  const MyCategoryRow({
    super.key,
    required this.category,
    required this.index,
    required this.count,
    required this.onOpen,
    this.busy = false,
  });

  final WriterCategory category;

  /// Its place in the list, and the list's length (the first can't move up, the last can't move down).
  final int index;
  final int count;
  final VoidCallback onOpen;

  /// A reorder is on its way: the handles and moves wait.
  final bool busy;

  Future<void> _act(BuildContext context, _CategoryAction action) async {
    final l10n = context.l10n;
    final cubit = context.read<MyCategoriesCubit>();
    switch (action) {
      case _CategoryAction.rename:
        await showCategoryNameDialog<bool>(
          context,
          title: l10n.categoryRenameTitle,
          action: l10n.save,
          existing: cubit.state.items,
          renaming: category,
          submit: (name) async {
            final failure = await cubit.rename(category.id, name);
            return failure == null ? const Ok(true) : Err(failure);
          },
        );
      case _CategoryAction.moveUp:
        final failure = await cubit.move(index, index - 1);
        if (context.mounted) showActionFailure(context, failure);
      case _CategoryAction.moveDown:
        final failure = await cubit.move(index, index + 1);
        if (context.mounted) showActionFailure(context, failure);
      case _CategoryAction.delete:
        if (!await confirmDeleteCategory(context, category) || !context.mounted) return;
        final failure = await cubit.delete(category.id);
        if (!context.mounted) return;
        failure == null ? showActionMessage(context, l10n.categoryDeleted) : showActionFailure(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final dir = Bidi.detect(category.name) ?? Directionality.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ReadInRadius.card),
      side: BorderSide(color: colors.border),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: ReadInSpace.s3),
      child: Material(
        color: colors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s1, ReadInSpace.s2, ReadInSpace.s1, ReadInSpace.s2),
            child: Row(
              children: [
                // Drag to reorder; screen readers and switch users have "Move up / down" in the menu.
                ReorderableDragStartListener(
                  index: index,
                  enabled: !busy && count > 1,
                  child: Tooltip(
                    message: l10n.categoryDragHandle,
                    excludeFromSemantics: true,
                    child: SizedBox(
                      width: 40,
                      height: 48,
                      child: ExcludeSemantics(
                        child: Icon(Icons.drag_indicator_rounded, color: count > 1 ? colors.textSecondary : colors.border),
                      ),
                    ),
                  ),
                ),
                const _CategoryIcon(),
                const SizedBox(width: ReadInSpace.s3),
                Expanded(
                  // The row's ink is the button; this tells where it goes.
                  child: Semantics(
                    hint: l10n.categoryOpenHint,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            Bidi.isolateOppositeRuns(category.name, dir),
                            textDirection: dir,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          category.isEmpty ? l10n.categoryEmptyOwn : l10n.categoryArticleCount(category.articleCount),
                          style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<_CategoryAction>(
                  key: ValueKey('my-category-menu-${category.id}'),
                  tooltip: l10n.categoryMenu,
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (action) => unawaited(_act(context, action)),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: _CategoryAction.rename, child: _MenuRow(Icons.edit_outlined, l10n.renameAction)),
                    if (index > 0)
                      PopupMenuItem(
                        value: _CategoryAction.moveUp,
                        enabled: !busy,
                        child: _MenuRow(Icons.arrow_upward_rounded, l10n.categoryMoveUp),
                      ),
                    if (index < count - 1)
                      PopupMenuItem(
                        value: _CategoryAction.moveDown,
                        enabled: !busy,
                        child: _MenuRow(Icons.arrow_downward_rounded, l10n.categoryMoveDown),
                      ),
                    PopupMenuItem(
                      value: _CategoryAction.delete,
                      child: _MenuRow(Icons.delete_outline_rounded, l10n.deleteAction, color: colors.error),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, {this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: ReadInSpace.s3),
          Flexible(child: Text(label, style: color == null ? null : TextStyle(color: color))),
        ],
      );
}

/// Three category cards while the list loads (static, so "reduce motion" is respected).
class _CategoriesSkeleton extends StatelessWidget {
  const _CategoriesSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(ReadInSpace.s4),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: ReadInSpace.s3),
                child: Row(
                  children: [
                    SkeletonBox(width: 44, height: 44, radius: ReadInRadius.md),
                    SizedBox(width: ReadInSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [SkeletonBox(width: 160, height: 18), SizedBox(height: ReadInSpace.s2), SkeletonBox(width: 70)],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

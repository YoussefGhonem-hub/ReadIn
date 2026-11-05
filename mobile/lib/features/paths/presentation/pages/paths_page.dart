import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/learning_path.dart';
import '../cubit/path_list_cubit.dart';
import '../path_routes.dart';
import '../widgets/path_widgets.dart';

/// Learning paths (F09, guests allowed): "All paths" | "My paths", each with field chips built from its list.
class PathsPage extends StatelessWidget {
  const PathsPage({super.key, this.initialTab = PathsTab.all});

  final PathsTab initialTab;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<AllPathsCubit>()..load()),
          // Loads the first time its tab is shown, signed in only.
          BlocProvider(create: (_) => getIt<MyPathsCubit>()),
        ],
        child: PathsView(initialTab: initialTab),
      );
}

/// The two tabs once [AllPathsCubit] and [MyPathsCubit] are provided.
class PathsView extends StatelessWidget {
  const PathsView({super.key, this.initialTab = PathsTab.all});

  final PathsTab initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: PathsTab.values.length,
      initialIndex: initialTab.index,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.pathsTitle),
          bottom: TabBar(tabs: [Tab(text: l10n.pathsTabAll), Tab(text: l10n.pathsTabMine)]),
        ),
        body: const TabBarView(children: [_AllPathsTab(), _MyPathsTab()]),
      ),
    );
  }
}

/// Opens a path; back on the list, both lists refresh (enrolling and reading change them).
Future<void> _openPath(BuildContext context, LearningPath path) async {
  final all = context.read<AllPathsCubit>();
  final mine = context.read<MyPathsCubit>();
  await context.push<void>(PathRoutes.of(path.slug));
  if (!all.isClosed) unawaited(all.refresh());
  if (!mine.isClosed && mine.state.status != PathListStatus.loading) unawaited(mine.refresh());
}

class _AllPathsTab extends StatelessWidget {
  const _AllPathsTab();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PathList<AllPathsCubit>(
      storageKey: 'paths-all',
      onOpen: (path) => _openPath(context, path),
      empty: EmptyView(icon: Icons.route_outlined, title: l10n.pathsEmptyTitle, body: l10n.pathsEmptyBody),
    );
  }
}

class _MyPathsTab extends StatefulWidget {
  const _MyPathsTab();

  @override
  State<_MyPathsTab> createState() => _MyPathsTabState();
}

class _MyPathsTabState extends State<_MyPathsTab> {
  @override
  void initState() {
    super.initState();
    if (context.read<SessionCubit>().state.isAuthenticated) unawaited(context.read<MyPathsCubit>().ensureLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);
    if (!signedIn) {
      return PageBlock(
        margin: const EdgeInsets.only(top: PageBlock.gap),
        child: EmptyView(
          icon: Icons.route_outlined,
          title: l10n.myPathsGuestTitle,
          body: l10n.myPathsGuestBody,
          action: Column(
            children: [
              FilledButton(onPressed: () => context.push('/auth/sign-up'), child: Text(l10n.signUp)),
              const SizedBox(height: ReadInSpace.s2),
              TextButton(onPressed: () => context.push('/auth/sign-in'), child: Text(l10n.signIn)),
            ],
          ),
        ),
      );
    }
    return PathList<MyPathsCubit>(
      storageKey: 'paths-mine',
      onOpen: (path) => _openPath(context, path),
      empty: EmptyView(
        icon: Icons.route_outlined,
        title: l10n.myPathsEmptyTitle,
        body: l10n.myPathsEmptyBody,
        action: FilledButton(
          onPressed: () => DefaultTabController.of(context).animateTo(PathsTab.all.index),
          child: Text(l10n.pathsBrowse),
        ),
      ),
    );
  }
}

/// A [PathListCubit]'s list: field chips, path cards, pull to refresh, and the loading, error and empty states. Each
/// path is a full-width block on the canvas, a gap apart (LinkedIn style); the error and empty states are a block too.
class PathList<C extends PathListCubit> extends StatefulWidget {
  const PathList({super.key, required this.onOpen, required this.empty, this.storageKey, this.leading, this.footer});

  final ValueChanged<LearningPath> onOpen;
  final Widget empty;
  final String? storageKey;

  /// A first sliver, e.g. the room for a pinned tab bar above (the profile).
  final Widget Function(BuildContext context)? leading;

  /// Below a non-empty list.
  final Widget? footer;

  @override
  State<PathList<C>> createState() => _PathListState<C>();
}

class _PathListState<C extends PathListCubit> extends State<PathList<C>> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cubit = context.read<C>();
    return BlocBuilder<C, PathListState>(
      builder: (context, state) {
        final visible = state.visible;
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: CustomScrollView(
            key: widget.storageKey == null ? null : PageStorageKey(widget.storageKey),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              ?widget.leading?.call(context),
              SliverToBoxAdapter(
                child: PathFieldChips(fields: state.fields, selected: state.fieldSlug, onSelected: cubit.selectField),
              ),
              ...switch (state.status) {
                PathListStatus.loading => [const SliverToBoxAdapter(child: PathListSkeleton())],
                PathListStatus.failure => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: PageBlock(child: ErrorView(failure: state.failure!, onRetry: cubit.load)),
                    ),
                  ],
                PathListStatus.ready when state.items.isEmpty => [
                    SliverFillRemaining(hasScrollBody: false, child: PageBlock(child: widget.empty)),
                  ],
                PathListStatus.ready => [
                    SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: PageBlock.gap),
                      itemBuilder: (context, i) => PageBlock(
                        child: PathCardTile(path: visible[i], onTap: () => widget.onOpen(visible[i])),
                      ),
                    ),
                    if (widget.footer != null)
                      SliverPadding(padding: PageBlock.gutters, sliver: SliverToBoxAdapter(child: widget.footer)),
                    const SliverToBoxAdapter(child: SizedBox(height: ReadInSpace.s6)),
                  ],
              },
            ],
          ),
        );
      },
    );
  }
}

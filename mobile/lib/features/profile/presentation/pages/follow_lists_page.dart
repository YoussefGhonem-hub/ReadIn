import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../follow/presentation/widgets/suggested_writers.dart';
import '../../domain/entities/profile.dart';
import '../cubit/follow_list_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/profile_header.dart';

/// `/u/{username}/followers` and `/following` (F12, F14): both lists in tabs. The profile screen hands over the
/// [profile]; a deep link loads it first (the lists are keyed by user id).
class FollowListsPage extends StatelessWidget {
  const FollowListsPage({super.key, required this.username, this.initialKind = FollowListKind.followers, this.profile});

  final String username;
  final FollowListKind initialKind;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    if (profile != null) return FollowListsView(profile: profile, initialKind: initialKind);
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..load(username),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => switch (state.status) {
          ProfileStatus.ready => FollowListsView(profile: state.profile!, initialKind: initialKind),
          ProfileStatus.loading => Scaffold(
              appBar: AppBar(),
              body: const SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: PageBlock(margin: _blockGap, child: _RowsSkeleton()),
              ),
            ),
          ProfileStatus.failure => Scaffold(
              appBar: AppBar(),
              body: PageBlock(
                margin: _blockGap,
                child: state.notFound
                    ? EmptyView(icon: Icons.person_off_outlined, title: context.l10n.profileNotFoundTitle, body: context.l10n.profileNotFoundBody)
                    : ErrorView(failure: state.failure!, onRetry: () => context.read<ProfileCubit>().load(username)),
              ),
            ),
        },
      ),
    );
  }
}

/// Followers and Following of [profile], each with its own search and paging.
class FollowListsView extends StatelessWidget {
  const FollowListsView({super.key, required this.profile, this.initialKind = FollowListKind.followers, this.cubitFor});

  final UserProfile profile;
  final FollowListKind initialKind;

  /// Test seam: the cubit of each list (default: from the service locator).
  final FollowListCubit Function(FollowListKind kind)? cubitFor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    FollowListCubit create(FollowListKind kind) =>
        cubitFor?.call(kind) ?? (getIt<FollowListCubit>(param1: profile.id, param2: kind)..load());
    return DefaultTabController(
      length: FollowListKind.values.length,
      initialIndex: initialKind.index,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BidiText(profile.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
              UsernameText(profile.username, style: context.textTheme.bodySmall),
            ],
          ),
          bottom: TabBar(tabs: [Tab(text: l10n.profileStatFollowers), Tab(text: l10n.profileStatFollowing)]),
        ),
        body: TabBarView(
          children: [
            for (final kind in FollowListKind.values)
              BlocProvider(create: (_) => create(kind), child: FollowListView(kind: kind, profile: profile)),
          ],
        ),
      ),
    );
  }
}

/// One list: search box (debounced), rows with follow buttons, infinite scroll, empty and error states. Needs a
/// [FollowListCubit] above it.
class FollowListView extends StatefulWidget {
  const FollowListView({super.key, required this.kind, required this.profile});

  final FollowListKind kind;
  final UserProfile profile;

  @override
  State<FollowListView> createState() => _FollowListViewState();
}

class _FollowListViewState extends State<FollowListView> with AutomaticKeepAliveClientMixin {
  late final _search = TextEditingController(text: context.read<FollowListCubit>().state.query);

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clear() {
    _search.clear();
    context.read<FollowListCubit>().search('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final cubit = context.read<FollowListCubit>();
    return BlocBuilder<FollowListCubit, FollowListState>(
      builder: (context, state) => RefreshIndicator(
        onRefresh: cubit.load,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 400) unawaited(cubit.loadMore());
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // The search in a white strip under the tabs, then the people a gap under it, in one block.
              SliverToBoxAdapter(
                child: PageBlock(
                  padding: const EdgeInsets.fromLTRB(PageBlock.gutter, ReadInSpace.s3, PageBlock.gutter, ReadInSpace.s3),
                  child: BidiTextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    textCapitalization: TextCapitalization.none,
                    onChanged: (text) {
                      cubit.search(text);
                      setState(() {}); // the clear button
                    },
                    decoration: InputDecoration(
                      hintText: l10n.profileFollowSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(tooltip: l10n.clearSearch, icon: const Icon(Icons.close_rounded), onPressed: _clear),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: PageBlock.gap)),
              ...switch (state.status) {
                FollowListStatus.loading => [const SliverToBoxAdapter(child: PageBlock(child: _RowsSkeleton()))],
                FollowListStatus.failure => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: PageBlock(child: ErrorView(failure: state.failure!, onRetry: cubit.load)),
                    ),
                  ],
                FollowListStatus.ready when state.items.isEmpty => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: PageBlock(child: _Empty(kind: widget.kind, profile: widget.profile, query: state.query)),
                    ),
                  ],
                // One block of rows split by dividers (each row a slice of it, so the list stays lazy), then the
                // footer on the canvas.
                FollowListStatus.ready => [
                    SliverList.builder(
                      itemCount: state.items.length + 1,
                      itemBuilder: (context, i) => i < state.items.length
                          ? PageBlock(
                              padding: EdgeInsets.fromLTRB(
                                PageBlock.gutter,
                                i == 0 ? ReadInSpace.s1 : 0,
                                PageBlock.gutter,
                                i == state.items.length - 1 ? ReadInSpace.s1 : 0,
                              ),
                              child: i == 0
                                  ? WriterTile(user: state.items[i])
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [const Divider(), WriterTile(user: state.items[i])],
                                    ),
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

class _Empty extends StatelessWidget {
  const _Empty({required this.kind, required this.profile, required this.query});

  final FollowListKind kind;
  final UserProfile profile;
  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (query.isNotEmpty) {
      return EmptyView(icon: Icons.search_off_rounded, title: l10n.profileFollowNoResultsTitle, body: l10n.profileFollowNoResultsBody);
    }
    return switch (kind) {
      FollowListKind.followers => EmptyView(
          icon: Icons.group_outlined,
          title: l10n.profileFollowersEmptyTitle,
          body: profile.isMe ? l10n.profileFollowersEmptyOwnBody : null,
        ),
      FollowListKind.following => EmptyView(
          icon: Icons.person_add_alt_outlined,
          title: l10n.profileFollowingEmptyTitle,
          body: profile.isMe ? l10n.profileFollowingEmptyOwnBody : null,
        ),
    };
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final FollowListState state;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (state.loadingMore) {
      child = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5));
    } else if (state.loadMoreFailure != null) {
      child = ErrorView(failure: state.loadMoreFailure!, compact: true, onRetry: context.read<FollowListCubit>().loadMore);
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s4), child: Center(child: child));
  }
}

/// The canvas above a block.
const _blockGap = EdgeInsets.only(top: PageBlock.gap);

class _RowsSkeleton extends StatelessWidget {
  const _RowsSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s2),
        child: Column(
          children: [
            for (var i = 0; i < 6; i++)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: ReadInSpace.s2),
                child: Row(
                  children: [
                    SkeletonBox(width: 44, height: 44, radius: 22),
                    SizedBox(width: ReadInSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [SkeletonBox(width: 130), SizedBox(height: ReadInSpace.s2), SkeletonBox(width: 90, height: 12)],
                      ),
                    ),
                    SkeletonBox(width: 84, height: 36, radius: ReadInRadius.chip),
                  ],
                ),
              ),
          ],
        ),
      );
}

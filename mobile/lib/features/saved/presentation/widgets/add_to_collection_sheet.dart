import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/domain/entities/article.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../domain/entities/saved.dart';
import '../cubit/collections_cubit.dart';
import 'collection_dialogs.dart';

/// "Add to collection" (F13): tick a collection to put [article] in it (saving it first when needed), untick to take
/// it out (it stays saved), or create a new one. Guests get the sign-in prompt.
Future<void> showAddToCollectionSheet(BuildContext context, ArticleCard article) async {
  if (!requireAccount(context)) return;
  final collections = context.read<CollectionsCubit>();
  final engagement = context.read<EngagementCubit>();
  unawaited(collections.load());
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider<CollectionsCubit>.value(value: collections),
        BlocProvider<EngagementCubit>.value(value: engagement),
      ],
      child: AddToCollectionView(article: article),
    ),
  );
}

class AddToCollectionView extends StatefulWidget {
  const AddToCollectionView({super.key, required this.article});

  final ArticleCard article;

  @override
  State<AddToCollectionView> createState() => _AddToCollectionViewState();
}

class _AddToCollectionViewState extends State<AddToCollectionView> {
  /// Shown inside the sheet: a snack bar would sit behind it.
  String? _error;

  void _show(Failure? failure) {
    if (mounted) setState(() => _error = failure == null ? null : localizeActionFailure(context.l10n, failure));
  }

  /// The API saves the article when it goes into a collection; saving through the store first also keeps the
  /// device copy and every bookmark in step.
  Future<Failure?> _add(String collectionId) async {
    final engagement = context.read<EngagementCubit>();
    final collections = context.read<CollectionsCubit>();
    if (!engagement.of(widget.article).isSaved) {
      final failure = await engagement.setSaved(widget.article, saved: true);
      if (failure != null) return failure;
    }
    return collections.add(collectionId, widget.article.id);
  }

  Future<void> _toggle(ArticleCollection collection, bool member) async {
    _show(null);
    final collections = context.read<CollectionsCubit>();
    _show(member ? await _add(collection.id) : await collections.remove(collection.id, widget.article.id));
  }

  Future<void> _create() async {
    _show(null);
    final l10n = context.l10n;
    final collections = context.read<CollectionsCubit>();
    final created = await showCollectionNameDialog<ArticleCollection>(
      context,
      title: l10n.newCollection,
      action: l10n.createAction,
      submit: (name) async => switch (await collections.create(name)) {
        Ok(:final value) => (value, null),
        Err(:final failure) => (null, failure),
      },
    );
    if (created != null && mounted) _show(await _add(created.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final state = context.watch<CollectionsCubit>().state;
    final memberOf = state.collectionsOf(widget.article.id);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s5, 0, ReadInSpace.s2, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(header: true, child: Text(l10n.addToCollection, style: context.textTheme.titleMedium)),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s2),
                child: Semantics(
                  liveRegion: true,
                  child: Text(_error!, style: context.textTheme.bodySmall?.copyWith(color: colors.error)),
                ),
              ),
            ListTile(
              leading: Icon(Icons.add_rounded, color: colors.primary),
              title: Text(l10n.newCollection, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
              onTap: state.status == CollectionsStatus.failure ? null : _create,
            ),
            const Divider(height: 1),
            Flexible(
              child: switch (state.status) {
                CollectionsStatus.idle || CollectionsStatus.loading => const Padding(
                    padding: EdgeInsets.all(ReadInSpace.s6),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                CollectionsStatus.failure => ErrorView(
                    failure: state.failure!,
                    compact: true,
                    onRetry: () => context.read<CollectionsCubit>().load(force: true),
                  ),
                CollectionsStatus.ready when state.items.isEmpty => EmptyView(
                    icon: Icons.folder_open_rounded,
                    title: l10n.collectionsEmptyTitle,
                    body: l10n.collectionsEmptyBody,
                  ),
                CollectionsStatus.ready => ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
                    children: [
                      for (final collection in state.items)
                        _CollectionRow(
                          collection: collection,
                          member: memberOf.contains(collection.id),
                          busy: state.isBusy(collection.id, widget.article.id),
                          onChanged: (member) => _toggle(collection, member),
                        ),
                    ],
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.collection, required this.member, required this.busy, required this.onChanged});

  final ArticleCollection collection;
  final bool member;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
        value: member,
        onChanged: busy ? null : (value) => onChanged(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        secondary: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
        title: BidiText(collection.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(context.l10n.collectionArticles(collection.articleCount), style: context.textTheme.bodySmall),
      );
}

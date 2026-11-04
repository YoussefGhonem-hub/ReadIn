import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/domain/entities/article.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../../domain/entities/editor_entities.dart';
import '../cubit/revisions_cubit.dart';
import '../widgets/editor_widgets.dart';
import 'article_preview_page.dart';

/// Revision history (F05): one version per publish or update, newest first. Opening one previews it; "Restore this
/// version" copies it into the working copy through [onRestore] (live after Update).
class RevisionsPage extends StatelessWidget {
  const RevisionsPage({super.key, required this.author, required this.onRestore, this.fields = const [], this.topics = const []});

  final Author author;
  final List<Field> fields;
  final List<Topic> topics;

  /// Restores revision `number`; true when it worked (the pages close).
  final Future<bool> Function(int number) onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editorRevisions)),
      body: BlocBuilder<RevisionsCubit, RevisionsState>(
        builder: (context, state) => switch (state.status) {
          RevisionsStatus.loading => const Center(child: CircularProgressIndicator()),
          RevisionsStatus.failure => ErrorView(failure: state.failure!, onRetry: context.read<RevisionsCubit>().load),
          RevisionsStatus.ready when state.revisions.isEmpty =>
            EmptyView(title: l10n.revisionsEmpty, icon: Icons.history_rounded),
          RevisionsStatus.ready => RevisionsList(
              revisions: state.revisions,
              loading: state.loadingDetails,
              onOpen: (revision) => _open(context, revision),
            ),
        },
      ),
    );
  }

  Future<void> _open(BuildContext context, ArticleRevision revision) async {
    final cubit = context.read<RevisionsCubit>();
    final details = await cubit.loadDetails(revision.number);
    if (details == null || !context.mounted) {
      if (context.mounted) showActionFailure(context, cubit.state.detailsFailure);
      return;
    }
    final l10n = context.l10n;
    final document = details.document;
    final restored = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (page) => ArticlePreviewPage(
        title: l10n.revisionLabel(revision.number),
        data: PreviewData(
          document: document,
          author: author,
          media: details.media,
          field: fields.where((f) => f.id == document.fieldId).firstOrNull,
          topic: topics.where((t) => t.id == document.topicId).firstOrNull,
          publishedAt: revision.createdAt,
        ),
        actions: [
          TextButton(
            key: const ValueKey('revision-restore'),
            onPressed: () async {
              final ok = await confirmDialog(
                page,
                title: l10n.revisionRestoreTitle(revision.number),
                body: l10n.revisionRestoreBody,
                confirm: l10n.restoreAction,
              );
              if (!ok || !page.mounted) return;
              final done = await onRestore(revision.number);
              if (done && page.mounted) Navigator.of(page).pop(true);
            },
            child: Text(l10n.revisionRestore),
          ),
        ],
      ),
    ));
    if (restored == true && context.mounted) Navigator.of(context).pop(true);
  }
}

class RevisionsList extends StatelessWidget {
  const RevisionsList({super.key, required this.revisions, required this.onOpen, this.loading = const {}});

  final List<ArticleRevision> revisions;
  final Set<int> loading;
  final ValueChanged<ArticleRevision> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
      itemCount: revisions.length,
      separatorBuilder: (_, _) => Divider(height: 1, indent: ReadInSpace.s5, endIndent: ReadInSpace.s5, color: context.colors.border),
      itemBuilder: (context, i) {
        final r = revisions[i];
        return ListTile(
          key: ValueKey('revision-${r.number}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5, vertical: ReadInSpace.s1),
          leading: CircleAvatar(
            backgroundColor: context.colors.primaryContainer,
            foregroundColor: context.colors.onPrimaryContainer,
            child: Text('${r.number}'),
          ),
          title: BidiText(r.title.isEmpty ? l10n.untitledArticle : r.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: ReadInSpace.s1),
            child: Wrap(
              spacing: ReadInSpace.s2,
              runSpacing: ReadInSpace.s1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${l10n.revisionLabel(r.number)} · ${formatDate(r.createdAt, lang)}',
                  style: context.textTheme.bodySmall,
                ),
                if (r.number == 1) InfoTag(label: l10n.revisionFirst, tone: InfoTagTone.neutral),
                for (final language in r.languages) InfoTag(label: articleLanguageName(l10n, language), tone: InfoTagTone.neutral),
              ],
            ),
          ),
          trailing: loading.contains(r.number)
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
          onTap: () => onOpen(r),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../article/domain/entities/article.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import 'add_to_collection_sheet.dart';

/// 🔖 Save / unsave (F13), on feed cards, the reader and the Saved list. Applies at once, rolls back on failure, and
/// offers "Undo" after an unsave. Guests get the sign-in prompt.
class SaveToggleButton extends StatelessWidget {
  const SaveToggleButton({super.key, required this.article});

  final ArticleCard article;

  Future<void> _toggle(BuildContext context) async {
    if (!requireAccount(context)) return;
    final l10n = context.l10n;
    final engagement = context.read<EngagementCubit>();
    final saving = !engagement.of(article).isSaved;
    final failure = await engagement.setSaved(article, saved: saving);
    if (!context.mounted) return;
    if (failure != null) {
      showActionFailure(context, failure);
    } else if (saving) {
      showActionMessage(context, l10n.articleSaved);
    } else {
      showActionMessage(
        context,
        l10n.articleUnsaved,
        action: SnackBarAction(label: l10n.undo, onPressed: () => engagement.setSaved(article, saved: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final saved = context.select((EngagementCubit c) => c.state.of(article).isSaved);
    return IconButton(
      tooltip: saved ? l10n.unsaveArticle : l10n.saveArticle,
      isSelected: saved,
      icon: const Icon(Icons.bookmark_border_rounded),
      selectedIcon: Icon(Icons.bookmark_rounded, color: context.colors.primary),
      onPressed: () => _toggle(context),
    );
  }
}

/// Opens "add to collection" for [article] (F13).
class AddToCollectionButton extends StatelessWidget {
  const AddToCollectionButton({super.key, required this.article});

  final ArticleCard article;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: context.l10n.addToCollection,
        icon: const Icon(Icons.playlist_add_rounded),
        onPressed: () => showAddToCollectionSheet(context, article),
      );
}

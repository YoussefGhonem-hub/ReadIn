import '../../../../core/l10n/l10n_x.dart';
import '../../../article/domain/entities/article.dart';

/// 💡 مفيد · ❤️ · 🔥 · 🤯 (SPEC F10), in this order everywhere.
extension ReactionVisuals on ReactionType {
  String get emoji => switch (this) {
        ReactionType.insightful => '💡',
        ReactionType.love => '❤️',
        ReactionType.fire => '🔥',
        ReactionType.mindBlown => '🤯',
      };

  String label(AppLocalizations l10n) => switch (this) {
        ReactionType.insightful => l10n.reactionInsightful,
        ReactionType.love => l10n.reactionLove,
        ReactionType.fire => l10n.reactionFire,
        ReactionType.mindBlown => l10n.reactionMindBlown,
      };
}

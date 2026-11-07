import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../moderation/presentation/widgets/moderation_labels.dart' show embedContent;
import '../../domain/usecases/admin_usecases.dart';
import 'admin_widgets.dart';

/// Admin actions inside the normal app (F23), outside the console: each asks first («إلغاء» / «موافق»), calls the
/// existing endpoint, then says it's done or why it failed. Each returns true once it went through.
abstract final class AdminFlows {
  /// "Remove verified badge" from a profile's "⋯" (`verification.manage`). The user is told nothing (F19). A
  /// `409 verification.not_verified` means it is already gone: the caller reloads either way.
  static Future<bool> removeBadge(
    BuildContext context, {
    required String userId,
    required String name,
    AdminUserCommands? commands,
  }) async {
    final l10n = context.l10n;
    final confirmed = await confirmAdminAction(
      context,
      title: l10n.adminRemoveBadgeTitle(embedContent(name)),
      body: l10n.adminRemoveBadgeBody,
    );
    if (!confirmed || !context.mounted) return false;
    final result = await (commands ?? getIt<AdminUserCommands>()).removeBadge(userId);
    if (!context.mounted) return result.isOk;
    final failure = result.failureOrNull;
    if (failure == null) {
      showActionMessage(context, l10n.adminBadgeRemoved);
      return true;
    }
    showActionFailure(context, failure);
    return failure.code == FailureCodes.verificationNotVerified;
  }

  /// "Feature" / "Unfeature" from an article's "⋯" (`articles.feature`): it shows in, or leaves, Explore's featured
  /// articles.
  static Future<bool> setFeatured(
    BuildContext context, {
    required String articleId,
    required bool featured,
    SetArticleFeatured? setFeatured,
  }) async {
    final l10n = context.l10n;
    final confirmed = await confirmAdminAction(
      context,
      title: featured ? l10n.adminFeatureTitle : l10n.adminUnfeatureTitle,
      body: featured ? l10n.adminFeatureBody : l10n.adminUnfeatureBody,
    );
    if (!confirmed || !context.mounted) return false;
    final result = await (setFeatured ?? getIt<SetArticleFeatured>())(articleId, featured: featured);
    if (!context.mounted) return result.isOk;
    if (result.failureOrNull case final failure?) {
      showActionFailure(context, failure);
      return false;
    }
    showActionMessage(context, featured ? l10n.adminFeaturedDone : l10n.adminUnfeaturedDone);
    return true;
  }
}

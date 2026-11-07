import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../moderation/presentation/widgets/moderation_labels.dart';
import '../../domain/entities/admin_user.dart';

/// ar/en text for the console's enums (F23).
extension AdminLabels on AppLocalizations {
  String signInMethod(SignInMethod method) => switch (method) {
        SignInMethod.phone => adminSignInPhone,
        SignInMethod.google => 'Google',
        SignInMethod.apple => 'Apple',
      };

  String userSort(AdminUserSort sort) => switch (sort) {
        AdminUserSort.joined => adminSortJoined,
        AdminUserSort.lastSeen => adminSortLastSeen,
        AdminUserSort.followers => adminSortFollowers,
        AdminUserSort.openReports => adminSortOpenReports,
      };

  /// "Active", "Suspended until {date}" or "Permanently suspended".
  String accountStatus(AdminUserRow user) => user.suspended ? suspendedUntil(user.suspendedUntil) : adminStatusActive;

  /// An audit code as words; an unknown code shows as it is (contract: "Audit actions").
  String auditAction(String code) => switch (code) {
        'admin.pii_viewed' => adminAuditPiiViewed,
        'admin.sessions_revoked' => adminAuditSessionsRevoked,
        'admin.password_reset' => adminAuditPasswordReset,
        'admin.verification_approved' => adminAuditVerificationApproved,
        'admin.verification_rejected' => adminAuditVerificationRejected,
        'admin.verification_removed' => adminAuditVerificationRemoved,
        'moderation.content_hidden' || 'user.hide_content' => adminLogUserHideContent,
        'moderation.content_restored' || 'user.unhide_content' => adminLogUserUnhideContent,
        'admin.article_featured' => adminAuditArticleFeatured,
        'admin.article_unfeatured' => adminAuditArticleUnfeatured,
        'admin.ticket_replied' => supportAuditReplied,
        'admin.ticket_note_added' => supportAuditNoteAdded,
        'admin.ticket_closed' => supportAuditClosed,
        'admin.ticket_reopened' => supportAuditReopened,
        'admin.ticket_category_changed' => supportAuditCategoryChanged,
        _ => code,
      };
}

IconData signInMethodIcon(SignInMethod method) => switch (method) {
      SignInMethod.phone => Icons.phone_iphone_rounded,
      SignInMethod.google => Icons.g_mobiledata_rounded,
      SignInMethod.apple => Icons.apple_rounded,
    };

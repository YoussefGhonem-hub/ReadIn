import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../article/domain/entities/article.dart';
import '../../../comments/presentation/widgets/comment_body.dart' show commentTimeLabel;
import '../../../follow/domain/entities/follow.dart';
import '../../../profile/presentation/widgets/profile_header.dart' show ProfileBioText, UsernameText;
import '../../domain/entities/moderation.dart';
import 'moderation_labels.dart';

/// The clock moderation times are shown against (golden tests freeze it).
abstract final class ModerationClock {
  static DateTime Function() now = DateTime.now;
}

/// "3 hrs ago", "yesterday", then the date.
String moderationTime(BuildContext context, DateTime at) => commentTimeLabel(
      context.l10n,
      at,
      now: ModerationClock.now(),
      languageCode: Localizations.localeOf(context).languageCode,
    );

/// الكل · مقالات · تعليقات · مستخدمين.
class ModerationTypeFilter extends StatelessWidget {
  const ModerationTypeFilter({super.key, required this.selected, required this.onSelected});

  final ModerationTargetType? selected;
  final ValueChanged<ModerationTargetType?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4, vertical: ReadInSpace.s2),
      child: Row(
        children: [
          for (final type in <ModerationTargetType?>[null, ...ModerationTargetType.values])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s2),
              child: ChoiceChip(
                label: Text(l10n.typeFilter(type)),
                selected: selected == type,
                showCheckmark: false,
                onSelected: (_) => onSelected(type),
              ),
            ),
        ],
      ),
    );
  }
}

/// Hidden / Deleted / Suspended, nothing for visible content and active users.
class TargetStateTag extends StatelessWidget {
  const TargetStateTag({super.key, required this.state});

  final ModerationTargetState state;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.targetState(state);
    if (label == null) return const SizedBox.shrink();
    return InfoTag(
      label: label,
      icon: switch (state) {
        ModerationTargetState.hidden => Icons.visibility_off_outlined,
        ModerationTargetState.suspended => Icons.block_rounded,
        _ => Icons.delete_outline_rounded,
      },
      tone: state == ModerationTargetState.deleted ? InfoTagTone.neutral : InfoTagTone.accent,
    );
  }
}

/// Open / Resolved / Dismissed.
class ReportStatusTag extends StatelessWidget {
  const ReportStatusTag({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) => InfoTag(
        label: context.l10n.reportStatus(status),
        tone: switch (status) {
          ReportStatus.open => InfoTagTone.primary,
          ReportStatus.resolved => InfoTagTone.success,
          ReportStatus.dismissed => InfoTagTone.neutral,
        },
      );
}

/// "سبام 3", "إساءة أو تنمّر 1": the reports per reason, most first.
class ReasonCounts extends StatelessWidget {
  const ReasonCounts({super.key, required this.reasons});

  final Map<ReportReason, int> reasons;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Wrap(
      spacing: ReadInSpace.s1,
      runSpacing: ReadInSpace.s1,
      children: [
        for (final MapEntry(key: reason, value: count) in reasons.entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: 2),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(ReadInRadius.chip),
            ),
            child: Text(
              '${l10n.reportReason(reason)} $count',
              style: context.textTheme.labelSmall?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

/// An author or a user: avatar, name, ✓ and `@handle`; "Deleted user" when the account is gone.
class ModerationUserRow extends StatelessWidget {
  const ModerationUserRow({super.key, required this.user, this.avatarSize = 24, this.trailing});

  final Author? user;
  final double avatarSize;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final u = user;
    final name = u?.displayName ?? context.l10n.commentsDeletedUser;
    return Row(
      children: [
        ExcludeSemantics(child: UserAvatar(name: name, url: u?.avatarUrl, size: avatarSize)),
        const SizedBox(width: ReadInSpace.s2),
        // Name and handle share what [trailing] leaves; each is cut only when both don't fit.
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: BidiText(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.copyWith(color: u == null ? colors.textSecondary : colors.textPrimary),
                ),
              ),
              if (u?.isVerified ?? false) ...[const SizedBox(width: 4), const VerifiedMark(size: 14)],
              if (u != null) ...[
                const SizedBox(width: ReadInSpace.s1),
                Flexible(
                  child: UsernameText(u.username, style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary)),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: ReadInSpace.s2), trailing!],
      ],
    );
  }
}

/// [UserSummary] (reporters, moderators) as an [Author] for [ModerationUserRow].
Author? summaryAuthor(UserSummary? user) => user == null
    ? null
    : Author(
        id: user.id,
        displayName: user.displayName,
        username: user.username,
        avatarUrl: user.avatarUrl,
        isVerified: user.isVerified,
      );

/// What was reported: an article's title, a comment's text and article, or a user, with its author and state.
/// [maxLines] trims the text in lists; null shows all of it (the case page).
class ModerationTargetPreview extends StatelessWidget {
  const ModerationTargetPreview({super.key, required this.type, required this.target, this.maxLines});

  final ModerationTargetType type;
  final ModerationTarget target;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = switch (type) {
      ModerationTargetType.article => target.title,
      ModerationTargetType.comment || ModerationTargetType.repost => target.body,
      ModerationTargetType.user => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (type == ModerationTargetType.user)
          ModerationUserRow(user: target.author, avatarSize: 32)
        else ...[
          if (text != null && text.isNotEmpty)
            ProfileBioText(
              text,
              maxLines: maxLines,
              style: (type == ModerationTargetType.article ? context.textTheme.titleMedium : context.textTheme.bodyMedium)
                  ?.copyWith(color: colors.textPrimary, height: 1.5),
            ),
          if (type != ModerationTargetType.article && (target.articleTitle?.isNotEmpty ?? false)) ...[
            const SizedBox(height: ReadInSpace.s1),
            Text(
              type == ModerationTargetType.repost
                  ? l10n.moderationRepostOf(embedContent(target.articleTitle!))
                  : l10n.moderationCommentOn(embedContent(target.articleTitle!)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: ReadInSpace.s2),
          ModerationUserRow(user: target.author, avatarSize: 20),
        ],
        if (type == ModerationTargetType.user && (target.isSuspended || target.warningCount > 0)) ...[
          const SizedBox(height: ReadInSpace.s2),
          Text(
            [
              if (target.isSuspended) l10n.suspendedUntil(target.suspendedUntil),
              if (target.warningCount > 0) l10n.moderationWarningCount(target.warningCount),
            ].join(' · '),
            style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// One case in the queue: type and state, the target, report count, reasons and the last report (or when it was
/// closed). Tapping opens the case.
class ModerationQueueTile extends StatelessWidget {
  const ModerationQueueTile({super.key, required this.item, this.onTap});

  final ModerationQueueItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final closedAt = item.closedAt;
    final when = item.status == ReportStatus.open || closedAt == null
        ? l10n.moderationLastReport(moderationTime(context, item.lastReportedAt))
        : l10n.moderationClosed(moderationTime(context, closedAt));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4, vertical: ReadInSpace.s1),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReadInRadius.card),
          side: BorderSide(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(ReadInSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(targetTypeIcon(item.targetType), size: 18, color: colors.textSecondary),
                    const SizedBox(width: ReadInSpace.s1),
                    Text(l10n.targetType(item.targetType), style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary)),
                    const SizedBox(width: ReadInSpace.s2),
                    TargetStateTag(state: item.target.state),
                    if (item.urgent && item.status == ReportStatus.open) ...[
                      const SizedBox(width: ReadInSpace.s1),
                      const UrgentTag(),
                    ],
                    const Spacer(),
                    Text(
                      l10n.moderationReportCount(item.reportCount),
                      style: context.textTheme.labelMedium?.copyWith(color: colors.error, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: ReadInSpace.s3),
                ModerationTargetPreview(type: item.targetType, target: item.target, maxLines: 3),
                if (item.reasons.isNotEmpty) ...[
                  const SizedBox(height: ReadInSpace.s3),
                  ReasonCounts(reasons: item.reasons),
                ],
                const SizedBox(height: ReadInSpace.s2),
                Text(when, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                if (item.status == ReportStatus.open && item.ageHours != null) ...[
                  const SizedBox(height: ReadInSpace.s1),
                  Text(
                    l10n.moderationCaseAge(item.ageHours!),
                    key: const ValueKey('moderation-case-age'),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: item.urgent ? colors.error : colors.textSecondary,
                      fontWeight: item.urgent ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «عاجل» / "Urgent": an open case 12 hours old or more (SPEC F22: every report is handled within 24 hours).
class UrgentTag extends StatelessWidget {
  const UrgentTag({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: const ValueKey('moderation-urgent'),
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: 2),
      decoration: BoxDecoration(color: colors.error, borderRadius: BorderRadius.circular(ReadInRadius.chip)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 13, color: colors.onError),
          const SizedBox(width: 3),
          Text(
            context.l10n.moderationUrgent,
            style: context.textTheme.labelSmall?.copyWith(color: colors.onError, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// A report on the case page: reporter, reason, details, time, and who closed it. A report of the content filter
/// (F37) reads «فلتر المحتوى» with the words it matched.
class ModerationReportTile extends StatelessWidget {
  const ModerationReportTile({super.key, required this.report});

  final ModerationReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final details = report.details;
    final closedBy = report.closedBy;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (report.isSystem)
            Row(
              key: const ValueKey('moderation-report-system'),
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colors.surfaceVariant,
                  child: Icon(Icons.filter_alt_outlined, size: 16, color: colors.textSecondary),
                ),
                const SizedBox(width: ReadInSpace.s2),
                Expanded(child: Text(l10n.moderationContentFilter, style: context.textTheme.titleSmall)),
                Text(moderationTime(context, report.createdAt), style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondary)),
              ],
            )
          else
            ModerationUserRow(
              user: summaryAuthor(report.reporter),
              trailing: Text(moderationTime(context, report.createdAt), style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondary)),
            ),
          const SizedBox(height: ReadInSpace.s2),
          Row(
            children: [
              Flexible(child: Text(l10n.reportReason(report.reason), style: context.textTheme.titleSmall)),
              if (report.status != ReportStatus.open) ...[
                const SizedBox(width: ReadInSpace.s2),
                ReportStatusTag(status: report.status),
              ],
            ],
          ),
          if (report.matchedTerms case final terms? when terms.isNotEmpty) ...[
            const SizedBox(height: ReadInSpace.s1),
            Text(
              l10n.moderationMatchedTerms(terms.map(embedContent).join('، ')),
              key: const ValueKey('moderation-report-terms'),
              style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
            ),
          ],
          if (details != null && details.trim().isNotEmpty) ...[
            const SizedBox(height: ReadInSpace.s1),
            ProfileBioText(details, style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary, height: 1.5)),
          ],
          if (closedBy != null) ...[
            const SizedBox(height: ReadInSpace.s1),
            Text(
              l10n.moderationClosedBy(embedContent(closedBy.displayName)),
              style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// A row of the moderation log, on the Log tab and in a case's history: what was done to what, by whom and when, the
/// note, the suspension's end and the reports it closed.
class ModerationLogTile extends StatelessWidget {
  const ModerationLogTile({
    super.key,
    required this.entry,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: ReadInSpace.s4, vertical: ReadInSpace.s3),
  });

  final ModerationLogEntry entry;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final dir = Directionality.of(context);
    final label = entry.targetLabel;
    final note = entry.note;
    final moderator = entry.moderator?.displayName ?? l10n.commentsDeletedUser;
    final facts = [
      Bidi.isolateOppositeRuns(moderator, dir),
      moderationTime(context, entry.createdAt),
      if (entry.action == ModerationLogAction.userSuspend)
        switch (entry.suspendedUntil) {
          final until? => l10n.moderationLogUntil(formatDateTime(until, l10n.localeName)),
          null => l10n.moderationPermanent,
        },
      if (entry.reportsClosed > 0) l10n.moderationLogReportsClosed(entry.reportsClosed),
    ];
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: colors.surfaceVariant, shape: BoxShape.circle),
              child: Icon(logActionIcon(entry.action), size: 18, color: colors.textSecondary),
            ),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.logAction(entry.action), style: context.textTheme.titleSmall),
                  if (label != null && label.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    ProfileBioText(label, maxLines: 2, style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary)),
                  ],
                  if (note != null && note.trim().isNotEmpty) ...[
                    const SizedBox(height: ReadInSpace.s1),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: ReadInSpace.s2),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(ReadInRadius.sm),
                      ),
                      child: ProfileBioText(note, style: context.textTheme.bodySmall?.copyWith(color: colors.textPrimary, height: 1.5)),
                    ),
                  ],
                  const SizedBox(height: ReadInSpace.s1),
                  Text(facts.join(' · '), style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

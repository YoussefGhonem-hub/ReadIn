import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../moderation/domain/entities/moderation.dart';
import '../../../moderation/presentation/cubit/moderation_action_cubit.dart';
import '../../../moderation/presentation/moderation_routes.dart';
import '../../../moderation/presentation/widgets/moderation_flows.dart';
import '../../../moderation/presentation/widgets/moderation_labels.dart';
import '../../../moderation/presentation/widgets/moderation_widgets.dart' show ModerationUserRow;
import '../../../profile/presentation/widgets/profile_header.dart' show ProfileBioText;
import '../../domain/entities/admin_content.dart';
import '../admin_routes.dart';
import '../cubit/admin_lists.dart';
import '../widgets/admin_filters.dart';
import '../widgets/admin_widgets.dart';

/// The console's Content (`/admin/content`, `moderation.manage`, F23): published and archived articles (filters:
/// published in a period, field, topic, writer, hidden, featured, reported, a title search) and "Latest comments" with hide and delete.
class AdminContentPage extends StatelessWidget {
  const AdminContentPage({super.key, this.query, this.articlesCubit, this.commentsCubit, this.actions, this.taxonomy});

  /// From the dashboard: the period's articles.
  final AdminArticleQuery? query;

  /// Test seams; the app takes the cubits from DI.
  final AdminArticlesCubit? articlesCubit;
  final AdminCommentsCubit? commentsCubit;
  final ModerationActionCubit? actions;
  final AdminTaxonomyChoices? taxonomy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allowed = context.select((SessionCubit c) => c.state.me?.can(Permissions.moderationManage) ?? false);
    if (!allowed) return AdminNoAccessPage(title: l10n.adminSectionContent);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => (articlesCubit ?? getIt<AdminArticlesCubit>(param1: query))..load()),
        BlocProvider(create: (_) => (commentsCubit ?? getIt<AdminCommentsCubit>())..load()),
        BlocProvider(create: (_) => actions ?? getIt<ModerationActionCubit>()),
      ],
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.adminSectionContent),
            bottom: TabBar(tabs: [Tab(text: l10n.adminContentArticles), Tab(text: l10n.adminContentComments)]),
          ),
          body: TabBarView(
            children: [AdminArticlesView(taxonomy: taxonomy ?? getIt<AdminTaxonomyChoices>()), const AdminCommentsView()],
          ),
        ),
      ),
    );
  }
}

class AdminArticlesView extends StatelessWidget {
  const AdminArticlesView({super.key, required this.taxonomy});

  /// The fields and topics of the field and topic filters.
  final AdminTaxonomyChoices taxonomy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminArticlesCubit>();
    final query = context.select((AdminArticlesCubit c) => c.state.query);
    final language = Localizations.localeOf(context).languageCode;
    void set(AdminArticleQuery next) => unawaited(cubit.setQuery(next));
    return AdminPagedList<AdminArticlesCubit, AdminArticleRow, AdminArticleQuery>(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSearchField(hint: l10n.adminArticlesSearchHint, initial: query.q, onSearch: (q) => set(query.copyWith(q: q))),
          AdminChipRow(
            children: [
              // Published in a period (the dashboard's, or picked here), a field, one of its topics, a writer.
              AdminPickerChip(
                key: const ValueKey('admin-articles-period'),
                label: l10n.adminFilterPublished,
                value: query.hasPeriod ? adminRangeLabel(l10n, query.from, query.to) : null,
                onPick: () async {
                  final range = await AdminDatePicker.pickRange(context, adminRangeOf(query.from, query.to));
                  if (range == null) return;
                  final picked = adminRange(range);
                  set(query.copyWith(from: () => picked.from, to: () => picked.to));
                },
                onClear: () => set(query.copyWith(from: () => null, to: () => null)),
              ),
              AdminPickerChip(
                key: const ValueKey('admin-articles-field'),
                label: l10n.adminFilterField,
                value: query.field == null ? null : (query.fieldLabel ?? l10n.adminFilterField),
                onPick: () async {
                  final choice = await showAdminChoiceSheet(
                    context,
                    title: l10n.adminChooseField,
                    allLabel: l10n.adminAllFields,
                    selected: query.field,
                    load: () => taxonomy.fields(language),
                  );
                  if (choice == null) return;
                  set(query.withField(choice.id.isEmpty ? null : choice.id, label: choice.label));
                },
                onClear: () => set(query.withField(null)),
              ),
              if (query.field case final fieldId?)
                AdminPickerChip(
                  key: const ValueKey('admin-articles-topic'),
                  label: l10n.adminFilterTopic,
                  value: query.topic == null ? null : (query.topicLabel ?? l10n.adminFilterTopic),
                  onPick: () async {
                    final choice = await showAdminChoiceSheet(
                      context,
                      title: l10n.adminChooseTopic,
                      allLabel: l10n.adminAllTopics,
                      selected: query.topic,
                      load: () => taxonomy.topics(fieldId, language),
                    );
                    if (choice == null) return;
                    set(query.withTopic(choice.id.isEmpty ? null : choice.id, label: choice.label));
                  },
                  onClear: () => set(query.withTopic(null)),
                ),
              // A writer comes from a user's page in the console ("Their articles"); here it can only be cleared.
              if (query.writer != null)
                AdminPickerChip(
                  key: const ValueKey('admin-articles-writer'),
                  label: l10n.adminWriterChip(l10n.adminWriterUnknown),
                  value: l10n.adminWriterChip(query.writerLabel ?? l10n.adminWriterUnknown),
                  onPick: () {},
                  onClear: () => set(query.withWriter(null)),
                ),
              AdminFilterChip(
                label: l10n.adminFilterHidden,
                selected: query.hidden == true,
                onSelected: (on) => set(query.copyWith(hidden: () => on ? true : null)),
              ),
              AdminFilterChip(
                label: l10n.adminFilterFeatured,
                selected: query.featured == true,
                onSelected: (on) => set(query.copyWith(featured: () => on ? true : null, featuredOrder: on)),
              ),
              AdminFilterChip(
                label: l10n.adminFilterReported,
                selected: query.reported,
                onSelected: (on) => set(query.copyWith(reported: on)),
              ),
            ],
          ),
        ],
      ),
      countLabel: l10n.adminArticlesCount,
      emptyIcon: Icons.article_outlined,
      emptyTitle: l10n.adminArticlesEmpty,
      itemBuilder: (context, article) => AdminArticleTile(
        article: article,
        onTap: () async {
          await context.push<void>(AdminRoutes.article(article.id));
          if (context.mounted) unawaited(cubit.refresh());
        },
      ),
    );
  }
}

/// An article in Content: its title in its own direction, the writer, field, date and numbers, and its state.
class AdminArticleTile extends StatelessWidget {
  const AdminArticleTile({super.key, required this.article, this.onTap});

  final AdminArticleRow article;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final secondary = context.textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final language = Localizations.localeOf(context).languageCode;
    return AdminRow(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: article.language == 'en' ? TextDirection.ltr : TextDirection.rtl,
            child: BidiText(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall),
          ),
          const SizedBox(height: ReadInSpace.s1),
          ModerationUserRow(user: article.author, avatarSize: 18),
          const SizedBox(height: ReadInSpace.s1),
          Text(
            [
              article.field.nameFor(language),
              article.publishedAt == null ? l10n.adminNeverPublished : adminDay(context, article.publishedAt!),
              l10n.adminReads(article.readCount),
            ].join(' · '),
            style: secondary,
          ),
          if (article.isHidden || article.isFeatured || article.archived || article.openReports > 0) ...[
            const SizedBox(height: ReadInSpace.s2),
            AdminArticleTags(article: article),
          ],
        ],
      ),
    );
  }
}

/// Hidden · Featured · Archived · {n} open reports.
class AdminArticleTags extends StatelessWidget {
  const AdminArticleTags({super.key, required this.article});

  final AdminArticleRow article;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: ReadInSpace.s1,
      runSpacing: ReadInSpace.s1,
      children: [
        if (article.isHidden) InfoTag(label: l10n.moderationStateHidden, icon: Icons.visibility_off_outlined, tone: InfoTagTone.accent),
        if (article.isFeatured) InfoTag(label: l10n.adminFeatured, icon: Icons.star_rounded, tone: InfoTagTone.success),
        if (article.archived) InfoTag(label: l10n.adminArchived, tone: InfoTagTone.neutral),
        if (article.openReports > 0) InfoTag(label: l10n.adminOpenReports(article.openReports), icon: Icons.flag_outlined),
      ],
    );
  }
}

class AdminCommentsView extends StatelessWidget {
  const AdminCommentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminCommentsCubit>();
    final query = context.select((AdminCommentsCubit c) => c.state.query);
    return AdminPagedList<AdminCommentsCubit, AdminCommentRow, AdminCommentQuery>(
      header: AdminChipRow(
        children: [
          AdminFilterChip(
            label: l10n.moderationFilterAll,
            selected: query.hidden == null,
            onSelected: (_) => unawaited(cubit.setQuery(const AdminCommentQuery())),
          ),
          AdminFilterChip(
            label: l10n.adminFilterVisible,
            selected: query.hidden == false,
            onSelected: (_) => unawaited(cubit.setQuery(const AdminCommentQuery(hidden: false))),
          ),
          AdminFilterChip(
            label: l10n.adminFilterHidden,
            selected: query.hidden == true,
            onSelected: (_) => unawaited(cubit.setQuery(const AdminCommentQuery(hidden: true))),
          ),
        ],
      ),
      emptyIcon: Icons.chat_bubble_outline_rounded,
      emptyTitle: l10n.adminCommentsEmpty,
      itemBuilder: (context, comment) => AdminCommentTile(comment: comment),
    );
  }
}

/// What the "⋯" of a comment in "Latest comments" offers.
enum AdminCommentAction { open, reports, hide, unhide, delete }

/// A comment in "Latest comments": the writer, the text in its own direction, its article and time, its state and
/// reports; "⋯" opens the article, hides or unhides it, or deletes it.
class AdminCommentTile extends StatelessWidget {
  const AdminCommentTile({super.key, required this.comment});

  final AdminCommentRow comment;

  Future<void> _onSelected(BuildContext context, AdminCommentAction action) async {
    final cubit = context.read<AdminCommentsCubit>();
    final target = ModerationTargetRef.comment(comment.id);
    switch (action) {
      case AdminCommentAction.open:
        final slug = Uri.encodeComponent(comment.article.slug);
        await context.push<void>('/a/$slug?lang=${comment.article.language}#comment-${comment.id}');
      case AdminCommentAction.reports:
        await context.push<void>(ModerationRoutes.caseOf(target));
        if (context.mounted) unawaited(cubit.refresh());
      case AdminCommentAction.hide:
        if (await ModerationFlows.hide(context, target)) cubit.replace(comment.copyWith(hiddenAt: () => DateTime.now().toUtc()));
      case AdminCommentAction.unhide:
        if (await ModerationFlows.unhide(context, target)) cubit.replace(comment.copyWith(hiddenAt: () => null));
      case AdminCommentAction.delete:
        if (await ModerationFlows.deleteComment(context, comment.id)) cubit.remove(comment.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final secondary = context.textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    return AdminRow(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: ModerationUserRow(user: comment.author, avatarSize: 22)),
              PopupMenuButton<AdminCommentAction>(
                key: ValueKey('admin-comment-menu-${comment.id}'),
                tooltip: l10n.adminCommentMenu,
                icon: Icon(Icons.more_horiz_rounded, color: colors.textSecondary),
                onSelected: (action) => unawaited(_onSelected(context, action)),
                itemBuilder: (_) => [
                  PopupMenuItem(value: AdminCommentAction.open, child: Text(l10n.adminOpenComment)),
                  if (comment.reportCount > 0) PopupMenuItem(value: AdminCommentAction.reports, child: Text(l10n.adminSeeReports)),
                  if (comment.isHidden)
                    PopupMenuItem(value: AdminCommentAction.unhide, child: Text(l10n.moderationUnhideComment))
                  else
                    PopupMenuItem(value: AdminCommentAction.hide, child: Text(l10n.moderationHideComment)),
                  PopupMenuItem(
                    value: AdminCommentAction.delete,
                    child: Text(l10n.moderationDeleteComment, style: TextStyle(color: colors.error)),
                  ),
                ],
              ),
            ],
          ),
          ProfileBioText(
            comment.body,
            maxLines: 4,
            style: context.textTheme.bodyMedium?.copyWith(color: comment.isHidden ? colors.textSecondary : colors.textPrimary),
          ),
          const SizedBox(height: ReadInSpace.s1),
          Text(
            l10n.moderationCommentOn(embedContent(comment.article.title)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: secondary,
          ),
          Text(
            [
              adminTime(context, comment.createdAt),
              if (comment.parentId != null) l10n.adminReply,
            ].join(' · '),
            style: secondary,
          ),
          if (comment.isHidden || comment.openReports > 0) ...[
            const SizedBox(height: ReadInSpace.s1),
            Wrap(
              spacing: ReadInSpace.s1,
              children: [
                if (comment.isHidden) InfoTag(label: l10n.moderationStateHidden, icon: Icons.visibility_off_outlined, tone: InfoTagTone.accent),
                if (comment.openReports > 0) InfoTag(label: l10n.adminOpenReports(comment.openReports), icon: Icons.flag_outlined),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

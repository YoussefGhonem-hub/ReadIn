import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../moderation/domain/entities/moderation.dart';
import '../../../moderation/presentation/cubit/moderation_action_cubit.dart';
import '../../../moderation/presentation/moderation_routes.dart';
import '../../../moderation/presentation/widgets/moderation_flows.dart';
import '../../../moderation/presentation/widgets/moderation_widgets.dart' show ModerationUserRow;
import '../../domain/entities/admin_content.dart';
import '../admin_routes.dart';
import '../cubit/admin_article_cubit.dart';
import '../cubit/admin_user_cubit.dart' show AdminPageStatus;
import '../widgets/admin_widgets.dart';
import 'admin_content_page.dart' show AdminArticleTags;

/// An article in the console (`/admin/content/{id}`, "Open in console", F23): its numbers and state; open it, hide or
/// unhide it, feature or unfeature it (`articles.feature`), see its reports.
class AdminArticlePage extends StatelessWidget {
  const AdminArticlePage({super.key, required this.articleId, this.cubit, this.actions});

  final String articleId;

  /// Test seams; the app takes the cubits from DI.
  final AdminArticleCubit? cubit;
  final ModerationActionCubit? actions;

  @override
  Widget build(BuildContext context) {
    final allowed = context.select((SessionCubit c) => c.state.me?.can(Permissions.moderationManage) ?? false);
    if (!allowed) return AdminNoAccessPage(title: context.l10n.adminSectionContent);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => (cubit ?? getIt<AdminArticleCubit>(param1: articleId))..load()),
        BlocProvider(create: (_) => actions ?? getIt<ModerationActionCubit>()),
      ],
      child: const AdminArticleView(),
    );
  }
}

class AdminArticleView extends StatelessWidget {
  const AdminArticleView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminArticleCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminArticleTitle)),
      body: BlocBuilder<AdminArticleCubit, AdminArticleState>(
        builder: (context, state) => switch (state.status) {
          AdminPageStatus.loading => const Center(child: CircularProgressIndicator()),
          AdminPageStatus.failure => ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.load())),
          AdminPageStatus.ready => _Body(article: state.article!, featuring: state.featuring),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.article, required this.featuring});

  final AdminArticleRow article;
  final bool featuring;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<AdminArticleCubit>();
    final me = context.select((SessionCubit c) => c.state.me);
    final canFeature = me?.canFeature ?? false;
    final canReadUsers = me?.canReadUsers ?? false;
    final language = Localizations.localeOf(context).languageCode;
    final target = ModerationTargetRef.article(article.id);
    final author = article.author;
    final featuredAt = article.featuredAt;
    final hiddenAt = article.hiddenAt;
    return RefreshIndicator(
      onRefresh: () async {
        final failure = await cubit.load();
        if (context.mounted) showActionFailure(context, failure);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: ReadInSpace.s6),
        children: [
          PageBlock(
            margin: const EdgeInsets.only(top: PageBlock.gap),
            padding: const EdgeInsets.all(PageBlock.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Directionality(
                  textDirection: article.language == 'en' ? TextDirection.ltr : TextDirection.rtl,
                  child: BidiText(article.title, style: context.textTheme.titleLarge),
                ),
                const SizedBox(height: ReadInSpace.s2),
                ModerationUserRow(user: author, avatarSize: 24),
                const SizedBox(height: ReadInSpace.s3),
                AdminArticleTags(article: article),
              ],
            ),
          ),
          PageBlock(
            margin: const EdgeInsets.only(top: PageBlock.gap),
            padding: const EdgeInsets.all(PageBlock.gutter),
            child: Column(
              children: [
                AdminInfoRow(
                  label: l10n.adminArticleField,
                  value: [article.field.nameFor(language), ?article.topic?.nameFor(language)].join(' · '),
                ),
                AdminInfoRow(
                  label: l10n.adminArticlePublished,
                  value: article.publishedAt == null ? l10n.adminNeverPublished : adminDateTime(context, article.publishedAt!),
                ),
                AdminInfoRow(label: l10n.adminCardReads, value: adminNumber(article.readCount)),
                AdminInfoRow(label: l10n.adminCardReactions, value: adminNumber(article.reactionCount)),
                AdminInfoRow(label: l10n.adminCardComments, value: adminNumber(article.commentCount)),
                AdminInfoRow(label: l10n.adminArticleReports, value: adminNumber(article.reportCount)),
                if (hiddenAt != null) AdminInfoRow(label: l10n.adminArticleHiddenAt, value: adminDateTime(context, hiddenAt)),
                if (featuredAt != null) AdminInfoRow(label: l10n.adminArticleFeaturedAt, value: adminDateTime(context, featuredAt)),
              ],
            ),
          ),
          PageBlock(
            margin: const EdgeInsets.only(top: PageBlock.gap),
            padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s2),
            child: Column(
              children: [
                if (!article.isHidden)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.open_in_new_rounded),
                    title: Text(l10n.moderationOpenArticle),
                    onTap: () => unawaited(context.push<void>('/a/${Uri.encodeComponent(article.slug)}?lang=${article.language}')),
                  ),
                if (canFeature && !article.isHidden && !article.archived || canFeature && article.isFeatured)
                  ListTile(
                    key: const ValueKey('admin-article-feature'),
                    contentPadding: EdgeInsets.zero,
                    enabled: !featuring,
                    leading: Icon(article.isFeatured ? Icons.star_outline_rounded : Icons.star_rounded),
                    title: Text(article.isFeatured ? l10n.adminUnfeature : l10n.adminFeature),
                    subtitle: Text(l10n.adminFeatureHint),
                    onTap: () => unawaited(_toggleFeatured(context)),
                  ),
                ListTile(
                  key: const ValueKey('admin-article-hide'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(article.isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: article.isHidden ? null : colors.error),
                  title: Text(
                    article.isHidden ? l10n.articleMenuUnhide : l10n.articleMenuHide,
                    style: article.isHidden ? null : TextStyle(color: colors.error),
                  ),
                  onTap: () async {
                    final done = article.isHidden ? await ModerationFlows.unhide(context, target) : await ModerationFlows.hide(context, target);
                    if (done) await cubit.refresh();
                  },
                ),
                if (article.reportCount > 0)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_outlined),
                    title: Text(l10n.adminSeeReports),
                    onTap: () async {
                      await context.push<void>(ModerationRoutes.caseOf(target));
                      if (context.mounted) unawaited(cubit.refresh());
                    },
                  ),
                if (canReadUsers && author != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text(l10n.adminOpenWriter),
                    onTap: () => unawaited(context.push<void>(AdminRoutes.user(author.id))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFeatured(BuildContext context) async {
    final l10n = context.l10n;
    final feature = !article.isFeatured;
    final confirmed = await confirmAdminAction(
      context,
      title: feature ? l10n.adminFeatureTitle : l10n.adminUnfeatureTitle,
      body: feature ? l10n.adminFeatureBody : l10n.adminUnfeatureBody,
    );
    if (!confirmed || !context.mounted) return;
    final failure = await context.read<AdminArticleCubit>().setFeatured(feature);
    if (!context.mounted) return;
    failure == null ? showActionMessage(context, feature ? l10n.adminFeaturedDone : l10n.adminUnfeaturedDone) : showActionFailure(context, failure);
  }
}

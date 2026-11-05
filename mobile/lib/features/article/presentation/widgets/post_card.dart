import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/rdoc_view.dart';
import '../../../../shared/utils/link_opener.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../comments/presentation/widgets/comment_body.dart' show CommentClock, commentTimeLabel;
import '../../../comments/presentation/widgets/comment_tile.dart' show CommentsSheetExit;
import '../../../comments/presentation/widgets/comments_sheet.dart';
import '../../../follow/presentation/widgets/follow_button.dart';
import '../../../glossary/presentation/widgets/glossary_sheet.dart';
import '../../../media/domain/entities/media.dart';
import '../../../moderation/presentation/cubit/moderation_action_cubit.dart';
import '../../../profile/presentation/profile_routes.dart';
import '../../../profile/presentation/widgets/profile_link.dart';
import '../../../reactions/presentation/widgets/reaction_button.dart';
import '../../../reactions/presentation/widgets/who_reacted_sheet.dart';
import '../../../reading/presentation/tracking/post_card_reading.dart';
import '../../../saved/presentation/widgets/save_button.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/entities/article.dart';
import '../../domain/usecases/get_article_preview.dart';
import '../cubit/engagement_cubit.dart';
import '../cubit/post_cards_cubit.dart';
import 'article_attachments_view.dart';
import 'article_menu.dart';
import 'article_share_button.dart';
import 'attachment_viewers.dart';
import 'post_card_text.dart';

/// An article in a list as a social post (SPEC F34): an optional label, the writer with field, time and reading time
/// (follow, save and "⋯" on the other side), the title, the beginning of the article with "Read more", the
/// attachments or the cover, up to three tags, the counts and the action bar (react, comment, share).
///
/// The card is not one link: the title opens the reader, the text expands in place, an image opens the viewer, the
/// writer opens their profile and a tag its tag page (F32). Counts and the viewer's reaction and save follow [EngagementCubit] (live counters,
/// F27). A [PostCardsCubit] above keeps the expanded cards of the list; without one the card keeps its own.
class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.article, this.label, this.onOpen});

  final ArticleCard article;

  /// Above the header, e.g. "مقال النهارده" on Home's daily article (F07).
  final String? label;

  /// Opens the reader; by default the article's page is pushed.
  final VoidCallback? onOpen;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  PostCardsCubit? _own;
  late PostCardsCubit _cards;

  /// "Read more" and "Show less" share it, so the keyboard focus stays on the card (F34 accessibility).
  final _toggleFocus = FocusNode(debugLabel: 'post-card-toggle');

  // Comments closed by opening a profile from them open again when the viewer comes back (F34).
  bool _reopenComments = false;
  bool _covered = false;

  ArticleCard get _article => widget.article;

  static Future<Result<ArticlePreview>> _loadPreview(String articleId, {required String language}) =>
      getIt<GetArticlePreview>()(articleId, language: language);

  void _findCards() => _cards = context.read<PostCardsCubit?>() ?? (_own ??= PostCardsCubit.withLoader(_loadPreview));

  @override
  void didUpdateWidget(PostCard old) {
    super.didUpdateWidget(old);
    _findCards();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _findCards();
    // Ticking stops while another screen covers the list.
    final visible = TickerMode.valuesOf(context).enabled;
    if (!visible) {
      _covered = _reopenComments;
    } else if (_covered) {
      _covered = false;
      _reopenComments = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_openComments());
      });
    }
  }

  @override
  void dispose() {
    _toggleFocus.dispose();
    unawaited(_own?.close());
    super.dispose();
  }

  void _open() {
    if (widget.onOpen case final open?) {
      open();
    } else {
      unawaited(context.push<void>('/a/${_article.slug}'));
    }
  }

  void _expand() {
    _keepFocus(_toggleFocus.hasFocus);
    unawaited(_cards.expand(_article));
  }

  void _collapse() {
    _keepFocus(_toggleFocus.hasFocus);
    _cards.collapse(_article.id);
    // Collapsing brings the card's top back into view if it scrolled off; otherwise nothing moves.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : ReadInMotion.base,
        curve: Curves.easeOutCubic,
      ));
    });
  }

  void _keepFocus(bool hadFocus) {
    if (!hadFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _toggleFocus.requestFocus();
    });
  }

  /// The full comments in a bottom sheet; the feed stays where it was behind it (F34 on phones).
  Future<void> _openComments() async {
    final exit = await showCommentsSheet(context, article: _article);
    if (mounted && exit == CommentsSheetExit.openedProfile) _reopenComments = true;
  }

  /// A glossary term in the expanded text (F21), for the version shown; an article picked there opens like any other.
  Future<void> _showTerm(RTerm term, String language) async {
    final router = GoRouter.maybeOf(context);
    final slug = await showGlossarySheet(context, termId: term.termId, text: term.text, language: language, articleId: _article.id);
    if (slug != null && mounted) unawaited(router?.push<void>('/a/$slug'));
  }

  /// An @mention in the expanded text opens that profile, as in the reader.
  void _openMention(RMention mention) {
    final router = GoRouter.maybeOf(context);
    if (router != null && mention.text.replaceFirst('@', '').isNotEmpty) {
      unawaited(router.push<void>(ProfileRoutes.of(mention.text)));
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<PostCardsCubit, PostCardsState>(
        bloc: _cards,
        buildWhen: (a, b) => a.of(_article.id) != b.of(_article.id),
        builder: (context, cards) {
          final article = _article;
          final view = cards.of(article.id);
          final language = view.preview?.language ?? article.language;
          final colors = context.colors;
          return Semantics(
            container: true,
            explicitChildNodes: true,
            child: Material(
              color: colors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.label case final label?) _PostLabel(label: label),
                  _PostHeader(
                    article: article,
                    hidden: view.hidden,
                    onModerated: (moderation) => _cards.setHidden(article.id, hidden: moderation != null),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, ReadInSpace.s2, ReadInSpace.s4, 0),
                    child: _PostTitle(article: article, onOpen: _open),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, ReadInSpace.s1, ReadInSpace.s4, 0),
                    child: RDocScope(
                      baseDirection: RDocScope.directionForLanguage(language),
                      bodyFontSize: ReadInArticleFontScale.s,
                      onLinkTap: openExternalLink,
                      onTermTap: (term) => unawaited(_showTerm(term, language)),
                      onMentionTap: _openMention,
                      child: PostCardText(
                        article: article,
                        view: view,
                        onExpand: _expand,
                        onCollapse: _collapse,
                        onRetry: () => unawaited(_cards.retry(article)),
                        onOpen: _open,
                        toggleFocus: _toggleFocus,
                        // An article shown whole here counts as read like in the reader (F04, F34).
                        completeWrapper: (child) => PostCardReading(articleId: article.id, language: language, child: child),
                      ),
                    ),
                  ),
                  _PostMedia(article: article),
                  if (article.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, ReadInSpace.s3, ReadInSpace.s4, 0),
                      child: _PostTags(article: article),
                    ),
                  _PostCounts(article: article, onComments: () => unawaited(_openComments())),
                  Divider(height: 1, indent: ReadInSpace.s4, endIndent: ReadInSpace.s4, color: colors.border),
                  _PostActions(article: article, onComments: () => unawaited(_openComments())),
                ],
              ),
            ),
          );
        },
      );
}

/// "✦ مقال النهارده" over the header, with a hairline under it.
class _PostLabel extends StatelessWidget {
  const _PostLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, ReadInSpace.s3, ReadInSpace.s4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: colors.primary),
              const SizedBox(width: ReadInSpace.s1),
              Flexible(
                child: Text(label, style: context.textTheme.labelMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: ReadInSpace.s2),
          Divider(height: 1, color: colors.border),
        ],
      ),
    );
  }
}

/// Avatar and name (the profile), field · time since publishing · reading time; follow, save and "⋯" on the other
/// side. A deleted author is "Deleted user", with no profile link and no follow (SPEC §9.6).
class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.article, required this.hidden, required this.onModerated});

  final ArticleCard article;
  final bool hidden;
  final ValueChanged<ArticleModeration?> onModerated;

  static const _avatar = 40.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final uiLang = Localizations.localeOf(context).languageCode;
    final uiDir = Directionality.of(context);
    final author = article.author;
    final myId = context.select((SessionCubit c) => c.state.me?.id);
    // Each part stays on one line (no-break spaces inside it): a narrow header wraps only between parts.
    final meta = [
      article.field.nameFor(uiLang),
      commentTimeLabel(l10n, article.publishedAt, now: CommentClock.now(), languageCode: uiLang),
      l10n.readingTime(article.readingTimeMinutes),
    ].map((part) => Bidi.isolateOppositeRuns(part.replaceAll(' ', ' '), uiDir)).join(' · ');
    final metaText = Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall);

    final Widget writer = author == null
        ? Row(
            children: [
              const GenericAvatar(size: _avatar),
              const SizedBox(width: ReadInSpace.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.deletedUser, maxLines: 1, style: context.textTheme.titleSmall?.copyWith(color: colors.textSecondary)),
                    metaText,
                  ],
                ),
              ),
            ],
          )
        : ProfileLink(
            username: author.username,
            child: Row(
              children: [
                UserAvatar(name: author.displayName, url: author.avatarUrl, size: _avatar),
                const SizedBox(width: ReadInSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: BidiText(author.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall),
                          ),
                          if (author.isVerified) ...[const SizedBox(width: 4), const VerifiedMark()],
                        ],
                      ),
                      metaText,
                    ],
                  ),
                ),
              ],
            ),
          );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s4, ReadInSpace.s3, ReadInSpace.s1, 0),
      child: Row(
        children: [
          Expanded(child: writer),
          // Follow while you don't follow the writer and it isn't your article; guests get the sign-in prompt.
          if (author != null && author.id != myId && !article.isFollowingAuthor)
            FollowButton(userId: author.id, name: author.displayName, text: true),
          SaveToggleButton(article: article),
          // Hiding from the card needs the moderation cubit; it is created only when a moderator uses it (F22).
          BlocProvider(
            create: (_) => getIt<ModerationActionCubit>(),
            child: ArticleMenuView(card: article, hidden: hidden, onModerated: onModerated),
          ),
        ],
      ),
    );
  }
}

/// The title, up to three lines: it opens the reader.
class _PostTitle extends StatelessWidget {
  const _PostTitle({required this.article, required this.onOpen});

  final ArticleCard article;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final titleDir = Bidi.detect(article.title) ?? RDocScope.directionForLanguage(article.language);
    return MergeSemantics(
      child: Semantics(
        link: true,
        hint: context.l10n.postOpenArticleHint,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(ReadInRadius.sm),
          child: Text(
            Bidi.isolateOppositeRuns(article.title, titleDir),
            textDirection: titleDir,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium?.copyWith(height: 1.5),
          ),
        ),
      ),
    );
  }
}

/// The post's attachments (F26), else its cover full width at 16:9, else nothing (no placeholder).
class _PostMedia extends StatelessWidget {
  const _PostMedia({required this.article});

  final ArticleCard article;

  /// The cover as a single image for the full-screen viewer, contained in a 16:9 frame.
  static ImageAttachment coverImage(String url) => ImageAttachment(
        assetId: 'cover',
        altText: '',
        width: 16,
        height: 9,
        variants: [MediaVariant(width: 1600, height: 900, url: url)],
      );

  @override
  Widget build(BuildContext context) {
    if (article.attachments != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, ReadInSpace.s3, ReadInSpace.s4, 0),
        child: ArticleAttachmentsView(article: article),
      );
    }
    final cover = article.coverUrl;
    if (cover == null || cover.isEmpty) return const SizedBox.shrink();
    void open() => unawaited(openImageViewer(context, article: article, images: [coverImage(cover)], index: 0));
    return Padding(
      padding: const EdgeInsets.only(top: ReadInSpace.s3),
      child: Semantics(
        button: true,
        image: true,
        label: context.l10n.postCoverImage,
        onTap: open,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: open,
          child: AspectRatio(aspectRatio: 16 / 9, child: AppNetworkImage(url: cover, borderRadius: BorderRadius.zero)),
        ),
      ),
    );
  }
}

/// Up to three tags, each opening its tag page (F32), then "+N", which opens nothing.
class _PostTags extends StatelessWidget {
  const _PostTags({required this.article});

  final ArticleCard article;

  @override
  Widget build(BuildContext context) =>
      TagChipsWrap(tags: article.tags, more: article.tagCount - article.tags.length);
}

/// Up to three reaction emojis and the total (who reacted) and "12 تعليق" (the comments). Nothing while both are 0.
class _PostCounts extends StatelessWidget {
  const _PostCounts({required this.article, required this.onComments});

  final ArticleCard article;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final engagement = context.select((EngagementCubit c) => c.state.of(article));
    final reactions = engagement.reactionCount;
    final comments = engagement.commentCount;
    if (reactions <= 0 && comments <= 0) return const SizedBox(height: ReadInSpace.s2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s3, ReadInSpace.s1, ReadInSpace.s3, 0),
      child: Row(
        children: [
          ReactionStackSummary(
            reactions: engagement.reactions,
            total: reactions,
            onTap: () => unawaited(
              showWhoReactedSheet(context, articleId: article.id, reactions: engagement.reactions, total: reactions),
            ),
          ),
          const Spacer(),
          if (comments > 0)
            Semantics(
              button: true,
              label: l10n.commentsCount(comments),
              onTapHint: l10n.commentsOpen,
              excludeSemantics: true,
              child: InkWell(
                onTap: onComments,
                borderRadius: BorderRadius.circular(ReadInRadius.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s1),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        l10n.commentsCount(comments),
                        style: context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// React, Comment and Share, always shown; none of them leaves the feed (F34).
class _PostActions extends StatelessWidget {
  const _PostActions({required this.article, required this.onComments});

  final ArticleCard article;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s1),
      child: Row(
        children: [
          Expanded(child: ReactionButton(article: article, labeled: true)),
          Expanded(child: _ActionButton(icon: Icons.chat_bubble_outline_rounded, label: l10n.postComment, onTap: onComments)),
          Expanded(
            child: Builder(
              builder: (context) => _ActionButton(
                icon: Icons.ios_share_rounded,
                label: l10n.share,
                onTap: () => unawaited(ArticleShareButton.share(context, article)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ReadInRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: ReadInSpace.s1),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A post card while its list loads (static, so "reduce motion" is respected).
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: context.colors.surface,
        child: const Padding(
          padding: EdgeInsets.all(ReadInSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 40, height: 40, radius: 20),
                  SizedBox(width: ReadInSpace.s2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 140),
                      SizedBox(height: ReadInSpace.s2),
                      SkeletonBox(width: 100, height: 12),
                    ],
                  ),
                ],
              ),
              SizedBox(height: ReadInSpace.s4),
              SkeletonBox(height: 18),
              SizedBox(height: ReadInSpace.s2),
              SkeletonBox(width: 220, height: 18),
              SizedBox(height: ReadInSpace.s4),
              SkeletonBox(),
              SizedBox(height: ReadInSpace.s2),
              SkeletonBox(),
              SizedBox(height: ReadInSpace.s2),
              SkeletonBox(width: 180),
            ],
          ),
        ),
      );
}

/// A list's post cards from the top: one card after another on `color.bg`, [ReadInSpace.s2] apart (F34).
const postCardGap = ReadInSpace.s2;

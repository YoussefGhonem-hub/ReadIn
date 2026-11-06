import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/blocks/text_blocks.dart';
import '../../../../shared/rdoc/rdoc_view.dart';
import '../../../../shared/utils/link_opener.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article_pdf/presentation/cubit/article_pdf_cubit.dart';
import '../../../article_pdf/presentation/widgets/article_pdf_widgets.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../comments/presentation/widgets/article_comments_section.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../../follow/presentation/widgets/follow_button.dart';
import '../../../glossary/presentation/widgets/glossary_sheet.dart';
import '../../../highlights/presentation/cubit/article_highlights_cubit.dart';
import '../../../highlights/presentation/widgets/reader_highlights.dart';
import '../../../moderation/presentation/cubit/moderation_action_cubit.dart';
import '../../../mutes/presentation/widgets/muted_writer_banner.dart';
import '../../../paths/presentation/widgets/next_in_path.dart';
import '../../../profile/presentation/profile_routes.dart';
import '../../../reading/presentation/tracking/reading_tracking.dart';
import '../../../saved/presentation/cubit/collections_cubit.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/article.dart';
import '../cubit/article_cubit.dart';
import '../cubit/article_live_cubit.dart';
import '../cubit/engagement_cubit.dart';
import '../widgets/article_attachments_view.dart';
import '../widgets/article_menu.dart';
import '../widgets/article_share_button.dart';
import '../widgets/article_toc.dart';
import '../widgets/reader_action_bar.dart';
import '../widgets/reader_resume.dart';
import '../widgets/reader_widgets.dart';
import '../widgets/related_articles_section.dart';

/// Article reader (F04). Deep link: `readin.app/a/{slug}`.
class ArticlePage extends StatelessWidget {
  const ArticlePage({super.key, required this.slug, this.anchor, this.language});

  final String slug;

  /// The block or comment the link points at (`#…`); null opens the article where the reader left it.
  final String? anchor;

  /// The version to open (`?lang=`, e.g. Continue reading's); null = the preferred article language.
  final String? language;

  @override
  Widget build(BuildContext context) {
    final preferred = language ?? _preferredArticleLanguage(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ArticleCubit>()..load(slug, preferredLanguage: preferred)),
        BlocProvider(create: (_) => getIt<ArticleLiveCubit>()),
        // Created when a moderator hides or unhides from the menu (F22).
        BlocProvider(create: (_) => getIt<ModerationActionCubit>()),
        // "تحميل PDF" in the "⋯" menu, on every article (F33); its failures show here, with "حاول تاني".
        BlocProvider(create: (_) => getIt<ArticlePdfCubit>()),
        // Highlights (F30): yours and the popular ones for the version on screen, loaded once they are shown.
        BlocProvider(create: (_) => getIt<ArticleHighlightsCubit>()),
      ],
      child: ArticlePdfFeedback(child: ReadingTracking(child: ArticleView(anchor: anchor))),
    );
  }
}

/// The version the reader opens first: the account's article language (F18). A guest can't set one (Settings asks
/// them to sign in), so they get their UI language's version, as the API gives guests their feeds.
String _preferredArticleLanguage(BuildContext context) {
  final settings = context.read<SettingsCubit>().state;
  if (context.read<SessionCubit>().state.isAuthenticated) return settings.articleLanguage;
  return settings.uiLanguage == 'en' ? 'en' : 'ar-EG';
}

/// The reader once its cubits are provided ([ArticleCubit], [ArticleLiveCubit]; [EngagementCubit],
/// [FollowsCubit] and [CollectionsCubit] come from the app).
class ArticleView extends StatefulWidget {
  const ArticleView({super.key, this.anchor});

  /// See [ArticlePage.anchor]: a link to a block or comment never resumes the last position.
  final String? anchor;

  @override
  State<ArticleView> createState() => _ArticleViewState();
}

class _ArticleViewState extends State<ArticleView> {
  final _scroll = ScrollController();
  final _progress = ValueNotifier<double>(0);
  late final AppLifecycleListener _lifecycle;

  // Resume (F04): tried once, for the first article shown.
  bool _resumeTried = false;
  ReaderResume? _resume;

  // The comments under the article (F11): the action bar's count and a link to a comment scroll to them.
  final _comments = GlobalKey<ArticleCommentsSectionState>();

  // A link to a comment scrolls to the comments once (F17).
  bool _commentsShown = false;

  /// The block the link points at (`#{blockId}`), if it isn't a comment's anchor.
  String? get _blockAnchor {
    final anchor = widget.anchor;
    return anchor == null || anchor.isEmpty || anchor.startsWith('comment-') ? null : anchor;
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Live counters pause in the background (SPEC §21.2); the socket itself goes offline too.
    final live = context.read<ArticleLiveCubit>();
    _lifecycle = AppLifecycleListener(onPause: () => unawaited(live.pause()), onResume: live.resume);
    final loaded = context.read<ArticleCubit>().state.article;
    if (loaded != null) _onArticle(loaded);
  }

  void _onScroll() {
    final position = _scroll.position;
    final max = position.maxScrollExtent;
    _progress.value = max <= 0 ? 1 : (position.pixels / max).clamp(0, 1);
  }

  /// A loaded article is the newest state of its counters, the author follow and its collections ("add to
  /// collection" opens with them ticked); then live counters follow it. A device copy (offline) is older than
  /// anything the app knows, so it seeds nothing. A deleted author has no follow to seed.
  void _onArticle(ArticleDetails article) {
    if (!article.isOfflineCopy) {
      context.read<EngagementCubit>().seed([article.card]);
      if (article.card.author case final author?) {
        context.read<FollowsCubit>().seed({author.id: article.isFollowingAuthor});
      }
      context.read<CollectionsCubit>().seedArticle(article.card.id, article.collectionIds);
    }
    context.read<ArticleLiveCubit>().watch(article.card.id);
    _maybeResume(article);
    _maybeShowComments(article);
  }

  /// A link to a comment (`#comment-{id}`: a reply, a mention or a comment on your article, F17) scrolls down to the
  /// article's comments once they are built, once. A device copy (offline) has no comments to show.
  void _maybeShowComments(ArticleDetails article) {
    if (_commentsShown || article.isOfflineCopy || !(widget.anchor?.startsWith('comment-') ?? false)) return;
    _commentsShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showComments();
    });
  }

  /// Scrolls down to the comments under the article (F11); the resume stops, as for a heading of the contents.
  void _showComments() {
    _resume?.cancel();
    unawaited(_comments.currentState?.reveal());
  }

  /// Scrolls back to where the reader left this version, once the first article is laid out (F04 resume). Another
  /// version or a link to a block never resumes; neither does a reader who already scrolled.
  void _maybeResume(ArticleDetails article) {
    if (_resumeTried) {
      // Another version replaced the content: the saved position no longer applies.
      _resume?.cancel();
      return;
    }
    _resumeTried = true;
    final fraction = widget.anchor == null ? article.resumeFraction : null;
    if (fraction != null) WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_resumeAt(fraction)));
  }

  Future<void> _resumeAt(double fraction) async {
    if (!mounted || !_scroll.hasClients || _scroll.position.pixels > 0) return;
    final resume = _resume = ReaderResume(controller: _scroll, fraction: fraction, onSettled: _onResumeSettled);
    final moved = await resume.start();
    if (!mounted || !moved) return;
    final l10n = context.l10n;
    showActionMessage(
      context,
      l10n.resumePickedUp,
      action: SnackBarAction(label: l10n.resumeStartOver, onPressed: _startOver),
    );
  }

  /// The tracker above this widget missed the jumps: hand it the settled position, as the scroll view would.
  void _onResumeSettled(ScrollMetrics metrics) {
    if (mounted) ScrollMetricsNotification(metrics: metrics.copyWith(), context: context).dispatch(context);
  }

  void _startOver() {
    _resume?.cancel();
    if (!mounted || !_scroll.hasClients) return;
    unawaited(_scroll.animateTo(0, duration: ReadInMotion.slow, curve: Curves.easeOutCubic));
  }

  void _onLive(LiveArticleCounts? counts) {
    final article = context.read<ArticleCubit>().state.article;
    if (counts != null && article != null) context.read<EngagementCubit>().applyLive(article.card.id, counts);
  }

  @override
  void dispose() {
    _resume?.cancel();
    _lifecycle.dispose();
    _scroll.dispose();
    _progress.dispose();
    super.dispose();
  }

  double _fontSizeFor(ArticleFontSize size) => switch (size) {
        ArticleFontSize.s => ReadInArticleFontScale.s,
        ArticleFontSize.m => ReadInArticleFontScale.m,
        ArticleFontSize.l => ReadInArticleFontScale.l,
        ArticleFontSize.xl => ReadInArticleFontScale.xl,
      };

  /// The glossary sheet (F21) for the version being read; an article picked there opens like any other.
  Future<void> _showTerm(RTerm term) async {
    final article = context.read<ArticleCubit>().state.article;
    if (article == null) return;
    final slug = await showGlossarySheet(
      context,
      termId: term.termId,
      text: term.text,
      language: article.card.language,
      articleId: article.card.id,
    );
    if (slug != null && mounted) unawaited(context.push('/a/$slug'));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>();
    final fontSize = settings.state.fontSize;

    return MultiBlocListener(
      listeners: [
        BlocListener<ArticleCubit, ArticleState>(
          listenWhen: (previous, current) => current.article != null && previous.article != current.article,
          listener: (_, state) => _onArticle(state.article!),
        ),
        BlocListener<ArticleLiveCubit, LiveArticleCounts?>(listener: (_, counts) => _onLive(counts)),
      ],
      child: Scaffold(
        // The status bar's inset belongs to the white bar at the top; the sides and the bottom stay safe.
        body: SafeArea(
          top: false,
          child: BlocBuilder<ArticleCubit, ArticleState>(
            builder: (context, state) {
              final article = state.article;
              return Column(
                children: [
                  // The progress and the bar on `surface`, up under the status bar, like the app's other bars.
                  ColoredBox(
                    color: context.colors.surface,
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          ReadingProgressBar(progress: _progress),
                          _TopBar(
                            article: article,
                            switching: state.switchingLanguage,
                            onLanguage: (lang) => context.read<ArticleCubit>().switchLanguage(lang),
                            onFontSize: () => showFontSizeSheet(context, current: fontSize, onChanged: settings.setFontSize),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.status == ArticleStatus.ready && article!.isOfflineCopy) const _OfflineCopyBanner(),
                  Expanded(
                    child: switch (state.status) {
                      ArticleStatus.loading => const _ReaderSkeleton(),
                      ArticleStatus.failure => PageBlock(
                          margin: const EdgeInsets.only(top: PageBlock.gap),
                          child: ErrorView(
                            failure: state.failure!,
                            onRetry: () => context.read<ArticleCubit>().retry(_preferredArticleLanguage(context)),
                          ),
                        ),
                      ArticleStatus.ready => NotificationListener<Notification>(
                          // While resuming, the jumps stay between the reader and its resume.
                          onNotification: (notification) => _resume?.onNotification(notification) ?? false,
                          // Selecting text to highlight, and the marks (F30).
                          child: ReaderHighlights(
                            article: article!,
                            onTextChanged: () => unawaited(context.read<ArticleCubit>().reloadVersion()),
                            child: ReaderBody(
                              article: article,
                              controller: _scroll,
                              // A link to a block (Saved → Highlights, F30) opens the article there.
                              initialBlockId: _blockAnchor,
                              bodyFontSize: _fontSizeFor(fontSize),
                              onTerm: (term) => unawaited(_showTerm(term)),
                              // A heading picked in the table of contents wins over the resume.
                              beforeTocJump: () => _resume?.cancel(),
                              // A muted writer's article still opens from a link, with "انت كاتم الكاتب ده" (F28).
                              leading: switch (article.card.author) {
                                final author? => MutedWriterBanner(
                                    userId: author.id,
                                    name: author.displayName,
                                    initiallyMuted: article.card.isAuthorMuted,
                                    padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, 0),
                                  ),
                                null => null,
                              },
                              trailing: [
                                // The comments right under the article, as on the web; a device copy has none.
                                if (!article.isOfflineCopy) ArticleCommentsSection(key: _comments, article: article.card),
                                NextInPathSliver(articleId: article.card.id),
                                RelatedArticlesSection(article: article.card),
                              ],
                              // Nobody can follow a deleted account (SPEC §9.6).
                              authorAction: switch (article.card.author) {
                                final author? => FollowButton(
                                    userId: author.id,
                                    name: author.displayName,
                                    initiallyFollowing: article.isFollowingAuthor,
                                    dense: true,
                                  ),
                                null => null,
                              },
                            ),
                          ),
                        ),
                    },
                  ),
                  if (state.status == ArticleStatus.ready)
                    ReaderActionBar(
                      article: article!.card,
                      menu: ArticleMenuButton(article: article),
                      // The comment count scrolls down to the comments; a device copy has no section, so its count
                      // opens them in a sheet.
                      onComments: article.isOfflineCopy ? null : _showComments,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.article, required this.switching, required this.onLanguage, required this.onFontSize});

  final ArticleDetails? article;
  final bool switching;
  final ValueChanged<String> onLanguage;
  final VoidCallback onFontSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = article;
    // As the app's bars: on `surface` (painted above it) with a 1 px `border` line under it.
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.colors.border))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: ReadInSpace.s1),
        child: Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const BackButtonIcon(),
              onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
            ),
            const Spacer(),
            if (a != null && a.hasBothLanguages)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s1),
                child: SegmentedButton<String>(
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'ar-EG', label: Text(l10n.langToggleArEg), tooltip: l10n.articleLangArEg),
                    ButtonSegment(value: 'en', label: Text(l10n.langToggleEn), tooltip: l10n.articleLangEn),
                  ],
                  selected: {a.card.language},
                  onSelectionChanged: switching ? null : (v) => onLanguage(v.first),
                ),
              ),
            IconButton(tooltip: l10n.fontSize, icon: const Icon(Icons.format_size_rounded), onPressed: onFontSize),
            ArticleShareButton(article: a?.card),
          ],
        ),
      ),
    );
  }
}

/// A saved article opened from its device copy because the API is unreachable (F13, F25).
class _OfflineCopyBanner extends StatelessWidget {
  const _OfflineCopyBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: colors.surfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5, vertical: ReadInSpace.s2),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 18, color: colors.textSecondary),
            const SizedBox(width: ReadInSpace.s2),
            Expanded(
              child: Text(context.l10n.offlineCopy, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The article as readers see it: header, trust row, health disclaimer, TL;DR, table of contents, content,
/// attachments, tags and sources, in one white block on the canvas ([PageBlock]'s look), then the [trailing] sections.
/// The editor's preview (F05) renders the same widget.
class ReaderBody extends StatefulWidget {
  const ReaderBody({
    super.key,
    required this.article,
    required this.bodyFontSize,
    this.controller,
    this.onTerm,
    this.authorAction,
    this.leading,
    this.trailing = const [],
    this.beforeTocJump,
    this.initialBlockId,
  });

  final ArticleDetails article;
  final ScrollController? controller;
  final double bodyFontSize;
  final ValueChanged<RTerm>? onTerm;

  /// At the end of the author row (the follow button).
  final Widget? authorAction;

  /// Above the header (the editor preview shows the feed card there).
  final Widget? leading;

  /// Slivers after the sources: the reader's end-of-article sections (comments, next in path, related articles). The
  /// editor preview has none.
  final List<Widget> trailing;

  /// Runs before a heading of the table of contents scrolls the reader (the reader stops resuming).
  final VoidCallback? beforeTocJump;

  /// A block to bring to the top once the article is laid out: a link to a block (Saved → Highlights, F30).
  final String? initialBlockId;

  @override
  State<ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends State<ReaderBody> {
  final _locator = RDocBlockLocator();

  @override
  void initState() {
    super.initState();
    final block = widget.initialBlockId;
    if (block != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_locator.reveal(block, duration: Duration.zero));
      });
    }
  }

  /// A heading picked in the table of contents: scrolled to the top of the reader.
  void _jumpTo(TocEntry entry) {
    widget.beforeTocJump?.call();
    final animate = !MediaQuery.disableAnimationsOf(context);
    unawaited(_locator.reveal(entry.blockId, duration: animate ? ReadInMotion.slow : Duration.zero));
  }

  /// An @mention in the content opens that profile (F14), as the web links it to `/@username`.
  void _openMention(RMention mention) {
    final router = GoRouter.maybeOf(context);
    if (router != null && mention.text.replaceFirst('@', '').isNotEmpty) {
      unawaited(router.push<void>(ProfileRoutes.of(mention.text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final direction = RDocScope.directionForLanguage(article.card.language);
    final showSummary = article.summary != null && article.summary!.isNotEmpty && !article.content.hasSummaryBlock;
    final toc = tableOfContents(article.content);
    const gutter = EdgeInsets.symmetric(horizontal: ReadInSpace.s5);

    final moderation = article.moderation;
    final leading = widget.leading;

    // A box inside the article's block: its own ink layer, so taps still ripple above the block's `surface`.
    Widget box(Widget child) => SliverToBoxAdapter(child: Material(type: MaterialType.transparency, child: child));

    return RDocScope(
      baseDirection: direction,
      bodyFontSize: widget.bodyFontSize,
      onLinkTap: openExternalLink,
      onTermTap: widget.onTerm,
      onMentionTap: _openMention,
      child: Builder(
        builder: (context) => CustomScrollView(
          controller: widget.controller,
          slivers: [
            // The article (banners, header, content, attachments, tags and sources) is one white block on the canvas,
            // a gap under the bar, as LinkedIn shows a post; the reading width, sizes and line height don't change.
            SliverPadding(
              padding: const EdgeInsets.only(top: PageBlock.gap),
              sliver: DecoratedSliver(
                decoration: BoxDecoration(color: context.colors.surface),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    // Only its author and moderators can open a hidden article (F22).
                    if (moderation != null)
                      SliverPadding(
                        padding: gutter.copyWith(top: ReadInSpace.s4),
                        sliver: box(HiddenArticleBanner(moderation: moderation)),
                      ),
                    if (leading != null) box(leading),
                    SliverPadding(
                      padding: gutter.copyWith(top: ReadInSpace.s4),
                      sliver: box(
                        ArticleHeader(
                          article: article,
                          titleScale: RDocScope.of(context).scale,
                          authorAction: widget.authorAction,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: gutter.copyWith(top: ReadInSpace.s4, bottom: ReadInSpace.s4),
                      sliver: box(TrustRow(article: article)),
                    ),
                    // Health content (medicine, public health) says it doesn't replace a doctor (SPEC F04).
                    if (article.card.field.isSensitive)
                      SliverPadding(padding: gutter.copyWith(bottom: ReadInSpace.s4), sliver: box(const HealthDisclaimer())),
                    if (showSummary)
                      SliverPadding(
                        padding: gutter.copyWith(bottom: ReadInSpace.s4),
                        sliver: box(
                          SummaryBox(
                            direction: direction,
                            child: Text(
                              article.summary!,
                              textDirection: direction,
                              style: rdocBodyStyle(context, direction, factor: 0.94),
                            ),
                          ),
                        ),
                      ),
                    if (toc.length >= ArticleToc.minHeadings)
                      SliverPadding(
                        padding: gutter.copyWith(bottom: ReadInSpace.s5),
                        sliver: box(ArticleToc(entries: toc, onSelected: _jumpTo)),
                      ),
                    SliverPadding(padding: gutter, sliver: RDocSliver(article.content, locator: _locator)),
                    if (article.card.attachments != null)
                      SliverPadding(
                        padding: gutter.copyWith(bottom: ReadInSpace.s4),
                        sliver: box(ArticleAttachmentsView(article: article.card)),
                      ),
                    if (article.tags.isNotEmpty)
                      SliverPadding(padding: gutter.copyWith(top: ReadInSpace.s4), sliver: box(ArticleTags(tags: article.tags))),
                    SliverPadding(
                      padding: gutter.copyWith(top: ReadInSpace.s4, bottom: ReadInSpace.s5),
                      sliver: box(SourcesSection(sources: article.sources, onOpen: openExternalLink)),
                    ),
                  ],
                ),
              ),
            ),
            // The end-of-article sections, each its own block a gap under the last.
            ...widget.trailing,
            const SliverToBoxAdapter(child: SizedBox(height: ReadInSpace.s6)),
          ],
        ),
      ),
    );
  }
}

/// The article's block while it loads (static, so "reduce motion" is respected).
class _ReaderSkeleton extends StatelessWidget {
  const _ReaderSkeleton();

  @override
  Widget build(BuildContext context) => PageBlock(
        margin: const EdgeInsets.only(top: PageBlock.gap),
        child: ListView(
          padding: const EdgeInsets.all(ReadInSpace.s5),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const SkeletonBox(width: 80, height: 18),
            const SizedBox(height: ReadInSpace.s4),
            const SkeletonBox(height: 26),
            const SizedBox(height: ReadInSpace.s2),
            const SkeletonBox(width: 220, height: 26),
            const SizedBox(height: ReadInSpace.s5),
            const Row(children: [
              SkeletonBox(width: 36, height: 36, radius: 18),
              SizedBox(width: ReadInSpace.s2),
              SkeletonBox(width: 140),
            ]),
            const SizedBox(height: ReadInSpace.s6),
            for (var i = 0; i < 8; i++) ...[
              SkeletonBox(width: i.isEven ? double.infinity : 260),
              const SizedBox(height: ReadInSpace.s3),
            ],
          ],
        ),
      );
}

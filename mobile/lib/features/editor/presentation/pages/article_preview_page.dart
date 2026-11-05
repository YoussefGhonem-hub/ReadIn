import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../article/domain/entities/article.dart';
import '../../../article/presentation/pages/article_page.dart';
import '../../../article/presentation/widgets/article_card_tile.dart';
import '../../../media/domain/entities/media.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../../domain/entities/editor_entities.dart';
import '../widgets/editor_widgets.dart';

/// What the preview shows: a document as readers will get it, with what the reader needs around it.
class PreviewData {
  const PreviewData({
    required this.document,
    required this.author,
    this.media = const [],
    this.field,
    this.topic,
    this.readingTime = const [],
    this.publishedAt,
  });

  final ArticleDraftDocument document;
  final Author author;

  /// The attachments' uploads.
  final List<MediaAsset> media;
  final Field? field;
  final Topic? topic;
  final List<ReadingTime> readingTime;
  final DateTime? publishedAt;

  /// The reader's [ArticleDetails] for the [language] version. Blocks still being filled in are left out, as the
  /// API leaves them out of the saved copy.
  ArticleDetails details(String language, {DateTime? now}) {
    final t = document.translation(language) ?? document.source;
    final f = field;
    return ArticleDetails(
      card: ArticleCard(
        id: 'preview',
        slug: 'preview',
        language: t.language,
        title: t.title,
        subtitle: t.subtitle,
        coverUrl: document.coverUrl,
        field: f == null
            ? const FieldRef(id: '', slug: '', nameAr: '—', nameEn: '—')
            : FieldRef(id: f.id, slug: f.slug, nameAr: f.nameAr, nameEn: f.nameEn, isSensitive: f.isSensitive),
        author: author,
        readingTimeMinutes: readingTime.where((r) => r.language == t.language).firstOrNull?.minutes ?? 1,
        publishedAt: publishedAt ?? now ?? DateTime.now(),
        isAiAssisted: document.isAiAssisted,
        versionBadge: document.versionBadge,
        attachments: previewAttachments(document.attachments, media),
      ),
      availableLanguages: document.languages,
      content: RDocSanitizer.forSave(t.content),
      topic: topic == null ? null : FieldRef(id: topic!.id, slug: topic!.slug, nameAr: topic!.nameAr, nameEn: topic!.nameEn),
      // Shown like the reader's tags, but without links: a new name has no tag page before it's published (F32).
      tags: [for (final name in document.tags) TagRef(slug: '', name: name)],
      sources: document.sources,
    );
  }
}

/// The reader's attachments from draft items and their uploads (nothing for items whose upload isn't known).
ArticleAttachments? previewAttachments(List<AttachmentItem> items, List<MediaAsset> media) {
  if (items.isEmpty) return null;
  final byId = {for (final m in media) m.id: m};
  final sorted = [...items]..sort((a, b) => a.order.compareTo(b.order));
  final first = byId[sorted.first.mediaAssetId];
  if (sorted.first.title != null || first?.kind == MediaKind.document) {
    final item = sorted.first;
    final asset = first;
    if (asset == null) return null;
    return ArticleAttachments(
      kind: AttachmentsKind.document,
      document: DocumentAttachment(
        assetId: asset.id,
        title: item.title ?? asset.title ?? '',
        pageCount: asset.pageCount ?? asset.pages.length,
        downloadUrl: '',
        pages: asset.pages,
        allowDownload: item.allowDownload ?? false,
      ),
    );
  }
  final images = [
    for (final item in sorted)
      if (byId[item.mediaAssetId] case final asset?)
        ImageAttachment(
          assetId: asset.id,
          order: item.order,
          caption: item.caption,
          altText: item.altText ?? '',
          width: asset.width ?? 0,
          height: asset.height ?? 0,
          blurHash: asset.blurHash,
          variants: asset.variants,
        ),
  ];
  return images.isEmpty ? null : ArticleAttachments(kind: AttachmentsKind.images, images: images);
}

/// "Preview" (F05): exactly as readers will see it — the reader's own widgets — with a light/dark switch and the
/// language versions. The feed card on top shows the cover.
class ArticlePreviewPage extends StatelessWidget {
  const ArticlePreviewPage({super.key, required this.data, this.title, this.actions = const []});

  final PreviewData data;

  /// Defaults to "Preview" (a revision preview names its version).
  final String? title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title ?? context.l10n.previewTitle), actions: actions),
        body: ArticlePreviewView(data: data),
      );
}

class ArticlePreviewView extends StatefulWidget {
  const ArticlePreviewView({super.key, required this.data, this.initialLanguage, this.initialDark});

  final PreviewData data;
  final String? initialLanguage;
  final bool? initialDark;

  @override
  State<ArticlePreviewView> createState() => _ArticlePreviewViewState();
}

class _ArticlePreviewViewState extends State<ArticlePreviewView> {
  late String _language = widget.initialLanguage ?? widget.data.document.sourceLanguage;
  bool? _dark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = _dark ?? widget.initialDark ?? context.isDark;
    final locale = Localizations.localeOf(context);
    final document = widget.data.document;
    final details = widget.data.details(_language);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, ReadInSpace.s2),
          child: Wrap(
            spacing: ReadInSpace.s3,
            runSpacing: ReadInSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<bool>(
                key: const ValueKey('preview-theme'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, icon: const Icon(Icons.light_mode_outlined), label: Text(l10n.previewLight)),
                  ButtonSegment(value: true, icon: const Icon(Icons.dark_mode_outlined), label: Text(l10n.previewDark)),
                ],
                selected: {dark},
                onSelectionChanged: (v) => setState(() => _dark = v.first),
              ),
              if (document.hasTranslation)
                SegmentedButton<String>(
                  key: const ValueKey('preview-language'),
                  showSelectedIcon: false,
                  segments: [
                    for (final t in document.translations) ButtonSegment(value: t.language, label: Text(articleLanguageName(l10n, t.language))),
                  ],
                  selected: {_language},
                  onSelectionChanged: (v) => setState(() => _language = v.first),
                ),
            ],
          ),
        ),
        Expanded(
          child: Theme(
            data: dark ? AppTheme.dark(locale) : AppTheme.light(locale),
            child: Builder(
              builder: (context) => ColoredBox(
                color: context.colors.bg,
                child: ReaderBody(
                  key: ValueKey('preview-$_language-$dark'),
                  article: details,
                  bodyFontSize: ReadInArticleFontScale.m,
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, ReadInSpace.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.previewInFeed, style: context.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary)),
                        const SizedBox(height: ReadInSpace.s2),
                        Container(
                          padding: const EdgeInsets.all(ReadInSpace.s3),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(ReadInRadius.card),
                            border: Border.all(color: context.colors.border),
                          ),
                          child: ArticleCardTile(article: details.card, onTap: () {}),
                        ),
                        const SizedBox(height: ReadInSpace.s4),
                        Divider(height: 1, color: context.colors.border),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

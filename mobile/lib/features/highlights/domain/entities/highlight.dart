import 'package:equatable/equatable.dart';

import '../../../../shared/rdoc/highlights/rdoc_highlight_text.dart';
import '../../../article/domain/entities/article.dart' show Author;

/// One of your highlights (F30): a range of a block's plain text in one version of an article (`HighlightDto`). Never
/// sent to anyone else.
class Highlight extends Equatable {
  const Highlight({
    required this.id,
    required this.blockId,
    required this.startOffset,
    required this.endOffset,
    required this.text,
    required this.createdAt,
  });

  /// The optimistic copy of a highlight being created, before the API answers: drawn, but it can't be removed yet.
  factory Highlight.pending(HighlightRange range, {required int serial}) => Highlight(
        id: '$pendingPrefix$serial',
        blockId: range.blockId,
        startOffset: range.startOffset,
        endOffset: range.endOffset,
        text: range.text,
        createdAt: DateTime.now().toUtc(),
      );

  static const pendingPrefix = 'pending:';

  final String id;
  final String blockId;
  final int startOffset;
  final int endOffset;
  final String text;
  final DateTime createdAt;

  bool get isPending => id.startsWith(pendingPrefix);

  HighlightRange get range => HighlightRange(blockId: blockId, startOffset: startOffset, endOffset: endOffset, text: text);

  @override
  List<Object?> get props => [id, blockId, startOffset, endOffset, text, createdAt];
}

/// A range at least 3 readers marked (`PopularHighlightDto`): no ids, no names.
class PopularHighlight extends Equatable {
  const PopularHighlight({
    required this.blockId,
    required this.startOffset,
    required this.endOffset,
    required this.text,
    required this.count,
  });

  final String blockId;
  final int startOffset;
  final int endOffset;
  final String text;

  /// "N قارئ علّموا الجملة دي"; your muted writers don't count, you do when you marked it too.
  final int count;

  @override
  List<Object?> get props => [blockId, startOffset, endOffset, text, count];
}

/// `GET /articles/{id}/highlights?lang=`: yours (document order, none for guests) and the popular ones (≤ 5) of one
/// version.
class ArticleHighlights extends Equatable {
  const ArticleHighlights({required this.articleId, required this.language, this.mine = const [], this.popular = const []});

  final String articleId;

  /// The version they belong to: the API's answer wins over the one asked for.
  final String language;
  final List<Highlight> mine;
  final List<PopularHighlight> popular;

  @override
  List<Object?> get props => [articleId, language, mine, popular];
}

/// `POST /articles/{id}/highlights`: the highlight now covering the range, and yours it joined (deleted).
class HighlightCreated extends Equatable {
  const HighlightCreated({required this.highlight, this.replacedIds = const []});

  final Highlight highlight;
  final List<String> replacedIds;

  @override
  List<Object?> get props => [highlight, replacedIds];
}

/// The article version a group of your highlights belongs to (Saved → Highlights).
class HighlightArticle extends Equatable {
  const HighlightArticle({required this.id, required this.slug, required this.language, required this.title, this.author});

  final String id;
  final String slug;

  /// Open the article in this version.
  final String language;

  /// That version's title.
  final String title;

  /// Null: the author deleted their account ("Deleted user").
  final Author? author;

  @override
  List<Object?> get props => [id, slug, language, title, author];
}

/// One article version with all your highlights on it, newest first (`HighlightGroupDto`).
class HighlightGroup extends Equatable {
  const HighlightGroup({required this.article, required this.highlights, required this.latestAt});

  final HighlightArticle article;
  final List<Highlight> highlights;

  /// Its newest highlight: groups come newest first.
  final DateTime latestAt;

  /// One group per article version: a page never repeats one already shown.
  String get key => '${article.id}|${article.language}';

  @override
  List<Object?> get props => [article, highlights, latestAt];
}

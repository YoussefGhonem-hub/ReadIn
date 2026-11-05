import 'dart:async';

import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/tags/domain/entities/tag.dart';
import 'package:readin/features/tags/domain/repositories/tags_repository.dart';

import 'post_card_fixtures.dart';
import 'social_fakes.dart';

/// Tags (F32) the way the API sends them: Arabic and English names, and names with symbols (`C#`, `.NET`, `C++`).
const csharpTag = ArticleTag(slug: 'csharp', name: 'C#', articleCount: 42);
const dotnetTag = ArticleTag(slug: 'dotnet', name: '.NET', articleCount: 128);
const cppTag = ArticleTag(slug: 'cplusplus', name: 'C++', articleCount: 9);
const aiArTag = ArticleTag(slug: 'الذكاء-الاصطناعي', name: 'الذكاء الاصطناعي', articleCount: 31);
const aiEnTag = ArticleTag(slug: 'ai', name: 'AI', articleCount: 57);

/// A tag nobody has published with yet: its page shows the empty state.
const emptyTag = ArticleTag(slug: 'zig', name: 'Zig');

/// A slug the API answers `404 tag.not_found` for (unknown or hidden).
const missingTagSlug = 'no-such-tag';

/// The tag of the page in the UI language: Arabic in Arabic, `C#` in English.
ArticleTag pageTagFor(String language) => language == 'en' ? csharpTag : aiArTag;

/// `TagDto` JSON.
Map<String, dynamic> tagJson(ArticleTag tag) => {'slug': tag.slug, 'name': tag.name, 'articleCount': tag.articleCount};

/// `TagRefDto` JSON.
Map<String, dynamic> tagRefJson(ArticleTag tag) => {'slug': tag.slug, 'name': tag.name};

/// A card JSON (`ArticleCardDto`) carrying [tags] as `TagRefDto`s.
Map<String, dynamic> taggedCardJson(int i, {List<ArticleTag> tags = const [csharpTag, dotnetTag, cppTag], int? tagCount}) => {
      ...detailsJson(i),
      'excerpt': 'Short.',
      'hasMore': true,
      'tags': [for (final t in tags) tagRefJson(t)],
      'tagCount': tagCount ?? tags.length,
    };

/// The post cards of a tag page: [count] cards from [first], in the page's language, each with the page's tag first.
List<ArticleCard> tagPageCards(ArticleTag tag, {int first = 1, int count = 2, String language = 'ar-EG'}) => [
      for (var i = first; i < first + count; i++)
        postCard(
          i,
          language: language,
          cover: false,
          tags: [tag.ref, ...sampleTagRefs.where((t) => t.slug != tag.slug).take(2)],
          tagCount: 4,
        ),
    ];

/// Scriptable [TagsRepository]: `GET /tags/{slug}` from [tags] (404 for any other slug), and the articles of a slug
/// from [pages] (a list of pages, cursors `c1`, `c2`, …). Every call is recorded.
class FakeTagsRepository implements TagsRepository {
  FakeTagsRepository({this.tags = const [], this.pages = const {}});

  final List<ArticleTag> tags;
  final Map<String, List<List<ArticleCard>>> pages;
  final calls = <String>[];

  /// Set to answer with a failure instead (e.g. offline).
  Failure? failure;

  /// Holds the answers until completed, to see the loading states.
  Completer<void>? gate;

  static const notFound = Failure(FailureCodes.tagNotFound, statusCode: 404);

  @override
  Future<Result<ArticleTag>> getTag(String slug) async {
    calls.add('tag $slug');
    await gate?.future;
    if (failure case final f?) return Err(f);
    final tag = tags.where((t) => t.slug == slug).firstOrNull;
    return tag == null ? const Err(notFound) : Ok(tag);
  }

  @override
  Future<Result<CursorPage<ArticleCard>>> getArticles(String slug, {String? cursor, int limit = 20}) async {
    calls.add('articles $slug${cursor == null ? '' : ' $cursor'}');
    await gate?.future;
    if (failure case final f?) return Err(f);
    final list = pages[slug];
    if (list == null) return const Err(notFound);
    final index = cursor == null ? 0 : int.parse(cursor.substring(1));
    if (index >= list.length) return const Ok(CursorPage(items: []));
    return Ok(CursorPage(items: list[index], nextCursor: index + 1 < list.length ? 'c${index + 1}' : null));
  }
}

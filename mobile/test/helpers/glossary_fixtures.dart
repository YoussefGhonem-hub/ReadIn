import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/glossary/domain/entities/glossary_term.dart';
import 'package:readin/features/glossary/domain/repositories/glossary_repository.dart';

import 'fixtures.dart';

/// Articles that use [diTerm]: `art-1` is the article the reader has open in the tests.
const diArticles = [
  GlossaryArticle(
    id: 'art-1',
    slug: 'article-1',
    language: 'ar-EG',
    title: 'إزاي تختار بين Transient و Scoped في مشروعك؟',
    readingTimeMinutes: 5,
    field: dotnetField,
  ),
  GlossaryArticle(
    id: 'art-2',
    slug: 'di-in-dotnet',
    language: 'ar-EG',
    title: 'يعني إيه Dependency Injection في .NET؟ وليه كل الناس بتتكلم عنه',
    readingTimeMinutes: 6,
    field: dotnetField,
  ),
  GlossaryArticle(
    id: 'art-3',
    slug: 'testing-with-fakes',
    language: 'en',
    title: 'Testing services with fakes instead of mocks',
    readingTimeMinutes: 4,
    field: dotnetField,
  ),
  GlossaryArticle(
    id: 'art-4',
    slug: 'agents-and-tools',
    language: 'ar-EG',
    title: 'الـ AI Agents هتغيّر طريقة شغلك إزاي؟',
    readingTimeMinutes: 7,
    field: aiField,
  ),
  GlossaryArticle(
    id: 'art-5',
    slug: 'clean-architecture',
    language: 'en',
    title: 'Clean Architecture in a Flutter app',
    readingTimeMinutes: 9,
    field: dotnetField,
  ),
  GlossaryArticle(
    id: 'art-6',
    slug: 'ef-core-queries',
    language: 'ar-EG',
    title: 'EF Core: إزاي تكتب queries سريعة من غير ما توجع الـ database',
    readingTimeMinutes: 8,
    field: dotnetField,
  ),
];

const diTerm = GlossaryTerm(
  slug: 'dependency-injection',
  term: 'Dependency Injection',
  definitionEn: 'A technique where an object receives the objects it depends on from outside, instead of creating them '
      'itself (for example from the DI container in ASP.NET Core).',
  explanationAr: 'إن الـ class ما يعملش الحاجات اللي محتاجها بنفسه، لكن تيجي له جاهزة من بره، غالباً من الـ DI container '
      'في .NET (زي ما بيحصل مع AddScoped).',
  articles: diArticles,
);

/// `GlossaryTermDto` JSON of [diTerm], the way the API sends it.
Map<String, dynamic> diTermJson() => {
      'slug': diTerm.slug,
      'term': diTerm.term,
      'definitionEn': diTerm.definitionEn,
      'explanationAr': diTerm.explanationAr,
      'articles': [
        for (final a in diTerm.articles)
          {
            'id': a.id,
            'slug': a.slug,
            'language': a.language,
            'title': a.title,
            'readingTimeMinutes': a.readingTimeMinutes,
            'field': {'id': a.field.id, 'slug': a.field.slug, 'nameAr': a.field.nameAr, 'nameEn': a.field.nameEn},
          },
      ],
    };

/// Search results of the editor's term picker (`GlossaryTermSummaryDto`).
const diSummary = GlossaryTermSummary(
  slug: 'dependency-injection',
  term: 'Dependency Injection',
  definitionEn: 'A technique where an object receives the objects it depends on from outside, instead of creating them itself.',
);
const iocSummary = GlossaryTermSummary(
  slug: 'ioc-container',
  term: 'IoC container',
  definitionEn: 'A framework component that creates objects and supplies their dependencies.',
);

/// A glossary that answers searches from [terms] the way the API does (the English term or the slug, case
/// insensitive), or fails with [failure]. [searches] records every query.
class FakeGlossaryRepository implements GlossaryRepository {
  FakeGlossaryRepository({this.terms = const [diSummary, iocSummary], this.failure});

  final List<GlossaryTermSummary> terms;
  Failure? failure;
  final searches = <String>[];

  @override
  Future<Result<List<GlossaryTermSummary>>> search(String query, {int limit = 8}) async {
    searches.add(query);
    if (failure != null) return Err(failure!);
    final q = query.toLowerCase();
    return Ok([for (final t in terms) if (t.term.toLowerCase().contains(q) || t.slug.contains(q)) t].take(limit).toList());
  }

  @override
  Future<Result<GlossaryTerm>> getTerm(String slug, {required String language}) async => const Ok(diTerm);
}

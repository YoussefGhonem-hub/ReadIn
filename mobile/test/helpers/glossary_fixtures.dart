import 'package:readin/features/glossary/domain/entities/glossary_term.dart';

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

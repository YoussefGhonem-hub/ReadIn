import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/bidi/bidi.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/glossary/domain/entities/glossary_term.dart';
import 'package:readin/features/glossary/domain/repositories/glossary_repository.dart';
import 'package:readin/features/glossary/domain/usecases/get_glossary_term.dart';
import 'package:readin/features/glossary/presentation/cubit/glossary_term_cubit.dart';
import 'package:readin/features/glossary/presentation/widgets/glossary_sheet.dart';

import '../../helpers/glossary_fixtures.dart';
import '../../helpers/test_app.dart';

class MockGlossaryRepository extends Mock implements GlossaryRepository {}

const _en = Variant(AppLocales.en, Brightness.light);
const _ar = Variant(AppLocales.ar, Brightness.light);

/// The glossary sheet (F21): its states, which texts it shows for each article version and UI language, and the
/// term's articles.
void main() {
  late MockGlossaryRepository repository;

  setUp(() => repository = MockGlossaryRepository());

  void answer(Future<Result<GlossaryTerm>> Function() result, {String language = 'ar-EG'}) =>
      when(() => repository.getTerm('dependency-injection', language: language)).thenAnswer((_) => result());

  /// The sheet's content for the open article `art-1`, as the sheet builds it.
  Future<GlossaryTermCubit> pumpView(
    WidgetTester tester, {
    String language = 'ar-EG',
    Variant variant = _en,
    String text = 'DI',
  }) async {
    usePhoneSurface(tester, size: const Size(390, 1200));
    final cubit = GlossaryTermCubit(GetGlossaryTerm(repository));
    addTearDown(cubit.close);
    unawaited(cubit.load('dependency-injection', language: language));
    await tester.pumpWidget(testApp(
      Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: GlossaryTermView(text: text, language: language, articleId: 'art-1'),
        ),
      ),
      variant: variant,
    ));
    await tester.pump();
    return cubit;
  }

  Text textWidget(WidgetTester tester, String containing) => tester.widget<Text>(find.textContaining(containing));
  double top(WidgetTester tester, Finder finder) => tester.getTopLeft(finder).dy;

  testWidgets('loading: the tapped words over a skeleton', (tester) async {
    final semantics = tester.ensureSemantics();
    answer(() => Completer<Result<GlossaryTerm>>().future);
    await pumpView(tester);

    expect(find.textContaining('DI'), findsOneWidget);
    expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
    expect(find.text('In English'), findsNothing);
    semantics.dispose();
  });

  testWidgets('an ar-EG article: the Arabic explanation, then the English definition labelled "In English"', (tester) async {
    final semantics = tester.ensureSemantics();
    answer(() async => const Ok(diTerm));
    await pumpView(tester);

    // The English term replaces the tapped words, left to right and isolated.
    final header = tester.widget<Text>(find.text(Bidi.ltrIsolate('Dependency Injection')));
    expect(header.textDirection, TextDirection.ltr);
    expect(header.data, Bidi.ltrIsolate('Dependency Injection'));
    expect(find.bySemanticsLabel('Glossary, Dependency Injection'), findsOneWidget);

    final explanation = textWidget(tester, 'ما يعملش');
    final definition = textWidget(tester, 'A technique');
    expect(explanation.textDirection, TextDirection.rtl);
    expect(explanation.data, contains('${Bidi.fsi}DI container${Bidi.pdi}'), reason: 'English runs are isolated (SPEC §14.2)');
    expect(definition.textDirection, TextDirection.ltr);
    expect(top(tester, find.textContaining('ما يعملش')), lessThan(top(tester, find.text('In English'))));
    expect(top(tester, find.text('In English')), lessThan(top(tester, find.textContaining('A technique'))));
    semantics.dispose();
  });

  testWidgets('an en article shows only the English definition in the English UI', (tester) async {
    answer(() async => const Ok(diTerm), language: 'en');
    await pumpView(tester, language: 'en');

    expect(find.textContaining('A technique'), findsOneWidget);
    expect(find.textContaining('ما يعملش'), findsNothing);
    expect(find.text('In English'), findsNothing);
  });

  testWidgets('an en article adds the Arabic explanation second in the Arabic UI', (tester) async {
    answer(() async => const Ok(diTerm), language: 'en');
    await pumpView(tester, language: 'en', variant: _ar);

    expect(find.text('بالعربي'), findsOneWidget);
    expect(find.text('بالإنجليزي'), findsNothing);
    expect(top(tester, find.textContaining('A technique')), lessThan(top(tester, find.text('بالعربي'))));
    expect(top(tester, find.text('بالعربي')), lessThan(top(tester, find.textContaining('ما يعملش'))));
  });

  testWidgets("the term's articles leave out the open one and show at most 5, titles in their own direction", (tester) async {
    final semantics = tester.ensureSemantics();
    answer(() async => const Ok(diTerm));
    await pumpView(tester);

    expect(find.text('Articles that use this term'), findsOneWidget);
    expect(find.textContaining('Transient'), findsNothing, reason: 'art-1 is the article being read');
    for (final article in diArticles.skip(1)) {
      final direction = article.language == 'en' ? TextDirection.ltr : TextDirection.rtl;
      final title = tester.widget<Text>(find.text(Bidi.isolateOppositeRuns(article.title, direction)));
      expect(title.textDirection, direction);
    }
    expect(find.bySemanticsLabel('Testing services with fakes instead of mocks, .NET, 4 min read'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(5));
    semantics.dispose();
  });

  testWidgets('more than 5 other articles: the first 5', (tester) async {
    final many = GlossaryTerm(
      slug: diTerm.slug,
      term: diTerm.term,
      definitionEn: diTerm.definitionEn,
      explanationAr: diTerm.explanationAr,
      articles: [
        for (var i = 0; i < 6; i++)
          GlossaryArticle(id: 'x-$i', slug: 'x-$i', language: 'en', title: 'Article $i', readingTimeMinutes: 3, field: diArticles[0].field),
      ],
    );
    answer(() async => Ok(many));
    await pumpView(tester);

    expect(find.text('Article 4'), findsOneWidget);
    expect(find.text('Article 5'), findsNothing);
  });

  testWidgets('no other article uses the term: no articles section', (tester) async {
    final alone = GlossaryTerm(
      slug: diTerm.slug,
      term: diTerm.term,
      definitionEn: diTerm.definitionEn,
      explanationAr: diTerm.explanationAr,
      articles: [diArticles.first],
    );
    answer(() async => Ok(alone));
    await pumpView(tester);

    expect(find.text('Articles that use this term'), findsNothing);
  });

  testWidgets('a term not in the glossary: the tapped words and "not in the glossary yet"', (tester) async {
    answer(() async => const Err(Failure(FailureCodes.glossaryTermNotFound, statusCode: 404)));
    await pumpView(tester, text: 'Service Locator');

    expect(find.textContaining('Service Locator'), findsOneWidget);
    expect(find.text("This term isn't in the glossary yet"), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('an error offers "Try again", which loads the term', (tester) async {
    var calls = 0;
    answer(() async => calls++ == 0 ? const Err(Failure(FailureCodes.networkOffline)) : const Ok(diTerm));
    await pumpView(tester);

    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('In English'), findsOneWidget);
  });

  testWidgets('large text still lays out (the sheet scrolls)', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    answer(() async => const Ok(diTerm));
    await pumpView(tester, variant: _ar);

    expect(tester.takeException(), isNull);
    expect(find.text('بالإنجليزي'), findsOneWidget);
  });

  testWidgets('the sheet loads the term for the version being read; a picked article closes it with its slug', (tester) async {
    answer(() async => const Ok(diTerm));
    usePhoneSurface(tester, size: const Size(390, 1400));
    String? picked;
    await tester.pumpWidget(testApp(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await showGlossarySheet(
              context,
              termId: 'dependency-injection',
              text: 'DI',
              language: 'ar-EG',
              articleId: 'art-1',
              cubit: () => GlossaryTermCubit(GetGlossaryTerm(repository)),
            ),
            child: const Text('term'),
          ),
        ),
      ),
      variant: _en,
    ));

    await tester.tap(find.text('term'));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    verify(() => repository.getTerm('dependency-injection', language: 'ar-EG')).called(1);

    await tester.tap(find.textContaining('fakes'));
    await tester.pumpAndSettle();
    expect(picked, 'testing-with-fakes');
    expect(find.byType(GlossaryTermView), findsNothing);
  });
}

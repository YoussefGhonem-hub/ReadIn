import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/paths/domain/usecases/path_usecases.dart';
import 'package:readin/features/paths/presentation/cubit/article_path_cubit.dart';
import 'package:readin/features/paths/presentation/widgets/next_in_path.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/path_fakes.dart';
import '../../helpers/path_fixtures.dart';

/// The reader's "Next in path" block (F04, F09).
void main() {
  late MockPathsRepository repository;
  late List<String> opened;

  setUp(() {
    repository = MockPathsRepository();
    opened = [];
  });

  Future<void> pumpCard(WidgetTester tester, Widget card, {Me? me = sampleMe}) =>
      pumpRouted(tester, Scaffold(body: SingleChildScrollView(child: card)), opened: opened, me: me);

  testWidgets('the path, the place in it, the next article, and Join', (tester) async {
    var joined = 0;
    String? next;
    await pumpCard(
      tester,
      NextInPathCard(articlePath: sampleArticlePath(), onJoin: () => joined++, onOpenPath: () {}, onOpenNext: (slug) => next = slug),
    );

    expect(find.textContaining('From the path: '), findsOneWidget);
    expect(find.text('2 of 4'), findsOneWidget);
    expect(find.text('Next in path'), findsOneWidget);
    expect(find.text('This is the last article in the path'), findsNothing);
    expect(find.text('2/4'), findsNothing, reason: "a guest's path has no progress");

    await tester.tap(find.text('Join path'));
    expect(joined, 1);
    await tester.tap(find.textContaining('EF Core:'));
    expect(next, 'article-3');
  });

  testWidgets('the last article: the last-one line and, once done, the celebration; no Join when enrolled', (tester) async {
    await pumpCard(
      tester,
      NextInPathCard(
        articlePath: sampleArticlePath(last: true, readCount: 4, completed: true),
        onJoin: () {},
        onOpenPath: () {},
        onOpenNext: (_) {},
      ),
    );

    expect(find.text('This is the last article in the path'), findsOneWidget);
    expect(find.text('Path completed 🎉'), findsOneWidget);
    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('Next in path'), findsNothing);
    expect(find.text('Join path'), findsNothing);
  });

  group('NextInPathSliver', () {
    late ArticlePathCubit cubit;

    setUp(() {
      cubit = ArticlePathCubit(GetArticlePath(repository), SetPathEnrollment(repository));
      getIt.registerFactory<ArticlePathCubit>(() => cubit);
    });

    tearDown(() => getIt.unregister<ArticlePathCubit>());

    /// A long article, then the block.
    Widget reader() => const Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: 3000)),
              NextInPathSliver(articleId: 'art-2'),
            ],
          ),
        );

    Future<void> pumpReader(WidgetTester tester, {Me? me = sampleMe}) => pumpRouted(tester, reader(), opened: opened, me: me);

    /// Scrolls to the end of the article, then once more: the block grows the scroll extent when it is built.
    Future<void> scrollToEnd(WidgetTester tester) async {
      for (var i = 0; i < 2; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('loads only when the end of the article comes near, then shows the block', (tester) async {
      when(() => repository.getArticlePath('art-2')).thenAnswer((_) async => Ok(sampleArticlePath()));
      await pumpReader(tester);
      verifyNever(() => repository.getArticlePath(any()));

      await scrollToEnd(tester);

      verify(() => repository.getArticlePath('art-2')).called(1);
      expect(find.text('Next in path'), findsOneWidget);

      await tester.tap(find.textContaining('From the path: '));
      await tester.pumpAndSettle();
      expect(opened, ['/paths/aspnet-core-basics']);
    });

    testWidgets('an article in no path (204) renders nothing', (tester) async {
      when(() => repository.getArticlePath('art-2')).thenAnswer((_) async => const Ok(null));
      await pumpReader(tester);
      await scrollToEnd(tester);

      verify(() => repository.getArticlePath('art-2')).called(1);
      expect(find.textContaining('From the path', skipOffstage: false), findsNothing);
    });

    testWidgets('Join path enrolls, reloads and says so', (tester) async {
      var calls = 0;
      when(() => repository.getArticlePath('art-2'))
          .thenAnswer((_) async => Ok(++calls == 1 ? sampleArticlePath(readCount: 1) : sampleArticlePath(readCount: 1, enrolled: true)));
      when(() => repository.enroll('p-1')).thenAnswer((_) async => Ok(samplePath(readCount: 1, enrolled: true)));
      await pumpReader(tester);
      await scrollToEnd(tester);

      await tester.tap(find.text('Join path'));
      await tester.pumpAndSettle();

      verify(() => repository.enroll('p-1')).called(1);
      expect(find.text('You joined the path'), findsOneWidget);
      expect(find.text('Join path'), findsNothing);
    });

    testWidgets('a guest gets the sign-in prompt on Join', (tester) async {
      when(() => repository.getArticlePath('art-2')).thenAnswer((_) async => Ok(sampleArticlePath()));
      await pumpReader(tester, me: null);
      await scrollToEnd(tester);

      await tester.tap(find.text('Join path'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to continue'), findsOneWidget);
      verifyNever(() => repository.enroll(any()));
    });
  });
}

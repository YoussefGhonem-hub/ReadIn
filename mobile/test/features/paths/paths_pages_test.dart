import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/paths/domain/usecases/path_usecases.dart';
import 'package:readin/features/paths/presentation/cubit/path_details_cubit.dart';
import 'package:readin/features/paths/presentation/cubit/path_list_cubit.dart';
import 'package:readin/features/paths/presentation/pages/path_page.dart';
import 'package:readin/features/paths/presentation/pages/paths_page.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/path_fakes.dart';
import '../../helpers/path_fixtures.dart';

/// `/paths` (All · My paths) and `/paths/{slug}` (F09).
void main() {
  late MockPathsRepository repository;
  late List<String> opened;

  setUp(() {
    repository = MockPathsRepository();
    opened = [];
  });

  Future<GoRouter> pump(WidgetTester tester, Widget child, {Me? me = sampleMe, List<BlocProvider> providers = const []}) =>
      pumpRouted(tester, child, opened: opened, me: me, providers: providers);

  group('paths list (/paths)', () {
    late AllPathsCubit all;
    late MyPathsCubit mine;

    setUp(() {
      all = AllPathsCubit(GetPaths(repository));
      mine = MyPathsCubit(GetMyPaths(repository));
      when(() => repository.getPaths()).thenAnswer((_) async => Ok(samplePaths()));
    });

    tearDown(() async {
      await all.close();
      await mine.close();
    });

    List<BlocProvider> lists() => [BlocProvider<AllPathsCubit>.value(value: all..load()), BlocProvider<MyPathsCubit>.value(value: mine)];

    testWidgets('cards with progress and the completion badge; field chips filter the list', (tester) async {
      await pump(tester, const PathsView(), providers: lists());
      await tester.pumpAndSettle();

      expect(find.textContaining('ASP.NET Core'), findsOneWidget);
      expect(find.textContaining('AI Agents'), findsOneWidget);
      expect(find.textContaining('EF Core'), findsOneWidget);
      expect(find.text('4 articles  ·  26 min'), findsOneWidget);
      expect(find.text('3 articles  ·  26 min'), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);
      expect(find.text('5/5'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'AI'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ASP.NET Core'), findsNothing);
      expect(find.textContaining('AI Agents'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ASP.NET Core'), findsOneWidget);
    });

    testWidgets('opening a path pushes /paths/{slug}; back on the list, it refreshes', (tester) async {
      final router = await pump(tester, const PathsView(), providers: lists());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('AI Agents'));
      await tester.pumpAndSettle();
      expect(opened, ['/paths/ai-agents-101']);

      router.pop();
      await tester.pumpAndSettle();
      verify(() => repository.getPaths()).called(2);
      verifyNever(() => repository.getMyPaths()); // its tab was never shown
    });

    testWidgets('My paths: a guest gets the sign-in invitation and no request', (tester) async {
      await pump(tester, const PathsView(), me: null, providers: lists());
      await tester.tap(find.text('My paths'));
      await tester.pumpAndSettle();

      expect(find.text('Keep track of your paths'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      verifyNever(() => repository.getMyPaths());
    });

    testWidgets('My paths loads when shown; empty, it leads back to all paths', (tester) async {
      when(() => repository.getMyPaths()).thenAnswer((_) async => const Ok([]));
      await pump(tester, const PathsView(), providers: lists());
      await tester.tap(find.text('My paths'));
      await tester.pumpAndSettle();

      verify(() => repository.getMyPaths()).called(1);
      expect(find.text("You haven't started a path yet"), findsOneWidget);

      await tester.tap(find.text('Explore learning paths'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ASP.NET Core'), findsOneWidget);
    });

    testWidgets('a failed load offers a retry', (tester) async {
      when(() => repository.getPaths()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      await pump(tester, const PathsView(), providers: lists());
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('path page (/paths/{slug})', () {
    late PathDetailsCubit cubit;

    setUp(() => cubit = PathDetailsCubit(GetPath(repository), SetPathEnrollment(repository)));
    tearDown(() => cubit.close());

    Future<GoRouter> pumpPath(WidgetTester tester, {Me? me = sampleMe}) async {
      unawaited(cubit.load('aspnet-core-basics'));
      final router = await pump(tester, const PathView(), me: me, providers: [BlocProvider<PathDetailsCubit>.value(value: cubit)]);
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('a guest sees the path and "Start path" asks them to sign in', (tester) async {
      when(() => repository.getPath('aspnet-core-basics')).thenAnswer((_) async => Ok(samplePathDetails()));
      await pumpPath(tester, me: null);

      expect(find.textContaining('ASP.NET Core'), findsOneWidget);
      expect(find.text('4 articles  ·  26 min'), findsOneWidget);
      expect(find.byTooltip('Path options'), findsNothing);

      await tester.tap(find.text('Start path'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to continue'), findsOneWidget);
      verifyNever(() => repository.enroll(any()));
    });

    testWidgets('"Start path" enrolls and opens the next article; back here, the page refreshes', (tester) async {
      var loads = 0;
      when(() => repository.getPath('aspnet-core-basics'))
          .thenAnswer((_) async => Ok(samplePathDetails(readCount: 1, enrolled: ++loads > 1)));
      when(() => repository.enroll('p-1')).thenAnswer((_) async => Ok(samplePath(readCount: 1, enrolled: true)));
      final router = await pumpPath(tester);

      await tester.tap(find.text('Start path'));
      await tester.pumpAndSettle();

      verify(() => repository.enroll('p-1')).called(1);
      expect(opened, ['/a/article-2']);

      router.pop();
      await tester.pumpAndSettle();
      verify(() => repository.getPath('aspnet-core-basics')).called(2);
      expect(find.byTooltip('Path options'), findsOneWidget);
    });

    testWidgets('enrolled: "Continue: {next}", read ticks and the next article highlighted', (tester) async {
      when(() => repository.getPath('aspnet-core-basics')).thenAnswer((_) async => Ok(samplePathDetails(readCount: 2, enrolled: true)));
      await pumpPath(tester);

      expect(find.textContaining('Continue: '), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);
      expect(find.text('Up next'), findsOneWidget);
      expect(find.bySemanticsLabel('1, Read'), findsOneWidget);
      expect(find.bySemanticsLabel('2, Read'), findsOneWidget);
      expect(find.bySemanticsLabel('3'), findsOneWidget);

      await tester.tap(find.textContaining('Continue: '));
      await tester.pumpAndSettle();
      expect(opened, ['/a/article-3']);
    });

    testWidgets('every article read: the completion badge and "Read again" from the first', (tester) async {
      when(() => repository.getPath('aspnet-core-basics')).thenAnswer((_) async => Ok(samplePathDetails(readCount: 4, completed: true)));
      await pumpPath(tester);

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Up next'), findsNothing);
      await tester.tap(find.text('Read again'));
      await tester.pumpAndSettle();
      expect(opened, ['/a/article-1']);
    });

    testWidgets('"Leave path" asks first, then leaves', (tester) async {
      when(() => repository.getPath('aspnet-core-basics')).thenAnswer((_) async => Ok(samplePathDetails(readCount: 2, enrolled: true)));
      when(() => repository.leave('p-1')).thenAnswer((_) async => const Ok(null));
      await pumpPath(tester);

      await tester.tap(find.byTooltip('Path options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave path'));
      await tester.pumpAndSettle();
      expect(find.text('Leave this path?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Leave path'));
      await tester.pumpAndSettle();
      verify(() => repository.leave('p-1')).called(1);
      expect(find.text('You left the path'), findsOneWidget);
      expect(find.byTooltip('Path options'), findsNothing);
      expect(find.text('Start path'), findsOneWidget);
    });

    testWidgets('cancelling the dialog keeps the enrollment', (tester) async {
      when(() => repository.getPath('aspnet-core-basics')).thenAnswer((_) async => Ok(samplePathDetails(readCount: 2, enrolled: true)));
      await pumpPath(tester);

      await tester.tap(find.byTooltip('Path options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave path'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => repository.leave(any()));
    });

    testWidgets('404 path.not_found shows the not-found state', (tester) async {
      when(() => repository.getPath('aspnet-core-basics'))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.pathNotFound, statusCode: 404)));
      await pumpPath(tester);

      expect(find.text("This path isn't available"), findsOneWidget);
    });
  });
}

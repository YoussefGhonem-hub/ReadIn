import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/app/app.dart';
import 'package:readin/app/splash_page.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/app_update/domain/entities/update_policy.dart';
import 'package:readin/features/app_update/presentation/cubit/app_update_cubit.dart';
import 'package:readin/features/app_update/presentation/pages/update_required_page.dart';
import 'package:readin/features/app_update/presentation/widgets/app_update_gate.dart';
import 'package:readin/features/app_update/presentation/widgets/update_motion.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/blocks/presentation/cubit/blocks_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_notices_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/reported_content_cubit.dart';
import 'package:readin/features/mutes/presentation/cubit/mutes_cubit.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';
import 'package:readin/features/reading/presentation/cubit/streak_cubit.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/shared/widgets/app_logo.dart';

import '../../helpers/app_update_fakes.dart';
import '../../helpers/moderation_fakes.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockStreakCubit extends MockCubit<Streak?> implements StreakCubit {}

class MockMutesCubit extends MockCubit<MutesState> implements MutesCubit {}

class MockBlocksCubit extends MockCubit<BlocksState> implements BlocksCubit {}

class MockReportedContentCubit extends MockCubit<Set<String>> implements ReportedContentCubit {}

/// A cubit whose answers the test sends.
MockAppUpdateCubit updateCubit(StreamController<AppUpdateState> answers, AppUpdateState initial) {
  final cubit = MockAppUpdateCubit();
  whenListen(cubit, answers.stream, initialState: initial);
  when(cubit.resumed).thenAnswer((_) async {});
  return cubit;
}

const _required = AppUpdateState(requirement: UpdateRequirement(storeUrl: playStoreUrl));

void main() {
  group('the Update page', () {
    for (final variant in Variant.all) {
      AppLocalizations l10n() => lookupAppLocalizations(variant.locale);

      testWidgets('Android: "Update now" opens the store page outside the app (${variant.name})', (tester) async {
        final launcher = FakeStoreLauncher();
        await tester.pumpWidget(testApp(
          UpdateRequiredPage(requirement: const UpdateRequirement(storeUrl: playStoreUrl), launchStore: launcher.call),
          variant: variant,
        ));

        expect(find.byType(AppLogo), findsOneWidget);
        expect(find.byType(UpdateHero), findsOneWidget);
        expect(find.text(l10n().updateRequiredTitle), findsOneWidget);
        expect(find.text(l10n().updateRequiredBody), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, l10n().updateRequiredAction));

        expect(launcher.opened, [Uri.parse(playStoreUrl)]);
      });

      testWidgets('iOS without a store page: no button, only the text (${variant.name})', (tester) async {
        await tester.pumpWidget(testApp(const UpdateRequiredPage(requirement: UpdateRequirement()), variant: variant));

        expect(find.text(l10n().updateRequiredTitle), findsOneWidget);
        expect(find.text(l10n().updateRequiredBody), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
        expect(find.text(l10n().updateRequiredAction), findsNothing);
      });

      testWidgets('reads as a heading, a message and a button (${variant.name})', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(testApp(
          UpdateRequiredPage(requirement: const UpdateRequirement(storeUrl: appStoreUrl), launchStore: FakeStoreLauncher().call),
          variant: variant,
        ));

        expect(find.bySemanticsLabel('ReadIn'), findsOneWidget);
        expect(tester.getSemantics(find.text(l10n().updateRequiredTitle)), isSemantics(isHeader: true));
        expect(
          tester.getSemantics(find.widgetWithText(FilledButton, l10n().updateRequiredAction)),
          isSemantics(label: l10n().updateRequiredAction, isButton: true, hasTapAction: true),
        );
        semantics.dispose();
      });

      testWidgets('large text on a small phone scrolls instead of overflowing (${variant.name})', (tester) async {
        usePhoneSurface(tester, size: const Size(320, 480));
        await tester.pumpWidget(MediaQuery(
          data: const MediaQueryData(size: Size(320, 480), textScaler: TextScaler.linear(2)),
          child: testApp(
            UpdateRequiredPage(requirement: const UpdateRequirement(storeUrl: playStoreUrl), launchStore: FakeStoreLauncher().call),
            variant: variant,
          ),
        ));

        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.byType(FilledButton), 100);
        expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
      });
    }

    testWidgets('back does not leave it', (tester) async {
      await tester.pumpWidget(testApp(Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const UpdateRequiredPage(requirement: UpdateRequirement()),
          )),
          child: const Text('open'),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(UpdateRequiredPage), findsOneWidget);
    });
  });

  group('the gate above the router', () {
    late StreamController<AppUpdateState> answers;

    setUp(() => answers = StreamController<AppUpdateState>.broadcast());
    tearDown(() => answers.close());

    Future<GoRouter> pumpRouterApp(WidgetTester tester, MockAppUpdateCubit cubit, {FakeStoreLauncher? launcher}) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Home'))),
          GoRoute(path: '/a/:slug', builder: (_, state) => Scaffold(body: Text('Article ${state.pathParameters['slug']}'))),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(BlocProvider<AppUpdateCubit>.value(
        value: cubit,
        child: MaterialApp.router(
          theme: AppTheme.light(AppLocales.en),
          locale: AppLocales.en,
          supportedLocales: AppLocales.supported,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
          builder: (context, child) => AppUpdateGate(launchStore: (launcher ?? FakeStoreLauncher()).call, child: child!),
        ),
      ));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('replaces every route, deep links and pushed screens included, until the update lifts', (tester) async {
      final launcher = FakeStoreLauncher();
      final router = await pumpRouterApp(tester, updateCubit(answers, _required), launcher: launcher);

      expect(find.byType(UpdateRequiredPage), findsOneWidget);
      expect(find.text('Home'), findsNothing);

      router.go('/a/deep-link');
      await tester.pumpAndSettle();
      unawaited(router.push<void>('/a/push-tap'));
      await tester.pumpAndSettle();
      expect(find.byType(UpdateRequiredPage), findsOneWidget);
      expect(find.textContaining('Article'), findsNothing);

      await tester.tap(find.text('Update now'));
      expect(launcher.opened, [Uri.parse(playStoreUrl)]);

      answers.add(const AppUpdateState()); // the minimum was lowered
      await tester.pumpAndSettle();
      expect(find.byType(UpdateRequiredPage), findsNothing);
      expect(find.text('Article push-tap'), findsOneWidget);
    });

    testWidgets('a policy that arrives while the app is open takes over the current screen', (tester) async {
      await pumpRouterApp(tester, updateCubit(answers, const AppUpdateState()));
      expect(find.text('Home'), findsOneWidget);

      answers.add(_required);
      await tester.pumpAndSettle();

      expect(find.byType(UpdateRequiredPage), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('checks again when the app returns to the foreground', (tester) async {
      final cubit = updateCubit(answers, const AppUpdateState());
      await pumpRouterApp(tester, cubit);

      void go(List<AppLifecycleState> states) => states.forEach(tester.binding.handleAppLifecycleStateChanged);
      addTearDown(() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));

      go([AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]);
      verifyNever(cubit.resumed);
      go([AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);

      verify(cubit.resumed).called(1);
    });

    group('in ReadInApp', () {
      setUp(() {
        getIt
          ..registerSingleton<StreakCubit>(MockStreakCubit()..hold(null))
          ..registerSingleton<ModerationNoticesCubit>(MockModerationNoticesCubit()..hold(const []))
          ..registerSingleton<MutesCubit>(MockMutesCubit()..hold(const MutesState()))
          // F36, F22 store additions: the app provides them like the mutes.
          ..registerSingleton<BlocksCubit>(MockBlocksCubit()..hold(const BlocksState()))
          ..registerSingleton<ReportedContentCubit>(MockReportedContentCubit()..hold(const <String>{}));
      });

      tearDown(() async {
        await getIt.unregister<StreakCubit>();
        await getIt.unregister<ModerationNoticesCubit>();
        await getIt.unregister<MutesCubit>();
        await getIt.unregister<BlocksCubit>();
        await getIt.unregister<ReportedContentCubit>();
      });

      for (final variant in Variant.all) {
        testWidgets('the Update page stands in for the splash and every screen after it (${variant.name})', (tester) async {
          final settings = MockSettingsCubit()..hold(const AppSettings(welcomeSeen: true));
          when(() => settings.locale).thenReturn(variant.locale);
          when(() => settings.themeMode)
              .thenReturn(variant.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light);
          final follows = MockFollowsCubit()..hold(const FollowsState());
          when(() => follows.changes).thenAnswer((_) => const Stream.empty());
          final pushOpens = StreamController<String>();
          addTearDown(pushOpens.close);

          await tester.pumpWidget(ReadInApp(
            session: MockSessionCubit()..hold(const SessionState()), // still restoring: the splash
            settings: settings,
            social: SocialStores(
              engagement: MockEngagementCubit()..hold(const EngagementState()),
              follows: follows,
              collections: MockCollectionsCubit()..hold(const CollectionsState()),
            ),
            appUpdate: updateCubit(answers, _required),
            pushOpens: pushOpens.stream,
          ));
          await tester.pump();

          expect(find.byType(UpdateRequiredPage), findsOneWidget);
          expect(find.byType(SplashPage), findsNothing);
          expect(find.text(lookupAppLocalizations(variant.locale).updateRequiredTitle), findsOneWidget);

          pushOpens.add('/a/di-in-dotnet'); // a push tap
          await tester.pump();
          await tester.pump();
          expect(find.byType(UpdateRequiredPage), findsOneWidget);

          answers.add(const AppUpdateState());
          await tester.pump();
          await tester.pump();
          expect(find.byType(UpdateRequiredPage), findsNothing);
          expect(find.byType(SplashPage), findsOneWidget);
        });
      }
    });
  });
}

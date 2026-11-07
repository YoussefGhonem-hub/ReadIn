import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:readin/features/auth/presentation/pages/sign_in_page.dart';
import 'package:readin/features/auth/presentation/widgets/auth_showcase.dart';
import 'package:readin/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';

import '../../helpers/test_app.dart';

class MockSignInCubit extends MockCubit<SignInState> implements SignInCubit {}

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

/// Sign in's look and motion, after the web login: the showcase header, the form rising piece by piece, the error
/// shake, and reduce motion. The rest of the suite sees the screen at rest (flutter_test_config.dart).
void main() {
  late MockSignInCubit cubit;

  setUp(() {
    cubit = MockSignInCubit();
    whenListen(cubit, const Stream<SignInState>.empty(), initialState: const SignInState());
  });

  Future<void> pump(WidgetTester tester, {SettingsCubit? settings}) async {
    usePhoneSurface(tester);
    Widget view = BlocProvider<SignInCubit>.value(value: cubit, child: const SignInView());
    if (settings != null) view = BlocProvider<SettingsCubit>.value(value: settings, child: view);
    await tester.pumpWidget(testApp(view, variant: const Variant(AppLocales.en, Brightness.light)));
  }

  /// The opacity of the piece of the form that holds [text].
  double opacityOf(WidgetTester tester, String text) =>
      tester.widget<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first).opacity;

  group('with motion', () {
    setUp(() => AuthMotion.enabled = true);
    tearDown(() => AuthMotion.enabled = false);

    testWidgets('the form rises in piece by piece and then rests, while the showcase keeps moving', (tester) async {
      await pump(tester);
      expect(opacityOf(tester, 'Welcome back'), 0);

      await tester.pump(const Duration(milliseconds: 400));
      final title = opacityOf(tester, 'Welcome back');
      expect(title, greaterThan(0));
      expect(opacityOf(tester, 'Create one'), lessThan(title), reason: 'the footer rises after the title');

      await tester.pump(const Duration(seconds: 2));
      expect(opacityOf(tester, 'Welcome back'), 1);
      expect(opacityOf(tester, 'Create one'), 1);
      expect(find.text('12'), findsOneWidget, reason: 'the streak has counted up');

      await tester.pump(const Duration(seconds: 5));
      expect(tester.hasRunningAnimations, isTrue, reason: 'the cards float on');
    });

    testWidgets('an error shakes once', (tester) async {
      whenListen(
        cubit,
        const Stream<SignInState>.empty(),
        initialState: const SignInState(failure: Failure(FailureCodes.userSuspended, statusCode: 403)),
      );
      await pump(tester);
      await tester.pump(const Duration(seconds: 1)); // risen
      final banner = find.byType(FailureBanner);
      final rest = tester.getTopLeft(banner).dx;

      // Shown again (a second failed attempt): it shakes, then settles where it was.
      await tester.pumpWidget(const SizedBox());
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getTopLeft(banner).dx, isNot(rest));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getTopLeft(banner).dx, rest);
    });

    testWidgets('with reduce motion everything rests in place and nothing ticks', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pump(tester);

      expect(opacityOf(tester, 'Welcome back'), 1);
      expect(opacityOf(tester, 'Create one'), 1);
      expect(find.text('12'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('the showcase is hidden from screen readers; the language switch is named', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    expect(find.bySemanticsLabel('Switch the app language to العربية'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('language models')), findsNothing);
    expect(find.bySemanticsLabel('Welcome back'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the language switch changes the app language', (tester) async {
    final settings = MockSettingsCubit();
    whenListen(settings, const Stream<AppSettings>.empty(), initialState: const AppSettings());
    when(() => settings.setUiLanguage(any())).thenAnswer((_) async => null);
    await pump(tester, settings: settings);

    await tester.tap(find.text('العربية'));
    verify(() => settings.setUiLanguage('ar')).called(1);
  });
}

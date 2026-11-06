import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/current_locale.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/article/presentation/widgets/reading_mode.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:readin/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/domain/repositories/settings_repository.dart';
import 'package:readin/features/settings/domain/usecases/settings_usecases.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';

import '../../helpers/test_app.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockMigrateDailyArticleSwitch extends Mock implements MigrateDailyArticleSwitch {}

const _progressKey = ValueKey('probe-progress');
const _topBarKey = ValueKey('probe-top-bar');
const _actionBarKey = ValueKey('probe-action-bar');

/// A reader's shape, wired like the real one (article_page.dart): the progress bar, a top bar with the toggle, the
/// text, an action bar, and the exit control in the Scaffold's floating slot.
class _Reader extends StatefulWidget {
  const _Reader();

  @override
  State<_Reader> createState() => _ReaderState();
}

class _ReaderState extends State<_Reader> {
  final scroll = ScrollController();

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = readingModeOf(context);
    return ReadingModeFrame(
      controller: scroll,
      child: Scaffold(
        floatingActionButton: on ? const ReadingModeExitButton() : null,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
        body: SafeArea(
          child: Column(
            children: [
              // The progress and the top bar in their own column, as in the reader, so the scroll view stays the same.
              Column(
                children: [
                  const SizedBox(key: _progressKey, height: 3, width: double.infinity),
                  if (!on) const SizedBox(key: _topBarKey, height: 56, child: Row(children: [Spacer(), ReadingModeToggle()])),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  itemCount: 120,
                  itemBuilder: (_, i) => SizedBox(height: 40, child: Text('line $i')),
                ),
              ),
              if (!on) const SizedBox(key: _actionBarKey, height: 56),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reading mode (F04): the toggle in the reader's top bar, the floating way out, system back, the text staying in
/// place, reduce motion, both directions, and the device-only setting.
void main() {
  late _MockSettingsRepository repository;
  late _MockMigrateDailyArticleSwitch migrate;

  setUpAll(() => registerFallbackValue(const AppSettings()));

  setUp(() {
    repository = _MockSettingsRepository();
    migrate = _MockMigrateDailyArticleSwitch();
    when(() => migrate()).thenAnswer((_) async => true);
    when(() => repository.load()).thenReturn(const AppSettings());
    when(() => repository.save(any())).thenAnswer((_) async {});
    when(() => repository.pushPreferences(any())).thenAnswer((_) async => const Ok(null));
  });

  SettingsCubit settings() {
    final cubit =
        SettingsCubit(LoadSettings(repository), SaveSettings(repository), SyncPreferences(repository), CurrentLocale(), migrate);
    addTearDown(cubit.close);
    return cubit;
  }

  /// The reader pushed over a home page, so back has somewhere to go.
  Future<SettingsCubit> pumpReader(
    WidgetTester tester, {
    Variant variant = const Variant(AppLocales.en, Brightness.light),
    bool reduceMotion = false,
    SettingsCubit? cubit,
  }) async {
    usePhoneSurface(tester);
    final settingsCubit = cubit ?? settings();
    Widget app = testApp(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _Reader())),
              child: const Text('open reader'),
            ),
          ),
        ),
      ),
      variant: variant,
    );
    app = BlocProvider<SettingsCubit>.value(value: settingsCubit, child: app);
    if (reduceMotion) {
      app = MediaQuery(data: const MediaQueryData(size: Size(390, 844), disableAnimations: true), child: app);
    }
    await tester.pumpWidget(app);
    await tester.tap(find.text('open reader'));
    await tester.pumpAndSettle();
    return settingsCubit;
  }

  testWidgets('the button turns it on: the bars hide, the text and the progress stay; the floating control turns it off',
      (tester) async {
    final cubit = await pumpReader(tester);
    expect(find.byKey(_topBarKey), findsOneWidget);
    expect(find.byKey(ReadingModeExitButton.exitKey), findsNothing);

    await tester.tap(find.byTooltip('Reading mode'));
    await tester.pumpAndSettle();
    expect(cubit.state.readingMode, isTrue);
    expect(find.byKey(_topBarKey), findsNothing);
    expect(find.byKey(_actionBarKey), findsNothing);
    expect(find.byKey(_progressKey), findsOneWidget);
    expect(find.text('line 0'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Exit reading mode'), findsOneWidget);

    await tester.tap(find.byKey(ReadingModeExitButton.exitKey));
    await tester.pumpAndSettle();
    expect(cubit.state.readingMode, isFalse);
    expect(find.byKey(_topBarKey), findsOneWidget);
    expect(find.byKey(_actionBarKey), findsOneWidget);
    expect(find.byKey(ReadingModeExitButton.exitKey), findsNothing);
  });

  testWidgets('the toggle is a named button that says whether it is on; Arabic labels', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpReader(tester, variant: const Variant(AppLocales.ar, Brightness.light));
    expect(
      tester.getSemantics(find.byKey(ReadingModeToggle.buttonKey)),
      isSemantics(tooltip: 'وضع القراءة', isButton: true, hasSelectedState: true, isSelected: false, isEnabled: true),
    );

    await tester.tap(find.byTooltip('وضع القراءة'));
    await tester.pumpAndSettle();
    expect(find.text('الخروج من وضع القراءة'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('الخروج من وضع القراءة')),
      isSemantics(label: 'الخروج من وضع القراءة', isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('system back leaves reading mode first, then the reader', (tester) async {
    final cubit = await pumpReader(tester);
    await tester.tap(find.byTooltip('Reading mode'));
    await tester.pumpAndSettle();

    // Android's back button / gesture.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(cubit.state.readingMode, isFalse);
    expect(find.byKey(_topBarKey), findsOneWidget, reason: 'still in the reader, with its bars back');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('open reader'), findsOneWidget);
  });

  testWidgets('switching keeps the text where it was on screen', (tester) async {
    final cubit = await pumpReader(tester);
    tester.widget<ListView>(find.byType(ListView)).controller!.jumpTo(900);
    await tester.pumpAndSettle();
    final line = find.text('line 30');
    final before = tester.getTopLeft(line).dy;

    await cubit.setReadingMode(true);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(line).dy, moreOrLessEquals(before), reason: 'the top bar left: its height came back as scroll');

    await cubit.setReadingMode(false);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(line).dy, moreOrLessEquals(before));
  });

  testWidgets('at the top of the article, turning it on stays at the top', (tester) async {
    final cubit = await pumpReader(tester);
    await cubit.setReadingMode(true);
    await tester.pumpAndSettle();
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.controller!.offset, 0);
    expect(tester.takeException(), isNull);
  });

  for (final variant in [const Variant(AppLocales.ar, Brightness.light), const Variant(AppLocales.en, Brightness.dark)]) {
    testWidgets('the floating control sits at the bottom end corner ${variant.name}', (tester) async {
      final cubit = await pumpReader(tester, variant: variant);
      await cubit.setReadingMode(true);
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byKey(ReadingModeExitButton.exitKey));
      expect(rect.bottom, greaterThan(844 - 100));
      if (variant.locale == AppLocales.ar) {
        expect(rect.left, lessThan(40), reason: 'RTL: the end is the left');
      } else {
        expect(rect.right, greaterThan(390 - 40), reason: 'LTR: the end is the right');
      }
    });
  }

  testWidgets('the floating control fades in, unless reduce motion is on', (tester) async {
    final cubit = await pumpReader(tester);
    await cubit.setReadingMode(true);
    await tester.pump();
    double opacity() => tester
        .widget<Opacity>(find.ancestor(of: find.byType(OutlinedButton), matching: find.byType(Opacity)).first)
        .opacity;
    expect(opacity(), lessThan(1));
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });

  testWidgets('with reduce motion the floating control shows at once', (tester) async {
    final cubit = await pumpReader(tester, reduceMotion: true);
    await cubit.setReadingMode(true);
    await tester.pump();
    final opacity = tester
        .widget<Opacity>(find.ancestor(of: find.byType(OutlinedButton), matching: find.byType(Opacity)).first)
        .opacity;
    expect(opacity, 1);
  });

  testWidgets('a reader opened in reading mode starts without its bars', (tester) async {
    when(() => repository.load()).thenReturn(const AppSettings(readingMode: true));
    await pumpReader(tester);
    expect(find.byKey(_topBarKey), findsNothing);
    expect(find.byKey(ReadingModeExitButton.exitKey), findsOneWidget);
  });

  group('the choice', () {
    test('off by default, and not one of the synced fields', () {
      expect(const AppSettings().readingMode, isFalse);
      expect(const AppSettings(readingMode: true).syncedFieldsDiffer(const AppSettings()), isFalse);
    });

    test('kept on this device, never sent to the account, even signed in', () async {
      final cubit = settings();
      await cubit.onSessionChanged(const Me(id: 'u1', displayName: 'Reader One', username: 'reader1', onboardingCompleted: true));
      clearInteractions(repository);

      expect(await cubit.setReadingMode(true), isNull);
      expect(cubit.state.readingMode, isTrue);
      verify(() => repository.save(any(that: isA<AppSettings>().having((s) => s.readingMode, 'readingMode', true)))).called(1);
      verifyNever(() => repository.pushPreferences(any()));
    });

    test('stored with the other settings', () async {
      final store = InMemoryKeyValueStore();
      final local = SettingsLocalDataSource(store);
      expect(local.read().readingMode, isFalse);
      await local.write(const AppSettings(readingMode: true));
      expect(store.read<bool>('settings.readingMode'), isTrue);
      expect(local.read().readingMode, isTrue);
    });
  });
}

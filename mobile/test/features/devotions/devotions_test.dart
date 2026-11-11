import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/devotions/data/datasources/devotions_assets.dart';
import 'package:readin/features/devotions/domain/entities/devotions.dart';
import 'package:readin/features/devotions/domain/usecases/devotion_usecases.dart';
import 'package:readin/features/devotions/presentation/cubit/devotions_cubits.dart';
import 'package:readin/features/devotions/presentation/pages/adhkar_page.dart';
import 'package:readin/features/devotions/presentation/pages/duas_page.dart';
import 'package:readin/features/devotions/presentation/pages/surah_page.dart';
import 'package:readin/features/devotions/presentation/widgets/devotions_widgets.dart';

import '../../helpers/devotions_fakes.dart';
import '../../helpers/test_app.dart';

/// Ayah 1 without the basmala, as Tanzil writes it (escaped: an editor may reorder the marks of typed Arabic).
const _yasin1 = 'يسٓ'; // يسٓ
const _waqiah1 =
    'إِذَا وَقَعَتِ '
    'ٱلْوَاقِعَةُ'; // إِذَا وَقَعَتِ ٱلْوَاقِعَةُ

/// The private corner (F38): the bundled texts, the counters, the text size and the du'as.
void main() {
  setUpAll(FakeDevotionsRepository.preload);

  group('the bundled texts', () {
    final assets = DevotionsAssets();

    test("Ya-Sin and Al-Waqi'ah are whole, the basmala opening each", () async {
      final yasin = await assets.surah(36);
      expect(yasin.name, 'يس');
      expect(yasin.ayat, hasLength(83));
      expect(yasin.opening, Surah.basmala);
      expect(yasin.ayahText(1), _yasin1);
      expect(yasin.ayahText(2), yasin.ayat[1]);
      expect(yasin.source, 'Tanzil Quran Text (Uthmani, Version 1.1)');

      final waqiah = await assets.surah(56);
      expect(waqiah.name, 'الواقعة');
      expect(waqiah.ayat, hasLength(96));
      expect(waqiah.opening, Surah.basmala);
      expect(waqiah.ayahText(1), _waqiah1);
    });

    test("the adhkar are Hisn al-Muslim's 24, each in its session, with the text's counts", () async {
      final book = await assets.adhkar();
      expect(book.items, hasLength(24));
      expect(book.items.map((d) => d.id), [for (var id = 75; id <= 98; id++) id]);
      final morning = book.forSession(AdhkarSession.morning).map((d) => d.id);
      final evening = book.forSession(AdhkarSession.evening).map((d) => d.id);
      expect(morning, hasLength(23));
      expect(morning, isNot(contains(97)));
      expect(evening, hasLength(21));
      expect(evening, isNot(anyOf(contains(93), contains(94), contains(95))));
      final repeat = {for (final d in book.items) d.id: d.repeat};
      expect(repeat[83], 7, reason: '(سَبْعَ مَرّاتٍ)');
      expect(repeat[76], 3);
      expect(repeat[91], 100);
    });

    test('ayah numbers use Arabic-Indic digits', () {
      expect(arabicIndicDigits(7), '٧');
      expect(arabicIndicDigits(83), '٨٣');
      expect(arabicIndicDigits(100), '١٠٠');
    });
  });

  group('AdhkarCubit', () {
    test('a tap counts one repetition down to zero, then nothing; reset starts over', () async {
      final cubit = AdhkarCubit(GetAdhkar(FakeDevotionsRepository()));
      addTearDown(cubit.close);
      await cubit.load(AdhkarSession.evening);
      final dhikr = cubit.state.items.firstWhere((d) => d.id == 97); // 3 times, evening only
      for (var i = 0; i < 4; i++) {
        cubit.count(dhikr);
      }
      expect(cubit.state.left(dhikr), 0);
      expect(cubit.state.done(dhikr), isTrue);
      expect(cubit.state.doneCount, 1);

      cubit.reset();
      expect(cubit.state.left(dhikr), 3);
      expect(cubit.state.doneCount, 0);
    });
  });

  group('DevotionsTextSizeCubit', () {
    test('steps by 10 % between 80 % and 180 %, kept on the device', () async {
      final store = InMemoryKeyValueStore();
      final cubit = DevotionsTextSizeCubit(store);
      addTearDown(cubit.close);
      expect(cubit.state, 1);
      await cubit.grow();
      expect(cubit.state, 1.1);
      expect(DevotionsTextSizeCubit(store).state, 1.1);
      for (var i = 0; i < 20; i++) {
        await cubit.shrink();
      }
      expect(cubit.state, DevotionsTextSizeCubit.min);
      expect(cubit.canShrink, isFalse);
    });
  });

  group('DuasCubit', () {
    late FakeDevotionsRepository repository;
    late DuasCubit cubit;

    setUp(() {
      repository = FakeDevotionsRepository(duas: [FakeDevotionsRepository.dua('d-1', 'اللهم اغفر لي')]);
      cubit = DuasCubit(GetDuas(repository), SaveDua(repository), DeleteDua(repository));
      addTearDown(cubit.close);
    });

    test('adds last, replaces in place, deletes', () async {
      await cubit.load();
      expect(await cubit.save(const DuaDraft(text: 'رب زدني علما', title: 'العلم')), isNull);
      expect(cubit.state.items.map((d) => d.text), ['اللهم اغفر لي', 'رب زدني علما']);

      expect(await cubit.save(const DuaDraft(text: 'اللهم اغفر لي ولوالدي'), id: 'd-1'), isNull);
      expect(cubit.state.items.first.text, 'اللهم اغفر لي ولوالدي');

      expect(await cubit.delete('d-1'), isNull);
      expect(cubit.state.items.map((d) => d.text), ['رب زدني علما']);
      expect(cubit.state.busy, isFalse);
    });

    test("a failed save says why and keeps the list; a du'a already gone just leaves it", () async {
      await cubit.load();
      repository.failNext = FailureCodes.duaLimit;
      expect((await cubit.save(const DuaDraft(text: 'دعاء')))?.code, FailureCodes.duaLimit);
      expect(cubit.state.items, hasLength(1));

      repository.failNext = FailureCodes.duaNotFound;
      expect(await cubit.delete('d-1'), isNull);
      expect(cubit.state.items, isEmpty);
    });
  });

  group('pages', () {
    testWidgets('a surah opens with its basmala, then the ayat with their marks, then the source', (tester) async {
      usePhoneSurface(tester);
      final textSize = DevotionsTextSizeCubit(InMemoryKeyValueStore());
      await tester.pumpWidget(
        testApp(SurahPage(number: 36, cubit: SurahCubit(GetSurah(FakeDevotionsRepository())), textSize: textSize)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('surah-opening')), findsOneWidget);
      final ayat = tester.widget<RichText>(
        find.descendant(of: find.byKey(const ValueKey('surah-ayat')), matching: find.byType(RichText)),
      );
      final text = ayat.text.toPlainText();
      expect(text, startsWith('$_yasin1 ۝١ '));
      expect(text, contains('۝٨٣'));
      expect(text, isNot(contains(Surah.basmala)));

      await tester.tap(find.byKey(const ValueKey('devotions-text-larger')));
      await tester.pump();
      expect(textSize.state, 1.1);
    });

    testWidgets('an adhkar card counts down on a tap and says done at zero', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        testApp(
          AdhkarPage(
            session: AdhkarSession.morning,
            cubit: AdhkarCubit(GetAdhkar(FakeDevotionsRepository())),
            textSize: DevotionsTextSizeCubit(InMemoryKeyValueStore()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ayatAlKursi = find.byKey(const ValueKey('dhikr-75')); // once
      expect(find.descendant(of: ayatAlKursi, matching: find.text('المتبقي: ١ من ١')), findsOneWidget);
      await tester.tap(ayatAlKursi);
      await tester.pumpAndSettle();
      expect(find.descendant(of: ayatAlKursi, matching: find.text('تم')), findsOneWidget);
      expect(find.byKey(const ValueKey('dhikr-97')), findsNothing, reason: 'evening only');
    });

    testWidgets("adding, editing and deleting a du'a", (tester) async {
      usePhoneSurface(tester);
      final repository = FakeDevotionsRepository();
      await tester.pumpWidget(
        testApp(DuasPage(cubit: DuasCubit(GetDuas(repository), SaveDua(repository), DeleteDua(repository)))),
      );
      await tester.pumpAndSettle();
      expect(find.text('لا توجد أدعية بعد'), findsOneWidget);

      // An empty du'a isn't sent.
      await tester.tap(find.byKey(const ValueKey('duas-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dua-save')));
      await tester.pumpAndSettle();
      expect(repository.items, isEmpty);

      await tester.enterText(find.byKey(const ValueKey('dua-title')), '  دعاء   السفر ');
      await tester.enterText(find.byKey(const ValueKey('dua-text')), ' اللهم أنت الصاحب في السفر\nوالخليفة في الأهل ');
      await tester.tap(find.byKey(const ValueKey('dua-save')));
      await tester.pumpAndSettle();
      expect(repository.items.single.title, 'دعاء السفر');
      expect(repository.items.single.text, 'اللهم أنت الصاحب في السفر\nوالخليفة في الأهل');
      expect(find.text('دعاء السفر'), findsOneWidget);

      final id = repository.items.single.id;
      await tester.tap(find.byKey(ValueKey('dua-menu-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dua-edit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('dua-title')), '');
      await tester.enterText(find.byKey(const ValueKey('dua-repeat')), '٣');
      await tester.tap(find.byKey(const ValueKey('dua-save')));
      await tester.pumpAndSettle();
      expect(repository.items.single.title, isNull);
      expect(repository.items.single.repeat, 3, reason: 'typed in Arabic-Indic digits');

      // It counts down like the adhkar: «المتبقي: ٣ من ٣», a tap a time, then done.
      final card = find.byKey(ValueKey('dua-count-$id'));
      expect(find.descendant(of: card, matching: find.text('المتبقي: ٣ من ٣')), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(card);
        await tester.pumpAndSettle();
      }
      expect(find.descendant(of: card, matching: find.text('تم')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('duas-reset')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: card, matching: find.text('المتبقي: ٣ من ٣')), findsOneWidget);

      await tester.tap(find.byKey(ValueKey('dua-menu-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dua-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dua-delete-confirm')));
      await tester.pumpAndSettle();
      expect(repository.items, isEmpty);
      expect(find.text('لا توجد أدعية بعد'), findsOneWidget);
    });
  });
}

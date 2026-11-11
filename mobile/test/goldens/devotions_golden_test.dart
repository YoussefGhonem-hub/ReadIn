@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/devotions/domain/entities/devotions.dart';
import 'package:readin/features/devotions/domain/usecases/devotion_usecases.dart';
import 'package:readin/features/devotions/presentation/cubit/devotions_cubits.dart';
import 'package:readin/features/devotions/presentation/pages/adhkar_page.dart';
import 'package:readin/features/devotions/presentation/pages/devotions_page.dart';
import 'package:readin/features/devotions/presentation/pages/duas_page.dart';
import 'package:readin/features/devotions/presentation/pages/surah_page.dart';

import '../helpers/devotions_fakes.dart';
import '../helpers/test_app.dart';

/// The private corner (F38) in ar/light and en/dark (SPEC §27): its cards, Ya-Sin's opening, the morning adhkar with
/// one done, and the du'as.
void main() {
  setUpAll(FakeDevotionsRepository.preload);

  for (final variant in Variant.golden) {
    testWidgets('devotions ${variant.name}', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(const DevotionsPage(), variant: variant));
      await expectLater(
        find.byType(DevotionsPage),
        matchesVariantGolden(variant, 'goldens/devotions_${variant.name}.png'),
      );
    });

    testWidgets('surah ${variant.name}', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        testApp(
          SurahPage(
            number: 36,
            cubit: SurahCubit(GetSurah(FakeDevotionsRepository())),
            textSize: DevotionsTextSizeCubit(InMemoryKeyValueStore()),
          ),
          variant: variant,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SurahPage),
        matchesVariantGolden(variant, 'goldens/devotions_surah_${variant.name}.png'),
      );
    });

    testWidgets('adhkar ${variant.name}', (tester) async {
      usePhoneSurface(tester);
      final cubit = AdhkarCubit(GetAdhkar(FakeDevotionsRepository()));
      await tester.pumpWidget(
        testApp(
          AdhkarPage(
            session: AdhkarSession.morning,
            cubit: cubit,
            textSize: DevotionsTextSizeCubit(InMemoryKeyValueStore()),
          ),
          variant: variant,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dhikr-75')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AdhkarPage),
        matchesVariantGolden(variant, 'goldens/devotions_adhkar_${variant.name}.png'),
      );
    });

    testWidgets('duas ${variant.name}', (tester) async {
      usePhoneSurface(tester);
      final repository = FakeDevotionsRepository(
        duas: [
          FakeDevotionsRepository.dua(
            'd-1',
            'اللهم إني أسألك علمًا نافعًا،\nورزقًا طيبًا، وعملًا متقبلًا.',
            title: 'دعاء الصباح',
          ),
          FakeDevotionsRepository.dua('d-2', 'رب اشرح لي صدري، ويسر لي أمري.'),
        ],
      );
      await tester.pumpWidget(
        testApp(
          DuasPage(cubit: DuasCubit(GetDuas(repository), SaveDua(repository), DeleteDua(repository))),
          variant: variant,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DuasPage),
        matchesVariantGolden(variant, 'goldens/devotions_duas_${variant.name}.png'),
      );
    });
  }
}

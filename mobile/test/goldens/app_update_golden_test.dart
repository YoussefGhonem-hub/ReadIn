@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/app_update/domain/entities/update_policy.dart';
import 'package:readin/features/app_update/presentation/pages/update_required_page.dart';

import '../helpers/app_update_fakes.dart';
import '../helpers/test_app.dart';

/// The forced update page in ar/light and en/dark (SPEC §27): with "Update now" (Android, or iOS with a store page),
/// and the text alone (iOS without one).
void main() {
  for (final variant in Variant.golden) {
    testWidgets('update required ${variant.name}', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(
        const UpdateRequiredPage(requirement: UpdateRequirement(storeUrl: playStoreUrl)),
        variant: variant,
      ));
      await expectLater(
        find.byType(UpdateRequiredPage),
        matchesVariantGolden(variant, 'goldens/update_required_${variant.name}.png'),
      );
    });

    testWidgets('update required without a store page ${variant.name}', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(const UpdateRequiredPage(requirement: UpdateRequirement()), variant: variant));
      await expectLater(
        find.byType(UpdateRequiredPage),
        matchesVariantGolden(variant, 'goldens/update_required_no_store_${variant.name}.png'),
      );
    });
  }
}

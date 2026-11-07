import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/app_update/domain/entities/update_policy.dart';
import 'package:readin/features/app_update/presentation/pages/update_required_page.dart';
import 'package:readin/features/app_update/presentation/widgets/update_motion.dart';

import '../../helpers/app_update_fakes.dart';
import '../../helpers/test_app.dart';

/// The motion of "Update ReadIn": the text and the button rise in after the picture pops in, the picture keeps moving,
/// and reduce motion keeps everything still. The rest of the suite sees the page at rest (flutter_test_config.dart).
void main() {
  const variant = Variant(AppLocales.en, Brightness.light);

  setUp(() => UpdateMotion.enabled = true);
  tearDown(() => UpdateMotion.enabled = false);

  Future<FakeStoreLauncher> pump(WidgetTester tester) async {
    usePhoneSurface(tester);
    final launcher = FakeStoreLauncher();
    await tester.pumpWidget(testApp(
      UpdateRequiredPage(requirement: const UpdateRequirement(storeUrl: playStoreUrl), launchStore: launcher.call),
      variant: variant,
    ));
    return launcher;
  }

  /// The opacity of the piece of the page that holds [text].
  double opacityOf(WidgetTester tester, String text) =>
      tester.widget<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first).opacity;

  testWidgets('the text and the button rise in one after the other, then rest while the picture keeps moving',
      (tester) async {
    await pump(tester);
    final l10n = lookupAppLocalizations(variant.locale);
    expect(opacityOf(tester, l10n.updateRequiredTitle), 0);

    await tester.pump(const Duration(milliseconds: 700));
    final title = opacityOf(tester, l10n.updateRequiredTitle);
    expect(title, greaterThan(0));
    expect(opacityOf(tester, l10n.updateRequiredAction), lessThan(title), reason: 'the button rises after the title');

    await tester.pump(const Duration(seconds: 2));
    expect(opacityOf(tester, l10n.updateRequiredTitle), 1);
    expect(opacityOf(tester, l10n.updateRequiredBody), 1);
    expect(opacityOf(tester, l10n.updateRequiredAction), 1);

    await tester.pump(const Duration(seconds: 5));
    expect(tester.hasRunningAnimations, isTrue, reason: 'the download keeps filling and the button keeps shining');
  });

  testWidgets('"Update now" still opens the store while everything moves', (tester) async {
    final launcher = await pump(tester);
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 200));

    expect(launcher.opened, [Uri.parse(playStoreUrl)]);
  });

  testWidgets('with reduce motion everything rests in place and nothing ticks', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pump(tester);
    final l10n = lookupAppLocalizations(variant.locale);

    expect(opacityOf(tester, l10n.updateRequiredTitle), 1);
    expect(opacityOf(tester, l10n.updateRequiredAction), 1);
    expect(find.byType(UpdateHero), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}

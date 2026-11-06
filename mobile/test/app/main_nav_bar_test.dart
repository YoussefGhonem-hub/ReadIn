import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/app/main_nav_bar.dart';
import 'package:readin/core/l10n/l10n_x.dart';

import '../helpers/test_app.dart';

void main() {
  const pageKey = Key('page');

  /// The bar under a page that records its own taps; returns what the bar asked for: a branch, or `more`.
  Future<List<Object>> pump(WidgetTester tester, Variant variant, {int current = 0, List<String>? pageTaps}) async {
    usePhoneSurface(tester);
    final pressed = <Object>[];
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: GestureDetector(
            key: pageKey,
            behavior: HitTestBehavior.opaque,
            onTap: () => pageTaps?.add('page'),
            child: const SizedBox.expand(),
          ),
          bottomNavigationBar: MainNavBar(
            currentIndex: current,
            onSelect: pressed.add,
            onMore: () => pressed.add('more'),
          ),
        ),
        variant: variant,
      ),
    );
    await tester.pumpAndSettle();
    return pressed;
  }

  Finder named(String label) => find.bySemanticsLabel(label);

  for (final variant in Variant.all) {
    group(variant.name, () {
      final l10n = lookupAppLocalizations(variant.locale);
      final icons = [l10n.navExplore, l10n.navWrite, l10n.navSaved, l10n.navMore];

      testWidgets('icons only: four named icons and, in the middle, the ReadIn mark as Home', (tester) async {
        final semantics = tester.ensureSemantics();
        await pump(tester, variant);

        for (final name in [...icons, l10n.navHome, l10n.navProfile]) {
          expect(find.text(name), findsNothing, reason: 'no text in the bar: $name');
        }
        for (final name in icons) {
          expect(named(name), findsOneWidget, reason: name);
        }
        expect(named(l10n.navHome), findsOneWidget);
        expect(named(l10n.navProfile), findsNothing, reason: 'Profile opens from More');
        final screen = tester.getSize(find.byType(Scaffold)).width;
        expect(tester.getCenter(named(l10n.navHome)).dx, moreOrLessEquals(screen / 2, epsilon: 0.5));
        semantics.dispose();
      });

      testWidgets('the mark opens Home, the icons their branch, More the More sheet', (tester) async {
        final semantics = tester.ensureSemantics();
        final pressed = await pump(tester, variant, current: 3);

        for (final name in [l10n.navHome, ...icons]) {
          await tester.tap(named(name));
        }

        expect(pressed, [0, 1, 2, 3, 'more']);
        semantics.dispose();
      });

      testWidgets('tells screen readers which one is open; More counts as open on Profile', (tester) async {
        final semantics = tester.ensureSemantics();
        await pump(tester, variant, current: 0);
        expect(
          tester.getSemantics(named(l10n.navHome)),
          isSemantics(label: l10n.navHome, isButton: true, isSelected: true, hasTapAction: true),
        );
        expect(
          tester.getSemantics(named(l10n.navSaved)),
          isSemantics(isButton: true, isSelected: false, hasTapAction: true),
        );

        await pump(tester, variant, current: 3);
        expect(tester.getSemantics(named(l10n.navHome)), isSemantics(isSelected: false));
        expect(tester.getSemantics(named(l10n.navSaved)), isSemantics(isSelected: true));
        expect(tester.getSemantics(named(l10n.navMore)), isSemantics(isSelected: false));

        await pump(tester, variant, current: MainNavBar.profileBranch);
        expect(tester.getSemantics(named(l10n.navMore)), isSemantics(isSelected: true));
        semantics.dispose();
      });
    });
  }

  testWidgets('a long press shows the icon\'s name', (tester) async {
    final semantics = tester.ensureSemantics();
    final l10n = lookupAppLocalizations(AppLocales.ar);
    await pump(tester, const Variant(AppLocales.ar, Brightness.light));
    await tester.longPress(named(l10n.navSaved));
    await tester.pumpAndSettle();
    expect(find.text(l10n.navSaved), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('in Arabic Explore and Write are on the right of the mark; in English on the left', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final variant in [
      const Variant(AppLocales.ar, Brightness.light),
      const Variant(AppLocales.en, Brightness.light),
    ]) {
      final l10n = lookupAppLocalizations(variant.locale);
      await pump(tester, variant);
      final x = {
        for (final name in [l10n.navExplore, l10n.navWrite, l10n.navSaved, l10n.navMore])
          name: tester.getCenter(named(name)).dx,
      };
      final middle = tester.getCenter(named(l10n.navHome)).dx;
      if (variant.locale == AppLocales.ar) {
        expect(x[l10n.navExplore]! > x[l10n.navWrite]!, isTrue);
        expect(x[l10n.navWrite]! > middle && middle > x[l10n.navSaved]!, isTrue);
        expect(x[l10n.navSaved]! > x[l10n.navMore]!, isTrue);
      } else {
        expect(x[l10n.navExplore]! < x[l10n.navWrite]!, isTrue);
        expect(x[l10n.navWrite]! < middle && middle < x[l10n.navSaved]!, isTrue);
        expect(x[l10n.navSaved]! < x[l10n.navMore]!, isTrue);
      }
    }
    semantics.dispose();
  });

  testWidgets('the page keeps all the room above the bar; the mark rises over its end and takes taps there', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final pageTaps = <String>[];
    final pressed = await pump(tester, const Variant(AppLocales.en, Brightness.light), pageTaps: pageTaps);
    final l10n = lookupAppLocalizations(AppLocales.en);

    final page = tester.getRect(find.byKey(pageKey));
    expect(page.bottom, 844 - MainNavBar.barHeight);
    final markRect = tester.getRect(named(l10n.navHome));
    expect(markRect.top, lessThan(page.bottom - 20), reason: 'the mark rises above the bar');

    // The mark's top, over the page: the mark takes it.
    await tester.tapAt(Offset(markRect.center.dx, markRect.top + 6));
    expect(pressed, [0]);
    expect(pageTaps, isEmpty);

    // Beside the mark, at the same height: the page shows there and takes the tap.
    await tester.tapAt(Offset(40, markRect.top + 6));
    expect(pageTaps, ['page']);
    expect(pressed, [0]);
    semantics.dispose();
  });
}

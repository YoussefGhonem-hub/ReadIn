import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/app/main_nav_bar.dart';
import 'package:readin/core/l10n/l10n_x.dart';

import '../helpers/test_app.dart';

void main() {
  const pageKey = Key('page');

  /// The bar under a page that records its own taps; returns the branches the bar asked for.
  Future<List<int>> pump(WidgetTester tester, Variant variant, {int current = 0, List<String>? pageTaps}) async {
    usePhoneSurface(tester);
    final selected = <int>[];
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: GestureDetector(
            key: pageKey,
            behavior: HitTestBehavior.opaque,
            onTap: () => pageTaps?.add('page'),
            child: const SizedBox.expand(),
          ),
          bottomNavigationBar: MainNavBar(currentIndex: current, onSelect: selected.add),
        ),
        variant: variant,
      ),
    );
    await tester.pumpAndSettle();
    return selected;
  }

  Finder mark(AppLocalizations l10n) => find.bySemanticsLabel(l10n.navHome);

  for (final variant in Variant.all) {
    group(variant.name, () {
      final l10n = lookupAppLocalizations(variant.locale);

      testWidgets('four named tabs and, in the middle, the ReadIn mark as Home with no "Today" label', (tester) async {
        final semantics = tester.ensureSemantics();
        await pump(tester, variant);

        for (final name in [l10n.navExplore, l10n.navWrite, l10n.navSaved, l10n.navProfile]) {
          expect(find.text(name), findsOneWidget);
        }
        expect(find.text(l10n.navHome), findsNothing);
        expect(mark(l10n), findsOneWidget);
        final screen = tester.getSize(find.byType(Scaffold)).width;
        expect(tester.getCenter(mark(l10n)).dx, moreOrLessEquals(screen / 2, epsilon: 0.5));
        semantics.dispose();
      });

      testWidgets('the mark opens Home and each tab its own branch', (tester) async {
        final semantics = tester.ensureSemantics();
        final selected = await pump(tester, variant, current: 3);

        await tester.tap(mark(l10n));
        await tester.tap(find.text(l10n.navExplore));
        await tester.tap(find.text(l10n.navWrite));
        await tester.tap(find.text(l10n.navSaved));
        await tester.tap(find.text(l10n.navProfile));

        expect(selected, [0, 1, 2, 3, 4]);
        semantics.dispose();
      });

      testWidgets('tells screen readers which one is open', (tester) async {
        final semantics = tester.ensureSemantics();
        await pump(tester, variant, current: 0);
        expect(
          tester.getSemantics(mark(l10n)),
          matchesSemantics(
            label: l10n.navHome,
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );
        expect(
          tester.getSemantics(find.text(l10n.navSaved)),
          matchesSemantics(
            label: l10n.navSaved,
            isButton: true,
            hasSelectedState: true,
            hasTapAction: true,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );

        await pump(tester, variant, current: 3);
        expect(
          tester.getSemantics(mark(l10n)),
          matchesSemantics(
            label: l10n.navHome,
            isButton: true,
            hasSelectedState: true,
            hasTapAction: true,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );
        expect(
          tester.getSemantics(find.text(l10n.navSaved)),
          matchesSemantics(
            label: l10n.navSaved,
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );
        semantics.dispose();
      });
    });
  }

  testWidgets('in Arabic Explore and Write are on the right of the mark; in English on the left', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final variant in [
      const Variant(AppLocales.ar, Brightness.light),
      const Variant(AppLocales.en, Brightness.light),
    ]) {
      final l10n = lookupAppLocalizations(variant.locale);
      await pump(tester, variant);
      final x = {
        for (final name in [l10n.navExplore, l10n.navWrite, l10n.navSaved, l10n.navProfile])
          name: tester.getCenter(find.text(name)).dx,
      };
      final middle = tester.getCenter(mark(l10n)).dx;
      if (variant.locale == AppLocales.ar) {
        expect(x[l10n.navExplore]! > x[l10n.navWrite]!, isTrue);
        expect(x[l10n.navWrite]! > middle && middle > x[l10n.navSaved]!, isTrue);
        expect(x[l10n.navSaved]! > x[l10n.navProfile]!, isTrue);
      } else {
        expect(x[l10n.navExplore]! < x[l10n.navWrite]!, isTrue);
        expect(x[l10n.navWrite]! < middle && middle < x[l10n.navSaved]!, isTrue);
        expect(x[l10n.navSaved]! < x[l10n.navProfile]!, isTrue);
      }
    }
    semantics.dispose();
  });

  testWidgets('the page keeps all the room above the bar; the mark rises over its end and takes taps there', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final pageTaps = <String>[];
    final selected = await pump(tester, const Variant(AppLocales.en, Brightness.light), pageTaps: pageTaps);
    final l10n = lookupAppLocalizations(AppLocales.en);

    final page = tester.getRect(find.byKey(pageKey));
    expect(page.bottom, 844 - MainNavBar.barHeight);
    final markRect = tester.getRect(mark(l10n));
    expect(markRect.top, lessThan(page.bottom - 20), reason: 'the mark rises above the bar');

    // The mark's top, over the page: the mark takes it.
    await tester.tapAt(Offset(markRect.center.dx, markRect.top + 6));
    expect(selected, [0]);
    expect(pageTaps, isEmpty);

    // Beside the mark, at the same height: the page shows there and takes the tap.
    await tester.tapAt(Offset(40, markRect.top + 6));
    expect(pageTaps, ['page']);
    expect(selected, [0]);
    semantics.dispose();
  });
}

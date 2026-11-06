@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/app/main_nav_bar.dart';
import 'package:readin/core/theme/theme_x.dart';
import 'package:readin/core/theme/tokens.g.dart';

import '../helpers/test_app.dart';

/// The bottom bar in ar/light and en/dark (SPEC §27), with Home open (the ring round the mark) and with Saved open, over
/// the end of a page so the mark is seen rising over it.
void main() {
  for (final variant in Variant.golden) {
    for (final (name, branch) in [('home', 0), ('saved', 3)]) {
      testWidgets('main nav bar, $name open, ${variant.name}', (tester) async {
        usePhoneSurface(tester, size: const Size(390, 220));
        await tester.pumpWidget(
          testApp(
            Scaffold(
              body: const _PageEnd(),
              bottomNavigationBar: MainNavBar(currentIndex: branch, onSelect: (_) {}),
            ),
            variant: variant,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/main_nav_bar_${name}_${variant.name}.png'));
      });
    }
  }
}

/// The last card of a feed on the grey canvas.
class _PageEnd extends StatelessWidget {
  const _PageEnd();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.bg,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 110,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 12, width: 220, decoration: _bar(colors)),
              const SizedBox(height: 10),
              Container(height: 12, width: 300, decoration: _bar(colors)),
              const SizedBox(height: 10),
              Container(height: 12, width: 160, decoration: _bar(colors)),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _bar(ReadInColors colors) =>
      BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(ReadInRadius.sm));
}

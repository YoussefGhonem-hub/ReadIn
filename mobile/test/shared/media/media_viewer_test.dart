import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/shared/media/media_item.dart';
import 'package:readin/shared/media/media_viewer.dart';

import '../../helpers/fake_media.dart';
import '../../helpers/test_app.dart';

List<MediaItem> _pages(int n) => [
      for (var i = 1; i <= n; i++)
        MediaItem(
          sources: [
            ImageSource(width: 400, height: 566, url: 'https://cdn.test/page-$i-400.webp'),
            ImageSource(width: 1080, height: 1528, url: 'https://cdn.test/page-$i-1080.webp'),
          ],
          width: 1080,
          height: 1528,
        ),
    ];

/// A page with a button that opens the viewer, like the feed card does.
Widget _launcher({int total = 3}) => testApp(
      Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => MediaViewerPage.open(
                context,
                (_) => MediaViewerPage(items: _pages(total), kind: MediaViewerKind.document, title: 'Slides'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      variant: const Variant(AppLocales.en, Brightness.light),
    );

double _scale(WidgetTester tester) =>
    tester.widget<InteractiveViewer>(find.byType(InteractiveViewer).first).transformationController!.value.getMaxScaleOnAxis();

Future<void> _doubleTap(WidgetTester tester) async {
  final center = tester.getCenter(find.byType(InteractiveViewer).first);
  await tester.tapAt(center);
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tapAt(center);
}

void main() {
  setUpAll(FakeMedia.install);

  Future<void> open(WidgetTester tester, {bool reduceMotion = false}) async {
    usePhoneSurface(tester);
    if (reduceMotion) {
      // The OS "reduce motion" setting, as MaterialApp's MediaQuery reads it.
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    }
    await tester.pumpWidget(_launcher());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(MediaViewerPage), findsOneWidget);
  }

  testWidgets('double tap zooms in and out', (tester) async {
    await open(tester);
    expect(_scale(tester), 1);

    await _doubleTap(tester);
    await tester.pumpAndSettle();
    expect(_scale(tester), closeTo(MediaViewerPage.doubleTapScale, 0.01));

    await _doubleTap(tester);
    await tester.pumpAndSettle();
    expect(_scale(tester), closeTo(1, 0.01));
  });

  testWidgets('reduce motion: double tap zooms without animating', (tester) async {
    await open(tester, reduceMotion: true);
    await _doubleTap(tester);
    await tester.pump();
    expect(_scale(tester), closeTo(MediaViewerPage.doubleTapScale, 0.01), reason: 'applied on the very next frame');
    await tester.pumpAndSettle();
  });

  testWidgets('closes with ✕', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('viewer-close')));
    await tester.pumpAndSettle();
    expect(find.byType(MediaViewerPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('closes with the system back button', (tester) async {
    await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MediaViewerPage), findsNothing);
  });

  testWidgets('closes with a swipe down', (tester) async {
    await open(tester);
    await tester.drag(find.byType(PageView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.byType(MediaViewerPage), findsNothing);
  });

  testWidgets('pages, counter, thumbnail strip and semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Page 1 of 3'), findsWidgets);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    // Jump with the thumbnail strip.
    await tester.tap(find.bySemanticsLabel('Page 3 of 3').last);
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    semantics.dispose();
  });
}

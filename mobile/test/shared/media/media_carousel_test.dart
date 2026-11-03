import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/shared/media/media_carousel.dart';
import 'package:readin/shared/media/media_image.dart';
import 'package:readin/shared/media/media_item.dart';

import '../../helpers/fake_media.dart';
import '../../helpers/test_app.dart';

const _width = 390.0;

List<MediaItem> _items(int n) => [
      for (var i = 0; i < n; i++)
        MediaItem(
          sources: [ImageSource(width: 640, height: 640, url: 'https://cdn.test/photo-$i.webp')],
          width: 640,
          height: 640,
          caption: i == 0 ? 'Program.cs' : null,
          altText: 'alt $i',
        ),
    ];

Widget _host({required Variant variant, ValueChanged<int>? onTap, int count = 3}) => testApp(
      Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: _width,
            child: Builder(
              builder: (context) => MediaCarousel(
                items: _items(count),
                aspectRatio: 1,
                semanticLabel: (i, total) => imageSlideLabel(context, i, total),
                onTap: onTap,
              ),
            ),
          ),
        ),
      ),
      variant: variant,
    );

Finder _slide(int i) => find.byKey(ValueKey('carousel-slide-$i'));

void main() {
  setUpAll(FakeMedia.install);

  const en = Variant(AppLocales.en, Brightness.light);
  const ar = Variant(AppLocales.ar, Brightness.light);

  testWidgets('swiping changes the counter (LTR)', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(_host(variant: en));
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('1 / 3'), findsNothing, reason: 'only the current slide shows the counter');

    await tester.drag(find.byType(PageView), const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('the next slide peeks ~15% from the trailing edge', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(_host(variant: en));
    final carousel = tester.getRect(find.byType(MediaCarousel));
    final first = tester.getRect(_slide(0));
    final next = tester.getRect(_slide(1));
    expect(first.left, carousel.left);
    expect(next.left, closeTo(carousel.left + _width * MediaCarousel.defaultViewportFraction, 0.5));
    final peek = carousel.right - next.left;
    expect(peek / _width, closeTo(0.15, 0.01));
  });

  testWidgets('RTL: starts from the right and swipes follow the UI direction', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(_host(variant: ar));
    final carousel = tester.getRect(find.byType(MediaCarousel));
    final first = tester.getRect(_slide(0));
    final next = tester.getRect(_slide(1));
    expect(first.right, carousel.right, reason: 'first slide hugs the right edge');
    expect(next.right, lessThan(first.left + 1), reason: 'the next slide peeks on the left');
    expect(carousel.left, lessThan(next.right));

    // Swiping towards the right moves forward in Arabic.
    await tester.drag(find.byType(PageView), const Offset(250, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('slides are tappable and labelled for screen readers', (tester) async {
    usePhoneSurface(tester);
    final taps = <int>[];
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(variant: en, onTap: taps.add));
    await tester.tap(_slide(0));
    expect(taps, [0]);
    expect(find.bySemanticsLabel('Image 1 of 3. alt 0'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('only slides next to the current one load images', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(testApp(
      Scaffold(
        body: SizedBox(
          width: _width,
          child: Builder(
            builder: (context) => MediaCarousel(
              items: _items(5),
              aspectRatio: 1,
              viewportFraction: 0.3,
              semanticLabel: (i, total) => imageSlideLabel(context, i, total),
            ),
          ),
        ),
      ),
      variant: en,
    ));
    MediaImage image(int i) => tester.widget<MediaImage>(find.descendant(of: _slide(i), matching: find.byType(MediaImage)));
    expect([image(0).load, image(1).load, image(2).load], [true, true, false]);
  });
}

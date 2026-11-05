import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/platform/share_service.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/article/domain/usecases/get_article.dart';
import 'package:readin/features/article/presentation/cubit/attachment_viewer_cubit.dart';
import 'package:readin/features/article/presentation/widgets/article_attachments_view.dart';
import 'package:readin/features/media/domain/usecases/media_usecases.dart';
import 'package:readin/shared/media/media_viewer.dart';

import '../../helpers/fake_media.dart';
import '../../helpers/media_fixtures.dart';

class _MockGetArticle extends Mock implements GetArticle {}

class _MockDownload extends Mock implements DownloadDocument {}

class _MockShare extends Mock implements ShareService {}

/// SPEC F26, pre-production step H: closing the full-screen viewer returns to the same place in the feed and the same
/// focus. Reproduced the way the app is built: the feed in a branch of a `StatefulShellRoute` (its own navigator), the
/// viewer pushed on the root navigator above it, closed with ✕, the system back (Android button / gesture, through
/// go_router's back dispatcher) and a swipe down.
void main() {
  setUpAll(FakeMedia.install);

  setUp(() {
    getIt.registerFactory<AttachmentViewerCubit>(() => AttachmentViewerCubit(_MockGetArticle(), _MockDownload(), _MockShare()));
  });

  tearDown(getIt.reset);

  const itemCount = 14;
  const target = 9;

  Key itemKey(int i) => ValueKey('feed-item-$i');

  /// The feed tab: cards with an image each, far more than a screen.
  Widget feed() => CustomScrollView(
        slivers: [
          SliverList.builder(
            itemCount: itemCount,
            itemBuilder: (context, i) => Padding(
              key: itemKey(i),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Post $i'),
                  const SizedBox(height: 8),
                  ArticleAttachmentsView(article: cardWithImages(1, language: 'en')),
                ],
              ),
            ),
          ),
        ],
      );

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => Scaffold(body: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => feed())]),
            StatefulShellBranch(routes: [GoRoute(path: '/other', builder: (_, _) => const Text('other'))]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      theme: AppTheme.light(AppLocales.en),
      locale: AppLocales.en,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ));
    await tester.pumpAndSettle();
    return router;
  }

  ScrollPosition feedPosition(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  Finder imageOf(int i) => find.descendant(of: find.byKey(itemKey(i)), matching: find.byType(AspectRatio)).first;

  /// The image's own focus node (its ink well), as a keyboard, switch access or a screen reader reaches it.
  FocusNode focusOf(WidgetTester tester, int i) => Focus.of(tester.element(imageOf(i)));

  /// Scrolls the feed down to [target], focuses its image and opens the viewer from it with the keyboard.
  Future<(double, FocusNode)> openFromFarDown(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.byKey(itemKey(target)), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    final offset = feedPosition(tester).pixels;
    expect(offset, greaterThan(1500), reason: 'the feed is scrolled well down');
    final node = focusOf(tester, target)..requestFocus();
    await tester.pump();
    expect(node.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(MediaViewerPage), findsOneWidget);
    return (offset, node);
  }

  void expectBackInPlace(WidgetTester tester, double offset, FocusNode node) {
    expect(find.byType(MediaViewerPage), findsNothing);
    expect(feedPosition(tester).pixels, offset, reason: 'the feed keeps its scroll position');
    expect(find.byKey(itemKey(target)), findsOneWidget);
    expect(node.hasPrimaryFocus, isTrue, reason: 'focus is back on the image that opened the viewer');
  }

  testWidgets('closing with ✕ keeps the place in the feed and the focus', (tester) async {
    await pumpApp(tester);
    final (offset, node) = await openFromFarDown(tester);

    await tester.tap(find.byKey(const ValueKey('viewer-close')));
    await tester.pumpAndSettle();

    expectBackInPlace(tester, offset, node);
  });

  testWidgets('closing with the system back (button or gesture) closes only the viewer, in place', (tester) async {
    final router = await pumpApp(tester);
    final (offset, node) = await openFromFarDown(tester);

    // What Android's back button / predictive back gesture sends.
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(router.state.uri.toString(), '/home', reason: 'the page under the viewer stays');
    expectBackInPlace(tester, offset, node);
  });

  testWidgets('closing with a swipe down keeps the place in the feed and the focus', (tester) async {
    await pumpApp(tester);
    final (offset, node) = await openFromFarDown(tester);

    await tester.fling(find.byType(MediaViewerPage), const Offset(0, 400), 1500);
    await tester.pumpAndSettle();

    expectBackInPlace(tester, offset, node);
  });

  testWidgets('a tap (no keyboard) also comes back to the same place, again and again', (tester) async {
    await pumpApp(tester);
    await tester.scrollUntilVisible(find.byKey(itemKey(target)), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    final offset = feedPosition(tester).pixels;

    for (var round = 0; round < 3; round++) {
      await tester.tap(imageOf(target));
      await tester.pumpAndSettle();
      expect(find.byType(MediaViewerPage), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('viewer-close')));
      await tester.pumpAndSettle();
      expect(feedPosition(tester).pixels, offset, reason: 'round $round');
    }
  });

  testWidgets("a screen reader's focus is sent back to the image after closing", (tester) async {
    final semantics = tester.ensureSemantics();
    final sent = <Map<Object?, Object?>>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (message) async {
      sent.add(message! as Map<Object?, Object?>);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, null));
    await pumpApp(tester);
    await tester.scrollUntilVisible(find.byKey(itemKey(target)), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    // TalkBack / VoiceOver is on the image (the platform reports it), then opens it.
    final imageNode = tester.getSemantics(find.descendant(of: find.byKey(itemKey(target)), matching: find.byType(ArticleAttachmentsView)));
    ServicesBinding.instance.accessibilityFocus.value = imageNode.id;
    await tester.tap(imageOf(target));
    await tester.pumpAndSettle();
    expect(find.byType(MediaViewerPage), findsOneWidget);
    // Inside the viewer the reader moves on.
    ServicesBinding.instance.accessibilityFocus.value = tester.getSemantics(find.byKey(const ValueKey('viewer-close'))).id;

    await tester.tap(find.byKey(const ValueKey('viewer-close')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1)); // Android waits for its own refocus first

    expect(sent.where((m) => m['type'] == 'focus').map((m) => m['nodeId']), contains(imageNode.id));
    ServicesBinding.instance.accessibilityFocus.value = null;
    semantics.dispose();
  });
}

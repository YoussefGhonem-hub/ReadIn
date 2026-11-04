import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/platform/share_service.dart';
import 'package:readin/features/article/presentation/widgets/article_share_button.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_app.dart';

class _RecordingShare extends ShareService {
  final links = <({String url, String? subject, Rect? origin})>[];
  bool fail = false;

  @override
  Future<void> shareLink(String url, {String? subject, Rect? origin}) async {
    links.add((url: url, subject: subject, origin: origin));
    if (fail) throw Exception('no share sheet');
  }
}

void main() {
  late _RecordingShare share;

  setUp(() {
    share = _RecordingShare();
    getIt.registerSingleton<ShareService>(share);
  });
  tearDown(() => getIt.unregister<ShareService>());

  Future<void> pump(WidgetTester tester, Widget button) =>
      tester.pumpWidget(testApp(Scaffold(body: Center(child: button))));

  testWidgets('shares the web link of the version being read, with the title (F24)', (tester) async {
    final card = sampleCard(1, language: 'en');
    await pump(tester, ArticleShareButton(article: card));

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(share.links, hasLength(1));
    expect(share.links.single.url, 'https://readin.app/en/a/article-1');
    expect(share.links.single.subject, card.title);
    // The popover anchor on iPad: the button itself.
    expect(share.links.single.origin, tester.getRect(find.byType(ArticleShareButton)));
  });

  testWidgets('the Arabic version shares the /ar/ address', (tester) async {
    await pump(tester, ArticleShareButton(article: sampleCard(2)));

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(share.links.single.url, 'https://readin.app/ar/a/article-2');
  });

  testWidgets('is labelled Share and disabled until the article has loaded', (tester) async {
    await pump(tester, const ArticleShareButton(article: null));

    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.onPressed, isNull);
    expect(button.tooltip, tester.element(find.byType(IconButton)).l10n.share);
  });

  testWidgets('a share sheet that fails to open is not an error', (tester) async {
    share.fail = true;
    await pump(tester, ArticleShareButton(article: sampleCard(3)));

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(share.links, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}

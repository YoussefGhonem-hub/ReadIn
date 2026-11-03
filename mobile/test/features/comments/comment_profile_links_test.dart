import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/comments/presentation/widgets/comment_tile.dart';

import '../../helpers/comment_fixtures.dart';

void main() {
  setUp(() => CommentClock.now = () => commentsNow);
  tearDown(() => CommentClock.now = DateTime.now);

  final callbacks = CommentCallbacks(onLike: (_) {}, onReply: (_) {}, onMenu: (_, _) {}, onMoreReplies: (_) {});

  /// A comment by [omar] mentioning [mona], shown in a bottom sheet like the comments sheet; `/u/:username` records
  /// which profile opened.
  Future<List<String>> pumpInSheet(WidgetTester tester, Comment shown) async {
    final opened = <String>[];
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => SingleChildScrollView(child: CommentTile(comment: shown, callbacks: callbacks)),
              ),
              child: const Text('open comments'),
            ),
          ),
        ),
        GoRoute(
          path: '/u/:username',
          builder: (_, state) {
            opened.add(state.pathParameters['username']!);
            return const Text('profile page');
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      locale: AppLocales.en,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(AppLocales.en),
      routerConfig: router,
    ));
    await tester.tap(find.text('open comments'));
    await tester.pumpAndSettle();
    return opened;
  }

  final mentioning = comment(
    'c-1',
    body: 'Thanks @mona_dev, great point',
    mentions: const [CommentMention(userId: 'w-1', username: 'mona_dev')],
  );

  testWidgets("the author's name closes the sheet and opens their profile (F14)", (tester) async {
    final opened = await pumpInSheet(tester, mentioning);

    await tester.tap(find.text('Omar Khaled'));
    await tester.pumpAndSettle();

    expect(opened, ['omar_k']);
    expect(find.byType(CommentTile), findsNothing); // the sheet closed
    expect(find.text('profile page'), findsOneWidget);
  });

  testWidgets('a resolved mention opens that profile; an unresolved @word stays plain text', (tester) async {
    final opened = await pumpInSheet(tester, mentioning);

    final body = tester.widget<RichText>(find.descendant(of: find.byType(CommentBody), matching: find.byType(RichText)));
    final spans = <TextSpan>[];
    body.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) spans.add(span);
      return true;
    });
    final tappable = spans.where((s) => s.recognizer != null).toList();
    expect(tappable, hasLength(1));
    expect(tappable.single.text, contains('@mona_dev'));

    (tappable.single.recognizer! as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();

    expect(opened, ['mona_dev']);
    expect(find.text('profile page'), findsOneWidget);
  });

  testWidgets('a deleted account ("Deleted user") has no profile link', (tester) async {
    final opened = await pumpInSheet(tester, comment('c-2', author: null));

    await tester.tap(find.text('Deleted user'));
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
    expect(find.byType(CommentTile), findsOneWidget);
  });
}

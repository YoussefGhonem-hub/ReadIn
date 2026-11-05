import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/reactions/domain/entities/reactions.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/reactions/presentation/widgets/reaction_bar.dart';
import 'package:readin/features/reactions/presentation/widgets/reaction_button.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

/// The floating reactions bar (F10, like LinkedIn): long press, slide onto a reaction and lift the finger; the
/// staggered entrance, grow and lift under the finger, and the pick; all of it instant with reduce motion.
void main() {
  late MockReactionsRepository reactions;
  late EngagementCubit engagement;
  final card = engagedCard(1);

  setUpAll(() => registerFallbackValue(ReactionType.insightful));

  setUp(() {
    reactions = MockReactionsRepository();
    engagement = EngagementCubit(SetReaction(reactions), SetSaved(MockSavedRepository()));
    when(() => reactions.react(any(), any())).thenAnswer((invocation) async {
      final type = invocation.positionalArguments[1] as ReactionType;
      return Ok(ArticleReactions(reactions: const ReactionCounts().move(to: type), total: 1, myReaction: type));
    });
  });
  tearDown(() => engagement.close());

  Future<void> pump(WidgetTester tester, {bool reduceMotion = false, bool showCount = false, Variant variant = const Variant(AppLocales.en, Brightness.light)}) async {
    usePhoneSurface(tester);
    final session = MockSessionCubit();
    whenListen(session, const Stream<SessionState>.empty(),
        initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<EngagementCubit>.value(value: engagement),
        ],
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: Scaffold(
              body: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ReactionButton(article: card, showCount: showCount),
                ),
              ),
            ),
          ),
        ),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  Finder inBar(Finder finder) => find.descendant(of: find.byType(ReactionBar), matching: finder);
  Finder emoji(String text) => inBar(find.text(text));

  double opacityOf(WidgetTester tester, String text) =>
      tester.widget<FadeTransition>(find.ancestor(of: emoji(text), matching: find.byType(FadeTransition)).first).opacity.value;

  /// Presses the button until the long press fires (the bar opens) and keeps the finger down.
  Future<TestGesture> press(WidgetTester tester) async {
    final gesture = await tester.startGesture(tester.getCenter(find.byType(ReactionButton)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 20));
    await tester.pump();
    return gesture;
  }

  testWidgets('slide onto a reaction and lift the finger: it grows and lifts under the finger, then is picked', (tester) async {
    await pump(tester, showCount: true);
    final gesture = await press(tester);
    await tester.pump(ReactionBar.enterDuration);
    expect(find.byType(ReactionBar), findsOneWidget);

    final before = tester.getRect(emoji('🔥'));
    await gesture.moveTo(tester.getCenter(emoji('🔥')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final hovered = tester.getRect(emoji('🔥'));
    expect(hovered.width, greaterThan(before.width * 1.3), reason: 'it grows');
    expect(hovered.center.dy, lessThan(before.center.dy - 8), reason: 'it lifts');
    expect(tester.getRect(emoji('❤️')).width, moreOrLessEquals(tester.getSize(emoji('❤️')).width, epsilon: 0.5),
        reason: 'the others stay as they were');

    // Sliding on moves the grow to the next one.
    await gesture.moveTo(tester.getCenter(emoji('🤯')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getRect(emoji('🔥')).width, moreOrLessEquals(before.width, epsilon: 0.5));

    await gesture.moveTo(tester.getCenter(emoji('🔥')));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pump();
    expect(find.byType(ReactionBar), findsOneWidget, reason: 'the pick plays a short animation first');
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsNothing);
    verify(() => reactions.react(card.id, ReactionType.fire)).called(1);
    expect(find.descendant(of: find.byType(ReactionButton), matching: find.text('🔥')), findsOneWidget);
  });

  testWidgets('the four come in one after the other', (tester) async {
    await pump(tester);
    final gesture = await press(tester);
    await tester.pump(const Duration(milliseconds: 90));
    final early = [for (final e in ['💡', '❤️', '🔥', '🤯']) opacityOf(tester, e)];
    expect(early.first, greaterThan(0));
    expect(early.last, 0, reason: 'the last one has not started yet');
    for (var i = 1; i < early.length; i++) {
      expect(early[i], lessThanOrEqualTo(early[i - 1]));
    }
    await tester.pump(ReactionBar.enterDuration);
    for (final e in ['💡', '❤️', '🔥', '🤯']) {
      expect(opacityOf(tester, e), 1);
    }
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('lifting the finger where it was pressed keeps the bar open; a tap outside closes it with no reaction', (tester) async {
    await pump(tester);
    final gesture = await press(tester);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);

    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsNothing);
    verifyNever(() => reactions.react(any(), any()));
  });

  testWidgets('back closes the bar, not the screen under it', (tester) async {
    await pump(tester);
    final gesture = await press(tester);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsNothing);
    expect(find.byType(ReactionButton), findsOneWidget, reason: 'the screen stays');
    verifyNever(() => reactions.react(any(), any()));
  });

  testWidgets('reduce motion: everything at once, no grow or lift (a ring instead), and the pick is instant', (tester) async {
    await pump(tester, reduceMotion: true);
    final gesture = await press(tester);
    for (final e in ['💡', '❤️', '🔥', '🤯']) {
      expect(opacityOf(tester, e), 1, reason: 'no stagger');
    }
    final before = tester.getRect(emoji('❤️'));
    await gesture.moveTo(tester.getCenter(emoji('❤️')));
    await tester.pump();
    final hovered = tester.getRect(emoji('❤️'));
    expect(hovered, before, reason: 'no grow, no lift');
    final ring = find.descendant(
      of: find.byType(ReactionBar),
      matching: find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).border != null),
    );
    expect(ring, findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(find.byType(ReactionBar), findsNothing, reason: 'no pick animation');
    verify(() => reactions.react(card.id, ReactionType.love)).called(1);
  });

  testWidgets('no numbers or text in the bar; each reaction has its name, the current one says it removes it', (tester) async {
    final semantics = tester.ensureSemantics();
    engagement.seed([card.copyWithEngagement(myReaction: () => ReactionType.love, reactionCount: 3)]);
    await pump(tester);
    final gesture = await press(tester);
    await gesture.up();
    await tester.pumpAndSettle();

    final texts = tester.widgetList<Text>(find.descendant(of: find.byType(ReactionBar), matching: find.byType(Text)));
    expect([for (final t in texts) t.data], ['💡', '❤️', '🔥', '🤯']);
    expect(find.bySemanticsLabel('Choose a reaction'), findsWidgets);
    expect(find.bySemanticsLabel('Insightful'), findsOneWidget);
    expect(inBar(find.bySemanticsLabel('Remove your reaction (Love)')), findsOneWidget);
    expect(find.bySemanticsLabel('Fire'), findsOneWidget);
    expect(find.bySemanticsLabel('Mind-blown'), findsOneWidget);

    // Picking the current reaction removes it.
    when(() => reactions.removeReaction(card.id)).thenAnswer((_) async => const Ok(ArticleReactions(reactions: ReactionCounts(), total: 0)));
    await tester.tap(inBar(find.bySemanticsLabel('Remove your reaction (Love)')));
    await tester.pumpAndSettle();
    verify(() => reactions.removeReaction(card.id)).called(1);
    semantics.dispose();
  });

  testWidgets("a screen reader's long press opens the bar too", (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, showCount: true);
    final node = tester.getSemantics(find.byType(ReactionButton));
    expect(node.label, 'React, 16');
    expect(node.getSemanticsData().hasAction(SemanticsAction.longPress), isTrue);
    tester.semantics.longPress(find.semantics.byLabel('React, 16'));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('in Arabic the bar opens over the button, lined up with its start (the right)', (tester) async {
    await pump(tester, showCount: true, variant: const Variant(AppLocales.ar, Brightness.light));
    final gesture = await press(tester);
    await gesture.up();
    await tester.pumpAndSettle();
    final bar = tester.getRect(find.byType(ReactionBar));
    final button = tester.getRect(find.byType(ReactionButton));
    expect(bar.bottom, lessThanOrEqualTo(button.top));
    expect(bar.right, moreOrLessEquals(button.right, epsilon: 1));
    // RTL: 💡 is the right-most.
    expect(tester.getCenter(emoji('💡')).dx, greaterThan(tester.getCenter(emoji('🤯')).dx));
  });
}

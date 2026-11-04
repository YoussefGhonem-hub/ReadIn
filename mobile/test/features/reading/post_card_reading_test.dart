import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/presentation/cubit/post_cards_cubit.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
import 'package:readin/features/article/presentation/widgets/post_card_text.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';
import 'package:readin/features/reading/domain/repositories/reading_repository.dart';
import 'package:readin/features/reading/domain/usecases/reading_usecases.dart';
import 'package:readin/features/reading/presentation/tracking/post_card_reading.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/post_card_fixtures.dart';
import '../../helpers/test_app.dart';

class MockReadingRepository extends Mock implements ReadingRepository {}

/// An article shown whole in its post card counts like one read in the reader (F34, F04): the reader's tracker
/// reports through `PUT /articles/{id}/progress`; a cut-off article and guests send nothing.
void main() {
  const en = Variant(AppLocales.en, Brightness.light);
  late AppLocalizations l10n;
  late MockReadingRepository repository;
  late List<(String, ReadingProgressReport)> sent;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(AppLocales.en);
    registerFallbackValue(const ReadingProgressReport(language: 'en', percent: 0, lastPosition: null, activeSecondsDelta: 0));
  });

  setUp(() {
    repository = MockReadingRepository();
    sent = [];
    when(() => repository.reportProgress(any(), any())).thenAnswer((invocation) async {
      sent.add((invocation.positionalArguments[0] as String, invocation.positionalArguments[1] as ReadingProgressReport));
      return const Ok(ReadingProgressResult(percent: 100, completed: false, completedNow: false));
    });
    getIt.registerFactory<ReportReadingProgress>(() => ReportReadingProgress(repository));
  });

  tearDown(() => getIt.unregister<ReportReadingProgress>());

  Future<void> expandCard(WidgetTester tester, {required bool isComplete, bool signedIn = true}) async {
    usePhoneSurface(tester);
    final postCards = PostCardsCubit.withLoader(previewLoader(isComplete: isComplete));
    addTearDown(postCards.close);
    await tester.pumpWidget(testApp(
      withCardStores(
        Scaffold(body: ListView(children: [PostCard(article: postCard(1, language: 'en', cover: false))])),
        session: signedIn ? const SessionState(status: SessionStatus.authenticated, me: sampleMe) : const SessionState(status: SessionStatus.guest),
        postCards: postCards,
      ),
      variant: en,
    ));
    await tester.tap(find.textContaining(PostExcerpt.moreLabel(l10n.postReadMore), findRichText: true));
    await tester.pumpAndSettle();
  }

  testWidgets('a whole article in the card reports its progress, and the last report when it collapses', (tester) async {
    await expandCard(tester, isComplete: true);
    expect(find.byType(PostCardReading), findsOneWidget);
    expect(sent, isNotEmpty, reason: 'the first report goes at once');
    expect(sent.first.$1, 'art-1');
    expect(sent.first.$2.language, 'en');

    await tester.tap(find.text(l10n.postShowLess));
    await tester.pumpAndSettle();
    expect(find.byType(PostCardReading), findsNothing);
    expect(sent.last.$2.percent, 100, reason: 'the whole text was on screen');
  });

  testWidgets('a cut-off article never counts from the card', (tester) async {
    await expandCard(tester, isComplete: false);
    expect(find.byType(PostCardReading), findsNothing);
    expect(sent, isEmpty);
  });

  testWidgets('guests send nothing', (tester) async {
    await expandCard(tester, isComplete: true, signedIn: false);
    await tester.tap(find.text(l10n.postShowLess));
    await tester.pumpAndSettle();
    expect(sent, isEmpty);
  });
}

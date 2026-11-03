import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/home/presentation/cubit/live_feed_cubit.dart';

class MockRealtimeService extends Mock implements RealtimeService {}

void main() {
  late MockRealtimeService realtime;
  late StreamController<int?> latest;
  late Map<String, StreamController<LiveArticleCounts>> articles;

  setUp(() {
    realtime = MockRealtimeService();
    latest = StreamController<int?>.broadcast();
    articles = {};
    when(() => realtime.latestPublished()).thenAnswer((_) => latest.stream);
    when(() => realtime.watchArticle(any())).thenAnswer(
      (invocation) => articles.putIfAbsent(invocation.positionalArguments.single as String, StreamController.broadcast).stream,
    );
  });

  blocTest<LiveFeedCubit, LiveFeedState>(
    'the first publish time is the baseline; a later one shows the banner until acknowledged',
    build: () => LiveFeedCubit(realtime),
    act: (cubit) async {
      cubit.start();
      latest.add(1000);
      await Future<void>.delayed(Duration.zero);
      latest.add(2000);
      await Future<void>.delayed(Duration.zero);
      cubit.acknowledgeNewArticles();
    },
    expect: () => [
      const LiveFeedState(hasNewArticles: true),
      const LiveFeedState(),
    ],
  );

  blocTest<LiveFeedCubit, LiveFeedState>(
    'the very first article shows the banner when nothing was published before',
    build: () => LiveFeedCubit(realtime),
    act: (cubit) async {
      cubit.start();
      latest.add(null);
      await Future<void>.delayed(Duration.zero);
      latest.add(5000);
    },
    expect: () => [const LiveFeedState(hasNewArticles: true)],
  );

  blocTest<LiveFeedCubit, LiveFeedState>(
    'cards on screen get live counters and keep the last values when they leave',
    build: () => LiveFeedCubit(realtime),
    act: (cubit) async {
      cubit.watch('a1');
      articles['a1']!.add(const LiveArticleCounts(commentCount: 3));
      await Future<void>.delayed(Duration.zero);
      cubit.unwatch('a1');
      await Future<void>.delayed(Duration.zero);
      articles['a1']!.add(const LiveArticleCounts(commentCount: 4)); // no longer listened to
    },
    expect: () => [
      const LiveFeedState(counts: {'a1': LiveArticleCounts(commentCount: 3)}),
    ],
    verify: (_) => expect(articles['a1']!.hasListener, isFalse),
  );

  test('the same article on screen twice keeps one listener until both leave', () async {
    final cubit = LiveFeedCubit(realtime)
      ..watch('a1')
      ..watch('a1')
      ..unwatch('a1');
    verify(() => realtime.watchArticle('a1')).called(1);
    expect(articles['a1']!.hasListener, isTrue);

    cubit.unwatch('a1');
    await Future<void>.delayed(Duration.zero);
    expect(articles['a1']!.hasListener, isFalse);
    await cubit.close();
  });

  test('close() cancels every subscription', () async {
    final cubit = LiveFeedCubit(realtime)
      ..start()
      ..watch('a1');
    await cubit.close();
    expect(latest.hasListener, isFalse);
    expect(articles['a1']!.hasListener, isFalse);
  });
}

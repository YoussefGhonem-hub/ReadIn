import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/realtime/live_connection.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/core/realtime/realtime_token_api.dart';

/// In-memory stand-in for the Realtime Database.
class FakeConnection implements LiveConnection {
  final values = <String, StreamController<Object?>>{};
  final children = <String, StreamController<(String, Object?)>>{};
  final childSince = <String, int>{};
  final signIns = <String>[];
  int signOuts = 0;
  bool? online;
  int serverNow = 1700000000000;

  StreamController<Object?> _value(String path) => values.putIfAbsent(path, StreamController<Object?>.broadcast);

  bool listening(String path) => values[path]?.hasListener ?? false;

  void emit(String path, Object? value) => _value(path).add(value);

  @override
  Stream<Object?> onValue(String path) => _value(path).stream;

  @override
  Stream<(String, Object?)> onChildAddedSince(String path, String orderBy, int since) {
    childSince['$path|$orderBy'] = since;
    return children.putIfAbsent(path, StreamController<(String, Object?)>.broadcast).stream;
  }

  @override
  Future<int> serverTime() async => serverNow;

  @override
  Future<void> signIn(String customToken) async => signIns.add(customToken);

  @override
  Future<void> signOut() async => signOuts++;

  @override
  void setOnline(bool online) => this.online = online;
}

class FakeConnector implements LiveConnector {
  FakeConnector(this.connection);

  final LiveConnection? connection;
  int opens = 0;

  @override
  Future<LiveConnection> open() async {
    opens++;
    return connection ?? (throw StateError('Firebase is unavailable'));
  }
}

class MockTokenApi extends Mock implements RealtimeTokenApi {}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeConnection connection;
  late FakeConnector connector;
  late MockTokenApi tokens;
  late RealtimeService service;

  setUp(() {
    connection = FakeConnection();
    connector = FakeConnector(connection);
    tokens = MockTokenApi();
    when(() => tokens.token()).thenAnswer((_) async => const RealtimeToken('custom-token'));
    service = RealtimeService(connector, tokens);
  });

  group('article counters', () {
    test('combine the counters, total the reactions and keep unknown fields null', () async {
      final seen = <LiveArticleCounts>[];
      final subscription = service.watchArticle('a1').listen(seen.add);
      await settle();

      connection.emit('live/articles/a1/commentCount', 7);
      connection.emit('live/articles/a1/reactions', {'insightful': 3, 'love': 2, 'fire': 1});
      await settle();

      expect(seen.first, const LiveArticleCounts(commentCount: 7));
      expect(seen.last.reactionCount, 6);
      expect(seen.last.reactions, {ReactionType.insightful: 3, ReactionType.love: 2, ReactionType.fire: 1, ReactionType.mindBlown: 0});
      expect(seen.last.saveCount, isNull);
      await subscription.cancel();
    });

    test('listen to the counters only, never the article node with its events', () async {
      final subscription = service.watchArticle('a1').listen((_) {});
      await settle();

      expect(connection.listening('live/articles/a1'), isFalse);
      expect(connection.listening('live/articles/a1/reactions'), isTrue);
      expect(connection.listening('live/articles/a1/commentCount'), isTrue);
      expect(connection.listening('live/articles/a1/saveCount'), isTrue);
      expect(connection.listening('live/articles/a1/repostCount'), isTrue);

      await subscription.cancel();
      await settle();
      expect(connection.listening('live/articles/a1/commentCount'), isFalse);
    });

    test('the repost counter (F29) comes with the others', () async {
      final seen = <LiveArticleCounts>[];
      final subscription = service.watchArticle('a1').listen(seen.add);
      await settle();
      connection.emit('live/articles/a1/repostCount', 5);
      await settle();
      expect(seen.last, const LiveArticleCounts(repostCount: 5));
      await subscription.cancel();
    });

    test('ignore malformed values', () async {
      final seen = <LiveArticleCounts>[];
      final subscription = service.watchArticle('a1').listen(seen.add);
      await settle();
      connection.emit('live/articles/a1/commentCount', 'many');
      connection.emit('live/articles/a1/saveCount', -4);
      await settle();
      expect(seen.last, const LiveArticleCounts());
      await subscription.cancel();
    });

    test('refuse ids that are not safe path segments', () async {
      expect(await service.watchArticle('a1/../../users/u2').isEmpty, isTrue);
      expect(await service.commentEvents('a.b').isEmpty, isTrue);
      expect(connector.opens, 0);
    });
  });

  test('comment events start at the server time and only valid ones pass', () async {
    final events = <CommentEvent>[];
    final subscription = service.commentEvents('a1').listen(events.add);
    await settle();

    expect(connection.childSince['live/articles/a1/events|at'], connection.serverNow);
    final added = connection.children['live/articles/a1/events']!;
    added
      ..add(('-Nx1', {'type': 'reply.created', 'commentId': 'c2', 'parentId': 'c1', 'at': 5}))
      ..add(('-Nx2', {'type': 'comment.exploded', 'commentId': 'c3', 'at': 6}))
      ..add(('-Nx3', {'type': 'comment.created', 'at': 7}));
    await settle();

    expect(events, [const CommentEvent(id: '-Nx1', type: CommentEventType.replyCreated, commentId: 'c2', parentId: 'c1', at: 5)]);
    await subscription.cancel();
  });

  test('the latest publish time is read as epoch ms', () async {
    final seen = <int?>[];
    final subscription = service.latestPublished().listen(seen.add);
    await settle();
    connection
      ..emit('live/feed/latestPublishedAt', 1700000000123)
      ..emit('live/feed/latestPublishedAt', '2026-11-03T08:00:00Z')
      ..emit('live/feed/latestPublishedAt', null);
    await settle();
    expect(seen, [1700000000123, DateTime.parse('2026-11-03T08:00:00Z').millisecondsSinceEpoch, null]);
    await subscription.cancel();
  });

  group('unread badge', () {
    test('signs in with a custom token and follows the user', () async {
      await service.followUser('user-1');
      expect(connection.signIns, ['custom-token']);

      connection.emit('live/users/user-1/unreadNotifications', 4);
      await settle();
      expect(service.unreadNotifications.value, 4);
    });

    test('stops, clears the badge and signs out of Firebase on sign-out', () async {
      await service.followUser('user-1');
      connection.emit('live/users/user-1/unreadNotifications', 2);
      await settle();

      await service.followUser(null);
      expect(service.unreadNotifications.value, 0);
      expect(connection.listening('live/users/user-1/unreadNotifications'), isFalse);
      expect(connection.signOuts, greaterThanOrEqualTo(2)); // before signing in, and on sign-out
    });

    test('does nothing for a guest who never connected', () async {
      await service.followUser(null);
      expect(connector.opens, 0);
    });

    test('keeps the badge at 0 when no token can be issued', () async {
      when(() => tokens.token()).thenThrow(Exception('404'));
      await service.followUser('user-1');
      expect(connection.signIns, isEmpty);
      expect(connection.listening('live/users/user-1/unreadNotifications'), isFalse);
      expect(service.unreadNotifications.value, 0);
      expect(service.unreadLive.value, isFalse, reason: 'the badge falls back to REST (F17)');
    });

    test('is live from the first value until the user changes or the listener ends (F17)', () async {
      await service.followUser('user-1');
      expect(service.unreadLive.value, isFalse, reason: 'nothing arrived yet');

      connection.emit('live/users/user-1/unreadNotifications', null);
      await settle();
      expect((service.unreadLive.value, service.unreadNotifications.value), (true, 0), reason: 'no node yet = 0 unread');

      await connection.values['live/users/user-1/unreadNotifications']!.close(); // e.g. permission denied
      await settle();
      expect(service.unreadLive.value, isFalse);

      await service.followUser('user-2');
      connection.emit('live/users/user-2/unreadNotifications', 3);
      await settle();
      expect(service.unreadLive.value, isTrue);
      await service.followUser(null);
      expect(service.unreadLive.value, isFalse);
    });
  });

  test('pauses the socket in the background', () async {
    await service.followUser('user-1');
    await service.setForeground(false);
    expect(connection.online, isFalse);
    await service.setForeground(true);
    expect(connection.online, isTrue);
  });

  test('stays on REST when Firebase is unavailable', () async {
    service = RealtimeService(FakeConnector(null), tokens);
    expect(await service.watchArticle('a1').isEmpty, isTrue);
    await service.followUser('user-1');
    expect(service.unreadNotifications.value, 0);
  });
}

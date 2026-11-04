import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/push/devices_api.dart';
import 'package:readin/core/push/push_platform.dart';
import 'package:readin/core/push/push_read_receipts.dart';
import 'package:readin/core/push/push_service.dart';

class FakePushPlatform implements PushPlatform {
  bool supported = true;
  PushPermission current = PushPermission.notDetermined;
  String? token = 'fcm-token-1';
  PushPayload? launch;
  int requests = 0;
  int deletes = 0;
  final shown = <PushPayload>[];
  final refreshes = StreamController<String>.broadcast();
  final foreground = StreamController<PushPayload>.broadcast();
  final opened = StreamController<PushPayload>.broadcast();

  @override
  bool get isSupported => supported;

  @override
  String get platformName => 'android';

  @override
  Future<void> initialize() async {}

  @override
  Future<PushPermission> permission() async => current;

  @override
  Future<PushPermission> requestPermission() async {
    requests++;
    return current = PushPermission.granted;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async => deletes++;

  @override
  Stream<String> get onTokenRefresh => refreshes.stream;

  @override
  Stream<PushPayload> get onForegroundMessage => foreground.stream;

  @override
  Stream<PushPayload> get onOpened => opened.stream;

  @override
  Future<PushPayload?> launchPayload() async => launch;

  @override
  Future<void> show(PushPayload payload) async => shown.add(payload);
}

class MockDevicesApi extends Mock implements DevicesApi {}

/// Records the notifications marked read; [failing] makes every call throw.
class FakeReadReceipts implements PushReadReceipts {
  final read = <String>[];
  bool failing = false;

  @override
  Future<void> markRead(String notificationId) async {
    if (failing) throw StateError('offline');
    read.add(notificationId);
  }
}

class FakeRegisterDeviceRequest extends Fake implements RegisterDeviceRequest {}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakePushPlatform platform;
  late MockDevicesApi devices;
  late PushService push;
  late FakeReadReceipts receipts;
  final registered = <String>[];

  setUpAll(() => registerFallbackValue(FakeRegisterDeviceRequest()));

  setUp(() {
    platform = FakePushPlatform();
    devices = MockDevicesApi();
    registered.clear();
    when(() => devices.register(any())).thenAnswer((invocation) async {
      final body = invocation.positionalArguments.single as RegisterDeviceRequest;
      registered.add('${body.platform}:${body.token}');
    });
    receipts = FakeReadReceipts();
    push = PushService(platform, devices, receipts);
  });

  test('stays unsupported and never asks without Cloud Messaging (emulator, no Firebase)', () async {
    platform.supported = false;
    await push.start();
    expect(push.permission.value, PushPermission.unsupported);
    expect(await push.enable(), PushPermission.unsupported);
    expect(platform.requests, 0);
  });

  test('never asks for permission by itself', () async {
    await push.start();
    await push.followUser('user-1');
    expect(platform.requests, 0);
    expect(registered, isEmpty);
  });

  test('asks in context, then registers this device for the signed-in user', () async {
    await push.start();
    await push.followUser('user-1');

    expect(await push.enable(), PushPermission.granted);
    expect(registered, ['android:fcm-token-1']);
  });

  test('registers on sign-in when permission was granted earlier, once per user and token', () async {
    platform.current = PushPermission.granted;
    await push.start();
    await push.followUser('user-1');
    await push.followUser('user-1');
    expect(registered, ['android:fcm-token-1']);

    platform.token = 'fcm-token-2';
    platform.refreshes.add('fcm-token-2');
    await settle();
    expect(registered, ['android:fcm-token-1', 'android:fcm-token-2']);
  });

  test('registers once start() finishes when the session was restored first', () async {
    platform.current = PushPermission.granted;
    await push.followUser('user-1');
    await push.start();
    expect(registered, ['android:fcm-token-1']);
  });

  test('a deleted account: the token is deleted on the device, registered or not, and nothing registers again', () async {
    await push.start();
    await push.followUser('user-1'); // no permission yet: never registered
    await push.forgetDevice();
    expect(platform.deletes, 1);

    platform.current = PushPermission.granted;
    platform.refreshes.add('fcm-token-2'); // FCM hands out a new token after the delete
    await settle();
    await push.followUser(null); // the session ends right after: no second delete
    expect(registered, isEmpty);
    expect(platform.deletes, 1);
  });

  test('forgetting the device without Cloud Messaging does nothing', () async {
    platform.supported = false;
    await push.forgetDevice();
    expect(platform.deletes, 0);
  });

  test('deletes the token on sign-out', () async {
    platform.current = PushPermission.granted;
    await push.start();
    await push.followUser('user-1');
    await push.followUser(null);
    expect(platform.deletes, 1);
  });

  test('shows foreground pushes as a local notification', () async {
    await push.start();
    platform.foreground.add(const PushPayload(title: 'أحمد رد عليك', link: 'readin://a/my-post'));
    await settle();
    expect(platform.shown.single.title, 'أحمد رد عليك');
  });

  test('turns taps into app routes, including the tap that launched the app', () async {
    platform.launch = const PushPayload(link: 'readin://a/launch-post');
    final paths = <String>[];
    push.openPaths.listen(paths.add);
    await push.start();

    platform.opened
      ..add(const PushPayload(link: 'https://readin.app/ar/a/my-post'))
      ..add(const PushPayload(link: 'https://evil.example/phish'))
      ..add(const PushPayload());
    await settle();

    expect(paths, ['/a/launch-post', '/a/my-post', '/notifications']);
  });

  group('daily-article push (F07)', () {
    // As FCM delivers it (docs/api/contract-v1.md, "Push payloads").
    const daily = RemoteMessage(
      notification: RemoteNotification(title: 'مقال النهارده جاهز ☕', body: 'RAG ولا Fine-tuning؟'),
      data: {
        'type': 'daily_article',
        'articleId': '0a1b2c3d-0000-0000-0000-000000000001',
        'slug': 'rag-vs-fine-tuning',
        'link': 'readin://a/rag-vs-fine-tuning',
        'lang': 'ar',
      },
    );
    final payload = FirebasePushPlatform.payloadOf(daily);

    test('is read the same way in every app state', () {
      expect(payload.title, 'مقال النهارده جاهز ☕');
      expect(payload.body, 'RAG ولا Fine-tuning؟');
      expect(payload.link, 'readin://a/rag-vs-fine-tuning');
      expect(payload.notificationId, isNull);
      final withoutLink = FirebasePushPlatform.payloadOf(
        const RemoteMessage(data: {'type': 'daily_article', 'slug': 'rag-vs-fine-tuning'}),
      );
      expect(withoutLink.link, 'readin://a/rag-vs-fine-tuning');
    });

    test('a tap that launches the app (terminated) opens the reader', () async {
      platform.launch = payload;
      final paths = <String>[];
      push.openPaths.listen(paths.add);
      await push.start();
      await settle();
      expect(paths, ['/a/rag-vs-fine-tuning']);
    });

    test('a tap while the app is in the background opens the reader', () async {
      final paths = <String>[];
      push.openPaths.listen(paths.add);
      await push.start();
      platform.opened.add(payload);
      await settle();
      expect(paths, ['/a/rag-vs-fine-tuning']);
    });

    test('in the foreground it is shown, and tapping it opens the reader', () async {
      final paths = <String>[];
      push.openPaths.listen(paths.add);
      await push.start();

      platform.foreground.add(payload);
      await settle();
      expect(platform.shown.single.title, 'مقال النهارده جاهز ☕');
      expect(paths, isEmpty, reason: 'showing it opens nothing by itself');

      platform.opened.add(PushPayload.fromLocalPayload(platform.shown.single.toLocalPayload())); // the local tap
      await settle();
      expect(paths, ['/a/rag-vs-fine-tuning']);
    });
  });

  group('a tapped push marks its notification read (F17)', () {
    // As FCM delivers it (docs/handoff/f17-notifications.md, "Push data").
    const reply = RemoteMessage(
      notification: RemoteNotification(title: 'ReadIn', body: 'منى ردّت على تعليقك'),
      data: {'type': 'comment_reply', 'notificationId': 'n-42', 'link': 'readin://a/di-dotnet#comment-c-7', 'lang': 'ar'},
    );
    final payload = FirebasePushPlatform.payloadOf(reply);

    test('the payload carries the notification id, and the link keeps the comment', () {
      expect(payload.notificationId, 'n-42');
      expect(payload.link, 'readin://a/di-dotnet#comment-c-7');
      expect(FirebasePushPlatform.payloadOf(const RemoteMessage(data: {'notificationId': '  '})).notificationId, isNull);
    });

    test('the local notification of a foreground push keeps the link and the id; a bare link still reads', () {
      final local = PushPayload.fromLocalPayload(payload.toLocalPayload());
      expect((local.link, local.notificationId), ('readin://a/di-dotnet#comment-c-7', 'n-42'));
      final legacy = PushPayload.fromLocalPayload('readin://a/older-post');
      expect((legacy.link, legacy.notificationId), ('readin://a/older-post', null));
      expect(PushPayload.fromLocalPayload(null).link, isNull);
      expect(PushPayload.fromLocalPayload('{not json').link, '{not json');
    });

    test('terminated: the launch tap waits for the restored session, then is marked read and opens the comment', () async {
      platform.launch = payload;
      final paths = <String>[];
      push.openPaths.listen(paths.add);
      await push.start();
      await settle();
      expect(paths, ['/a/di-dotnet#comment-c-7']);
      expect(receipts.read, isEmpty, reason: 'no access token before the session is restored');

      await push.followUser('user-1');
      await settle();
      expect(receipts.read, ['n-42']);
    });

    test('background: marked read right away when signed in', () async {
      await push.start();
      await push.followUser('user-1');
      platform.opened.add(payload);
      await settle();
      expect(receipts.read, ['n-42']);
    });

    test('foreground: the shown notification\'s tap is marked read', () async {
      await push.start();
      await push.followUser('user-1');
      platform.foreground.add(payload);
      await settle();
      expect(receipts.read, isEmpty, reason: 'showing it is not opening it');

      platform.opened.add(PushPayload.fromLocalPayload(platform.shown.single.toLocalPayload()));
      await settle();
      expect(receipts.read, ['n-42']);
    });

    test('a tap without a link is still marked read and opens nothing', () async {
      final paths = <String>[];
      push.openPaths.listen(paths.add);
      await push.start();
      await push.followUser('user-1');
      platform.opened.add(const PushPayload(notificationId: 'n-7'));
      await settle();
      expect(receipts.read, ['n-7']);
      expect(paths, isEmpty);
    });

    test('signed out: the tap opens the app but nothing is marked, not even after a later sign in', () async {
      platform.launch = payload;
      await push.start();
      await push.followUser(null);
      await push.followUser('user-2');
      await settle();
      expect(receipts.read, isEmpty);
    });

    test('a failed receipt is swallowed', () async {
      receipts.failing = true;
      await push.start();
      await push.followUser('user-1');
      platform.opened.add(payload);
      await settle();
      expect(receipts.read, isEmpty);
    });
  });
}

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/push/devices_api.dart';
import 'package:readin/core/push/push_platform.dart';
import 'package:readin/core/push/push_service.dart';

class FakePushPlatform implements PushPlatform {
  bool supported = true;
  PushPermission current = PushPermission.notDetermined;
  String? token = 'fcm-token-1';
  String? launch;
  int requests = 0;
  int deletes = 0;
  final shown = <PushPayload>[];
  final refreshes = StreamController<String>.broadcast();
  final foreground = StreamController<PushPayload>.broadcast();
  final opened = StreamController<String?>.broadcast();

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
  Stream<String?> get onOpened => opened.stream;

  @override
  Future<String?> launchLink() async => launch;

  @override
  Future<void> show(PushPayload payload) async => shown.add(payload);
}

class MockDevicesApi extends Mock implements DevicesApi {}

class FakeRegisterDeviceRequest extends Fake implements RegisterDeviceRequest {}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakePushPlatform platform;
  late MockDevicesApi devices;
  late PushService push;
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
    push = PushService(platform, devices);
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
    platform.launch = 'readin://a/launch-post';
    final paths = <String>[];
    push.openPaths.listen(paths.add);
    await push.start();

    platform.opened
      ..add('https://readin.app/ar/a/my-post')
      ..add('https://evil.example/phish')
      ..add(null);
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
      final withoutLink = FirebasePushPlatform.payloadOf(
        const RemoteMessage(data: {'type': 'daily_article', 'slug': 'rag-vs-fine-tuning'}),
      );
      expect(withoutLink.link, 'readin://a/rag-vs-fine-tuning');
    });

    test('a tap that launches the app (terminated) opens the reader', () async {
      platform.launch = payload.link;
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
      platform.opened.add(payload.link);
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

      platform.opened.add(platform.shown.single.link); // the local notification's tap
      await settle();
      expect(paths, ['/a/rag-vs-fine-tuning']);
    });
  });
}

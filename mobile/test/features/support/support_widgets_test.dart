import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/push/push_links.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:readin/features/media/domain/repositories/media_picker.dart';
import 'package:readin/features/moderation/presentation/widgets/moderation_widgets.dart' show ModerationClock;
import 'package:readin/features/notifications/data/models/notification_models.dart';
import 'package:readin/features/notifications/domain/entities/app_notification.dart';
import 'package:readin/features/notifications/domain/entities/notification_settings.dart';
import 'package:readin/features/notifications/presentation/cubit/notification_settings_cubit.dart';
import 'package:readin/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:readin/features/notifications/presentation/widgets/notification_text.dart';
import 'package:readin/features/support/data/datasources/support_device_source.dart';
import 'package:readin/features/support/domain/entities/support.dart';
import 'package:readin/features/support/domain/entities/support_failures.dart';
import 'package:readin/features/support/domain/usecases/support_usecases.dart';
import 'package:readin/features/support/presentation/cubit/support_cubits.dart';
import 'package:readin/features/support/presentation/pages/admin_ticket_page.dart';
import 'package:readin/features/support/presentation/pages/new_ticket_page.dart';
import 'package:readin/features/support/presentation/pages/support_ticket_page.dart';

import '../../helpers/admin_fakes.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class _MockPicker extends Mock implements MediaPicker {}

class _Device implements SupportDeviceSource {
  @override
  Future<SupportDevice> read({String? screen}) async => SupportDevice(platform: 'ios', screen: screen);
}

class _MockNotificationSettingsCubit extends MockCubit<NotificationSettingsState> implements NotificationSettingsCubit {}

const _en = Variant(AppLocales.en, Brightness.light);

void main() {
  late MockSupportRepository repository;
  late AppLocalizations en;
  late AppLocalizations ar;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(AppLocales.en);
    ar = await AppLocalizations.delegate.load(AppLocales.ar);
    registerFallbackValue(const NewSupportTicket(category: SupportCategory.other, subject: '', message: ''));
  });

  setUp(() {
    repository = MockSupportRepository();
    ModerationClock.now = () => adminNow;
  });

  tearDown(() => ModerationClock.now = DateTime.now);

  MockSessionCubit sessionOf(Me me) => MockSessionCubit()..hold(SessionState(status: SessionStatus.authenticated, me: me));

  Future<void> pump(WidgetTester tester, Widget child, {Me? me, Variant variant = _en, Size size = const Size(390, 844)}) async {
    usePhoneSurface(tester, size: size);
    await tester.pumpWidget(testApp(
      BlocProvider<SessionCubit>.value(value: sessionOf(me ?? supportMemberMe), child: child),
      variant: variant,
    ));
    await tester.pump();
  }

  group('a new ticket', () {
    NewTicketCubit cubit() => NewTicketCubit(CreateSupportTicket(repository, _Device()), _MockPicker());

    for (final variant in Variant.all) {
      testWidgets('says what is missing, then sends ${variant.name}', (tester) async {
        when(() => repository.create(any())).thenAnswer((_) async => Ok(ticketOf(ticketSummary())));
        final form = cubit();
        await pump(tester, BlocProvider.value(value: form, child: const NewTicketView(from: '/settings')), variant: variant, size: const Size(390, 1400));

        await tester.tap(find.byKey(const ValueKey('support-send')));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(form.state.showErrors, isTrue);
        verifyNever(() => repository.create(any()));

        await tester.tap(find.byKey(const ValueKey('support-category-app_problem')));
        await tester.enterText(find.byKey(const ValueKey('support-subject')), 'PDF crash');
        await tester.enterText(find.byKey(const ValueKey('support-message')), 'The app closes when I open a PDF.');
        await tester.pump();
        expect(form.state.isValid, isTrue);
        await form.close();
      });
    }

    testWidgets('the ticket limit says which one', (tester) async {
      when(() => repository.create(any())).thenAnswer((_) async => const Err(SupportLimitFailure(limit: SupportLimitKind.open)));
      final form = cubit()
        ..setCategory(SupportCategory.other)
        ..setSubject('Hello there')
        ..setMessage('A question about the app.');
      await pump(tester, BlocProvider.value(value: form, child: const NewTicketView()), size: const Size(390, 1400));

      await form.submit();
      await tester.pump();

      expect(find.byKey(const ValueKey('support-failure')), findsOneWidget);
      expect(find.text(en.errSupportLimitOpen), findsOneWidget);
      await form.close();
    });
  });

  group("a member's ticket", () {
    for (final variant in Variant.all) {
      testWidgets('closed within 30 days: Reopen, no composer ${variant.name}', (tester) async {
        final summary = ticketSummary(status: SupportStatus.closed, canReopen: true);
        when(() => repository.ticket('t-1')).thenAnswer((_) async => Ok(ticketOf(summary)));
        await pump(
          tester,
          BlocProvider(create: (_) => SupportTicketCubit(MyTicketCommands(repository), 't-1')..load(), child: const SupportTicketView()),
          variant: variant,
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('support-reopen')), findsOneWidget);
        expect(find.byKey(const ValueKey('composer-text')), findsNothing);
      });
    }

    testWidgets('open: the conversation and a reply box; support is anonymous', (tester) async {
      final summary = ticketSummary(status: SupportStatus.answered);
      when(() => repository.ticket('t-1')).thenAnswer((_) async => Ok(ticketOf(summary)));
      await pump(
        tester,
        BlocProvider(create: (_) => SupportTicketCubit(MyTicketCommands(repository), 't-1')..load(), child: const SupportTicketView()),
      );
      await tester.pump();

      expect(find.textContaining('#12'), findsOneWidget, reason: 'the number, isolated left to right');
      expect(find.byKey(const ValueKey('support-message-m-2')), findsOneWidget);
      expect(find.text(en.supportTeam), findsOneWidget);
      expect(find.byKey(const ValueKey('composer-text')), findsOneWidget);
    });
  });

  group('a ticket in the console', () {
    for (final variant in Variant.all) {
      testWidgets('internal notes stand apart; reply or note ${variant.name}', (tester) async {
        when(() => repository.adminTicket('t-1')).thenAnswer((_) async => Ok(adminTicket()));
        when(() => repository.adminMessage('t-1', any(), internal: any(named: 'internal')))
            .thenAnswer((_) async => Ok(SupportMessage(id: 'm-3', fromSupport: true, body: 'x', createdAt: adminNow)));
        await pump(
          tester,
          BlocProvider(create: (_) => AdminTicketCubit(AdminTicketCommands(repository), 't-1')..load(), child: const AdminTicketView()),
          me: adminMe(),
          variant: variant,
          size: const Size(390, 1600),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('admin-ticket-mode')), findsOneWidget);
        expect(find.byKey(const ValueKey('support-message-m-2')), findsOneWidget);

        final l10n = variant.locale == AppLocales.ar ? ar : en;
        await tester.tap(find.text(l10n.supportNoteMode).last);
        await tester.pump();
        await tester.enterText(find.byKey(const ValueKey('composer-text')), 'Crash in the PDF viewer');
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('composer-send')));
        await tester.pumpAndSettle();

        verify(() => repository.adminMessage('t-1', 'Crash in the PDF viewer', internal: true)).called(1);
      });
    }
  });

  group('notifications (F23, F35)', () {
    AppNotification parse(Map<String, Object?> json) => NotificationModel.fromJson({
          'id': 'n-1',
          'createdAt': '2026-11-07T10:00:00Z',
          'updatedAt': '2026-11-07T10:00:00Z',
          'isRead': false,
          'actorCount': 0,
          'link': 'readin://notifications',
          ...json,
        }).toEntity();

    test('announcements show their own title and body', () {
      final n = parse({
        'type': 'announcement',
        'data': {'announcementId': 'an-1', 'title': 'تحديث جديد', 'body': 'جرّب المسارات الجديدة'},
      });

      expect(n.type, NotificationType.announcement);
      expect(notificationMessage(en, n), 'تحديث جديد');
      expect(notificationDetail(n), 'جرّب المسارات الجديدة');
      expect(notificationMessage(en, parse({'type': 'announcement', 'data': <String, Object?>{}})), en.adminNotifAnnouncement);
    });

    test("support replies are anonymous, say when support closed it, and show '#12 · subject'", () {
      final reply = parse({
        'type': 'support_reply',
        'data': {'ticketId': 't-1', 'ticketNumber': 12, 'subject': 'PDF crash'},
      });
      final closed = parse({
        'type': 'support_reply',
        'data': {'ticketId': 't-1', 'ticketNumber': 12, 'subject': 'PDF crash', 'closed': true},
      });

      expect(notificationMessage(en, reply), 'Support replied to your ticket');
      expect(notificationMessage(ar, reply), 'ردّ فريق الدعم على تذكرتك');
      expect(notificationMessage(en, closed), 'Your ticket was closed');
      expect(notificationDetail(reply), contains('#12'));
      expect(notificationDetail(reply), endsWith(' · PDF crash'));
      expect(isActorNotification(NotificationType.supportReply), isFalse);
    });

    test('a new ticket leads with the member', () {
      final n = parse({
        'type': 'support_ticket',
        'actor': {'id': 'u-1', 'displayName': 'Ahmed', 'username': 'ahmed'},
        'actorCount': 1,
        'data': {'ticketId': 't-1', 'ticketNumber': 3, 'subject': 'Locked out'},
      });

      expect(isActorNotification(n.type), isTrue);
      expect(notificationMessage(en, n), 'New support message from Ahmed');
    });

    test('announcement and support_ticket can be turned off; support_reply always comes', () {
      expect(NotificationType.announcement.isConfigurable, isTrue);
      expect(NotificationType.supportTicket.isConfigurable, isTrue);
      expect(NotificationType.supportReply.isConfigurable, isFalse);
      final settings = NotificationSettingsModel.fromJson({
        'types': {'announcement': 'off', 'support_ticket': 'inApp', 'support_reply': 'off'},
      }).toEntity();
      expect(settings.types, {NotificationType.announcement: NotificationMode.off, NotificationType.supportTicket: NotificationMode.inApp});
    });

    testWidgets('Settings lists announcements and new tickets only when the API sends them', (tester) async {
      Future<void> pumpSettings(Map<NotificationType, NotificationMode> types) async {
        final cubit = _MockNotificationSettingsCubit()
          ..hold(NotificationSettingsState(status: NotificationSettingsStatus.ready, settings: NotificationSettings(types: types)));
        await pump(
          tester,
          BlocProvider<NotificationSettingsCubit>.value(value: cubit, child: const NotificationSettingsView()),
          size: const Size(390, 1600),
        );
      }

      await pumpSettings(const {});
      expect(find.byKey(const ValueKey('mode-announcement')), findsNothing);
      expect(find.byKey(const ValueKey('mode-support_ticket')), findsNothing);

      await pumpSettings(const {NotificationType.announcement: NotificationMode.all, NotificationType.supportTicket: NotificationMode.off});
      expect(find.byKey(const ValueKey('mode-announcement')), findsOneWidget);
      expect(find.byKey(const ValueKey('mode-support_ticket')), findsOneWidget);
    });

    test('push links: a learning path, a member ticket and a console ticket', () {
      expect(pushLinkToPath('readin://paths/dotnet-backend'), '/paths/dotnet-backend');
      expect(pushLinkToPath('readin://support/0a1b2c3d-0000-0000-0000-000000000001'), '/settings/support/tickets/0a1b2c3d-0000-0000-0000-000000000001');
      expect(pushLinkToPath('readin://admin/support/t-1'), '/admin/tickets/t-1');
      expect(pushLinkToPath('readin://support/..%2Fsettings'), isNull);
      expect(pushLinkToPath('readin://admin/users/x'), isNull);
    });
  });

  testWidgets('the suspension screen shows the support email for an appeal', (tester) async {
    await pump(
      tester,
      const Scaffold(body: FailureBanner(failure: Failure(FailureCodes.userSuspended, statusCode: 403))),
    );

    expect(find.byKey(const ValueKey('support-appeal-note')), findsOneWidget);
    await tester.tap(find.text(en.contactSupport));
    await tester.pumpAndSettle();
    expect(find.text(en.supportAppealBody), findsOneWidget);
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/features/admin/domain/entities/paged_list.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/media/domain/repositories/media_picker.dart';
import 'package:readin/features/support/data/datasources/support_device_source.dart';
import 'package:readin/features/support/domain/entities/support.dart';
import 'package:readin/features/support/domain/entities/support_failures.dart';
import 'package:readin/features/support/domain/usecases/support_usecases.dart';
import 'package:readin/features/support/presentation/cubit/support_cubits.dart';

import '../../helpers/admin_fakes.dart';

class _MockPicker extends Mock implements MediaPicker {}

class _FixedDevice implements SupportDeviceSource {
  String? screen;

  @override
  Future<SupportDevice> read({String? screen}) async {
    this.screen = screen;
    return SupportDevice(platform: 'android', osVersion: 'Android 15', appVersion: '1.2.0+57', language: 'ar', screen: screen);
  }
}

void main() {
  late MockSupportRepository repository;
  late _MockPicker picker;
  late _FixedDevice device;

  const offline = Failure(FailureCodes.networkOffline);

  setUpAll(() {
    registerFallbackValue(const NewSupportTicket(category: SupportCategory.other, subject: '', message: ''));
    registerFallbackValue(MyTicketsFilter.active);
    registerFallbackValue(const AdminTicketQuery());
  });

  setUp(() {
    repository = MockSupportRepository();
    picker = _MockPicker();
    device = _FixedDevice();
  });

  group('GetSupportConfig', () {
    test('asks once per run; a failure is asked again', () async {
      when(() => repository.config()).thenAnswer((_) async => const Err(offline));
      final get = GetSupportConfig(repository);

      expect((await get()).isOk, isFalse);
      when(() => repository.config()).thenAnswer((_) async => const Ok(SupportConfig(email: 'help@readin.online')));
      expect((await get()).valueOrNull?.email, 'help@readin.online');
      await get();

      verify(() => repository.config()).called(2);
    });
  });

  group('NewTicketCubit', () {
    NewTicketCubit cubit() => NewTicketCubit(CreateSupportTicket(repository, device), picker);

    test('needs a category, a subject of 5–120 and a message of 10–2000 before it sends', () async {
      final form = cubit();

      final failure = await form.submit(screen: '/settings');

      expect(failure?.code, FailureCodes.validationFailed);
      expect(form.state.showErrors, isTrue);
      expect(form.state.categoryValid, isFalse);
      form
        ..setCategory(SupportCategory.appProblem)
        ..setSubject('Bug')
        ..setMessage('Too short');
      expect(form.state.subjectValid, isFalse);
      expect(form.state.messageValid, isFalse);
      form
        ..setSubject('  PDF crash  ')
        ..setMessage('The app closes when I open a PDF.');
      expect(form.state.isValid, isTrue);
      verifyNever(() => repository.create(any()));
      await form.close();
    });

    test('sends the ticket with the device details and the screen it came from', () async {
      final ticket = ticketOf(ticketSummary());
      when(() => repository.create(any())).thenAnswer((_) async => Ok(ticket));
      when(() => picker.pickImages(limit: 3)).thenAnswer((_) async => const [PickedMediaFile(path: '/a.png', name: 'a.png')]);
      final form = cubit()
        ..setCategory(SupportCategory.appProblem)
        ..setSubject('PDF crash')
        ..setMessage('The app closes when I open a PDF.');
      await form.pickScreenshots();

      final failure = await form.submit(screen: '/settings');

      expect(failure, isNull);
      expect(form.state.created, ticket);
      final sent = verify(() => repository.create(captureAny())).captured.single as NewSupportTicket;
      expect(sent.category, SupportCategory.appProblem);
      expect(sent.subject, 'PDF crash');
      expect(sent.screenshots.single.name, 'a.png');
      expect(sent.device.screen, '/settings');
      expect(sent.device.platform, 'android');
      await form.close();
    });

    test('up to 3 screenshots; the picker is asked only for what is left; one can be removed', () async {
      when(() => picker.pickImages(limit: any(named: 'limit'))).thenAnswer((i) async => [
            for (var n = 0; n < (i.namedArguments[#limit] as int); n++) PickedMediaFile(path: '/$n.png', name: '$n.png'),
          ]);
      final form = cubit();

      await form.pickScreenshots();
      expect(form.state.screenshots, hasLength(3));
      expect(form.state.canAddScreenshot, isFalse);
      await form.pickScreenshots();
      verify(() => picker.pickImages(limit: 3)).called(1);

      form.removeScreenshot(0);
      expect(form.state.screenshots, hasLength(2));
      await form.pickScreenshots();
      verify(() => picker.pickImages(limit: 1)).called(1);
      await form.close();
    });

    test('the limit is kept so the form can say which one', () async {
      when(() => repository.create(any())).thenAnswer((_) async => const Err(SupportLimitFailure(limit: SupportLimitKind.daily)));
      final form = cubit()
        ..setCategory(SupportCategory.other)
        ..setSubject('Hello there')
        ..setMessage('A question about the app.');

      final failure = await form.submit();

      expect(failure, isA<SupportLimitFailure>());
      expect(form.state.failure, const SupportLimitFailure(limit: SupportLimitKind.daily));
      expect(form.state.sending, isFalse);
      await form.close();
    });
  });

  group('MyTicketsCubit', () {
    test('one tab, then its next page', () async {
      when(() => repository.myTickets(MyTicketsFilter.closed, cursor: null, limit: 20))
          .thenAnswer((_) async => Ok(CursorPage(items: [ticketSummary(status: SupportStatus.closed)], nextCursor: 'n')));
      when(() => repository.myTickets(MyTicketsFilter.closed, cursor: 'n', limit: 20))
          .thenAnswer((_) async => Ok(CursorPage(items: [ticketSummary(id: 't-2', status: SupportStatus.closed)])));
      final cubit = MyTicketsCubit(GetMyTickets(repository), MyTicketsFilter.closed);

      await cubit.load();
      await cubit.loadMore();

      expect([for (final t in cubit.state.items) t.id], ['t-1', 't-2']);
      expect(cubit.state.hasMore, isFalse);
      await cubit.close();
    });
  });

  group('SupportTicketCubit', () {
    test('a reply is sent trimmed with its screenshots and the conversation is read again', () async {
      final summary = ticketSummary(status: SupportStatus.answered);
      when(() => repository.ticket('t-1')).thenAnswer((_) async => Ok(ticketOf(summary)));
      when(() => repository.reply('t-1', any(), screenshots: any(named: 'screenshots'))).thenAnswer(
        (_) async => Ok(SupportMessage(id: 'm-3', fromSupport: false, body: 'More', createdAt: adminNow)),
      );
      final cubit = SupportTicketCubit(MyTicketCommands(repository), 't-1');
      await cubit.load();

      final failure = await cubit.reply('  More  ', screenshots: const [PickedMediaFile(path: '/a.png', name: 'a.png')]);

      expect(failure, isNull);
      verify(() => repository.reply('t-1', 'More', screenshots: const [PickedMediaFile(path: '/a.png', name: 'a.png')])).called(1);
      verify(() => repository.ticket('t-1')).called(2);
      expect(cubit.state.busy, isNull);
      await cubit.close();
    });

    test('an empty reply is refused before sending', () async {
      when(() => repository.ticket('t-1')).thenAnswer((_) async => Ok(ticketOf(ticketSummary())));
      final cubit = SupportTicketCubit(MyTicketCommands(repository), 't-1');
      await cubit.load();

      expect((await cubit.reply('   '))?.code, FailureCodes.validationFailed);
      verifyNever(() => repository.reply(any(), any(), screenshots: any(named: 'screenshots')));
      await cubit.close();
    });

    test('close, then reopen; an expired reopen shows the ticket as it is', () async {
      var status = SupportStatus.open;
      when(() => repository.ticket('t-1')).thenAnswer((_) async => Ok(ticketOf(ticketSummary(status: status, canReopen: true))));
      when(() => repository.close('t-1')).thenAnswer((_) async {
        status = SupportStatus.closed;
        return const Ok(null);
      });
      when(() => repository.reopen('t-1')).thenAnswer((_) async => const Err(Failure(FailureCodes.supportReopenExpired)));
      final cubit = SupportTicketCubit(MyTicketCommands(repository), 't-1');
      await cubit.load();

      expect(await cubit.closeTicket(), isNull);
      expect(cubit.state.ticket!.summary.isClosed, isTrue);
      expect((await cubit.reopenTicket())?.code, FailureCodes.supportReopenExpired);
      expect(cubit.state.ticket!.summary.isClosed, isTrue);
      expect(cubit.state.busy, isNull);
      await cubit.close();
    });
  });

  group('AdminTicketCubit', () {
    test('a reply and an internal note go out with their flag; the ticket is read again', () async {
      when(() => repository.adminTicket('t-1')).thenAnswer((_) async => Ok(adminTicket()));
      when(() => repository.adminMessage('t-1', any(), internal: any(named: 'internal'))).thenAnswer(
        (_) async => Ok(SupportMessage(id: 'm-3', fromSupport: true, body: 'x', createdAt: adminNow)),
      );
      final cubit = AdminTicketCubit(AdminTicketCommands(repository), 't-1');
      await cubit.load();

      expect(await cubit.post(' Done ', internal: false), isNull);
      expect(await cubit.post('Check logs', internal: true), isNull);

      verify(() => repository.adminMessage('t-1', 'Done', internal: false)).called(1);
      verify(() => repository.adminMessage('t-1', 'Check logs', internal: true)).called(1);
      verify(() => repository.adminTicket('t-1')).called(3);
      await cubit.close();
    });

    test('close and change the category take the ticket the API answers; the same category is not sent', () async {
      when(() => repository.adminTicket('t-1')).thenAnswer((_) async => Ok(adminTicket()));
      when(() => repository.adminUpdate('t-1', status: SupportStatus.closed)).thenAnswer((_) async => Ok(adminTicket(status: SupportStatus.closed)));
      final cubit = AdminTicketCubit(AdminTicketCommands(repository), 't-1');
      await cubit.load();

      expect(await cubit.setCategory(SupportCategory.appProblem), isNull);
      verifyNever(() => repository.adminUpdate(any(), category: any(named: 'category')));

      expect(await cubit.closeTicket(), isNull);
      expect(cubit.state.ticket!.row.status, SupportStatus.closed);
      expect(cubit.state.busy, isNull);
      await cubit.close();
    });

    test('a reply to a closed ticket is refused by the API and the ticket is read again', () async {
      when(() => repository.adminTicket('t-1')).thenAnswer((_) async => Ok(adminTicket(status: SupportStatus.closed)));
      when(() => repository.adminMessage('t-1', any(), internal: false))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.supportTicketClosed)));
      final cubit = AdminTicketCubit(AdminTicketCommands(repository), 't-1');
      await cubit.load();

      final failure = await cubit.post('Hello', internal: false);

      expect(failure?.code, FailureCodes.supportTicketClosed);
      verify(() => repository.adminTicket('t-1')).called(2);
      await cubit.close();
    });
  });

  group('AdminTicketsCubit', () {
    test('the status tab, the category and the search start again from page 1', () async {
      when(() => repository.adminTickets(any(), page: 1, pageSize: 50))
          .thenAnswer((_) async => Ok(PagedList(items: [adminTicketRow()], totalCount: 1, totalPages: 1)));
      final cubit = AdminTicketsCubit(GetAdminTickets(repository), null);
      await cubit.load();

      const query = AdminTicketQuery(status: SupportStatus.closed, category: SupportCategory.account, q: '#12');
      await cubit.setQuery(query);

      verify(() => repository.adminTickets(const AdminTicketQuery(), page: 1, pageSize: 50)).called(1);
      verify(() => repository.adminTickets(query, page: 1, pageSize: 50)).called(1);
      await cubit.close();
    });
  });

  group('SupportAttachmentCache', () {
    test('reads each image once; a failure is read again', () async {
      when(() => repository.attachment('a-1')).thenAnswer((_) async => Ok(Uint8List.fromList([1])));
      when(() => repository.attachment('a-2')).thenAnswer((_) async => const Err(offline));
      final cache = SupportAttachmentCache(LoadSupportAttachment(repository));

      await cache.get('a-1');
      await cache.get('a-1');
      await cache.get('a-2');
      await Future<void>.delayed(Duration.zero);
      await cache.get('a-2');

      verify(() => repository.attachment('a-1')).called(1);
      verify(() => repository.attachment('a-2')).called(2);
    });
  });
}

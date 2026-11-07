import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/media/data/datasources/image_compressor.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/support/data/datasources/support_api.dart';
import 'package:readin/features/support/data/datasources/support_attachment_data_source.dart';
import 'package:readin/features/support/data/repositories/support_repository_impl.dart';
import 'package:readin/features/support/domain/entities/support.dart';
import 'package:readin/features/support/domain/entities/support_failures.dart';

import '../../helpers/fake_auth.dart';

/// No image engine in unit tests: every screenshot is sent as picked.
class _NoCompression extends ImageCompressor {
  @override
  Future<Uint8List?> compress(String path) async => null;
}

/// Help & support (F35, docs/api/contract-v1.md "Support"): method, path, query, body (multipart for the member's
/// messages), and how the answers parse.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late Dio dio;
  late Directory temp;

  setUp(() {
    requests = [];
    respond = (_) => null;
    dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = ScriptedAdapter((options) {
        requests.add(options);
        final body = respond(options);
        if (body is (int, Object?)) return body;
        return (200, body);
      });
    temp = Directory.systemTemp.createTempSync('support-test');
  });

  // The multipart body still holds the files open on Windows (the scripted server never reads it).
  tearDown(() {
    try {
      temp.deleteSync(recursive: true);
    } on FileSystemException {
      // left for the OS to clean
    }
  });

  String call(int i) => '${requests[i].method} ${requests[i].uri.path.replaceFirst('/api/v1', '')}';
  Map<String, String> query(int i) => requests[i].uri.queryParameters;

  SupportRepositoryImpl repository() =>
      SupportRepositoryImpl(SupportApi(dio), SupportAttachmentDataSource(dio), _NoCompression());

  PickedMediaFile picked(String name) {
    final file = File('${temp.path}${Platform.pathSeparator}$name')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
    return PickedMediaFile(path: file.path, name: name, sizeBytes: 4);
  }

  const author = {'id': 'u-110', 'displayName': 'Youssef', 'username': 'reader1', 'avatarUrl': null, 'isVerified': false};

  Map<String, Object?> ticketJson({String status = 'open', List<Object?> messages = const []}) => {
        'id': 't-1',
        'number': 12,
        'category': 'app_problem',
        'subject': 'PDF crash',
        'status': status,
        'createdAt': '2026-11-06T10:00:00Z',
        'updatedAt': '2026-11-07T09:00:00Z',
        'lastMessage': {'fromSupport': true, 'excerpt': 'On it', 'createdAt': '2026-11-07T09:00:00Z'},
        'closedAt': status == 'closed' ? '2026-11-07T10:00:00Z' : null,
        'canReopen': status == 'closed',
        'device': {'platform': 'android', 'osVersion': 'Android 15', 'appVersion': '1.2.0+57', 'language': 'ar', 'screen': '/settings'},
        'messages': messages,
      };

  test('GET /support/config: the email and the categories in order; unknown categories are skipped', () async {
    respond = (_) => {
          'email': 'support@readin.online',
          'categories': ['account', 'app_problem', 'refund'],
          'maxAttachments': 3,
          'maxAttachmentBytes': 5242880,
          'attachmentTypes': ['image/jpeg'],
        };

    final config = (await repository().config()).valueOrNull!;

    expect(call(0), 'GET /support/config');
    expect(config.email, 'support@readin.online');
    expect(config.categories, [SupportCategory.account, SupportCategory.appProblem]);
  });

  test('a blank email is none', () async {
    respond = (_) => {'email': '  ', 'categories': <String>[]};

    final config = (await repository().config()).valueOrNull!;

    expect(config.email, isNull);
    expect(config.categories, SupportCategory.values, reason: 'every category when the API lists none');
  });

  group('POST /support/tickets', () {
    test('multipart: the ticket, the device details and the screenshots in order', () async {
      respond = (_) => (201, ticketJson());

      final ticket = (await repository().create(NewSupportTicket(
        category: SupportCategory.appProblem,
        subject: '  PDF crash  ',
        message: '  The app closes when I open a PDF.  ',
        screenshots: [picked('a.png'), picked('b.jpg')],
        device: const SupportDevice(platform: 'android', osVersion: 'Android 15', appVersion: '1.2.0+57', language: 'ar', screen: '/settings'),
      )))
          .valueOrNull!;

      expect(call(0), 'POST /support/tickets');
      final form = requests[0].data as FormData;
      expect(Map.fromEntries(form.fields), {
        'category': 'app_problem',
        'subject': 'PDF crash',
        'message': 'The app closes when I open a PDF.',
        'platform': 'android',
        'osVersion': 'Android 15',
        'appVersion': '1.2.0+57',
        'language': 'ar',
        'screen': '/settings',
      });
      expect([for (final f in form.files) f.key], ['screenshots', 'screenshots']);
      expect([for (final f in form.files) f.value.filename], ['a.png', 'b.jpg']);
      expect([for (final f in form.files) f.value.contentType?.mimeType], ['image/png', 'image/jpeg']);
      expect(ticket.summary.number, 12);
      expect(ticket.device.osVersion, 'Android 15');
    });

    test('without screenshots or device details, those parts are left out', () async {
      respond = (_) => (201, ticketJson());

      await repository().create(const NewSupportTicket(category: SupportCategory.other, subject: 'Hello', message: 'A question here'));

      final form = requests[0].data as FormData;
      expect([for (final f in form.fields) f.key], ['category', 'subject', 'message']);
      expect(form.files, isEmpty);
    });

    test('429 support.limit says which limit', () async {
      respond = (_) => (429, {'status': 429, 'code': 'support.limit', 'limit': 'open', 'title': 'Too many'});

      final failure = (await repository().create(const NewSupportTicket(category: SupportCategory.other, subject: 'Hello', message: 'A question here')))
          .failureOrNull;

      expect(failure, isA<SupportLimitFailure>());
      expect(failure?.code, FailureCodes.supportLimit);
      expect((failure! as SupportLimitFailure).limit, SupportLimitKind.open);
    });

    test('a screenshot the server refuses keeps its code', () async {
      respond = (_) => (400, {'status': 400, 'code': 'support.attachment_invalid'});

      final failure = (await repository().create(
        NewSupportTicket(category: SupportCategory.other, subject: 'Hello', message: 'A question here', screenshots: [picked('x.heic')]),
      ))
          .failureOrNull;

      expect(failure?.code, FailureCodes.supportAttachmentInvalid);
    });

    test('a picked file that is gone is an invalid screenshot, before anything is sent', () async {
      final failure = (await repository().create(
        const NewSupportTicket(
          category: SupportCategory.other,
          subject: 'Hello',
          message: 'A question here',
          screenshots: [PickedMediaFile(path: '/nowhere/x.png', name: 'x.png')],
        ),
      ))
          .failureOrNull;

      expect(failure?.code, FailureCodes.supportAttachmentInvalid);
      expect(requests, isEmpty);
    });
  });

  test('GET /me/support/tickets: the tab, the cursor and the limit', () async {
    respond = (_) => {
          'items': [ticketJson(status: 'answered')],
          'nextCursor': 'n2',
        };

    final page = (await repository().myTickets(MyTicketsFilter.active, cursor: 'c1')).valueOrNull!;

    expect(call(0), 'GET /me/support/tickets');
    expect(query(0), {'status': 'active', 'cursor': 'c1', 'limit': '20'});
    expect(page.items.single.status, SupportStatus.answered);
    expect(page.items.single.lastMessage.fromSupport, isTrue);
    expect(page.nextCursor, 'n2');
  });

  test('a ticket, a reply with a screenshot, close and reopen', () async {
    respond = (options) => switch ((options.method, options.path)) {
          ('GET', '/support/tickets/t-1') => ticketJson(
              status: 'closed',
              messages: [
                {
                  'id': 'm-1',
                  'fromSupport': false,
                  'body': 'Crash',
                  'attachments': [
                    {'id': 'att-1', 'contentType': 'image/png', 'sizeBytes': 1000},
                  ],
                  'createdAt': '2026-11-06T10:00:00Z',
                },
              ],
            ),
          ('POST', '/support/tickets/t-1/messages') => (
              201,
              {'id': 'm-2', 'fromSupport': false, 'body': 'More', 'attachments': <Object>[], 'createdAt': '2026-11-07T10:00:00Z'},
            ),
          _ => (204, null),
        };

    final ticket = (await repository().ticket('t-1')).valueOrNull!;
    final message = (await repository().reply('t-1', ' More ', screenshots: [picked('c.webp')])).valueOrNull!;
    await repository().close('t-1');
    await repository().reopen('t-1');

    expect(ticket.summary.isClosed, isTrue);
    expect(ticket.summary.canReopen, isTrue);
    expect(ticket.messages.single.attachments.single.id, 'att-1');
    expect(call(1), 'POST /support/tickets/t-1/messages');
    final form = requests[1].data as FormData;
    expect(Map.fromEntries(form.fields), {'message': 'More'});
    expect(form.files.single.value.contentType?.mimeType, 'image/webp');
    expect(message.id, 'm-2');
    expect(call(2), 'POST /support/tickets/t-1/close');
    expect(call(3), 'POST /support/tickets/t-1/reopen');
  });

  test('GET /support/attachments/{id} reads the bytes with the session', () async {
    respond = (_) => [1, 2, 3];

    final bytes = (await repository().attachment('att-1')).valueOrNull;

    expect(call(0), 'GET /support/attachments/att-1');
    expect(requests[0].responseType, ResponseType.bytes);
    expect(bytes, isNotNull);
  });

  group('the console (support.manage)', () {
    Map<String, Object?> adminJson({String status = 'open'}) => {
          'id': 't-1',
          'number': 12,
          'category': 'account',
          'subject': 'Locked out',
          'status': status,
          'user': author,
          'createdAt': '2026-11-06T10:00:00Z',
          'waitingSince': status == 'open' ? '2026-11-06T10:00:00Z' : null,
          'lastMessage': {'fromSupport': true, 'isInternalNote': true, 'excerpt': 'Check logs', 'createdAt': '2026-11-06T11:00:00Z'},
          'closedAt': null,
          'device': {'platform': 'ios', 'osVersion': 'iOS 18.1', 'appVersion': '1.2.0', 'language': 'en', 'screen': null},
          'messages': [
            {
              'id': 'm-2',
              'fromSupport': true,
              'isInternalNote': true,
              'author': {'id': 'u-super', 'displayName': 'Super Admin', 'username': 'superadmin'},
              'body': 'Check logs',
              'attachments': <Object>[],
              'createdAt': '2026-11-06T11:00:00Z',
            },
          ],
          'closedBy': null,
          'member': {
            'status': 'suspended',
            'suspendedUntil': null,
            'joinedAt': '2026-09-01T00:00:00Z',
            'signInMethods': ['phone'],
            'ticketCount': 3,
          },
          'reportsFiled': {'items': <Object>[], 'total': 0},
          'reportsAgainst': 2,
          'moderation': [
            {'id': 'h-1', 'action': 'user.suspend', 'note': 'Spam', 'suspendedUntil': null, 'createdAt': '2026-11-01T00:00:00Z'},
          ],
        };

    test('the queue: status, category, search and page in the query', () async {
      respond = (_) => {
            'items': [adminJson()],
            'page': 1,
            'pageSize': 50,
            'totalCount': 1,
            'totalPages': 1,
          };

      final page = (await repository().adminTickets(
        const AdminTicketQuery(status: SupportStatus.answered, category: SupportCategory.account, q: ' #12 '),
      ))
          .valueOrNull!;

      expect(call(0), 'GET /admin/support/tickets');
      expect(query(0), {'status': 'answered', 'category': 'account', 'q': '#12', 'page': '1', 'pageSize': '50'});
      expect(page.items.single.waitingSince, DateTime.utc(2026, 11, 6, 10));
      expect(page.items.single.lastMessage.isInternalNote, isTrue);
    });

    test('a ticket with notes, the member card and history; a reply and a note; close and change the category', () async {
      respond = (options) => switch ((options.method, options.path)) {
            ('POST', _) => (
                201,
                {'id': 'm-3', 'fromSupport': true, 'isInternalNote': false, 'body': 'Done', 'attachments': <Object>[], 'createdAt': '2026-11-07T10:00:00Z'},
              ),
            ('PATCH', _) => adminJson(status: 'closed'),
            _ => adminJson(),
          };

      final ticket = (await repository().adminTicket('t-1')).valueOrNull!;
      await repository().adminMessage('t-1', '  Done  ', internal: false);
      await repository().adminMessage('t-1', 'Note', internal: true);
      final closed = (await repository().adminUpdate('t-1', status: SupportStatus.closed)).valueOrNull!;
      await repository().adminUpdate('t-1', category: SupportCategory.content);

      expect(call(0), 'GET /admin/support/tickets/t-1');
      expect(ticket.messages.single.isInternalNote, isTrue);
      expect(ticket.messages.single.author?.username, 'superadmin');
      expect(ticket.member.suspended, isTrue);
      expect(ticket.member.ticketCount, 3);
      expect(ticket.reportsAgainst, 2);
      expect(ticket.moderation!.single.action, 'user.suspend');
      expect(call(1), 'POST /admin/support/tickets/t-1/messages');
      expect(requests[1].data, {'body': 'Done', 'internal': false});
      expect(requests[2].data, {'body': 'Note', 'internal': true});
      expect(call(3), 'PATCH /admin/support/tickets/t-1');
      expect(requests[3].data, {'status': 'closed'});
      expect(requests[4].data, {'category': 'content'});
      expect(closed.row.status, SupportStatus.closed);
    });
  });
}

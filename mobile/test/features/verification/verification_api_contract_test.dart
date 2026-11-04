import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/verification/data/datasources/verification_api.dart';
import 'package:readin/features/verification/data/repositories/verification_repository_impl.dart';
import 'package:readin/features/verification/domain/entities/verification.dart';

import '../../helpers/fake_auth.dart';

/// Every requester endpoint of writer verification (F19) against the contract: method, path, the multipart parts
/// (exactly `fieldId`, `jobTitle`, `proofUrl`, `note`, `proof`), and how the answers and errors parse.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late Dio dio;
  late Directory temp;

  setUp(() {
    requests = [];
    respond = (_) => null;
    dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = _DrainingAdapter((options) {
        requests.add(options);
        final body = respond(options);
        if (body is (int, Object?)) return body;
        return (200, body);
      });
    temp = Directory.systemTemp.createTempSync('readin-verification-');
  });
  tearDown(() => temp.deleteSync(recursive: true));

  String call(int i) => '${requests[i].method} ${requests[i].uri.path.replaceFirst('/api/v1', '')}';

  VerificationRepositoryImpl repository() => VerificationRepositoryImpl(VerificationApi(dio));

  Map<String, dynamic> problem(int status, String code, {Map<String, List<String>>? errors}) =>
      {'status': status, 'code': code, 'title': 'error', 'errors': ?errors};

  Map<String, dynamic> requestJson({String status = 'pending', Map<String, dynamic> extra = const {}}) => {
        'id': 'vr-1',
        'status': status,
        'field': {'id': 'f-dotnet', 'slug': 'dotnet', 'name': '.NET'},
        'jobTitle': 'Senior Backend Engineer',
        'proofUrl': 'https://www.linkedin.com/in/youssef-hassan',
        'proofFileName': 'card.pdf',
        'note': null,
        'submittedAt': '2026-11-02T09:30:00Z',
        'decidedAt': null,
        'rejectionReason': null,
        ...extra,
      };

  PickedMediaFile file(String name, List<int> bytes) {
    final f = File('${temp.path}${Platform.pathSeparator}$name')..writeAsBytesSync(bytes);
    return PickedMediaFile(path: f.path, name: name, sizeBytes: bytes.length);
  }

  group('GET /me/verification', () {
    test('nothing requested yet: not verified, may request, no request', () async {
      respond = (_) => {'isVerified': false, 'canRequest': true, 'request': null};
      final status = (await repository().getStatus()).valueOrNull!;
      expect(call(0), 'GET /me/verification');
      expect(status, VerificationStatus.none);
    });

    test('reads every field of the latest request (a rejected one)', () async {
      respond = (_) => {
            'isVerified': false,
            'canRequest': true,
            'request': requestJson(status: 'rejected', extra: {
              'proofFileName': null,
              'note': 'Writing about .NET since 2019',
              'decidedAt': '2026-11-03T14:00:00Z',
              'rejectionReason': 'The LinkedIn link does not open.',
            }),
          };
      final status = (await repository().getStatus()).valueOrNull!;
      expect(status.isVerified, isFalse);
      expect(status.canRequest, isTrue);
      expect(
        status.request,
        VerificationRequest(
          id: 'vr-1',
          status: VerificationRequestStatus.rejected,
          field: const VerificationField(id: 'f-dotnet', slug: 'dotnet', name: '.NET'),
          jobTitle: 'Senior Backend Engineer',
          proofUrl: 'https://www.linkedin.com/in/youssef-hassan',
          note: 'Writing about .NET since 2019',
          submittedAt: DateTime.utc(2026, 11, 2, 9, 30),
          decidedAt: DateTime.utc(2026, 11, 3, 14),
          rejectionReason: 'The LinkedIn link does not open.',
        ),
      );
      expect(status.pending, isNull);
    });

    test('verified, and a pending request; an unknown status is kept as unknown', () async {
      respond = (_) => {'isVerified': true, 'canRequest': false, 'request': requestJson(status: 'approved')};
      final approved = (await repository().getStatus()).valueOrNull!;
      expect((approved.isVerified, approved.canRequest), (true, false));
      expect(approved.request!.status, VerificationRequestStatus.approved);

      respond = (_) => {'isVerified': false, 'canRequest': false, 'request': requestJson()};
      final pending = (await repository().getStatus()).valueOrNull!;
      expect(pending.pending?.id, 'vr-1');
      expect(pending.request!.proofFileName, 'card.pdf');

      respond = (_) => {'isVerified': false, 'canRequest': true, 'request': requestJson(status: 'escalated')};
      expect((await repository().getStatus()).valueOrNull!.request!.status, VerificationRequestStatus.unknown);
    });

    test('a failure is a Failure', () async {
      respond = (_) => (401, problem(401, 'auth.unauthorized'));
      expect((await repository().getStatus()).failureOrNull?.code, FailureCodes.authUnauthorized);
    });
  });

  group('POST /verification-requests', () {
    test('sends multipart/form-data with exactly fieldId, jobTitle, proofUrl, note and the proof file', () async {
      respond = (_) => (201, requestJson());
      final proof = file('card.pdf', '%PDF-1.7\n%test'.codeUnits);
      final request = (await repository().submit(VerificationSubmission(
        fieldId: 'f-dotnet',
        jobTitle: 'Senior Backend Engineer',
        proofUrl: 'https://www.linkedin.com/in/youssef-hassan',
        note: 'بكتب عن الـ .NET',
        proof: proof,
      )))
          .valueOrNull!;

      expect(call(0), 'POST /verification-requests');
      expect(requests[0].contentType, startsWith('multipart/form-data'));
      final form = requests[0].data as FormData;
      expect({for (final MapEntry(:key, :value) in form.fields) key: value}, {
        'fieldId': 'f-dotnet',
        'jobTitle': 'Senior Backend Engineer',
        'proofUrl': 'https://www.linkedin.com/in/youssef-hassan',
        'note': 'بكتب عن الـ .NET',
      });
      expect(form.fields.map((e) => e.key), hasLength(4), reason: 'each part once');
      expect(form.files.map((e) => e.key), ['proof']);
      final part = form.files.single.value;
      expect(part.filename, 'card.pdf');
      expect(part.contentType.toString(), 'application/pdf');
      expect(part.length, 14);

      expect(request.id, 'vr-1');
      expect(request.isPending, isTrue);
      expect(request.field.name, '.NET');
    });

    test('leaves out the parts that are not set: a link alone', () async {
      respond = (_) => (201, requestJson(extra: {'proofFileName': null}));
      await repository().submit(const VerificationSubmission(fieldId: 'f-ai', jobTitle: 'ML Engineer', proofUrl: 'https://github.com/mona'));
      final form = requests[0].data as FormData;
      expect(form.fields.map((e) => e.key), ['fieldId', 'jobTitle', 'proofUrl']);
      expect(form.files, isEmpty);
    });

    test('a file alone, with the content type of its kind', () async {
      for (final (name, type) in [('card.png', 'image/png'), ('card.JPG', 'image/jpeg'), ('card.webp', 'image/webp')]) {
        requests.clear();
        respond = (_) => (201, requestJson());
        await repository().submit(VerificationSubmission(fieldId: 'f-ai', jobTitle: 'ML Engineer', proof: file(name, [1, 2, 3])));
        final form = requests[0].data as FormData;
        expect(form.fields.map((e) => e.key), ['fieldId', 'jobTitle'], reason: name);
        expect(form.files.single.key, 'proof');
        expect(form.files.single.value.contentType.toString(), type, reason: name);
      }
    });

    test('a picked file that is gone is a proof to pick again, without a request', () async {
      final result = await repository().submit(VerificationSubmission(
        fieldId: 'f-ai',
        jobTitle: 'ML Engineer',
        proof: PickedMediaFile(path: '${temp.path}${Platform.pathSeparator}missing.pdf', name: 'missing.pdf', sizeBytes: 10),
      ));
      expect(result.failureOrNull?.code, FailureCodes.verificationProofInvalid);
      expect(requests, isEmpty);
    });

    test('maps the errors of the contract', () async {
      const submission = VerificationSubmission(fieldId: 'f-ai', jobTitle: 'ML Engineer', proofUrl: 'https://github.com/mona');
      for (final (status, code) in [
        (400, FailureCodes.verificationProofRequired),
        (400, FailureCodes.verificationFieldInvalid),
        (400, FailureCodes.verificationProofInvalid),
        (409, FailureCodes.verificationAlreadyPending),
        (409, FailureCodes.verificationAlreadyVerified),
        (403, FailureCodes.userSuspended),
      ]) {
        respond = (_) => (status, problem(status, code));
        final failure = (await repository().submit(submission)).failureOrNull!;
        expect((failure.statusCode, failure.code), (status, code));
      }

      respond = (_) => (
            400,
            problem(400, FailureCodes.validationFailed, errors: {
              'jobTitle': ['validation.max_length'],
              'proofUrl': ['validation.url'],
            }),
          );
      final failure = (await repository().submit(submission)).failureOrNull!;
      expect(failure.code, FailureCodes.validationFailed);
      expect(failure.fieldErrors, {
        'jobTitle': ['validation.max_length'],
        'proofUrl': ['validation.url'],
      });
    });
  });

  group('DELETE /me/verification', () {
    test('withdraws the pending request (204)', () async {
      respond = (_) => (204, null);
      expect((await repository().withdraw()).isOk, isTrue);
      expect(call(0), 'DELETE /me/verification');
    });

    test('none pending is 404 verification.not_found', () async {
      respond = (_) => (404, problem(404, FailureCodes.verificationNotFound));
      expect((await repository().withdraw()).failureOrNull?.code, FailureCodes.verificationNotFound);
    });
  });
}

/// [ScriptedAdapter] that reads the request body like a server would, so the proof file is read (and closed).
class _DrainingAdapter extends ScriptedAdapter {
  _DrainingAdapter(super.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    await requestStream?.drain<void>();
    return super.fetch(options, requestStream, cancelFuture);
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/network/api_error_mapper.dart';
import 'package:readin/core/network/interceptors.dart';
import 'package:readin/core/network/request_context.dart';
import 'package:readin/core/platform/share_service.dart';
import 'package:readin/features/article_pdf/data/datasources/article_pdf_data_source.dart';
import 'package:readin/features/article_pdf/data/repositories/article_pdf_repository_impl.dart';
import 'package:readin/features/article_pdf/domain/entities/article_pdf.dart';
import 'package:readin/features/article_pdf/domain/repositories/article_pdf_repository.dart';
import 'package:readin/features/article_pdf/domain/usecases/download_article_pdf.dart';
import 'package:readin/features/article_pdf/presentation/cubit/article_pdf_cubit.dart';
import 'package:readin/features/article_pdf/presentation/widgets/article_pdf_widgets.dart';

/// A PDF's first bytes.
final _pdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.7\n%âãÏÓ\n1 0 obj\n<<>>\nendobj\n%%EOF\n'));

/// Answers every request with [handler]'s response; records the requests.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options.copyWith(headers: {...options.headers})); // a retry mutates the same options
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _pdf(List<int> bytes, {String? disposition}) => ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/pdf'],
        if (disposition != null) 'content-disposition': [disposition],
      },
    );

ResponseBody _problem(int status, String code) => ResponseBody.fromString(
      jsonEncode({'type': 'about:blank', 'title': 'Problem', 'status': status, 'code': code}),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/problem+json; charset=utf-8'],
      },
    );

class _FakeRepository implements ArticlePdfRepository {
  final calls = <(String, String)>[];
  Completer<Result<ArticlePdf>>? pending;
  Result<ArticlePdf> answer = const Ok(ArticlePdf(path: '/tmp/article-pdf/clean-code-en.pdf', fileName: 'clean-code-en.pdf'));

  @override
  Future<Result<ArticlePdf>> download(String articleId, {required String language}) {
    calls.add((articleId, language));
    return pending?.future ?? Future.value(answer);
  }
}

/// Signed in with `a1`; a refresh gives `a2`.
class _Tokens implements SessionTokenProvider {
  String? current = 'a1';
  final suspended = <Failure>[];

  @override
  Future<String?> accessToken() async => current;

  @override
  Future<String?> refreshAfterRejection(String token) async => current = 'a2';

  @override
  Future<void> endSuspended(Failure reason) async {
    suspended.add(reason);
    current = null;
  }
}

class _RecordingShare extends ShareService {
  final files = <({String path, String mimeType, String? fileName, Rect? origin})>[];
  bool fail = false;

  @override
  Future<void> shareFile(String path, {required String mimeType, String? fileName, Rect? origin}) async {
    files.add((path: path, mimeType: mimeType, fileName: fileName, origin: origin));
    if (fail) throw Exception('no share sheet');
  }
}

void main() {
  group('the file name from Content-Disposition (F33)', () {
    String name(String? header) => ArticlePdfFileName.fromContentDisposition(header);

    test('takes the RFC 5987 filename*', () {
      expect(name('''attachment; filename="readin-article.pdf"; filename*=UTF-8''clean-code-en.pdf'''), 'clean-code-en.pdf');
    });

    test('percent-decodes an Arabic slug', () {
      final encoded = Uri.encodeComponent('الذكاء-الاصطناعي-ar-EG.pdf');
      expect(name('''attachment; filename="readin-article.pdf"; filename*=UTF-8''$encoded'''), 'الذكاء-الاصطناعي-ar-EG.pdf');
      expect(name('''attachment; filename*=utf-8'ar'$encoded'''), 'الذكاء-الاصطناعي-ar-EG.pdf');
    });

    test('falls back to filename, then to readin-article.pdf', () {
      expect(name('attachment; filename="readin-article.pdf"'), 'readin-article.pdf');
      expect(name('attachment; filename=other.pdf'), 'other.pdf');
      // A filename* that doesn't decode, or isn't UTF-8.
      expect(name('''attachment; filename="readin-article.pdf"; filename*=UTF-8''%E0%A4%A.pdf'''), 'readin-article.pdf');
      expect(name('''attachment; filename="readin-article.pdf"; filename*=ISO-8859-1''caf%E9.pdf'''), 'readin-article.pdf');
      expect(name('attachment'), ArticlePdfFileName.fallback);
      expect(name(''), ArticlePdfFileName.fallback);
      expect(name(null), ArticlePdfFileName.fallback);
    });

    test('is always a safe .pdf name', () {
      expect(name('''attachment; filename*=UTF-8''..%2F..%2Fetc%2Fpasswd'''), '_.._etc_passwd.pdf');
      expect(name('''attachment; filename*=UTF-8''report'''), 'report.pdf');
      expect(name('''attachment; filename*=UTF-8''a%3Ab%2A%3F.PDF'''), 'a_b__.pdf');
      expect(name('''attachment; filename*=UTF-8''%2E%2E'''), ArticlePdfFileName.fallback);
    });

    test('a very long slug is shortened but keeps its language', () {
      final slug = List.filled(200, 'ذ').join();
      final result = name("attachment; filename*=UTF-8''${Uri.encodeComponent('$slug-ar-EG.pdf')}");
      expect(utf8.encode(result).length, lessThanOrEqualTo(240));
      expect(result, endsWith('ذ-ar-EG.pdf'));
    });
  });

  group('GET /articles/{id}/pdf (F33)', () {
    late Directory temp;
    late _Adapter adapter;
    late ArticlePdfRepositoryImpl repository;
    late FutureOr<ResponseBody> Function(RequestOptions) respond;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('readin-pdf-test');
      respond = (_) => _pdf(_pdfBytes, disposition: '''attachment; filename="readin-article.pdf"; filename*=UTF-8''clean-code-en.pdf''');
      adapter = _Adapter((options) => respond(options));
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1', receiveTimeout: const Duration(seconds: 20)))..httpClientAdapter = adapter;
      repository = ArticlePdfRepositoryImpl(ArticlePdfDataSource(dio, temporaryDirectory: () async => temp));
    });

    tearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    test('asks for the version in lang, waits at least 100 s, and saves the file under the server name', () async {
      final pdf = (await repository.download('art 1', language: 'en')).valueOrNull!;

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/v1/articles/art%201/pdf');
      expect(request.uri.queryParameters, {'lang': 'en'});
      expect(request.responseType, ResponseType.bytes);
      expect(request.receiveTimeout, greaterThanOrEqualTo(const Duration(seconds: 100)));
      expect(request.headers[Headers.acceptHeader], contains('application/problem+json'));

      expect(pdf.fileName, 'clean-code-en.pdf');
      expect(pdf.path, '${temp.path}${Platform.pathSeparator}article-pdf${Platform.pathSeparator}clean-code-en.pdf');
      expect(await File(pdf.path).readAsBytes(), _pdfBytes);
    });

    test('an Arabic slug names the file; a second download of it replaces the first', () async {
      final encoded = Uri.encodeComponent('الذكاء-الاصطناعي-ar-EG.pdf');
      respond = (_) => _pdf(_pdfBytes, disposition: '''attachment; filename="readin-article.pdf"; filename*=UTF-8''$encoded''');
      await repository.download('art-2', language: 'ar-EG');
      final pdf = (await repository.download('art-2', language: 'ar-EG')).valueOrNull!;
      expect(pdf.fileName, 'الذكاء-الاصطناعي-ar-EG.pdf');
      expect(await File(pdf.path).readAsBytes(), _pdfBytes);
    });

    test('no Content-Disposition: readin-article.pdf', () async {
      respond = (_) => _pdf(_pdfBytes);
      expect((await repository.download('art-1', language: 'en')).valueOrNull!.fileName, 'readin-article.pdf');
    });

    for (final (status, code) in [
      (404, FailureCodes.articleNotFound),
      (409, FailureCodes.articlePdfHidden),
      (429, FailureCodes.articlePdfLimit),
      (503, FailureCodes.articlePdfBusy),
      (500, FailureCodes.articlePdfFailed),
      (403, FailureCodes.userSuspended),
    ]) {
      test('$status $code reads the ProblemDetails code', () async {
        respond = (_) => _problem(status, code);
        final failure = (await repository.download('art-1', language: 'en')).failureOrNull!;
        expect(failure.code, code);
        expect(failure.statusCode, status);
        expect(Directory('${temp.path}${Platform.pathSeparator}article-pdf').existsSync(), isFalse);
      });
    }

    test('a 429 without a body is still the rate limit', () async {
      respond = (_) => ResponseBody.fromBytes(const [], 429);
      expect((await repository.download('art-1', language: 'en')).failureOrNull!.code, FailureCodes.rateLimited);
    });

    test('an answer that is not a PDF fails', () async {
      respond = (_) => ResponseBody.fromString('<html>proxy</html>', 200, headers: {
            Headers.contentTypeHeader: ['text/html'],
          });
      expect((await repository.download('art-1', language: 'en')).failureOrNull!.code, FailureCodes.serverError);
    });

    test('offline and timeouts', () async {
      respond = (options) => throw DioException.connectionError(requestOptions: options, reason: 'offline');
      expect((await repository.download('art-1', language: 'en')).failureOrNull!.code, FailureCodes.networkOffline);
      respond = (options) => throw DioException.receiveTimeout(timeout: const Duration(seconds: 110), requestOptions: options);
      expect((await repository.download('art-1', language: 'en')).failureOrNull!.code, FailureCodes.networkTimeout);
    });

    test('a 401 refreshes once and gets the PDF; a 403 user.suspended ends the session (F22)', () async {
      final tokens = _Tokens();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))..httpClientAdapter = adapter;
      dio.interceptors.add(AuthInterceptor(tokens, dio));
      final signedIn = ArticlePdfRepositoryImpl(ArticlePdfDataSource(dio, temporaryDirectory: () async => temp));

      respond = (options) => options.headers['Authorization'] == 'Bearer a1'
          ? _problem(401, FailureCodes.authUnauthorized)
          : _pdf(_pdfBytes, disposition: "attachment; filename*=UTF-8''clean-code-en.pdf");
      final pdf = (await signedIn.download('art-1', language: 'en')).valueOrNull!;
      expect(pdf.fileName, 'clean-code-en.pdf');
      expect(adapter.requests.map((r) => r.headers['Authorization']), ['Bearer a1', 'Bearer a2']);
      expect(adapter.requests.last.responseType, ResponseType.bytes);

      respond = (_) => _problem(403, FailureCodes.userSuspended);
      final failure = (await signedIn.download('art-1', language: 'en')).failureOrNull!;
      expect(failure.code, FailureCodes.userSuspended);
      expect(tokens.suspended.single.code, FailureCodes.userSuspended);
    });

    test('ProblemDetails in a bytes body read like JSON ones', () {
      final body = utf8.encode(jsonEncode({'status': 409, 'code': 'article.pdf_hidden'}));
      expect(ApiErrorMapper.fromProblem(409, body), const Failure(FailureCodes.articlePdfHidden, statusCode: 409));
      expect(ApiErrorMapper.fromProblem(500, utf8.encode('<html>')), const Failure(FailureCodes.serverError, statusCode: 500));
      expect(ApiErrorMapper.fromProblem(429, const <int>[]), const Failure(FailureCodes.rateLimited, statusCode: 429));
    });

    test('a file that cannot be written: "couldn\'t prepare the PDF"', () async {
      final file = File('${temp.path}${Platform.pathSeparator}not-a-folder');
      await file.writeAsString('x');
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))..httpClientAdapter = adapter;
      final broken = ArticlePdfRepositoryImpl(ArticlePdfDataSource(dio, temporaryDirectory: () async => Directory(file.path)));
      expect((await broken.download('art-1', language: 'en')).failureOrNull!.code, FailureCodes.articlePdfFailed);
    });
  });

  group('ArticlePdfCubit', () {
    late _FakeRepository repository;
    late _RecordingShare share;
    late ArticlePdfCubit cubit;

    setUp(() {
      repository = _FakeRepository();
      share = _RecordingShare();
      cubit = ArticlePdfCubit(DownloadArticlePdf(repository), share);
    });

    tearDown(() => cubit.close());

    test('builds, then opens the share sheet with the PDF', () async {
      repository.pending = Completer();
      const origin = Rect.fromLTWH(10, 20, 100, 40);
      final done = cubit.download('art-1', language: 'en', origin: origin);
      expect(cubit.state.isBuilding('art-1'), isTrue);
      expect(cubit.state.isBuilding('art-2'), isFalse);

      // A second tap while it builds does nothing.
      await cubit.download('art-1', language: 'en');
      expect(repository.calls, [('art-1', 'en')]);

      repository.pending!.complete(const Ok(ArticlePdf(path: '/tmp/article-pdf/clean-code-en.pdf', fileName: 'clean-code-en.pdf')));
      await done;
      expect(cubit.state.building, isEmpty);
      expect(cubit.state.failure, isNull);
      expect(share.files.single, (path: '/tmp/article-pdf/clean-code-en.pdf', mimeType: 'application/pdf', fileName: 'clean-code-en.pdf', origin: origin));
    });

    test('two articles build side by side', () async {
      repository.pending = Completer();
      final first = cubit.download('art-1', language: 'en');
      final second = cubit.download('art-2', language: 'ar-EG');
      expect(cubit.state.building, {'art-1', 'art-2'});
      repository.pending!.complete(repository.answer);
      await Future.wait([first, second]);
      expect(cubit.state.building, isEmpty);
      expect(share.files, hasLength(2));
    });

    test('a failure is explained once, and "Try again" asks for the same version', () async {
      repository.answer = const Err(Failure(FailureCodes.articlePdfBusy, statusCode: 503));
      await cubit.download('art-1', language: 'ar-EG');
      expect(cubit.state.building, isEmpty);
      expect(cubit.state.failure?.code, FailureCodes.articlePdfBusy);
      expect(cubit.state.failed, const ArticlePdfRequest('art-1', 'ar-EG'));
      expect(cubit.state.failureSeq, 1);
      expect(share.files, isEmpty);

      await cubit.retry();
      expect(repository.calls, [('art-1', 'ar-EG'), ('art-1', 'ar-EG')]);
      expect(cubit.state.failureSeq, 2);

      repository.answer = const Ok(ArticlePdf(path: '/tmp/a.pdf', fileName: 'a.pdf'));
      await cubit.retry();
      expect(share.files.single.fileName, 'a.pdf');
      expect(cubit.state.failureSeq, 2);
    });

    test('"Try again" opens the share sheet where the first tap was (iPad needs the anchor)', () async {
      const origin = Rect.fromLTWH(10, 20, 100, 40);
      repository.answer = const Err(Failure(FailureCodes.articlePdfBusy, statusCode: 503));
      await cubit.download('art-1', language: 'en', origin: origin);
      expect(cubit.state.failed, const ArticlePdfRequest('art-1', 'en', origin: origin));

      repository.answer = const Ok(ArticlePdf(path: '/tmp/a.pdf', fileName: 'a.pdf'));
      await cubit.retry(); // the snackbar's action has no anchor of its own
      expect(share.files.single.origin, origin);
    });

    test('a share sheet that fails to open is not an error', () async {
      share.fail = true;
      await cubit.download('art-1', language: 'en');
      expect(cubit.state.failure, isNull);
      expect(cubit.state.building, isEmpty);
    });

    test('closed while building: nothing is shared', () async {
      repository.pending = Completer();
      final done = cubit.download('art-1', language: 'en');
      await cubit.close();
      repository.pending!.complete(repository.answer);
      await done;
      expect(share.files, isEmpty);
    });
  });

  group('what a failed download says (the contract table)', () {
    for (final locale in AppLocales.supported) {
      test(locale.languageCode, () {
        final l10n = lookupAppLocalizations(locale);
        ({String message, bool retry})? say(String code) => describePdfFailure(l10n, Failure(code));

        expect(say(FailureCodes.articleNotFound), (message: l10n.errArticlePdfNotFound, retry: false));
        expect(say(FailureCodes.articlePdfHidden), (message: l10n.errArticlePdfHidden, retry: false));
        expect(say(FailureCodes.articlePdfLimit), (message: l10n.errArticlePdfLimit, retry: true));
        // Another limiter's 429 keeps its usual message, as on web.
        expect(say(FailureCodes.rateLimited), (message: l10n.errTooManyRequests, retry: false));
        expect(say(FailureCodes.articlePdfBusy), (message: l10n.errArticlePdfBusy, retry: true));
        expect(say(FailureCodes.articlePdfFailed), (message: l10n.errArticlePdfFailed, retry: true));
        expect(say(FailureCodes.serverError), (message: l10n.errArticlePdfFailed, retry: true));
        expect(say(FailureCodes.networkTimeout), (message: l10n.errArticlePdfFailed, retry: true));
        expect(say('something.new'), (message: l10n.errArticlePdfFailed, retry: true));
        expect(say(FailureCodes.networkOffline), (message: l10n.errArticlePdfOffline, retry: true));
        // Other codes keep their usual message.
        expect(say(FailureCodes.authForbidden), (message: l10n.errForbidden, retry: false));
        expect(describePdfFailure(l10n, const Failure(FailureCodes.userSuspended)), (message: l10n.errSuspendedPermanently, retry: false));
        expect(say(FailureCodes.requestCancelled), isNull);
      });
    }

    test('the Arabic and English texts are the contract\'s', () {
      final ar = lookupAppLocalizations(AppLocales.ar);
      final en = lookupAppLocalizations(AppLocales.en);
      expect(ar.pdfDownload, 'تنزيل PDF');
      expect(en.pdfDownload, 'Download PDF');
      expect(ar.pdfPreparing, 'جارٍ تجهيز ملف PDF…');
      expect(en.pdfPreparing, 'Preparing the PDF…');
      expect(ar.pdfRetry, 'إعادة المحاولة');
      expect(en.pdfRetry, 'Try again');
      expect(ar.pdfLanguageTitle, 'أي نسخة تريد؟');
      expect(ar.errArticlePdfNotFound, 'المقال غير موجود.');
      expect(en.errArticlePdfNotFound, 'Article not found.');
      expect(ar.errArticlePdfHidden, 'أخفى المشرفون هذا المقال، لذا لا يمكن تنزيله بصيغة PDF.');
      expect(en.errArticlePdfHidden, "Moderators hid this article, so it can't be downloaded as a PDF.");
      expect(ar.errArticlePdfLimit, 'نزّلت ملفات PDF كثيرة خلال هذه الساعة. حاول مرة أخرى لاحقًا.');
      expect(en.errArticlePdfLimit, "You've downloaded many PDFs this hour. Try again later.");
      expect(ar.errArticlePdfBusy, 'يجري الآن تجهيز ملفات PDF كثيرة. حاول مرة أخرى بعد قليل.');
      expect(en.errArticlePdfBusy, 'Many PDFs are being prepared right now. Try again in a moment.');
      expect(ar.errArticlePdfFailed, 'تعذّر تجهيز ملف PDF. حاول مرة أخرى.');
      expect(en.errArticlePdfFailed, "We couldn't prepare the PDF. Try again.");
      expect(ar.errArticlePdfOffline, 'تحتاج إلى اتصال بالإنترنت لتنزيل ملف PDF.');
      expect(en.errArticlePdfOffline, 'You need an internet connection to download the PDF.');
    });
  });
}

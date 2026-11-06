import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/failure_messages.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/quote_card/data/datasources/quote_card_data_source.dart';
import 'package:readin/features/quote_card/data/repositories/quote_card_repository_impl.dart';
import 'package:readin/features/quote_card/domain/entities/quote_card.dart';
import 'package:readin/features/quote_card/presentation/widgets/quote_card_sheet.dart';
import 'package:readin/shared/rdoc/highlights/rdoc_highlight_text.dart';

import '../../helpers/quote_card_fakes.dart';

/// Answers every request with [handler]'s response; records the requests.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _png(List<int> bytes, {String? disposition}) => ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: ['image/png'],
        'cache-control': ['private, max-age=600'],
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

const _range = HighlightRange(blockId: 'p1', startOffset: 42, endOffset: 52, text: 'Dependency');

const _request = QuoteCardRequest(
  articleId: 'art 1',
  language: 'ar-EG',
  range: _range,
  theme: QuoteCardTheme.dark,
  format: QuoteCardFormat.landscape,
);

/// The quote card's data side (SPEC F24, contract "Quote card (F24)"): the request, the PNG and its name, the errors,
/// the temporary file for the share sheet, and what each error says.
void main() {
  group('the file name from Content-Disposition', () {
    String name(String? header) => QuoteCardFileName.fromContentDisposition(header);

    test('takes the RFC 5987 filename*, percent-decoded; falls back to readin-quote.png', () {
      expect(name('''inline; filename="readin-quote.png"; filename*=UTF-8''readin-quote-clean-code.png'''), 'readin-quote-clean-code.png');
      final arabic = Uri.encodeComponent('readin-quote-الذكاء-الاصطناعي.png');
      expect(name('''inline; filename="readin-quote.png"; filename*=UTF-8''$arabic'''), 'readin-quote-الذكاء-الاصطناعي.png');
      expect(name('inline; filename="readin-quote.png"'), 'readin-quote.png');
      expect(name(null), QuoteCardFileName.fallback);
      expect(name(''), QuoteCardFileName.fallback);
    });

    test('never a path, and always .png', () {
      expect(name('''inline; filename*=UTF-8''..%2F..%2Fetc%2Fpasswd'''), '_.._etc_passwd.png');
      expect(name('''inline; filename*=UTF-8''a%3Ab.PNG'''), 'a_b.png');
      expect(name('''inline; filename*=ISO-8859-1''x.png; filename="y.png"'''), 'y.png');
      final long = Uri.encodeComponent('readin-quote-${List.filled(200, 'ذ').join()}.png');
      expect(utf8.encode(name("inline; filename*=UTF-8''$long")).length, lessThanOrEqualTo(240));
    });
  });

  group('POST /articles/{id}/quote-card', () {
    late Directory temp;
    late _Adapter adapter;
    late QuoteCardRepositoryImpl repository;
    late FutureOr<ResponseBody> Function(RequestOptions) respond;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('readin-quote-test');
      respond = (_) => _png(tinyPng, disposition: '''inline; filename="readin-quote.png"; filename*=UTF-8''readin-quote-clean-code.png''');
      adapter = _Adapter((options) => respond(options));
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1', receiveTimeout: const Duration(seconds: 20)))..httpClientAdapter = adapter;
      repository = QuoteCardRepositoryImpl(QuoteCardDataSource(dio, temporaryDirectory: () async => temp));
    });

    tearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    test('sends the seven fields, waits at least 40 s, and keeps the PNG in memory under the server name', () async {
      final image = (await repository.make(_request)).valueOrNull!;

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/v1/articles/art%201/quote-card');
      expect(request.data, {
        'language': 'ar-EG',
        'blockId': 'p1',
        'startOffset': 42,
        'endOffset': 52,
        'text': 'Dependency',
        'theme': 'dark',
        'format': 'landscape',
      });
      expect(request.responseType, ResponseType.bytes);
      expect(request.receiveTimeout, greaterThanOrEqualTo(const Duration(seconds: 40)));
      expect(request.headers[Headers.acceptHeader], allOf(contains('image/png'), contains('application/problem+json')));

      expect(image.bytes, tinyPng);
      expect(image.fileName, 'readin-quote-clean-code.png');
      // Nothing on disk until Share.
      expect(Directory('${temp.path}${Platform.pathSeparator}quote-card').existsSync(), isFalse);
    });

    test('Share writes the bytes to <temp>/quote-card/{name}; again replaces it', () async {
      final image = (await repository.make(_request)).valueOrNull!;
      await repository.temporaryFile(image);
      final path = (await repository.temporaryFile(image)).valueOrNull!;
      expect(path, '${temp.path}${Platform.pathSeparator}quote-card${Platform.pathSeparator}readin-quote-clean-code.png');
      expect(await File(path).readAsBytes(), tinyPng);
    });

    test('a folder that cannot be written: quote.failed', () async {
      final file = File('${temp.path}${Platform.pathSeparator}not-a-folder');
      await file.writeAsString('x');
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))..httpClientAdapter = adapter;
      final broken = QuoteCardRepositoryImpl(QuoteCardDataSource(dio, temporaryDirectory: () async => Directory(file.path)));
      final image = QuoteCardImage(bytes: tinyPng, fileName: 'readin-quote.png');
      expect((await broken.temporaryFile(image)).failureOrNull!.code, FailureCodes.quoteFailed);
    });

    for (final (status, code) in [
      (400, FailureCodes.quoteTextMismatch),
      (400, FailureCodes.quoteBlockNotAllowed),
      (400, FailureCodes.quoteTooShort),
      (400, FailureCodes.quoteTooLong),
      (404, FailureCodes.articleNotFound),
      (409, FailureCodes.quoteHidden),
      (429, FailureCodes.quoteLimit),
      (503, FailureCodes.quoteBusy),
      (500, FailureCodes.quoteFailed),
      (403, FailureCodes.userSuspended),
    ]) {
      test('$status $code reads the ProblemDetails code', () async {
        respond = (_) => _problem(status, code);
        final failure = (await repository.make(_request)).failureOrNull!;
        expect(failure.code, code);
        expect(failure.statusCode, status);
      });
    }

    test('an answer that is not a PNG fails', () async {
      respond = (_) => ResponseBody.fromString('<html>proxy</html>', 200, headers: {
            Headers.contentTypeHeader: ['text/html'],
          });
      expect((await repository.make(_request)).failureOrNull!.code, FailureCodes.serverError);
    });

    test('offline and timeouts', () async {
      respond = (options) => throw DioException.connectionError(requestOptions: options, reason: 'offline');
      expect((await repository.make(_request)).failureOrNull!.code, FailureCodes.networkOffline);
      respond = (options) => throw DioException.receiveTimeout(timeout: const Duration(seconds: 45), requestOptions: options);
      expect((await repository.make(_request)).failureOrNull!.code, FailureCodes.networkTimeout);
    });
  });

  group('what the sheet says (contract table, ar and en)', () {
    late AppLocalizations ar;
    late AppLocalizations en;

    setUpAll(() async {
      ar = await AppLocalizations.delegate.load(AppLocales.ar);
      en = await AppLocalizations.delegate.load(AppLocales.en);
    });

    test('every quote code, with "Try again" only where it can help', () {
      final expected = {
        FailureCodes.articleNotFound: ('المقال مش موجود.', 'Article not found.', false),
        FailureCodes.quoteHidden: (
          'المشرفين خفّوا المقال ده، فمينفعش تشارك منه اقتباس.',
          "Moderators hid this article, so its quotes can't be shared.",
          false,
        ),
        FailureCodes.quoteTextMismatch: (
          'النص ده اتغيّر في المقال. حدّث الصفحة وجرّب تاني.',
          'This text has changed in the article. Reload and try again.',
          false,
        ),
        FailureCodes.quoteBlockNotAllowed: ('مينفعش تشارك الجزء ده كاقتباس.', "This part can't be shared as a quote.", false),
        FailureCodes.quoteTooShort: ('اختار 3 حروف على الأقل.', 'Select at least 3 characters.', false),
        FailureCodes.quoteTooLong: (
          'الاقتباس لازم يكون 400 حرف أو أقل. اختار جزء أصغر.',
          'A quote can be at most 400 characters. Select less text.',
          false,
        ),
        FailureCodes.quoteLimit: (
          'عملت كروت اقتباس كتير الساعة دي. حاول تاني بعد شوية.',
          "You've made many quote cards this hour. Try again later.",
          true,
        ),
        FailureCodes.quoteBusy: (
          'فيه كروت كتير بتتجهز دلوقتي. حاول تاني كمان شوية.',
          'Many cards are being prepared right now. Try again in a moment.',
          true,
        ),
        FailureCodes.quoteFailed: ('معرفناش نجهّز كارت الاقتباس. حاول تاني.', "We couldn't prepare the quote card. Try again.", true),
        FailureCodes.serverError: ('معرفناش نجهّز كارت الاقتباس. حاول تاني.', "We couldn't prepare the quote card. Try again.", true),
        FailureCodes.networkTimeout: ('معرفناش نجهّز كارت الاقتباس. حاول تاني.', "We couldn't prepare the quote card. Try again.", true),
        'something.new': ('معرفناش نجهّز كارت الاقتباس. حاول تاني.', "We couldn't prepare the quote card. Try again.", true),
        FailureCodes.networkOffline: (
          'محتاج إنترنت عشان تعمل كارت اقتباس.',
          'You need an internet connection to make a quote card.',
          true,
        ),
        FailureCodes.validationFailed: (ar.errServer, en.errServer, false),
      };
      for (final MapEntry(key: code, value: (arabic, english, retry)) in expected.entries) {
        expect(describeQuoteCardFailure(ar, Failure(code)), (message: arabic, retry: retry), reason: code);
        expect(describeQuoteCardFailure(en, Failure(code)), (message: english, retry: retry), reason: code);
      }
      expect(describeQuoteCardFailure(en, const Failure(FailureCodes.requestCancelled)), isNull);
      // Other codes keep their usual message, without "Try again".
      expect(describeQuoteCardFailure(en, const Failure(FailureCodes.userSuspended)), (message: localizeFailure(en, const Failure(FailureCodes.userSuspended)), retry: false));
    });

    test('the quote codes have their own message wherever the app translates codes', () {
      for (final code in [
        FailureCodes.quoteTextMismatch,
        FailureCodes.quoteBlockNotAllowed,
        FailureCodes.quoteTooShort,
        FailureCodes.quoteTooLong,
        FailureCodes.quoteHidden,
        FailureCodes.quoteLimit,
        FailureCodes.quoteBusy,
        FailureCodes.quoteFailed,
      ]) {
        expect(localizeErrorCode(en, code), isNot(en.errServer), reason: code);
        expect(localizeErrorCode(ar, code), isNot(ar.errServer), reason: code);
      }
    });
  });
}

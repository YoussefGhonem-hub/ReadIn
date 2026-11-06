import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/config/app_links.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/quote_card/data/datasources/quote_card_data_source.dart';
import 'package:readin/features/quote_card/data/repositories/quote_card_repository_impl.dart';
import 'package:readin/features/quote_card/domain/entities/quote_card.dart';
import 'package:readin/features/quote_card/presentation/cubit/quote_card_cubit.dart';
import 'package:readin/shared/rdoc/highlights/rdoc_highlight_text.dart';

import '../../helpers/quote_card_fakes.dart';

const _range = HighlightRange(blockId: 'p1', startOffset: 42, endOffset: 52, text: 'Dependency');

const _source = QuoteCardSource(
  articleId: 'art-1',
  language: 'ar-EG',
  slug: 'الحقن-في-dotnet',
  title: 'إزاي تستخدم DI في .NET 10؟',
  range: _range,
);

/// Answers every request with a PNG named like the server does.
class _PngAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final slug = Uri.encodeComponent('readin-quote-الحقن-في-dotnet.png');
    return ResponseBody.fromBytes(tinyPng, 200, headers: {
      Headers.contentTypeHeader: ['image/png'],
      'content-disposition': ['''inline; filename="readin-quote.png"; filename*=UTF-8''$slug'''],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// The quote card sheet's logic (SPEC F24): one call per look, kept while the sheet is open; failures and "Try
/// again"; Share with a real temporary file and the article link; Save.
void main() {
  late FakeQuoteCardRepository repository;
  late RecordingShare share;
  late RecordingSaver saver;
  late QuoteCardCubit cubit;

  setUp(() {
    repository = FakeQuoteCardRepository();
    share = RecordingShare();
    saver = RecordingSaver();
    cubit = quoteCardCubit(repository, share: share, saver: saver);
  });

  tearDown(() => cubit.close());

  List<(QuoteCardTheme, QuoteCardFormat)> looks() => [for (final r in repository.requests) (r.theme, r.format)];

  test('opens on the given theme, square, and draws that card from the selection', () async {
    final states = <QuoteCardState>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.open(_source, theme: QuoteCardTheme.dark);
    // The stream delivers in later microtasks.
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(repository.requests.single, const QuoteCardRequest(
      articleId: 'art-1',
      language: 'ar-EG',
      range: _range,
      theme: QuoteCardTheme.dark,
      format: QuoteCardFormat.square,
    ));
    expect(states.map((s) => s.current?.status), [null, QuoteCardSlotStatus.loading, QuoteCardSlotStatus.ready]);
    expect(cubit.state.image!.fileName, 'readin-quote-dark-square.png');
    expect(cubit.state.canExport, isTrue);
  });

  test('each new theme or format is a new call; switching back reuses the card', () async {
    await cubit.open(_source);
    await cubit.setFormat(QuoteCardFormat.landscape);
    await cubit.setTheme(QuoteCardTheme.dark);
    await cubit.setFormat(QuoteCardFormat.square);
    expect(looks(), [
      (QuoteCardTheme.light, QuoteCardFormat.square),
      (QuoteCardTheme.light, QuoteCardFormat.landscape),
      (QuoteCardTheme.dark, QuoteCardFormat.landscape),
      (QuoteCardTheme.dark, QuoteCardFormat.square),
    ]);

    await cubit.setTheme(QuoteCardTheme.light);
    await cubit.setFormat(QuoteCardFormat.landscape);
    await cubit.setFormat(QuoteCardFormat.landscape);
    expect(repository.requests, hasLength(4));
    expect(cubit.state.image!.fileName, 'readin-quote-light-landscape.png');
  });

  test('while a card loads, switching shows the others already drawn; Share and Save wait for the chosen one', () async {
    await cubit.open(_source);
    repository.gate = Completer<void>();
    final pending = cubit.setTheme(QuoteCardTheme.dark);
    expect(cubit.state.current, QuoteCardSlot.loading);
    expect(cubit.state.canExport, isFalse);
    await cubit.share();
    await cubit.save();
    expect(share.shared, isEmpty);
    expect(saver.saved, isEmpty);

    // Back to the light card while the dark one is drawn: no new call, and it can be shared.
    await cubit.setTheme(QuoteCardTheme.light);
    expect(cubit.state.canExport, isTrue);
    repository.gate!.complete();
    await pending;
    expect(cubit.state.slots[(theme: QuoteCardTheme.dark, format: QuoteCardFormat.square)]!.status, QuoteCardSlotStatus.ready);
    expect(cubit.state.theme, QuoteCardTheme.light);
    expect(repository.requests, hasLength(2));
  });

  test('a failure shows on its look; "Try again" calls again; another look is not blocked by it', () async {
    repository.answer = (_) => const Err(Failure(FailureCodes.networkOffline));
    await cubit.open(_source);
    expect(cubit.state.current!.failure!.code, FailureCodes.networkOffline);
    expect(cubit.state.canExport, isFalse);

    // Switching away and back shows the same failure without a new call.
    repository.answer = null;
    await cubit.setFormat(QuoteCardFormat.landscape);
    await cubit.setFormat(QuoteCardFormat.square);
    expect(repository.requests, hasLength(2));
    expect(cubit.state.current!.status, QuoteCardSlotStatus.failed);

    await cubit.retry();
    expect(repository.requests, hasLength(3));
    expect(cubit.state.current!.status, QuoteCardSlotStatus.ready);

    // Nothing to retry on a drawn card.
    await cubit.retry();
    expect(repository.requests, hasLength(3));
  });

  test('Share: the PNG in a real temporary file, the share sheet with the article link and the title', () async {
    final temp = await Directory.systemTemp.createTemp('readin-quote-share');
    addTearDown(() => temp.delete(recursive: true));
    final adapter = _PngAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))..httpClientAdapter = adapter;
    final real = QuoteCardRepositoryImpl(QuoteCardDataSource(dio, temporaryDirectory: () async => temp));
    final sharing = quoteCardCubit(real, share: share, saver: saver);
    addTearDown(sharing.close);

    await sharing.open(_source);
    const origin = Rect.fromLTWH(10, 20, 30, 40);
    await sharing.share(origin: origin);

    final call = share.shared.single;
    expect(call.mimeType, 'image/png');
    expect(call.fileName, 'readin-quote-الحقن-في-dotnet.png');
    expect(call.text, AppLinks.article('الحقن-في-dotnet', language: 'ar-EG'));
    expect(call.text, endsWith('/ar/a/${Uri.encodeComponent('الحقن-في-dotnet')}'));
    expect(call.subject, 'إزاي تستخدم DI في .NET 10؟');
    expect(call.origin, origin);
    expect(call.path, '${temp.path}${Platform.pathSeparator}quote-card${Platform.pathSeparator}readin-quote-الحقن-في-dotnet.png');
    expect(await File(call.path).readAsBytes(), tinyPng);
    // The bytes already shown: no new call.
    expect(adapter.requests, hasLength(1));
    expect(sharing.state.sharing, isFalse);
    expect(sharing.state.notice, isNull);
  });

  test('Share says so when the file or the share sheet fails', () async {
    await cubit.open(_source);
    share.fail = true;
    await cubit.share();
    expect(cubit.state.notice, QuoteCardNotice.shareFailed);

    share.fail = false;
    repository.fileFailure = const Failure(FailureCodes.quoteFailed);
    await cubit.share();
    expect(cubit.state.notice, QuoteCardNotice.shareFailed);
    expect(share.shared, hasLength(1));

    // A new look clears the line.
    await cubit.setTheme(QuoteCardTheme.dark);
    expect(cubit.state.notice, isNull);
  });

  test('Save: the bytes on screen under the server name; a cancel says nothing; a failure says so', () async {
    await cubit.open(_source);
    await cubit.save();
    expect(saver.saved.single.bytes, tinyPng);
    expect(saver.saved.single.fileName, 'readin-quote-light-square.png');
    expect(saver.saved.single.mimeType, 'image/png');
    expect(cubit.state.notice, QuoteCardNotice.saved);
    expect(cubit.state.saving, isFalse);

    saver.result = false;
    await cubit.save();
    expect(cubit.state.notice, isNull);

    saver.fail = true;
    await cubit.save();
    expect(cubit.state.notice, QuoteCardNotice.saveFailed);
    expect(repository.requests, hasLength(1));
  });

  test('a card that arrives after the sheet closed is dropped', () async {
    repository.gate = Completer<void>();
    final opening = cubit.open(_source);
    await cubit.close();
    repository.gate!.complete();
    await opening;
    expect(cubit.state.current, QuoteCardSlot.loading);
  });
}

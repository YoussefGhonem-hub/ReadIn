import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/platform/file_save_service.dart';
import 'package:readin/core/platform/share_service.dart';
import 'package:readin/features/quote_card/domain/entities/quote_card.dart';
import 'package:readin/features/quote_card/domain/repositories/quote_card_repository.dart';
import 'package:readin/features/quote_card/domain/usecases/make_quote_card.dart';
import 'package:readin/features/quote_card/presentation/cubit/quote_card_cubit.dart';

/// A valid 1 × 1 PNG: enough for the data source's signature check and for the sheet's widget tests.
final tinyPng = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

/// The cards the API drew for the goldens (copies of the backend's F24 baselines): Arabic light square, English dark
/// landscape.
Uint8List quoteCardFixture(String name) => File('test/fixtures/quote_card/$name').readAsBytesSync();

/// `POST /articles/{id}/quote-card`, recorded. [answer] decides each card (default: [tinyPng] named after the look);
/// [gate], when set, holds every answer until it completes (the loading state).
class FakeQuoteCardRepository implements QuoteCardRepository {
  final requests = <QuoteCardRequest>[];
  final files = <QuoteCardImage>[];
  Result<QuoteCardImage> Function(QuoteCardRequest request)? answer;
  Completer<void>? gate;
  Failure? fileFailure;

  static QuoteCardImage imageFor(QuoteCardRequest request) =>
      QuoteCardImage(bytes: tinyPng, fileName: 'readin-quote-${request.theme.name}-${request.format.name}.png');

  @override
  Future<Result<QuoteCardImage>> make(QuoteCardRequest request) async {
    requests.add(request);
    await gate?.future;
    return answer?.call(request) ?? Ok(imageFor(request));
  }

  @override
  Future<Result<String>> temporaryFile(QuoteCardImage image) async {
    files.add(image);
    final failure = fileFailure;
    return failure == null ? Ok('/tmp/quote-card/${image.fileName}') : Err(failure);
  }
}

/// The system share sheet, recorded.
class RecordingShare extends ShareService {
  final shared = <({String path, String mimeType, String text, String? subject, String? fileName, Rect? origin})>[];
  bool fail = false;

  @override
  Future<void> shareFileWithText(
    String path, {
    required String mimeType,
    required String text,
    String? subject,
    String? fileName,
    Rect? origin,
  }) async {
    shared.add((path: path, mimeType: mimeType, text: text, subject: subject, fileName: fileName, origin: origin));
    if (fail) throw Exception('no share sheet');
  }
}

/// The "Save as" dialog, recorded: [result] true saves, false is a cancel; [fail] throws.
class RecordingSaver extends FileSaveService {
  final saved = <({Uint8List bytes, String fileName, String mimeType})>[];
  bool result = true;
  bool fail = false;

  @override
  Future<bool> save(Uint8List bytes, {required String fileName, required String mimeType}) async {
    saved.add((bytes: bytes, fileName: fileName, mimeType: mimeType));
    if (fail) throw Exception('no dialog');
    return result;
  }
}

QuoteCardCubit quoteCardCubit(QuoteCardRepository repository, {ShareService? share, FileSaveService? saver}) => QuoteCardCubit(
      MakeQuoteCard(repository),
      PrepareQuoteCardFile(repository),
      share ?? RecordingShare(),
      saver ?? RecordingSaver(),
    );

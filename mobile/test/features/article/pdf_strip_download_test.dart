import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/platform/share_service.dart';
import 'package:readin/features/article/domain/usecases/get_article.dart';
import 'package:readin/features/article/presentation/cubit/attachment_viewer_cubit.dart';
import 'package:readin/features/article/presentation/widgets/article_attachments_view.dart';
import 'package:readin/features/article/presentation/widgets/attachment_viewers.dart';
import 'package:readin/features/media/data/datasources/document_file_data_source.dart';
import 'package:readin/features/media/data/datasources/image_compressor.dart';
import 'package:readin/features/media/data/datasources/media_api.dart';
import 'package:readin/features/media/data/repositories/media_repository_impl.dart';
import 'package:readin/features/media/domain/usecases/media_usecases.dart';

import '../../helpers/fake_media.dart';
import '../../helpers/media_fixtures.dart';
import '../../helpers/test_app.dart';

class _MockGetArticle extends Mock implements GetArticle {}

class _MockMediaApi extends Mock implements MediaApi {}

class _MockCompressor extends Mock implements ImageCompressor {}

/// The share sheet, recorded.
class _FakeShare extends ShareService {
  final files = <(String path, String mimeType, String? fileName)>[];

  @override
  Future<void> shareFile(String path, {required String mimeType, String? fileName, Rect? origin}) async =>
      files.add((path, mimeType, fileName));
}

/// Answers every request with [handler]; records the requests.
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

final _pdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.7\n1 0 obj\n<<>>\nendobj\n%%EOF\n'));

/// The download icon in a PDF's title strip (SPEC F26, pre-production step G): shown when the caller may download
/// (`canDownload`), and a tap really downloads the file — through the app's HTTP client to a file — and hands it to the
/// system share sheet, where it is saved or sent.
void main() {
  setUpAll(FakeMedia.install);

  late Directory temp;
  late _FakeShare share;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('readin-pdf-strip-');
    share = _FakeShare();
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  /// path_provider's temporary directory → [temp].
  void mockTempDir(WidgetTester tester) {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async => temp.path);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
  }

  /// A real cubit over the real download path: [DownloadDocument] → [MediaRepositoryImpl] → [DocumentFileDataSource]
  /// → Dio (answered by [adapter]).
  AttachmentViewerCubit cubitWith(_Adapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.readin.test/api/v1'))..httpClientAdapter = adapter;
    final repository = MediaRepositoryImpl(_MockMediaApi(), _MockCompressor(), DocumentFileDataSource(dio));
    return AttachmentViewerCubit(_MockGetArticle(), DownloadDocument(repository), share);
  }

  Future<void> pumpStrip(WidgetTester tester, Widget strip, {Variant variant = const Variant(AppLocales.en, Brightness.light)}) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(testApp(Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: strip)), variant: variant));
    await tester.pump();
  }

  testWidgets('the strip shows the download icon when the file may be downloaded, and none otherwise', (tester) async {
    final l10n = await AppLocalizations.delegate.load(AppLocales.en);
    await pumpStrip(tester, ArticleAttachmentsView(article: cardWithDocument(language: 'en')));

    expect(find.byKey(DocumentDownloadButton.buttonKey), findsOneWidget);
    expect(find.byTooltip(l10n.pdfStripDownload), findsOneWidget);
    // The title still opens the viewer, as its own button.
    expect(find.bySemanticsLabel(RegExp('^${RegExp.escape(l10n.openDocument)}')), findsOneWidget);

    // Not allowed for this reader (`canDownload` false): no icon.
    await pumpStrip(
      tester,
      DocumentDownloadButton(article: cardWithDocument(language: 'en'), document: sampleDocument(canDownload: false)),
    );
    expect(find.byKey(DocumentDownloadButton.buttonKey), findsNothing);
  });

  testWidgets('a tap downloads the PDF to a file and opens the share sheet with it (save or send)', (tester) async {
    mockTempDir(tester);
    final adapter = _Adapter((_) => ResponseBody.fromBytes(_pdfBytes, 200, headers: {
          Headers.contentTypeHeader: ['application/pdf'],
          'content-disposition': ['attachment; filename="clean-architecture.pdf"'],
        }));
    final article = cardWithDocument(language: 'en');
    final document = article.attachments!.document!;
    await pumpStrip(tester, DocumentDownloadButton(article: article, document: document, createCubit: () => cubitWith(adapter)));

    await tester.runAsync(() async {
      await tester.tap(find.byKey(DocumentDownloadButton.buttonKey));
      for (var i = 0; i < 50 && share.files.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();

    // The document's own download link, through the app's client (its interceptors add the session).
    expect(adapter.requests.single.uri.toString(), document.downloadUrl);
    final (path, mimeType, fileName) = share.files.single;
    expect(mimeType, 'application/pdf');
    expect(fileName, endsWith('.pdf'));
    expect(path, startsWith(temp.path));
    expect(File(path).readAsBytesSync(), _pdfBytes);
    // Back to the icon once done.
    expect(find.byKey(DocumentDownloadButton.buttonKey), findsOneWidget);
  });

  testWidgets('while it downloads a spinner replaces the icon; a refused download says why', (tester) async {
    mockTempDir(tester);
    final l10n = await AppLocalizations.delegate.load(AppLocales.en);
    final gate = Completer<void>();
    final adapter = _Adapter((_) async {
      await gate.future;
      return ResponseBody.fromString(
        jsonEncode({'title': 'Forbidden', 'status': 403, 'code': 'media.download_not_allowed'}),
        403,
        headers: {
          Headers.contentTypeHeader: ['application/problem+json'],
        },
      );
    });
    final article = cardWithDocument(language: 'en');
    await pumpStrip(
      tester,
      DocumentDownloadButton(article: article, document: article.attachments!.document!, createCubit: () => cubitWith(adapter)),
    );

    await tester.runAsync(() async {
      await tester.tap(find.byKey(DocumentDownloadButton.buttonKey));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    expect(find.byKey(DocumentDownloadButton.buttonKey), findsNothing);
    expect(find.bySemanticsLabel(l10n.viewerDownloading), findsOneWidget);

    await tester.runAsync(() async {
      gate.complete();
      for (var i = 0; i < 50 && find.byKey(DocumentDownloadButton.buttonKey).evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pump();

    expect(find.text(l10n.errMediaDownloadNotAllowed), findsOneWidget);
    expect(share.files, isEmpty);
    expect(find.byKey(DocumentDownloadButton.buttonKey), findsOneWidget);
  });
}

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/transfer.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/media/domain/repositories/media_picker.dart';
import 'package:readin/features/media/domain/repositories/media_repository.dart';
import 'package:readin/features/media/domain/usecases/media_usecases.dart';
import 'package:readin/features/media/presentation/cubit/attachments_cubit.dart';

import '../../helpers/media_fixtures.dart';

class MockMediaRepository extends Mock implements MediaRepository {}

class MockMediaPicker extends Mock implements MediaPicker {}

void main() {
  late MockMediaRepository repository;
  late MockMediaPicker picker;

  setUpAll(() {
    registerFallbackValue(sampleImageFile);
    registerFallbackValue(TransferToken());
  });

  setUp(() {
    repository = MockMediaRepository();
    picker = MockMediaPicker();
    when(() => repository.deleteUpload(any())).thenAnswer((_) async => const Ok(null));
  });

  AttachmentsCubit build() => AttachmentsCubit(
        PickImages(picker),
        PickPdf(picker),
        UploadImage(repository),
        UploadDocument(repository),
        GetUpload(repository),
        DeleteUpload(repository),
        pollInterval: Duration.zero,
      );

  void stubImageUpload(Future<Result<MediaAsset>> Function(PickedMediaFile file, TransferToken? token, TransferProgress? onProgress) answer) =>
      when(() => repository.uploadImage(any(), token: any(named: 'token'), onProgress: any(named: 'onProgress'))).thenAnswer(
        (inv) => answer(
          inv.positionalArguments.first as PickedMediaFile,
          inv.namedArguments[#token] as TransferToken?,
          inv.namedArguments[#onProgress] as TransferProgress?,
        ),
      );

  void stubDocumentUpload(Result<MediaAsset> result) => when(() => repository.uploadDocument(
        any(),
        title: any(named: 'title'),
        allowDownload: any(named: 'allowDownload'),
        token: any(named: 'token'),
        onProgress: any(named: 'onProgress'),
      )).thenAnswer((inv) async {
        (inv.namedArguments[#onProgress] as TransferProgress?)?.call(100, 100);
        return result;
      });

  /// Answers `GET /uploads/{id}` from a queue.
  void stubPolls(List<Result<MediaAsset>> answers) {
    final queue = [...answers];
    when(() => repository.getUpload(any())).thenAnswer((_) async => queue.length > 1 ? queue.removeAt(0) : queue.first);
  }

  group('images', () {
    blocTest<AttachmentsCubit, AttachmentsState>(
      'upload reports progress, then the ready asset',
      setUp: () => stubImageUpload((file, token, onProgress) async {
        onProgress?.call(0, 1000);
        onProgress?.call(400, 1000);
        onProgress?.call(1000, 1000);
        return Ok(imageAsset('a1'));
      }),
      build: build,
      act: (cubit) => cubit.addImages([sampleImageFile]),
      expect: () => [
        const AttachmentsState(images: [ImageDraft(localId: 'local-1', file: sampleImageFile)]),
        const AttachmentsState(images: [ImageDraft(localId: 'local-1', file: sampleImageFile, phase: UploadPhase.uploading, progress: 0)]),
        const AttachmentsState(images: [ImageDraft(localId: 'local-1', file: sampleImageFile, phase: UploadPhase.uploading, progress: 0.4)]),
        const AttachmentsState(images: [ImageDraft(localId: 'local-1', file: sampleImageFile, phase: UploadPhase.uploading, progress: 1)]),
        AttachmentsState(images: [ImageDraft(localId: 'local-1', file: sampleImageFile, phase: UploadPhase.ready, asset: imageAsset('a1'))]),
      ],
    );

    late Completer<void> uploadStarted;
    blocTest<AttachmentsCubit, AttachmentsState>(
      'cancel stops the upload; retry uploads the same file again',
      setUp: () {
        uploadStarted = Completer<void>();
        var calls = 0;
        stubImageUpload((file, token, onProgress) {
          calls++;
          if (calls == 1) {
            onProgress?.call(300, 1000);
            final result = Completer<Result<MediaAsset>>();
            token!.onCancel(() => result.complete(const Err(Failure(FailureCodes.requestCancelled))));
            uploadStarted.complete();
            return result.future;
          }
          return Future.value(Ok(imageAsset('a2')));
        });
      },
      build: build,
      act: (cubit) async {
        cubit.addImages([sampleImageFile]);
        await uploadStarted.future;
        cubit.cancel('local-1');
        await Future<void>.delayed(Duration.zero);
        await cubit.retry('local-1');
      },
      skip: 2,
      expect: () => [
        const AttachmentsState(images: [ImageDraft(localId: 'local-1', file: sampleImageFile, phase: UploadPhase.cancelled)]),
        const AttachmentsState(images: [ImageDraft(localId: 'local-1', file: sampleImageFile)]),
        AttachmentsState(images: [ImageDraft(localId: 'local-1', file: sampleImageFile, phase: UploadPhase.ready, asset: imageAsset('a2'))]),
      ],
      verify: (cubit) {
        verify(() => repository.uploadImage(sampleImageFile, token: any(named: 'token'), onProgress: any(named: 'onProgress'))).called(2);
        expect(cubit.state.blockers, [AttachmentBlocker.altText]);
      },
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'a failed upload keeps a translatable error and blocks publishing until retried or removed',
      setUp: () => stubImageUpload((_, _, _) async => const Err(Failure(FailureCodes.mediaQuotaDaily, statusCode: 409))),
      build: build,
      act: (cubit) async {
        cubit.addImages([sampleImageFile]);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const AttachmentsState(images: [ImageDraft(localId: 'local-1', file: sampleImageFile)]),
        const AttachmentsState(images: [
          ImageDraft(
            localId: 'local-1',
            file: sampleImageFile,
            phase: UploadPhase.failed,
            failure: Failure(FailureCodes.mediaQuotaDaily, statusCode: 409),
          ),
        ]),
      ],
      verify: (cubit) {
        expect(cubit.state.blockers, containsAll([AttachmentBlocker.failed, AttachmentBlocker.altText]));
        expect(cubit.state.canPublish, isFalse);
      },
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'alt text is required on every image before publishing',
      setUp: () => stubImageUpload((file, _, _) async => Ok(imageAsset(file.name))),
      build: build,
      act: (cubit) async {
        cubit.addImages([sampleImageFile, sampleImageFile2]);
        await Future<void>.delayed(Duration.zero);
        cubit.setAltText('local-1', 'Program.cs');
        expect(cubit.state.blockers, [AttachmentBlocker.altText]);
        cubit.setAltText('local-2', '   ');
        expect(cubit.state.canPublish, isFalse, reason: 'whitespace is not alt text');
        cubit.setAltText('local-2', 'Swagger UI');
      },
      verify: (cubit) {
        expect(cubit.state.canPublish, isTrue);
        expect(cubit.state.requestItems, const [
          AttachmentItem(mediaAssetId: 'photo-1.jpg', order: 0, altText: 'Program.cs'),
          AttachmentItem(mediaAssetId: 'photo-2.heic', order: 1, altText: 'Swagger UI'),
        ]);
      },
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'alt text and captions take up to 5000 characters',
      setUp: () => stubImageUpload((file, _, _) async => Ok(imageAsset(file.name))),
      build: build,
      act: (cubit) async {
        cubit.addImages([sampleImageFile]);
        await Future<void>.delayed(Duration.zero);
        cubit.setAltText('local-1', 'A' * 4000);
        cubit.setCaption('local-1', 'C' * 6000);
      },
      verify: (cubit) {
        expect(AttachmentLimits.maxAltText, 5000);
        expect(AttachmentLimits.maxCaption, 5000);
        expect(cubit.state.images.single.altText, hasLength(4000));
        expect(cubit.state.images.single.caption, hasLength(5000));
        expect(cubit.state.canPublish, isTrue);
      },
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'publishing is blocked while an image is uploading',
      setUp: () => stubImageUpload((_, _, _) => Completer<Result<MediaAsset>>().future),
      build: build,
      act: (cubit) {
        cubit.addImages([sampleImageFile]);
        cubit.setAltText('local-1', 'alt');
      },
      verify: (cubit) => expect(cubit.state.blockers, [AttachmentBlocker.busy]),
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'at most 10 images; extra picks are dropped with a notice',
      setUp: () => stubImageUpload((file, _, _) async => Ok(imageAsset(file.path))),
      build: build,
      act: (cubit) {
        cubit.addImages([for (var i = 0; i < 12; i++) PickedMediaFile(path: '/p/$i.jpg', name: '$i.jpg')]);
        expect(cubit.state.notice, const Failure(FailureCodes.attachmentsTooManyImages));
      },
      verify: (cubit) {
        expect(cubit.state.images, hasLength(AttachmentLimits.maxImages));
        expect(cubit.state.noticeSeq, 1);
        expect(cubit.state.canAddImages, isFalse);
      },
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'reorder by drag and by the accessible move actions',
      setUp: () => stubImageUpload((file, _, _) async => Ok(imageAsset(file.path))),
      build: build,
      act: (cubit) async {
        cubit.addImages([for (var i = 0; i < 3; i++) PickedMediaFile(path: '/p/$i.jpg', name: '$i.jpg')]);
        await Future<void>.delayed(Duration.zero);
        cubit.reorder(0, 2);
        cubit.move('local-3', 1);
      },
      verify: (cubit) => expect([for (final i in cubit.state.images) i.localId], ['local-2', 'local-1', 'local-3']),
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'removing an uploaded image deletes the asset, ignoring failures',
      setUp: () {
        stubImageUpload((_, _, _) async => Ok(imageAsset('a1')));
        when(() => repository.deleteUpload('a1')).thenAnswer((_) async => const Err(Failure(FailureCodes.mediaInUse)));
      },
      build: build,
      act: (cubit) async {
        cubit.addImages([sampleImageFile]);
        await Future<void>.delayed(Duration.zero);
        cubit.remove('local-1');
      },
      verify: (cubit) {
        expect(cubit.state.isEmpty, isTrue);
        expect(cubit.state.canPublish, isTrue);
        verify(() => repository.deleteUpload('a1')).called(1);
      },
    );
  });

  group('pdf', () {
    blocTest<AttachmentsCubit, AttachmentsState>(
      'processing → ready: polls GET /uploads/{id} until the pages are rendered',
      setUp: () {
        stubDocumentUpload(Ok(documentAsset(status: MediaStatus.processing)));
        stubPolls([
          Ok(documentAsset(status: MediaStatus.processing, pagesReady: 3)),
          Ok(documentAsset(status: MediaStatus.ready, pagesReady: 12)),
        ]);
      },
      build: build,
      act: (cubit) => cubit.setDocument(samplePdfFile),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const AttachmentsState(document: DocumentDraft(localId: 'local-1', file: samplePdfFile, title: 'clean architecture notes')),
        const AttachmentsState(
          document: DocumentDraft(localId: 'local-1', file: samplePdfFile, title: 'clean architecture notes', phase: UploadPhase.uploading, progress: 1),
        ),
        AttachmentsState(
          document: DocumentDraft(
            localId: 'local-1',
            file: samplePdfFile,
            title: 'clean architecture notes',
            phase: UploadPhase.processing,
            asset: documentAsset(status: MediaStatus.processing),
          ),
        ),
        AttachmentsState(
          document: DocumentDraft(
            localId: 'local-1',
            file: samplePdfFile,
            title: 'clean architecture notes',
            phase: UploadPhase.processing,
            asset: documentAsset(status: MediaStatus.processing, pagesReady: 3),
          ),
        ),
        AttachmentsState(
          document: DocumentDraft(
            localId: 'local-1',
            file: samplePdfFile,
            title: 'clean architecture notes',
            phase: UploadPhase.ready,
            asset: documentAsset(status: MediaStatus.ready, pagesReady: 12),
          ),
        ),
      ],
      verify: (cubit) {
        verify(() => repository.getUpload('doc-asset')).called(2);
        expect(cubit.state.canPublish, isTrue);
        // "Allow download" is on by default for a new PDF (SPEC F26, pre-production step; it was off before).
        expect(cubit.state.requestItems, const [
          AttachmentItem(mediaAssetId: 'doc-asset', order: 0, title: 'clean architecture notes', allowDownload: true),
        ]);
      },
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'a new PDF is uploaded with "Allow download" on, sent explicitly; the writer can turn it off',
      setUp: () => stubDocumentUpload(Ok(documentAsset(status: MediaStatus.ready, pagesReady: 12))),
      build: build,
      act: (cubit) async {
        cubit.setDocument(samplePdfFile);
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.document!.allowDownload, isTrue);
        cubit.setAllowDownload(false);
      },
      verify: (cubit) {
        verify(() => repository.uploadDocument(
              any(),
              title: any(named: 'title'),
              allowDownload: true,
              token: any(named: 'token'),
              onProgress: any(named: 'onProgress'),
            )).called(1);
        expect(cubit.state.document!.allowDownload, isFalse);
        expect(cubit.state.requestItems.single.allowDownload, isFalse);
      },
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'an existing PDF being edited keeps its own value (off stays off)',
      build: build,
      act: (cubit) => cubit.seed(
        const [AttachmentItem(mediaAssetId: 'doc-asset', order: 0, title: 'notes', allowDownload: false)],
        [documentAsset(status: MediaStatus.ready, pagesReady: 12)],
      ),
      verify: (cubit) => expect(cubit.state.document!.allowDownload, isFalse),
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'processing → failed carries the server reason; "try again" re-uploads',
      setUp: () {
        stubDocumentUpload(Ok(documentAsset(status: MediaStatus.processing)));
        stubPolls([Ok(documentAsset(status: MediaStatus.failed, failureReason: FailureCodes.mediaPdfEncrypted))]);
      },
      build: build,
      act: (cubit) => cubit.setDocument(samplePdfFile),
      wait: const Duration(milliseconds: 50),
      skip: 3,
      expect: () => [
        AttachmentsState(
          document: DocumentDraft(
            localId: 'local-1',
            file: samplePdfFile,
            title: 'clean architecture notes',
            phase: UploadPhase.failed,
            asset: documentAsset(status: MediaStatus.failed, failureReason: FailureCodes.mediaPdfEncrypted),
            failure: const Failure(FailureCodes.mediaPdfEncrypted),
          ),
        ),
      ],
      verify: (cubit) {
        expect(cubit.state.blockers, [AttachmentBlocker.failed]);
        verify(() => repository.getUpload('doc-asset')).called(1);
      },
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'processing timeout without a reason falls back to media.processing_failed',
      setUp: () {
        stubDocumentUpload(Ok(documentAsset(status: MediaStatus.processing)));
        stubPolls([Ok(documentAsset(status: MediaStatus.failed))]);
      },
      build: build,
      act: (cubit) => cubit.setDocument(samplePdfFile),
      wait: const Duration(milliseconds: 50),
      verify: (cubit) => expect(cubit.state.document!.failure, const Failure(FailureCodes.mediaProcessingFailed)),
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'removing a processing PDF stops polling and deletes the asset',
      setUp: () {
        stubDocumentUpload(Ok(documentAsset(status: MediaStatus.processing)));
        stubPolls([Ok(documentAsset(status: MediaStatus.processing, pagesReady: 1))]);
      },
      build: build,
      act: (cubit) async {
        cubit.setDocument(samplePdfFile);
        await Future<void>.delayed(Duration.zero);
        cubit.remove('local-1');
      },
      wait: const Duration(milliseconds: 50),
      verify: (cubit) {
        expect(cubit.state.document, isNull);
        verifyNever(() => repository.getUpload(any()));
        verify(() => repository.deleteUpload('doc-asset')).called(1);
      },
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'a PDF over 20 MB is rejected on the device',
      build: build,
      act: (cubit) => cubit.setDocument(const PickedMediaFile(path: '/big.pdf', name: 'big.pdf', sizeBytes: AttachmentLimits.maxPdfBytes + 1)),
      expect: () => [const AttachmentsState(notice: Failure(FailureCodes.mediaTooLarge), noticeSeq: 1)],
      verify: (_) => verifyNever(() => repository.uploadDocument(
            any(),
            title: any(named: 'title'),
            allowDownload: any(named: 'allowDownload'),
            token: any(named: 'token'),
            onProgress: any(named: 'onProgress'),
          )),
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'the document title is required',
      setUp: () => stubDocumentUpload(Ok(documentAsset(status: MediaStatus.ready, pagesReady: 12))),
      build: build,
      act: (cubit) async {
        cubit.setDocument(samplePdfFile);
        await Future<void>.delayed(Duration.zero);
        cubit.setDocumentTitle('  ');
        cubit.setAllowDownload(true);
      },
      verify: (cubit) {
        expect(cubit.state.blockers, [AttachmentBlocker.documentTitle]);
        expect(cubit.state.document!.allowDownload, isTrue);
      },
    );
  });

  group('no mixing', () {
    blocTest<AttachmentsCubit, AttachmentsState>(
      'images cannot be added next to a PDF',
      setUp: () => stubDocumentUpload(Ok(documentAsset(status: MediaStatus.ready, pagesReady: 12))),
      build: build,
      act: (cubit) async {
        cubit.setDocument(samplePdfFile);
        await Future<void>.delayed(Duration.zero);
        cubit.addImages([sampleImageFile]);
        await cubit.pickImages();
      },
      verify: (cubit) {
        expect(cubit.state.images, isEmpty);
        expect(cubit.state.canAddImages, isFalse);
        expect(cubit.state.notice, const Failure(FailureCodes.attachmentsMixedKinds));
        verifyNever(() => picker.pickImages(limit: any(named: 'limit')));
      },
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'a PDF cannot be added next to images',
      setUp: () => stubImageUpload((_, _, _) async => Ok(imageAsset('a1'))),
      build: build,
      act: (cubit) async {
        cubit.addImages([sampleImageFile]);
        cubit.setDocument(samplePdfFile);
        expect(cubit.state.notice, const Failure(FailureCodes.attachmentsMixedKinds));
        await cubit.pickPdf();
      },
      verify: (cubit) {
        expect(cubit.state.document, isNull);
        expect(cubit.state.canAddDocument, isFalse);
        expect(cubit.state.noticeSeq, 2);
        verifyNever(() => picker.pickPdf());
      },
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'the picker is asked for the remaining number of images',
      setUp: () {
        stubImageUpload((file, _, _) async => Ok(imageAsset(file.path)));
        when(() => picker.pickImages(limit: any(named: 'limit'))).thenAnswer((_) async => [sampleImageFile2]);
      },
      build: build,
      act: (cubit) async {
        cubit.addImages([sampleImageFile, sampleImageFile]);
        await cubit.pickImages();
      },
      verify: (cubit) {
        verify(() => picker.pickImages(limit: 8)).called(1);
        expect(cubit.state.images, hasLength(3));
      },
    );
  });

  test('the PDF title is pre-filled from the file name', () {
    expect(AttachmentsCubit.titleFromFileName('Clean_Architecture  notes.v2.pdf'), 'Clean Architecture notes.v2');
    expect(AttachmentsCubit.titleFromFileName('.pdf'), '.pdf');
    expect(AttachmentsCubit.titleFromFileName('${'a' * 5200}.pdf'), hasLength(AttachmentLimits.maxDocumentTitle));
  });

  test('closing the composer cancels uploads and stops polling', () async {
    TransferToken? token;
    stubImageUpload((_, t, _) {
      token = t;
      return Completer<Result<MediaAsset>>().future;
    });
    final cubit = build()..addImages([sampleImageFile]);
    await cubit.close();
    expect(token!.isCancelled, isTrue);
  });
}

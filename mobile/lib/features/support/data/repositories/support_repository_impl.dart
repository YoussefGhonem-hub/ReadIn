import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../admin/domain/entities/paged_list.dart';
import '../../../media/data/datasources/image_compressor.dart';
import '../../../media/domain/entities/media.dart';
import '../../domain/entities/support.dart';
import '../../domain/entities/support_failures.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_api.dart';
import '../datasources/support_attachment_data_source.dart';
import '../models/support_models.dart';

@LazySingleton(as: SupportRepository)
class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._api, this._attachments, this._compressor);

  final SupportApi _api;
  final SupportAttachmentDataSource _attachments;
  final ImageCompressor _compressor;

  @override
  Future<Result<SupportConfig>> config() => _guard(() async => (await _api.config()).toEntity());

  @override
  Future<Result<SupportTicket>> create(NewSupportTicket ticket) => _guard(() async {
        final screenshots = await _screenshots(ticket.screenshots);
        final device = ticket.device;
        final model = await _api.create(
          ticket.category.wire,
          ticket.subject.trim(),
          ticket.message.trim(),
          platform: device.platform,
          osVersion: device.osVersion,
          appVersion: device.appVersion,
          language: device.language,
          screen: device.screen,
          screenshots: screenshots.isEmpty ? null : screenshots,
        );
        return model.toEntity();
      });

  @override
  Future<Result<CursorPage<SupportTicketSummary>>> myTickets(MyTicketsFilter filter, {String? cursor, int limit = 20}) =>
      _guard(() async {
        final page = await _api.myTickets(filter.name, cursor, limit);
        return CursorPage(items: [for (final t in page.items) t.toSummary()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<SupportTicket>> ticket(String id) => _guard(() async => (await _api.ticket(id)).toEntity());

  @override
  Future<Result<SupportMessage>> reply(String ticketId, String message, {List<PickedMediaFile> screenshots = const []}) =>
      _guard(() async {
        final files = await _screenshots(screenshots);
        return (await _api.reply(ticketId, message.trim(), screenshots: files.isEmpty ? null : files)).toEntity();
      });

  @override
  Future<Result<void>> close(String ticketId) => _guard(() => _api.close(ticketId));

  @override
  Future<Result<void>> reopen(String ticketId) => _guard(() => _api.reopen(ticketId));

  @override
  Future<Result<Uint8List>> attachment(String attachmentId) => _guard(() => _attachments.download(attachmentId));

  @override
  Future<Result<PagedList<AdminTicketRow>>> adminTickets(AdminTicketQuery query, {int page = 1, int pageSize = 50}) =>
      _guard(() async {
        final result = await _api.adminTickets({
          'status': query.status.name,
          if (query.category case final category?) 'category': category.wire,
          if (query.q.trim().isNotEmpty) 'q': query.q.trim(),
          'page': page,
          'pageSize': pageSize,
        });
        return PagedList(
          items: [for (final t in result.items) t.toRow()],
          page: result.page,
          pageSize: result.pageSize,
          totalCount: result.totalCount,
          totalPages: result.totalPages,
        );
      });

  @override
  Future<Result<AdminTicket>> adminTicket(String id) => _guard(() async => (await _api.adminTicket(id)).toEntity());

  @override
  Future<Result<SupportMessage>> adminMessage(String ticketId, String body, {required bool internal}) => _guard(
        () async =>
            (await _api.adminMessage(ticketId, AdminTicketMessageRequest(body: body.trim(), internal: internal))).toEntity(),
      );

  @override
  Future<Result<AdminTicket>> adminUpdate(String ticketId, {SupportStatus? status, SupportCategory? category}) =>
      _guard(() async {
        final body = AdminTicketUpdateRequest(status: status?.name, category: category?.wire);
        return (await _api.adminUpdate(ticketId, body)).toEntity();
      });

  /// Each screenshot as a JPEG (EXIF dropped, at most 2048 px, so HEIC from iOS works and the size stays small); the
  /// original file when it can't be compressed. The server decides by the bytes.
  Future<List<MultipartFile>> _screenshots(List<PickedMediaFile> files) async {
    final parts = <MultipartFile>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final jpeg = await _compressor.compress(file.path);
      if (jpeg != null) {
        parts.add(MultipartFile.fromBytes(jpeg, filename: 'screenshot-${i + 1}.jpg', contentType: DioMediaType('image', 'jpeg')));
      } else {
        parts.add(await MultipartFile.fromFile(file.path, filename: file.name, contentType: screenshotMediaType(file.name)));
      }
    }
    return parts;
  }

  /// A screenshot's content type by its extension; the server decides by the bytes.
  static DioMediaType screenshotMediaType(String fileName) => switch (screenshotExtensionOf(fileName)) {
        'png' => DioMediaType('image', 'png'),
        'webp' => DioMediaType('image', 'webp'),
        _ => DioMediaType('image', 'jpeg'),
      };

  /// [guardApi], plus `429 support.limit` with which limit it was ([SupportLimitFailure]) and a picked file that can't
  /// be read any more (`support.attachment_invalid`).
  static Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      final result = await guardApi(() async {
        try {
          return await call();
        } on DioException catch (e) {
          final data = e.response?.data;
          if (data is Map && data['code'] == FailureCodes.supportLimit) {
            throw _SupportLimit(SupportLimitFailure(limit: SupportLimitKind.fromWire(data['limit']), message: data['title'] as String?));
          }
          rethrow;
        }
      });
      return result;
    } on _SupportLimit catch (e) {
      return Err(e.failure);
    } on FileSystemException catch (e) {
      return Err(Failure(FailureCodes.supportAttachmentInvalid, message: e.message));
    }
  }
}

class _SupportLimit implements Exception {
  const _SupportLimit(this.failure);

  final SupportLimitFailure failure;
}

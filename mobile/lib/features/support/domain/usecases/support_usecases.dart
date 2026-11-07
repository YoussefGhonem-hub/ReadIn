import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../admin/domain/entities/paged_list.dart';
import '../../../media/domain/entities/media.dart';
import '../../data/datasources/support_device_source.dart';
import '../entities/support.dart';
import '../repositories/support_repository.dart';

/// `GET /support/config`, read once per run: the support email and the categories.
@lazySingleton
class GetSupportConfig {
  GetSupportConfig(this._repository);

  final SupportRepository _repository;

  Future<Result<SupportConfig>>? _config;

  Future<Result<SupportConfig>> call() async {
    final pending = _config ??= _repository.config();
    final result = await pending;
    // A failure is asked again next time.
    if (!result.isOk && identical(_config, pending)) _config = null;
    return result;
  }
}

/// Sends a new ticket with the device details the app adds (F35).
@injectable
class CreateSupportTicket {
  const CreateSupportTicket(this._repository, this._device);

  final SupportRepository _repository;
  final SupportDeviceSource _device;

  Future<Result<SupportTicket>> call({
    required SupportCategory category,
    required String subject,
    required String message,
    List<PickedMediaFile> screenshots = const [],
    String? screen,
  }) async =>
      _repository.create(NewSupportTicket(
        category: category,
        subject: subject.trim(),
        message: message.trim(),
        screenshots: screenshots,
        device: await _device.read(screen: screen),
      ));
}

/// My tickets: active or closed, 20 a page.
@injectable
class GetMyTickets {
  const GetMyTickets(this._repository);

  final SupportRepository _repository;

  static const pageSize = 20;

  Future<Result<CursorPage<SupportTicketSummary>>> call(MyTicketsFilter filter, {String? cursor}) =>
      _repository.myTickets(filter, cursor: cursor, limit: pageSize);
}

/// The member's ticket: read it, reply (with screenshots), close and reopen it.
@injectable
class MyTicketCommands {
  const MyTicketCommands(this._repository);

  final SupportRepository _repository;

  Future<Result<SupportTicket>> get(String id) => _repository.ticket(id);

  Future<Result<SupportMessage>> reply(String id, String message, {List<PickedMediaFile> screenshots = const []}) =>
      _repository.reply(id, message.trim(), screenshots: screenshots);

  Future<Result<void>> close(String id) => _repository.close(id);

  Future<Result<void>> reopen(String id) => _repository.reopen(id);
}

/// A screenshot's bytes, read with the session (the ticket's member or `support.manage`).
@injectable
class LoadSupportAttachment {
  const LoadSupportAttachment(this._repository);

  final SupportRepository _repository;

  Future<Result<Uint8List>> call(String attachmentId) => _repository.attachment(attachmentId);
}

/// The console's ticket queue, 50 a page.
@injectable
class GetAdminTickets {
  const GetAdminTickets(this._repository);

  final SupportRepository _repository;

  static const pageSize = 50;

  Future<Result<PagedList<AdminTicketRow>>> call(AdminTicketQuery query, {int page = 1}) =>
      _repository.adminTickets(query, page: page, pageSize: pageSize);
}

/// A ticket in the console: read it, reply or add an internal note, change its category, close or reopen it.
@injectable
class AdminTicketCommands {
  const AdminTicketCommands(this._repository);

  final SupportRepository _repository;

  Future<Result<AdminTicket>> get(String id) => _repository.adminTicket(id);

  Future<Result<SupportMessage>> post(String id, String body, {required bool internal}) =>
      _repository.adminMessage(id, body.trim(), internal: internal);

  Future<Result<AdminTicket>> update(String id, {SupportStatus? status, SupportCategory? category}) =>
      _repository.adminUpdate(id, status: status, category: category);
}

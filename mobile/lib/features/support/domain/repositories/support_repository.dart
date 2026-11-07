import 'dart:typed_data';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../admin/domain/entities/paged_list.dart';
import '../../../media/domain/entities/media.dart';
import '../entities/support.dart';

/// Help & support tickets (F35): the member's side and the console's queue.
abstract interface class SupportRepository {
  /// `GET /support/config` (no account needed).
  Future<Result<SupportConfig>> config();

  /// `POST /support/tickets` (multipart). `429 support.limit` ([SupportLimitFailure]), `400 validation.failed`,
  /// `support.attachment_invalid`, `support.too_many_attachments`.
  Future<Result<SupportTicket>> create(NewSupportTicket ticket);

  /// `GET /me/support/tickets`: active (Open or Answered) or closed, latest activity first.
  Future<Result<CursorPage<SupportTicketSummary>>> myTickets(MyTicketsFilter filter, {String? cursor, int limit = 20});

  /// `GET /support/tickets/{id}`. `404 support.ticket_not_found`.
  Future<Result<SupportTicket>> ticket(String id);

  /// `POST /support/tickets/{id}/messages` (multipart). `409 support.ticket_closed`.
  Future<Result<SupportMessage>> reply(String ticketId, String message, {List<PickedMediaFile> screenshots = const []});

  /// `POST /support/tickets/{id}/close` (idempotent).
  Future<Result<void>> close(String ticketId);

  /// `POST /support/tickets/{id}/reopen`. `409 support.reopen_expired`.
  Future<Result<void>> reopen(String ticketId);

  /// `GET /support/attachments/{id}`: the image's bytes, with the session.
  Future<Result<Uint8List>> attachment(String attachmentId);

  /// `GET /admin/support/tickets` (`support.manage`).
  Future<Result<PagedList<AdminTicketRow>>> adminTickets(AdminTicketQuery query, {int page = 1, int pageSize = 50});

  /// `GET /admin/support/tickets/{id}`.
  Future<Result<AdminTicket>> adminTicket(String id);

  /// `POST /admin/support/tickets/{id}/messages`: a reply, or an internal note ([internal]).
  Future<Result<SupportMessage>> adminMessage(String ticketId, String body, {required bool internal});

  /// `PATCH /admin/support/tickets/{id}`: close or reopen ([status]), or change the [category].
  Future<Result<AdminTicket>> adminUpdate(String ticketId, {SupportStatus? status, SupportCategory? category});
}

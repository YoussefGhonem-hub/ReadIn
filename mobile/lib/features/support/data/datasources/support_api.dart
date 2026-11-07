import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/support_models.dart';

part 'support_api.g.dart';

/// Help & support tickets (F35): the member's routes (`support.create`) and the console's queue (`support.manage`).
/// Writes use the `writes` rate limit; `GET /support/config` needs no account.
@lazySingleton
@RestApi()
abstract class SupportApi {
  @factoryMethod
  factory SupportApi(Dio dio) = _SupportApi;

  @GET('/support/config')
  Future<SupportConfigModel> config();

  /// `multipart/form-data`: the ticket, the device details the app adds, and 0–3 screenshots. `201 SupportTicketDto`.
  @POST('/support/tickets')
  @MultiPart()
  Future<SupportTicketModel> create(
    @Part(name: 'category') String category,
    @Part(name: 'subject') String subject,
    @Part(name: 'message') String message, {
    @Part(name: 'platform') String? platform,
    @Part(name: 'osVersion') String? osVersion,
    @Part(name: 'appVersion') String? appVersion,
    @Part(name: 'language') String? language,
    @Part(name: 'screen') String? screen,
    @Part(name: 'screenshots') List<MultipartFile>? screenshots,
  });

  /// `status` = `active` | `closed`; null = all. Latest activity first.
  @GET('/me/support/tickets')
  Future<SupportTicketPageModel> myTickets(
    @Query('status') String? status,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  @GET('/support/tickets/{id}')
  Future<SupportTicketModel> ticket(@Path('id') String id);

  /// `multipart/form-data`: `message` (1–2000) and 0–3 screenshots. `201 SupportMessageDto`.
  @POST('/support/tickets/{id}/messages')
  @MultiPart()
  Future<SupportMessageModel> reply(
    @Path('id') String id,
    @Part(name: 'message') String message, {
    @Part(name: 'screenshots') List<MultipartFile>? screenshots,
  });

  @POST('/support/tickets/{id}/close')
  Future<void> close(@Path('id') String id);

  @POST('/support/tickets/{id}/reopen')
  Future<void> reopen(@Path('id') String id);

  /// `status` = `open` (waiting longest first) | `answered` | `closed`; `category`; `q` (subject, member, `#12`).
  @GET('/admin/support/tickets')
  Future<AdminTicketPageModel> adminTickets(@Queries() Map<String, dynamic> query);

  @GET('/admin/support/tickets/{id}')
  Future<AdminTicketModel> adminTicket(@Path('id') String id);

  /// A reply (`internal: false`, the ticket becomes Answered) or an internal note. `201 AdminSupportMessageDto`.
  @POST('/admin/support/tickets/{id}/messages')
  Future<SupportMessageModel> adminMessage(@Path('id') String id, @Body() AdminTicketMessageRequest body);

  /// `{ status?: open | closed, category? }` → `200 AdminTicketDto`.
  @PATCH('/admin/support/tickets/{id}')
  Future<AdminTicketModel> adminUpdate(@Path('id') String id, @Body() AdminTicketUpdateRequest body);
}

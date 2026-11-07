import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../domain/entities/support.dart';

part 'support_models.freezed.dart';
part 'support_models.g.dart';

/// `GET /support/config` (`SupportConfigDto`).
@freezed
abstract class SupportConfigModel with _$SupportConfigModel {
  const SupportConfigModel._();

  const factory SupportConfigModel({
    String? email,
    @Default(<String>[]) List<String> categories,
    @Default(SupportLimits.maxScreenshots) int maxAttachments,
    @Default(SupportLimits.screenshotMaxBytes) int maxAttachmentBytes,
  }) = _SupportConfigModel;

  factory SupportConfigModel.fromJson(Map<String, dynamic> json) => _$SupportConfigModelFromJson(json);

  SupportConfig toEntity() {
    final known = [for (final c in categories) ?SupportCategory.fromWire(c)];
    final address = email?.trim() ?? '';
    return SupportConfig(
      email: address.isEmpty ? null : address,
      categories: known.isEmpty ? SupportCategory.values : known,
      maxAttachments: maxAttachments,
      maxAttachmentBytes: maxAttachmentBytes,
    );
  }
}

/// `SupportDeviceDto`.
@freezed
abstract class SupportDeviceModel with _$SupportDeviceModel {
  const SupportDeviceModel._();

  const factory SupportDeviceModel({
    String? platform,
    String? osVersion,
    String? appVersion,
    String? language,
    String? screen,
  }) = _SupportDeviceModel;

  factory SupportDeviceModel.fromJson(Map<String, dynamic> json) => _$SupportDeviceModelFromJson(json);

  SupportDevice toEntity() =>
      SupportDevice(platform: platform, osVersion: osVersion, appVersion: appVersion, language: language, screen: screen);
}

/// `SupportAttachmentDto`.
@freezed
abstract class SupportAttachmentModel with _$SupportAttachmentModel {
  const SupportAttachmentModel._();

  const factory SupportAttachmentModel({
    required String id,
    @Default('image/jpeg') String contentType,
    @Default(0) int sizeBytes,
  }) = _SupportAttachmentModel;

  factory SupportAttachmentModel.fromJson(Map<String, dynamic> json) => _$SupportAttachmentModelFromJson(json);

  SupportAttachment toEntity() => SupportAttachment(id: id, contentType: contentType, sizeBytes: sizeBytes);
}

/// `AdminSupportMessageDto.author`.
@freezed
abstract class SupportPersonModel with _$SupportPersonModel {
  const SupportPersonModel._();

  const factory SupportPersonModel({required String id, @Default('') String displayName, @Default('') String username}) =
      _SupportPersonModel;

  factory SupportPersonModel.fromJson(Map<String, dynamic> json) => _$SupportPersonModelFromJson(json);

  SupportPerson toEntity() => SupportPerson(id: id, displayName: displayName, username: username);
}

/// `SupportMessageDto`, and `AdminSupportMessageDto` (with [isInternalNote] and [author]).
@freezed
abstract class SupportMessageModel with _$SupportMessageModel {
  const SupportMessageModel._();

  const factory SupportMessageModel({
    required String id,
    @Default(false) bool fromSupport,
    @Default('') String body,
    @Default(<SupportAttachmentModel>[]) List<SupportAttachmentModel> attachments,
    required DateTime createdAt,
    @Default(false) bool isInternalNote,
    SupportPersonModel? author,
  }) = _SupportMessageModel;

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) => _$SupportMessageModelFromJson(json);

  SupportMessage toEntity() => SupportMessage(
        id: id,
        fromSupport: fromSupport,
        body: body,
        attachments: [for (final a in attachments) a.toEntity()],
        createdAt: createdAt,
        isInternalNote: isInternalNote,
        author: author?.toEntity(),
      );
}

/// `lastMessage` of a ticket row.
@freezed
abstract class SupportLastMessageModel with _$SupportLastMessageModel {
  const SupportLastMessageModel._();

  const factory SupportLastMessageModel({
    @Default(false) bool fromSupport,
    @Default(false) bool isInternalNote,
    @Default('') String excerpt,
    required DateTime createdAt,
  }) = _SupportLastMessageModel;

  factory SupportLastMessageModel.fromJson(Map<String, dynamic> json) => _$SupportLastMessageModelFromJson(json);

  SupportLastMessage toEntity() =>
      SupportLastMessage(fromSupport: fromSupport, isInternalNote: isInternalNote, excerpt: excerpt, createdAt: createdAt);
}

/// `SupportTicketDto` (a summary when [messages] and [device] are absent: `SupportTicketSummaryDto`).
@freezed
abstract class SupportTicketModel with _$SupportTicketModel {
  const SupportTicketModel._();

  const factory SupportTicketModel({
    required String id,
    @Default(0) int number,
    String? category,
    @Default('') String subject,
    String? status,
    required DateTime createdAt,
    required DateTime updatedAt,
    SupportLastMessageModel? lastMessage,
    DateTime? closedAt,
    @Default(false) bool canReopen,
    SupportDeviceModel? device,
    @Default(<SupportMessageModel>[]) List<SupportMessageModel> messages,
  }) = _SupportTicketModel;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) => _$SupportTicketModelFromJson(json);

  SupportTicketSummary toSummary() => SupportTicketSummary(
        id: id,
        number: number,
        category: SupportCategory.fromWire(category),
        subject: subject,
        status: SupportStatus.fromWire(status),
        createdAt: createdAt,
        updatedAt: updatedAt,
        lastMessage: lastMessage?.toEntity() ?? SupportLastMessage(fromSupport: false, excerpt: '', createdAt: updatedAt),
        closedAt: closedAt,
        canReopen: canReopen,
      );

  SupportTicket toEntity() => SupportTicket(
        summary: toSummary(),
        device: device?.toEntity() ?? const SupportDevice(),
        messages: [for (final m in messages) m.toEntity()],
      );
}

/// `CursorPage<SupportTicketSummaryDto>`.
@freezed
abstract class SupportTicketPageModel with _$SupportTicketPageModel {
  const factory SupportTicketPageModel({
    @Default(<SupportTicketModel>[]) List<SupportTicketModel> items,
    String? nextCursor,
  }) = _SupportTicketPageModel;

  factory SupportTicketPageModel.fromJson(Map<String, dynamic> json) => _$SupportTicketPageModelFromJson(json);
}

/// `AdminTicketRowDto`, and `AdminTicketDto` with the page's extra parts.
@freezed
abstract class AdminTicketModel with _$AdminTicketModel {
  const AdminTicketModel._();

  const factory AdminTicketModel({
    required String id,
    @Default(0) int number,
    String? category,
    @Default('') String subject,
    String? status,
    required AuthorModel user,
    required DateTime createdAt,
    DateTime? waitingSince,
    SupportLastMessageModel? lastMessage,
    DateTime? closedAt,
    // The page (`GET /admin/support/tickets/{id}`).
    SupportDeviceModel? device,
    @Default(<SupportMessageModel>[]) List<SupportMessageModel> messages,
    String? closedBy,
    AdminTicketMemberModel? member,
    AdminTicketReportsModel? reportsFiled,
    int? reportsAgainst,
    List<AdminTicketModerationModel>? moderation,
  }) = _AdminTicketModel;

  factory AdminTicketModel.fromJson(Map<String, dynamic> json) => _$AdminTicketModelFromJson(json);

  AdminTicketRow toRow() => AdminTicketRow(
        id: id,
        number: number,
        category: SupportCategory.fromWire(category),
        subject: subject,
        status: SupportStatus.fromWire(status),
        user: user.toEntity(),
        createdAt: createdAt,
        waitingSince: waitingSince,
        lastMessage: lastMessage?.toEntity() ?? SupportLastMessage(fromSupport: false, excerpt: '', createdAt: createdAt),
        closedAt: closedAt,
      );

  AdminTicket toEntity() => AdminTicket(
        row: toRow(),
        device: device?.toEntity() ?? const SupportDevice(),
        messages: [for (final m in messages) m.toEntity()],
        closedBy: SupportClosedBy.fromWire(closedBy),
        member: member?.toEntity() ?? AdminTicketMember(joinedAt: createdAt),
        reportsFiled: reportsFiled == null ? null : [for (final r in reportsFiled!.items) r.toEntity()],
        reportsFiledTotal: reportsFiled?.total ?? 0,
        reportsAgainst: reportsAgainst,
        moderation: moderation == null ? null : [for (final m in moderation!) m.toEntity()],
      );
}

/// `AdminTicketDto.member`: the user card.
@freezed
abstract class AdminTicketMemberModel with _$AdminTicketMemberModel {
  const AdminTicketMemberModel._();

  const factory AdminTicketMemberModel({
    String? status,
    DateTime? suspendedUntil,
    required DateTime joinedAt,
    @Default(<String>[]) List<String> signInMethods,
    @Default(0) int ticketCount,
  }) = _AdminTicketMemberModel;

  factory AdminTicketMemberModel.fromJson(Map<String, dynamic> json) => _$AdminTicketMemberModelFromJson(json);

  AdminTicketMember toEntity() => AdminTicketMember(
        suspended: status == 'suspended',
        suspendedUntil: suspendedUntil,
        joinedAt: joinedAt,
        signInMethods: signInMethods,
        ticketCount: ticketCount,
      );
}

/// `AdminTicketDto.reportsFiled`: `{ items, total }`.
@freezed
abstract class AdminTicketReportsModel with _$AdminTicketReportsModel {
  const factory AdminTicketReportsModel({
    @Default(<AdminTicketReportModel>[]) List<AdminTicketReportModel> items,
    @Default(0) int total,
  }) = _AdminTicketReportsModel;

  factory AdminTicketReportsModel.fromJson(Map<String, dynamic> json) => _$AdminTicketReportsModelFromJson(json);
}

/// `AdminUserReportDto`, as a ticket page lists it.
@freezed
abstract class AdminTicketReportModel with _$AdminTicketReportModel {
  const AdminTicketReportModel._();

  const factory AdminTicketReportModel({
    required String id,
    @Default('') String targetType,
    String? targetLabel,
    @Default('other') String reason,
    @Default('open') String status,
    required DateTime createdAt,
  }) = _AdminTicketReportModel;

  factory AdminTicketReportModel.fromJson(Map<String, dynamic> json) => _$AdminTicketReportModelFromJson(json);

  AdminTicketReport toEntity() => AdminTicketReport(
        id: id,
        targetType: targetType,
        targetLabel: targetLabel,
        reason: reason,
        status: status,
        createdAt: createdAt,
      );
}

/// `ModerationActionDto`, as a ticket page lists it.
@freezed
abstract class AdminTicketModerationModel with _$AdminTicketModerationModel {
  const AdminTicketModerationModel._();

  const factory AdminTicketModerationModel({
    required String id,
    @Default('') String action,
    String? note,
    DateTime? suspendedUntil,
    required DateTime createdAt,
  }) = _AdminTicketModerationModel;

  factory AdminTicketModerationModel.fromJson(Map<String, dynamic> json) => _$AdminTicketModerationModelFromJson(json);

  AdminTicketModeration toEntity() =>
      AdminTicketModeration(id: id, action: action, note: note, suspendedUntil: suspendedUntil, createdAt: createdAt);
}

/// `PagedList<AdminTicketRowDto>`.
@freezed
abstract class AdminTicketPageModel with _$AdminTicketPageModel {
  const factory AdminTicketPageModel({
    @Default(<AdminTicketModel>[]) List<AdminTicketModel> items,
    @Default(1) int page,
    @Default(50) int pageSize,
    @Default(0) int totalCount,
    @Default(0) int totalPages,
  }) = _AdminTicketPageModel;

  factory AdminTicketPageModel.fromJson(Map<String, dynamic> json) => _$AdminTicketPageModelFromJson(json);
}

/// `POST /admin/support/tickets/{id}/messages` body.
@freezed
abstract class AdminTicketMessageRequest with _$AdminTicketMessageRequest {
  const factory AdminTicketMessageRequest({required String body, required bool internal}) = _AdminTicketMessageRequest;

  factory AdminTicketMessageRequest.fromJson(Map<String, dynamic> json) => _$AdminTicketMessageRequestFromJson(json);
}

/// `PATCH /admin/support/tickets/{id}` body: at least one of the two; null fields are left out.
@freezed
abstract class AdminTicketUpdateRequest with _$AdminTicketUpdateRequest {
  @JsonSerializable(includeIfNull: false)
  const factory AdminTicketUpdateRequest({String? status, String? category}) = _AdminTicketUpdateRequest;

  factory AdminTicketUpdateRequest.fromJson(Map<String, dynamic> json) => _$AdminTicketUpdateRequestFromJson(json);
}

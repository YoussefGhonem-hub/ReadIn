import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';
import '../../../media/domain/entities/media.dart';

/// Help & support tickets (SPEC F35, docs/api/contract-v1.md "Support"). The server checks everything again; a
/// screenshot is checked there by its bytes.
abstract final class SupportLimits {
  static const subjectMin = 5;
  static const subjectMax = 120;

  /// A new ticket's first message.
  static const firstMessageMin = 10;
  static const messageMax = 2000;
  static const maxScreenshots = 3;
  static const screenshotMaxBytes = 5 * 1024 * 1024;

  /// The image types a screenshot may be, by extension (the server reads the bytes).
  static const screenshotExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  /// A closed ticket can be reopened this long after it was closed.
  static const reopenWithin = Duration(days: 30);
}

/// `SupportCategory`, in the order the form lists it.
enum SupportCategory {
  appProblem('app_problem'),
  account('account'),
  content('content'),
  verification('verification'),
  suggestion('suggestion'),
  other('other');

  const SupportCategory(this.wire);

  final String wire;

  /// Null for a category this app version doesn't know.
  static SupportCategory? fromWire(String? wire) => values.where((c) => c.wire == wire).firstOrNull;
}

/// `SupportStatus`: Open (waiting for support), Answered (waiting for the member), Closed.
enum SupportStatus {
  open,
  answered,
  closed;

  static SupportStatus fromWire(String? wire) => values.where((s) => s.name == wire).firstOrNull ?? open;
}

/// Who closed a ticket (`AdminTicketDto.closedBy`).
enum SupportClosedBy {
  member,
  support,
  auto;

  static SupportClosedBy? fromWire(String? wire) => values.where((s) => s.name == wire).firstOrNull;
}

/// `GET /support/config`: the support email (null when none is set) and the form's rules.
class SupportConfig extends Equatable {
  const SupportConfig({
    this.email,
    this.categories = SupportCategory.values,
    this.maxAttachments = SupportLimits.maxScreenshots,
    this.maxAttachmentBytes = SupportLimits.screenshotMaxBytes,
  });

  final String? email;
  final List<SupportCategory> categories;
  final int maxAttachments;
  final int maxAttachmentBytes;

  @override
  List<Object?> get props => [email, categories, maxAttachments, maxAttachmentBytes];
}

/// `SupportDeviceDto`: what the app added to the ticket. No device identifier.
class SupportDevice extends Equatable {
  const SupportDevice({this.platform, this.osVersion, this.appVersion, this.language, this.screen});

  /// `ios` | `android` | `web`.
  final String? platform;

  /// e.g. "Android 15", "iOS 18.1".
  final String? osVersion;

  /// Version and build, e.g. "1.2.0+57".
  final String? appVersion;

  /// The UI language, `ar` | `en`.
  final String? language;

  /// The route the ticket came from.
  final String? screen;

  bool get isEmpty => platform == null && osVersion == null && appVersion == null && language == null && screen == null;

  @override
  List<Object?> get props => [platform, osVersion, appVersion, language, screen];
}

/// A screenshot of a message: read with the session from `GET /support/attachments/{id}`, never cached on disk.
class SupportAttachment extends Equatable {
  const SupportAttachment({required this.id, this.contentType = 'image/jpeg', this.sizeBytes = 0});

  final String id;
  final String contentType;
  final int sizeBytes;

  @override
  List<Object?> get props => [id, contentType, sizeBytes];
}

/// A message of the conversation. The member sees support's replies as from «فريق الدعم» / "Support".
class SupportMessage extends Equatable {
  const SupportMessage({
    required this.id,
    required this.fromSupport,
    required this.body,
    required this.createdAt,
    this.attachments = const [],
    this.isInternalNote = false,
    this.author,
  });

  final String id;
  final bool fromSupport;
  final String body;
  final List<SupportAttachment> attachments;
  final DateTime createdAt;

  /// Admins only: a note the member never sees.
  final bool isInternalNote;

  /// Admins only: who wrote it; null once that account is deleted, and always for members.
  final SupportPerson? author;

  @override
  List<Object?> get props => [id, fromSupport, body, attachments, createdAt, isInternalNote, author];
}

/// The member or the admin who wrote a message (admins see it).
class SupportPerson extends Equatable {
  const SupportPerson({required this.id, required this.displayName, required this.username});

  final String id;
  final String displayName;
  final String username;

  @override
  List<Object?> get props => [id, displayName, username];
}

/// The latest message of a ticket, one line.
class SupportLastMessage extends Equatable {
  const SupportLastMessage({required this.fromSupport, required this.excerpt, required this.createdAt, this.isInternalNote = false});

  final bool fromSupport;
  final bool isInternalNote;
  final String excerpt;
  final DateTime createdAt;

  @override
  List<Object?> get props => [fromSupport, isInternalNote, excerpt, createdAt];
}

/// A row of My tickets (`SupportTicketSummaryDto`), and the head of a ticket page.
class SupportTicketSummary extends Equatable {
  const SupportTicketSummary({
    required this.id,
    required this.number,
    required this.category,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessage,
    this.closedAt,
    this.canReopen = false,
  });

  final String id;

  /// Shown as "#12".
  final int number;

  /// Null for a category this app version doesn't know (shown as "Other").
  final SupportCategory? category;
  final String subject;
  final SupportStatus status;
  final DateTime createdAt;

  /// The latest message: the list order.
  final DateTime updatedAt;
  final SupportLastMessage lastMessage;
  final DateTime? closedAt;

  /// Closed less than 30 days ago.
  final bool canReopen;

  bool get isClosed => status == SupportStatus.closed;

  @override
  List<Object?> get props => [id, number, category, subject, status, createdAt, updatedAt, lastMessage, closedAt, canReopen];
}

/// A ticket's page for its member (`SupportTicketDto`): never internal notes.
class SupportTicket extends Equatable {
  const SupportTicket({required this.summary, this.device = const SupportDevice(), this.messages = const []});

  final SupportTicketSummary summary;
  final SupportDevice device;

  /// Oldest first.
  final List<SupportMessage> messages;

  String get id => summary.id;

  @override
  List<Object?> get props => [summary, device, messages];
}

/// A new ticket (`POST /support/tickets`, multipart).
class NewSupportTicket extends Equatable {
  const NewSupportTicket({
    required this.category,
    required this.subject,
    required this.message,
    this.screenshots = const [],
    this.device = const SupportDevice(),
  });

  final SupportCategory category;
  final String subject;
  final String message;

  /// 0–3 JPEG, PNG or WebP images of at most 5 MB.
  final List<PickedMediaFile> screenshots;
  final SupportDevice device;

  @override
  List<Object?> get props => [category, subject, message, screenshots, device];
}

/// The two ticket lists of the member: active (Open or Answered) and closed.
enum MyTicketsFilter {
  active,
  closed;
}

/// A row of the console's queue (`AdminTicketRowDto`).
class AdminTicketRow extends Equatable {
  const AdminTicketRow({
    required this.id,
    required this.number,
    required this.category,
    required this.subject,
    required this.status,
    required this.user,
    required this.createdAt,
    required this.lastMessage,
    this.waitingSince,
    this.closedAt,
  });

  final String id;
  final int number;
  final SupportCategory? category;
  final String subject;
  final SupportStatus status;

  /// The member.
  final Author user;
  final DateTime createdAt;

  /// Open: the member's last message ("waiting 3 h"); null otherwise.
  final DateTime? waitingSince;
  final SupportLastMessage lastMessage;
  final DateTime? closedAt;

  @override
  List<Object?> get props => [id, number, category, subject, status, user, createdAt, waitingSince, lastMessage, closedAt];
}

/// The member card of a console ticket.
class AdminTicketMember extends Equatable {
  const AdminTicketMember({
    required this.joinedAt,
    this.suspended = false,
    this.suspendedUntil,
    this.signInMethods = const [],
    this.ticketCount = 0,
  });

  final bool suspended;
  final DateTime? suspendedUntil;
  final DateTime joinedAt;

  /// `phone` | `google` | `apple`.
  final List<String> signInMethods;
  final int ticketCount;

  @override
  List<Object?> get props => [suspended, suspendedUntil, joinedAt, signInMethods, ticketCount];
}

/// A ticket in the console (`AdminTicketDto`): the conversation with internal notes, the member's card, the device,
/// and their reports and moderation history (null without `moderation.manage`).
class AdminTicket extends Equatable {
  const AdminTicket({
    required this.row,
    required this.member,
    this.device = const SupportDevice(),
    this.messages = const [],
    this.closedBy,
    this.reportsFiled,
    this.reportsFiledTotal = 0,
    this.reportsAgainst,
    this.moderation,
  });

  final AdminTicketRow row;
  final SupportDevice device;
  final List<SupportMessage> messages;
  final SupportClosedBy? closedBy;
  final AdminTicketMember member;

  /// Their reports, newest first (≤ 10); null without `moderation.manage`.
  final List<AdminTicketReport>? reportsFiled;
  final int reportsFiledTotal;

  /// Open reports about them, their articles and comments.
  final int? reportsAgainst;

  /// Warnings and suspensions about them, newest first (≤ 10).
  final List<AdminTicketModeration>? moderation;

  String get id => row.id;

  @override
  List<Object?> get props =>
      [row, device, messages, closedBy, member, reportsFiled, reportsFiledTotal, reportsAgainst, moderation];
}

/// A report the member filed, as a ticket page lists it.
class AdminTicketReport extends Equatable {
  const AdminTicketReport({
    required this.id,
    required this.targetType,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.targetLabel,
  });

  final String id;
  final String targetType;
  final String? targetLabel;
  final String reason;
  final String status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, targetType, targetLabel, reason, status, createdAt];
}

/// A warning or suspension of the member, as a ticket page lists it.
class AdminTicketModeration extends Equatable {
  const AdminTicketModeration({required this.id, required this.action, required this.createdAt, this.note, this.suspendedUntil});

  /// `user.warn`, `user.suspend`, …
  final String id;
  final String action;
  final String? note;
  final DateTime? suspendedUntil;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, action, note, suspendedUntil, createdAt];
}

/// The console queue's filters: a status tab, a category and a search (subject, member, or "#12").
class AdminTicketQuery extends Equatable {
  const AdminTicketQuery({this.status = SupportStatus.open, this.category, this.q = ''});

  final SupportStatus status;
  final SupportCategory? category;
  final String q;

  AdminTicketQuery copyWith({SupportStatus? status, SupportCategory? Function()? category, String? q}) => AdminTicketQuery(
        status: status ?? this.status,
        category: category != null ? category() : this.category,
        q: q ?? this.q,
      );

  @override
  List<Object?> get props => [status, category, q];
}

/// The lower-cased extension of [fileName] (`Shot.PNG` → `png`), or empty.
String screenshotExtensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot < 0 || dot == fileName.length - 1 ? '' : fileName.substring(dot + 1).toLowerCase();
}

/// Whether [file] may be sent as a screenshot: JPEG, PNG or WebP by its extension and not over 5 MB (an unknown size is
/// left to the server).
bool isAcceptedScreenshot(PickedMediaFile file) =>
    SupportLimits.screenshotExtensions.contains(screenshotExtensionOf(file.name)) &&
    (file.sizeBytes ?? 0) <= SupportLimits.screenshotMaxBytes;

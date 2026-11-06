import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/features/notifications/domain/entities/app_notification.dart';
import 'package:readin/features/notifications/domain/entities/notification_settings.dart';
import 'package:readin/features/notifications/domain/repositories/notifications_repository.dart';

/// The notification center's clock in tests: 4 Nov 2026, 18:00 local time.
final notificationsNow = DateTime(2026, 11, 4, 18);

const mona = NotificationActor(id: 'u-mona', displayName: 'منى عادل', username: 'mona_dev', isVerified: true);
const ahmed = NotificationActor(id: 'u-ahmed', displayName: 'Ahmed Samir', username: 'ahmed');
const sara = NotificationActor(id: 'u-sara', displayName: 'سارة', username: 'sara');

const diArticle = NotificationArticle(
  id: 'art-1',
  slug: 'di-dotnet',
  title: 'الـ Dependency Injection في .NET بالبلدي',
  language: 'ar-EG',
);
const ragArticle = NotificationArticle(
  id: 'art-2',
  slug: 'rag-vs-fine-tuning',
  title: 'RAG vs fine-tuning: when to use which',
  language: 'en',
);

AppNotification notification(
  String id,
  NotificationType type, {
  Duration ago = const Duration(minutes: 5),
  bool isRead = false,
  NotificationActor? actor,
  int actorCount = 0,
  NotificationArticle? article,
  NotificationComment? comment,
  int? threshold,
  int? streakDays,
  SecurityChange? securityChange,
  bool? approved,
  int? articleCount,
  String? link,
}) {
  final at = notificationsNow.subtract(ago);
  return AppNotification(
    id: id,
    type: type,
    createdAt: at,
    updatedAt: at,
    isRead: isRead,
    actor: actor,
    actorCount: actorCount,
    article: article,
    comment: comment,
    threshold: threshold,
    streakDays: streakDays,
    securityChange: securityChange,
    approved: approved,
    articleCount: articleCount,
    link: link ?? (article == null ? '' : 'readin://a/${article.slug}'),
  );
}

/// The official @readin account (F17): its new articles of a day come in one entry.
const readinActor = NotificationActor(id: 'u-readin', displayName: 'ReadIn', username: 'readin', isVerified: true);

/// @readin's day entry with [count] articles, [diArticle] the newest: two or more open the account's profile.
AppNotification readinDay(int count, {String id = 'n-readin', bool isRead = false, Duration ago = const Duration(minutes: 20)}) =>
    notification(
      id,
      NotificationType.followedWriterArticle,
      ago: ago,
      isRead: isRead,
      actor: readinActor,
      actorCount: 1,
      article: diArticle,
      articleCount: count,
      link: count >= 2 ? 'readin://u/readin' : 'readin://a/${diArticle.slug}',
    );

/// A mixed center: Today (an unread reply, ten commenters on an English article, three new followers) and Earlier (a
/// mention in a comment by a deleted account, a mention in an English article, a milestone, today's article, a streak
/// reminder, a security alert, a followed writer, a moderation warning).
final mixedNotifications = [
  notification(
    'n-reply',
    NotificationType.commentReply,
    actor: mona,
    actorCount: 1,
    article: diArticle,
    comment: const NotificationComment(id: 'c-7', parentId: 'c-1', excerpt: 'تمام كده، بس الـ Scoped بيعيش قد إيه بالظبط؟'),
    link: 'readin://a/di-dotnet#comment-c-7',
  ),
  notification(
    'n-comments',
    NotificationType.articleComment,
    ago: const Duration(hours: 2),
    actor: ahmed,
    actorCount: 10,
    article: ragArticle,
    comment: const NotificationComment(id: 'c-9', excerpt: 'Great breakdown, the cost table helped a lot.'),
    link: 'readin://a/rag-vs-fine-tuning#comment-c-9',
  ),
  notification(
    'n-followers',
    NotificationType.newFollower,
    ago: const Duration(hours: 5),
    isRead: true,
    actor: sara,
    actorCount: 3,
    link: 'readin://u/reader1/followers',
  ),
  notification(
    'n-mention',
    NotificationType.mention,
    ago: const Duration(days: 1),
    actorCount: 1,
    article: diArticle,
    comment: const NotificationComment(id: 'c-3', excerpt: '@reader1 شوف الجزء بتاع الـ lifetime'),
    link: 'readin://a/di-dotnet#comment-c-3',
  ),
  // Mentioned in an article: no comment, the link opens the article itself.
  notification(
    'n-article-mention',
    NotificationType.mention,
    ago: const Duration(days: 1, hours: 1),
    isRead: true,
    actor: ahmed,
    actorCount: 1,
    article: ragArticle,
  ),
  notification('n-milestone', NotificationType.reactionsMilestone, ago: const Duration(days: 1, hours: 3), isRead: true, article: ragArticle, threshold: 50),
  notification('n-daily', NotificationType.dailyArticle, ago: const Duration(days: 1, hours: 10), isRead: true, article: diArticle),
  notification('n-streak', NotificationType.streakReminder, ago: const Duration(days: 2), isRead: true, streakDays: 12, link: 'readin://me/stats'),
  notification(
    'n-security',
    NotificationType.securityAlert,
    ago: const Duration(days: 3),
    securityChange: SecurityChange.passwordChanged,
    link: 'readin://settings/account',
  ),
  notification('n-writer', NotificationType.followedWriterArticle, ago: const Duration(days: 4), isRead: true, actor: mona, actorCount: 1, article: diArticle),
  notification('n-warning', NotificationType.moderationNotice, ago: const Duration(days: 6), isRead: true),
];

/// [NotificationsRepository] in memory: pages of [items] ([pageSize] each, cursor = the next index), and every call
/// recorded. Set a `…Failure` to make that call fail.
class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({List<AppNotification>? items, this.pageSize = 20}) : items = [...?items];

  List<AppNotification> items;
  int pageSize;
  int unread = 0;
  NotificationSettings settings = const NotificationSettings();

  final calls = <String>[];
  final saved = <NotificationSettings>[];

  Failure? listFailure;
  Failure? unreadFailure;
  Failure? seenFailure;
  Failure? readFailure;
  Failure? readAllFailure;
  Failure? settingsFailure;
  Failure? updateFailure;

  @override
  Future<Result<CursorPage<AppNotification>>> list({String? cursor, int limit = 20}) async {
    calls.add('list ${cursor ?? '-'}');
    if (listFailure case final failure?) return Err(failure);
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + pageSize).clamp(0, items.length);
    return Ok(CursorPage(items: items.sublist(start, end), nextCursor: end < items.length ? '$end' : null));
  }

  @override
  Future<Result<int>> unreadCount() async {
    calls.add('unread-count');
    if (unreadFailure case final failure?) return Err(failure);
    return Ok(unread);
  }

  @override
  Future<Result<void>> markSeen() async {
    calls.add('seen');
    if (seenFailure case final failure?) return Err(failure);
    unread = 0;
    return const Ok(null);
  }

  @override
  Future<Result<void>> markRead(String id) async {
    calls.add('read $id');
    if (readFailure case final failure?) return Err(failure);
    return const Ok(null);
  }

  @override
  Future<Result<void>> markAllRead() async {
    calls.add('read-all');
    if (readAllFailure case final failure?) return Err(failure);
    return const Ok(null);
  }

  @override
  Future<Result<NotificationSettings>> getSettings() async {
    calls.add('settings');
    if (settingsFailure case final failure?) return Err(failure);
    return Ok(settings);
  }

  @override
  Future<Result<void>> updateSettings(NotificationSettings settings) async {
    calls.add('update-settings');
    saved.add(settings);
    if (updateFailure case final failure?) return Err(failure);
    this.settings = settings;
    return const Ok(null);
  }
}

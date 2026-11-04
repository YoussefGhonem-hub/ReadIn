# Handoff: F17 Notifications (session readin-5e, formerly readin-4f)

Written 2026-11-04 when the user stopped all sessions but "main".

## What's done

- **F17: design only, no code.** The user picked F17 out of the unclaimed features (F15/F16, F23, F28–F30) on
  2026-11-04. Repo work was on hold for the dev consolidation, so the code was never started. The full contract is
  below and is ready to build from.
- **Coordination already agreed:**
  - **F22 (readin-8e):** it keeps `ModerationActions` and `GET /me/moderation-notices`. F17 adds a `moderation_notice`
    notification per notice and takes over F22's push: redirect `ModerationNoticeIssuedEventHandler`
    (Application/Features/Moderation/ModerationNotices.cs) from `ModerationNoticePush` to the notification writer, so
    there is no double push.
  - **Account deletion (F22's `AccountEraser`, Infrastructure/Identity):** the F17 commit deletes `NotificationActors`
    by ActorId there, asserts it in `AccountDeletionTests.Deleting_removes_everything_in_the_data_map_at_once`, and
    adds the tables to SPEC §9.6.
  - **F05:** `Article.Publish` returns early when the article is already published, so `ArticlePublishedDomainEvent`
    fires only on the first publish. That is what `followed_writer_article` needs. Edits of a published article raise
    no event.
  - **F09 (readin-c2):** path completion raises no domain event. A `path_completed` notification would need one first.
- **Earlier work of this session, all on dev:**
  - F27 real-time.
  - F10/F12/F13 + F07 (wave 1, 94ef79d..9494502).
  - F14 Profile (a0b38e1..154f028).
  - Guest article-card language fix (3d466a8).

## What's left

All of F17:
- **Backend:**
  - tables and the `Notifications` migration, generated on dev after the latest migration;
  - `NotificationWriter` and the outbox handlers per type;
  - `NotificationPushJob` (Hangfire) with quiet hours;
  - the streak-reminder job;
  - the endpoints and settings;
  - `DailyArticleDelivery.QuietHoursOf` (it returns null until F17);
  - the daily-article row;
  - the AccountEraser change;
  - the F22 handler switch.
- **Web:** the `/notifications` page (replaces the placeholder in `features/placeholders.routes.ts`), Settings →
  Notifications, and "push tap marks read".
- **Mobile:** `NotificationsPage` (replaces ComingSoon), the settings section, the local `dailyNotifications` switch
  moved to the server `daily_article` mode, and "push tap marks read".
- **Docs:** `docs/api/contract-v1.md` (endpoints, DTOs, push payloads, new deep links), SPEC §9.6 + §21.1 details, the
  README status row.

Defaults chosen and reported to the user (unconfirmed, change if asked):
- Opening the center clears the badge; items stay unread until opened or "mark all read".
- Security alerts can't be turned off and ignore quiet hours.
- The streak reminder goes out at 20:00 local.
- `followed_writer_article` push is on by default.

## Known errors

- No F17 code exists, so there are no F17 errors.
- Open leftovers from earlier work:
  - the web initial bundle is ~507 kB, over the 500 kB warning;
  - the who-reacted sheet can show a stale list (race);
  - production FCM/RTDB setup isn't configured (service account, rules deploy, VAPID, Apple Services ID, release
    SHA-1s);
  - the mobile daily-reminder switch is device-only (fixed by F17 as planned above).

## Tests that ran

- None for F17.
- Last full backend run by this session: 1307 green (the guest-language fix, 7a72654 → pushed as 3d466a8).
- Last full web and mobile runs by this session were at F14: web 486 unit + 162/162 e2e, mobile 828.

---

# Contract (design, ready to build)


Scope: SPEC F17 + §21.1. Review notifications are dropped (review removed). F19 verification and F22 moderation get
reserved types; their owners emit them.

## Types (`type` string; also the push `data.type`)

| type | source | recipient | aggregated per | link | push default |
|---|---|---|---|---|---|
| `new_follower` | `UserFollowedDomainEvent` | followee | day (`new_follower:{yyyy-MM-dd}`) | 1 actor `readin://u/{actor}`; more `readin://u/{me}/followers` | on |
| `article_comment` | `CommentChangedDomainEvent` Created, ParentId null | article author (not self) | article (`article_comment:{articleId}`) | `readin://a/{slug}#comment-{id}` | on |
| `comment_reply` | `CommentChangedDomainEvent` Created, ParentId set | parent comment author (not self) | parent comment (`comment_reply:{parentId}`) | `readin://a/{slug}#comment-{id}` | on |
| `mention` | Created or Edited; only mentions not notified before | each mentioned user (not self) | no | `readin://a/{slug}#comment-{id}` | on |
| `reactions_milestone` | `ReactionChangedDomainEvent` → total crosses 10/50/100 | article author | no (one per article + threshold, ever) | `readin://a/{slug}` | on |
| `followed_writer_article` | `ArticlePublishedDomainEvent` (first publish only) | the author's followers | no | `readin://a/{slug}` | on |
| `daily_article` | existing `DailyArticleDelivery` (now also writes the row) | user | no | `readin://a/{slug}` | on |
| `streak_reminder` | new Hangfire job, 20:00 local, streak ≥ 1 and nothing read today | user | no | `readin://me/stats` | on |
| `security_alert` | `UserSecurityChangedDomainEvent` | owner | no | `readin://settings/account` | always (not configurable, ignores quiet hours) |
| `verification_result` | reserved for F19 | | | | |
| `moderation_notice` | `ModerationNoticeIssuedDomainEvent(NoticeId)` (Domain/Moderation/ModerationAction.cs); the ModerationActions row has TargetUserId, NoticeKind warning / article_hidden, TargetId (article), Note. Redirect `ModerationNoticeIssuedEventHandler` (Application/Features/Moderation/ModerationNotices.cs) from `ModerationNoticePush` to the writer | TargetUserId | no | the notice or article | always on (F17's job takes over F22's push) |

One notification per recipient per comment: precedence `mention` > `comment_reply` > `article_comment`.
Hidden/deleted comments, unpublished articles and deleted actors drop out of the list query (no rewrite needed).

## Data model (one migration, `Notifications`)

- `Notifications`: Id, UserId (FK Users CASCADE), Type varchar(40), GroupKey varchar(200) null, DedupeKey varchar(200)
  null, ArticleId null (FK NO ACTION), CommentId null (FK NO ACTION), Data nvarchar(max) JSON (threshold, streakDays,
  securityChange), CreatedAt, UpdatedAt (last activity, list order), SeenAt null, ReadAt null, PushStatus tinyint
  (None/Pending/Sent/Skipped/Failed), PushAfter null, PushedAt null, PushAttempts.
  - Unique (UserId, DedupeKey) filtered NOT NULL: makes outbox retries idempotent. Event `OccurredAt` is stable across
    retries, so security alerts use `security_alert:{change}:{occurredAt ticks}`.
  - Index (UserId, UpdatedAt DESC, Id DESC) for the list; (PushStatus, PushAfter) filtered Pending for the job.
- `NotificationActors`: NotificationId (CASCADE) + ActorId (FK Users NO ACTION: two cascade paths otherwise), At.
  PK (NotificationId, ActorId) = distinct actors, retry-safe. Aggregation: an unread notification with the same
  (UserId, GroupKey) updated in the last 24 h gets the actor added, UpdatedAt bumped, SeenAt/ReadAt cleared, push re-armed.
- `UserNotificationSettings`: UserId + Type (PK), Mode tinyint (All=0, InApp=1, Off=2); sparse (absent = default).
- `Users`: QuietHoursEnabled bit default 1, QuietHoursStart time default 23:00, QuietHoursEnd time default 07:00.
- Account hard delete: in `AccountEraser` (Infrastructure/Identity, F22 owner readin-8e) delete NotificationActors by
  ActorId explicitly, in the F17 commit; assert in `AccountDeletionTests.Deleting_removes_everything_in_the_data_map_at_once`;
  add the tables to SPEC §9.6.

## Delivery

- Outbox handlers only write rows (`NotificationWriter`), never push. After saving they publish
  `/live/users/{id} { unreadNotifications = count(SeenAt null), lastNotificationAt }`.
- `NotificationPushJob` (Hangfire, every minute + triggered after writes): Pending rows with PushAfter ≤ now, per user,
  all devices, localized title/body in the user's UI language, collapse key = GroupKey ?? type. Removes invalid tokens,
  retries transient failures up to 3 times, skips rows older than 24 h. Mode InApp/Off → no push; Off → no row at all.
- Quiet hours (user's time zone): PushAfter = end of quiet hours. `security_alert` ignores them. `daily_article`
  keeps F07's rule (skip when in quiet hours; the hero card stays).
- Aggregated push text: "أحمد و9 غيره علّقوا على مقالك" / "Ahmed and 9 others commented on your article".

## API (Bearer; reads unthrottled, writes rate limit `writes`)

| Method | Path | Body → Response |
|---|---|---|
| GET | `/me/notifications?cursor=&limit=` | → `CursorPage<NotificationDto>` (UpdatedAt DESC) |
| GET | `/me/notifications/unread-count` | → `{ unread: number }` (REST fallback for the badge) |
| POST | `/me/notifications/seen` | → `204`: SeenAt = now for all; badge 0 (call on opening the center) |
| POST | `/me/notifications/{id}/read` | → `204` (also on a push tap; idempotent; 404 `notification.not_found`) |
| POST | `/me/notifications/read-all` | → `204` |
| GET | `/me/notification-settings` | → `NotificationSettingsDto` |
| PUT | `/me/notification-settings` | `NotificationSettingsDto` (types partial) → `204`; 400 `notification.type_invalid`, `notification.mode_invalid`, `notification.quiet_hours_invalid` |

```ts
type NotificationType = 'new_follower' | 'article_comment' | 'comment_reply' | 'mention' | 'reactions_milestone'
  | 'followed_writer_article' | 'daily_article' | 'streak_reminder' | 'security_alert' | 'verification_result' | 'moderation_notice';

interface NotificationDto {
  id: string;
  type: NotificationType;
  createdAt: string; updatedAt: string;
  isRead: boolean;
  actor: { id: string; displayName: string; username: string; avatarUrl: string | null; isVerified: boolean } | null; // latest actor
  actorCount: number;            // distinct actors (≥ 1 when actor-based); "X and {actorCount-1} others"
  article: { id: string; slug: string; title: string; language: ArticleLanguage } | null; // viewer's article language
  comment: { id: string; parentId: string | null; excerpt: string } | null;              // ≤ 140 chars, plain text
  data: { threshold?: number; streakDays?: number; securityChange?: SecurityChange };
  link: string;                  // readin://… (same mapping as push links)
}

type NotificationMode = 'all' | 'inApp' | 'off';
interface NotificationSettingsDto {
  quietHours: { enabled: boolean; start: string; end: string };   // "HH:mm", user's time zone
  types: Partial<Record<Exclude<NotificationType, 'security_alert' | 'verification_result' | 'moderation_notice'>, NotificationMode>>;
}
```

Push `data`: `{ type, notificationId, link, lang? }` (`lang` = "ar" | "en" for article links, as daily_article).
New deep links for clients: `readin://u/{username}/followers`, `readin://me/stats`, `readin://settings/account`.

## Clients

- Web: `/notifications` page replaces the placeholder (list, infinite scroll, Today/Earlier, mark all read, tap = read +
  navigate, POST seen on open); Settings → Notifications (per-type mode + quiet hours); push tap → read.
- Mobile: NotificationsPage replaces ComingSoon (cubit + repository, pull to refresh); settings section; the local
  daily switch becomes the server `daily_article` mode (migrate the stored value once, then drop it); push tap → read.
- Both: list text from type + actor + actorCount with ICU plurals (ar + en); "Deleted user" when actor is null.

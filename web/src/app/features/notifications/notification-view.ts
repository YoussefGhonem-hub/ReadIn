import type { TranslocoService } from '@jsverse/transloco';
import type { ArticleLanguage, NotificationDto, NotificationType, SecurityChange } from '../../core/api/models';
import type { UiLanguage } from '../../core/i18n/language.service';
import { pushLinkToPath } from '../../core/push/push-message';
import { translatePlural } from '../../shared/pipes/intl';

/** Types whose text starts with who did it: "X (and N others) …". */
const ACTOR_TYPES = new Set<NotificationType>([
  'new_follower',
  'article_comment',
  'comment_reply',
  'mention',
  'followed_writer_article',
  'article_reposted',
  // F35: "New support message from {name}" (the member), for holders of support.manage.
  'support_ticket',
]);

const SECURITY_CHANGES = new Set<SecurityChange>([
  'passwordChanged',
  'passwordReset',
  'recoveryPinChanged',
  'phoneNumberChanged',
  'recoveryLockedOut',
  'externalLoginLinked',
  'externalLoginUnlinked',
  'phoneSignInAdded',
]);

/** Stands in for the actor's name while translating, so the name can be rendered (bold, isolated) on its own. */
const NAME_MARK = '';

/** One line of a notification: the text around the actor's name, which is null for types without an actor. */
export interface NotificationText {
  before: string;
  actor: string | null;
  after: string;
}

export function isActorType(type: NotificationType): boolean {
  return ACTOR_TYPES.has(type);
}

/**
 * The notification's sentence in the UI language: "Ahmed and 9 others commented on your article" (CLDR plurals, so
 * Arabic gets its six forms), "Deleted user" when the actor's account is gone, a generic line for unknown types. A
 * mention without a comment is a mention in an article. The official @readin account's day of articles says how many
 * ("نشر ReadIn 3 مقالات جديدة"), then the row shows the newest one's title.
 */
export function notificationText(n: NotificationDto, transloco: TranslocoService, lang: UiLanguage): NotificationText {
  const key = `notifications.text.${n.type}`;
  if (ACTOR_TYPES.has(n.type)) {
    const name = n.actor?.displayName?.trim() || transloco.translate('common.deletedUser', {}, lang);
    const others = Math.max(0, Math.floor(n.actorCount) - 1);
    const articles = n.type === 'followed_writer_article' ? (positive(n.data?.articleCount) ?? 1) : 1;
    const text =
      others > 0
        ? translatePlural(transloco, `${key}.group`, others, lang, { name: NAME_MARK })
        : articles >= 2
          ? translatePlural(transloco, `${key}.articles`, articles, lang, { name: NAME_MARK })
          : transloco.translate(`${key}.${singleKey(n)}`, { name: NAME_MARK }, lang);
    const at = text.indexOf(NAME_MARK);
    return at < 0 ? { before: text, actor: null, after: '' } : { before: text.slice(0, at), actor: name ?? null, after: text.slice(at + NAME_MARK.length) };
  }
  return { before: plainText(n, key, transloco, lang), actor: null, after: '' };
}

/** One actor: a mention without a comment is in an article (the mentions in an article are one notification). */
function singleKey(n: NotificationDto): 'single' | 'article' {
  return n.type === 'mention' && !n.comment ? 'article' : 'single';
}

function plainText(n: NotificationDto, key: string, transloco: TranslocoService, lang: UiLanguage): string {
  switch (n.type) {
    case 'reactions_milestone':
      return translatePlural(transloco, key, positive(n.data?.threshold) ?? 10, lang);
    case 'streak_reminder':
      return translatePlural(transloco, key, positive(n.data?.streakDays) ?? 1, lang);
    case 'security_alert': {
      const change = n.data?.securityChange;
      return transloco.translate(`${key}.${change && SECURITY_CHANGES.has(change) ? change : 'other'}`, {}, lang);
    }
    case 'moderation_notice':
      return transloco.translate(`${key}.${n.article ? 'articleHidden' : 'warning'}`, {}, lang);
    case 'verification_result':
      return transloco.translate(`${key}.${verificationOutcome(n)}`, {}, lang);
    case 'daily_article':
      return transloco.translate(key, {}, lang);
    // F23: the announcement's own title, in the UI language (the API sends it).
    case 'announcement':
      return n.data?.title?.trim() || transloco.translate(key, {}, lang);
    // F35: support replied, or closed the ticket.
    case 'support_reply':
      return transloco.translate(`${key}.${n.data?.closed ? 'closed' : 'replied'}`, {}, lang);
    default:
      return transloco.translate('notifications.text.other', {}, lang);
  }
}

/**
 * A writer verification result (F19) by `data.approved`: approved, rejected, or (an API older than F19 left it out) the
 * general line.
 */
export function verificationOutcome(n: Pick<NotificationDto, 'data'>): 'approved' | 'rejected' | 'other' {
  const approved = n.data?.approved;
  return approved === true ? 'approved' : approved === false ? 'rejected' : 'other';
}

/** The Lucide icon for the type (lazy ones are in notification-icons.ts). */
export function notificationIcon(n: NotificationDto): string {
  switch (n.type) {
    case 'new_follower':
      return 'UserPlus';
    case 'article_comment':
      return 'MessageCircle';
    case 'comment_reply':
      return 'Reply';
    case 'mention':
      return 'AtSign';
    case 'reactions_milestone':
      return 'PartyPopper';
    case 'followed_writer_article':
      return 'PenLine';
    case 'article_reposted':
      return 'Repeat2';
    case 'daily_article':
      return 'Coffee';
    case 'streak_reminder':
      return 'Flame';
    case 'security_alert':
      return 'ShieldAlert';
    case 'verification_result':
      return verificationOutcome(n) === 'rejected' ? 'BadgeX' : 'BadgeCheck';
    case 'moderation_notice':
      return n.article ? 'EyeOff' : 'TriangleAlert';
    case 'announcement':
      return 'Megaphone';
    case 'support_reply':
    case 'support_ticket':
      return 'LifeBuoy';
    default:
      return 'Bell';
  }
}

/**
 * The row's second line for the F23/F35 types: an announcement's body, a ticket's "#12 · subject"; null for the others.
 */
export function notificationDetail(n: Pick<NotificationDto, 'type' | 'data'>): string | null {
  switch (n.type) {
    case 'announcement':
      return n.data?.body?.trim() || null;
    case 'support_reply':
    case 'support_ticket': {
      const subject = n.data?.subject?.trim();
      const number = positive(n.data?.ticketNumber);
      if (!subject && !number) return null;
      return [number ? `#${number}` : null, subject].filter(Boolean).join(' · ');
    }
    default:
      return null;
  }
}

/** The UI language whose route opens an article version (`/ar/a/…` for ar-EG). */
export function articleRouteLang(language: ArticleLanguage | null | undefined, fallback: UiLanguage): UiLanguage {
  if (language === 'ar-EG') return 'ar';
  if (language === 'en') return 'en';
  return fallback;
}

/**
 * Where tapping the notification goes: its `readin://` link mapped like a push's (pushLinkToPath), an article in the
 * language of the version it names. Null when there is nowhere else to go (a moderation warning opens its dialog).
 */
export function notificationPath(n: NotificationDto, uiLang: UiLanguage, origin: string): string | null {
  const path = pushLinkToPath(n.link, origin, articleRouteLang(n.article?.language, uiLang));
  return path === '/notifications' ? null : path;
}

/** "Today" is the user's calendar day, in their time zone. */
export function dayKey(date: Date, timeZone: string | null | undefined): string {
  try {
    return new Intl.DateTimeFormat('en-CA', { timeZone: timeZone || undefined, year: 'numeric', month: '2-digit', day: '2-digit' }).format(date);
  } catch {
    return new Intl.DateTimeFormat('en-CA', { year: 'numeric', month: '2-digit', day: '2-digit' }).format(date); // unknown zone
  }
}

function positive(value: unknown): number | null {
  return typeof value === 'number' && Number.isFinite(value) && value > 0 ? Math.floor(value) : null;
}

/**
 * DTOs for ReadIn API v1 — mirrors docs/api/contract-v1.md.
 * Replace with the client generated from `/openapi/v1.json` once the backend publishes it (SPEC §3.2).
 */
import type { RDoc } from '../../shared/rdoc/rdoc.models';

export type UiLanguage = 'ar' | 'en';
export type ArticleLanguage = 'ar-EG' | 'en';
export type ThemePreference = 'system' | 'light' | 'dark';
export type DevicePlatform = 'android' | 'ios' | 'web';

export interface CursorPage<T> {
  items: T[];
  nextCursor: string | null;
}

/** https URLs (≤ 2048); null or missing when not set. */
export interface ProfileLinks {
  github?: string | null;
  linkedin?: string | null;
  website?: string | null;
}

/**
 * Who may @mention you, in comments and articles (F18): everyone, the people you follow, or nobody (you can always
 * mention yourself). Anyone else's `@username` stays plain text: no link, no notification.
 */
export type MentionPolicy = 'everyone' | 'following' | 'nobody';

/** Settings → Privacy (F18), in `GET /me`. */
export interface PrivacySettingsDto {
  /** Reading stats + heatmap on the public profile (F14). Off by default. */
  publicReadingStats: boolean;
  /** `everyone` by default (and when an API older than it leaves it out). */
  whoCanMention: MentionPolicy;
}

/** `PUT /me/privacy`: each setting is optional (left out = unchanged), at least one is required. */
export type UpdatePrivacyRequest = Partial<PrivacySettingsDto>;

export interface MeDto {
  id: string;
  /** E.164; only in MeDto and admin endpoints (SPEC §9.5). */
  phoneNumber: string | null;
  email: string | null;
  displayName: string;
  username: string;
  avatarUrl: string | null;
  bio: string | null;
  links: ProfileLinks;
  uiLanguage: UiLanguage;
  articleLanguage: ArticleLanguage;
  theme: ThemePreference;
  timeZone: string;
  reminderTime: string;
  /** The Verified badge (`Users.IsVerified`): a badge, not a role (SPEC §10). */
  isVerified: boolean;
  /** True once ≥ 3 interests are saved. */
  onboardingCompleted: boolean;
  /** Guards after sign in, in this order (SPEC §9.2): change password → set PIN → complete profile → onboarding. */
  mustChangePassword: boolean;
  mustSetRecoveryPin: boolean;
  isProfileComplete: boolean;
  hasRecoveryPin: boolean;
  /** False for Google/Apple-only accounts: no phone, password or PIN (they can add them later). */
  hasPassword: boolean;
  externalLogins: ExternalLoginDto[];
  /** `["Member"]` or `["SuperAdmin"]` (SPEC §10). Never test it: gate on `permissions`, show the badge from `isVerified`. */
  roles: string[];
  permissions: string[];
  interests: { fieldIds: string[]; topicIds: string[] };
  /** Missing from an API older than F14: every setting at its default. */
  privacy?: PrivacySettingsDto;
}

// ── Auth (SPEC §9, ADR 0007, ADR 0009, ADR 0012) ────────────────

export type ExternalProvider = 'google' | 'apple';

export interface ExternalLoginDto {
  provider: ExternalProvider;
  /** The email the provider reported (verified), if any. */
  email: string | null;
  linkedAt: string;
}

export interface AuthConfigDto {
  /** Number of PIN boxes (default 4). */
  pinLength: number;
  password: { minLength: number; maxLength: number; requireLetter: boolean; requireDigit: boolean };
  /** Google/Apple sign in this server accepts; the other buttons stay hidden. */
  externalProviders: ExternalProvider[];
}

/** A fresh ID token from Google Identity Services or Sign in with Apple. Never stored. */
export interface ExternalCredential {
  provider: ExternalProvider;
  idToken: string;
  /** The RAW nonce (Apple): Apple was given its SHA-256 hex. */
  nonce?: string;
  /**
   * Apple's one-time `authorization.code`. The API exchanges it for a refresh token it can revoke when the account is
   * deleted (Apple requires that), so it goes along with every Apple sign in, link and confirmation.
   */
  authorizationCode?: string;
}

export interface ExternalSignInRequest extends ExternalCredential {
  /** Apple sends the name only on the first authorization; used for a new account. */
  displayName?: string;
  uiLanguage?: UiLanguage;
  timeZone?: string;
  /** "I already have an account": the phone + password of the account to link. */
  link?: { phoneNumber: string; password: string };
  /** "Create a new account" (never together with `link`). */
  createAccount?: boolean;
}

/** Confirms a sensitive action: exactly one of the password or a fresh sign in of a linked provider. */
export interface AccountConfirmation {
  password?: string;
  external?: ExternalCredential;
}

export interface RegisterRequest {
  /** E.164, mobile numbers only. */
  phoneNumber: string;
  password: string;
  recoveryPin: string;
  uiLanguage?: UiLanguage;
  /** IANA, e.g. "Africa/Cairo". */
  timeZone?: string;
}

export interface LoginRequest {
  phoneNumber: string;
  password: string;
}

/** A signed-in session. On the web `refreshToken` is null: it lives in an HttpOnly cookie the page never sees. */
export interface SessionDto {
  accessToken: string;
  accessTokenExpiresAt: string;
  refreshToken: string | null;
  refreshTokenExpiresAt: string;
  user: MeDto;
}

export interface VerifyPinRequest {
  phoneNumber: string;
  pin: string;
}

/** Forgot password, step 1: a 10-minute, single-use token for step 2. */
export interface PasswordResetTokenDto {
  resetToken: string;
  expiresAt: string;
}

export interface ResetPasswordRequest {
  resetToken: string;
  newPassword: string;
}

export interface CompleteProfileRequest {
  displayName: string;
  username: string;
  avatarUrl?: string | null;
}

export interface UsernameAvailabilityDto {
  username: string;
  valid: boolean;
  available: boolean;
}

/** `PATCH /me` (F14) → `204`; refetch `GET /me` afterwards. */
export interface UpdateProfileRequest {
  /** 2..60 */
  displayName: string;
  /** ^[a-z0-9_]{3,30}$ */
  username: string;
  /** ≤ 300 */
  bio?: string | null;
  links?: ProfileLinks;
  /**
   * Left out: keep the current avatar. null: remove it. An image you uploaded with `purpose=avatar`: set it.
   * `400 profile.avatar_invalid` (also for an unknown id), field `avatarAssetId`.
   */
  avatarAssetId?: string | null;
  /** 0–5 enabled field ids, in order; left out = unchanged, [] clears. `400 profile.expertise_invalid` (field `expertiseFieldIds`). */
  expertiseFieldIds?: string[];
}

export interface UpdatePreferencesRequest {
  uiLanguage: UiLanguage;
  articleLanguage: ArticleLanguage;
  theme: ThemePreference;
  timeZone: string;
  reminderTime: string;
}

export interface UpdateInterestsRequest {
  fieldIds: string[];
  topicIds: string[];
}

export interface RegisterDeviceRequest {
  token: string;
  platform: DevicePlatform;
}

export interface FieldDto {
  id: string;
  slug: string;
  name: string;
  nameAr: string;
  nameEn: string;
  icon: string;
  color: string;
  isSensitive: boolean;
  /** Publishing in this field needs at least one source. */
  requiresSources: boolean;
  topicCount: number;
}

export interface TopicDto {
  id: string;
  fieldId: string;
  slug: string;
  name: string;
  nameAr: string;
  nameEn: string;
}

export interface AuthorDto {
  id: string;
  displayName: string;
  username: string;
  avatarUrl: string | null;
  isVerified: boolean;
}

export interface FieldRefDto {
  id: string;
  slug: string;
  name: string;
  nameAr: string;
  nameEn: string;
  /**
   * Medicine and Public Health: the reader shows a health disclaimer (SPEC F04, §20). Missing from an API older than
   * step 6.6 (no disclaimer then).
   */
  isSensitive?: boolean;
}

export interface ArticleCardDto {
  id: string;
  slug: string;
  language: ArticleLanguage;
  title: string;
  subtitle: string | null;
  coverUrl: string | null;
  field: FieldRefDto;
  /** Null when the author deleted their account (SPEC §9.6): shown as "Deleted user", with no name, photo, profile or follow. */
  author: AuthorDto | null;
  readingTimeMinutes: number;
  isAiAssisted: boolean;
  versionBadge: string | null;
  publishedAt: string;
  /** Always the sum of `reactions`. */
  reactionCount: number;
  /** Per type (F10). */
  reactions: ReactionCountsDto;
  commentCount: number;
  saveCount: number;
  /** The viewer's reaction; null for guests. */
  myReaction: ReactionType | null;
  /** False for guests. */
  isSaved: boolean;
  /** Feed cards carry at most the first 10 PDF pages; article details carry all of them. */
  attachments: ArticleAttachmentsDto | null;
  /**
   * The served version's beginning as plain text (≤ 400 characters, cut at a word), for the post card (F34). Null only
   * for an article not backfilled yet: the card then shows the title alone and treats `hasMore` as true.
   */
  excerpt: string | null;
  /** The article has more than the excerpt shows; false only when the excerpt is the whole article. */
  hasMore: boolean;
  /** False for guests, on your own articles and for a deleted author. */
  isFollowingAuthor: boolean;
  /** The first 3 tags, in the writer's order (F32): each links to its tag page. Hidden tags are left out. */
  tags: TagRefDto[];
  /** All the article's visible tags (0–5), for "+N". */
  tagCount: number;
  /**
   * F28: the article's topic, for the "كتم المواضيع" sheet (on cards since F28; `ArticleDetailsDto` always had it).
   * Missing from an API older than F28.
   */
  topic?: FieldRefDto | null;
  /**
   * F28 viewer flags, filled per caller like `isSaved` (false for guests; missing from an API older than F28). Lists that
   * apply mutes leave such cards out, so there they are false, except a field page's own field and picked topic.
   * `isAuthorMuted` is false on your own articles and for a deleted author: the reader's "انت كاتم الكاتب ده" banner.
   */
  isAuthorMuted?: boolean;
  isFieldMuted?: boolean;
  isTopicMuted?: boolean;
}

/** `GET /articles/{id}/preview?lang=` (F34): the first blocks, about 300 words, never cutting a block, at least one. */
export interface ArticlePreviewDto {
  id: string;
  /** The version served: the requested one, else the source language. */
  language: ArticleLanguage;
  content: RDoc;
  /** `content` is the whole article. */
  isComplete: boolean;
}

export interface ArticleSourceDto {
  title: string;
  url: string;
}

export interface ArticleDetailsDto extends ArticleCardDto {
  availableLanguages: ArticleLanguage[];
  summary: string | null;
  content: RDoc;
  topic: FieldRefDto | null;
  /** All the article's visible tags (≤ 5); the card's `tags` holds the first 3. */
  tags: TagRefDto[];
  sources: ArticleSourceDto[];
  readCount: number;
  /** The viewer's collections that contain the article; empty for guests. */
  collectionIds: string[];
  /** The viewer's reading progress, to resume where they left off (F04); null for guests and unopened articles. */
  myProgress: MyProgressDto | null;
  /**
   * Non-null only while the article is hidden by moderators (F22): then only its author and moderators get it at all,
   * and the reader shows a "hidden" banner. Missing from an API older than F22.
   */
  moderation?: ArticleModerationDto | null;
  /**
   * The writer's category of the article (F31): the byline's "في قسم {name}", linking to
   * `/@{author.username}/c/{slug}`. Null: none. Missing from an API older than F31.
   */
  category?: WriterCategoryRefDto | null;
}

// ── Writer categories (F31) ─────────────────────────────────

/** A card of the profile's Categories tab and a row of the writer's manage list. Show `name` with `dir="auto"`. */
export interface WriterCategoryDto {
  id: string;
  /** Made once from the name, never changes on rename; opens `/@{username}/c/{slug}` (percent-encoded: may be Arabic). */
  slug: string;
  /** 1–40 characters, the writer's spelling. */
  name: string;
  /** Articles readers can see in it, the same for everyone; 0 only in `GET /me/categories`. */
  articleCount: number;
  /** The writer's order, ascending; lists already come sorted. */
  sortOrder: number;
}

/** `GET /users/{username}/categories`, `GET /me/categories`, `PUT /me/categories/order`. */
export interface WriterCategoryListDto {
  /** The profile: non-empty ones only; `/me`: all of them, empty ones included. */
  items: WriterCategoryDto[];
  /** Articles readers can see without a category: the last card, "مقالات تانية" (`/c/_other`); hidden when 0. */
  uncategorizedCount: number;
}

/** `GET /users/{username}/categories/{slug}`: the category page's header. */
export interface WriterCategoryPageDto {
  /** Null for the uncategorized list (slug `_other`). */
  id: string | null;
  slug: string;
  /** Null for `_other`: show "مقالات تانية" / "Other articles". */
  name: string | null;
  /** 0 → the empty state (and `noindex`). */
  articleCount: number;
  /** The writer: the page title ("{name} · {displayName}") and the link back to the profile. */
  author: AuthorDto;
}

/** `ArticleDetailsDto.category`. */
export interface WriterCategoryRefDto {
  slug: string;
  name: string;
}

// ── Reactions (F10) ─────────────────────────────────────────

/** 💡 ❤️ 🔥 🤯 — one per user per article. */
export type ReactionType = 'insightful' | 'love' | 'fire' | 'mindBlown';
export const REACTION_TYPES: readonly ReactionType[] = ['insightful', 'love', 'fire', 'mindBlown'];

export type ReactionCountsDto = Record<ReactionType, number>;

/** `PUT` / `DELETE /articles/{id}/reaction`. */
export interface ArticleReactionsDto {
  reactions: ReactionCountsDto;
  total: number;
  myReaction: ReactionType | null;
}

/** "Who reacted", newest first. */
export interface ReactorDto {
  user: AuthorDto;
  type: ReactionType;
  reactedAt: string;
}

// ── Saved (F13) ─────────────────────────────────────────────

export interface SaveStateDto {
  isSaved: boolean;
  saveCount: number;
}

export interface SavedArticleDto {
  savedAt: string;
  collectionIds: string[];
  article: ArticleCardDto;
}

/** A named list of saved articles (max 50 per user, names unique per user, case-insensitive). */
export interface CollectionDto {
  id: string;
  /** 1–60 characters, trimmed. */
  name: string;
  articleCount: number;
  createdAt: string;
}

// ── Follow (F12) ────────────────────────────────────────────

export interface FollowStateDto {
  isFollowing: boolean;
  followerCount: number;
}

export interface UserSummaryDto {
  id: string;
  displayName: string;
  username: string;
  avatarUrl: string | null;
  isVerified: boolean;
  bio: string | null;
  /** The viewer follows this user (false for guests). */
  isFollowing: boolean;
  /** This user follows the viewer (false for guests). */
  followsYou: boolean;
}

/** Followed fields and topics (F02 interests); the same shape as `MeDto.interests`. */
export interface InterestsDto {
  fieldIds: string[];
  topicIds: string[];
}

// ── Mute & feedback (F28) ───────────────────────────────────

/** `PUT` / `DELETE /users/{id}/mute`. */
export interface UserMuteStateDto {
  isMuted: boolean;
  /** After the change: a mute always ends your follow; `DELETE ?restoreFollow=true` follows again. */
  isFollowing: boolean;
  /** The writer's followers after the change. */
  followerCount: number;
  /** `PUT`: this mute ended your follow, so its Undo sends `restoreFollow=true`. Always false on `DELETE`. */
  followRemoved: boolean;
}

/** `PUT` / `DELETE /me/mutes/{fields|topics}/{id}`: every field and topic you muted, after the change. */
export interface ContentMutesDto {
  fieldIds: string[];
  topicIds: string[];
}

/** A muted field in Settings → Muted; `name` in Accept-Language, `icon` a Lucide name, `color` a token. */
export interface MutedFieldDto {
  id: string;
  slug: string;
  name: string;
  nameAr: string;
  nameEn: string;
  icon: string;
  color: string;
}

export interface MutedTopicDto {
  id: string;
  slug: string;
  name: string;
  nameAr: string;
  nameEn: string;
  field: MutedFieldDto;
}

/** `GET /me/mutes` (Settings → Muted, F18): each list newest mute first, not paged. */
export interface MutesDto {
  /** `isFollowing` is always false (a mute ends the follow); suspended accounts stay listed. */
  users: UserSummaryDto[];
  fields: MutedFieldDto[];
  topics: MutedTopicDto[];
}

// ── Comments (F11) ──────────────────────────────────────────

/** `top` (default) = likes + 2 × replies, then newest; `new` = newest first. */
export type CommentSort = 'top' | 'new';

/** An @handle in the text that resolved to a user: clients link exactly these, other "@words" stay text. */
export interface CommentMentionDto {
  userId: string;
  username: string;
}

/** A comment or reply as the viewer sees it. Placeholders (deleted, or hidden for you) have no `body` and no `author`. */
export interface CommentDto {
  id: string;
  articleId: string;
  /** The thread's top-level comment; null for top-level comments. */
  parentId: string | null;
  /** Null for placeholders. Render with `dir="auto"`. */
  body: string | null;
  /** Null: "Deleted user" (or a placeholder). */
  author: AuthorDto | null;
  /** The "الكاتب" badge. */
  isArticleAuthor: boolean;
  mentions: CommentMentionDto[];
  likeCount: number;
  likedByMe: boolean;
  /** Visible replies (top-level comments). */
  replyCount: number;
  isPinned: boolean;
  createdAt: string;
  /** Set once edited ("edited"). */
  editedAt: string | null;
  /** Placeholder of a deleted comment kept for its replies. */
  isDeleted: boolean;
  /** Hidden by a moderator: a placeholder for others, the full text for its author and moderators. */
  isHidden: boolean;
  canEdit: boolean;
  canDelete: boolean;
  canPin: boolean;
  canReport: boolean;
  canModerate: boolean;
  /** In lists: the first 2 replies of a top-level comment, oldest first. */
  replies?: CommentDto[];
  /**
   * F28: you muted the author, so it collapses to "تعليق من شخص كتمته" with "عرض" (replies under it stay). False for
   * guests and placeholders; missing from an API older than F28.
   */
  isAuthorMuted?: boolean;
}

/** `GET /articles/{id}/comments`. `total` is the article's comment count (visible comments and replies). */
export interface CommentPageDto {
  items: CommentDto[];
  nextCursor: string | null;
  total: number;
}

/** `PUT` / `DELETE /comments/{id}/like`. */
export interface CommentLikeDto {
  likeCount: number;
  liked: boolean;
}

/** `GET /users/mention-suggestions`: someone to @mention while typing. */
export interface MentionCandidateDto {
  id: string;
  displayName: string;
  username: string;
  avatarUrl: string | null;
  isVerified: boolean;
}

// ── Reports and moderation (F22) ────────────────────────────

export type ReportReason = 'spam' | 'misinformation' | 'harassment' | 'copyright' | 'other';
export const REPORT_REASONS: readonly ReportReason[] = ['spam', 'misinformation', 'harassment', 'copyright', 'other'];

export type ModerationTargetType = 'article' | 'comment' | 'user';
export const MODERATION_TARGET_TYPES: readonly ModerationTargetType[] = ['article', 'comment', 'user'];

export type ReportStatus = 'open' | 'resolved' | 'dismissed';
export const REPORT_STATUSES: readonly ReportStatus[] = ['open', 'resolved', 'dismissed'];

/**
 * `POST /reports` → 204 (permission `reports.create`). Not your own content or yourself (`report.own_content`);
 * reporting the same target again is a no-op 204.
 */
export interface ReportRequest {
  targetType: ModerationTargetType;
  targetId: string;
  reason: ReportReason;
  /** ≤ 500 characters. */
  details?: string | null;
}

export type ModerationAction = 'hide' | 'unhide' | 'delete' | 'warn' | 'suspend' | 'unsuspend' | 'clear_category' | 'dismiss';

/**
 * `POST /moderation/actions` → 204 (permission `moderation.manage`; suspend / unsuspend also `users.suspend`).
 * Allowed: comment hide/unhide/delete/dismiss · article hide/unhide/dismiss · user
 * warn/suspend/unsuspend/clear_category/dismiss.
 */
export interface ModerationActionRequest {
  action: ModerationAction;
  targetType: ModerationTargetType;
  targetId: string;
  /** ≤ 500; required for warn and suspend (`moderation.note_required`). */
  note?: string;
  /** Suspend only: 1–365 days; null or left out = permanent (`moderation.duration_invalid`). */
  durationDays?: number | null;
  /** Also resolve these open reports (e.g. warning the author from an article's case). */
  resolveReportsOf?: { targetType: ModerationTargetType; targetId: string };
  /**
   * `clear_category` only (F31): one of the user's categories, renamed to a neutral placeholder ("قسم {n}") with a new
   * slug. `404 category.not_found` when it isn't theirs.
   */
  categoryId?: string;
}

/** `GET /moderation/summary`: targets with open reports (the nav badge). */
export interface ModerationSummaryDto {
  open: { article: number; comment: number; user: number; total: number };
}

/**
 * What a case is about. article/comment: visible|hidden|deleted; user: active|suspended|deleted. The fields of the
 * other target types are null (the API sends them as null rather than leaving them out).
 */
export interface ModerationTargetDto {
  state: 'visible' | 'hidden' | 'deleted' | 'active' | 'suspended';
  /** The article's or comment's author (null = deleted account); for a user target, the user. */
  author: AuthorDto | null;
  // article
  title?: string | null;
  slug?: string | null;
  language?: string | null;
  // comment
  body?: string | null;
  articleId?: string | null;
  articleSlug?: string | null;
  articleTitle?: string | null;
  // user
  /** When `state = suspended`; null = permanent. */
  suspendedUntil?: string | null;
  /** Warn actions on this user so far. */
  warningCount?: number | null;
}

/** One target in the queue, with its reports in `status` grouped. */
export interface ModerationQueueItemDto {
  targetType: ModerationTargetType;
  targetId: string;
  /** The status the list is filtered on. */
  status: ReportStatus;
  /** Reports in this status. */
  reportCount: number;
  reasons: Partial<Record<ReportReason, number>>;
  firstReportedAt: string;
  lastReportedAt: string;
  /** Resolved and dismissed lists. */
  closedAt: string | null;
  target: ModerationTargetDto;
}

export interface ModerationReportDto {
  id: string;
  /** Null: the reporter deleted their account. */
  reporter: UserSummaryDto | null;
  reason: ReportReason;
  details: string | null;
  status: ReportStatus;
  createdAt: string;
  closedAt: string | null;
  closedBy: UserSummaryDto | null;
}

/** A row of the moderation log (SPEC §16 `ModerationActions`). */
export type ModerationLogAction =
  | 'comment.hide'
  | 'comment.unhide'
  | 'comment.delete'
  | 'article.hide'
  | 'article.unhide'
  | 'user.warn'
  | 'user.suspend'
  | 'user.unsuspend'
  // F31: a moderator cleared an offensive category name (`targetLabel` is the old name).
  | 'user.clear_category'
  | 'reports.dismiss';

export interface ModerationActionDto {
  id: string;
  action: ModerationLogAction;
  targetType: ModerationTargetType;
  targetId: string;
  /** Article title, the first 80 characters of a comment or @username, as it was at the time. */
  targetLabel: string | null;
  /** The affected user (the author, or the user target). */
  targetUser: UserSummaryDto | null;
  /** Null: the moderator's account was deleted. */
  moderator: UserSummaryDto | null;
  note: string | null;
  /** `user.suspend`: when it ends (null = permanent). */
  suspendedUntil: string | null;
  reportsClosed: number;
  createdAt: string;
}

/** `GET /moderation/reports/{targetType}/{targetId}`. */
export interface ModerationCaseDto {
  /** `status` is open while any report is open, else the latest closed status. */
  item: ModerationQueueItemDto;
  /** All statuses, newest first. */
  reports: ModerationReportDto[];
  /** Actions on the target and, for an article or comment, on its author; newest first. */
  history: ModerationActionDto[];
  /**
   * A user case (F31): all of that user's writer categories, empty ones included, in their order, so a moderator can
   * clear an offensive name (`clear_category`). `[]` for article and comment cases; missing from an older API.
   */
  categories?: WriterCategoryDto[] | null;
}

/** A warning, or "your article was hidden", for the affected user to acknowledge. */
export interface ModerationNoticeDto {
  id: string;
  kind: 'warning' | 'article_hidden';
  note: string | null;
  /** `article_hidden`. */
  article: { id: string; slug: string; title: string } | null;
  createdAt: string;
}

/** Set on a hidden article (only its author and moderators can open it). */
export interface ArticleModerationDto {
  hiddenAt: string;
  note: string | null;
}

// ── Profile (F14) ───────────────────────────────────────────

/** Square avatar renditions (WebP) by width. */
export type AvatarVariantsDto = Partial<Record<'64' | '128' | '256' | '512', string>>;

/** A field of expertise. `name` is in the request's UI language; `icon` is a Lucide name and `color` a token name. */
export interface ExpertiseFieldDto {
  id: string;
  slug: string;
  name: string;
  icon: string;
  color: string;
}

export interface ProfileStatsDto {
  /** Published articles. */
  articles: number;
  followers: number;
  following: number;
  /** Reads of the user's published articles. */
  totalReads: number;
}

/** `GET /users/{username}` 🌐 — the public profile. Never carries the phone number (SPEC §9.5). */
export interface ProfileDto {
  id: string;
  displayName: string;
  username: string;
  /** The variant of at least 256 px, else the largest (the same URL every AuthorDto carries), or null. */
  avatarUrl: string | null;
  /** Null without an avatar, or for an old avatar without variants; otherwise all four widths (absolute URLs). */
  avatarVariants: AvatarVariantsDto | null;
  isVerified: boolean;
  /** Mixed text: rendered in the direction of its first strong character. */
  bio: string | null;
  links: ProfileLinks;
  /** In the user's order, at most 5. */
  expertise: ExpertiseFieldDto[];
  joinedAt: string;
  stats: ProfileStatsDto;
  isMe: boolean;
  /** False for guests and on your own profile. */
  isFollowing: boolean;
  /** False for guests and on your own profile. */
  followsYou: boolean;
  /** True on your own profile, or when the user made their reading stats public. */
  readingStatsVisible: boolean;
  /**
   * F28: you muted this user: "انت كاتم الكاتب ده" with "إلغاء الكتم". False for guests and on your own profile;
   * missing from an API older than F28.
   */
  isMuted?: boolean;
  /**
   * F28: the official ReadIn account (`@readin`). It can't be muted, so the profile's "⋯" leaves Mute out. Missing from
   * an API older than F28.
   */
  isSystemAccount?: boolean;
}

// ── Writing (F05) ───────────────────────────────────────────

/** `draft → published` (an `archived` state exists in the backend but has no endpoint). */
export type ArticleStatus = 'draft' | 'published';

/** One language version of the article being edited. */
export interface DraftTranslation {
  language: ArticleLanguage;
  /** May be '' in a draft; 5..150 to publish. */
  title: string;
  /** ≤ 250. */
  subtitle: string | null;
  /** `content.language === language`. In a draft an image block may have `alt: ''`. */
  content: RDoc;
}

/** One attachment of the draft: 1–10 images or one PDF (ADR 0011). */
export interface DraftAttachment {
  mediaAssetId: string;
  order: number;
  /** Images, ≤ 5000. */
  caption?: string | null;
  /** Images, required to publish, ≤ 5000. */
  altText?: string | null;
  /** The PDF, required to publish, ≤ 5000, no line breaks. */
  title?: string | null;
  /** The PDF, default false. */
  allowDownload?: boolean;
}

/** Everything the editor edits. Sent whole on every autosave. */
export interface ArticleDraftDocument {
  /** The first version; must be one of `translations[].language`. */
  sourceLanguage: ArticleLanguage;
  /** 1 or 2, distinct languages. */
  translations: DraftTranslation[];
  /** Required to publish. */
  fieldId: string | null;
  /** Must belong to `fieldId`. */
  topicId: string | null;
  /**
   * ≤ 5 tag names (F32 rules: features/editor/tag-rules.ts). The server stores them cleaned with repeats dropped, and
   * new names become tags on publish.
   */
  tags: string[];
  /** ≤ 30; title 1..200, url http(s) ≤ 2048. Required to publish when the field has `requiresSources`. */
  sources: ArticleSourceDto[];
  /** Absolute URL from `POST /uploads/images` (purpose=cover), or null. */
  coverUrl: string | null;
  /** ≤ 30, e.g. ".NET 10". */
  versionBadge: string | null;
  isAiAssisted: boolean;
  /** 1–10 images OR one PDF, or []. */
  attachments: DraftAttachment[];
}

export interface SaveDraftRequest {
  baseVersion: number;
  document: ArticleDraftDocument;
}

export type DraftProblemCode =
  | 'article.field_required'
  | 'article.title_length'
  | 'article.content_empty'
  | 'article.content_invalid'
  | 'article.image_alt_required'
  | 'article.sources_required'
  | 'attachments.alt_text_required'
  | 'attachments.title_required'
  | 'attachments.asset_not_ready'
  | 'attachments.mixed_kinds'
  | 'attachments.single_document'
  | 'media.in_use'
  // F32: a hidden tag the published article doesn't have; more than 20 new tags in 24 hours.
  | 'tag.hidden'
  | 'tag.limit';

export interface DraftProblemDto {
  code: DraftProblemCode;
  /** For translation problems. */
  language: ArticleLanguage | null;
  /** RDoc block id (image alt), or null. */
  blockId: string | null;
  /** Attachment problems. */
  mediaAssetId: string | null;
  /** Tag problems (F32): the name as in `document.tags`. Missing from an API older than F32. */
  tag?: string | null;
}

export interface ReadingTimeCheckDto {
  language: ArticleLanguage;
  minutes: number;
  words: number;
}

export interface DraftChecksDto {
  /** Per translation (SPEC §13.5). */
  readingTime: ReadingTimeCheckDto[];
  /** Empty → can publish. */
  problems: DraftProblemDto[];
}

/** The editor's view of an article (`GET /articles/{id}/edit`, every save, discard and restore). */
export interface ArticleEditDto {
  id: string;
  status: ArticleStatus;
  /** Null until the first publish. */
  slug: string | null;
  publishedAt: string | null;
  /** Working-copy version; send it back as `baseVersion`. */
  version: number;
  /** Last save of the working copy (or the publish time). */
  savedAt: string;
  /** Published articles: the working copy differs from what readers see. Always false for drafts. */
  hasUnpublishedChanges: boolean;
  /** As stored (server-normalized). */
  document: ArticleDraftDocument;
  /** The assets the document references (attachments, cover, image blocks). */
  media: MediaAssetDto[];
  checks: DraftChecksDto;
  /**
   * The writer's category (F31; null: none). Not part of `document`: changed at once with `PUT /articles/{id}/category`,
   * so autosave, discard, restore and publish never touch it. Missing from an API older than F31.
   */
  categoryId?: string | null;
}

export interface PublishedArticleDto {
  id: string;
  slug: string;
  publishedAt: string;
  revision: number;
  firstPublish: boolean;
}

export interface ArticleRevisionDto {
  /** 1 = first publish. */
  number: number;
  createdAt: string;
  /** Source-language title at that time. */
  title: string;
  languages: ArticleLanguage[];
}

export interface ArticleRevisionDetailsDto extends ArticleRevisionDto {
  document: ArticleDraftDocument;
  /** The attachments' assets, so the preview shows them like the reader does. */
  media: MediaAssetDto[];
}

/** A row of "My articles" (`GET /me/articles`). */
export interface MyArticleDto {
  id: string;
  status: ArticleStatus;
  slug: string | null;
  /** The source language. */
  language: ArticleLanguage;
  /** Source-language title; '' → "Untitled". */
  title: string;
  coverUrl: string | null;
  field: FieldRefDto | null;
  readingTimeMinutes: number;
  /** Last edit. */
  savedAt: string;
  publishedAt: string | null;
  hasUnpublishedChanges: boolean;
  /** 0 for drafts. */
  reactionCount: number;
  commentCount: number;
  readCount: number;
  /**
   * The published versions, source language first (F33): what "Download PDF" offers (two → it asks which). Empty for
   * drafts; missing from an API older than F33.
   */
  publishedLanguages?: ArticleLanguage[];
}

// ── Tags (F32) ──────────────────────────────────────────────

/** A tag on a card or in the reader: shown as "#name" (`dir="auto"`), linking to `/tags/{slug}`. */
export interface TagRefDto {
  /** Made by the server and never changed; may hold Arabic letters. Clients never build one from a name. */
  slug: string;
  /** The first spelling anyone used, e.g. "C#", ".NET", "الذكاء الاصطناعي". */
  name: string;
}

/** `GET /tags?q=` (the editor's suggestions, most used first) and `GET /tags/{slug}` (the tag page's header). */
export interface TagDto extends TagRefDto {
  /** Published articles readers can see; 0 → the tag page's empty state (and `noindex`). */
  articleCount: number;
}

// ── Search (F16) ────────────────────────────────────────────

/** `GET /search?type=`: articles → SearchArticleDto, users → UserSummaryDto, topics → SearchTopicDto, tags → TagDto. */
export type SearchType = 'articles' | 'users' | 'topics' | 'tags';

/** Where the query was found, best first: the served version's title, its title + text, or only the attached PDF. */
export type SearchMatch = 'title' | 'text' | 'attachment';

export interface SearchArticleDto {
  /** In the version that matched; shown as the compact row (F34), not the post card. */
  article: ArticleCardDto;
  /** `attachment` → "لقيناها في ملف الـ PDF المرفق" / "Found in the attached PDF". */
  matchedIn: SearchMatch;
}

/** A field or a topic. Opens the field page (F15): `/f/{fieldSlug}`, or `/f/{fieldSlug}?topic={topicSlug}` for a topic. */
export interface SearchTopicDto {
  kind: 'field' | 'topic';
  /** The field's or the topic's id. */
  id: string;
  /** In Accept-Language. */
  name: string;
  nameAr: string;
  nameEn: string;
  fieldSlug: string;
  /** Null for a field. */
  topicSlug: string | null;
  /** The field's name in Accept-Language (= `name` for a field): a topic's subtitle. */
  fieldName: string;
  /** The field's Lucide icon name, e.g. "cpu". */
  icon: string;
  /** The field's color token, e.g. "primary". */
  color: string;
  /** Published articles readers can see in it. */
  articleCount: number;
}

/** `GET /search/suggest`: at most 3 of each type, ranked as in `/search`, for the as-you-type dropdown. */
export interface SearchSuggestionsDto {
  articles: SearchArticleDto[];
  users: UserSummaryDto[];
  topics: SearchTopicDto[];
  tags: TagDto[];
}

// ── Explore and field pages (F15) ───────────────────────────

/** `GET /explore`: every section of the Explore page in one call. An empty section is `[]` (clients hide it). */
export interface ExploreDto {
  /** Every enabled field, in display order (empty ones included). */
  fields: FieldSummaryDto[];
  /** ≤ 6: the first of `/explore/trending`. */
  trending: ArticleCardDto[];
  /** ≤ 6: the first of `/explore/most-saved`. */
  mostSaved: ArticleCardDto[];
  /** ≤ 10, latest first publish first. May hold the caller (no Follow on your own row). */
  newWriters: UserSummaryDto[];
  /** ≤ 6, featured order. */
  featuredPaths: PathCardDto[];
}

/** A field tile on Explore; opens `/f/{slug}`. */
export interface FieldSummaryDto {
  id: string;
  slug: string;
  /** In Accept-Language. */
  name: string;
  nameAr: string;
  nameEn: string;
  /** Lucide icon name, e.g. "cpu". */
  icon: string;
  /** Color token, e.g. "primary". */
  color: string;
  /** Articles readers can see in it (the same for everyone). */
  articleCount: number;
}

/** `GET /fields/{slug}`: the field page's header and topic chips. */
export interface FieldPageDto {
  /** For `PUT`/`DELETE /me/interests/fields/{id}`. */
  id: string;
  slug: string;
  /** In Accept-Language. */
  name: string;
  nameAr: string;
  nameEn: string;
  icon: string;
  color: string;
  /** Show the health disclaimer note. */
  isSensitive: boolean;
  /** `0` → the empty state (`noindex`). */
  articleCount: number;
  /** People who follow the field itself (a followed topic doesn't count). */
  followerCount: number;
  /** False for guests. */
  isFollowing: boolean;
  /** Every topic, in editorial order, empty ones included. */
  topics: FieldPageTopicDto[];
}

/** A topic chip: filters with `?topic={slug}`. */
export interface FieldPageTopicDto {
  /** For `PUT`/`DELETE /me/interests/topics/{id}`. */
  id: string;
  slug: string;
  /** In Accept-Language. */
  name: string;
  nameAr: string;
  nameEn: string;
  articleCount: number;
  /** False for guests. */
  isFollowing: boolean;
}

// ── Media (ADR 0011) ────────────────────────────────────────

export type MediaKind = 'image' | 'document';
export type MediaPurpose = 'image' | 'avatar' | 'cover' | 'document';
export type MediaStatus = 'uploading' | 'processing' | 'ready' | 'failed';

/**
 * One responsive WebP rendition (an exact file per width, never upscaled). Widths per purpose:
 * avatar 64/128/256/512 · cover 400/800/1200 · image 320/640/1080/1600.
 */
export interface MediaVariantDto {
  width: number;
  height: number;
  url: string;
  bytes: number;
}

/** A rendered PDF page: 400 px thumb + 1080 px view. */
export interface MediaPageDto {
  pageNo: number;
  width: number;
  height: number;
  blurHash: string;
  thumbUrl: string;
  viewUrl: string;
}

export interface MediaAssetDto {
  id: string;
  kind: MediaKind;
  purpose: MediaPurpose;
  status: MediaStatus;
  /** Stable error code when `status = "failed"`, e.g. `media.processing_timeout`. */
  failureReason: string | null;
  /** Image: oriented original; document: first page (view size). */
  width: number | null;
  height: number | null;
  /** Placeholder (https://blurha.sh); document: first page. */
  blurHash: string | null;
  /** Original upload. */
  sizeBytes: number;
  /** Images, ascending width. */
  variants: MediaVariantDto[];
  /** Documents. */
  title: string | null;
  /** Documents, known as soon as the upload is accepted. */
  pageCount: number | null;
  /** Documents, pages rendered so far (page 1 first). */
  pagesReady: number;
  /** Documents, rendered pages in order. */
  pages: MediaPageDto[];
  allowDownload: boolean;
  createdAt: string;
}

export interface ImageAttachmentDto {
  assetId: string;
  order: number;
  /** ≤ 5000, render with `dir="auto"`. */
  caption: string | null;
  altText: string;
  width: number;
  height: number;
  blurHash: string | null;
  variants: MediaVariantDto[];
}

export interface DocumentAttachmentDto {
  assetId: string;
  title: string;
  pageCount: number;
  /** The author's setting. */
  allowDownload: boolean;
  /** For the current caller: `allowDownload`, or owner / moderator. */
  canDownload: boolean;
  /** `GET /documents/{assetId}/download` (absolute). */
  downloadUrl: string;
  pages: MediaPageDto[];
}

/** Either 1–10 images or exactly one PDF, never both. */
export interface ArticleAttachmentsDto {
  kind: 'images' | 'document';
  images: ImageAttachmentDto[];
  document: DocumentAttachmentDto | null;
}

// ── Reading & streaks (ADR 0013) ────────────────────────────
// Dates are the user's local dates ("yyyy-MM-dd") in their profile time zone.

/** `PUT /articles/{id}/progress`. Readers report on open (delta 0), every 15 s while active, and when they leave. */
export interface ReadingProgressRequest {
  language: ArticleLanguage;
  /** 0–100, the highest scroll position reached. */
  percent: number;
  /** ≤ 100 characters; restores the scroll position. */
  lastPosition: string | null;
  /** 0–3600, active seconds since the previous report. */
  activeSecondsDelta: number;
}

export interface StreakDto {
  /** 0 once broken. */
  current: number;
  longest: number;
  readToday: boolean;
  /** A freeze is ready for the next missed day (one per rolling 7 days). */
  freezeAvailable: boolean;
  /** Yesterday was missed; reading today uses a freeze and keeps the streak. */
  freezePending: boolean;
  today: string;
}

export type StreakMilestone = 7 | 30 | 100 | 365;

export interface ReadingProgressResultDto {
  percent: number;
  completed: boolean;
  /** This report made the article "read" (≥ 70% and ≥ 30 s, SPEC F04). */
  completedNow: boolean;
  /** Set when `completedNow`. */
  streak: StreakDto | null;
  /** Celebrate with a shareable card. */
  milestone: StreakMilestone | null;
}

/** A field the user reads most. `name` is localized; `icon` is a Lucide name and `color` a design token name. */
export interface TopFieldDto {
  id: string;
  slug: string;
  name: string;
  icon: string;
  color: string;
  articles: number;
}

/** `GET /me/stats` (owner only). "This week" is the last 7 local days and "this month" the last 30. */
export interface ReadingStatsDto {
  streak: StreakDto;
  totalArticles: number;
  minutesRead: number;
  articlesThisWeek: number;
  minutesThisWeek: number;
  articlesThisMonth: number;
  /** ≤ 3. */
  topFields: TopFieldDto[];
}

export interface HeatmapDayDto {
  date: string;
  articles: number;
  minutes: number;
  /** A missed day covered by a streak freeze. */
  frozen: boolean;
}

/** `GET /me/stats/heatmap?days=`: only days with a read or a freeze, oldest first. */
export interface ReadingHeatmapDto {
  from: string;
  /** The user's local today. */
  to: string;
  days: HeatmapDayDto[];
}

/** `ArticleDetailsDto.myProgress`: what the reader reached on one version (contract "Resume (F04)"). */
export interface MyProgressDto {
  /** The version the progress was recorded on. */
  language: ArticleLanguage;
  /** 0–100, the highest scroll position reached. */
  percent: number;
  /** As sent in `ReadingProgressRequest`, e.g. "0.4523". */
  lastPosition: string | null;
  /** Set once the article counts as read. */
  completedAt: string | null;
}

// ── Glossary (F21) ──────────────────────────────────────────

/** `GET /glossary?q=&limit=`: the editor's term picker. */
export interface GlossaryTermSummaryDto {
  /** The RDoc `term` node's `termId`. */
  slug: string;
  /** The English term, always shown LTR. */
  term: string;
  definitionEn: string;
}

/** `GET /glossary/{slug}?lang=`. `slug` is the RDoc `term` node's `termId`. */
export interface GlossaryTermDto {
  slug: string;
  /** The English term, always shown LTR. */
  term: string;
  definitionEn: string;
  /** Egyptian Arabic with English terms (SPEC §14 BiDi rules apply). */
  explanationAr: string;
  /** ≤ 6 published articles that use the term, best first; the reader drops the open one and shows ≤ 5. */
  articles: GlossaryArticleDto[];
}

export interface GlossaryArticleDto {
  id: string;
  slug: string;
  /** The language of `title` (the `lang` asked for when the article has it). */
  language: ArticleLanguage;
  title: string;
  readingTimeMinutes: number;
  field: FieldRefDto;
}

// ── Learning paths (F09) ────────────────────────────────────

/** A published path as a card: `/paths`, `/me/paths`, `/me/paths/active`, `/users/{username}/paths`. */
export interface PathCardDto {
  id: string;
  slug: string;
  /** In the UI language (Accept-Language). */
  title: string;
  /** In the UI language. */
  description: string | null;
  field: FieldRefDto;
  /** Articles a reader can open, in path order. */
  articleCount: number;
  /** Sum of their reading times (source language). */
  readingTimeMinutes: number;
  /** Absolute; the first article's cover. */
  coverUrl: string | null;
  /** Signed-in callers (also when not enrolled); null for guests. */
  progress: PathProgressDto | null;
  /** Null when not enrolled, and for guests. */
  enrollment: PathEnrollmentDto | null;
}

export interface PathProgressDto {
  /** Articles of this path you have read (F04 "read": ≥ 70% and ≥ 30 s). */
  readCount: number;
  /** = articleCount. */
  total: number;
  /** floor(readCount * 100 / total), 0–100. */
  percent: number;
  /** The first unread article in path order; null when all are read. */
  next: PathArticleRefDto | null;
}

export interface PathEnrollmentDto {
  enrolledAt: string;
  /** Set once every article was read while enrolled (the completion badge). It stays when the path later grows. */
  completedAt: string | null;
}

export interface PathArticleRefDto {
  id: string;
  slug: string;
  /** In your article language preference (falls back to the source language). */
  title: string;
  /** The version the title is in. */
  language: ArticleLanguage;
  /** 1-based place in the path. */
  position: number;
  readingTimeMinutes: number;
}

export interface PathItemDto {
  /** 1-based, dense. */
  position: number;
  article: ArticleCardDto;
  /** False for guests. */
  isRead: boolean;
}

/** `GET /paths/{slug}`. `404 path.not_found`. */
export interface PathDetailsDto extends PathCardDto {
  /** Path order. */
  items: PathItemDto[];
}

/** `GET /articles/{id}/path` (the reader's "Next in path" block); `204` when the article is in no published path. */
export interface ArticlePathDto {
  /** In several paths: the one you're enrolled in with the latest activity, else the first in editorial order. */
  path: PathCardDto;
  /** This article's place in the path, 1-based. */
  position: number;
  total: number;
  previous: PathArticleRefDto | null;
  /** The following article in path order (read or not); null on the last one. */
  next: ArticleCardDto | null;
}

// ── Continue reading (F03) ──────────────────────────────────

/** `GET /me/continue-reading`: an unfinished article you read in the last 30 days. */
export interface ContinueReadingDto {
  /** In the language you were reading (`language`). */
  article: ArticleCardDto;
  /** 5–100, how far you scrolled. */
  percent: number;
  /** The version you were reading. */
  language: ArticleLanguage;
  /** Last progress report. */
  updatedAt: string;
}

// ── Notifications (F17, SPEC §21.1) ───────────────────────────

/** The notification's `type`, also the push's `data.type`. */
export type NotificationType =
  | 'new_follower'
  | 'article_comment'
  | 'comment_reply'
  | 'mention'
  | 'reactions_milestone'
  | 'followed_writer_article'
  | 'daily_article'
  | 'streak_reminder'
  | 'security_alert'
  /** F19: an admin approved or rejected your writer verification request (`data.approved`). */
  | 'verification_result'
  | 'moderation_notice';

/** What changed on the account (`security_alert`); the API's `SecurityChange`, camelCase. */
export type SecurityChange =
  | 'passwordChanged'
  | 'passwordReset'
  | 'recoveryPinChanged'
  | 'phoneNumberChanged'
  | 'recoveryLockedOut'
  | 'externalLoginLinked'
  | 'externalLoginUnlinked'
  | 'phoneSignInAdded';

export interface NotificationActorDto {
  id: string;
  displayName: string;
  username: string;
  avatarUrl: string | null;
  isVerified: boolean;
}

/** `GET /me/notifications`, newest activity (`updatedAt`) first. */
export interface NotificationDto {
  id: string;
  type: NotificationType;
  createdAt: string;
  /** Last activity: aggregated rows move up when someone else joins. */
  updatedAt: string;
  isRead: boolean;
  /** The latest actor; null when that account was deleted ("Deleted user") or the type has none. */
  actor: NotificationActorDto | null;
  /** Distinct actors (≥ 1 when actor-based): "X and {actorCount - 1} others". */
  actorCount: number;
  /** In the viewer's article language. */
  article: { id: string; slug: string; title: string; language: ArticleLanguage } | null;
  /** ≤ 140 characters of plain text. Null for a mention in an article (`mention` names the article only). */
  comment: { id: string; parentId: string | null; excerpt: string } | null;
  /** `approved`: `verification_result` only (F19), left out by an API older than it. */
  data: { threshold?: number; streakDays?: number; securityChange?: SecurityChange; approved?: boolean };
  /** `readin://…`, the same deep links as pushes. */
  link: string;
}

export interface UnreadNotificationsDto {
  unread: number;
}

/** all = push + the notification center; inApp = the center only; off = nothing. */
export type NotificationMode = 'all' | 'inApp' | 'off';

/** The types a user can configure: security alerts, moderation notices and verification results always arrive. */
export type ConfigurableNotificationType = Exclude<NotificationType, 'security_alert' | 'verification_result' | 'moderation_notice'>;

export interface QuietHoursDto {
  enabled: boolean;
  /** "HH:mm" in the user's time zone. */
  start: string;
  end: string;
}

/** `GET`/`PUT /me/notification-settings`. A PUT sends only the types it changes (absent = unchanged). */
export interface NotificationSettingsDto {
  quietHours: QuietHoursDto;
  types: Partial<Record<ConfigurableNotificationType, NotificationMode>>;
}

// ── Writer verification (F19) ───────────────────────────────

export type VerificationStatus = 'pending' | 'approved' | 'rejected';
export const VERIFICATION_STATUSES: readonly VerificationStatus[] = ['pending', 'approved', 'rejected'];

export interface VerificationFieldDto {
  id: string;
  slug: string;
  /** In the request's UI language. */
  name: string;
}

/** Your latest request (`GET /me/verification`, `POST /verification-requests`). */
export interface MyVerificationRequestDto {
  id: string;
  status: VerificationStatus;
  field: VerificationFieldDto;
  jobTitle: string;
  proofUrl: string | null;
  /** The uploaded file's (sanitized) name; null without a file, and once the request is decided (the file is deleted). */
  proofFileName: string | null;
  note: string | null;
  submittedAt: string;
  decidedAt: string | null;
  /** Rejected only: the reviewer's reason, shown on the verification page (never in the push). */
  rejectionReason: string | null;
}

/** `GET /me/verification`. `canRequest`: signed in, not verified, not suspended, nothing pending. */
export interface VerificationStatusDto {
  isVerified: boolean;
  canRequest: boolean;
  /** The latest request, or null. */
  request: MyVerificationRequestDto | null;
}

/** `POST /verification-requests` (multipart). At least one of `proofUrl` / `proof`. */
export interface VerificationSubmission {
  fieldId: string;
  jobTitle: string;
  proofUrl: string | null;
  note: string | null;
  proof: File | null;
}

/** The uploaded proof as an admin sees it before the decision; `GET …/{id}/proof` streams it. */
export interface VerificationProofDto {
  fileName: string;
  contentType: string;
  sizeBytes: number;
}

/** A request in the admin review (`GET /admin/verification-requests`, `/{id}`). */
export interface AdminVerificationRequestDto {
  id: string;
  status: VerificationStatus;
  user: { id: string; displayName: string; username: string; avatarUrl: string | null; isVerified: boolean };
  field: VerificationFieldDto;
  jobTitle: string;
  proofUrl: string | null;
  /** Null without a file, and after the decision (the file is deleted then). */
  proof: VerificationProofDto | null;
  note: string | null;
  submittedAt: string;
  decidedAt: string | null;
  /** Null while pending, and when the reviewer's account was deleted. */
  decidedBy: { id: string; username: string } | null;
  rejectionReason: string | null;
}

/** RFC 9457 ProblemDetails with ReadIn's stable `code` (SPEC §6.5, §17.1). */
export interface ProblemDetails {
  type?: string;
  title?: string;
  status?: number;
  detail?: string;
  code?: string;
  traceId?: string;
  errors?: Record<string, string[]>;
  /** `user.suspended` (F22): when the suspension ends (ISO, UTC), or null when it is permanent. */
  suspendedUntil?: string | null;
}

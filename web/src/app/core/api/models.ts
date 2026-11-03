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

/** Settings → Privacy (F18). "Who can mention me" joins it with F11. */
export interface PrivacySettingsDto {
  /** Reading stats + heatmap on the public profile (F14). Off by default. */
  publicReadingStats: boolean;
}

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

/** Confirms a sensitive action: the password, or (accounts without one) a fresh token of a linked provider. */
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
}

export interface ArticleCardDto {
  id: string;
  slug: string;
  language: ArticleLanguage;
  title: string;
  subtitle: string | null;
  coverUrl: string | null;
  field: FieldRefDto;
  author: AuthorDto;
  readingTimeMinutes: number;
  isReviewed: boolean;
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
  tags: string[];
  sources: ArticleSourceDto[];
  reviewedBy: { displayName: string; username: string } | null;
  lastReviewedAt: string | null;
  readCount: number;
  /** False for guests and on your own articles. */
  isFollowingAuthor: boolean;
  /** The viewer's collections that contain the article; empty for guests. */
  collectionIds: string[];
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

// ── Reports and moderation (F22 hooks in F11) ───────────────

export type ReportReason = 'spam' | 'misinformation' | 'harassment' | 'copyright' | 'other';
export const REPORT_REASONS: readonly ReportReason[] = ['spam', 'misinformation', 'harassment', 'copyright', 'other'];

/** `POST /reports` (only comments until F22). Reporting again is a no-op. */
export interface ReportRequest {
  targetType: 'comment';
  targetId: string;
  reason: ReportReason;
  /** ≤ 500 characters. */
  details?: string | null;
}

export type ModerationAction = 'hide' | 'unhide' | 'delete';

/** `POST /moderation/actions` (permission `moderation.manage`). */
export interface ModerationActionRequest {
  action: ModerationAction;
  targetType: 'comment';
  targetId: string;
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
}

// ── Writing ─────────────────────────────────────────────────

export interface CreateArticleRequest {
  fieldId: string;
  topicId?: string | null;
  language: ArticleLanguage;
  /** 5..150 characters. */
  title: string;
  subtitle?: string | null;
  content: RDoc;
  tags?: string[];
  sources?: ArticleSourceDto[];
  coverUrl?: string | null;
  versionBadge?: string | null;
  isAiAssisted: boolean;
}

/** `201` response of `POST /articles` (the article is a draft until published). */
export interface CreatedArticleDto {
  id: string;
  slug: string;
}

export interface SetAttachmentItem {
  mediaAssetId: string;
  order: number;
  /** Images, ≤ 5000. */
  caption?: string | null;
  /** Images, required, ≤ 5000. */
  altText?: string | null;
  /** The document, required, ≤ 5000. */
  title?: string | null;
  /** The document. */
  allowDownload?: boolean;
}

/** Replaces the whole attachment set; `items: []` clears it. */
export interface SetAttachmentsRequest {
  items: SetAttachmentItem[];
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

/** RFC 9457 ProblemDetails with ReadIn's stable `code` (SPEC §6.5, §17.1). */
export interface ProblemDetails {
  type?: string;
  title?: string;
  status?: number;
  detail?: string;
  code?: string;
  traceId?: string;
  errors?: Record<string, string[]>;
}

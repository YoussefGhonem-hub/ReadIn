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

export interface ProfileLinks {
  github?: string;
  linkedin?: string;
  website?: string;
}

export interface SyncUserRequest {
  uiLanguage?: UiLanguage;
  timeZone?: string;
}

export interface MeDto {
  id: string;
  email: string;
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
  onboardingCompleted: boolean;
  roles: string[];
  permissions: string[];
  interests: { fieldIds: string[]; topicIds: string[] };
}

export interface UpdateProfileRequest {
  displayName: string;
  username: string;
  bio?: string | null;
  avatarUrl?: string | null;
  links?: ProfileLinks;
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
  reactionCount: number;
  commentCount: number;
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
  saveCount: number;
  readCount: number;
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

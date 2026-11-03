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

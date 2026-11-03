import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideRouter } from '@angular/router';
import { API_BASE_URL } from '../app/core/api/api.config';
import { ArticleCardDto, ArticleDetailsDto, ProblemDetails } from '../app/core/api/models';
import { SessionStore } from '../app/core/auth/session.store';
import { errorInterceptor } from '../app/core/http/error.interceptor';
import { provideAppIcons } from '../app/shared/ui/icons';
import { ToastService } from '../app/shared/ui/toast/toast.service';
import { TEST_API, testMe } from './auth-testing';
import { translocoTesting } from './transloco-testing';

/** A feed card with 12 reactions (💡 6 · ❤️ 3 · 🔥 2 · 🤯 1), 4 saves and 3 comments, as a guest sees it. */
export function testCard(patch: Partial<ArticleCardDto> = {}): ArticleCardDto {
  return {
    id: 'a1',
    slug: 'clean-architecture',
    language: 'en',
    title: 'Clean Architecture on one whiteboard',
    subtitle: null,
    coverUrl: null,
    field: { id: 'f1', slug: 'software', name: 'Software', nameAr: 'البرمجيات', nameEn: 'Software' },
    author: { id: 'writer-1', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true },
    readingTimeMinutes: 4,
    isReviewed: true,
    isAiAssisted: false,
    versionBadge: null,
    publishedAt: '2026-11-02T08:00:00Z',
    reactionCount: 12,
    reactions: { insightful: 6, love: 3, fire: 2, mindBlown: 1 },
    commentCount: 3,
    saveCount: 4,
    myReaction: null,
    isSaved: false,
    attachments: null,
    ...patch,
  };
}

export function testDetails(patch: Partial<ArticleDetailsDto> = {}): ArticleDetailsDto {
  return {
    ...testCard(),
    availableLanguages: ['en'],
    summary: null,
    content: { version: 1, language: 'en', blocks: [] },
    topic: null,
    tags: [],
    sources: [],
    reviewedBy: null,
    lastReviewedAt: null,
    readCount: 0,
    isFollowingAuthor: false,
    collectionIds: [],
    ...patch,
  } as ArticleDetailsDto;
}

export function problem(status: number, code: string, errors?: Record<string, string[]>): ProblemDetails {
  return { title: code, status, code, ...(errors ? { errors } : {}) };
}

/**
 * HttpClient with the error interceptor (failures become translated ApiErrors) against HttpTestingController, real
 * ar/en strings and a session: signed in as `user-1` unless `guest`.
 */
export function setupSocialTesting(options: { guest?: boolean; providers?: unknown[] } = {}) {
  TestBed.configureTestingModule({
    imports: [translocoTesting()],
    providers: [
      provideHttpClient(withInterceptors([errorInterceptor])),
      provideHttpClientTesting(),
      provideRouter([]),
      provideAppIcons(),
      { provide: API_BASE_URL, useValue: TEST_API },
      { provide: PLATFORM_ID, useValue: 'browser' },
      ...((options.providers ?? []) as never[]),
    ],
  });
  const session = TestBed.inject(SessionStore);
  if (options.guest) session.setGuest();
  else session.setMe(testMe());
  return { http: TestBed.inject(HttpTestingController), session, toasts: TestBed.inject(ToastService) };
}

/** Lets awaited HTTP results and the stores' follow-up requests run. */
export async function flushMicrotasks(times = 6): Promise<void> {
  for (let i = 0; i < times; i++) await Promise.resolve();
}

export { TEST_API };

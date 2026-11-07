import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Type } from '@angular/core';
import {
  AdminArticleRowDto,
  AdminCommentRowDto,
  AdminTicketDto,
  AdminTicketRowDto,
  AdminUserDto,
  AdminUserRowDto,
  PagedList,
  SupportTicketDto,
} from '../app/core/api/models';
import { flushMicrotasks } from './social-testing';

/** One offset page (F23). */
export function testPage<T>(items: T[], patch: Partial<PagedList<T>> = {}): PagedList<T> {
  return { items, page: 1, pageSize: 50, totalCount: items.length, totalPages: items.length ? 1 : 0, ...patch };
}

export function testUserRow(patch: Partial<AdminUserRowDto> = {}): AdminUserRowDto {
  return {
    id: 'u-salma',
    displayName: 'Salma Nabil',
    username: 'salma',
    avatarUrl: null,
    isVerified: false,
    isSystemAccount: false,
    roles: ['Member'],
    signInMethods: ['phone', 'google'],
    phoneMasked: '+20***4567',
    joinedAt: '2026-10-01T09:00:00Z',
    lastSeenAt: '2026-11-07T08:00:00Z',
    publishedArticles: 4,
    followers: 12,
    status: 'active',
    suspendedUntil: null,
    openReports: 0,
    ...patch,
  };
}

export function testAdminUser(patch: Partial<AdminUserDto> = {}): AdminUserDto {
  return {
    ...testUserRow(),
    headline: 'Backend engineer',
    bio: null,
    links: [],
    uiLanguage: 'ar',
    signUpMethod: 'phone',
    isStaff: false,
    stats: { drafts: 1, comments: 7, following: 3, totalReads: 90, articlesRead: 20, currentStreak: 4, longestStreak: 9 },
    access: { activeSessions: 2, hasRecoveryPin: true, recoveryDisabled: false, mustChangePassword: false, mustSetRecoveryPin: false, lockedOutUntil: null },
    actions: {
      canSuspend: true,
      canWarn: true,
      canLogoutAll: true,
      canResetPassword: true,
      canRemoveBadge: false,
      canClearProfile: true,
      canRestoreContent: false,
      canRevealPhone: true,
    },
    moderation: { warnings: 1, suspensions: 0, hiddenArticles: 0, hiddenComments: 1, hiddenWithAccount: 0, history: [], historyTotal: 0 },
    reports: { against: [], againstTotal: 0, filed: [], filedTotal: 0 },
    verification: { items: [], total: 0 },
    tickets: { items: [], total: 0 },
    audit: { items: [], total: 0 },
    ...patch,
  };
}

export function testArticleRow(patch: Partial<AdminArticleRowDto> = {}): AdminArticleRowDto {
  return {
    id: 'a1',
    slug: 'clean-architecture',
    status: 'published',
    title: 'Clean Architecture on one whiteboard',
    language: 'en',
    author: { id: 'writer-1', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true },
    field: { id: 'f1', slug: 'software', name: 'Software', nameAr: 'البرمجيات', nameEn: 'Software' },
    topic: null,
    publishedAt: '2026-11-02T08:00:00Z',
    readCount: 40,
    reactionCount: 12,
    commentCount: 3,
    hiddenAt: null,
    featuredAt: null,
    openReports: 0,
    reportCount: 0,
    ...patch,
  };
}

export function testCommentRow(patch: Partial<AdminCommentRowDto> = {}): AdminCommentRowDto {
  return {
    id: 'c1',
    body: 'Buy followers at spam.example',
    author: { id: 'u-spam', displayName: 'Spammer', username: 'spam', avatarUrl: null, isVerified: false },
    article: { id: 'a1', slug: 'clean-architecture', title: 'Clean Architecture', language: 'en' },
    parentId: null,
    createdAt: '2026-11-07T09:00:00Z',
    editedAt: null,
    hiddenAt: null,
    likeCount: 0,
    replyCount: 0,
    openReports: 0,
    reportCount: 0,
    ...patch,
  };
}

export function testTicketRow(patch: Partial<AdminTicketRowDto> = {}): AdminTicketRowDto {
  return {
    id: 't1',
    number: 12,
    category: 'app_problem',
    subject: 'The app closes on launch',
    status: 'open',
    user: { id: 'u-salma', displayName: 'Salma Nabil', username: 'salma', avatarUrl: null, isVerified: false },
    createdAt: '2026-11-07T08:00:00Z',
    waitingSince: '2026-11-07T08:00:00Z',
    lastMessage: { fromSupport: false, isInternalNote: false, excerpt: 'It closes right after the splash screen.', createdAt: '2026-11-07T08:00:00Z' },
    closedAt: null,
    ...patch,
  };
}

export function testAdminTicket(patch: Partial<AdminTicketDto> = {}): AdminTicketDto {
  return {
    ...testTicketRow(),
    device: { platform: 'android', osVersion: 'Android 15', appVersion: '1.2.0+57', language: 'ar', screen: '/settings/support' },
    messages: [
      {
        id: 'm1',
        fromSupport: false,
        isInternalNote: false,
        body: 'It closes right after the splash screen.',
        attachments: [{ id: 'att-1', contentType: 'image/png', sizeBytes: 120_000 }],
        createdAt: '2026-11-07T08:00:00Z',
        author: { id: 'u-salma', displayName: 'Salma Nabil', username: 'salma' },
      },
    ],
    closedBy: null,
    member: { status: 'active', suspendedUntil: null, joinedAt: '2026-10-01T09:00:00Z', signInMethods: ['phone'], ticketCount: 2 },
    reportsFiled: { items: [], total: 0 },
    reportsAgainst: 0,
    moderation: [],
    ...patch,
  };
}

export function testTicket(patch: Partial<SupportTicketDto> = {}): SupportTicketDto {
  return {
    id: 't1',
    number: 12,
    category: 'app_problem',
    subject: 'The app closes on launch',
    status: 'answered',
    createdAt: '2026-11-07T08:00:00Z',
    updatedAt: '2026-11-07T10:00:00Z',
    lastMessage: { fromSupport: true, excerpt: 'Please update to 1.2.1.', createdAt: '2026-11-07T10:00:00Z' },
    closedAt: null,
    canReopen: false,
    device: { platform: 'web', osVersion: 'Windows · Chrome 131', appVersion: null, language: 'ar', screen: '/support' },
    messages: [
      { id: 'm1', fromSupport: false, body: 'It closes right after the splash screen.', attachments: [{ id: 'att-1', contentType: 'image/png', sizeBytes: 120_000 }], createdAt: '2026-11-07T08:00:00Z' },
      { id: 'm2', fromSupport: true, body: 'Please update to 1.2.1.', attachments: [], createdAt: '2026-11-07T10:00:00Z' },
    ],
    ...patch,
  };
}

/** Renders a component with optional inputs and gives query helpers and `stable()` (HTTP results applied). */
export function renderAdmin<T>(component: Type<T>, inputs: Record<string, unknown> = {}) {
  const fixture: ComponentFixture<T> = TestBed.createComponent(component);
  for (const [key, value] of Object.entries(inputs)) fixture.componentRef.setInput(key, value);
  fixture.detectChanges();
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await flushMicrotasks();
    fixture.detectChanges();
  };
  const $ = <E extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<E>(selector);
  const $$ = (selector: string) => [...root.querySelectorAll<HTMLElement>(selector)];
  /** Sets an input's or select's value and fires its event. */
  const type = (selector: string, value: string, event: 'input' | 'change' = 'input') => {
    const el = root.querySelector<HTMLInputElement>(selector)!;
    el.value = value;
    el.dispatchEvent(new Event(event));
    fixture.detectChanges();
  };
  return { fixture, root, stable, $, $$, type };
}

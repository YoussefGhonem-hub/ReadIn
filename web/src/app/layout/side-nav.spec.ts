import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { testMe } from '../../testing/auth-testing';
import { setupSocialTesting } from '../../testing/social-testing';
import { ModerationSummaryStore } from '../core/moderation/moderation-summary.store';
import { NotificationBadge } from '../core/notifications/notification-badge';
import { SideNav } from './side-nav';

describe('SideNav: admin entries (F19)', () => {
  function render(permissions: string[]) {
    TestBed.resetTestingModule();
    const { session } = setupSocialTesting({
      providers: [
        { provide: NotificationBadge, useValue: { count: signal(0) } },
        { provide: ModerationSummaryStore, useValue: { total: signal(0) } },
      ],
    });
    session.setMe(testMe({ permissions }));
    const fixture = TestBed.createComponent(SideNav);
    fixture.detectChanges();
    return fixture.nativeElement as HTMLElement;
  }

  it('"Verification requests" only with verification.manage', () => {
    expect(render(['articles.read', 'articles.create']).querySelector('a[href="/admin/verification"]')).toBeNull();

    const nav = render(['articles.read', 'articles.create', 'verification.manage']);
    const link = nav.querySelector<HTMLAnchorElement>('a[href="/admin/verification"]')!;
    expect(link.textContent!.trim()).toBe('طلبات التوثيق');
    // Moderation stays with its own permission.
    expect(nav.querySelector('a[href="/moderation"]')).toBeNull();
  });
});

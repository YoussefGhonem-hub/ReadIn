import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { setupSocialTesting } from '../../testing/social-testing';
import { NotificationBadge } from '../core/notifications/notification-badge';
import { StreakStore } from '../features/reading/streak.store';
import { TopBar } from './top-bar';

describe('TopBar notifications bell (F17)', () => {
  const count = signal(0);

  beforeEach(() => {
    TestBed.resetTestingModule();
    count.set(0);
    setupSocialTesting({
      providers: [
        { provide: NotificationBadge, useValue: { count } },
        { provide: StreakStore, useValue: { streak: signal(null) } },
      ],
    });
  });

  it('shows a dot while there are unseen notifications, and says how many to screen readers', () => {
    const fixture = TestBed.createComponent(TopBar);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const bell = root.querySelector<HTMLAnchorElement>('[data-notifications-link]')!;
    expect(bell.getAttribute('href')).toBe('/notifications');
    expect(bell.querySelector('[data-unread-badge]')).toBeNull();
    expect(bell.getAttribute('aria-label')).toBe('الإشعارات');

    count.set(3);
    fixture.detectChanges();
    expect(bell.querySelector('[data-unread-badge]')).not.toBeNull();
    expect(bell.getAttribute('aria-label')).toBe('الإشعارات، 3 إشعارات جديدة');

    count.set(0); // the center was opened
    fixture.detectChanges();
    expect(bell.querySelector('[data-unread-badge]')).toBeNull();
  });
});

import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { ReportedStore } from '../../core/moderation/reported.store';
import { BlockStore } from '../../core/social/block.store';
import { FollowStore } from '../../core/social/follow.store';
import { ReportSheet, ReportTarget } from './report-sheet';
import { ReportedNotice } from './reported-notice';

@Component({
  imports: [ReportSheet, ReportedNotice],
  template: `
    <rd-report-sheet [target]="target()" (closed)="target.set(null)" />
    <rd-reported-notice (show)="shows = shows + 1" />
  `,
})
class Host {
  readonly target = signal<ReportTarget | null>(null);
  shows = 0;
}

const AUTHOR = { id: 'writer-2', displayName: 'Omar', username: 'omar' };

describe('ReportSheet: the App Store additions (F22, F36)', () => {
  let http: HttpTestingController;

  function render() {
    TestBed.resetTestingModule();
    const setup = setupSocialTesting();
    http = setup.http;
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    };
    const open = async (target: ReportTarget) => {
      fixture.componentInstance.target.set(target);
      await stable();
    };
    return { root, stable, open, toasts: setup.toasts, host: fixture.componentInstance, $: <T extends HTMLElement = HTMLElement>(s: string) => root.querySelector<T>(s) };
  }

  afterEach(() => http.verify());

  it('a repost is reported with its own title and question', async () => {
    const t = render();
    await t.open({ type: 'repost', id: 'r1', author: AUTHOR });
    expect(t.$('#report-sheet-title')!.textContent!.trim()).toBe('الإبلاغ عن إعادة النشر');
    expect(t.$('legend')!.textContent!.trim()).toBe('ما المشكلة في إعادة النشر هذه؟');
    t.$<HTMLInputElement>('[data-reason="spam"]')!.click();
    await t.stable();
    t.$('[data-report-submit]')!.click();
    const req = http.expectOne(`${TEST_API}/reports`);
    expect(req.request.body).toEqual({ targetType: 'repost', targetId: 'r1', reason: 'spam' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
  });

  it('"Also block @username" is off by default; without it the report is sent alone and the target collapses for you', async () => {
    const t = render();
    await t.open({ type: 'comment', id: 'c1', author: AUTHOR });
    const also = t.$('[data-also-block]')!;
    expect(also.textContent!.replace(/\s+/g, ' ').trim()).toBe('حظر أيضًا @omar');
    expect(also.querySelector<HTMLInputElement>('input')!.checked).toBe(false);

    t.$<HTMLInputElement>('[data-reason="harassment"]')!.click();
    await t.stable();
    t.$('[data-report-submit]')!.click();
    const req = http.expectOne(`${TEST_API}/reports`);
    expect(req.request.body.alsoBlock).toBeUndefined();
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();

    expect(TestBed.inject(ReportedStore).isCollapsed('comment', 'c1')).toBe(true);
    expect(TestBed.inject(BlockStore).isBlocked('writer-2')).toBe(false);
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['شكرًا، سنراجع البلاغ']);
  });

  it('ticked, the report blocks them too (one request), ends the follow and says so', async () => {
    const t = render();
    const follows = TestBed.inject(FollowStore);
    follows.learn('writer-2', true);
    await t.open({ type: 'article', id: 'a1', author: AUTHOR });
    t.$<HTMLInputElement>('[data-reason="spam"]')!.click();
    t.$<HTMLInputElement>('[data-also-block] input')!.click();
    await t.stable();
    t.$('[data-report-submit]')!.click();
    const req = http.expectOne(`${TEST_API}/reports`);
    expect(req.request.body).toEqual({ targetType: 'article', targetId: 'a1', reason: 'spam', alsoBlock: true });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();

    expect(TestBed.inject(BlockStore).isBlocked('writer-2')).toBe(true);
    expect(follows.isFollowing('writer-2', true)).toBe(false);
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['شكرًا، سنراجع البلاغ. وتم حظر الحساب أيضًا.']);
    http.expectNone(`${TEST_API}/users/writer-2/block`);
  });

  it('a target without a known author (a deleted account) has no "Also block"', async () => {
    const t = render();
    await t.open({ type: 'article', id: 'a1', author: null });
    expect(t.$('[data-also-block]')).toBeNull();
    await t.open({ type: 'user', id: 'u1' });
    expect(t.$('[data-also-block]')).toBeNull();
  });

  it('opening the sheet again starts with "Also block" off', async () => {
    const t = render();
    await t.open({ type: 'article', id: 'a1', author: AUTHOR });
    t.$<HTMLInputElement>('[data-also-block] input')!.click();
    await t.stable();
    t.host.target.set(null);
    await t.stable();
    await t.open({ type: 'article', id: 'a2', author: AUTHOR });
    expect(t.$<HTMLInputElement>('[data-also-block] input')!.checked).toBe(false);
  });

  it('the collapsed notice says you reported it and offers «عرض»', async () => {
    const t = render();
    const notice = t.$('[data-reported-notice]')!;
    expect(notice.textContent).toContain('أبلغت عن هذا المحتوى، ولن يظهر لك بعد الآن.');
    const show = t.$('[data-reported-show]')!;
    expect(show.textContent!.trim()).toBe('عرض');
    show.click();
    expect(t.host.shows).toBe(1);
  });
});

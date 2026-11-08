import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { NEVER } from 'rxjs';
import { testProfile } from '../../../testing/profile-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ProfileDto } from '../../core/api/models';
import { ProfilesApi } from '../../core/api/profiles.api';
import { ReadingApi } from '../../core/api/reading.api';
import { BlockStore } from '../../core/social/block.store';
import { ProfilePage } from './profile.page';

const PROFILE = `${TEST_API}/users/karim`;
const KARIM = { id: 'writer-1', displayName: 'Karim Hassan', username: 'karim' };

describe('ProfilePage: someone you blocked (F36)', () => {
  let http: HttpTestingController;

  afterEach(() => {
    for (const extra of http.match(() => true)) extra.flush({ items: [], nextCursor: null });
    http.verify();
  });

  async function render(first: ProfileDto | 'blocked') {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({
      providers: [
        { provide: ReadingApi, useValue: { stats: () => NEVER, heatmap: () => NEVER } },
        { provide: ProfilesApi, useFactory: () => Object.assign(new ProfilesApi(), { stats: () => NEVER, heatmap: () => NEVER }) },
      ],
    }));
    const fixture = TestBed.createComponent(ProfilePage);
    fixture.componentRef.setInput('username', 'karim');
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const settle = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await flushMicrotasks();
      fixture.detectChanges();
    };
    const answer = async (response: ProfileDto | 'blocked') => {
      const req = http.expectOne(PROFILE);
      if (response === 'blocked') req.flush({ ...problem(403, 'block.blocked'), blockedUser: KARIM }, { status: 403, statusText: 'Forbidden' });
      else req.flush(response);
      // Their articles (and anything else the page lists): empty here.
      for (const extra of http.match((r) => r.url !== PROFILE)) extra.flush({ items: [], nextCursor: null });
      await settle();
    };
    await answer(first);
    return { root, settle, answer, $: (s: string) => root.querySelector<HTMLElement>(s) };
  }

  it('"This account isn\'t available", with Unblock that loads the profile again', async () => {
    const t = await render('blocked');
    const state = t.$('rd-blocked-state')!;
    expect(state.getAttribute('data-blocked-state')).toBe('account');
    expect(state.textContent).toContain('هذا الحساب غير متاح');
    expect(state.textContent!.replace(/\s+/g, ' ')).toContain('لقد حظرت @karim');
    expect(t.$('[data-profile-header]')).toBeNull();

    t.$('[data-unblock]')!.click();
    await t.settle();
    const del = http.expectOne(`${TEST_API}/users/writer-1/block`);
    expect(del.request.method).toBe('DELETE');
    del.flush({ userId: 'writer-1', isBlocked: false, followRemoved: false });
    await t.settle();
    await t.answer(testProfile());
    expect(t.$('rd-blocked-state')).toBeNull();
    expect(t.$('[data-profile-header]')).not.toBeNull();
  });

  it('a block from the "⋯" menu shows the state at once; Unblock brings the profile back without a reload', async () => {
    const t = await render(testProfile());
    expect(t.$('[data-profile-header]')).not.toBeNull();
    TestBed.inject(BlockStore).learnBlocked('writer-1');
    await t.settle();
    expect(t.$('rd-blocked-state')!.textContent).toContain('هذا الحساب غير متاح');
    t.$('[data-unblock]')!.click();
    await t.settle();
    http.expectOne(`${TEST_API}/users/writer-1/block`).flush({ userId: 'writer-1', isBlocked: false, followRemoved: false });
    await t.settle();
    expect(t.$('[data-profile-header]')).not.toBeNull();
    http.expectNone(PROFILE);
  });
});

import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { BlockStore, BlockedPersonRef } from '../../core/social/block.store';
import { BlockDialog } from './block-dialog';
import { BlockedState } from './blocked-state';

const OMAR: BlockedPersonRef = { id: 'writer-2', displayName: 'Omar', username: 'omar' };
const URL = `${TEST_API}/users/writer-2/block`;

@Component({
  imports: [BlockDialog, BlockedState],
  template: `
    <rd-block-dialog [person]="person()" (closed)="closes = closes + 1; person.set(null)" (blocked)="blocked.push($event.id)" />
    @if (stateUser(); as u) {
      <rd-blocked-state [kind]="kind()" [user]="u" (unblocked)="unblocks = unblocks + 1" />
    }
  `,
})
class Host {
  readonly person = signal<BlockedPersonRef | null>(null);
  readonly stateUser = signal<BlockedPersonRef | null>(null);
  readonly kind = signal<'account' | 'content'>('content');
  closes = 0;
  unblocks = 0;
  readonly blocked: string[] = [];
}

describe('Block dialog and the unavailable state (F36)', () => {
  let http: HttpTestingController;

  function render(options: { guest?: boolean } = {}) {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting(options));
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      fixture.detectChanges();
      await flushMicrotasks();
      fixture.detectChanges();
    };
    return { fixture, host: fixture.componentInstance, root, stable, $: (s: string) => root.querySelector<HTMLElement>(s) };
  }

  afterEach(() => http.verify());

  it('asks first, names @username, says what a block does, and confirms with «حظر» in the error color', async () => {
    const t = render();
    t.host.person.set(OMAR);
    await t.stable();
    const dialog = t.$('[data-block-dialog]')!;
    expect(t.$('#block-dialog-title')!.textContent!.replace(/\s+/g, ' ').trim()).toBe('هل تريد حظر @omar؟');
    expect(dialog.textContent).toContain('لن يرى أحدكما مقالات الآخر أو تعليقاته');
    const confirm = t.$('[data-block-confirm]')!;
    expect(confirm.textContent!.trim()).toBe('حظر');
    expect(confirm.className).toContain('bg-error');
    expect([...dialog.querySelectorAll('button')].map((b) => b.textContent!.trim())).toEqual(['إلغاء', 'حظر']);
  });

  it('Cancel closes without a request', async () => {
    const t = render();
    t.host.person.set(OMAR);
    await t.stable();
    [...t.$('[data-block-dialog]')!.querySelectorAll('button')][0].click();
    await t.stable();
    expect(t.host.closes).toBe(1);
    expect(t.$('[data-block-dialog]')).toBeNull();
    http.expectNone(URL);
  });

  it('«حظر» blocks (PUT), reports it and closes; a refusal closes without reporting a block', async () => {
    const t = render();
    t.host.person.set(OMAR);
    await t.stable();
    t.$('[data-block-confirm]')!.click();
    await t.stable();
    // Busy while the block is on its way.
    expect((t.$('[data-block-confirm]') as HTMLButtonElement).disabled).toBe(true);
    const put = http.expectOne(URL);
    expect(put.request.method).toBe('PUT');
    put.flush({ userId: 'writer-2', isBlocked: true, followRemoved: false });
    await t.stable();
    expect(t.host.blocked).toEqual(['writer-2']);
    expect(t.host.closes).toBe(1);
    expect(TestBed.inject(BlockStore).isBlocked('writer-2')).toBe(true);

    t.host.person.set({ ...OMAR, id: 'writer-3', username: 'sara' });
    await t.stable();
    t.$('[data-block-confirm]')!.click();
    await t.stable();
    http.expectOne(`${TEST_API}/users/writer-3/block`).flush(problem(400, 'block.self'), { status: 400, statusText: 'Bad Request' });
    await t.stable();
    expect(t.host.blocked).toEqual(['writer-2']);
    expect(t.host.closes).toBe(2);
  });

  it('guests get the sign-in prompt instead of the dialog', async () => {
    const t = render({ guest: true });
    t.host.person.set(OMAR);
    await t.stable();
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
    expect(t.host.closes).toBe(1);
    http.expectNone(URL);
  });

  it('the blocker sees «هذا المحتوى غير متاح» or «هذا الحساب غير متاح», with Unblock that reloads the page', async () => {
    const t = render();
    t.host.stateUser.set(OMAR);
    await t.stable();
    const state = t.$('rd-blocked-state')!;
    expect(state.getAttribute('data-blocked-state')).toBe('content');
    expect(state.getAttribute('role')).toBe('status');
    expect(state.querySelector('h3')!.textContent!.trim()).toBe('هذا المحتوى غير متاح');
    expect(state.textContent!.replace(/\s+/g, ' ')).toContain('لقد حظرت @omar');
    t.host.kind.set('account');
    await t.stable();
    expect(state.querySelector('h3')!.textContent!.trim()).toBe('هذا الحساب غير متاح');

    t.$('[data-unblock]')!.click();
    await t.stable();
    const del = http.expectOne(URL);
    expect(del.request.method).toBe('DELETE');
    del.flush({ userId: 'writer-2', isBlocked: false, followRemoved: false });
    await t.stable();
    expect(t.host.unblocks).toBe(1);
  });

  it('a failed Unblock keeps the state, so the page does not reload', async () => {
    const t = render();
    t.host.stateUser.set(OMAR);
    await t.stable();
    t.$('[data-unblock]')!.click();
    await t.stable();
    http.expectOne(URL).flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    await t.stable();
    expect(t.host.unblocks).toBe(0);
    expect((t.$('[data-unblock]') as HTMLButtonElement).disabled).toBe(false);
  });
});

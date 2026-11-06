import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Router } from '@angular/router';
import { testProfile } from '../../../testing/profile-testing';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { LanguageService } from '../../core/i18n/language.service';
import { PROFILE_CARD_GRACE_MS, ProfileCardService } from './profile-card.service';

function key(name: string): void {
  document.dispatchEvent(new KeyboardEvent('keydown', { key: name, bubbles: true }));
}

const card = () => document.querySelector<HTMLElement>('.cdk-overlay-container [data-profile-card]');

describe('ProfileCardService (one hover card at a time)', () => {
  let http: HttpTestingController;
  let cards: ProfileCardService;
  let links: HTMLElement[];

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
    cards = TestBed.inject(ProfileCardService);
    links = ['karim', 'nour'].map((name) => {
      const a = document.createElement('a');
      a.href = `/@${name}`;
      a.textContent = `@${name}`;
      document.body.appendChild(a);
      return a;
    });
  });

  afterEach(() => {
    cards.close();
    links.forEach((a) => a.remove());
    vi.useRealTimers();
    http.verify();
  });

  async function respond(username: string): Promise<void> {
    TestBed.tick(); // the card renders and asks
    http.expectOne(`${TEST_API}/users/${username}`).flush(testProfile({ username, displayName: username === 'karim' ? 'Karim Hassan' : 'Nour Fawzy' }));
    await flushMicrotasks();
    TestBed.tick();
  }

  it('opens the card at its link, in the UI direction, without taking the focus', async () => {
    links[0].focus();
    cards.open(links[0], 'karim');
    TestBed.tick();
    expect(cards.isOpenFor(links[0])).toBe(true);
    expect(card()).not.toBeNull();
    expect(card()!.closest('[dir]')!.getAttribute('dir')).toBe(TestBed.inject(LanguageService).dir());
    expect(document.activeElement).toBe(links[0]);
    await respond('karim');
    expect(card()!.textContent).toContain('Karim Hassan');
  });

  it('only one card is ever open: another one replaces it', async () => {
    cards.open(links[0], 'karim');
    await respond('karim');
    cards.open(links[1], 'nour');
    await respond('nour');
    expect(document.querySelectorAll('[data-profile-card]')).toHaveLength(1);
    expect(card()!.textContent).toContain('Nour Fawzy');
    expect(cards.isOpenFor(links[0])).toBe(false);
    expect(cards.isOpenFor(links[1])).toBe(true);
  });

  it('closes on Escape', async () => {
    cards.open(links[0], 'karim');
    await respond('karim');
    key('Enter');
    expect(card()).not.toBeNull();
    key('Escape');
    expect(card()).toBeNull();
    expect(cards.isOpenFor(links[0])).toBe(false);
  });

  it('closes on navigation', async () => {
    cards.open(links[0], 'karim');
    await respond('karim');
    await TestBed.inject(Router).navigateByUrl('/elsewhere').catch(() => undefined);
    expect(card()).toBeNull();
  });

  it('leaving the link closes it after a short grace; the pointer reaching the card keeps it open', async () => {
    vi.useFakeTimers();
    cards.open(links[0], 'karim');
    await respond('karim');
    const pane = card()!.closest<HTMLElement>('.cdk-overlay-pane')!;

    cards.leave(links[0]);
    vi.advanceTimersByTime(PROFILE_CARD_GRACE_MS - 50);
    pane.dispatchEvent(new Event('pointerenter'));
    vi.advanceTimersByTime(PROFILE_CARD_GRACE_MS * 2);
    expect(card()).not.toBeNull();

    // The link losing focus while the pointer rests on the card doesn't close it either.
    cards.leave(links[0]);
    vi.advanceTimersByTime(PROFILE_CARD_GRACE_MS * 2);
    expect(card()).not.toBeNull();

    pane.dispatchEvent(new Event('pointerleave'));
    vi.advanceTimersByTime(PROFILE_CARD_GRACE_MS - 50);
    expect(card()).not.toBeNull();
    cards.stay(); // back on the link
    vi.advanceTimersByTime(PROFILE_CARD_GRACE_MS * 2);
    expect(card()).not.toBeNull();

    cards.leave(links[0]);
    vi.advanceTimersByTime(PROFILE_CARD_GRACE_MS);
    expect(card()).toBeNull();
  });

  it('leaving or removing another link leaves the open card alone', async () => {
    cards.open(links[0], 'karim');
    await respond('karim');
    cards.leave(links[1]);
    cards.closeFor(links[1]);
    expect(cards.isOpenFor(links[0])).toBe(true);
    cards.closeFor(links[0]);
    expect(card()).toBeNull();
  });

  it('cards are for devices that hover', () => {
    const stub = (matches: boolean) => vi.stubGlobal('matchMedia', (query: string) => ({ matches, media: query, addEventListener: () => undefined, removeEventListener: () => undefined }));
    stub(true);
    expect(cards.canHover()).toBe(true);
    stub(false);
    expect(cards.canHover()).toBe(false);
    vi.unstubAllGlobals();
  });
});

describe('ProfileCardService on the server', () => {
  it('does nothing', () => {
    TestBed.resetTestingModule();
    const { http } = setupSocialTesting({ providers: [{ provide: PLATFORM_ID, useValue: 'server' }] });
    const cards = TestBed.inject(ProfileCardService);
    const link = document.createElement('a');
    cards.open(link, 'karim');
    expect(cards.isOpenFor(link)).toBe(false);
    expect(cards.canHover()).toBe(false);
    http.verify();
  });
});

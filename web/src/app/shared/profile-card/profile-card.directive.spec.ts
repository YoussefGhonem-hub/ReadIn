import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { setupSocialTesting } from '../../../testing/social-testing';
import { ProfileCardTrigger } from './profile-card.directive';
import { PROFILE_CARD_FOCUS_MS, PROFILE_CARD_HOVER_MS, ProfileCardService } from './profile-card.service';

@Component({
  imports: [ProfileCardTrigger],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (shown()) {
      <a href="/@karim" [rdProfileCard]="username()" data-link>&#64;karim</a>
    }
  `,
})
class Host {
  readonly username = signal<string | null>('@karim');
  readonly shown = signal(true);
}

function pointer(el: Element, type: string, pointerType = 'mouse'): void {
  const event = new Event(type);
  Object.defineProperty(event, 'pointerType', { value: pointerType });
  el.dispatchEvent(event);
}

describe('[rdProfileCard] (the hover card trigger)', () => {
  let cards: { open: ReturnType<typeof vi.fn>; leave: ReturnType<typeof vi.fn>; stay: ReturnType<typeof vi.fn>; closeFor: ReturnType<typeof vi.fn>; isOpenFor: ReturnType<typeof vi.fn>; canHover: ReturnType<typeof vi.fn> };
  let open: Element | null;

  beforeEach(() => {
    TestBed.resetTestingModule();
    open = null;
    cards = {
      open: vi.fn((el: Element) => (open = el)),
      leave: vi.fn(),
      stay: vi.fn(),
      closeFor: vi.fn(),
      isOpenFor: vi.fn((el: Element) => el === open),
      canHover: vi.fn(() => true),
    };
    setupSocialTesting({ providers: [{ provide: ProfileCardService, useValue: cards }] });
    vi.useFakeTimers();
  });

  afterEach(() => vi.useRealTimers());

  function render() {
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const link = (fixture.nativeElement as HTMLElement).querySelector<HTMLAnchorElement>('[data-link]')!;
    return { fixture, link };
  }

  it('opens the card after the pointer rests on the link, without the @', () => {
    const { link } = render();
    expect(link.hasAttribute('aria-haspopup')).toBe(false); // the link stays a plain link
    pointer(link, 'pointerenter');
    vi.advanceTimersByTime(PROFILE_CARD_HOVER_MS - 1);
    expect(cards.open).not.toHaveBeenCalled();
    vi.advanceTimersByTime(1);
    expect(cards.open).toHaveBeenCalledWith(link, 'karim');
  });

  it('passing over the link opens nothing; leaving starts the grace of an open card', () => {
    const { link } = render();
    pointer(link, 'pointerenter');
    vi.advanceTimersByTime(PROFILE_CARD_HOVER_MS / 2);
    pointer(link, 'pointerleave');
    vi.advanceTimersByTime(PROFILE_CARD_HOVER_MS * 2);
    expect(cards.open).not.toHaveBeenCalled();
    expect(cards.leave).toHaveBeenCalledWith(link);
  });

  it('coming back to the link while its card is open keeps it open', () => {
    const { link } = render();
    pointer(link, 'pointerenter');
    vi.advanceTimersByTime(PROFILE_CARD_HOVER_MS);
    pointer(link, 'pointerleave');
    pointer(link, 'pointerenter');
    expect(cards.stay).toHaveBeenCalled();
    vi.advanceTimersByTime(PROFILE_CARD_HOVER_MS);
    expect(cards.open).toHaveBeenCalledTimes(1);
  });

  it('touch and devices that don’t hover get no card: a tap opens the profile', () => {
    const { link } = render();
    pointer(link, 'pointerenter', 'touch');
    vi.advanceTimersByTime(PROFILE_CARD_HOVER_MS * 2);
    expect(cards.open).not.toHaveBeenCalled();

    cards.canHover.mockReturnValue(false);
    pointer(link, 'pointerenter');
    vi.advanceTimersByTime(PROFILE_CARD_HOVER_MS * 2);
    expect(cards.open).not.toHaveBeenCalled();
  });

  it('a press cancels the card on its way', () => {
    const { link } = render();
    pointer(link, 'pointerenter');
    pointer(link, 'pointerdown');
    vi.advanceTimersByTime(PROFILE_CARD_HOVER_MS * 2);
    expect(cards.open).not.toHaveBeenCalled();
  });

  it('keyboard focus that shows opens it after a longer rest; a click’s focus doesn’t', () => {
    const { link } = render();
    const matches = vi.spyOn(link, 'matches').mockImplementation((selector: string) => selector === ':focus-visible');
    link.dispatchEvent(new FocusEvent('focus'));
    vi.advanceTimersByTime(PROFILE_CARD_HOVER_MS);
    expect(cards.open).not.toHaveBeenCalled();
    vi.advanceTimersByTime(PROFILE_CARD_FOCUS_MS - PROFILE_CARD_HOVER_MS);
    expect(cards.open).toHaveBeenCalledWith(link, 'karim');

    link.dispatchEvent(new FocusEvent('blur'));
    expect(cards.leave).toHaveBeenCalledWith(link);

    cards.open.mockClear();
    open = null;
    matches.mockReturnValue(false);
    link.dispatchEvent(new FocusEvent('focus'));
    vi.advanceTimersByTime(PROFILE_CARD_FOCUS_MS * 2);
    expect(cards.open).not.toHaveBeenCalled();
  });

  it('no username, no card', () => {
    const { fixture, link } = render();
    fixture.componentInstance.username.set(null);
    fixture.detectChanges();
    pointer(link, 'pointerenter');
    vi.advanceTimersByTime(PROFILE_CARD_HOVER_MS * 2);
    expect(cards.open).not.toHaveBeenCalled();
  });

  it('a link that leaves the page closes its card', () => {
    const { fixture, link } = render();
    pointer(link, 'pointerenter');
    vi.advanceTimersByTime(PROFILE_CARD_HOVER_MS);
    fixture.componentInstance.shown.set(false);
    fixture.detectChanges();
    expect(cards.closeFor).toHaveBeenCalledWith(link);
  });
});

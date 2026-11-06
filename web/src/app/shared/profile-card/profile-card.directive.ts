import { DestroyRef, Directive, ElementRef, inject, input } from '@angular/core';
import { PROFILE_CARD_FOCUS_MS, PROFILE_CARD_HOVER_MS, ProfileCardService } from './profile-card.service';

/**
 * Opens a person's profile card on a link to them (a comment's author, an @mention in a comment or an article):
 * `<a [routerLink]="'/@' + username" [rdProfileCard]="username">`. After about 450 ms of the pointer resting on the link,
 * or 600 ms after keyboard focus that shows (`:focus-visible`), on devices that hover only: on touch a tap opens the
 * profile as before. The link stays a plain link (no `aria-haspopup`). One card at a time ({@link ProfileCardService}).
 */
@Directive({
  selector: '[rdProfileCard]',
  host: {
    '(pointerenter)': 'pointerEnter($event)',
    '(pointerleave)': 'leave()',
    '(pointerdown)': 'cancel()',
    '(focus)': 'focus()',
    '(blur)': 'leave()',
  },
})
export class ProfileCardTrigger {
  private readonly cards = inject(ProfileCardService);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  /** The person's username (with or without the `@`); nothing opens without one. */
  readonly username = input<string | null | undefined>(null, { alias: 'rdProfileCard' });

  private timer: ReturnType<typeof setTimeout> | undefined;

  constructor() {
    inject(DestroyRef).onDestroy(() => {
      this.cancel();
      this.cards.closeFor(this.host.nativeElement);
    });
  }

  protected pointerEnter(event: PointerEvent): void {
    if (event.pointerType === 'touch' || !this.cards.canHover()) return;
    this.schedule(PROFILE_CARD_HOVER_MS);
  }

  protected focus(): void {
    if (this.cards.canHover() && focusVisible(this.host.nativeElement)) this.schedule(PROFILE_CARD_FOCUS_MS);
  }

  /** The pointer or focus left the link: no card yet, or its card closes after the grace. */
  protected leave(): void {
    this.cancel();
    this.cards.leave(this.host.nativeElement);
  }

  /** A press opens the profile: no card on the way. */
  protected cancel(): void {
    clearTimeout(this.timer);
    this.timer = undefined;
  }

  private schedule(delay: number): void {
    const el = this.host.nativeElement;
    if (this.cards.isOpenFor(el)) {
      this.cards.stay();
      return;
    }
    const username = this.username()?.replace(/^@/, '').trim();
    if (!username) return;
    this.cancel();
    this.timer = setTimeout(() => {
      this.timer = undefined;
      if (el.isConnected) this.cards.open(el, username);
    }, delay);
  }
}

/** Focus the browser shows (from the keyboard), not the focus a click gives. */
function focusVisible(el: Element): boolean {
  try {
    return el.matches(':focus-visible');
  } catch {
    return false;
  }
}

import { DOCUMENT, DestroyRef, Injectable, Injector, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { NavigationStart, Router } from '@angular/router';
import { OverlayRef, createFlexibleConnectedPositionStrategy, createOverlayRef, createRepositionScrollStrategy } from '@angular/cdk/overlay';
import { ComponentPortal } from '@angular/cdk/portal';
import { LanguageService } from '../../core/i18n/language.service';
import { ProfileCard } from './profile-card';

/** Resting the pointer on a name or mention this long opens its card. */
export const PROFILE_CARD_HOVER_MS = 450;
/** Keyboard focus (`:focus-visible`) on a name or mention this long opens its card. */
export const PROFILE_CARD_FOCUS_MS = 600;
/** Moving between the link and its card within this time keeps the card open. */
export const PROFILE_CARD_GRACE_MS = 250;
/** Only devices that hover get the card; on touch a tap opens the profile as before. */
export const HOVER_QUERY = '(hover: hover) and (pointer: fine)';
/** The card's width, and the room kept from the window's edges. */
const CARD_WIDTH = 320;
const OFFSET = 8;

/**
 * The one profile card on screen (web, contract "Profile card on hover"): opening a card closes the other. It sits
 * below its link, aligned to the start (in the UI's direction), 8 px away, flips above when there's no room, and
 * follows the link when the page scrolls (CDK overlay). It stays open while the pointer is over the link or the card
 * (a short grace covers moving between them), and closes on Escape and on navigation. It never takes the focus.
 * Nothing happens on the server.
 */
@Injectable({ providedIn: 'root' })
export class ProfileCardService {
  private readonly injector = inject(Injector);
  private readonly document = inject(DOCUMENT);
  private readonly language = inject(LanguageService);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  private overlay: OverlayRef | null = null;
  private origin: Element | null = null;
  private closeTimer: ReturnType<typeof setTimeout> | undefined;
  /** The pointer is over the card (the link losing focus meanwhile doesn't close it). */
  private overCard = false;

  constructor() {
    const navigation = inject(Router).events.subscribe((event) => {
      if (event instanceof NavigationStart) this.close();
    });
    inject(DestroyRef).onDestroy(() => {
      navigation.unsubscribe();
      this.close();
    });
  }

  /** Whether this device hovers with a fine pointer (mouse, pen, trackpad). */
  canHover(): boolean {
    return this.isBrowser && !!this.document.defaultView?.matchMedia?.(HOVER_QUERY).matches;
  }

  /** The card is open on this link. */
  isOpenFor(origin: Element): boolean {
    return !!this.overlay && this.origin === origin;
  }

  /** Opens `username`'s card at `origin`, closing any other card. */
  open(origin: HTMLElement, username: string): void {
    if (!this.isBrowser) return;
    this.stay();
    if (this.isOpenFor(origin)) return;
    this.close();
    const overlay = createOverlayRef(this.injector, {
      direction: this.language.dir(),
      width: CARD_WIDTH,
      maxWidth: `calc(100vw - ${2 * OFFSET}px)`,
      panelClass: 'rd-profile-card-pane',
      disposeOnNavigation: true,
      scrollStrategy: createRepositionScrollStrategy(this.injector),
      positionStrategy: createFlexibleConnectedPositionStrategy(this.injector, origin)
        .withPositions([
          { originX: 'start', originY: 'bottom', overlayX: 'start', overlayY: 'top', offsetY: OFFSET },
          { originX: 'start', originY: 'top', overlayX: 'start', overlayY: 'bottom', offsetY: -OFFSET },
        ])
        .withViewportMargin(OFFSET)
        .withPush(true),
    });
    const card = overlay.attach(new ComponentPortal(ProfileCard, null, this.injector));
    card.setInput('username', username);
    overlay.overlayElement.addEventListener('pointerenter', this.enterCard);
    overlay.overlayElement.addEventListener('pointerleave', this.leaveCard);
    this.document.addEventListener('keydown', this.keydown, true);
    this.overlay = overlay;
    this.origin = origin;
  }

  /** The pointer (or focus) is back on the link or the card: it stays open. */
  readonly stay = (): void => {
    clearTimeout(this.closeTimer);
    this.closeTimer = undefined;
  };

  /** The pointer or focus left `origin`: its card closes after the grace, unless the pointer is on the card. */
  leave(origin: Element): void {
    if (this.isOpenFor(origin) && !this.overCard) this.scheduleClose();
  }

  /** Closes the card on `origin` at once (the link left the page). */
  closeFor(origin: Element): void {
    if (this.isOpenFor(origin)) this.close();
  }

  close(): void {
    this.stay();
    const overlay = this.overlay;
    if (!overlay) return;
    this.overlay = null;
    this.origin = null;
    this.overCard = false;
    overlay.overlayElement.removeEventListener('pointerenter', this.enterCard);
    overlay.overlayElement.removeEventListener('pointerleave', this.leaveCard);
    this.document.removeEventListener('keydown', this.keydown, true);
    overlay.dispose();
  }

  private readonly enterCard = (): void => {
    this.overCard = true;
    this.stay();
  };

  private readonly leaveCard = (): void => {
    this.overCard = false;
    this.scheduleClose();
  };

  private readonly keydown = (event: KeyboardEvent): void => {
    if (event.key === 'Escape') this.close();
  };

  private scheduleClose(): void {
    this.stay();
    this.closeTimer = setTimeout(() => this.close(), PROFILE_CARD_GRACE_MS);
  }
}

/**
 * What the lazily loaded "Me" menu (layout/me-menu.ts) needs from the top bar that opened it. A file of its own, so the
 * menu's chunk doesn't import the top bar.
 */
export abstract class MeMenuHost {
  /** Closes the menu; `refocus` gives the focus back to the button that opened it (Escape, Tab, a picked item). */
  abstract closeMeMenu(refocus: boolean): void;
}

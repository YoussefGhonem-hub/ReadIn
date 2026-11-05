/** Viewport rectangle a popup opens next to (the caret, a button). */
export interface PopupAnchor {
  left: number;
  right: number;
  top: number;
  bottom: number;
}

/**
 * Fixed position for a popup of `size` under `anchor`, aligned to its start side in the page's direction and kept
 * inside the viewport; above the anchor when it doesn't fit below.
 */
export function placePopup(anchor: PopupAnchor, size: { width: number; height: number }): { left: number; top: number } {
  const viewportWidth = document.documentElement.clientWidth || window.innerWidth;
  const viewportHeight = window.innerHeight;
  const rtl = document.documentElement.dir === 'rtl';
  const start = rtl ? anchor.right - size.width : anchor.left;
  const left = Math.max(8, Math.min(start, viewportWidth - size.width - 8));
  const below = anchor.bottom + 6;
  const above = anchor.top - 6 - size.height;
  return { left, top: below + size.height > viewportHeight - 8 && above >= 8 ? above : below };
}

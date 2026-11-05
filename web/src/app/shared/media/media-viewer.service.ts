import { DOCUMENT, Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { Dialog, DialogRef } from '@angular/cdk/dialog';
import { TranslocoService } from '@jsverse/transloco';
import { LanguageService } from '../../core/i18n/language.service';
import { MediaViewer, MediaViewerData } from './media-viewer';
import { MEDIA_VIEWER_HISTORY_KEY, MediaViewerHistory } from './viewer-history';

export { MEDIA_VIEWER_HISTORY_KEY } from './viewer-history';

/**
 * Opens the full-screen media viewer. It pushes a history entry so the browser Back button (and the Android back
 * gesture) closes the viewer instead of leaving the page; closing it any other way (✕, Esc, swipe down) pops that entry
 * again. That entry has the page's own URL, and moving into or out of it is kept from the router
 * ({@link MediaViewerHistory}, `provideMediaViewerHistory()` in the app config), so the page keeps its scroll
 * position; the dialog gives the focus back to the image or page that opened it (SPEC F26).
 */
@Injectable({ providedIn: 'root' })
export class MediaViewerService {
  private readonly dialog = inject(Dialog);
  private readonly language = inject(LanguageService);
  private readonly transloco = inject(TranslocoService);
  private readonly document = inject(DOCUMENT);
  private readonly viewerHistory = inject(MediaViewerHistory);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private current: DialogRef<void, MediaViewer> | null = null;

  get isOpen(): boolean {
    return this.current !== null;
  }

  open(data: MediaViewerData): DialogRef<void, MediaViewer> | null {
    const window = this.document.defaultView;
    if (!this.isBrowser || !window || this.current) return null;

    const ref = this.dialog.open<void, MediaViewerData, MediaViewer>(MediaViewer, {
      data,
      ariaLabel: data.title || this.transloco.translate('media.viewer.label'),
      ariaModal: true,
      width: '100%',
      height: '100%',
      maxWidth: '100vw',
      maxHeight: '100dvh',
      hasBackdrop: false,
      panelClass: 'rd-viewer-pane',
      autoFocus: 'first-tabbable',
      restoreFocus: true,
      closeOnNavigation: false,
      direction: this.language.dir(),
    });
    this.current = ref;

    const history = window.history;
    const marker = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
    history.pushState({ ...(history.state ?? {}), [MEDIA_VIEWER_HISTORY_KEY]: marker }, '');
    this.viewerHistory.pushed(window.location.href);
    // Back (or any history move off the entry) closes the viewer; the entry is gone already then.
    let closedByHistory = false;
    this.viewerHistory.onLeave(() => {
      closedByHistory = true;
      ref.close();
    });

    ref.closed.subscribe(() => {
      this.viewerHistory.onLeave(null);
      this.current = null;
      // ✕, Esc or swipe down: leave the viewer's entry, so Back then leaves the page as usual.
      if (!closedByHistory && history.state?.[MEDIA_VIEWER_HISTORY_KEY] === marker) history.back();
    });
    return ref;
  }
}

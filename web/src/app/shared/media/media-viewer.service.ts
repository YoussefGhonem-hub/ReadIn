import { DOCUMENT, Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { Dialog, DialogRef } from '@angular/cdk/dialog';
import { TranslocoService } from '@jsverse/transloco';
import { LanguageService } from '../../core/i18n/language.service';
import { MediaViewer, MediaViewerData } from './media-viewer';

const HISTORY_KEY = 'rdMediaViewer';

/**
 * Opens the full-screen media viewer. It pushes a history entry so the browser Back button (and the Android back
 * gesture) closes the viewer instead of leaving the page; closing it any other way pops that entry again.
 */
@Injectable({ providedIn: 'root' })
export class MediaViewerService {
  private readonly dialog = inject(Dialog);
  private readonly language = inject(LanguageService);
  private readonly transloco = inject(TranslocoService);
  private readonly document = inject(DOCUMENT);
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
    history.pushState({ ...(history.state ?? {}), [HISTORY_KEY]: marker }, '');
    let closedByBack = false;
    const onPopState = () => {
      closedByBack = true;
      ref.close();
    };
    window.addEventListener('popstate', onPopState);

    ref.closed.subscribe(() => {
      window.removeEventListener('popstate', onPopState);
      this.current = null;
      if (!closedByBack && history.state?.[HISTORY_KEY] === marker) history.back();
    });
    return ref;
  }
}

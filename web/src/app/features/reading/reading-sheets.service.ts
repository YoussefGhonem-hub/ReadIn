import { EnvironmentInjector, Injectable, PLATFORM_ID, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { StreakMilestone } from '../../core/api/models';

/**
 * Opens the app-wide reading sheets (F08): the reading stats sheet behind the 🔥 badge and the streak milestone
 * celebration. They are loaded and attached to `<body>` on first use, so they stay out of the initial bundle and
 * outlive the page that opened them (a milestone can arrive with the reader's last report).
 */
@Injectable({ providedIn: 'root' })
export class ReadingSheetsService {
  private readonly injector = inject(EnvironmentInjector);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private mounted: Promise<void> | null = null;

  private readonly _statsOpen = signal(false);
  private readonly _milestone = signal<StreakMilestone | null>(null);
  readonly statsOpen = this._statsOpen.asReadonly();
  /** The milestone being celebrated, or null. */
  readonly milestone = this._milestone.asReadonly();

  openStats(): void {
    this._statsOpen.set(true);
    this.mount();
  }

  closeStats(): void {
    this._statsOpen.set(false);
  }

  celebrate(milestone: StreakMilestone): void {
    this._statsOpen.set(false);
    this._milestone.set(milestone);
    this.mount();
  }

  closeCelebration(): void {
    this._milestone.set(null);
  }

  private mount(): void {
    if (!this.isBrowser || this.mounted) return;
    this.mounted = import('./reading-sheets')
      .then((m) => m.mountReadingSheets(this.injector))
      .catch(() => {
        this.mounted = null; // e.g. offline: the next tap tries again
      });
  }
}

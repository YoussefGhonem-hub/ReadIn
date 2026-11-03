import {
  ApplicationRef,
  ChangeDetectionStrategy,
  Component,
  DOCUMENT,
  EnvironmentInjector,
  createComponent,
  effect,
  inject,
  untracked,
} from '@angular/core';
import { SessionStore } from '../../core/auth/session.store';
import { MilestoneCelebration } from './milestone-celebration';
import { ReadingSheetsService } from './reading-sheets.service';
import { ReadingStatsSheet } from './reading-stats-sheet';

/** The reading stats sheet and the milestone celebration, attached to `<body>` by `ReadingSheetsService`. */
@Component({
  selector: 'rd-reading-sheets',
  imports: [ReadingStatsSheet, MilestoneCelebration],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-reading-stats-sheet [open]="sheets.statsOpen()" (closed)="sheets.closeStats()" />
    <rd-milestone-celebration [milestone]="sheets.milestone()" (closed)="sheets.closeCelebration()" />
  `,
})
export class ReadingSheets {
  protected readonly sheets = inject(ReadingSheetsService);

  constructor() {
    const session = inject(SessionStore);
    // Both show the signed-in user's own data: signing out closes them.
    effect(() => {
      if (session.isAuthenticated()) return;
      untracked(() => {
        this.sheets.closeStats();
        this.sheets.closeCelebration();
      });
    });
  }
}

/** Creates the sheets once and attaches them to the app and `<body>`. */
export function mountReadingSheets(injector: EnvironmentInjector): void {
  const ref = createComponent(ReadingSheets, { environmentInjector: injector });
  injector.get(ApplicationRef).attachView(ref.hostView);
  injector.get(DOCUMENT).body.appendChild(ref.location.nativeElement);
}

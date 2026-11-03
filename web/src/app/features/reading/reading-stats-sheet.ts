import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { ReadingHeatmap } from './reading-heatmap';
import { ReadingStatsCard } from './reading-stats-card';

/** "Reading stats" behind the 🔥 badge (F08): the stats card and the heatmap, loaded fresh every time it opens. */
@Component({
  selector: 'rd-reading-stats-sheet',
  imports: [TranslocoPipe, BottomSheet, ReadingStatsCard, ReadingHeatmap],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open()" labelledBy="rd-reading-stats-title" (closed)="closed.emit()">
      @if (open()) {
        <h2 id="rd-reading-stats-title" class="m-0 mb-4 pe-10 text-xl font-semibold">{{ 'reading.stats.title' | transloco }}</h2>
        <rd-reading-stats-card />
        <rd-reading-heatmap class="mt-6" />
      }
    </rd-bottom-sheet>
  `,
})
export class ReadingStatsSheet {
  readonly open = input(false);
  readonly closed = output<void>();
}

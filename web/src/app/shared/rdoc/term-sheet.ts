import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { BottomSheet } from '../ui/bottom-sheet';
import { TermSheetService } from './rdoc-context';

/**
 * Glossary term sheet (tap a term → definition). The glossary API (`GET /glossary/{slug}`, F21) ships in Phase 3;
 * until then the sheet names the term and says the definition is coming.
 */
@Component({
  selector: 'rd-term-sheet',
  imports: [BottomSheet, TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="!!terms.openTerm()" [label]="'rdoc.term.title' | transloco" (closed)="terms.close()">
      @if (terms.openTerm(); as term) {
        <div class="flex flex-col gap-3 pe-10">
          <span class="inline-flex items-center gap-2 text-xs font-semibold text-primary">
            <svg lucideIcon="BookOpen" [size]="16" aria-hidden="true"></svg>
            {{ 'rdoc.term.title' | transloco }}
          </span>
          <h2 class="m-0 text-xl font-semibold" dir="auto">{{ term.text }}</h2>
          <p class="m-0 text-sm text-text-secondary">{{ 'rdoc.term.soon' | transloco }}</p>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class TermSheet {
  protected readonly terms = inject(TermSheetService);
}

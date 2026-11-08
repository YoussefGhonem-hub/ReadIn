import { ChangeDetectionStrategy, Component, output } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';

/**
 * «أبلغت عن هذا المحتوى، ولن يظهر لك بعد الآن» with «عرض» (F22, store requirements): what a reported article, comment
 * or repost caption collapses to for the person who reported it. "Show" opens it here only; it stays reported.
 */
@Component({
  selector: 'rd-reported-notice',
  imports: [TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-wrap items-center gap-x-2 text-sm text-text-secondary', 'data-reported-notice': '' },
  template: `
    <span class="italic">{{ 'report.hiddenForYou' | transloco }}</span>
    <button type="button" class="-my-1.5 inline-flex min-h-8 items-center rounded-md px-1 font-semibold text-primary hover:underline" (click)="show.emit()" data-reported-show>
      {{ 'report.show' | transloco }}
    </button>
  `,
})
export class ReportedNotice {
  readonly show = output<void>();
}

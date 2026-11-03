import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { BdiText } from '../../shared/directives/bdi-text';
import { TocEntry } from '../../shared/rdoc/rdoc.utils';

/** Table of contents built from h2/h3 blocks; shown for long articles (F04). */
@Component({
  selector: 'rd-article-toc',
  imports: [TranslocoPipe, BdiText, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <details class="group rd-card px-4 py-3 shadow-none" [open]="openByDefault()">
      <summary class="flex cursor-pointer list-none items-center gap-2 text-sm font-semibold">
        <svg lucideIcon="ListTree" [size]="16" class="text-primary" aria-hidden="true"></svg>
        {{ 'article.toc' | transloco }}
        <svg lucideIcon="ChevronDown" [size]="16" class="ms-auto transition-transform group-open:rotate-180" aria-hidden="true"></svg>
      </summary>
      <nav [attr.aria-label]="'article.toc' | transloco" class="mt-3">
        <ol class="m-0 flex list-none flex-col gap-2 p-0 text-sm">
          @for (entry of entries(); track entry.id) {
            <li [class.ps-4]="entry.level === 3">
              <a [href]="'#' + entry.anchor" class="text-text-secondary no-underline hover:text-primary" dir="auto"
                ><rd-bdi-text [text]="entry.text"
              /></a>
            </li>
          }
        </ol>
      </nav>
    </details>
  `,
})
export class ArticleToc {
  readonly entries = input.required<TocEntry[]>();
  readonly openByDefault = input(false);
}

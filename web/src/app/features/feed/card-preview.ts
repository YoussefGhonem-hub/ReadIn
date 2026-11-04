import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleCardDto, ArticlePreviewDto } from '../../core/api/models';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { RDocRenderer } from '../../shared/rdoc/rdoc-renderer';
import { articleLink } from '../../shared/ui/article-link';
import { LinesSkeleton } from '../../shared/ui/skeletons';

export type PreviewStatus = 'loading' | 'loaded' | 'error';

/**
 * A post card's text once "Read more" is pressed (F34), in its own lazy chunk with the reader's RDoc renderer: the
 * first blocks of the article as the reader shows them (formatting, code, tables, images, glossary terms, BiDi;
 * embeds as a link), then "Read the full article" when there is more. While the preview loads, the excerpt stays in
 * place, uncut, with a few skeleton lines under it; a failure keeps it too, with a retry.
 */
@Component({
  selector: 'rd-card-preview',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, RDocRenderer, LinesSkeleton],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', '[attr.data-preview-status]': 'status()' },
  template: `
    @switch (status()) {
      @case ('loaded') {
        @if (preview(); as p) {
          <rd-rdoc
            class="rd-card-rdoc"
            [doc]="p.content"
            [articleId]="article().id"
            [embedsAsLinks]="true"
            [style.--rd-article-size]="'16px'"
            style="line-height: 1.7"
            data-card-preview
          />
          @if (!p.isComplete) {
            <a
              [routerLink]="link()"
              class="mt-3 inline-flex min-h-11 items-center gap-1 font-semibold text-primary no-underline hover:underline"
              data-card-read-full
            >
              {{ 'feedCard.readFull' | transloco }}
              <svg lucideIcon="ArrowLeft" [size]="16" class="ltr:rotate-180" aria-hidden="true"></svg>
            </a>
          }
        }
      }
      @case ('error') {
        @if (article().excerpt; as excerpt) {
          <p class="rd-card-text m-0" [attr.dir]="excerptDir()" [attr.lang]="article().language"><rd-bdi-text [text]="excerpt" /></p>
        }
        <div class="mt-3 flex flex-wrap items-center gap-3 rounded-md bg-surface-variant px-3 py-2 text-sm" role="alert" data-card-preview-error>
          <span class="flex-1 text-text-secondary">{{ 'feedCard.previewError' | transloco }}</span>
          <button type="button" class="rd-btn rd-btn-outline min-h-11 px-3 text-sm" (click)="retry.emit()">{{ 'common.retry' | transloco }}</button>
        </div>
      }
      @default {
        @if (article().excerpt; as excerpt) {
          <p class="rd-card-text m-0" [attr.dir]="excerptDir()" [attr.lang]="article().language"><rd-bdi-text [text]="excerpt" /></p>
        }
        <div class="mt-3" aria-busy="true" data-card-preview-loading>
          <rd-lines-skeleton [count]="3" />
          <span class="sr-only">{{ 'common.loading' | transloco }}</span>
        </div>
      }
    }
  `,
})
export class CardPreview {
  readonly article = input.required<ArticleCardDto>();
  readonly preview = input<ArticlePreviewDto | null>(null);
  readonly status = input.required<PreviewStatus>();
  readonly retry = output<void>();

  protected readonly link = computed(() => articleLink(this.article()));
  protected readonly excerptDir = computed(() => detectDir(this.article().excerpt) ?? 'auto');
}

import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ContinueReadingDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { articleLink } from '../../shared/ui/article-link';
import { ProgressBar } from '../../shared/ui/progress-bar';

/**
 * Home's "Continue reading" (F03): the last unfinished article, in the version you were reading. The reader resumes
 * from your last position itself.
 */
@Component({
  selector: 'rd-continue-reading-card',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, ProgressBar],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    @let a = item().article;
    <a [routerLink]="link()" class="rd-card flex items-center gap-3 p-3 text-inherit no-underline shadow-none transition-colors hover:border-primary" data-continue-reading>
      <span class="h-14 w-14 shrink-0 overflow-hidden rounded-md bg-primary-container" aria-hidden="true">
        @if (a.coverUrl) {
          <img [src]="a.coverUrl" alt="" class="h-full w-full object-cover" />
        } @else {
          <span class="grid h-full w-full place-items-center font-mono text-xs text-on-primary-container" dir="ltr">&lt;/&gt;</span>
        }
      </span>
      <span class="min-w-0 flex-1">
        <span class="flex flex-wrap items-center gap-2 text-xs">
          <span class="font-semibold text-primary">{{ 'home.continueReading.title' | transloco }}</span>
          <span class="rd-tag rd-tag-neutral"><rd-bdi-text [text]="field()" /></span>
        </span>
        <!-- A whole-pixel line height keeps the card's height an integer, so the feed below never sits on a sub-pixel. -->
        <span class="mt-1 block truncate text-[15px] font-semibold leading-5" [attr.dir]="titleDir()" [attr.lang]="item().language" data-continue-title
          ><rd-bdi-text [text]="a.title"
        /></span>
        <rd-progress-bar class="mt-2" [value]="item().percent" [label]="'home.continueReading.percent' | transloco: { percent: item().percent }" />
      </span>
      <svg lucideIcon="ChevronRight" [size]="18" class="rd-flip-rtl shrink-0 text-text-secondary" aria-hidden="true"></svg>
    </a>
  `,
})
export class ContinueReadingCard {
  private readonly lang = inject(LanguageService).lang;
  readonly item = input.required<ContinueReadingDto>();

  protected readonly link = computed(() => articleLink({ slug: this.item().article.slug, language: this.item().language }));
  protected readonly titleDir = computed(() => detectDir(this.item().article.title) ?? 'auto');
  protected readonly field = computed(() => (this.lang() === 'ar' ? this.item().article.field.nameAr : this.item().article.field.nameEn));
}

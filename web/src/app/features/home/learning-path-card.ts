import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { PathCardDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { articleLink } from '../../shared/ui/article-link';
import { ProgressBar } from '../../shared/ui/progress-bar';

/**
 * Home's learning path card (F03, F09). Your path in progress: its title and field, "read/total" with a bar, and the
 * next article as the main action (the rest of the card opens the path). Without one, or as a guest, a slim row that
 * leads to `/paths`.
 */
@Component({
  selector: 'rd-learning-path-card',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, ProgressBar],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  styles: `
    /* The title link covers the card; the next-article button sits above it. */
    .stretched::after {
      content: '';
      position: absolute;
      inset: 0;
    }
  `,
  template: `
    @if (loading()) {
      <!-- The size of the card: the title row, the bar and the button. -->
      <div class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-hidden="true" data-home-path-loading>
        <div class="flex items-center gap-3">
          <div class="rd-skeleton h-10 w-10 shrink-0 rounded-full"></div>
          <div class="flex flex-1 flex-col gap-2">
            <div class="rd-skeleton h-3 w-20"></div>
            <div class="rd-skeleton h-4 w-2/3"></div>
          </div>
        </div>
        <div class="rd-skeleton mt-3 h-1.5"></div>
        <div class="rd-skeleton mt-3 h-11"></div>
      </div>
    } @else if (path(); as p) {
      <section class="rd-card relative p-4 shadow-none transition-colors hover:bg-surface-variant max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-labelledby="home-path-title" data-home-path>
        <div class="flex items-center gap-3">
          <span class="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-primary-container text-on-primary-container" aria-hidden="true">
            <svg lucideIcon="Route" [size]="20"></svg>
          </span>
          <div class="min-w-0 flex-1">
            <p class="m-0 flex flex-wrap items-center gap-2 text-xs">
              <span class="font-semibold text-primary">{{ 'home.path.label' | transloco }}</span>
              <span class="rd-tag rd-tag-neutral"><rd-bdi-text [text]="field()" /></span>
            </p>
            <h2 id="home-path-title" class="m-0 mt-1 truncate text-base font-semibold" [attr.dir]="titleDir()">
              <a [routerLink]="['/paths', p.slug]" class="stretched text-inherit no-underline" data-home-path-link><rd-bdi-text [text]="p.title" /></a>
            </h2>
          </div>
          @if (p.progress; as progress) {
            <span class="shrink-0 text-sm font-semibold" dir="ltr" aria-hidden="true" data-home-path-count>{{
              'paths.progress' | transloco: { read: progress.readCount, total: progress.total }
            }}</span>
          }
        </div>
        @if (p.progress; as progress) {
          <rd-progress-bar class="mt-3" [value]="progress.percent" [label]="'paths.progressLabel' | transloco: { read: progress.readCount, total: progress.total }" />
          @if (progress.next; as next) {
            <a class="rd-btn rd-btn-primary relative z-10 mt-3 w-full" [routerLink]="nextLink()" data-home-path-next>
              <span class="truncate">{{ 'home.path.next' | transloco }} <rd-bdi-text [text]="next.title" /></span>
              <svg lucideIcon="ArrowLeft" [size]="18" class="shrink-0 ltr:rotate-180" aria-hidden="true"></svg>
            </a>
          }
        }
      </section>
    } @else {
      <a routerLink="/paths" class="rd-card flex h-14 items-center gap-3 px-3 text-inherit no-underline shadow-none transition-colors hover:bg-surface-variant max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 max-sm:px-4" data-home-path-prompt>
        <span class="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-primary-container text-on-primary-container" aria-hidden="true">
          <svg lucideIcon="Route" [size]="18"></svg>
        </span>
        <span class="flex-1 text-sm font-semibold">{{ 'home.path.prompt' | transloco }}</span>
        <svg lucideIcon="ChevronRight" [size]="18" class="rd-flip-rtl shrink-0 text-text-secondary" aria-hidden="true"></svg>
      </a>
    }
  `,
})
export class LearningPathCard {
  private readonly lang = inject(LanguageService).lang;
  /** Your path in progress; null shows the prompt row. */
  readonly path = input<PathCardDto | null>(null);
  readonly loading = input(false);

  protected readonly field = computed(() => {
    const p = this.path();
    return p ? (this.lang() === 'ar' ? p.field.nameAr : p.field.nameEn) : '';
  });
  protected readonly titleDir = computed(() => detectDir(this.path()?.title) ?? 'auto');
  protected readonly nextLink = computed(() => {
    const next = this.path()?.progress?.next;
    return next ? articleLink(next) : null;
  });
}

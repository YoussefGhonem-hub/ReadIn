import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleCardDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { LocalizedDatePipe, ReadingTimePipe } from '../../shared/pipes/format.pipes';
import { articleLink } from '../../shared/ui/article-link';
import { Avatar } from '../../shared/ui/avatar';

/** "مقال النهارده" hero card (F03/F07); its author row opens the writer's profile (F14). */
@Component({
  selector: 'rd-today-hero',
  imports: [RouterLink, TranslocoPipe, BdiText, Avatar, ReadingTimePipe, LocalizedDatePipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'rd-card block overflow-hidden' },
  template: `
    <a [routerLink]="link()" class="block text-inherit no-underline">
      <div class="relative h-40 overflow-hidden bg-primary-container">
        @if (article().coverUrl) {
          <img [src]="article().coverUrl" alt="" class="h-full w-full object-cover" />
        } @else {
          <div class="absolute -top-20 start-10 h-48 w-48 rounded-full border border-primary/25" aria-hidden="true"></div>
          <div class="absolute top-6 start-24 h-28 w-16 rotate-[28deg] rounded-[6px_28px_4px_25px] bg-accent/80" aria-hidden="true"></div>
        }
        <span class="absolute end-4 top-4 inline-flex items-center gap-1 rounded-sm bg-surface/90 px-2 py-1 text-xs font-bold text-primary">
          {{ 'home.todayPick' | transloco }}
          <svg lucideIcon="Sparkles" [size]="12" aria-hidden="true"></svg>
        </span>
      </div>
      <div class="px-4 pt-4">
        <div class="mb-2 flex flex-wrap items-center gap-2 text-xs">
          <span class="rd-tag"><rd-bdi-text [text]="fieldName()" /></span>
          <span class="font-semibold text-primary">{{ article().readingTimeMinutes | rdReadingTime: lang() }}</span>
        </div>
        <h2 class="m-0 text-lg font-semibold leading-relaxed" [attr.dir]="titleDir()"><rd-bdi-text [text]="article().title" /></h2>
      </div>
    </a>
    <!-- Outside the article link: the author opens their profile (F14). -->
    <div class="flex items-center justify-between gap-2 px-4 pb-2 text-xs text-text-secondary">
      <a
        [routerLink]="'/@' + article().author.username"
        class="inline-flex min-h-11 items-center gap-2 font-semibold text-text-primary no-underline hover:underline"
        data-hero-author
      >
        <rd-avatar [name]="article().author.displayName" [src]="article().author.avatarUrl" [size]="26" />
        {{ article().author.displayName }}
        @if (article().author.isVerified) {
          <svg lucideIcon="BadgeCheck" [size]="14" class="text-primary" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
        }
      </a>
      <span>{{ article().publishedAt | rdDate: lang() }}</span>
    </div>
  `,
})
export class TodayHero {
  protected readonly lang = inject(LanguageService).lang;
  readonly article = input.required<ArticleCardDto>();
  protected readonly link = computed(() => articleLink(this.article()));
  protected readonly titleDir = computed(() => detectDir(this.article().title) ?? 'auto');
  protected readonly fieldName = computed(() => (this.lang() === 'ar' ? this.article().field.nameAr : this.article().field.nameEn));
}

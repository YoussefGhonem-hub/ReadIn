import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleCardDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { ToastService } from './toast/toast.service';
import { BdiText } from '../directives/bdi-text';
import { detectDir } from '../directives/bidi';
import { CompactNumberPipe, ReadingTimePipe } from '../pipes/format.pipes';
import { articleLink } from './article-link';

/** Feed row (F03): thumbnail, title, author, reading time, counts, save. */
@Component({
  selector: 'rd-article-card',
  imports: [RouterLink, TranslocoPipe, BdiText, ReadingTimePipe, CompactNumberPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'relative flex gap-3 border-t border-border py-4 first:border-t-0' },
  template: `
    <a [routerLink]="link()" class="absolute inset-0 z-0" [attr.aria-label]="article().title"></a>
    <div class="h-[72px] w-[72px] shrink-0 overflow-hidden rounded-md bg-primary-container" aria-hidden="true">
      @if (article().coverUrl) {
        <img [src]="article().coverUrl" alt="" class="h-full w-full object-cover" loading="lazy" />
      } @else {
        <div class="grid h-full w-full place-items-center font-mono text-sm text-on-primary-container" dir="ltr">&lt;/&gt;</div>
      }
    </div>
    <div class="min-w-0 flex-1">
      <div class="mb-1 flex flex-wrap items-center gap-1.5 text-xs">
        <span class="rd-tag"><rd-bdi-text [text]="fieldName()" /></span>
        @if (article().isReviewed) {
          <span class="rd-tag rd-tag-neutral">✓ {{ 'article.reviewed' | transloco }}</span>
        }
      </div>
      <h3 class="m-0 line-clamp-2 text-[15px] font-semibold leading-snug" [attr.dir]="titleDir()">
        <rd-bdi-text [text]="article().title" />
      </h3>
      <div class="mt-1.5 flex flex-wrap items-center gap-x-2 text-xs text-text-secondary">
        <span class="inline-flex items-center gap-1 text-text-primary">
          {{ article().author.displayName }}
          @if (article().author.isVerified) {
            <svg lucideIcon="BadgeCheck" [size]="14" class="text-primary" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
          }
        </span>
        <span aria-hidden="true">·</span>
        <span>{{ article().readingTimeMinutes | rdReadingTime: lang() }}</span>
      </div>
      <div class="mt-1.5 flex gap-3 text-xs text-text-secondary">
        <span class="inline-flex items-center gap-1"
          ><svg lucideIcon="Lightbulb" [size]="13" aria-hidden="true"></svg>{{ article().reactionCount | rdCompactNumber: lang() }}</span
        >
        <span class="inline-flex items-center gap-1"
          ><svg lucideIcon="MessageCircle" [size]="13" aria-hidden="true"></svg>{{ article().commentCount | rdCompactNumber: lang() }}</span
        >
      </div>
    </div>
    <button
      type="button"
      class="relative z-10 self-start p-1 text-text-secondary hover:text-primary"
      [attr.aria-label]="'article.save' | transloco"
      (click)="save()"
    >
      <svg lucideIcon="Bookmark" [size]="18"></svg>
    </button>
  `,
})
export class ArticleCard {
  private readonly language = inject(LanguageService);
  private readonly prompt = inject(AuthPromptService);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);

  readonly article = input.required<ArticleCardDto>();

  protected readonly lang = this.language.lang;
  protected readonly link = computed(() => articleLink(this.article()));
  protected readonly titleDir = computed(() => detectDir(this.article().title) ?? 'auto');
  protected readonly fieldName = computed(() => (this.lang() === 'ar' ? this.article().field.nameAr : this.article().field.nameEn));

  /** Saving ships with F13; guests get the sign-in prompt now. */
  protected save(): void {
    if (this.prompt.requireAuth()) this.toasts.info(this.transloco.translate('common.comingSoonShort'));
  }
}

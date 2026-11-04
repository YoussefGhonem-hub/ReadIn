import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleCardDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { injectInViewport } from '../../core/realtime/live-signals';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { bindLiveCounters } from '../../core/social/live-article';
import { BdiText } from '../directives/bdi-text';
import { detectDir } from '../directives/bidi';
import { ArticleAttachments } from '../media/article-attachments';
import { CompactNumberPipe, ReadingTimePipe } from '../pipes/format.pipes';
import { articleLink } from './article-link';

/**
 * Feed row (F03): thumbnail, title, author (opens the profile, F14), reading time, live counts, save (F13); post
 * attachments (F26) full width below. Content marked `rdCardFooter` goes under the card, above its link (e.g. the
 * Saved page's actions).
 */
@Component({
  selector: 'rd-article-card',
  imports: [RouterLink, TranslocoPipe, BdiText, ReadingTimePipe, CompactNumberPipe, LucideDynamicIcon, ArticleAttachments],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'relative block border-t border-border py-4 first:border-t-0' },
  styles: `
    .author::after {
      content: '';
      position: absolute;
      inset: -14px 0;
    }
  `,
  template: `
    <a [routerLink]="link()" class="absolute inset-0 z-0" [attr.aria-label]="article().title"></a>
    <div class="flex gap-3">
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
        </div>
        <h3 class="m-0 line-clamp-2 text-[15px] font-semibold leading-snug" [attr.dir]="titleDir()">
          <rd-bdi-text [text]="article().title" />
        </h3>
        <div class="mt-1.5 flex flex-wrap items-center gap-x-2 text-xs text-text-secondary">
          @if (article().author; as author) {
            <!-- Above the card link; its ::after box makes the tap target 44 px tall without moving anything. -->
            <a [routerLink]="'/@' + author.username" class="author relative z-10 inline-flex items-center gap-1 text-text-primary no-underline hover:underline" data-card-author>
              {{ author.displayName }}
              @if (author.isVerified) {
                <svg lucideIcon="BadgeCheck" [size]="14" class="text-primary" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
              }
            </a>
          } @else {
            <!-- The author deleted their account (SPEC §9.6): no profile link. -->
            <span data-deleted-author>{{ 'common.deletedUser' | transloco }}</span>
          }
          <span aria-hidden="true">·</span>
          <span>{{ article().readingTimeMinutes | rdReadingTime: lang() }}</span>
        </div>
        <div class="mt-1.5 flex gap-3 text-xs text-text-secondary">
          <span class="inline-flex items-center gap-1"
            ><svg lucideIcon="Lightbulb" [size]="13" aria-hidden="true"></svg>{{ reactionCount() | rdCompactNumber: lang() }}</span
          >
          <span class="inline-flex items-center gap-1"
            ><svg lucideIcon="MessageCircle" [size]="13" aria-hidden="true"></svg>{{ commentCount() | rdCompactNumber: lang() }}</span
          >
        </div>
      </div>
      <!-- 44px target, laid out like the 26px icon button it replaces (negative margin). -->
      <button
        type="button"
        class="relative z-10 -m-[9px] self-start p-[13px] hover:text-primary"
        [class]="state().isSaved ? 'text-primary' : 'text-text-secondary'"
        data-card-save
        [attr.aria-pressed]="state().isSaved"
        [attr.aria-label]="'article.save' | transloco"
        (click)="save()"
      >
        <svg lucideIcon="Bookmark" [size]="18" [class.fill-current]="state().isSaved" aria-hidden="true"></svg>
      </button>
    </div>
    @if (article().attachments; as attachments) {
      <!-- Above the card link so taps open the carousel / viewer instead of the article. -->
      <rd-article-attachments class="relative z-10 mt-3" [attachments]="attachments" [article]="article()" [priority]="priorityMedia()" />
    }
    <ng-content select="[rdCardFooter]" />
  `,
})
export class ArticleCard {
  private readonly language = inject(LanguageService);
  private readonly prompt = inject(AuthPromptService);
  private readonly social = inject(ArticleSocialStore);

  readonly article = input.required<ArticleCardDto>();
  /** Loads the first attachment image eagerly (the first card with media in the feed). */
  readonly priorityMedia = input(false);

  protected readonly lang = this.language.lang;
  protected readonly link = computed(() => articleLink(this.article()));
  protected readonly titleDir = computed(() => detectDir(this.article().title) ?? 'auto');
  protected readonly fieldName = computed(() => (this.lang() === 'ar' ? this.article().field.nameAr : this.article().field.nameEn));

  /** The feed values with your actions and the live counters on top. */
  protected readonly state = computed(() => this.social.state(this.article()));
  protected readonly reactionCount = computed(() => this.state().reactionCount);
  protected readonly commentCount = computed(() => this.state().commentCount);

  constructor() {
    // Live counters only while the card is on screen (F27).
    const inView = injectInViewport();
    bindLiveCounters(() => this.article(), inView);
  }

  /** Bookmark toggle (F13); guests get the sign-in prompt. */
  protected save(): void {
    if (this.prompt.requireAuth()) void this.social.toggleSave(this.article());
  }
}

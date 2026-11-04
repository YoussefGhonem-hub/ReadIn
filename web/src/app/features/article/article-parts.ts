import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleLanguage, ArticleSourceDto, UiLanguage } from '../../core/api/models';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { ReadingTimePipe } from '../../shared/pipes/format.pipes';
import { safeHttpUrl } from '../../shared/rdoc/rdoc.utils';

/**
 * Parts of the article page shared by the reader (F04) and the editor's preview (F05), so the preview looks exactly
 * like the published article.
 */

/** The cover image above the headline (absolute URL of the cover upload). */
@Component({
  selector: 'rd-article-cover',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mb-5 block' },
  template: `
    <figure class="m-0 overflow-hidden rounded-card bg-surface-variant" style="aspect-ratio: 1200 / 630" data-article-cover>
      <img [src]="url()" alt="" class="rd-photo h-full w-full object-cover" decoding="async" />
    </figure>
  `,
})
export class ArticleCover {
  readonly url = input.required<string>();
}

/** Field, topic and reading time, then the title (H1) and the subtitle. */
@Component({
  selector: 'rd-article-headline',
  imports: [BdiText, ReadingTimePipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <div class="mb-2 flex flex-wrap items-center gap-2 text-xs">
      @if (field(); as field) {
        <span class="rd-tag"><rd-bdi-text [text]="field" /></span>
      }
      @if (topic(); as topic) {
        <span class="text-text-secondary"><rd-bdi-text [text]="topic" /></span>
      }
      @if (minutes() !== null) {
        <span class="text-text-secondary">· {{ minutes() | rdReadingTime: uiLang() }}</span>
      }
    </div>

    <h1 class="m-0 text-[28px] font-semibold leading-snug tracking-tight lg:text-[32px]" [attr.dir]="titleDir()" [attr.lang]="language()">
      <rd-bdi-text [text]="title()" />
    </h1>
    @if (subtitle(); as subtitle) {
      <p class="mt-2 text-lg text-text-secondary" [attr.dir]="subtitleDir()" [attr.lang]="language()"><rd-bdi-text [text]="subtitle" /></p>
    }
  `,
})
export class ArticleHeadline {
  /** Field name in the UI language. */
  readonly field = input<string | null>(null);
  readonly topic = input<string | null>(null);
  readonly minutes = input<number | null>(null);
  readonly title = input.required<string>();
  readonly subtitle = input<string | null>(null);
  readonly language = input.required<ArticleLanguage>();
  readonly uiLang = input.required<UiLanguage>();

  protected readonly titleDir = computed(() => detectDir(this.title()) ?? 'auto');
  protected readonly subtitleDir = computed(() => detectDir(this.subtitle()) ?? 'auto');
}

/** Trust row (SPEC §20): verified writer, version badge, AI-assisted label. */
@Component({
  selector: 'rd-article-trust-row',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <ul class="my-5 flex list-none flex-wrap items-center gap-x-3 gap-y-2 border-y border-border p-0 py-3 text-xs text-text-secondary" data-trust-row>
      @if (verified()) {
        <li class="inline-flex items-center gap-1 font-semibold text-success">
          <svg lucideIcon="BadgeCheck" [size]="14" aria-hidden="true"></svg>{{ 'article.verifiedWriter' | transloco }}
        </li>
      }
      @if (versionBadge(); as badge) {
        <li><span class="rd-tag rd-tag-neutral" dir="ltr">{{ badge }}</span></li>
      }
      @if (aiAssisted()) {
        <li class="inline-flex items-center gap-1"><svg lucideIcon="Bot" [size]="14" aria-hidden="true"></svg>{{ 'article.aiAssisted' | transloco }}</li>
      }
    </ul>
  `,
})
export class ArticleTrustRow {
  readonly verified = input(false);
  readonly versionBadge = input<string | null>(null);
  readonly aiAssisted = input(false);
}

/**
 * Health disclaimer (SPEC F04, §20) for articles in a sensitive field (Medicine, Public Health): below the trust row,
 * above the TL;DR and the content. Information, not a warning; in the UI language.
 */
@Component({
  selector: 'rd-article-health-notice',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mb-6 block' },
  template: `
    <aside class="flex items-start gap-3 rounded-card bg-callout-info p-4 text-sm" role="note" data-health-disclaimer>
      <svg lucideIcon="Stethoscope" [size]="20" class="shrink-0 text-callout-info-accent" aria-hidden="true"></svg>
      <p class="m-0 leading-relaxed">{{ 'article.healthDisclaimer' | transloco }}</p>
    </aside>
  `,
})
export class ArticleHealthNotice {}

/** Sources (mandatory for technical content, SPEC §20): http(s) links only. */
@Component({
  selector: 'rd-article-sources',
  imports: [TranslocoPipe, LucideDynamicIcon, BdiText],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <section class="mt-10" [attr.aria-labelledby]="headingId()">
      <h2 [id]="headingId()" class="mb-3 text-lg font-semibold">📚 {{ 'article.sources' | transloco }}</h2>
      @if (links().length) {
        <ol class="m-0 flex flex-col gap-2 ps-5 text-sm">
          @for (source of links(); track $index) {
            <li>
              <a [href]="source.url" target="_blank" rel="nofollow noopener noreferrer" class="inline-flex items-center gap-1 text-link underline underline-offset-2" dir="auto">
                <rd-bdi-text [text]="source.title" />
                <svg lucideIcon="ExternalLink" [size]="13" class="rd-flip-rtl shrink-0" aria-hidden="true"></svg>
              </a>
            </li>
          }
        </ol>
      } @else {
        <p class="text-sm text-text-secondary">{{ 'article.noSources' | transloco }}</p>
      }
    </section>
  `,
})
export class ArticleSources {
  readonly sources = input.required<readonly ArticleSourceDto[]>();
  readonly headingId = input('sources-title');

  protected readonly links = computed(() =>
    this.sources().flatMap((s) => {
      const url = safeHttpUrl(s.url);
      return url ? [{ title: s.title || url, url }] : [];
    }),
  );
}

import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { ArticleAttachmentsDto, ArticleDraftDocument, ArticleLanguage, FieldDto, MediaAssetDto, TopicDto, UiLanguage } from '../../core/api/models';
import { BdiText } from '../../shared/directives/bdi-text';
import { ArticleAttachments } from '../../shared/media/article-attachments';
import { LocalizedDatePipe } from '../../shared/pipes/format.pipes';
import { RDocRenderer } from '../../shared/rdoc/rdoc-renderer';
import { tableOfContents } from '../../shared/rdoc/rdoc.utils';
import { Avatar } from '../../shared/ui/avatar';
import { ArticleCover, ArticleHeadline, ArticleHealthNotice, ArticleSources, ArticleTrustRow } from '../article/article-parts';
import { ArticleToc } from '../article/article-toc';
import { VerifiedBadge } from '../../shared/ui/verified-badge';

export interface PreviewAuthor {
  displayName: string;
  username: string;
  avatarUrl: string | null;
  isVerified: boolean;
}

/** Same rule as the reader (F04): the table of contents appears from this many headings. */
const TOC_MIN_HEADINGS = 3;

/**
 * The article attachments as readers get them (`ArticleAttachmentsDto`), built from the draft's attachments and the
 * assets of `ArticleEditDto.media`. Attachments whose asset isn't ready are left out (they block publishing anyway).
 */
export function previewAttachments(document: ArticleDraftDocument, media: readonly MediaAssetDto[]): ArticleAttachmentsDto | null {
  const assets = new Map(media.map((m) => [m.id, m]));
  const items = [...document.attachments].sort((a, b) => a.order - b.order).flatMap((item) => {
    const asset = assets.get(item.mediaAssetId);
    return asset?.status === 'ready' ? [{ item, asset }] : [];
  });
  const pdf = items.find(({ asset }) => asset.kind === 'document');
  if (pdf) {
    const { item, asset } = pdf;
    return {
      kind: 'document',
      images: [],
      document: {
        assetId: asset.id,
        title: item.title ?? asset.title ?? '',
        pageCount: asset.pageCount ?? asset.pages.length,
        allowDownload: !!item.allowDownload,
        canDownload: false,
        downloadUrl: '',
        pages: asset.pages,
      },
    };
  }
  const images = items
    .filter(({ asset }) => asset.kind === 'image')
    .map(({ item, asset }, order) => ({
      assetId: asset.id,
      order,
      caption: item.caption ?? null,
      altText: item.altText ?? '',
      width: asset.width ?? 1600,
      height: asset.height ?? 1200,
      blurHash: asset.blurHash,
      variants: asset.variants,
    }));
  return images.length ? { kind: 'images', images, document: null } : null;
}

/**
 * Preview (F05): one language version of the draft exactly as readers will see it, built from the reader's own
 * parts (cover, headline, trust row, health disclaimer, RDoc renderer, attachments, tags, sources). Nothing here is
 * interactive.
 */
@Component({
  selector: 'rd-article-preview',
  imports: [
    TranslocoPipe,
    BdiText,
    Avatar,
    LocalizedDatePipe,
    RDocRenderer,
    ArticleAttachments,
    ArticleCover,
    ArticleHeadline,
    ArticleTrustRow,
    ArticleHealthNotice,
    VerifiedBadge,
    ArticleSources,
    ArticleToc,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-preview': '', '[attr.data-preview-language]': 'language()' },
  template: `
    @if (translation(); as t) {
      <article class="mx-auto max-w-[720px]">
        @if (document().coverUrl; as cover) {
          <rd-article-cover [url]="cover" />
        }
        <rd-article-headline
          [field]="fieldName()"
          [topic]="topicName()"
          [minutes]="minutes()"
          [title]="t.title || ('editor.myArticles.untitled' | transloco)"
          [subtitle]="t.subtitle"
          [language]="t.language"
          [uiLang]="uiLang()"
        />

        <div class="mt-5 flex items-center gap-3">
          <rd-avatar [name]="author().displayName" [src]="author().avatarUrl" [size]="40" />
          <div class="min-w-0">
            <span class="inline-flex items-center gap-1 font-semibold">
              <rd-bdi-text [text]="author().displayName" />
              @if (author().isVerified) {
                <rd-verified-badge [size]="16" />
              }
            </span>
            <div class="text-xs text-text-secondary">
              @if (publishedAt(); as date) {
                {{ date | rdDate: uiLang() : 'long' }}
              } @else {
                {{ 'editor.preview.notPublished' | transloco }}
              }
            </div>
          </div>
        </div>

        <rd-article-trust-row [verified]="author().isVerified" [versionBadge]="document().versionBadge" [aiAssisted]="document().isAiAssisted" />

        @if (field()?.isSensitive) {
          <rd-article-health-notice />
        }

        @if (toc().length >= tocMinHeadings) {
          <rd-article-toc class="mb-6 block" [entries]="toc()" />
        }

        <rd-rdoc [doc]="t.content" />

        @if (attachments(); as list) {
          <rd-article-attachments class="mt-8" [attachments]="list" [article]="{ slug: slug() ?? '', language: t.language, title: t.title }" />
        }

        @if (document().tags.length) {
          <ul class="mt-8 flex list-none flex-wrap gap-2 p-0">
            @for (tag of document().tags; track tag) {
              <li class="rd-tag rd-tag-neutral" dir="auto">#{{ tag }}</li>
            }
          </ul>
        }

        <rd-article-sources [sources]="document().sources" headingId="preview-sources-title" />
      </article>
    }
  `,
})
export class ArticlePreview {
  readonly document = input.required<ArticleDraftDocument>();
  readonly language = input.required<ArticleLanguage>();
  readonly media = input<readonly MediaAssetDto[]>([]);
  readonly field = input<FieldDto | null>(null);
  readonly topic = input<TopicDto | null>(null);
  readonly author = input.required<PreviewAuthor>();
  readonly minutes = input<number | null>(null);
  readonly publishedAt = input<string | null>(null);
  readonly slug = input<string | null>(null);
  readonly uiLang = input.required<UiLanguage>();

  protected readonly tocMinHeadings = TOC_MIN_HEADINGS;
  protected readonly translation = computed(() => this.document().translations.find((t) => t.language === this.language()) ?? this.document().translations[0]);
  protected readonly fieldName = computed(() => {
    const field = this.field();
    return field ? (this.uiLang() === 'ar' ? field.nameAr : field.nameEn) : null;
  });
  protected readonly topicName = computed(() => {
    const topic = this.topic();
    return topic ? (this.uiLang() === 'ar' ? topic.nameAr : topic.nameEn) : null;
  });
  protected readonly toc = computed(() => tableOfContents(this.translation()?.content));
  protected readonly attachments = computed(() => previewAttachments(this.document(), this.media()));
}

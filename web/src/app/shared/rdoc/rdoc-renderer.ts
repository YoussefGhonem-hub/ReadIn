import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RDocContext } from './rdoc-context';
import { RDoc } from './rdoc.models';
import { languageDir } from './rdoc.utils';
import {
  BulletListBlockView,
  HeadingBlockView,
  OrderedListBlockView,
  ParagraphBlockView,
  QuoteBlockView,
  StepsBlockView,
  SummaryBlockView,
} from './blocks/text-blocks';
import {
  CalloutBlockView,
  CodeBlockView,
  CodeTabsBlockView,
  DividerBlockView,
  EmbedBlockView,
  ImageBlockView,
  TableBlockView,
} from './blocks/rich-blocks';

/**
 * Renders an RDoc document (SPEC §13) — one component per block type. Unknown block types are skipped so an older
 * client never breaks on newer content. Font size is driven by the `--rd-article-size` CSS variable.
 */
@Component({
  selector: 'rd-rdoc',
  imports: [
    ParagraphBlockView,
    HeadingBlockView,
    BulletListBlockView,
    OrderedListBlockView,
    StepsBlockView,
    QuoteBlockView,
    CalloutBlockView,
    CodeBlockView,
    CodeTabsBlockView,
    TableBlockView,
    ImageBlockView,
    DividerBlockView,
    EmbedBlockView,
    SummaryBlockView,
  ],
  providers: [RDocContext],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'rdoc block', '[attr.lang]': 'doc()?.language', '[attr.dir]': 'dir()' },
  template: `
    @for (block of doc()?.blocks ?? []; track block.id) {
      @switch (block.type) {
        @case ('paragraph') {
          <rd-paragraph-block [block]="block" />
        }
        @case ('heading') {
          <rd-heading-block [block]="block" />
        }
        @case ('bulletList') {
          <rd-bullet-list-block [block]="block" />
        }
        @case ('orderedList') {
          <rd-ordered-list-block [block]="block" />
        }
        @case ('steps') {
          <rd-steps-block [block]="block" />
        }
        @case ('quote') {
          <rd-quote-block [block]="block" />
        }
        @case ('callout') {
          <rd-callout-block [block]="block" />
        }
        @case ('code') {
          <rd-code-block [block]="block" />
        }
        @case ('codeTabs') {
          <rd-code-tabs-block [block]="block" />
        }
        @case ('table') {
          <rd-table-block [block]="block" />
        }
        @case ('image') {
          <rd-image-block [block]="block" />
        }
        @case ('divider') {
          <rd-divider-block [block]="block" />
        }
        @case ('embed') {
          <rd-embed-block [block]="block" />
        }
        @case ('summary') {
          <rd-summary-block [block]="block" />
        }
      }
    }
  `,
})
export class RDocRenderer {
  readonly doc = input.required<RDoc | null | undefined>();
  /** The published article this is the content of: the glossary sheet leaves it out of its article list (F21). */
  readonly articleId = input<string | null>(null);
  /** Embeds as a link card instead of a player (a post card's preview, F34). */
  readonly embedsAsLinks = input(false);
  protected readonly dir = computed(() => languageDir(this.doc()?.language ?? 'ar-EG'));

  constructor() {
    inject(RDocContext).bind(this.doc, this.articleId, this.embedsAsLinks);
  }
}

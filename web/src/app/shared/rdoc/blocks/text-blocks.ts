import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { BdiText } from '../../directives/bdi-text';
import { InlineContentView } from '../inline-content';
import { RDocContext } from '../rdoc-context';
import {
  BulletListBlock,
  HeadingBlock,
  OrderedListBlock,
  ParagraphBlock,
  QuoteBlock,
  StepsBlock,
  SummaryBlock,
} from '../rdoc.models';
import { headingAnchor, resolveBlockDir } from '../rdoc.utils';

/*
 * Text blocks. Each renders with its own resolved direction (SPEC §14.2 rule 1): the explicit `dir` when set,
 * otherwise the block's first strong character, otherwise the article language.
 */

@Component({
  selector: 'rd-paragraph-block',
  imports: [InlineContentView],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<p [attr.dir]="dir()" data-block-type="paragraph" [attr.data-block-id]="block().id"><rd-inline [nodes]="block().content" [baseDir]="dir()" /></p>`,
})
export class ParagraphBlockView {
  private readonly ctx = inject(RDocContext);
  readonly block = input.required<ParagraphBlock>();
  protected readonly dir = computed(() => resolveBlockDir(this.block(), this.block().dir, this.ctx.fallbackDir()));
}

@Component({
  selector: 'rd-heading-block',
  imports: [InlineContentView],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (block().level === 2) {
      <h2 [id]="anchor()" [attr.dir]="dir()" data-block-type="heading" [attr.data-block-id]="block().id"><rd-inline [nodes]="block().content" [baseDir]="dir()" /></h2>
    } @else {
      <h3 [id]="anchor()" [attr.dir]="dir()" data-block-type="heading" [attr.data-block-id]="block().id"><rd-inline [nodes]="block().content" [baseDir]="dir()" /></h3>
    }
  `,
})
export class HeadingBlockView {
  private readonly ctx = inject(RDocContext);
  readonly block = input.required<HeadingBlock>();
  protected readonly anchor = computed(() => headingAnchor(this.block().id));
  protected readonly dir = computed(() => resolveBlockDir(this.block(), this.block().dir, this.ctx.fallbackDir()));
}

@Component({
  selector: 'rd-bullet-list-block',
  imports: [InlineContentView],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <ul [attr.dir]="dir()" data-block-type="bulletList" [attr.data-block-id]="block().id">
      @for (item of block().items; track $index) {
        <li><rd-inline [nodes]="item" [baseDir]="dir()" /></li>
      }
    </ul>
  `,
})
export class BulletListBlockView {
  private readonly ctx = inject(RDocContext);
  readonly block = input.required<BulletListBlock>();
  protected readonly dir = computed(() => resolveBlockDir(this.block(), this.block().dir, this.ctx.fallbackDir()));
}

@Component({
  selector: 'rd-ordered-list-block',
  imports: [InlineContentView],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <ol [attr.dir]="dir()" data-block-type="orderedList" [attr.data-block-id]="block().id">
      @for (item of block().items; track $index) {
        <li><rd-inline [nodes]="item" [baseDir]="dir()" /></li>
      }
    </ol>
  `,
})
export class OrderedListBlockView {
  private readonly ctx = inject(RDocContext);
  readonly block = input.required<OrderedListBlock>();
  protected readonly dir = computed(() => resolveBlockDir(this.block(), this.block().dir, this.ctx.fallbackDir()));
}

@Component({
  selector: 'rd-steps-block',
  imports: [InlineContentView, BdiText],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <ol class="rd-steps" [attr.dir]="dir()" data-block-type="steps" [attr.data-block-id]="block().id">
      @for (item of block().items; track $index) {
        <li>
          <span class="rd-step-title"><rd-bdi-text [text]="item.title" [baseDir]="dir()" /></span>
          <rd-inline [nodes]="item.content" [baseDir]="dir()" />
        </li>
      }
    </ol>
  `,
})
export class StepsBlockView {
  private readonly ctx = inject(RDocContext);
  readonly block = input.required<StepsBlock>();
  protected readonly dir = computed(() => resolveBlockDir(this.block(), this.block().dir, this.ctx.fallbackDir()));
}

@Component({
  selector: 'rd-quote-block',
  imports: [InlineContentView, BdiText],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <blockquote [attr.dir]="dir()" data-block-type="quote" [attr.data-block-id]="block().id">
      <p><rd-inline [nodes]="block().content" [baseDir]="dir()" /></p>
      @if (block().cite; as cite) {
        <cite>— <rd-bdi-text [text]="cite" [baseDir]="dir()" /></cite>
      }
    </blockquote>
  `,
})
export class QuoteBlockView {
  private readonly ctx = inject(RDocContext);
  readonly block = input.required<QuoteBlock>();
  protected readonly dir = computed(() => resolveBlockDir(this.block(), this.block().dir, this.ctx.fallbackDir()));
}

@Component({
  selector: 'rd-summary-block',
  imports: [InlineContentView, TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <aside class="rd-summary" role="note" [attr.dir]="dir()" data-block-type="summary" [attr.data-block-id]="block().id">
      <span class="rd-summary-label">{{ 'rdoc.summary' | transloco }}</span>
      <rd-inline [nodes]="block().content" [baseDir]="dir()" />
    </aside>
  `,
})
export class SummaryBlockView {
  private readonly ctx = inject(RDocContext);
  readonly block = input.required<SummaryBlock>();
  protected readonly dir = computed(() => resolveBlockDir(this.block(), this.block().dir, this.ctx.fallbackDir()));
}

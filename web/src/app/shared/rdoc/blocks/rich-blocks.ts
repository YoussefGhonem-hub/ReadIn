import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { DomSanitizer } from '@angular/platform-browser';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { BdiText } from '../../directives/bdi-text';
import { InlineContentView } from '../inline-content';
import { RDocContext } from '../rdoc-context';
import { RDocMarks } from '../rdoc-marks';
import { CalloutBlock, CodeBlock, CodeTabsBlock, DividerBlock, EmbedBlock, ImageBlock, TableBlock } from '../rdoc.models';
import { resolveBlockDir, safeHttpUrl, youtubeId } from '../rdoc.utils';
import { sameMarks } from '../text-marks';
import { CodeView } from './code-view';

@Component({
  selector: 'rd-callout-block',
  imports: [InlineContentView, BdiText, TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <aside
      class="rd-callout rd-callout-{{ block().variant }}"
      role="note"
      [attr.dir]="dir()"
      data-block-type="callout"
      [attr.data-variant]="block().variant"
      [attr.data-block-id]="block().id"
    >
      <span class="rd-callout-icon mt-1 shrink-0" aria-hidden="true">
        @switch (block().variant) {
          @case ('tip') {
            <svg lucideIcon="Lightbulb" [size]="20"></svg>
          }
          @case ('info') {
            <svg lucideIcon="Info" [size]="20"></svg>
          }
          @case ('warning') {
            <svg lucideIcon="TriangleAlert" [size]="20"></svg>
          }
          @case ('danger') {
            <svg lucideIcon="OctagonX" [size]="20"></svg>
          }
        }
      </span>
      <div class="min-w-0 flex-1">
        <strong class="block">
          @if (block().title; as title) {
            <rd-bdi-text [text]="title" [baseDir]="dir()" />
          } @else {
            {{ 'rdoc.callout.' + block().variant | transloco }}
          }
        </strong>
        <rd-inline [nodes]="block().content" [baseDir]="dir()" [marks]="marks()" />
      </div>
    </aside>
  `,
})
export class CalloutBlockView {
  private readonly ctx = inject(RDocContext);
  private readonly highlights = inject(RDocMarks);
  readonly block = input.required<CalloutBlock>();
  protected readonly dir = computed(() => resolveBlockDir(this.block(), this.block().dir, this.ctx.fallbackDir()));
  protected readonly marks = computed(() => this.highlights.of(this.block().id), { equal: sameMarks });
}

@Component({
  selector: 'rd-code-block',
  imports: [CodeView],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { 'data-block-type': 'code', '[attr.data-block-id]': 'block().id', dir: 'ltr', class: 'block' },
  template: `
    <rd-code-view
      [code]="block().code"
      [lang]="block().lang"
      [filename]="block().filename"
      [highlightLines]="block().highlightLines"
    />
  `,
})
export class CodeBlockView {
  readonly block = input.required<CodeBlock>();
}

@Component({
  selector: 'rd-code-tabs-block',
  imports: [CodeView],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { 'data-block-type': 'codeTabs', '[attr.data-block-id]': 'block().id', dir: 'ltr', class: 'rd-code-tabs rd-code block' },
  template: `
    <div role="tablist">
      @for (tab of block().tabs; track $index) {
        <button
          type="button"
          role="tab"
          [id]="tabId($index)"
          [attr.aria-selected]="selected() === $index"
          [attr.aria-controls]="panelId($index)"
          [attr.tabindex]="selected() === $index ? 0 : -1"
          (click)="selected.set($index)"
          (keydown.arrowRight)="move(1)"
          (keydown.arrowLeft)="move(-1)"
        >
          {{ tab.label }}
        </button>
      }
    </div>
    @for (tab of block().tabs; track $index) {
      <div role="tabpanel" [id]="panelId($index)" [attr.aria-labelledby]="tabId($index)" [hidden]="selected() !== $index">
        <rd-code-view [code]="tab.code" [lang]="tab.lang" [filename]="tab.filename" />
      </div>
    }
  `,
})
export class CodeTabsBlockView {
  readonly block = input.required<CodeTabsBlock>();
  protected readonly selected = signal(0);

  protected tabId(i: number): string {
    return `${this.block().id}-tab-${i}`;
  }

  protected panelId(i: number): string {
    return `${this.block().id}-panel-${i}`;
  }

  protected move(delta: number): void {
    const count = this.block().tabs.length;
    this.selected.update((i) => (i + delta + count) % count);
  }
}

@Component({
  selector: 'rd-table-block',
  imports: [InlineContentView],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="rd-table-wrap" data-block-type="table" [attr.data-block-id]="block().id" tabindex="0">
      <table [attr.dir]="dir()">
        <thead>
          <tr>
            @for (cell of block().header; track $index) {
              <th scope="col"><rd-inline [nodes]="cell" [baseDir]="dir()" /></th>
            }
          </tr>
        </thead>
        <tbody>
          @for (row of block().rows; track $index) {
            <tr>
              @for (cell of row; track $index) {
                <td><rd-inline [nodes]="cell" [baseDir]="dir()" /></td>
              }
            </tr>
          }
        </tbody>
      </table>
    </div>
  `,
})
export class TableBlockView {
  private readonly ctx = inject(RDocContext);
  readonly block = input.required<TableBlock>();
  protected readonly dir = computed(() => resolveBlockDir(this.block(), this.block().dir, this.ctx.fallbackDir()));
}

@Component({
  selector: 'rd-image-block',
  imports: [BdiText],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <figure class="rd-figure" data-block-type="image" [attr.data-block-id]="block().id">
      @if (src(); as src) {
        <img
          [src]="src"
          [alt]="block().alt"
          [attr.width]="block().width"
          [attr.height]="block().height"
          [class.rd-only-light]="!!darkSrc()"
          loading="lazy"
          decoding="async"
        />
        @if (darkSrc(); as darkSrc) {
          <img
            [src]="darkSrc"
            [alt]="block().alt"
            [attr.width]="block().width"
            [attr.height]="block().height"
            class="rd-only-dark"
            loading="lazy"
            decoding="async"
          />
        }
      }
      @if (block().caption; as caption) {
        <figcaption><rd-bdi-text [text]="caption" /></figcaption>
      }
    </figure>
  `,
})
export class ImageBlockView {
  private readonly ctx = inject(RDocContext);
  readonly block = input.required<ImageBlock>();
  protected readonly src = computed(() => this.ctx.resolveAsset(this.block().src));
  /** Diagrams can ship a dark-mode variant (SPEC §15.5 rule 5); CSS picks the visible one, even during SSR. */
  protected readonly darkSrc = computed(() => this.ctx.resolveAsset(this.block().darkSrc));
}

@Component({
  selector: 'rd-divider-block',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<hr data-block-type="divider" [attr.data-block-id]="block().id" />`,
})
export class DividerBlockView {
  readonly block = input.required<DividerBlock>();
}

@Component({
  selector: 'rd-embed-block',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div data-block-type="embed" [attr.data-provider]="block().provider" [attr.data-block-id]="block().id">
      @if (youtubeSrc(); as src) {
        <div class="rd-embed">
          <iframe
            [src]="src"
            [title]="'rdoc.embed.youtube' | transloco"
            loading="lazy"
            allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            referrerpolicy="strict-origin-when-cross-origin"
            allowfullscreen
          ></iframe>
        </div>
      } @else if (link(); as href) {
        <a
          [href]="href"
          target="_blank"
          rel="nofollow ugc noopener noreferrer"
          class="rd-card flex items-center justify-between gap-3 p-4 no-underline"
        >
          <span>{{ (block().provider === 'github-gist' ? 'rdoc.embed.gist' : 'rdoc.embed.open') | transloco }}</span>
          <svg lucideIcon="ExternalLink" [size]="18" class="rd-flip-rtl"></svg>
        </a>
      }
    </div>
  `,
})
export class EmbedBlockView {
  private readonly sanitizer = inject(DomSanitizer);
  private readonly ctx = inject(RDocContext);
  readonly block = input.required<EmbedBlock>();

  /** Allow-listed providers only (SPEC §13.2); the id is validated before building the embed URL. */
  protected readonly youtubeSrc = computed(() => {
    if (this.block().provider !== 'youtube' || this.ctx.embedsAsLinks()) return null;
    const id = youtubeId(this.block().url);
    return id ? this.sanitizer.bypassSecurityTrustResourceUrl(`https://www.youtube-nocookie.com/embed/${id}`) : null;
  });

  protected readonly link = computed(() => {
    const url = safeHttpUrl(this.block().url);
    if (!url) return null;
    if (this.block().provider === 'github-gist') return /^https:\/\/gist\.github\.com\//.test(url) ? url : null;
    return url;
  });
}

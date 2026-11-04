import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import { RouterLink } from '@angular/router';
import { BidiSegment, TextDir, segmentBidi } from '../directives/bidi';
import { InlineContent, Mark } from './rdoc.models';
import { RDocContext } from './rdoc-context';
import { safeHttpUrl } from './rdoc.utils';

type InlineVm =
  | { kind: 'text'; segments: BidiSegment[]; marks: Mark[] }
  | { kind: 'term'; termId: string; text: string; segments: BidiSegment[] }
  | { kind: 'mention'; handle: string; text: string }
  | { kind: 'break' };

/**
 * Renders RDoc inline nodes (SPEC §13.3). Runs in the opposite direction of the block are wrapped in `<bdi>` so
 * punctuation and word order never break (SPEC §14.2 rule 2). Inline code is isolated with `dir="ltr"`.
 */
@Component({
  selector: 'rd-inline',
  imports: [NgTemplateOutlet, RouterLink],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @for (node of vm(); track $index) {
      @switch (node.kind) {
        @case ('text') {
          <ng-container *ngTemplateOutlet="marked; context: { segs: node.segments, marks: node.marks, i: 0 }" />
        }
        @case ('term') {
          <button type="button" class="rd-term" aria-haspopup="dialog" [attr.data-term]="node.termId" (click)="openTerm($event, node.termId, node.text)">
            <ng-container *ngTemplateOutlet="plain; context: { segs: node.segments }" />
          </button>
        }
        @case ('mention') {
          <a class="rd-mention" [routerLink]="'/@' + node.handle"><bdi>{{ node.text }}</bdi></a>
        }
        @case ('break') {
          <br />
        }
      }
    }

    <ng-template #plain let-segs="segs">
      @for (seg of segs; track $index) {
        @if (seg.isolate) {
          <bdi>{{ seg.text }}</bdi>
        } @else {
          <ng-container>{{ seg.text }}</ng-container>
        }
      }
    </ng-template>

    <ng-template #marked let-segs="segs" let-marks="marks" let-i="i">
      @let mark = marks[i];
      @if (!mark) {
        <ng-container *ngTemplateOutlet="plain; context: { segs }" />
      } @else {
        @switch (mark.type) {
          @case ('bold') {
            <strong><ng-container *ngTemplateOutlet="marked; context: { segs, marks, i: i + 1 }" /></strong>
          }
          @case ('italic') {
            <em><ng-container *ngTemplateOutlet="marked; context: { segs, marks, i: i + 1 }" /></em>
          }
          @case ('strike') {
            <s><ng-container *ngTemplateOutlet="marked; context: { segs, marks, i: i + 1 }" /></s>
          }
          @case ('highlight') {
            <mark><ng-container *ngTemplateOutlet="marked; context: { segs, marks, i: i + 1 }" /></mark>
          }
          @case ('code') {
            <code class="rd-inline-code" dir="ltr">{{ joined(segs) }}</code>
          }
          @case ('link') {
            @let href = safeHref(mark.href);
            @if (href) {
              <a [href]="href" target="_blank" rel="nofollow ugc noopener noreferrer"
                ><ng-container *ngTemplateOutlet="marked; context: { segs, marks, i: i + 1 }"
              /></a>
            } @else {
              <ng-container *ngTemplateOutlet="marked; context: { segs, marks, i: i + 1 }" />
            }
          }
          @default {
            <ng-container *ngTemplateOutlet="marked; context: { segs, marks, i: i + 1 }" />
          }
        }
      }
    </ng-template>
  `,
})
export class InlineContentView {
  protected readonly ctx = inject(RDocContext);

  readonly nodes = input.required<InlineContent>();
  /** Resolved direction of the containing block. */
  readonly baseDir = input.required<TextDir>();

  protected readonly vm = computed<InlineVm[]>(() => {
    const base = this.baseDir();
    return (this.nodes() ?? []).map((node): InlineVm => {
      switch (node.type) {
        case 'text': {
          const marks = node.marks ?? [];
          // Inline code is isolated as a whole; its text is not split.
          const isCode = marks.some((m) => m.type === 'code');
          const ordered = isCode ? [...marks.filter((m) => m.type !== 'code'), { type: 'code' } as Mark] : marks;
          return { kind: 'text', segments: isCode ? [{ text: node.text, isolate: false }] : segmentBidi(node.text, base), marks: ordered };
        }
        case 'term':
          return { kind: 'term', termId: node.termId, text: node.text, segments: segmentBidi(node.text, base) };
        case 'mention':
          return { kind: 'mention', handle: node.text.replace(/^@/, ''), text: node.text };
        default:
          return { kind: 'break' };
      }
    });
  });

  /**
   * The sheet gives focus back to whatever had it when it opened (F21). Safari doesn't focus a button on click, so the
   * term takes focus first.
   */
  protected openTerm(event: Event, termId: string, text: string): void {
    (event.currentTarget as HTMLElement | null)?.focus({ preventScroll: true });
    this.ctx.openTerm(termId, text);
  }

  protected safeHref(href: string): string | null {
    return safeHttpUrl(href);
  }

  protected joined(segs: BidiSegment[]): string {
    return segs.map((s) => s.text).join('');
  }
}

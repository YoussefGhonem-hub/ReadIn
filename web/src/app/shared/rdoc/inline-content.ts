import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import { RouterLink } from '@angular/router';
import { BidiSegment, TextDir, segmentBidi } from '../directives/bidi';
import { ProfileCardTrigger } from '../profile-card/profile-card.directive';
import { InlineContent, Mark } from './rdoc.models';
import { RDocContext } from './rdoc-context';
import { safeHttpUrl } from './rdoc.utils';
import { MarkedPiece, NO_MARKS, TextMark, markPieces } from './text-marks';

/** A BiDi run, cut into pieces where highlights (F30) start or end; `pieces` is null when none touches it. */
type Segment = BidiSegment & { pieces: MarkedPiece[] | null };

type InlineVm =
  | { kind: 'text'; segments: Segment[]; marks: Mark[] }
  | { kind: 'term'; termId: string; text: string; segments: Segment[] }
  | { kind: 'mention'; handle: string; userId: string; text: string; pieces: MarkedPiece[] | null }
  | { kind: 'break' };

/**
 * Renders RDoc inline nodes (SPEC §13.3). Runs in the opposite direction of the block are wrapped in `<bdi>` so
 * punctuation and word order never break (SPEC §14.2 rule 2). Inline code is isolated with `dir="ltr"`.
 *
 * Highlights (F30, `marks`) are drawn as plain `<span>`s inside each run, `<bdi>` and inline code: a run is never split
 * or reordered, and the spans set no direction, so they can't change how mixed Arabic/English text is laid out.
 *
 * An @mention opens the person's profile; a pointer resting on it opens their profile card (web, F11/F14).
 */
@Component({
  selector: 'rd-inline',
  imports: [NgTemplateOutlet, RouterLink, ProfileCardTrigger],
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: `
    /* A highlight is cut into one span per BiDi run: "skip-spaces: none" keeps the underline under a space at a span's
       edge (Chromium skips those by default), so it runs on unbroken into the next run. */
    .rd-hl-popular {
      text-decoration-line: underline;
      text-decoration-color: color-mix(in srgb, var(--rd-color-accent) 60%, transparent);
      text-decoration-thickness: 2px;
      text-underline-offset: 0.28em;
      text-decoration-skip-ink: none;
      text-decoration-skip-spaces: none;
      cursor: pointer;
    }
    .rd-hl-mine {
      background-color: color-mix(in srgb, var(--rd-color-accent) 24%, transparent);
      text-decoration-line: underline;
      text-decoration-color: var(--rd-color-accent);
      text-decoration-thickness: 2px;
      text-underline-offset: 0.28em;
      text-decoration-skip-ink: none;
      text-decoration-skip-spaces: none;
      cursor: pointer;
    }
    @media (forced-colors: active) {
      .rd-hl-mine {
        background-color: Mark;
        color: MarkText;
      }
      .rd-hl-popular {
        text-decoration-color: LinkText;
      }
    }
  `,
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
          @if (!ctx.isMentionLinked(node.userId)) {
            <!-- F36: someone you are blocked with: plain text -->
            <bdi data-unlinked-mention>@if (node.pieces) {<ng-container *ngTemplateOutlet="pieces; context: { pieces: node.pieces }" />} @else {{{ node.text }}}</bdi>
          } @else {
          <a class="rd-mention" [routerLink]="'/@' + node.handle" [rdProfileCard]="node.handle"
            ><bdi>@if (node.pieces) {<ng-container *ngTemplateOutlet="pieces; context: { pieces: node.pieces }" />} @else {{{ node.text }}}</bdi></a
          >
          }
        }
        @case ('break') {
          <br />
        }
      }
    }

    <ng-template #plain let-segs="segs">
      @for (seg of segs; track $index) {
        @if (seg.isolate) {
          <bdi>@if (seg.pieces) {<ng-container *ngTemplateOutlet="pieces; context: { pieces: seg.pieces }" />} @else {{{ seg.text }}}</bdi>
        } @else if (seg.pieces) {
          <ng-container *ngTemplateOutlet="pieces; context: { pieces: seg.pieces }" />
        } @else {
          <ng-container>{{ seg.text }}</ng-container>
        }
      }
    </ng-template>

    <!-- Highlights (F30): yours (with its id) and popular ones (with their count) -->
    <ng-template #pieces let-pieces="pieces">
      @for (piece of pieces; track $index) {
        @if (piece.mine !== null || piece.count !== null) {
          <span
            class="rd-hl"
            [class.rd-hl-mine]="piece.mine !== null"
            [class.rd-hl-popular]="piece.count !== null"
            [attr.data-hl-mine]="piece.mine"
            [attr.data-hl-count]="piece.count"
            >{{ piece.text }}</span
          >
        } @else {
          <ng-container>{{ piece.text }}</ng-container>
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
            <code class="rd-inline-code" dir="ltr"
              >@if (segs[0]?.pieces; as codePieces) {<ng-container *ngTemplateOutlet="pieces; context: { pieces: codePieces }" />} @else {{{ joined(segs) }}}</code
            >
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
  /** Highlights to draw (F30), in offsets of this content's plain text (text-marks.ts). */
  readonly marks = input<readonly TextMark[]>(NO_MARKS);

  protected readonly vm = computed<InlineVm[]>(() => {
    const base = this.baseDir();
    const highlights = this.marks();
    let offset = 0;
    /** The runs of a node's text, each with its highlight pieces; `offset` moves past the node. */
    const cut = (segments: BidiSegment[]): Segment[] =>
      segments.map((seg) => {
        const pieces = highlights.length ? markPieces(seg.text, offset, highlights) : null;
        offset += seg.text.length;
        return { ...seg, pieces };
      });
    return (this.nodes() ?? []).map((node): InlineVm => {
      switch (node.type) {
        case 'text': {
          const marks = node.marks ?? [];
          // Inline code is isolated as a whole; its text is not split.
          const isCode = marks.some((m) => m.type === 'code');
          const ordered = isCode ? [...marks.filter((m) => m.type !== 'code'), { type: 'code' } as Mark] : marks;
          return { kind: 'text', segments: cut(isCode ? [{ text: node.text, isolate: false }] : segmentBidi(node.text, base)), marks: ordered };
        }
        case 'term':
          return { kind: 'term', termId: node.termId, text: node.text, segments: cut(segmentBidi(node.text, base)) };
        case 'mention': {
          const pieces = highlights.length ? markPieces(node.text, offset, highlights) : null;
          offset += node.text.length;
          return { kind: 'mention', handle: node.text.replace(/^@/, ''), userId: node.userId, text: node.text, pieces };
        }
        default:
          offset += 1; // a hard break is "\n" in the plain text
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

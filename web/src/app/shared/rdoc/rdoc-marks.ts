import { Injectable, Signal, signal } from '@angular/core';
import { NO_MARKS, TextMark } from './text-marks';

/** Highlights to draw (F30), by block id, in offsets of each block's plain text. */
export type BlockMarks = ReadonlyMap<string, readonly TextMark[]>;
const NO_BLOCK_MARKS: BlockMarks = new Map();

/**
 * The highlights (F30) drawn in one `<rd-rdoc>`, for its block components; only the reader sets any. Kept apart from
 * RDocContext, whose file the initial bundle carries (TermSheetService), so none of this lands there.
 */
@Injectable()
export class RDocMarks {
  private marks: Signal<BlockMarks | null> = signal(null);

  bind(marks: Signal<BlockMarks | null>): void {
    this.marks = marks;
  }

  /** A block's highlights. */
  of(blockId: string): readonly TextMark[] {
    return (this.marks() ?? NO_BLOCK_MARKS).get(blockId) ?? NO_MARKS;
  }
}

import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { TextDir, detectDir, segmentBidi } from './bidi';

/**
 * Renders a plain string with opposite-direction runs wrapped in `<bdi>` (titles, bios, card text).
 * The host carries the text's own direction, which also isolates it from the surrounding UI — so a pure-English
 * label like `.NET` inside the Arabic UI keeps its leading dot in place.
 */
@Component({
  selector: 'rd-bdi-text',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { '[attr.dir]': 'dir()' },
  template: `@for (seg of segments(); track $index) {@if (seg.isolate) {<bdi>{{ seg.text }}</bdi>} @else {<ng-container>{{ seg.text }}</ng-container>}}`,
})
export class BdiText {
  readonly text = input.required<string>();
  /** Direction of the surrounding block; defaults to the text's own first strong character. */
  readonly baseDir = input<TextDir | null>(null);

  protected readonly dir = computed<TextDir | null>(() => this.baseDir() ?? detectDir(this.text()));
  protected readonly segments = computed(() => segmentBidi(this.text() ?? '', this.dir() ?? 'ltr'));
}

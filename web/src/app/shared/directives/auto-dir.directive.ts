import { Directive, computed, input } from '@angular/core';
import { TextDir, detectDir } from './bidi';

/**
 * Sets `dir` on an element from its text's first strong character (SPEC §14.2 rule 1, 6).
 * Unlike plain `dir="auto"`, the resolved value is available during SSR and to code that needs it.
 *
 * <p [rdAutoDir]="comment.body">{{ comment.body }}</p>
 */
@Directive({
  selector: '[rdAutoDir]',
  host: { '[attr.dir]': 'dir()' },
})
export class AutoDir {
  readonly rdAutoDir = input<string | null | undefined>('');
  /** Used when the text has no strong character (numbers, emoji). `auto` lets the browser decide. */
  readonly rdAutoDirFallback = input<TextDir | 'auto'>('auto');

  readonly dir = computed<TextDir | 'auto'>(() => detectDir(this.rdAutoDir()) ?? this.rdAutoDirFallback());
}

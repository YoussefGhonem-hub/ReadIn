import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';

/**
 * The Verified badge (F19) next to a writer's name, announced as «كاتب موثّق» / "Verified writer" (SPEC §26).
 *
 * Lucide adds `aria-hidden="true"` to every icon without a title, which hid this one's `role="img"` and `aria-label`
 * from screen readers. An empty title tells it the icon is labelled without adding a `<title>` element (that would
 * bring the browser's own tooltip). The host has no box (`display: contents`), so the icon sits in the name's row
 * exactly as an inline icon did.
 */
@Component({
  selector: 'rd-verified-badge',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'contents' },
  template: `<svg
    lucideIcon="BadgeCheck"
    [size]="size()"
    [title]="''"
    class="shrink-0 text-primary"
    role="img"
    [attr.aria-label]="'article.verifiedWriter' | transloco"
    data-verified-badge
  ></svg>`,
})
export class VerifiedBadge {
  /** The icon's size in px (14–20 next to names). */
  readonly size = input(16);
}

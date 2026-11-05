import { ChangeDetectionStrategy, Component, DOCUMENT, Injector, afterNextRender, computed, inject, input, model, signal } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { LinkPlatform } from '../../core/api/models';
import { LinkIcon } from './link-icon';
import { LINK_PLACEHOLDERS, LINK_PLATFORMS, LinkDraft, MAX_LINKS, MAX_LINK_LABEL, normalizeLinkUrl } from './link-rules';

/** A link row in the editor; `id` keeps the row (and its focus) while the list is reordered. */
export interface LinkRow extends LinkDraft {
  id: number;
}

let nextRowId = 1;

/** Rows for the editor from saved links (or nothing). */
export function linkRows(links: readonly { platform: LinkPlatform; url: string; label?: string | null }[]): LinkRow[] {
  return links.map((link) => ({ id: nextRowId++, platform: link.platform, url: link.url, label: link.label ?? '' }));
}

/**
 * The "روابط" / "Links" section of Edit profile (F14): the member's social links in their order, each with its
 * platform's icon and name, the URL (and a name for Other), move up / down and remove; "+ إضافة رابط" opens the platform
 * picker (a named platform already used is disabled, Other may repeat) and focuses the new link's field. At most 8. A
 * URL typed without a scheme gets `https://` when the field is left. Errors come from the page (`errors`, keyed like
 * the API: `links`, `links[2].url`, `links[2].label`, `links[2].platform`, valued with translation keys).
 */
@Component({
  selector: 'rd-links-editor',
  imports: [TranslocoPipe, LucideDynamicIcon, LinkIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-links-editor': '' },
  template: `
    <fieldset class="m-0 flex flex-col gap-3 border-0 p-0" aria-describedby="links-hint">
      <legend class="rd-label p-0">{{ 'profile.linksEditor.title' | transloco }}</legend>
      <p id="links-hint" class="m-0 -mt-2 text-xs text-text-secondary">{{ 'profile.linksEditor.hint' | transloco: { max: maxLinks } }}</p>

      @if (rows().length) {
        <ol class="m-0 flex list-none flex-col gap-3 p-0" data-link-rows>
          @for (row of rows(); track row.id; let i = $index, first = $first, last = $last) {
            @let name = 'profile.links.platforms.' + row.platform | transloco;
            <li class="rounded-md border border-border p-3" [attr.data-link-row]="i" [attr.data-platform]="row.platform">
              <div class="flex items-center gap-2">
                <span class="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-surface-variant text-text-primary">
                  <rd-link-icon [platform]="row.platform!" [size]="18" />
                </span>
                <span class="min-w-0 flex-1 truncate text-sm font-semibold" [id]="'link-' + row.id + '-name'">{{ name }}</span>
                <button
                  type="button"
                  class="rd-btn rd-btn-ghost h-11 w-11 p-0"
                  [disabled]="disabled() || first"
                  [attr.aria-label]="'profile.linksEditor.moveUp' | transloco: { name: rowName(row, name) }"
                  [id]="'link-' + row.id + '-up'"
                  data-link-up
                  (click)="move(i, -1, 'up')"
                >
                  <svg lucideIcon="ChevronUp" [size]="18" aria-hidden="true"></svg>
                </button>
                <button
                  type="button"
                  class="rd-btn rd-btn-ghost h-11 w-11 p-0"
                  [disabled]="disabled() || last"
                  [attr.aria-label]="'profile.linksEditor.moveDown' | transloco: { name: rowName(row, name) }"
                  [id]="'link-' + row.id + '-down'"
                  data-link-down
                  (click)="move(i, 1, 'down')"
                >
                  <svg lucideIcon="ChevronDown" [size]="18" aria-hidden="true"></svg>
                </button>
                <button
                  type="button"
                  class="rd-btn rd-btn-ghost h-11 w-11 p-0 text-error"
                  [disabled]="disabled()"
                  [attr.aria-label]="'profile.linksEditor.remove' | transloco: { name: rowName(row, name) }"
                  data-link-remove
                  (click)="remove(i)"
                >
                  <svg lucideIcon="Trash2" [size]="18" aria-hidden="true"></svg>
                </button>
              </div>
              @if (errors()['links[' + i + '].platform']; as key) {
                <p class="rd-field-error" data-link-error="platform">{{ key | transloco }}</p>
              }

              @if (row.platform === 'other') {
                <div class="mt-2">
                  <label class="rd-label" [for]="'link-' + row.id + '-label'">{{ 'profile.linksEditor.label' | transloco }}</label>
                  <input
                    class="rd-input"
                    dir="auto"
                    autocomplete="off"
                    [id]="'link-' + row.id + '-label'"
                    [attr.maxlength]="maxLabel"
                    [value]="row.label"
                    [placeholder]="'profile.linksEditor.labelPlaceholder' | transloco"
                    [disabled]="disabled()"
                    [attr.aria-invalid]="!!errors()['links[' + i + '].label'] || null"
                    [attr.aria-describedby]="errors()['links[' + i + '].label'] ? 'link-' + row.id + '-label-error' : null"
                    data-link-label
                    (input)="patch(i, { label: $any($event.target).value })"
                  />
                  @if (errors()['links[' + i + '].label']; as key) {
                    <p class="rd-field-error" [id]="'link-' + row.id + '-label-error'" data-link-error="label">{{ key | transloco }}</p>
                  }
                </div>
              }

              <div class="mt-2">
                <label class="sr-only" [for]="'link-' + row.id + '-url'">{{ 'profile.linksEditor.url' | transloco: { name: rowName(row, name) } }}</label>
                <input
                  class="rd-input"
                  type="url"
                  inputmode="url"
                  dir="ltr"
                  autocapitalize="off"
                  autocorrect="off"
                  spellcheck="false"
                  autocomplete="off"
                  [id]="'link-' + row.id + '-url'"
                  [value]="row.url"
                  [placeholder]="placeholders[row.platform!]"
                  [disabled]="disabled()"
                  [attr.aria-invalid]="!!errors()['links[' + i + '].url'] || null"
                  [attr.aria-describedby]="errors()['links[' + i + '].url'] ? 'link-' + row.id + '-url-error' : null"
                  data-link-url
                  (input)="patch(i, { url: $any($event.target).value })"
                  (blur)="tidy(i)"
                />
                @if (errors()['links[' + i + '].url']; as key) {
                  <p class="rd-field-error" [id]="'link-' + row.id + '-url-error'" data-link-error="url">{{ key | transloco }}</p>
                }
              </div>
            </li>
          }
        </ol>
      }

      @if (errors()['links']; as key) {
        <p class="rd-field-error m-0" data-link-error="list">{{ key | transloco }}</p>
      }

      @if (rows().length < maxLinks) {
        @if (picking()) {
          <div class="rounded-md border border-border p-3" role="group" aria-labelledby="link-picker-title" data-link-picker>
            <p id="link-picker-title" class="m-0 mb-2 text-sm font-semibold">{{ 'profile.linksEditor.pick' | transloco }}</p>
            <div class="grid grid-cols-2 gap-2 sm:grid-cols-3">
              @for (platform of platforms; track platform; let first = $first) {
                <button
                  type="button"
                  class="rd-btn rd-btn-outline min-h-11 justify-start gap-2 px-3 text-sm"
                  [disabled]="disabled() || taken().has(platform)"
                  [attr.data-pick-platform]="platform"
                  [id]="first ? 'link-picker-first' : null"
                  (click)="add(platform)"
                >
                  <rd-link-icon [platform]="platform" [size]="18" />
                  <span class="min-w-0 truncate">{{ 'profile.links.platforms.' + platform | transloco }}</span>
                </button>
              }
            </div>
            <button type="button" class="rd-btn rd-btn-ghost mt-2 min-h-11 px-3 text-sm" data-link-picker-cancel (click)="closePicker()">
              {{ 'common.cancel' | transloco }}
            </button>
          </div>
        } @else {
          <button
            type="button"
            id="link-add"
            class="rd-btn rd-btn-outline min-h-11 gap-1.5 self-start px-4 text-sm"
            [disabled]="disabled()"
            aria-haspopup="true"
            data-add-link
            (click)="openPicker()"
          >
            <svg lucideIcon="Plus" [size]="16" aria-hidden="true"></svg>
            {{ 'profile.linksEditor.add' | transloco }}
          </button>
        }
      } @else {
        <p class="m-0 text-xs text-text-secondary" data-links-full>{{ 'profile.linksEditor.full' | transloco: { max: maxLinks } }}</p>
      }
    </fieldset>
  `,
})
export class LinksEditor {
  private readonly document = inject(DOCUMENT);
  private readonly injector = inject(Injector);

  /** The links being edited, in order (two-way). */
  readonly rows = model.required<LinkRow[]>();
  /** Translation keys of the errors to show, keyed like the API (`links`, `links[2].url`, …). */
  readonly errors = input<Readonly<Record<string, string>>>({});
  readonly disabled = input(false);

  protected readonly platforms = LINK_PLATFORMS;
  protected readonly placeholders = LINK_PLACEHOLDERS;
  protected readonly maxLinks = MAX_LINKS;
  protected readonly maxLabel = MAX_LINK_LABEL;
  protected readonly picking = signal(false);
  /** Named platforms already in the list (one link each); Other may repeat. */
  protected readonly taken = computed(() => new Set<LinkPlatform>(this.rows().flatMap((r) => (r.platform && r.platform !== 'other' ? [r.platform] : []))));

  /** "Instagram", or an Other link's own name when it has one. */
  protected rowName(row: LinkRow, platformName: string): string {
    return row.platform === 'other' && row.label.trim() ? row.label.trim() : platformName;
  }

  protected openPicker(): void {
    this.picking.set(true);
    this.focusLater('link-picker-first');
  }

  protected closePicker(): void {
    this.picking.set(false);
    this.focusLater('link-add');
  }

  protected add(platform: LinkPlatform): void {
    if (this.rows().length >= MAX_LINKS || this.taken().has(platform)) return;
    const row: LinkRow = { id: nextRowId++, platform, url: '', label: '' };
    this.rows.update((rows) => [...rows, row]);
    this.picking.set(false);
    // Other asks for its name first, then the link.
    this.focusLater(`link-${row.id}-${platform === 'other' ? 'label' : 'url'}`);
  }

  protected remove(index: number): void {
    const rows = this.rows();
    const next = rows[index + 1] ?? rows[index - 1];
    this.rows.set(rows.filter((_, i) => i !== index));
    this.focusLater(next ? `link-${next.id}-url` : 'link-add');
  }

  protected move(index: number, step: -1 | 1, button: 'up' | 'down'): void {
    const rows = [...this.rows()];
    const target = index + step;
    if (target < 0 || target >= rows.length) return;
    [rows[index], rows[target]] = [rows[target], rows[index]];
    this.rows.set(rows);
    // Keep the focus on the moved row's button; at an end of the list, on its other button.
    const moved = rows[target];
    const atEnd = target === 0 || target === rows.length - 1;
    const id = atEnd ? (button === 'up' ? 'down' : 'up') : button;
    this.focusLater(`link-${moved.id}-${id}`);
  }

  protected patch(index: number, patch: Partial<LinkDraft>): void {
    this.rows.update((rows) => rows.map((row, i) => (i === index ? { ...row, ...patch } : row)));
  }

  /** "github.com/mona" becomes "https://github.com/mona" when the field is left. */
  protected tidy(index: number): void {
    const row = this.rows()[index];
    if (!row) return;
    const url = normalizeLinkUrl(row.url);
    if (url !== row.url) this.patch(index, { url });
  }

  private focusLater(id: string): void {
    afterNextRender(() => this.document.getElementById(id)?.focus(), { injector: this.injector });
  }
}

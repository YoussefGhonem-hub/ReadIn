import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { ADMIN_CARD, AdminPageHeader, oneOf } from '../admin-ui';
import { FieldsTab } from './fields-tab';
import { TagsTab } from './tags-tab';

const TABS = ['fields', 'tags'] as const;

/**
 * Taxonomy & Tags (F23, `taxonomy.manage`, web only), `/admin/taxonomy?tab=fields|tags`: fields and their topics (add,
 * rename in both languages, reorder, disable or enable; slugs never change, nothing is deleted) and tags (rename, merge,
 * hide, F32).
 */
@Component({
  selector: 'rd-admin-taxonomy-page',
  imports: [RouterLink, TranslocoPipe, AdminPageHeader, FieldsTab, TagsTab],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-admin-taxonomy': '' },
  template: `
    <rd-admin-page-header [title]="'admin.nav.taxonomy' | transloco" [subtitle]="'admin.taxonomy.subtitle' | transloco" />
    <div [class]="card">
      <nav class="flex gap-5 border-b border-border px-4" [attr.aria-label]="'admin.nav.taxonomy' | transloco" data-taxonomy-tabs>
        @for (t of tabs; track t) {
          <a
            routerLink="/admin/taxonomy"
            [queryParams]="t === 'fields' ? {} : { tab: t }"
            class="-mb-px inline-flex min-h-11 items-center border-b-2 px-1 text-sm no-underline"
            [class]="current() === t ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary hover:text-text-primary'"
            [attr.aria-current]="current() === t ? 'page' : null"
            [attr.data-taxonomy-tab]="t"
            >{{ 'admin.taxonomy.tab.' + t | transloco }}</a
          >
        }
      </nav>
      @if (current() === 'fields') {
        <rd-admin-fields-tab />
      } @else {
        <rd-admin-tags-tab [q]="q()" [status]="status()" [origin]="origin()" [sort]="sort()" [page]="page()" />
      }
    </div>
  `,
})
export class AdminTaxonomyPage {
  // `?…` (component input binding)
  readonly tab = input<string | undefined>();
  readonly q = input<string | undefined>();
  readonly status = input<string | undefined>();
  readonly origin = input<string | undefined>();
  readonly sort = input<string | undefined>();
  readonly page = input<string | undefined>();

  protected readonly card = ADMIN_CARD;
  protected readonly tabs = TABS;
  protected readonly current = computed(() => oneOf(this.tab(), TABS) ?? 'fields');
}

import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { AdminApi } from '../../../core/api/admin.api';
import { isApiError } from '../../../core/api/api.config';
import { AdminFieldDto, AdminTaxonomyDto, AdminTopicDto } from '../../../core/api/models';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { LanguageService } from '../../../core/i18n/language.service';
import { PluralPipe } from '../../../shared/pipes/format.pipes';
import { translatePlural } from '../../../shared/pipes/intl';
import { BottomSheet } from '../../../shared/ui/bottom-sheet';
import { FieldIcon } from '../../../shared/ui/field-icon';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { fieldColorOf } from '../../search/search-query';
import { AdminConfirm } from '../admin-ui';
import { provideAdminIcons } from '../admin-icons';

/** kebab-case, 2–64 characters (contract: `validation.slug`). */
export const SLUG = /^[a-z0-9]+(-[a-z0-9]+)*$/;
export const NAME_MAX = 100;

/** The field or topic being added or edited. */
export interface TaxonomyDraft {
  kind: 'field' | 'topic';
  /** Editing this row; null: a new one. */
  id: string | null;
  fieldId: string | null;
  slug: string;
  nameAr: string;
  nameEn: string;
  icon: string;
  color: string;
  isSensitive: boolean;
  requiresSources: boolean;
  isEnabled: boolean;
  /** What disabling would hide (edits only). */
  articleCount: number;
  /** Enabled when the form opened (disabling it asks first). */
  wasEnabled: boolean;
}

/** Moves the item at `index` by `by` (−1 up, +1 down); the same array when it can't move. */
export function move<T>(items: readonly T[], index: number, by: -1 | 1): T[] {
  const to = index + by;
  if (to < 0 || to >= items.length) return [...items];
  const next = [...items];
  [next[index], next[to]] = [next[to], next[index]];
  return next;
}

/**
 * Fields and topics (F23): every field in display order (disabled ones too), each with its icon and color, both names,
 * its slug and articles; Up / Down reorder (the whole order is saved), Edit, and its topics (add, edit, reorder,
 * disable). Fields from `content/taxonomy.yaml` can be renamed and disabled, never deleted; the first console change
 * marks a row customized, and the seeder leaves it alone from then on. Disabling asks first, with what it hides.
 */
@Component({
  selector: 'rd-admin-fields-tab',
  imports: [TranslocoPipe, LucideDynamicIcon, PluralPipe, BottomSheet, FieldIcon, EmptyState, ErrorState, AdminConfirm],
  providers: [provideAdminIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-fields-tab': '' },
  template: `
    <div class="flex flex-wrap items-center justify-between gap-2 border-b border-border p-4">
      <p class="m-0 text-sm text-text-secondary">{{ 'admin.taxonomy.fieldsHint' | transloco }}</p>
      <button type="button" class="rd-btn rd-btn-primary min-h-11 px-4" [disabled]="!data()" (click)="newField()" data-add-field>
        <svg lucideIcon="Plus" [size]="16" aria-hidden="true"></svg>
        {{ 'admin.taxonomy.addField' | transloco }}
      </button>
    </div>

    @switch (status()) {
      @case ('error') {
        <rd-error-state [message]="'admin.loadError' | transloco" (retry)="load()" />
      }
      @case ('loaded') {
        @if (fields().length) {
          <ol class="m-0 list-none divide-y divide-border p-0" data-fields-list>
            @for (f of fields(); track f.id; let i = $index; let last = $last) {
              <li class="px-4 py-3" [attr.data-field-row]="f.slug" [attr.data-enabled]="f.isEnabled">
                <div class="flex flex-wrap items-center gap-3">
                  <span
                    class="grid h-10 w-10 shrink-0 place-items-center rounded-full"
                    [style.background-color]="'color-mix(in srgb, ' + color(f.color) + ' 14%, transparent)'"
                    [style.color]="color(f.color)"
                    aria-hidden="true"
                  >
                    <rd-field-icon [name]="f.icon" [size]="18" />
                  </span>
                  <div class="min-w-0 flex-1">
                    <p class="m-0 font-semibold" [class.text-text-secondary]="!f.isEnabled">
                      <span lang="ar" dir="rtl">{{ f.nameAr }}</span> · <span lang="en" dir="ltr">{{ f.nameEn }}</span>
                    </p>
                    <p class="m-0 flex flex-wrap items-center gap-1.5 text-xs text-text-secondary">
                      <bdi dir="ltr">{{ f.slug }}</bdi>
                      · {{ articlesLabel(f.articleCount) }}
                      @if (!f.isEnabled) {
                        <span class="rd-tag bg-callout-warning text-text-primary">{{ 'admin.taxonomy.disabled' | transloco }}</span>
                      }
                      @if (f.isSensitive) {
                        <span class="rd-tag rd-tag-neutral">{{ 'admin.taxonomy.sensitive' | transloco }}</span>
                      }
                      @if (f.requiresSources) {
                        <span class="rd-tag rd-tag-neutral">{{ 'admin.taxonomy.requiresSources' | transloco }}</span>
                      }
                      @if (f.inTaxonomyFile) {
                        <span class="rd-tag rd-tag-neutral" [title]="'admin.taxonomy.fromFileHint' | transloco">{{ 'admin.taxonomy.fromFile' | transloco }}</span>
                      }
                      @if (f.customizedAt) {
                        <span class="rd-tag rd-tag-neutral" [title]="'admin.taxonomy.customizedHint' | transloco">{{ 'admin.taxonomy.customized' | transloco }}</span>
                      }
                    </p>
                  </div>
                  <div class="flex shrink-0 gap-1">
                    <button type="button" class="rd-icon-btn h-10 w-10" [disabled]="i === 0 || busy()" [attr.aria-label]="'admin.moveUp' | transloco" (click)="moveField(i, -1)" data-field-up>
                      <svg lucideIcon="ArrowUp" [size]="16" aria-hidden="true"></svg>
                    </button>
                    <button type="button" class="rd-icon-btn h-10 w-10" [disabled]="last || busy()" [attr.aria-label]="'admin.moveDown' | transloco" (click)="moveField(i, 1)" data-field-down>
                      <svg lucideIcon="ArrowDown" [size]="16" aria-hidden="true"></svg>
                    </button>
                    <button type="button" class="rd-btn rd-btn-outline min-h-10 px-3 text-sm" (click)="editField(f)" data-field-edit>{{ 'admin.edit' | transloco }}</button>
                    <button
                      type="button"
                      class="rd-btn rd-btn-ghost min-h-10 px-3 text-sm"
                      [attr.aria-expanded]="open().has(f.id)"
                      [attr.aria-controls]="'topics-' + f.id"
                      (click)="toggle(f.id)"
                      data-field-topics
                    >
                      {{ f.topics.length | rdPlural: 'admin.taxonomy.topicsCount' : lang() }}
                      <svg lucideIcon="ChevronDown" [size]="16" [class.rotate-180]="open().has(f.id)" aria-hidden="true"></svg>
                    </button>
                  </div>
                </div>

                @if (open().has(f.id)) {
                  <div [id]="'topics-' + f.id" class="mt-3 rounded-md border border-border" data-topics>
                    <ol class="m-0 list-none divide-y divide-border p-0">
                      @for (t of f.topics; track t.id; let ti = $index; let tlast = $last) {
                        <li class="flex flex-wrap items-center gap-2 px-3 py-2 text-sm" [attr.data-topic-row]="t.slug" [attr.data-enabled]="t.isEnabled">
                          <span class="min-w-0 flex-1" [class.text-text-secondary]="!t.isEnabled">
                            <span lang="ar" dir="rtl">{{ t.nameAr }}</span> · <span lang="en" dir="ltr">{{ t.nameEn }}</span>
                            <span class="block text-xs text-text-secondary">
                              <bdi dir="ltr">{{ t.slug }}</bdi> · {{ articlesLabel(t.articleCount) }}
                              @if (!t.isEnabled) {
                                · {{ 'admin.taxonomy.disabled' | transloco }}
                              }
                            </span>
                          </span>
                          <button type="button" class="rd-icon-btn h-9 w-9" [disabled]="ti === 0 || busy()" [attr.aria-label]="'admin.moveUp' | transloco" (click)="moveTopic(f, ti, -1)" data-topic-up>
                            <svg lucideIcon="ArrowUp" [size]="14" aria-hidden="true"></svg>
                          </button>
                          <button type="button" class="rd-icon-btn h-9 w-9" [disabled]="tlast || busy()" [attr.aria-label]="'admin.moveDown' | transloco" (click)="moveTopic(f, ti, 1)" data-topic-down>
                            <svg lucideIcon="ArrowDown" [size]="14" aria-hidden="true"></svg>
                          </button>
                          <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-xs" (click)="editTopic(t)" data-topic-edit>{{ 'admin.edit' | transloco }}</button>
                        </li>
                      } @empty {
                        <li class="px-3 py-2 text-sm text-text-secondary">{{ 'admin.taxonomy.noTopics' | transloco }}</li>
                      }
                    </ol>
                    <div class="border-t border-border p-2">
                      <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-3 text-sm" (click)="newTopic(f)" data-add-topic>
                        <svg lucideIcon="Plus" [size]="14" aria-hidden="true"></svg>
                        {{ 'admin.taxonomy.addTopic' | transloco }}
                      </button>
                    </div>
                  </div>
                }
              </li>
            }
          </ol>
        } @else {
          <rd-empty-state [title]="'admin.taxonomy.noFields' | transloco" />
        }
      }
      @default {
        <div class="flex flex-col gap-3 p-4" aria-busy="true" data-fields-loading>
          @for (i of [1, 2, 3, 4]; track i) {
            <div class="rd-skeleton h-12 w-full" aria-hidden="true"></div>
          }
        </div>
      }
    }

    <!-- Add or edit a field or a topic -->
    <rd-bottom-sheet [open]="!!draft()" labelledBy="taxonomy-form-title" [dismissible]="!saving()" (closed)="closeForm()">
      @if (draft(); as d) {
        <form class="flex flex-col gap-3 pt-1" (submit)="save($event)" data-taxonomy-form [attr.data-kind]="d.kind">
          <h2 id="taxonomy-form-title" class="m-0 pe-10 text-xl font-semibold">{{ formTitle() | transloco }}</h2>
          <div>
            <label for="tax-slug" class="rd-label">{{ 'admin.taxonomy.slug' | transloco }}</label>
            <input
              id="tax-slug"
              class="rd-input"
              dir="ltr"
              maxlength="64"
              autocomplete="off"
              [value]="d.slug"
              [disabled]="!!d.id || saving()"
              [attr.aria-invalid]="slugError() ? true : null"
              aria-describedby="tax-slug-hint"
              (input)="patch({ slug: $any($event.target).value.trim() })"
              data-tax-slug
            />
            <p id="tax-slug-hint" class="rd-field-hint">{{ (d.id ? 'admin.taxonomy.slugFixed' : 'admin.taxonomy.slugHint') | transloco }}</p>
          </div>
          <div>
            <label for="tax-name-ar" class="rd-label">{{ 'admin.taxonomy.nameAr' | transloco }}</label>
            <input id="tax-name-ar" class="rd-input" dir="rtl" lang="ar" [attr.maxlength]="nameMax" [value]="d.nameAr" [disabled]="saving()" (input)="patch({ nameAr: $any($event.target).value })" data-tax-name-ar />
          </div>
          <div>
            <label for="tax-name-en" class="rd-label">{{ 'admin.taxonomy.nameEn' | transloco }}</label>
            <input id="tax-name-en" class="rd-input" dir="ltr" lang="en" [attr.maxlength]="nameMax" [value]="d.nameEn" [disabled]="saving()" (input)="patch({ nameEn: $any($event.target).value })" data-tax-name-en />
          </div>
          @if (d.kind === 'field') {
            <div class="flex flex-wrap gap-3">
              <label class="flex min-w-40 flex-1 flex-col gap-1">
                <span class="rd-label m-0">{{ 'admin.taxonomy.icon' | transloco }}</span>
                <span class="flex items-center gap-2">
                  <rd-field-icon [name]="d.icon" [size]="20" />
                  <select class="rd-input flex-1" dir="ltr" [value]="d.icon" [disabled]="saving()" (change)="patch({ icon: $any($event.target).value })" data-tax-icon>
                    @for (icon of data()?.icons ?? []; track icon) {
                      <option [value]="icon">{{ icon }}</option>
                    }
                  </select>
                </span>
              </label>
              <label class="flex min-w-40 flex-1 flex-col gap-1">
                <span class="rd-label m-0">{{ 'admin.taxonomy.color' | transloco }}</span>
                <span class="flex items-center gap-2">
                  <span class="h-6 w-6 shrink-0 rounded-full" [style.background-color]="color(d.color)" aria-hidden="true"></span>
                  <select class="rd-input flex-1" dir="ltr" [value]="d.color" [disabled]="saving()" (change)="patch({ color: $any($event.target).value })" data-tax-color>
                    @for (c of data()?.colors ?? []; track c) {
                      <option [value]="c">{{ c }}</option>
                    }
                  </select>
                </span>
              </label>
            </div>
            <label class="flex min-h-10 items-center gap-2 text-sm">
              <input type="checkbox" class="h-4 w-4" [checked]="d.isSensitive" [disabled]="saving()" (change)="patch({ isSensitive: $any($event.target).checked })" data-tax-sensitive />
              {{ 'admin.taxonomy.sensitiveLabel' | transloco }}
            </label>
            <label class="flex min-h-10 items-center gap-2 text-sm">
              <input type="checkbox" class="h-4 w-4" [checked]="d.requiresSources" [disabled]="saving()" (change)="patch({ requiresSources: $any($event.target).checked })" data-tax-sources />
              {{ 'admin.taxonomy.requiresSourcesLabel' | transloco }}
            </label>
          }
          <label class="flex min-h-10 items-center gap-2 text-sm">
            <input type="checkbox" class="h-4 w-4" [checked]="d.isEnabled" [disabled]="saving()" (change)="patch({ isEnabled: $any($event.target).checked })" data-tax-enabled />
            {{ 'admin.taxonomy.enabledLabel' | transloco }}
          </label>
          @if (formError()) {
            <p class="rd-alert rd-alert-error m-0" role="alert" data-taxonomy-error>{{ formError() }}</p>
          }
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="saving()" (click)="closeForm()">{{ 'common.cancel' | transloco }}</button>
            <button type="submit" class="rd-btn rd-btn-primary flex-1" [disabled]="!canSave()" [attr.aria-busy]="saving()" data-taxonomy-save>
              @if (saving()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ 'common.save' | transloco }}
            </button>
          </div>
        </form>
      }
    </rd-bottom-sheet>

    <!-- Disabling asks first -->
    <rd-admin-confirm
      [open]="confirmDisable()"
      [title]="(draft()?.kind === 'topic' ? 'admin.taxonomy.disableTopic.title' : 'admin.taxonomy.disableField.title') | transloco"
      [body]="disableBody()"
      [danger]="true"
      [busy]="saving()"
      [error]="formError()"
      (confirmed)="submit()"
      (closed)="confirmDisable.set(false)"
    />
  `,
})
export class FieldsTab {
  private readonly api = inject(AdminApi);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  protected readonly nameMax = NAME_MAX;
  protected readonly color = fieldColorOf;
  protected readonly status = signal<'loading' | 'loaded' | 'error'>('loading');
  protected readonly data = signal<AdminTaxonomyDto | null>(null);
  protected readonly fields = computed(() => this.data()?.fields ?? []);
  protected readonly open = signal<ReadonlySet<string>>(new Set());
  protected readonly busy = signal(false);
  protected readonly draft = signal<TaxonomyDraft | null>(null);
  protected readonly saving = signal(false);
  protected readonly formError = signal<string | null>(null);
  protected readonly confirmDisable = signal(false);

  protected readonly formTitle = computed(() => {
    const d = this.draft();
    if (!d) return '';
    return `admin.taxonomy.${d.id ? 'edit' : 'add'}${d.kind === 'field' ? 'Field' : 'Topic'}`;
  });
  protected readonly slugError = computed(() => {
    const d = this.draft();
    return !!d && !d.id && d.slug.length > 0 && !this.slugValid(d.slug);
  });
  protected readonly canSave = computed(() => {
    const d = this.draft();
    if (!d || this.saving()) return false;
    const names = d.nameAr.trim().length > 0 && d.nameEn.trim().length > 0 && d.nameAr.trim().length <= NAME_MAX && d.nameEn.trim().length <= NAME_MAX;
    return names && (!!d.id || this.slugValid(d.slug));
  });
  protected readonly disableBody = computed(() => {
    const d = this.draft();
    if (!d) return '';
    return translatePlural(this.transloco, `admin.taxonomy.${d.kind === 'topic' ? 'disableTopic' : 'disableField'}.body`, d.articleCount, this.lang());
  });

  constructor() {
    void this.load();
  }

  async load(): Promise<void> {
    if (!this.data()) this.status.set('loading');
    try {
      this.data.set(await firstValueFrom(this.api.taxonomy()));
      this.status.set('loaded');
    } catch {
      if (!this.data()) this.status.set('error');
    }
  }

  protected articlesLabel(count: number): string {
    return translatePlural(this.transloco, 'admin.taxonomy.articles', count, this.lang());
  }

  protected toggle(id: string): void {
    const next = new Set(this.open());
    if (next.has(id)) next.delete(id);
    else next.add(id);
    this.open.set(next);
  }

  protected async moveField(index: number, by: -1 | 1): Promise<void> {
    const data = this.data();
    if (!data || this.busy()) return;
    const fields = move(data.fields, index, by);
    this.data.set({ ...data, fields });
    await this.saveOrder(() => this.api.reorderFields(fields.map((f) => f.id)));
  }

  protected async moveTopic(field: AdminFieldDto, index: number, by: -1 | 1): Promise<void> {
    const data = this.data();
    if (!data || this.busy()) return;
    const topics = move(field.topics, index, by);
    this.data.set({ ...data, fields: data.fields.map((f) => (f.id === field.id ? { ...f, topics } : f)) });
    await this.saveOrder(() => this.api.reorderTopics(field.id, topics.map((t) => t.id)));
  }

  private async saveOrder(request: () => ReturnType<AdminApi['reorderFields']>): Promise<void> {
    this.busy.set(true);
    try {
      await firstValueFrom(request());
    } catch (error) {
      this.toasts.error(this.errors.forError(error));
      await this.load();
    } finally {
      this.busy.set(false);
    }
  }

  protected newField(): void {
    const data = this.data();
    this.openForm({
      kind: 'field',
      id: null,
      fieldId: null,
      slug: '',
      nameAr: '',
      nameEn: '',
      icon: data?.icons[0] ?? 'book-open',
      color: data?.colors[0] ?? 'primary',
      isSensitive: false,
      requiresSources: false,
      isEnabled: true,
      articleCount: 0,
      wasEnabled: true,
    });
  }

  protected editField(f: AdminFieldDto): void {
    this.openForm({ kind: 'field', id: f.id, fieldId: null, slug: f.slug, nameAr: f.nameAr, nameEn: f.nameEn, icon: f.icon, color: f.color, isSensitive: f.isSensitive, requiresSources: f.requiresSources, isEnabled: f.isEnabled, articleCount: f.articleCount, wasEnabled: f.isEnabled });
  }

  protected newTopic(f: AdminFieldDto): void {
    this.openForm({ kind: 'topic', id: null, fieldId: f.id, slug: '', nameAr: '', nameEn: '', icon: '', color: '', isSensitive: false, requiresSources: false, isEnabled: true, articleCount: 0, wasEnabled: true });
  }

  protected editTopic(t: AdminTopicDto): void {
    this.openForm({ kind: 'topic', id: t.id, fieldId: t.fieldId, slug: t.slug, nameAr: t.nameAr, nameEn: t.nameEn, icon: '', color: '', isSensitive: false, requiresSources: false, isEnabled: t.isEnabled, articleCount: t.articleCount, wasEnabled: t.isEnabled });
  }

  private openForm(draft: TaxonomyDraft): void {
    this.formError.set(null);
    this.draft.set(draft);
  }

  protected patch(change: Partial<TaxonomyDraft>): void {
    const d = this.draft();
    if (d) this.draft.set({ ...d, ...change });
  }

  protected closeForm(): void {
    if (!this.saving()) {
      this.draft.set(null);
      this.confirmDisable.set(false);
    }
  }

  protected save(event: Event): void {
    event.preventDefault();
    const d = this.draft();
    if (!d || !this.canSave()) return;
    // Disabling a row that readers see asks first, with what it hides.
    if (d.id && d.wasEnabled && !d.isEnabled) {
      this.formError.set(null);
      this.confirmDisable.set(true);
      return;
    }
    void this.submit();
  }

  async submit(): Promise<void> {
    const d = this.draft();
    if (!d || this.saving()) return;
    this.saving.set(true);
    this.formError.set(null);
    const names = { nameAr: d.nameAr.trim(), nameEn: d.nameEn.trim() };
    try {
      if (d.kind === 'field') {
        const body = { ...names, icon: d.icon, color: d.color, isSensitive: d.isSensitive, requiresSources: d.requiresSources, isEnabled: d.isEnabled };
        await firstValueFrom(d.id ? this.api.updateField(d.id, body) : this.api.createField({ slug: d.slug, ...body }));
      } else {
        const body = { ...names, isEnabled: d.isEnabled };
        await firstValueFrom(d.id ? this.api.updateTopic(d.id, body) : this.api.createTopic({ fieldId: d.fieldId!, slug: d.slug, ...body }));
        if (d.fieldId && !this.open().has(d.fieldId)) this.toggle(d.fieldId);
      }
      this.toasts.success(this.transloco.translate('admin.saved'));
      this.saving.set(false);
      this.confirmDisable.set(false);
      this.draft.set(null);
      await this.load();
    } catch (error) {
      this.formError.set(this.message(error));
    } finally {
      this.saving.set(false);
    }
  }

  private slugValid(slug: string): boolean {
    return slug.length >= 2 && slug.length <= 64 && SLUG.test(slug);
  }

  /** A validation failure names its first field code (e.g. `validation.slug`, `field.icon_invalid`). */
  private message(error: unknown): string {
    if (isApiError(error) && error.code === 'validation.failed') {
      const first = Object.values(error.validationErrors).flat()[0];
      if (first) return this.errors.forCode(first);
    }
    return this.errors.forError(error);
  }
}

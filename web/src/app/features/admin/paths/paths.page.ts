import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { AdminApi } from '../../../core/api/admin.api';
import { isApiError } from '../../../core/api/api.config';
import { AdminArticleRowDto, AdminPathDto, FieldDto, UpsertPathRequest } from '../../../core/api/models';
import { TaxonomyApi } from '../../../core/api/taxonomy.api';
import { SessionStore } from '../../../core/auth/session.store';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { LanguageService } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { isolate } from '../../../shared/directives/bidi';
import { PluralPipe } from '../../../shared/pipes/format.pipes';
import { BottomSheet } from '../../../shared/ui/bottom-sheet';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { ADMIN_CARD, AdminConfirm, AdminPageHeader } from '../admin-ui';
import { move } from '../taxonomy/fields-tab';
import { ArticlePicker, PickedArticle } from './article-picker';
import { provideAdminIcons } from '../admin-icons';

/** Path slugs: kebab-case, 3–100 (contract: `validation.slug`). */
const PATH_SLUG = /^[a-z0-9]+(-[a-z0-9]+)*$/;
/** Featured paths on Explore (contract: 0–20). */
export const MAX_FEATURED_PATHS = 20;
/** A path's articles (contract: 1–100). */
export const MAX_PATH_ITEMS = 100;

export type PathForm = UpsertPathRequest & { id: string | null };

/**
 * Paths & Featured (F23, web only), `/admin/paths`: the learning paths (`paths.manage`, over the F09 path admin API):
 * create, edit, set and order their articles, publish or unpublish and delete; editorial paths (from
 * `content/taxonomy.yaml`) stay read-only. Then the featured lists (`articles.feature`): which paths Explore features,
 * in order (saved as a whole), and the featured articles with Unfeature.
 */
@Component({
  selector: 'rd-admin-paths-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, PluralPipe, BottomSheet, EmptyState, ErrorState, AdminConfirm, AdminPageHeader, ArticlePicker],
  providers: [provideAdminIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col gap-2', 'data-admin-paths': '' },
  template: `
    <rd-admin-page-header [title]="'admin.nav.paths' | transloco" [subtitle]="'admin.paths.subtitle' | transloco">
      @if (canManage()) {
        <button type="button" class="rd-btn rd-btn-primary min-h-11 px-4" [disabled]="status() !== 'loaded'" (click)="newPath()" data-add-path>
          <svg lucideIcon="Plus" [size]="16" aria-hidden="true"></svg>
          {{ 'admin.paths.add' | transloco }}
        </button>
      }
    </rd-admin-page-header>

    @if (canManage()) {
      <section [class]="card" aria-labelledby="paths-title" data-paths>
        <h2 id="paths-title" class="m-0 px-4 pb-1 pt-4 text-base font-semibold">{{ 'admin.paths.title' | transloco }}</h2>
        @switch (status()) {
          @case ('error') {
            <rd-error-state [message]="'admin.loadError' | transloco" (retry)="load()" />
          }
          @case ('loaded') {
            @if (paths().length) {
              <ol class="m-0 list-none divide-y divide-border p-0" data-paths-list>
                @for (p of paths(); track p.id) {
                  <li class="flex flex-wrap items-center gap-3 px-4 py-3" [attr.data-path-row]="p.slug">
                    <div class="min-w-0 flex-1">
                      <p class="m-0 font-semibold">
                        @if (p.isPublished) {
                          <a [routerLink]="['/paths', p.slug]" class="text-text-primary no-underline hover:underline"><bdi dir="auto">{{ titleOf(p) }}</bdi></a>
                        } @else {
                          <bdi dir="auto">{{ titleOf(p) }}</bdi>
                        }
                      </p>
                      <p class="m-0 flex flex-wrap items-center gap-1.5 text-xs text-text-secondary">
                        <bdi dir="ltr">{{ p.slug }}</bdi> · {{ fieldName(p.fieldId) }} · {{ p.articleIds.length | rdPlural: 'admin.paths.itemsCount' : lang() }} ·
                        {{ p.enrollmentCount | rdPlural: 'admin.paths.enrolled' : lang() }}
                        <span class="rd-tag" [class]="p.isPublished ? 'rd-tag-accent' : 'rd-tag-neutral'">{{ (p.isPublished ? 'admin.paths.published' : 'admin.paths.unpublished') | transloco }}</span>
                        @if (p.isEditorial) {
                          <span class="rd-tag rd-tag-neutral" [title]="'admin.paths.editorialHint' | transloco" data-editorial>{{ 'admin.paths.editorial' | transloco }}</span>
                        }
                        @if (p.isFeatured) {
                          <span class="rd-tag rd-tag-accent">{{ 'admin.paths.featuredAt' | transloco: { order: p.featuredOrder } }}</span>
                        }
                      </p>
                    </div>
                    @if (!p.isEditorial) {
                      <div class="flex flex-wrap gap-1">
                        <button type="button" class="rd-btn rd-btn-outline min-h-10 px-3 text-sm" (click)="editPath(p)" data-path-edit>{{ 'admin.edit' | transloco }}</button>
                        <button type="button" class="rd-btn rd-btn-outline min-h-10 px-3 text-sm" (click)="openItems(p)" data-path-items>{{ 'admin.paths.articles' | transloco }}</button>
                        <button type="button" class="rd-btn rd-btn-ghost min-h-10 px-3 text-sm" [disabled]="busy()" (click)="setPublished(p, !p.isPublished)" data-path-publish>
                          {{ (p.isPublished ? 'admin.paths.unpublish' : 'admin.paths.publish') | transloco }}
                        </button>
                        <button type="button" class="rd-btn rd-btn-ghost min-h-10 px-3 text-sm text-error" (click)="deleting.set(p)" data-path-delete>{{ 'admin.delete' | transloco }}</button>
                      </div>
                    }
                  </li>
                }
              </ol>
            } @else {
              <rd-empty-state [title]="'admin.paths.empty' | transloco" />
            }
          }
          @default {
            <div class="flex flex-col gap-3 p-4" aria-busy="true" data-paths-loading>
              @for (i of [1, 2, 3]; track i) {
                <div class="rd-skeleton h-12 w-full" aria-hidden="true"></div>
              }
            </div>
          }
        }
      </section>
    }

    <!-- Featured paths, in Explore's order -->
    @if (canFeature() && status() === 'loaded') {
      <section [class]="card + ' p-4'" aria-labelledby="featured-paths-title" data-featured-paths>
        <h2 id="featured-paths-title" class="m-0 text-base font-semibold">{{ 'admin.paths.featuredTitle' | transloco }}</h2>
        <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'admin.paths.featuredHint' | transloco: { max: maxFeatured } }}</p>
        <ol class="m-0 mt-3 flex list-none flex-col gap-1 p-0">
          @for (id of featured(); track id; let i = $index; let last = $last) {
            <li class="flex items-center gap-2 rounded-md bg-surface-variant px-3 py-1.5 text-sm" [attr.data-featured-path]="id">
              <span class="w-5 tabular-nums text-text-secondary">{{ i + 1 }}</span>
              <bdi dir="auto" class="min-w-0 flex-1 truncate">{{ titleById(id) }}</bdi>
              <button type="button" class="rd-icon-btn h-9 w-9" [disabled]="i === 0" [attr.aria-label]="'admin.moveUp' | transloco" (click)="featured.set(move(featured(), i, -1))">
                <svg lucideIcon="ArrowUp" [size]="14" aria-hidden="true"></svg>
              </button>
              <button type="button" class="rd-icon-btn h-9 w-9" [disabled]="last" [attr.aria-label]="'admin.moveDown' | transloco" (click)="featured.set(move(featured(), i, 1))">
                <svg lucideIcon="ArrowDown" [size]="14" aria-hidden="true"></svg>
              </button>
              <button type="button" class="rd-icon-btn h-9 w-9" [attr.aria-label]="'admin.remove' | transloco" (click)="removeFeatured(id)" data-featured-remove>
                <svg lucideIcon="X" [size]="14" aria-hidden="true"></svg>
              </button>
            </li>
          } @empty {
            <li class="text-sm text-text-secondary">{{ 'admin.paths.noFeatured' | transloco }}</li>
          }
        </ol>
        <div class="mt-3 flex flex-wrap items-center gap-2">
          <label for="add-featured" class="sr-only">{{ 'admin.paths.addFeatured' | transloco }}</label>
          <select id="add-featured" class="rd-input min-h-10 max-w-full flex-1 py-1" [disabled]="featured().length >= maxFeatured" (change)="addFeatured($any($event.target))" data-add-featured>
            <option value="">{{ 'admin.paths.addFeatured' | transloco }}</option>
            @for (p of notFeatured(); track p.id) {
              <option [value]="p.id">{{ titleOf(p) }}</option>
            }
          </select>
          <button type="button" class="rd-btn rd-btn-primary min-h-10 px-4" [disabled]="!featuredChanged() || busy()" (click)="saveFeatured()" data-save-featured>{{ 'common.save' | transloco }}</button>
        </div>
      </section>
    }

    <!-- Featured articles -->
    @if (canFeature() && session.hasPermission('moderation.manage')) {
      <section [class]="card" aria-labelledby="featured-articles-title" data-featured-articles>
        <div class="flex flex-wrap items-center justify-between gap-2 px-4 pt-4">
          <h2 id="featured-articles-title" class="m-0 text-base font-semibold">{{ 'admin.paths.featuredArticles' | transloco }}</h2>
          <a routerLink="/admin/content" [queryParams]="{ featured: 'true', sort: 'featured' }" class="text-sm text-link no-underline hover:underline">{{ 'admin.paths.allFeatured' | transloco }}</a>
        </div>
        <p class="m-0 px-4 pb-2 pt-1 text-sm text-text-secondary">{{ 'admin.paths.featuredArticlesHint' | transloco }}</p>
        @if (featuredArticles().length) {
          <ol class="m-0 list-none divide-y divide-border p-0">
            @for (a of featuredArticles(); track a.id) {
              <li class="flex items-center gap-3 px-4 py-2.5 text-sm" [attr.data-featured-article]="a.id">
                <a [routerLink]="['/admin/content', a.id]" class="min-w-0 flex-1 truncate font-semibold text-text-primary no-underline hover:underline" [attr.lang]="a.language"><rd-bdi-text [text]="a.title" /></a>
                @if (a.hiddenAt) {
                  <span class="rd-tag bg-callout-warning text-text-primary">{{ 'admin.content.hiddenTag' | transloco }}</span>
                }
                <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2 text-xs" [disabled]="busy()" (click)="unfeature(a)" data-unfeature>{{ 'admin.content.unfeature' | transloco }}</button>
              </li>
            }
          </ol>
        } @else {
          <p class="m-0 px-4 pb-4 text-sm text-text-secondary" data-no-featured-articles>{{ 'admin.paths.noFeaturedArticles' | transloco }}</p>
        }
      </section>
    }

    <!-- Create or edit a path -->
    <rd-bottom-sheet [open]="!!form()" labelledBy="path-form-title" [dismissible]="!busy()" (closed)="closeForm()">
      @if (form(); as f) {
        <form class="flex flex-col gap-3 pt-1" (submit)="savePath($event)" data-path-form>
          <h2 id="path-form-title" class="m-0 pe-10 text-xl font-semibold">{{ (f.id ? 'admin.paths.edit' : 'admin.paths.add') | transloco }}</h2>
          <div>
            <label for="path-slug" class="rd-label">{{ 'admin.taxonomy.slug' | transloco }}</label>
            <input id="path-slug" class="rd-input" dir="ltr" maxlength="100" [value]="f.slug" [disabled]="busy()" (input)="patchForm({ slug: $any($event.target).value.trim() })" data-path-slug />
            <p class="rd-field-hint">{{ 'admin.paths.slugHint' | transloco }}</p>
          </div>
          <div>
            <label for="path-field" class="rd-label">{{ 'admin.content.field' | transloco }}</label>
            <select id="path-field" class="rd-input" [value]="f.fieldId" [disabled]="busy()" (change)="patchForm({ fieldId: $any($event.target).value })" data-path-field>
              <option value="" disabled>{{ 'admin.paths.pickField' | transloco }}</option>
              @for (field of fields(); track field.id) {
                <option [value]="field.id">{{ lang() === 'ar' ? field.nameAr : field.nameEn }}</option>
              }
            </select>
          </div>
          <div>
            <label for="path-title-ar" class="rd-label">{{ 'admin.paths.titleAr' | transloco }}</label>
            <input id="path-title-ar" class="rd-input" dir="rtl" lang="ar" maxlength="200" [value]="f.titleAr" [disabled]="busy()" (input)="patchForm({ titleAr: $any($event.target).value })" data-path-title-ar />
          </div>
          <div>
            <label for="path-title-en" class="rd-label">{{ 'admin.paths.titleEn' | transloco }}</label>
            <input id="path-title-en" class="rd-input" dir="ltr" lang="en" maxlength="200" [value]="f.titleEn" [disabled]="busy()" (input)="patchForm({ titleEn: $any($event.target).value })" data-path-title-en />
          </div>
          <div>
            <label for="path-desc-ar" class="rd-label">{{ 'admin.paths.descriptionAr' | transloco }}</label>
            <textarea id="path-desc-ar" class="rd-input" dir="rtl" lang="ar" rows="2" maxlength="500" [value]="f.descriptionAr ?? ''" [disabled]="busy()" (input)="patchForm({ descriptionAr: $any($event.target).value })"></textarea>
          </div>
          <div>
            <label for="path-desc-en" class="rd-label">{{ 'admin.paths.descriptionEn' | transloco }}</label>
            <textarea id="path-desc-en" class="rd-input" dir="ltr" lang="en" rows="2" maxlength="500" [value]="f.descriptionEn ?? ''" [disabled]="busy()" (input)="patchForm({ descriptionEn: $any($event.target).value })"></textarea>
          </div>
          <div class="flex flex-wrap items-end gap-3">
            <label class="flex flex-col gap-1">
              <span class="rd-label m-0">{{ 'admin.paths.sortOrder' | transloco }}</span>
              <input type="number" min="0" class="rd-input w-28" dir="ltr" [value]="f.sortOrder" [disabled]="busy()" (input)="patchForm({ sortOrder: +$any($event.target).value })" data-path-order />
            </label>
            <label class="flex min-h-11 items-center gap-2 text-sm">
              <input type="checkbox" class="h-4 w-4" [checked]="f.isPublished" [disabled]="busy()" (change)="patchForm({ isPublished: $any($event.target).checked })" data-path-published />
              {{ 'admin.paths.publishedLabel' | transloco }}
            </label>
          </div>
          @if (error()) {
            <p class="rd-alert rd-alert-error m-0" role="alert" data-path-error>{{ error() }}</p>
          }
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="closeForm()">{{ 'common.cancel' | transloco }}</button>
            <button type="submit" class="rd-btn rd-btn-primary flex-1" [disabled]="!formValid() || busy()" data-path-save>{{ 'common.save' | transloco }}</button>
          </div>
        </form>
      }
    </rd-bottom-sheet>

    <!-- A path's articles, in order -->
    <rd-bottom-sheet [open]="!!itemsOf()" labelledBy="path-items-title" [dismissible]="!busy()" (closed)="closeItems()">
      @if (itemsOf(); as p) {
        <div class="flex flex-col gap-3 pt-1" data-path-items-editor>
          <h2 id="path-items-title" class="m-0 pe-10 text-xl font-semibold">{{ 'admin.paths.itemsTitle' | transloco: { title: isolate(titleOf(p)) } }}</h2>
          <ol class="m-0 flex list-none flex-col gap-1 p-0">
            @for (item of items(); track item.id; let i = $index; let last = $last) {
              <li class="flex items-center gap-2 rounded-md bg-surface-variant px-3 py-1.5 text-sm" [attr.data-path-item]="item.id">
                <span class="w-6 tabular-nums text-text-secondary">{{ i + 1 }}</span>
                <span class="min-w-0 flex-1 truncate" [attr.lang]="item.language">
                  @if (item.title) {
                    <rd-bdi-text [text]="item.title" />
                  } @else {
                    <bdi dir="ltr" class="text-text-secondary">{{ item.id }}</bdi>
                  }
                </span>
                <button type="button" class="rd-icon-btn h-9 w-9" [disabled]="i === 0" [attr.aria-label]="'admin.moveUp' | transloco" (click)="items.set(move(items(), i, -1))">
                  <svg lucideIcon="ArrowUp" [size]="14" aria-hidden="true"></svg>
                </button>
                <button type="button" class="rd-icon-btn h-9 w-9" [disabled]="last" [attr.aria-label]="'admin.moveDown' | transloco" (click)="items.set(move(items(), i, 1))">
                  <svg lucideIcon="ArrowDown" [size]="14" aria-hidden="true"></svg>
                </button>
                <button type="button" class="rd-icon-btn h-9 w-9" [attr.aria-label]="'admin.remove' | transloco" (click)="removeItem(item.id)" data-item-remove>
                  <svg lucideIcon="X" [size]="14" aria-hidden="true"></svg>
                </button>
              </li>
            } @empty {
              <li class="text-sm text-text-secondary">{{ 'admin.paths.noItems' | transloco }}</li>
            }
          </ol>
          @if (items().length < maxItems) {
            <rd-admin-article-picker [exclude]="itemIds()" (picked)="addItem($event)" />
          }
          @if (error()) {
            <p class="rd-alert rd-alert-error m-0" role="alert" data-path-error>{{ error() }}</p>
          }
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="closeItems()">{{ 'common.cancel' | transloco }}</button>
            <button type="button" class="rd-btn rd-btn-primary flex-1" [disabled]="!items().length || busy()" (click)="saveItems()" data-items-save>{{ 'common.save' | transloco }}</button>
          </div>
        </div>
      }
    </rd-bottom-sheet>

    <rd-admin-confirm
      [open]="!!deleting()"
      [title]="'admin.paths.deleteTitle' | transloco: { title: isolate(deleting() ? titleOf(deleting()!) : '') }"
      [body]="'admin.paths.deleteBody' | transloco"
      [danger]="true"
      [busy]="busy()"
      [error]="error()"
      (confirmed)="deletePath()"
      (closed)="deleting.set(null); error.set(null)"
    />
  `,
})
export class AdminPathsPage {
  private readonly api = inject(AdminApi);
  private readonly taxonomy = inject(TaxonomyApi);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  protected readonly session = inject(SessionStore);
  protected readonly lang = inject(LanguageService).lang;

  protected readonly card = ADMIN_CARD;
  protected readonly isolate = isolate;
  protected readonly move = move;
  protected readonly maxFeatured = MAX_FEATURED_PATHS;
  protected readonly maxItems = MAX_PATH_ITEMS;

  protected readonly canManage = computed(() => this.session.hasPermission('paths.manage'));
  protected readonly canFeature = computed(() => this.session.hasPermission('articles.feature'));
  protected readonly status = signal<'loading' | 'loaded' | 'error'>('loading');
  protected readonly paths = signal<AdminPathDto[]>([]);
  protected readonly fields = signal<FieldDto[]>([]);
  protected readonly featured = signal<string[]>([]);
  private readonly savedFeatured = signal<string[]>([]);
  protected readonly featuredArticles = signal<AdminArticleRowDto[]>([]);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly form = signal<PathForm | null>(null);
  protected readonly itemsOf = signal<AdminPathDto | null>(null);
  protected readonly items = signal<PickedArticle[]>([]);
  protected readonly deleting = signal<AdminPathDto | null>(null);

  protected readonly itemIds = computed(() => this.items().map((i) => i.id));
  protected readonly notFeatured = computed(() => this.paths().filter((p) => !this.featured().includes(p.id)));
  protected readonly featuredChanged = computed(() => this.featured().join() !== this.savedFeatured().join());
  protected readonly formValid = computed(() => {
    const f = this.form();
    if (!f) return false;
    const titles = [f.titleAr, f.titleEn].every((t) => t.trim().length >= 1 && t.trim().length <= 200);
    const descriptions = [f.descriptionAr, f.descriptionEn].every((d) => (d ?? '').trim().length <= 500);
    return titles && descriptions && !!f.fieldId && f.slug.length >= 3 && f.slug.length <= 100 && PATH_SLUG.test(f.slug) && Number.isInteger(f.sortOrder) && f.sortOrder >= 0;
  });

  constructor() {
    void this.load();
    void firstValueFrom(this.taxonomy.fields()).then(
      (fields) => this.fields.set(fields),
      () => undefined,
    );
    if (this.canFeature() && this.session.hasPermission('moderation.manage')) void this.loadFeaturedArticles();
  }

  async load(): Promise<void> {
    if (!this.canManage()) {
      this.status.set('loaded');
      return;
    }
    if (this.status() !== 'loaded') this.status.set('loading');
    try {
      const paths = await firstValueFrom(this.api.paths());
      this.paths.set(paths);
      const featured = paths
        .filter((p) => p.isFeatured)
        .sort((a, b) => (a.featuredOrder ?? 0) - (b.featuredOrder ?? 0))
        .map((p) => p.id);
      this.featured.set(featured);
      this.savedFeatured.set(featured);
      this.status.set('loaded');
    } catch {
      this.status.set('error');
    }
  }

  private async loadFeaturedArticles(): Promise<void> {
    try {
      const page = await firstValueFrom(this.api.articles({ featured: true, sort: 'featured', pageSize: 20 }));
      this.featuredArticles.set(page.items);
    } catch {
      this.featuredArticles.set([]);
    }
  }

  protected titleOf(p: AdminPathDto): string {
    return this.lang() === 'ar' ? p.titleAr : p.titleEn;
  }

  protected titleById(id: string): string {
    const p = this.paths().find((x) => x.id === id);
    return p ? this.titleOf(p) : id;
  }

  protected fieldName(id: string): string {
    const f = this.fields().find((x) => x.id === id);
    return f ? (this.lang() === 'ar' ? f.nameAr : f.nameEn) : '';
  }

  protected newPath(): void {
    this.error.set(null);
    this.form.set({ id: null, slug: '', fieldId: '', titleAr: '', titleEn: '', descriptionAr: '', descriptionEn: '', sortOrder: this.paths().length + 1, isPublished: false });
  }

  protected editPath(p: AdminPathDto): void {
    this.error.set(null);
    this.form.set({ id: p.id, ...this.requestOf(p) });
  }

  protected patchForm(change: Partial<PathForm>): void {
    const f = this.form();
    if (f) this.form.set({ ...f, ...change });
  }

  protected closeForm(): void {
    if (!this.busy()) this.form.set(null);
  }

  protected async savePath(event: Event): Promise<void> {
    event.preventDefault();
    const f = this.form();
    if (!f || !this.formValid() || this.busy()) return;
    const { id, ...request } = f;
    const body: UpsertPathRequest = {
      ...request,
      titleAr: request.titleAr.trim(),
      titleEn: request.titleEn.trim(),
      descriptionAr: request.descriptionAr?.trim() || null,
      descriptionEn: request.descriptionEn?.trim() || null,
    };
    await this.write(async () => {
      if (id) await firstValueFrom(this.api.updatePath(id, body));
      else await firstValueFrom(this.api.createPath(body));
      this.form.set(null);
    });
  }

  protected async setPublished(p: AdminPathDto, isPublished: boolean): Promise<void> {
    await this.write(() => firstValueFrom(this.api.updatePath(p.id, { ...this.requestOf(p), isPublished })));
  }

  protected async deletePath(): Promise<void> {
    const p = this.deleting();
    if (!p) return;
    await this.write(async () => {
      await firstValueFrom(this.api.deletePath(p.id));
      this.deleting.set(null);
    });
  }

  protected async openItems(p: AdminPathDto): Promise<void> {
    this.error.set(null);
    this.itemsOf.set(p);
    this.items.set(p.articleIds.map((id) => ({ id, title: null, language: null })));
    // The titles, one request each (the console's article route), in the background.
    const rows = await Promise.allSettled(p.articleIds.map((id) => firstValueFrom(this.api.article(id))));
    if (this.itemsOf()?.id !== p.id) return;
    const byId = new Map(rows.flatMap((r) => (r.status === 'fulfilled' ? [[r.value.id, r.value] as const] : [])));
    this.items.update((items) => items.map((item) => (item.title ? item : { ...item, title: byId.get(item.id)?.title ?? null, language: byId.get(item.id)?.language ?? null })));
  }

  protected closeItems(): void {
    if (!this.busy()) this.itemsOf.set(null);
  }

  protected addItem(article: PickedArticle): void {
    if (!this.items().some((i) => i.id === article.id)) this.items.update((items) => [...items, article]);
  }

  protected removeItem(id: string): void {
    this.items.update((items) => items.filter((i) => i.id !== id));
  }

  protected async saveItems(): Promise<void> {
    const p = this.itemsOf();
    if (!p) return;
    await this.write(async () => {
      await firstValueFrom(this.api.setPathItems(p.id, this.itemIds()));
      this.itemsOf.set(null);
    });
  }

  protected addFeatured(select: HTMLSelectElement): void {
    const id = select.value;
    select.value = '';
    if (id && !this.featured().includes(id) && this.featured().length < MAX_FEATURED_PATHS) this.featured.update((list) => [...list, id]);
  }

  protected removeFeatured(id: string): void {
    this.featured.update((list) => list.filter((x) => x !== id));
  }

  protected async saveFeatured(): Promise<void> {
    await this.write(() => firstValueFrom(this.api.setFeaturedPaths(this.featured())));
  }

  protected async unfeature(article: AdminArticleRowDto): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    try {
      await firstValueFrom(this.api.unfeature(article.id));
      this.featuredArticles.update((list) => list.filter((a) => a.id !== article.id));
      this.toasts.success(this.transloco.translate('admin.content.unfeaturedDone'));
    } catch (error) {
      if (isApiError(error) && error.code === 'article.not_found') this.featuredArticles.update((list) => list.filter((a) => a.id !== article.id));
      this.toasts.error(this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }

  private requestOf(p: AdminPathDto): UpsertPathRequest {
    return {
      slug: p.slug,
      fieldId: p.fieldId,
      titleAr: p.titleAr,
      titleEn: p.titleEn,
      descriptionAr: p.descriptionAr,
      descriptionEn: p.descriptionEn,
      sortOrder: p.sortOrder,
      isPublished: p.isPublished,
    };
  }

  /** Runs a write; then the list loads again. A failure stays in the open dialog, or shows as a toast. */
  private async write(run: () => Promise<unknown>): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      await run();
      this.toasts.success(this.transloco.translate('admin.saved'));
      await this.load();
    } catch (error) {
      const message = this.message(error);
      if (this.form() || this.itemsOf() || this.deleting()) this.error.set(message);
      else this.toasts.error(message);
    } finally {
      this.busy.set(false);
    }
  }

  private message(error: unknown): string {
    if (isApiError(error) && error.code === 'validation.failed') {
      const first = Object.values(error.validationErrors).flat()[0];
      if (first) return this.errors.forCode(first);
    }
    return this.errors.forError(error);
  }
}

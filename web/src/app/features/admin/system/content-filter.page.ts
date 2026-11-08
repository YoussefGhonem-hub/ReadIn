import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { AdminApi } from '../../../core/api/admin.api';
import { isApiError } from '../../../core/api/api.config';
import { CONTENT_FILTER_LEVELS, ContentFilterLevel, ContentFilterTermDto, ContentFilterTermInput, ContentFilterTestDto } from '../../../core/api/models';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { LanguageService } from '../../../core/i18n/language.service';
import { translatePlural } from '../../../shared/pipes/intl';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { ADMIN_CARD, AdminPageHeader } from '../admin-ui';
import { provideAdminIcons } from '../admin-icons';

type Language = 'ar' | 'en';
const LANGUAGES: readonly Language[] = ['ar', 'en'];
/** Contract: each term 2–100 characters (after normalization) with a letter; at most 5,000 terms. */
export const TERM_MAX = 100;
export const MAX_TERMS = 5000;

/** One editable row: the term as written, its list and level; `id` once saved. */
export interface FilterRow extends ContentFilterTermInput {
  id: string | null;
  source: 'file' | 'console' | null;
}

/** A term the browser can already refuse (the API checks it again after normalization). */
export function termProblem(term: string): 'length' | 'letter' | null {
  const text = term.trim();
  if (text.length < 2 || text.length > TERM_MAX) return 'length';
  return /\p{L}/u.test(text) ? null : 'letter';
}

/** The same term in the same list, ignoring case and spaces at the ends. */
const sameTerm = (a: string, b: string) => a.trim().toLocaleLowerCase() === b.trim().toLocaleLowerCase();

/**
 * The content filter (F37, `system.settings`), `/admin/system/content-filter`: the word lists by language (Arabic,
 * with Egyptian and Franco-Arabic spellings, and English) and level (Block: refused with `422 content.objectionable`;
 * Flag: published, with a system report to the moderation queue). Add, remove or move a term between levels, then Save:
 * the whole enabled list goes back (`PUT`, audited); a file term left out is disabled and the seeder never brings it
 * back. "Try a text" shows which level a text gets and the terms it matched. Changes reach the API without a release.
 */
@Component({
  selector: 'rd-admin-content-filter-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, EmptyState, ErrorState, AdminPageHeader],
  providers: [provideAdminIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col gap-2', 'data-admin-content-filter': '' },
  template: `
    <a routerLink="/admin/system" class="inline-flex min-h-11 items-center gap-1.5 text-sm text-text-secondary no-underline hover:text-text-primary" data-filter-back>
      <svg lucideIcon="ArrowLeft" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
      {{ 'admin.nav.system' | transloco }}
    </a>
    <rd-admin-page-header [title]="'admin.filter.title' | transloco" [subtitle]="'admin.filter.subtitle' | transloco">
      <button type="button" class="rd-btn rd-btn-primary min-h-11 px-4" [disabled]="!dirty() || saving() || tooMany()" [attr.aria-busy]="saving()" (click)="save()" data-filter-save>
        @if (saving()) {
          <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
        }
        {{ 'common.save' | transloco }}
      </button>
    </rd-admin-page-header>

    @switch (status()) {
      @case ('error') {
        <div [class]="card"><rd-error-state [message]="'admin.loadError' | transloco" (retry)="load()" /></div>
      }
      @case ('loaded') {
        @if (dirty()) {
          <p class="rd-alert rd-alert-info m-0" role="status" data-filter-unsaved>{{ 'admin.filter.unsaved' | transloco }}</p>
        }
        @if (saveError()) {
          <p class="rd-alert rd-alert-error m-0" role="alert" data-filter-error>{{ saveError() }}</p>
        }

        <!-- Try a text -->
        <section [class]="card + ' flex flex-col gap-2 p-4'" aria-labelledby="filter-test-title" data-filter-test>
          <h2 id="filter-test-title" class="m-0 text-base font-semibold">{{ 'admin.filter.test' | transloco }}</h2>
          <label for="filter-test-text" class="sr-only">{{ 'admin.filter.testText' | transloco }}</label>
          <textarea id="filter-test-text" class="rd-input" rows="2" dir="auto" maxlength="5000" [value]="testText()" [placeholder]="'admin.filter.testText' | transloco" (input)="testText.set($any($event.target).value)" data-filter-test-text></textarea>
          <div class="flex flex-wrap items-center gap-2">
            <button type="button" class="rd-btn rd-btn-outline min-h-10 px-4" [disabled]="!testText().trim() || testing()" (click)="test()" data-filter-test-run>{{ 'admin.filter.testRun' | transloco }}</button>
            @if (testResult(); as r) {
              <span class="rd-tag" [class]="r.level === 'block' ? 'bg-callout-danger text-error' : r.level === 'flag' ? 'bg-callout-warning text-text-primary' : 'rd-tag-neutral'" [attr.data-filter-result]="r.level">
                {{ 'admin.filter.results.' + r.level | transloco }}
              </span>
              @for (m of r.matches; track m) {
                <span class="rd-tag rd-tag-neutral" dir="auto">{{ m }}</span>
              }
            }
          </div>
          <p class="m-0 text-xs text-text-secondary">{{ 'admin.filter.testHint' | transloco }}</p>
        </section>

        <div [class]="card">
          <!-- Language and level -->
          <div class="flex flex-wrap items-center gap-2 border-b border-border p-4" role="toolbar" [attr.aria-label]="'admin.filter.lists' | transloco">
            @for (l of languages; track l) {
              <button type="button" class="rd-chip" [attr.aria-pressed]="language() === l" (click)="language.set(l)" [attr.data-filter-language]="l">
                {{ 'admin.filter.languages.' + l | transloco }}
              </button>
            }
            <span class="mx-1 h-6 w-px bg-border" aria-hidden="true"></span>
            @for (lv of levels; track lv) {
              <button type="button" class="rd-chip" [attr.aria-pressed]="level() === lv" (click)="level.set(lv)" [attr.data-filter-level]="lv">
                {{ 'admin.filter.levels.' + lv | transloco }} <span class="tabular-nums opacity-80">{{ countOf(lv) }}</span>
              </button>
            }
          </div>
          <p class="m-0 border-b border-border px-4 py-2 text-xs text-text-secondary">{{ 'admin.filter.levelHints.' + level() | transloco }}</p>

          <!-- Add a term to this list -->
          <form class="flex flex-wrap items-start gap-2 border-b border-border p-4" (submit)="add($event)" data-filter-add>
            <div class="min-w-48 flex-1">
              <label for="filter-new-term" class="sr-only">{{ 'admin.filter.newTerm' | transloco }}</label>
              <input
                id="filter-new-term"
                class="rd-input"
                [attr.dir]="language() === 'ar' ? 'auto' : 'ltr'"
                [attr.maxlength]="termMax"
                autocomplete="off"
                [value]="newTerm()"
                [placeholder]="'admin.filter.newTerm' | transloco"
                [attr.aria-invalid]="addError() ? true : null"
                (input)="newTerm.set($any($event.target).value); addError.set(null)"
                data-filter-new-term
              />
              @if (addError()) {
                <p class="rd-field-error m-0" role="alert" data-filter-add-error>{{ addError() }}</p>
              }
            </div>
            <button type="submit" class="rd-btn rd-btn-outline min-h-11 px-4" [disabled]="!newTerm().trim()" data-filter-add-button>
              <svg lucideIcon="Plus" [size]="16" aria-hidden="true"></svg>
              {{ 'admin.filter.add' | transloco }}
            </button>
          </form>

          @if (shown().length) {
            <ul class="m-0 list-none divide-y divide-border p-0" data-filter-terms>
              @for (row of shown(); track row.term + row.language) {
                <li class="flex flex-wrap items-center gap-2 px-4 py-2 text-sm" [attr.data-filter-term]="row.term">
                  <bdi dir="auto" class="min-w-0 flex-1 font-semibold [overflow-wrap:anywhere]">{{ row.term }}</bdi>
                  <span class="rd-tag rd-tag-neutral">{{ (row.source === 'file' ? 'admin.filter.fromFile' : 'admin.filter.fromConsole') | transloco }}</span>
                  <label class="sr-only" [attr.for]="'level-' + $index">{{ 'admin.filter.level' | transloco }}</label>
                  <select [id]="'level-' + $index" class="rd-input min-h-9 w-auto py-1 text-xs" [value]="row.level" (change)="setLevel(row, $any($event.target).value)" data-filter-row-level>
                    @for (lv of levels; track lv) {
                      <option [value]="lv">{{ 'admin.filter.levels.' + lv | transloco }}</option>
                    }
                  </select>
                  <button type="button" class="rd-icon-btn h-9 w-9" [attr.aria-label]="'admin.filter.remove' | transloco: { term: row.term }" (click)="remove(row)" data-filter-remove>
                    <svg lucideIcon="X" [size]="14" aria-hidden="true"></svg>
                  </button>
                </li>
              }
            </ul>
          } @else {
            <rd-empty-state [title]="'admin.filter.empty' | transloco" data-filter-empty />
          }

          @if (disabledShown().length) {
            <details class="border-t border-border px-4 py-3 text-sm" data-filter-disabled>
              <summary class="cursor-pointer text-text-secondary">{{ disabledLabel() }}</summary>
              <ul class="m-0 mt-2 flex list-none flex-col gap-1 p-0">
                @for (t of disabledShown(); track t.id) {
                  <li class="flex items-center gap-2">
                    <bdi dir="auto" class="min-w-0 flex-1 text-text-secondary line-through">{{ t.term }}</bdi>
                    <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2 text-xs" (click)="restore(t)" [attr.data-filter-restore]="t.term">{{ 'admin.filter.restore' | transloco }}</button>
                  </li>
                }
              </ul>
            </details>
          }
        </div>
        @if (tooMany()) {
          <p class="rd-alert rd-alert-error m-0" role="alert">{{ 'admin.filter.tooMany' | transloco: { max: maxTerms } }}</p>
        }
      }
      @default {
        <div [class]="card + ' flex flex-col gap-3 p-4'" aria-busy="true" data-filter-loading>
          @for (i of [1, 2, 3, 4]; track i) {
            <div class="rd-skeleton h-8 w-full" aria-hidden="true"></div>
          }
        </div>
      }
    }
  `,
})
export class AdminContentFilterPage {
  private readonly api = inject(AdminApi);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  protected readonly card = ADMIN_CARD;
  protected readonly languages = LANGUAGES;
  protected readonly levels = CONTENT_FILTER_LEVELS;
  protected readonly termMax = TERM_MAX;
  protected readonly maxTerms = MAX_TERMS;

  protected readonly status = signal<'loading' | 'loaded' | 'error'>('loading');
  /** Every term as the API has it (disabled ones too). */
  private readonly saved = signal<ContentFilterTermDto[]>([]);
  /** The enabled list being edited. */
  protected readonly rows = signal<FilterRow[]>([]);
  protected readonly language = signal<Language>('ar');
  protected readonly level = signal<ContentFilterLevel>('block');
  protected readonly newTerm = signal('');
  protected readonly addError = signal<string | null>(null);
  protected readonly saving = signal(false);
  protected readonly saveError = signal<string | null>(null);
  protected readonly testText = signal('');
  protected readonly testing = signal(false);
  protected readonly testResult = signal<ContentFilterTestDto | null>(null);

  protected readonly shown = computed(() => this.rows().filter((r) => r.language === this.language() && r.level === this.level()));
  /** File terms an admin removed, in this language (they can be brought back). */
  protected readonly disabledShown = computed(() =>
    this.saved().filter((t) => !t.isEnabled && t.language === this.language() && !this.rows().some((r) => r.language === t.language && sameTerm(r.term, t.term))),
  );
  protected readonly dirty = computed(() => this.key(this.rows()) !== this.key(this.enabledOf(this.saved())));
  protected readonly tooMany = computed(() => this.rows().length > MAX_TERMS);

  constructor() {
    void this.load();
  }

  async load(): Promise<void> {
    if (this.status() !== 'loaded') this.status.set('loading');
    try {
      const filter = await firstValueFrom(this.api.contentFilter());
      this.apply(filter.terms);
      this.status.set('loaded');
    } catch {
      if (this.status() !== 'loaded') this.status.set('error');
    }
  }

  protected countOf(level: ContentFilterLevel): number {
    return this.rows().filter((r) => r.language === this.language() && r.level === level).length;
  }

  protected disabledLabel(): string {
    return translatePlural(this.transloco, 'admin.filter.disabled', this.disabledShown().length, this.lang());
  }

  protected add(event: Event): void {
    event.preventDefault();
    const term = this.newTerm().trim();
    const problem = termProblem(term);
    if (problem) {
      this.addError.set(this.transloco.translate(`admin.filter.problems.${problem}`, { max: TERM_MAX }));
      return;
    }
    const existing = this.rows().find((r) => r.language === this.language() && sameTerm(r.term, term));
    if (existing) {
      this.addError.set(this.transloco.translate('admin.filter.problems.duplicate', { level: this.transloco.translate(`admin.filter.levels.${existing.level}`) }));
      return;
    }
    this.rows.update((rows) => [{ id: null, source: null, term, language: this.language(), level: this.level() }, ...rows]);
    this.newTerm.set('');
  }

  protected remove(row: FilterRow): void {
    this.rows.update((rows) => rows.filter((r) => r !== row));
  }

  protected setLevel(row: FilterRow, level: ContentFilterLevel): void {
    this.rows.update((rows) => rows.map((r) => (r === row ? { ...r, level } : r)));
  }

  protected restore(term: ContentFilterTermDto): void {
    this.rows.update((rows) => [{ id: term.id, source: term.source, term: term.term, language: term.language, level: term.level }, ...rows]);
  }

  protected async save(): Promise<void> {
    if (!this.dirty() || this.saving() || this.tooMany()) return;
    this.saving.set(true);
    this.saveError.set(null);
    try {
      const filter = await firstValueFrom(this.api.saveContentFilter(this.rows().map(({ term, language, level }) => ({ term, language, level }))));
      this.apply(filter.terms);
      this.toasts.success(this.transloco.translate('admin.saved'));
    } catch (error) {
      this.saveError.set(this.message(error));
    } finally {
      this.saving.set(false);
    }
  }

  protected async test(): Promise<void> {
    const text = this.testText().trim();
    if (!text || this.testing()) return;
    this.testing.set(true);
    try {
      this.testResult.set(await firstValueFrom(this.api.testContentFilter(text)));
    } catch (error) {
      this.toasts.error(this.errors.forError(error));
    } finally {
      this.testing.set(false);
    }
  }

  private apply(terms: ContentFilterTermDto[]): void {
    this.saved.set(terms);
    this.rows.set(this.enabledOf(terms));
  }

  private enabledOf(terms: ContentFilterTermDto[]): FilterRow[] {
    return terms.filter((t) => t.isEnabled).map((t) => ({ id: t.id, source: t.source, term: t.term, language: t.language, level: t.level }));
  }

  /** The list's content, order aside: what Save would change. */
  private key(rows: readonly ContentFilterTermInput[]): string {
    return rows
      .map((r) => `${r.language}|${r.level}|${r.term.trim().toLocaleLowerCase()}`)
      .sort()
      .join('\n');
  }

  private message(error: unknown): string {
    if (isApiError(error) && error.code === 'validation.failed') {
      const first = Object.values(error.validationErrors).flat()[0];
      if (first) return this.errors.forCode(first);
    }
    return this.errors.forError(error);
  }
}

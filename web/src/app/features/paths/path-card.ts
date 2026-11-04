import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { PathCardDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { PluralPipe } from '../../shared/pipes/format.pipes';
import { FIELD_ICONS, FieldIcon } from '../../shared/ui/field-icon';
import { ProgressBar } from '../../shared/ui/progress-bar';
import { fieldColor } from '../reading/reading-stats-card';
import { FieldCatalog } from './field-catalog';

/** A path is complete once you finished it while enrolled (the badge stays when the path grows later). */
export function isCompleted(path: Pick<PathCardDto, 'enrollment'>): boolean {
  return !!path.enrollment?.completedAt;
}

/** The field name in the UI language. */
export function fieldName(path: Pick<PathCardDto, 'field'>, lang: 'ar' | 'en'): string {
  return lang === 'ar' ? path.field.nameAr : path.field.nameEn;
}

/** A path's cover image, or its field's color and icon when it has none (F09). */
@Component({
  selector: 'rd-path-cover',
  imports: [LucideDynamicIcon, FieldIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'relative block overflow-hidden', '[style.background-color]': 'background()', 'aria-hidden': 'true' },
  template: `
    @if (path().coverUrl) {
      <img [src]="path().coverUrl" alt="" class="h-full w-full object-cover" [attr.loading]="eager() ? null : 'lazy'" />
    } @else {
      <span class="grid h-full w-full place-items-center" [style.color]="color()">
        @if (icon(); as name) {
          <rd-field-icon [name]="name" [size]="iconSize()" />
        } @else {
          <svg lucideIcon="Route" [size]="iconSize()"></svg>
        }
      </span>
    }
  `,
})
export class PathCover {
  private readonly catalog = inject(FieldCatalog);
  readonly path = input.required<Pick<PathCardDto, 'coverUrl' | 'field'>>();
  readonly iconSize = input(28);
  /** The page's main image (path header): not lazy. */
  readonly eager = input(false);

  private readonly field = computed(() => this.catalog.byId().get(this.path().field.id) ?? null);
  /** A known Lucide name of the field, else the path icon. */
  protected readonly icon = computed(() => {
    const name = this.field()?.icon;
    return name && FIELD_ICONS[name] ? name : null;
  });
  protected readonly color = computed(() => fieldColor(this.field()?.color ?? 'primary'));
  protected readonly background = computed(() => (this.path().coverUrl ? null : `color-mix(in srgb, ${this.color()} 14%, var(--rd-color-surface))`));

  constructor() {
    void this.catalog.load();
  }
}

/**
 * Path card (F09): cover (or field color + icon), title, two lines of description, "N articles · M min", the field;
 * signed in, the progress bar with "read/total", and "✓ Completed" once finished. The whole card opens the path.
 */
@Component({
  selector: 'rd-path-card',
  imports: [RouterLink, TranslocoPipe, BdiText, PluralPipe, ProgressBar, PathCover],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    @let p = path();
    <a
      [routerLink]="['/paths', p.slug]"
      class="rd-card flex gap-3 p-3 text-inherit no-underline shadow-none transition-colors hover:border-primary"
      [attr.data-path-card]="p.slug"
    >
      <rd-path-cover class="h-20 w-20 shrink-0 rounded-md" [path]="p" />
      <div class="min-w-0 flex-1">
        <div class="mb-1 flex flex-wrap items-center gap-1.5 text-xs">
          <span class="rd-tag"><rd-bdi-text [text]="field()" /></span>
          @if (completed()) {
            <span class="rd-tag bg-success/15 text-success" data-path-completed>{{ 'paths.completed' | transloco }}</span>
          }
        </div>
        <h3 class="m-0 line-clamp-2 text-[15px] font-semibold leading-snug" [attr.dir]="titleDir()"><rd-bdi-text [text]="p.title" /></h3>
        @if (p.description) {
          <p class="m-0 mt-1 line-clamp-2 text-sm text-text-secondary" [attr.dir]="descriptionDir()"><rd-bdi-text [text]="p.description" /></p>
        }
        <p class="m-0 mt-1.5 text-xs text-text-secondary" data-path-meta>
          {{ p.articleCount | rdPlural: 'reading.articles' : lang() }} · {{ p.readingTimeMinutes | rdPlural: 'reading.minutes' : lang() }}
        </p>
        @if (p.progress; as progress) {
          <div class="mt-2 flex items-center gap-2" data-path-progress>
            <rd-progress-bar
              class="flex-1"
              [value]="progress.percent"
              [tone]="completed() ? 'success' : 'primary'"
              [label]="'paths.progressLabel' | transloco: { read: progress.readCount, total: progress.total }"
            />
            <span class="text-xs font-semibold text-text-secondary" dir="ltr" aria-hidden="true">{{
              'paths.progress' | transloco: { read: progress.readCount, total: progress.total }
            }}</span>
          </div>
        }
      </div>
    </a>
  `,
})
export class PathCard {
  protected readonly lang = inject(LanguageService).lang;
  readonly path = input.required<PathCardDto>();

  protected readonly field = computed(() => fieldName(this.path(), this.lang()));
  protected readonly completed = computed(() => isCompleted(this.path()));
  protected readonly titleDir = computed(() => detectDir(this.path().title) ?? 'auto');
  protected readonly descriptionDir = computed(() => detectDir(this.path().description) ?? 'auto');
}

@Component({
  selector: 'rd-path-card-skeleton',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'rd-card flex gap-3 p-3 shadow-none', 'aria-hidden': 'true' },
  template: `
    <div class="rd-skeleton h-20 w-20 shrink-0 rounded-md"></div>
    <div class="flex flex-1 flex-col gap-2 pt-1">
      <div class="rd-skeleton h-3 w-16"></div>
      <div class="rd-skeleton h-4 w-full"></div>
      <div class="rd-skeleton h-4 w-2/3"></div>
      <div class="rd-skeleton h-3 w-1/3"></div>
    </div>
  `,
})
export class PathCardSkeleton {}

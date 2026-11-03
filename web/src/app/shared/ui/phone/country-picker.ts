import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  afterNextRender,
  computed,
  inject,
  input,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { CdkTrapFocus } from '@angular/cdk/a11y';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { LanguageService } from '../../../core/i18n/language.service';
import { Country, PINNED_COUNTRIES, countryName, flagUrl, searchCountries, sortedCountries } from './countries';

let nextId = 0;

/**
 * The searchable country list of the phone field (SPEC §9.4), shown in a CDK overlay: a popover under the field on
 * wide screens, a bottom sheet on small ones. Combobox + listbox pattern: focus stays in the search box and the
 * arrow keys move the active option (`aria-activedescendant`); Enter picks it, Escape closes.
 */
@Component({
  selector: 'rd-country-picker',
  imports: [TranslocoPipe, LucideDynamicIcon, CdkTrapFocus],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    role: 'dialog',
    'aria-modal': 'true',
    '[attr.aria-labelledby]': 'titleId',
    class: 'flex w-full flex-col border border-border bg-surface-raised text-text-primary shadow-raised',
    '[class]': "sheet() ? 'max-h-[85dvh] rounded-t-sheet p-4 pb-6' : 'max-h-[420px] rounded-md p-3'",
    '(keydown)': 'onKeydown($event)',
  },
  template: `
    <div cdkTrapFocus class="flex min-h-0 flex-1 flex-col">
      @if (sheet()) {
        <div class="mx-auto mb-3 h-1 w-9 shrink-0 rounded-chip bg-border" aria-hidden="true"></div>
      }
      <div class="mb-2 flex shrink-0 items-center gap-2">
        <h2 [id]="titleId" class="m-0 flex-1 text-base font-semibold">{{ 'phone.picker.title' | transloco }}</h2>
        <button type="button" class="rd-icon-btn h-9 w-9" [attr.aria-label]="'common.close' | transloco" (click)="closed.emit()">
          <svg lucideIcon="X" [size]="18"></svg>
        </button>
      </div>
      <div class="relative mb-2 shrink-0">
        <svg lucideIcon="Search" [size]="16" class="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 text-text-secondary" aria-hidden="true"></svg>
        <input
          #search
          type="search"
          class="rd-input ps-9"
          role="combobox"
          aria-autocomplete="list"
          aria-expanded="true"
          [attr.aria-controls]="listId"
          [attr.aria-activedescendant]="activeOptionId()"
          [attr.aria-label]="'phone.picker.search' | transloco"
          [placeholder]="'phone.picker.search' | transloco"
          autocomplete="off"
          spellcheck="false"
          (input)="onSearch($event)"
        />
      </div>
      <ul [id]="listId" role="listbox" [attr.aria-labelledby]="titleId" class="m-0 min-h-0 flex-1 list-none overflow-y-auto overscroll-contain p-0">
        @for (country of results(); track country.iso2; let i = $index) {
          @if (i === pinnedCount() && i > 0) {
            <li role="presentation" class="my-1 border-t border-border" aria-hidden="true"></li>
          }
          <li
            [id]="optionId(country)"
            role="option"
            tabindex="-1"
            [attr.aria-selected]="country.iso2 === selected()"
            class="flex min-h-11 cursor-pointer items-center gap-3 rounded-sm px-2 text-sm"
            [class.bg-surface-variant]="i === active()"
            [attr.data-country]="country.iso2"
            (click)="pick(country)"
            (keydown.enter)="pick(country)"
            (mousemove)="active.set(i)"
          >
            <img class="rd-flag" [src]="flag(country)" alt="" width="22" height="16" loading="lazy" decoding="async" />
            <span class="min-w-0 flex-1 truncate"><bdi>{{ name(country) }}</bdi></span>
            <span class="font-latin text-text-secondary" dir="ltr">+{{ country.dialCode }}</span>
            <span class="grid w-4 place-items-center text-primary" aria-hidden="true">
              @if (country.iso2 === selected()) {
                <svg lucideIcon="Check" [size]="16"></svg>
              }
            </span>
          </li>
        } @empty {
          <li role="presentation" class="px-2 py-6 text-center text-sm text-text-secondary">{{ 'phone.picker.empty' | transloco }}</li>
        }
      </ul>
    </div>
  `,
})
export class CountryPicker {
  /** ISO code of the current country. */
  readonly selected = input<string>('');
  /** Bottom-sheet layout (small screens). */
  readonly sheet = input(false);
  readonly picked = output<Country>();
  readonly closed = output<void>();

  private readonly lang = inject(LanguageService).lang;
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly searchBox = viewChild.required<ElementRef<HTMLInputElement>>('search');

  private readonly id = nextId++;
  protected readonly titleId = `rd-country-title-${this.id}`;
  protected readonly listId = `rd-country-list-${this.id}`;

  protected readonly query = signal('');
  private readonly all = computed(() => sortedCountries(this.lang()));
  protected readonly results = computed(() => searchCountries(this.all(), this.query()));
  /** The divider after the pinned Arab countries, only while not searching. */
  protected readonly pinnedCount = computed(() => (this.query().trim() ? -1 : PINNED_COUNTRIES.length));
  protected readonly active = signal(0);
  protected readonly activeOptionId = computed(() => {
    const country = this.results()[this.active()];
    return country ? this.optionId(country) : null;
  });

  constructor() {
    afterNextRender(() => {
      const index = this.results().findIndex((c) => c.iso2 === this.selected());
      this.active.set(Math.max(0, index));
      this.scrollActiveIntoView('center');
      this.searchBox().nativeElement.focus();
    });
  }

  protected optionId(country: Country): string {
    return `rd-country-${this.id}-${country.iso2}`;
  }

  protected name(country: Country): string {
    return countryName(country, this.lang());
  }

  protected flag(country: Country): string {
    return flagUrl(country.iso2);
  }

  protected onSearch(event: Event): void {
    this.query.set((event.target as HTMLInputElement).value);
    this.active.set(0);
    this.host.nativeElement.querySelector('[role="listbox"]')?.scrollTo({ top: 0 });
  }

  protected pick(country: Country): void {
    this.picked.emit(country);
  }

  protected onKeydown(event: KeyboardEvent): void {
    const count = this.results().length;
    const move = (index: number) => {
      event.preventDefault();
      if (!count) return;
      this.active.set((index + count) % count);
      this.scrollActiveIntoView('nearest');
    };
    switch (event.key) {
      case 'ArrowDown':
        return move(this.active() + 1);
      case 'ArrowUp':
        return move(this.active() - 1);
      case 'PageDown':
        return move(Math.min(this.active() + 8, count - 1));
      case 'PageUp':
        return move(Math.max(this.active() - 8, 0));
      case 'Home':
        if (event.target === this.searchBox().nativeElement && this.query()) return;
        return move(0);
      case 'End':
        if (event.target === this.searchBox().nativeElement && this.query()) return;
        return move(count - 1);
      case 'Enter': {
        const country = this.results()[this.active()];
        if (!country) return;
        event.preventDefault();
        this.pick(country);
        return;
      }
      case 'Escape':
        event.preventDefault();
        event.stopPropagation();
        this.closed.emit();
        return;
    }
  }

  private scrollActiveIntoView(block: ScrollLogicalPosition): void {
    const id = this.activeOptionId();
    if (id) this.host.nativeElement.querySelector(`#${CSS.escape(id)}`)?.scrollIntoView({ block });
  }
}

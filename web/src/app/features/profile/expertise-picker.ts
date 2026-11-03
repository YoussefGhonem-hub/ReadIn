import { ChangeDetectionStrategy, Component, computed, inject, input, output } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { FieldDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { FieldIcon } from '../../shared/ui/field-icon';

/** Fields of expertise on a profile (F14, `expertiseFieldIds`). */
export const MAX_EXPERTISE = 5;

/** Picks or drops a field, keeping the pick order; a sixth pick is refused (returns the same list). */
export function toggleExpertise(selected: readonly string[], fieldId: string, max = MAX_EXPERTISE): string[] {
  if (selected.includes(fieldId)) return selected.filter((id) => id !== fieldId);
  return selected.length >= max ? [...selected] : [...selected, fieldId];
}

/**
 * Expertise picker (F14): toggle chips for the fields from `/fields`, at most 5, in the order they were picked (the
 * number on a chip). Once 5 are picked the others say why they can't be added.
 */
@Component({
  selector: 'rd-expertise-picker',
  imports: [TranslocoPipe, LucideDynamicIcon, BdiText, FieldIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-expertise-picker': '' },
  template: `
    <div class="flex flex-wrap gap-2" role="group" [attr.aria-labelledby]="labelledBy()" [attr.aria-describedby]="hintId()">
      @for (field of fields(); track field.id) {
        @let position = selected().indexOf(field.id) + 1;
        <button
          type="button"
          class="rd-chip min-h-11"
          [class.opacity-60]="full() && !position"
          [attr.aria-pressed]="position > 0"
          [attr.aria-disabled]="full() && !position ? true : null"
          [attr.data-expertise]="field.slug"
          (click)="toggle(field.id)"
        >
          @if (position) {
            <span class="grid h-5 w-5 place-items-center rounded-full bg-surface text-[11px] font-bold text-primary" aria-hidden="true">{{ position }}</span>
          } @else {
            <rd-field-icon [name]="field.icon" [size]="15" />
          }
          <rd-bdi-text [text]="lang() === 'ar' ? field.nameAr : field.nameEn" />
          @if (position) {
            <svg lucideIcon="Check" [size]="14" aria-hidden="true"></svg>
          }
        </button>
      }
    </div>
    <p [id]="hintId()" class="m-0 mt-2 text-xs" [class]="full() ? 'font-semibold text-text-primary' : 'text-text-secondary'" aria-live="polite" data-expertise-count>
      {{ 'profile.edit.expertiseCount' | transloco: { count: selected().length } }} ·
      {{ (full() ? 'profile.edit.expertiseFull' : 'profile.edit.expertiseHint') | transloco }}
    </p>
  `,
})
export class ExpertisePicker {
  protected readonly lang = inject(LanguageService).lang;

  readonly fields = input.required<FieldDto[]>();
  /** Field ids in order. */
  readonly selected = input.required<string[]>();
  readonly labelledBy = input<string | null>(null);
  readonly hintId = input('expertise-hint');
  readonly selectedChange = output<string[]>();

  protected readonly full = computed(() => this.selected().length >= MAX_EXPERTISE);

  protected toggle(fieldId: string): void {
    const next = toggleExpertise(this.selected(), fieldId);
    if (next.length !== this.selected().length) this.selectedChange.emit(next);
  }
}

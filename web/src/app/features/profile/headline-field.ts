import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { toObservable, toSignal } from '@angular/core/rxjs-interop';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { TranslocoPipe } from '@jsverse/transloco';
import { startWith, switchMap } from 'rxjs';
import { MAX_HEADLINE } from './link-rules';

/** The counter shows in the last 20 characters before the limit, and past it. */
const COUNTER_FROM = MAX_HEADLINE - 20;

/**
 * The title field (F14, "المسمى" / "Title") of Edit profile and Complete profile: optional, one line, mixed Arabic and
 * English in its own direction, at most 120 characters, with a counter near the limit and the error under it.
 */
@Component({
  selector: 'rd-headline-field',
  imports: [ReactiveFormsModule, TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-headline-field': '' },
  template: `
    <label class="rd-label" [for]="inputId()">{{ 'profile.headline.label' | transloco }}</label>
    <!-- Typed text takes its own direction; empty, the placeholder follows the UI's. -->
    <input
      class="rd-input"
      type="text"
      [attr.dir]="length() ? 'auto' : null"
      autocomplete="organization-title"
      enterkeyhint="next"
      [id]="inputId()"
      [formControl]="control()"
      [placeholder]="'profile.headline.placeholder' | transloco"
      [attr.aria-invalid]="!!error() || null"
      [attr.aria-describedby]="inputId() + '-hint'"
      data-headline-input
    />
    <div class="mt-1 flex items-start justify-between gap-3" [id]="inputId() + '-hint'">
      @if (error(); as key) {
        <p class="rd-field-error m-0" data-field-error="headline">{{ key | transloco: { max: max } }}</p>
      } @else {
        <span class="text-xs text-text-secondary">{{ 'profile.headline.hint' | transloco }}</span>
      }
      @if (length() >= counterFrom) {
        <span class="shrink-0 text-xs" [class]="length() > max ? 'font-semibold text-error' : 'text-text-secondary'" dir="ltr" data-headline-count>
          {{ length() }} / {{ max }}
        </span>
      }
    </div>
  `,
})
export class HeadlineField {
  readonly control = input.required<FormControl<string>>();
  readonly inputId = input('edit-headline');
  /** Translation key of the error to show, if any. */
  readonly error = input<string | null>(null);

  protected readonly max = MAX_HEADLINE;
  protected readonly counterFrom = COUNTER_FROM;
  private readonly value = toSignal(
    toObservable(this.control).pipe(switchMap((control) => control.valueChanges.pipe(startWith(control.value)))),
    { initialValue: '' },
  );
  /** Characters after trimming, as the API counts them. */
  protected readonly length = computed(() => (this.value() ?? '').trim().length);
}

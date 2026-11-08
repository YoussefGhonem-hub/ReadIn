import { ChangeDetectionStrategy, Component, input, model } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';

/**
 * The sign-up checkbox (SPEC §9.2, F37): «أوافق على شروط الاستخدام وقواعد المجتمع، ولا تسامح مطلقًا مع المحتوى المسيء أو
 * المستخدمين المسيئين». Required before an account is created (phone sign up and new Google/Apple accounts); the links
 * open the public pages in a new tab, so the form keeps its state.
 */
@Component({
  selector: 'rd-terms-checkbox',
  imports: [TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-terms-checkbox': '' },
  template: `
    <label class="flex cursor-pointer items-start gap-3 text-sm leading-relaxed">
      <input type="checkbox" class="mt-1 h-5 w-5 shrink-0 accent-primary" [checked]="checked()" [disabled]="disabled()" (change)="checked.set($any($event.target).checked)" data-accept-terms />
      <span>
        {{ 'legal.checkbox.agree' | transloco }}
        <a href="/terms" target="_blank" rel="noopener" class="font-semibold text-link">{{ 'legal.terms.title' | transloco }}</a
        >{{ 'legal.checkbox.and' | transloco }}<a href="/community-guidelines" target="_blank" rel="noopener" class="font-semibold text-link">{{ 'legal.guidelines.title' | transloco }}</a>{{
          'legal.checkbox.zeroTolerance' | transloco
        }}
      </span>
    </label>
  `,
})
export class TermsCheckbox {
  readonly checked = model(false);
  readonly disabled = input(false);
}

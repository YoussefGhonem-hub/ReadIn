import { ChangeDetectionStrategy, Component, computed, effect, inject, input } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { bindPageLanguage } from '../../core/i18n/language-alternates';
import { LanguageService } from '../../core/i18n/language.service';
import { environment } from '../../../environments/environment';
import { LEGAL_TEXTS, LegalPageId, SUPPORT_EMAIL_PLACEHOLDER } from './legal-content';

/**
 * The public Terms of Use (`/terms`) and Community Guidelines (`/community-guidelines`) (F37): server-rendered and
 * indexable, linked from sign up, the terms screen, Settings → Legal and the footer. Shown in the UI language; the apps
 * open them as `?lang=ar|en` (LanguageService shows that language without saving it), and the other language is one
 * tap away the same way. Canonical and hreflang links name both versions.
 */
@Component({
  selector: 'rd-legal-page',
  imports: [RouterLink, TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[760px] px-4 pb-16 pt-5 lg:pt-8', '[attr.data-legal-page]': 'page()' },
  template: `
    @let t = text();
    <article class="rd-card p-5 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-8" [attr.lang]="shown()" [attr.dir]="shown() === 'ar' ? 'rtl' : 'ltr'">
      <div class="flex flex-wrap items-start justify-between gap-3">
        <h1 class="m-0 text-2xl font-bold lg:text-3xl" data-legal-title>{{ t.title }}</h1>
        <a
          [routerLink]="[]"
          [queryParams]="{ lang: other() }"
          [replaceUrl]="true"
          class="rd-btn rd-btn-outline min-h-10 px-3 text-sm no-underline"
          [attr.lang]="other()"
          [attr.hreflang]="other()"
          data-legal-language
        >
          {{ other() === 'ar' ? 'العربية' : 'English' }}
        </a>
      </div>
      <p class="m-0 mt-1 text-sm text-text-secondary">{{ t.updated }}</p>
      <p class="m-0 mt-4 rounded-md bg-primary-container p-4 text-on-primary-container" data-legal-intro>{{ email(t.intro) }}</p>
      @for (section of t.sections; track section.heading) {
        <section class="mt-6">
          <h2 class="m-0 mb-2 text-lg font-semibold">{{ section.heading }}</h2>
          @for (p of section.paragraphs ?? []; track $index) {
            <p class="m-0 mb-2 leading-relaxed">{{ email(p) }}</p>
          }
          @if (section.items?.length) {
            <ul class="m-0 flex flex-col gap-1.5 ps-5 leading-relaxed">
              @for (item of section.items; track $index) {
                <li>{{ email(item) }}</li>
              }
            </ul>
          }
        </section>
      }
    </article>
    <nav class="mt-3 flex flex-wrap justify-center gap-x-4 gap-y-1 text-sm" [attr.aria-label]="'legal.settingsTitle' | transloco" data-legal-links>
      @if (page() === 'terms') {
        <a routerLink="/community-guidelines" queryParamsHandling="preserve" class="text-link">{{ 'legal.guidelines.title' | transloco }}</a>
      } @else {
        <a routerLink="/terms" queryParamsHandling="preserve" class="text-link">{{ 'legal.terms.title' | transloco }}</a>
      }
      <a [href]="privacyUrl" target="_blank" rel="noopener" class="text-link">{{ 'legal.privacy' | transloco }}</a>
      <a routerLink="/support" queryParamsHandling="preserve" class="text-link">{{ 'support.title' | transloco }}</a>
    </nav>
  `,
})
export class LegalPage {
  private readonly uiLang = inject(LanguageService).lang;

  /** `data.page` (component input binding). */
  readonly page = input<LegalPageId>('terms');
  /** `?lang=ar|en` (component input binding): the apps open the page in their language. */
  readonly lang = input<string | null>();

  /** The UI language: the page's `?lang=` or the member's own. */
  protected readonly shown = this.uiLang;
  protected readonly other = computed(() => (this.shown() === 'ar' ? 'en' : 'ar'));
  protected readonly text = computed(() => LEGAL_TEXTS[this.page()][this.shown()]);
  protected readonly privacyUrl = `${new URL(environment.accountDeletionUrl).origin}/privacy`;

  constructor() {
    const title = inject(Title);
    const meta = inject(Meta);
    effect(() => {
      const t = this.text();
      title.setTitle(`${t.title} — ReadIn`);
      meta.updateTag({ name: 'description', content: this.email(t.intro).slice(0, 160) });
    });
    bindPageLanguage(() => (this.page() === 'terms' ? '/terms' : '/community-guidelines'), this.lang);
  }

  protected email(text: string): string {
    return text.split(SUPPORT_EMAIL_PLACEHOLDER).join(environment.supportEmail);
  }
}

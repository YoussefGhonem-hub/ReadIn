import {
  ChangeDetectionStrategy,
  Component,
  DOCUMENT,
  DestroyRef,
  ElementRef,
  Provider,
  ViewEncapsulation,
  afterNextRender,
  inject,
  input,
} from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LUCIDE_ICONS, LucideDynamicIcon, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import BadgeCheck from 'lucide/dist/esm/icons/badge-check.mjs';
import Clock from 'lucide/dist/esm/icons/clock.mjs';
import Flame from 'lucide/dist/esm/icons/flame.mjs';
import Highlighter from 'lucide/dist/esm/icons/highlighter.mjs';
import Quote from 'lucide/dist/esm/icons/quote.mjs';
import { LanguageService } from '../../core/i18n/language.service';
import { LanguageSwitch } from '../../shared/ui/language-switch';
import { Wordmark } from '../../shared/ui/wordmark';

/** The showcase's own icons, added to the registry it inherits (the auth chunk carries them, not the main bundle). */
function provideShowcaseIcons(): Provider {
  return {
    provide: LUCIDE_ICONS,
    useFactory: () => {
      const icons = { ...inject(LUCIDE_ICONS, { skipSelf: true }) };
      for (const icon of lucideLegacyIconMap({ BadgeCheck, Clock, Flame, Highlighter, Quote })) {
        icons[icon.name] = icon;
        for (const alias of icon.aliases ?? []) icons[alias] = icon;
      }
      return icons;
    },
  };
}

/** The topics the headline cycles through; the first comes back at the end so the loop has no jump. */
const SHOWCASE_TOPICS = ['tech', 'medicine', 'business', 'mind', 'tech'] as const;
const STREAK_DAYS = [0, 1, 2, 3, 4, 5, 6] as const;

/**
 * The brand panel beside the auth forms on wide screens: a sample of the app (today's article being read, a reading
 * streak, a highlighted line) floating over the brand green, and a headline that cycles through topics. Decorative only:
 * hidden from screen readers, nothing to focus. With a mouse, the cards lean toward the pointer (not with reduce motion).
 * `compact` shows only the cards, smaller (Welcome on phones).
 */
@Component({
  selector: 'rd-auth-showcase',
  imports: [NgTemplateOutlet, TranslocoPipe, LucideDynamicIcon],
  providers: [provideShowcaseIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  styleUrl: './auth-showcase.css',
  host: { class: 'block', 'aria-hidden': 'true', 'data-auth-showcase': '' },
  template: `
    @if (compact()) {
      <div class="rd-sc h-[210px]">
        <span class="rd-sc-glow"></span><span class="rd-sc-glow"></span><span class="rd-sc-dots"></span>
        <div class="absolute left-1/2 top-3 h-[320px] w-[460px] origin-top -translate-x-1/2 scale-[.6]">
          <ng-container [ngTemplateOutlet]="stage" />
        </div>
      </div>
    } @else {
      <div class="rd-sc flex h-full flex-col justify-between gap-6 p-10 xl:p-12">
        <span class="rd-sc-glow"></span><span class="rd-sc-glow"></span><span class="rd-sc-dots"></span>
        <p class="rd-sc-pill m-0 inline-flex items-center gap-2 self-start rounded-chip px-3 py-1.5 text-xs font-semibold">
          <span class="rd-sc-live"></span>{{ 'auth.showcase.daily' | transloco }}
        </p>

        <div class="relative mx-auto h-[320px] w-full max-w-[460px]"><ng-container [ngTemplateOutlet]="stage" /></div>

        <p class="m-0 text-[clamp(1.75rem,2.6vw,2.5rem)] font-bold leading-tight">
          {{ 'auth.showcase.learn' | transloco }}
          <span class="rd-sc-ticker">
            <span class="rd-sc-words">
              @for (topic of topics; track $index) {
                <span>{{ 'auth.showcase.topics.' + topic | transloco }}</span>
              }
            </span>
          </span>
        </p>
      </div>
    }

    <ng-template #stage>
      <div class="rd-sc-card start-0 top-8 w-[285px] p-4" style="--r: -2deg; --depth: 14px; --in: 150ms; --float: 7s">
        <div class="flex items-center justify-between gap-2">
          <span class="rd-tag">{{ 'auth.showcase.field' | transloco }}</span>
          <span class="inline-flex items-center gap-1 text-[11px] text-text-secondary">
            <svg lucideIcon="Clock" [size]="12"></svg>{{ 'auth.showcase.minutes' | transloco }}
          </span>
        </div>
        <p class="m-0 mt-3 text-[15px] font-semibold leading-6">{{ 'auth.showcase.article' | transloco }}</p>
        <span class="mt-2 block h-1.5 w-full rounded-chip bg-surface-variant"></span>
        <span class="mt-1.5 block h-1.5 w-4/5 rounded-chip bg-surface-variant"></span>
        <div class="mt-4 flex items-center gap-2">
          <span class="grid h-7 w-7 place-items-center rounded-full bg-primary-container text-[11px] font-bold text-on-primary-container">
            {{ ('auth.showcase.author' | transloco).charAt(0) }}
          </span>
          <span class="text-xs font-semibold">{{ 'auth.showcase.author' | transloco }}</span>
          <svg lucideIcon="BadgeCheck" [size]="14" class="text-primary"></svg>
        </div>
        <span class="mt-3 block h-1 overflow-hidden rounded-chip bg-surface-variant">
          <span class="rd-sc-progress block h-full rounded-chip bg-primary"></span>
        </span>
      </div>

      <div class="rd-sc-card end-0 top-0 w-[172px] p-4" style="--r: 4deg; --depth: -10px; --in: 350ms; --float: 6s">
        <div class="flex items-center gap-3">
          <span class="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-accent-container text-accent">
            <svg lucideIcon="Flame" [size]="20" class="rd-sc-flame"></svg>
          </span>
          <div class="min-w-0">
            <p class="rd-sc-count m-0 font-latin text-2xl font-bold leading-none"></p>
            <p class="m-0 mt-1 text-[11px] text-text-secondary">{{ 'auth.showcase.streak' | transloco }}</p>
          </div>
        </div>
        <div class="mt-3 flex justify-between">
          @for (day of days; track day) {
            <span class="rd-sc-day h-2.5 w-2.5 rounded-full bg-accent" [style.--i]="day"></span>
          }
        </div>
      </div>

      <div class="rd-sc-card bottom-0 end-0 w-[250px] p-4" style="--r: -3deg; --depth: 22px; --in: 550ms; --float: 8s">
        <svg lucideIcon="Quote" [size]="18" class="rd-flip-rtl text-primary"></svg>
        <p class="m-0 mt-1.5 text-[13px] leading-6"><mark class="rd-sc-mark">{{ 'auth.showcase.quote' | transloco }}</mark></p>
        <p class="m-0 mt-2 flex items-center gap-1.5 text-[11px] text-text-secondary">
          <svg lucideIcon="Highlighter" [size]="12"></svg>{{ 'auth.showcase.highlighted' | transloco }}
        </p>
      </div>
    </ng-template>
  `,
})
export class AuthShowcase {
  /** Just the cards, on a short panel (Welcome on phones). */
  readonly compact = input(false);
  protected readonly topics = SHOWCASE_TOPICS;
  protected readonly days = STREAK_DAYS;

  constructor() {
    const host = inject<ElementRef<HTMLElement>>(ElementRef).nativeElement;
    const view = inject(DOCUMENT).defaultView;
    const destroyRef = inject(DestroyRef);
    // Plain listeners: following the pointer never needs a change detection.
    afterNextRender(() => {
      if (!view || view.matchMedia?.('(prefers-reduced-motion: reduce)').matches !== false) return;
      let frame = 0;
      const lean = (x: number, y: number) => {
        view.cancelAnimationFrame(frame);
        frame = view.requestAnimationFrame(() => {
          host.style.setProperty('--px', x.toFixed(3));
          host.style.setProperty('--py', y.toFixed(3));
        });
      };
      const move = (event: PointerEvent) => {
        if (event.pointerType !== 'mouse') return;
        const box = host.getBoundingClientRect();
        if (!box.width || !box.height) return;
        lean(((event.clientX - box.left) / box.width) * 2 - 1, ((event.clientY - box.top) / box.height) * 2 - 1);
      };
      const rest = () => lean(0, 0);
      host.addEventListener('pointermove', move);
      host.addEventListener('pointerleave', rest);
      destroyRef.onDestroy(() => {
        view.cancelAnimationFrame(frame);
        host.removeEventListener('pointermove', move);
        host.removeEventListener('pointerleave', rest);
      });
    });
  }
}

/**
 * The page frame of the auth screens (Welcome, Sign in, Create account and the setup steps): the wordmark (to Home) and
 * the UI language switch on top, the screen in the middle over a soft drifting light, the tagline at the bottom. On wide
 * screens the brand showcase fills the other half and stays in view while the form scrolls. The screens' content rises
 * in one piece after another, an error shakes once, the primary button shines on hover; reduce motion turns it all off.
 */
@Component({
  selector: 'rd-auth-frame',
  imports: [RouterLink, TranslocoPipe, Wordmark, LanguageSwitch, AuthShowcase],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  styleUrl: './auth-frame.css',
  host: { class: 'rd-auth-frame relative isolate grid min-h-dvh lg:grid-cols-[minmax(0,1fr)_minmax(0,1.1fr)]' },
  template: `
    <div class="rd-auth-backdrop" aria-hidden="true"><span></span><span></span><span></span></div>
    <div class="flex min-h-dvh min-w-0 flex-col px-4 pb-6 pt-3 sm:px-8 lg:px-12">
      <div class="flex items-center justify-between gap-3">
        <a routerLink="/" class="rd-auth-rise rounded-md no-underline" style="--d: 0ms" [attr.aria-label]="'nav.home' | transloco" data-auth-home>
          <rd-wordmark [size]="26" [withIcon]="true" />
        </a>
        <rd-language-switch />
      </div>
      <div class="flex flex-1 flex-col items-center justify-center py-8"><ng-content /></div>
      <p class="m-0 text-center text-xs text-text-secondary">
        {{ 'app.tagline' | transloco }}
        @if (lang() === 'ar') {
          · <span dir="ltr">Read daily. Grow daily.</span>
        }
      </p>
    </div>
    <div class="sticky top-0 hidden h-dvh p-4 ps-0 lg:block">
      <rd-auth-showcase class="h-full" />
    </div>
  `,
})
export class AuthFrame {
  protected readonly lang = inject(LanguageService).lang;
}

import {
  ChangeDetectionStrategy,
  Component,
  DOCUMENT,
  PLATFORM_ID,
  computed,
  effect,
  inject,
  input,
  output,
  signal,
  untracked,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { StreakMilestone } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { translatePlural } from '../../shared/pipes/format.pipes';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { renderMilestoneCard } from './milestone-card';

interface MilestoneCard {
  file: File;
  url: string;
  /** The Web Share API takes this file; otherwise it is downloaded. */
  shareable: boolean;
}

/** Streak milestone celebration (F08: 7, 30, 100 and 365 days) with a shareable card. */
@Component({
  selector: 'rd-milestone-celebration',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="milestone() !== null" labelledBy="rd-milestone-title" describedBy="rd-milestone-body" (closed)="closed.emit()">
      @if (milestone(); as days) {
        <div class="flex flex-col items-center gap-3 pt-2 text-center">
          <span class="text-5xl leading-none" aria-hidden="true">🔥</span>
          <h2 id="rd-milestone-title" class="m-0 text-2xl font-bold">{{ 'reading.milestone.title.' + days | transloco }}</h2>
          <p id="rd-milestone-body" class="m-0 max-w-sm text-sm text-text-secondary">{{ 'reading.milestone.body' | transloco: { days: daysText() } }}</p>
          <div class="grid aspect-square w-full max-w-[260px] place-items-center overflow-hidden rounded-card border border-border bg-surface-variant">
            @if (card(); as c) {
              <img [src]="c.url" [alt]="'reading.milestone.cardAlt' | transloco: { days: daysText() }" class="h-full w-full" width="1080" height="1080" />
            } @else {
              <span class="text-sm text-text-secondary" aria-live="polite">{{ 'reading.milestone.preparing' | transloco }}</span>
            }
          </div>
          <div class="mt-2 flex w-full flex-col gap-2">
            <button type="button" class="rd-btn rd-btn-primary" [disabled]="!card()" (click)="share()">
              @if (card()?.shareable === false) {
                <svg lucideIcon="Download" [size]="18" aria-hidden="true"></svg>
                {{ 'reading.milestone.download' | transloco }}
              } @else {
                <svg lucideIcon="Share2" [size]="18" aria-hidden="true"></svg>
                {{ 'reading.milestone.share' | transloco }}
              }
            </button>
            <button type="button" class="rd-btn rd-btn-ghost" (click)="closed.emit()">{{ 'reading.milestone.keepReading' | transloco }}</button>
          </div>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class MilestoneCelebration {
  readonly milestone = input<StreakMilestone | null>(null);
  readonly closed = output<void>();

  private readonly document = inject(DOCUMENT);
  private readonly transloco = inject(TranslocoService);
  private readonly language = inject(LanguageService);
  protected readonly card = signal<MilestoneCard | null>(null);
  protected readonly daysText = computed(() => translatePlural(this.transloco, 'reading.days', this.milestone() ?? 0, this.language.lang()));

  constructor() {
    const isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
    // Draw the card for this milestone, in the current language and theme.
    effect((onCleanup) => {
      const milestone = this.milestone();
      const lang = this.language.lang();
      if (!milestone || !isBrowser) return;
      let current = true;
      let url: string | null = null;
      untracked(() => {
        void this.draw(milestone, lang).then((card) => {
          if (!card) return;
          if (current) {
            url = card.url;
            this.card.set(card);
          } else URL.revokeObjectURL(card.url);
        });
      });
      onCleanup(() => {
        current = false;
        this.card.set(null);
        if (url) URL.revokeObjectURL(url);
      });
    });
  }

  /** Web Share with the PNG when the browser can share files, otherwise a download. */
  protected async share(): Promise<void> {
    const card = this.card();
    if (!card) return;
    if (card.shareable) {
      try {
        await navigator.share({ files: [card.file], title: 'ReadIn', text: this.transloco.translate('reading.milestone.shareText', { days: this.daysText() }) });
      } catch {
        /* share sheet dismissed */
      }
      return;
    }
    const link = this.document.createElement('a');
    link.href = card.url;
    link.download = card.file.name;
    link.click();
  }

  private async draw(milestone: StreakMilestone, lang: 'ar' | 'en'): Promise<MilestoneCard | null> {
    const t = (key: string) => this.transloco.translate(key, {}, lang);
    const blob = await renderMilestoneCard(this.document, milestone, {
      headline: translatePlural(this.transloco, 'reading.milestone.cardHeadline', milestone, lang),
      title: t(`reading.milestone.title.${milestone}`),
      tagline: t('app.tagline'),
      dir: lang === 'ar' ? 'rtl' : 'ltr',
    });
    if (!blob) return null;
    const file = new File([blob], `readin-streak-${milestone}.png`, { type: 'image/png' });
    const shareable = typeof navigator.canShare === 'function' && navigator.canShare({ files: [file] });
    return { file, url: URL.createObjectURL(blob), shareable };
  }
}

import { PLATFORM_ID, Type, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Observable, of, throwError } from 'rxjs';
import { ApiError } from '../../core/api/api.config';
import { ReadingHeatmapDto, ReadingStatsDto, StreakDto } from '../../core/api/models';
import { ProfilesApi } from '../../core/api/profiles.api';
import { ReadingApi } from '../../core/api/reading.api';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService, UiLanguage } from '../../core/i18n/language.service';
import { StreakBadge } from '../../shared/ui/streak-badge';
import { provideAppIcons } from '../../shared/ui/icons';
import { testMe } from '../../../testing/auth-testing';
import { translocoTesting } from '../../../testing/transloco-testing';
import { ReadingHeatmap } from './reading-heatmap';
import { ReadingSheetsService } from './reading-sheets.service';
import { ReadingStatsCard, fieldColor, freezeStatus } from './reading-stats-card';
import { StreakStore } from './streak.store';

const STREAK: StreakDto = { current: 12, longest: 30, readToday: true, freezeAvailable: true, freezePending: false, today: '2026-11-03' };
const STATS: ReadingStatsDto = {
  streak: STREAK,
  totalArticles: 48,
  minutesRead: 410,
  articlesThisWeek: 5,
  minutesThisWeek: 37,
  articlesThisMonth: 19,
  topFields: [{ id: 'f1', slug: 'dotnet', name: '.NET', icon: 'code', color: 'primary', articles: 9 }],
};
const HEATMAP: ReadingHeatmapDto = {
  from: '2025-11-04',
  to: '2026-11-03',
  days: [
    { date: '2026-11-02', articles: 2, minutes: 14, frozen: false },
    { date: '2026-11-01', articles: 0, minutes: 0, frozen: true },
  ],
};

interface Options {
  lang?: UiLanguage;
  stats?: () => Observable<ReadingStatsDto>;
  /** Someone else's stats (`GET /users/{username}/stats`). */
  userStats?: () => Observable<ReadingStatsDto>;
  sheets?: boolean;
}

function configure(options: Options = {}): void {
  const lang = options.lang ?? 'en';
  TestBed.configureTestingModule({
    // Transloco's active language and the UI language agree, as in the app.
    imports: [translocoTesting({ translocoConfig: { availableLangs: ['ar', 'en'], defaultLang: lang } })],
    providers: [
      provideAppIcons(),
      { provide: PLATFORM_ID, useValue: 'browser' },
      { provide: LanguageService, useValue: { lang: signal(lang), dir: signal(lang === 'ar' ? 'rtl' : 'ltr') } },
      { provide: ReadingApi, useValue: { stats: vi.fn(options.stats ?? (() => of(STATS))), heatmap: vi.fn(() => of(HEATMAP)) } },
      { provide: ProfilesApi, useValue: { stats: vi.fn(options.userStats ?? (() => of(STATS))), heatmap: vi.fn(() => of(HEATMAP)) } },
      ...(options.sheets ? [] : [{ provide: ReadingSheetsService, useValue: { openStats: vi.fn() } }]),
    ],
  });
  TestBed.inject(SessionStore).setMe(testMe());
}

async function render<T>(
  component: Type<T>,
  options: Options & { inputs?: Record<string, unknown> } = {},
): Promise<{ fixture: ComponentFixture<T>; root: HTMLElement }> {
  configure(options);
  const fixture = TestBed.createComponent(component);
  for (const [name, value] of Object.entries(options.inputs ?? {})) fixture.componentRef.setInput(name, value);
  await fixture.whenStable();
  fixture.detectChanges();
  return { fixture, root: fixture.nativeElement as HTMLElement };
}

const text = (root: HTMLElement) => root.textContent?.replace(/\s+/g, ' ') ?? '';

describe('reading stats views', () => {
  beforeEach(() => TestBed.resetTestingModule());

  describe('ReadingStatsCard', () => {
    it('shows the streak, freeze status, last 7 / 30 days, totals and top fields', async () => {
      const { root } = await render(ReadingStatsCard);
      const content = text(root);

      expect(content).toContain('12 days');
      expect(content).toContain('Longest: 30 days');
      expect(content).toContain('You read today');
      expect(content).toContain('A freeze is ready');
      expect(content).toContain('5 articles');
      expect(content).toContain('37 min');
      expect(content).toContain('19 articles');
      expect(content).toContain('48 articles');
      expect(content).toContain('.NET');
    });

    it('speaks Egyptian Arabic plurals', async () => {
      const { root } = await render(ReadingStatsCard, { lang: 'ar' });
      expect(text(root)).toContain('12 يوم');
      expect(text(root)).toContain('5 مقالات');
    });

    it('hands the fresh streak to the badge', async () => {
      await render(ReadingStatsCard);
      expect(TestBed.inject(StreakStore).streak()).toEqual(STREAK);
    });

    it('offers a retry when the stats fail to load', async () => {
      const { root } = await render(ReadingStatsCard, { stats: () => throwError(() => new ApiError(503, 'server.error', null)) });
      expect(root.querySelector('[role="alert"]')?.textContent).toContain('couldn’t load');
    });
  });

  describe('on a profile (F14)', () => {
    it('loads that user’s public stats, without the coaching meant for the owner', async () => {
      const { root } = await render(ReadingStatsCard, { inputs: { username: 'karim' } });
      expect(TestBed.inject(ProfilesApi).stats).toHaveBeenCalledWith('karim');
      expect(text(root)).toContain('12 days');
      expect(text(root)).toContain('48 articles');
      expect(text(root)).not.toContain('You read today');
      expect(text(root)).not.toContain('A freeze is ready');
    });

    it('says so when the stats turned private', async () => {
      const { root } = await render(ReadingStatsCard, {
        inputs: { username: 'karim' },
        userStats: () => throwError(() => new ApiError(403, 'profile.stats_private', null)),
      });
      expect(root.querySelector('[data-stats-private]')?.textContent).toContain('These reading stats are private.');
      expect(root.querySelector('[role="alert"]')).toBeNull();
    });

    it('the heatmap loads that user’s days', async () => {
      const { root } = await render(ReadingHeatmap, { inputs: { username: 'karim' } });
      expect(TestBed.inject(ProfilesApi).heatmap).toHaveBeenCalledWith('karim', 365);
      expect(root.querySelectorAll('[role="img"]')).toHaveLength(365);
    });
  });

  describe('ReadingHeatmap', () => {
    it('renders a labelled cell per day with distinct frozen days and a legend', async () => {
      const { root } = await render(ReadingHeatmap);
      const cells = root.querySelectorAll('[role="img"]');

      expect(cells).toHaveLength(365);
      expect(root.querySelector('[aria-label="Nov 2: 2 articles · 14 min"]')?.className).toContain('bg-primary/65');
      expect(root.querySelector('[aria-label="Nov 1: streak freeze"]')?.className).toContain('bg-callout-info-accent');
      expect(root.querySelector('[aria-label="Nov 3: no reading"]')?.className).toContain('ring-1'); // today
      expect(text(root)).toContain('3+');
    });
  });

  describe('StreakBadge', () => {
    it('labels the streak and opens the stats sheet', async () => {
      const { root } = await render(StreakBadge, { inputs: { streak: { ...STREAK, readToday: false, freezePending: true } } });
      const button = root.querySelector('button')!;

      expect(button.getAttribute('aria-label')).toBe(
        "Reading streak: 12 days. You haven't read today yet. Read today and a freeze keeps your streak",
      );
      expect(button.className).toContain('border-dashed');
      expect(button.textContent).toContain('❄');

      button.click();
      expect(TestBed.inject(ReadingSheetsService).openStats).toHaveBeenCalledOnce();
    });

    it('shows "—" until the streak is known', async () => {
      const { root } = await render(StreakBadge);
      expect(root.querySelector('button')?.textContent).toContain('—');
      expect(root.querySelector('button')?.getAttribute('aria-label')).toBe('Reading streak');
    });
  });

  describe('ReadingSheetsService', () => {
    afterEach(() => document.querySelectorAll('rd-reading-sheets').forEach((el) => el.remove()));

    it('loads the sheets on first use and opens the stats', async () => {
      configure({ sheets: true });
      const sheets = TestBed.inject(ReadingSheetsService);
      expect(document.querySelector('rd-reading-sheets')).toBeNull();

      sheets.openStats();
      await vi.waitFor(() => {
        TestBed.tick();
        expect(document.getElementById('rd-reading-stats-title')?.textContent).toContain('Reading stats');
        expect(document.querySelector('rd-reading-stats-card')?.textContent).toContain('12 days');
      });

      sheets.closeStats();
      TestBed.tick();
      expect(document.getElementById('rd-reading-stats-title')).toBeNull();
    });
  });

  describe('helpers', () => {
    it('picks the freeze line', () => {
      expect(freezeStatus({ freezePending: true, freezeAvailable: true })).toBe('pending');
      expect(freezeStatus({ freezePending: false, freezeAvailable: true })).toBe('available');
      expect(freezeStatus({ freezePending: false, freezeAvailable: false })).toBe('later');
    });

    it('maps a field color token to its CSS variable and refuses anything else', () => {
      expect(fieldColor('callout-info-accent')).toBe('var(--rd-color-callout-info-accent)');
      expect(fieldColor('red;background:url(x)')).toBe('var(--rd-color-primary)');
    });
  });
});

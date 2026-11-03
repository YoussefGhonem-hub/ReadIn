import { Pipe, PipeTransform, inject } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { UiLanguage } from '../../core/i18n/language.service';

/** Locales always use Western digits for consistency with code (SPEC §14.2 rule 4). */
export function intlLocale(lang: UiLanguage): string {
  return lang === 'ar' ? 'ar-EG-u-nu-latn' : 'en-US';
}

/** `{{ date | rdDate: lang() }}` → "12 أكتوبر 2026" / "Oct 12, 2026". The language argument keeps it pure. */
@Pipe({ name: 'rdDate' })
export class LocalizedDatePipe implements PipeTransform {
  transform(value: string | Date | null | undefined, lang: UiLanguage, style: 'medium' | 'long' | 'monthYear' = 'medium'): string {
    if (!value) return '';
    const date = typeof value === 'string' ? new Date(value) : value;
    if (Number.isNaN(date.getTime())) return '';
    const options: Intl.DateTimeFormatOptions =
      style === 'monthYear' ? { month: 'long', year: 'numeric' } : { day: 'numeric', month: style === 'long' ? 'long' : 'short', year: 'numeric' };
    return new Intl.DateTimeFormat(intlLocale(lang), options).format(date);
  }
}

const DIVISIONS: [Intl.RelativeTimeFormatUnit, number][] = [
  ['second', 60],
  ['minute', 60],
  ['hour', 24],
  ['day', 7],
  ['week', 4.34524],
  ['month', 12],
  ['year', Number.POSITIVE_INFINITY],
];

/** `{{ comment.createdAt | rdRelativeTime: lang() }}` → "من ساعتين" / "2 hours ago". */
@Pipe({ name: 'rdRelativeTime' })
export class RelativeTimePipe implements PipeTransform {
  transform(value: string | Date | null | undefined, lang: UiLanguage, now: Date = new Date()): string {
    if (!value) return '';
    const date = typeof value === 'string' ? new Date(value) : value;
    let duration = (date.getTime() - now.getTime()) / 1000;
    const format = new Intl.RelativeTimeFormat(intlLocale(lang), { numeric: 'auto' });
    for (const [unit, amount] of DIVISIONS) {
      if (Math.abs(duration) < amount) return format.format(Math.round(duration), unit);
      duration /= amount;
    }
    return '';
  }
}

/** `{{ 6 | rdReadingTime: lang() }}` → "6 دقايق" / "6 min read". */
@Pipe({ name: 'rdReadingTime' })
export class ReadingTimePipe implements PipeTransform {
  private readonly transloco = inject(TranslocoService);

  transform(minutes: number | null | undefined, lang: UiLanguage): string {
    const count = Math.max(1, Math.round(minutes ?? 1));
    return this.transloco.translate('common.readingTime', { count }, lang);
  }
}

/** `{{ 2400 | rdCompactNumber: lang() }}` → "2.4K". */
@Pipe({ name: 'rdCompactNumber' })
export class CompactNumberPipe implements PipeTransform {
  transform(value: number | null | undefined, lang: UiLanguage): string {
    return new Intl.NumberFormat(intlLocale(lang), { notation: 'compact', maximumFractionDigits: 1 }).format(value ?? 0);
  }
}

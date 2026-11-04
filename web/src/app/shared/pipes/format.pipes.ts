import { Pipe, PipeTransform, inject } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { UiLanguage } from '../../core/i18n/language.service';
import { intlLocale, translatePlural } from './intl';

export { intlLocale, translatePlural } from './intl';

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

/** `{{ 6 | rdReadingTime: lang() }}` → "6 دقايق قراءة" / "6 min read" (Arabic plural forms: "دقيقتين قراءة", "11 دقيقة قراءة"). */
@Pipe({ name: 'rdReadingTime' })
export class ReadingTimePipe implements PipeTransform {
  private readonly transloco = inject(TranslocoService);

  transform(minutes: number | null | undefined, lang: UiLanguage): string {
    const count = Math.max(1, Math.round(minutes ?? 1));
    return translatePlural(this.transloco, 'common.readingTime', count, lang);
  }
}

/** `{{ 2400 | rdCompactNumber: lang() }}` → "2.4K". */
@Pipe({ name: 'rdCompactNumber' })
export class CompactNumberPipe implements PipeTransform {
  transform(value: number | null | undefined, lang: UiLanguage): string {
    return new Intl.NumberFormat(intlLocale(lang), { notation: 'compact', maximumFractionDigits: 1 }).format(value ?? 0);
  }
}

/** "2.3 ميجا" / "2.3 MB", "830 كيلو" / "830 KB": Western digits in both languages, the unit in the UI language. */
export function formatFileSize(transloco: TranslocoService, bytes: number, lang: UiLanguage): string {
  const megabytes = bytes >= 1024 * 1024;
  const size = megabytes ? (bytes / (1024 * 1024)).toFixed(1) : String(Math.max(1, Math.round(bytes / 1024)));
  return transloco.translate(megabytes ? 'common.fileSize.mb' : 'common.fileSize.kb', { size }, lang);
}

/** `{{ file.size | rdFileSize: lang() }}` → "2.3 ميجا" / "2.3 MB". */
@Pipe({ name: 'rdFileSize' })
export class FileSizePipe implements PipeTransform {
  private readonly transloco = inject(TranslocoService);

  transform(bytes: number | null | undefined, lang: UiLanguage): string {
    return formatFileSize(this.transloco, bytes ?? 0, lang);
  }
}

/** `{{ 12 | rdPlural: 'media.pageCount' : lang() }}` → "12 صفحة" / "12 pages". */
@Pipe({ name: 'rdPlural' })
export class PluralPipe implements PipeTransform {
  private readonly transloco = inject(TranslocoService);

  transform(count: number | null | undefined, key: string, lang: UiLanguage, params: Record<string, unknown> = {}): string {
    return translatePlural(this.transloco, key, count ?? 0, lang, params);
  }
}

import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { translocoTesting } from '../../../testing/transloco-testing';
import { FileSizePipe, ReadingTimePipe, formatFileSize } from './format.pipes';

describe('Reading time and file sizes in the UI language', () => {
  beforeEach(() => {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({ imports: [translocoTesting()], providers: [ReadingTimePipe, FileSizePipe] });
  });

  it('reading time uses the Arabic plural forms, like the app (mobile readingTime)', () => {
    const pipe = TestBed.inject(ReadingTimePipe);
    expect([1, 2, 3, 10, 11, 25, 100].map((n) => pipe.transform(n, 'ar'))).toEqual([
      'دقيقة قراءة',
      'دقيقتين قراءة',
      '3 دقايق قراءة',
      '10 دقايق قراءة',
      '11 دقيقة قراءة',
      '25 دقيقة قراءة',
      '100 دقيقة قراءة',
    ]);
    expect([1, 6].map((n) => pipe.transform(n, 'en'))).toEqual(['1 min read', '6 min read']);
    // Never "0 minutes": a short article reads as one minute.
    expect(pipe.transform(0, 'ar')).toBe('دقيقة قراءة');
    expect(pipe.transform(null, 'en')).toBe('1 min read');
  });

  it('file sizes keep Western digits and say the unit in the UI language', () => {
    const transloco = TestBed.inject(TranslocoService);
    expect(formatFileSize(transloco, 850_000, 'ar')).toBe('830 كيلو');
    expect(formatFileSize(transloco, 2_500_000, 'ar')).toBe('2.4 ميجا');
    expect(formatFileSize(transloco, 10, 'ar')).toBe('1 كيلو');
    expect(formatFileSize(transloco, 850_000, 'en')).toBe('830 KB');
    expect(TestBed.inject(FileSizePipe).transform(2_500_000, 'en')).toBe('2.4 MB');
  });
});

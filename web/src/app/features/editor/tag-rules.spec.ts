import { addTag, cleanTagName, hasTag, normalizeTagName, tagNameProblem } from './tag-rules';

/** The server's tag rules (docs/api/contract-v1.md → Tags), applied by the editor before a chip is added (F32). */
describe('tag names (F32)', () => {
  it('rule 1: removes format characters, leading #s and extra spaces, and writes Arabic-Indic digits as 0–9', () => {
    expect(cleanTagName('  ##AI  ')).toBe('AI');
    expect(cleanTagName('#  clean \t  architecture ')).toBe('clean architecture');
    expect(cleanTagName('‏الذكاء‌ الاصطناعي⁩')).toBe('الذكاء الاصطناعي');
    expect(cleanTagName('ويب ٣')).toBe('ويب 3');
    expect(cleanTagName('دوت نت ۱۰')).toBe('دوت نت 10');
    // Only leading #s go: C# keeps its own.
    expect(cleanTagName('#C#')).toBe('C#');
    expect(cleanTagName('   ')).toBe('');
  });

  it('rule 2: 2–30 characters; letters, marks, digits, spaces and - _ . + #; at least one letter or digit', () => {
    for (const ok of ['C#', '.NET', 'C++', 'ASP.NET Core', 'machine_learning', 'web-3', 'الذكاء الاصطناعي', 'عِلم', 'ai', 'x'.repeat(30)]) {
      expect(tagNameProblem(ok), ok).toBeNull();
    }
    expect(tagNameProblem('a')).toBe('tooShort');
    expect(tagNameProblem('x'.repeat(31))).toBe('tooLong');
    expect(tagNameProblem('CI/CD')).toBe('charset');
    expect(tagNameProblem('Span<T>')).toBe('charset');
    expect(tagNameProblem('🔥 hot')).toBe('charset');
    expect(tagNameProblem('--')).toBe('noLetter');
    expect(tagNameProblem('+#')).toBe('noLetter');
    // Tatweel is a letter to Unicode (\p{Lm}) but not to the server: it only stretches the letters around it.
    for (const stretched of ['ــ', 'ـــ', 'ـَـ', 'ـ-ـ']) {
      expect(tagNameProblem(stretched), stretched).toBe('noLetter');
    }
    expect(tagNameProblem('عـلم')).toBeNull();
  });

  it('rule 3: one tag ignoring case, leading #s and Arabic spelling variants', () => {
    expect(normalizeTagName('#AI')).toBe(normalizeTagName('ai'));
    expect(normalizeTagName('الذَّكاء')).toBe(normalizeTagName('الذكاء'));
    expect(normalizeTagName('إدارة')).toBe('اداره');
    expect(normalizeTagName('آمن')).toBe(normalizeTagName('امن'));
    expect(normalizeTagName('مستشفى')).toBe(normalizeTagName('مستشفي'));
    expect(normalizeTagName('تـــطوير')).toBe(normalizeTagName('تطوير'));
    expect(normalizeTagName('C#')).not.toBe(normalizeTagName('C++'));
    expect(hasTag(['Machine Learning'], 'machine learning')).toBe(true);
    expect(hasTag(['C#'], 'C')).toBe(false);
  });

  it('adds a new name only when it follows the rules; an existing tag as it is', () => {
    expect(addTag([], ' #.NET ')).toEqual(['.NET']);
    expect(addTag(['AI'], 'ai')).toEqual(['AI']);
    expect(addTag([], 'CI/CD')).toEqual([]);
    // An existing tag may predate the rules: picked from the suggestions, it is added.
    expect(addTag([], 'CI/CD', true)).toEqual(['CI/CD']);
    expect(addTag(['ab', 'bc', 'cd', 'de', 'ef'], 'CI/CD', true)).toHaveLength(5);
  });
});

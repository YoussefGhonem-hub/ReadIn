import { CATEGORY_NAME_MAX, categoryLink, categoryNameProblem, categoryNameTaken, categoryPath, cleanCategoryName, normalizeCategoryName } from './category-rules';

describe('writer category names (F31, contract "Writer categories" → Names)', () => {
  it('cleans like a tag name, but a leading # stays', () => {
    expect(cleanCategoryName('  ASP.NET   Core \t')).toBe('ASP.NET Core');
    expect(cleanCategoryName('#Tips')).toBe('#Tips');
    // Invisible format characters (here RLM and a zero-width joiner) and control characters go; ٠–٩ become 0–9.
    expect(cleanCategoryName('‏نصايح‍ ٢٠٢٦\u0007')).toBe('نصايح 2026');
    expect(cleanCategoryName('Line\none')).toBe('Line one');
  });

  it('needs 1–40 characters (UTF-16 units) with a letter or digit; punctuation and emoji are fine', () => {
    expect(categoryNameProblem('')).toBe('empty');
    expect(categoryNameProblem('a'.repeat(CATEGORY_NAME_MAX))).toBeNull();
    expect(categoryNameProblem('a'.repeat(CATEGORY_NAME_MAX + 1))).toBe('tooLong');
    expect(categoryNameProblem('!!! 🎉')).toBe('noLetter');
    // Tatweel only stretches letters, it isn't one.
    expect(categoryNameProblem('ـــ')).toBe('noLetter');
    expect(categoryNameProblem('Docker 🐳')).toBeNull();
    expect(categoryNameProblem('C#')).toBeNull();
    expect(categoryNameProblem('7')).toBeNull();
  });

  it('compares names ignoring case and Arabic spelling variants; the one being renamed is not a clash', () => {
    expect(normalizeCategoryName('AI')).toBe(normalizeCategoryName('ai'));
    expect(normalizeCategoryName('أفكار جاية')).toBe(normalizeCategoryName('افكار جايه'));
    expect(normalizeCategoryName('#AI')).not.toBe(normalizeCategoryName('AI'));
    const mine = [
      { id: 'c1', name: 'ASP.NET Core' },
      { id: 'c2', name: 'أفكار جاية' },
    ];
    expect(categoryNameTaken(mine, 'asp.net core')).toBe(true);
    expect(categoryNameTaken(mine, 'إفكار جايه')).toBe(true);
    expect(categoryNameTaken(mine, 'Docker')).toBe(false);
    expect(categoryNameTaken(mine, 'asp.net CORE', 'c1')).toBe(false);
  });

  it('links a category page by its slug, never by its name', () => {
    expect(categoryLink('mona', 'نصايح-البرمجة')).toEqual(['/@mona', 'c', 'نصايح-البرمجة']);
    expect(categoryPath('mona', 'نصايح-البرمجة')).toBe('/@mona/c/%D9%86%D8%B5%D8%A7%D9%8A%D8%AD-%D8%A7%D9%84%D8%A8%D8%B1%D9%85%D8%AC%D8%A9');
    expect(categoryPath('mona', '_other')).toBe('/@mona/c/_other');
  });
});

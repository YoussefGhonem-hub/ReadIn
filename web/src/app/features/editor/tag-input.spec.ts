import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { translocoTesting } from '../../../testing/transloco-testing';
import { TagDto } from '../../core/api/models';
import { TagsApi } from '../../core/api/tags.api';
import { provideAppIcons } from '../../shared/ui/icons';
import { TagInput } from './tag-input';

/** Longer than the field's suggestion debounce (250 ms). */
const SETTLE_MS = 320;
const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const TAGS: TagDto[] = [
  { slug: 'csharp', name: 'C#', articleCount: 23 },
  { slug: 'cplusplus', name: 'C++', articleCount: 4 },
  { slug: 'ci-cd', name: 'CI/CD', articleCount: 1 },
  { slug: 'ai', name: 'AI', articleCount: 9 },
];

/** Like the API: a word of the name starts with `q` (case-insensitive), most used first. */
function search(q: string) {
  const query = q.toLowerCase();
  return of(TAGS.filter((t) => t.name.toLowerCase().startsWith(query)).sort((a, b) => b.articleCount - a.articleCount));
}

async function render(tags: string[] = [], inputs: { flagged?: string[]; errors?: { code: string; tag: string | null }[] } = {}) {
  TestBed.resetTestingModule();
  const api = { search: vi.fn(search) };
  TestBed.configureTestingModule({ imports: [translocoTesting()], providers: [provideAppIcons(), { provide: TagsApi, useValue: api }] });
  const fixture = TestBed.createComponent(TagInput);
  const emitted: string[][] = [];
  fixture.componentRef.setInput('tags', tags);
  if (inputs.flagged) fixture.componentRef.setInput('flagged', inputs.flagged);
  if (inputs.errors) fixture.componentRef.setInput('errors', inputs.errors);
  // The editor writes the change back into the document, which flows in again.
  fixture.componentInstance.tagsChange.subscribe((next) => {
    emitted.push(next);
    fixture.componentRef.setInput('tags', next);
  });
  fixture.detectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  const $$ = (selector: string) => [...root.querySelectorAll<HTMLElement>(selector)];
  const field = () => $<HTMLInputElement>('[data-tag-input]')!;
  const stable = async () => {
    fixture.detectChanges();
    await fixture.whenStable();
  };
  const type = async (text: string, settle = true) => {
    field().value = text;
    field().dispatchEvent(new Event('input'));
    await stable();
    if (settle) {
      await wait(SETTLE_MS);
      await stable();
    }
  };
  const key = async (name: string) => {
    field().dispatchEvent(new KeyboardEvent('keydown', { key: name, cancelable: true }));
    await stable();
  };
  const chips = () => $$('[data-tag]').map((c) => c.getAttribute('data-tag'));
  return { fixture, root, api, emitted, $, $$, field, type, key, chips, stable };
}

describe('TagInput (F32)', () => {
  it('suggests existing tags while typing, most used first, and adds a picked one as it is', async () => {
    const t = await render();
    await t.type('c');
    expect(t.api.search).toHaveBeenCalledWith('c', 8);
    expect(t.field().getAttribute('aria-expanded')).toBe('true');
    expect(t.$$('[data-tag-option]').map((o) => o.getAttribute('data-tag-option'))).toEqual(['C#', 'C++', 'CI/CD']);
    // "CI/CD" breaks today's rules, but it exists: picking it adds it.
    t.$('[data-tag-option="CI/CD"]')!.click();
    await t.stable();
    expect(t.chips()).toEqual(['CI/CD']);
    expect(t.field().value).toBe('');
    expect(t.$('[data-tag-suggestions]')).toBeNull();
  });

  it('offers "Create new tag" when no suggestion is that tag; Enter on an exact match adds the existing spelling', async () => {
    const t = await render();
    await t.type('#Clean   Code');
    const create = t.$('[data-tag-create]')!;
    expect(create.getAttribute('data-tag-create')).toBe('Clean Code');
    expect(create.textContent!.replace(/\s+/g, ' ').trim()).toBe('إنشاء وسم جديد: #Clean Code');
    create.click();
    await t.stable();
    expect(t.chips()).toEqual(['Clean Code']);

    // "ai" is the tag "AI": no create option, and Enter adds "AI".
    await t.type('ai');
    expect(t.$('[data-tag-create]')).toBeNull();
    await t.key('Enter');
    expect(t.chips()).toEqual(['Clean Code', 'AI']);
  });

  it('arrow keys move through the options and Enter picks the active one; Escape closes the list', async () => {
    const t = await render();
    await t.type('c');
    await t.key('ArrowDown');
    await t.key('ArrowDown');
    expect(t.field().getAttribute('aria-activedescendant')).toMatch(/-list-1$/);
    await t.key('Enter');
    expect(t.chips()).toEqual(['C++']);

    await t.type('c');
    await t.key('Escape');
    expect(t.$('[data-tag-suggestions]')).toBeNull();
    expect(t.field().getAttribute('aria-expanded')).toBe('false');
  });

  it('applies the rules to a new name with an inline message, and keeps the text to fix', async () => {
    const t = await render();
    // A character more typing can't fix shows as soon as the suggestions are in.
    await t.type('a/b');
    expect(t.$('[data-tag-problem]')!.getAttribute('data-rule')).toBe('charset');
    expect(t.field().getAttribute('aria-invalid')).toBe('true');
    expect(t.field().getAttribute('aria-describedby')).toContain('-problem');
    expect(t.$('[data-tag-create]')).toBeNull();

    // Too short only once you try to add it.
    await t.type('x');
    expect(t.$('[data-tag-problem]')).toBeNull();
    await t.key('Enter');
    expect(t.$('[data-tag-problem]')!.textContent).toContain('يجب أن يتكون الوسم من حرفين على الأقل.');
    expect(t.field().value).toBe('x');
    expect(t.emitted).toEqual([]);

    await t.type('x'.repeat(31));
    expect(t.$('[data-tag-problem]')!.getAttribute('data-rule')).toBe('tooLong');
    await t.type('--');
    await t.key('Enter');
    expect(t.$('[data-tag-problem]')!.getAttribute('data-rule')).toBe('noLetter');
  });

  it('a comma (or the Arabic "،") adds the typed tag; repeats are ignored, also by case and Arabic spelling', async () => {
    const t = await render(['AI', 'الذكاء']);
    await t.type('dotnet,', false);
    expect(t.chips()).toEqual(['AI', 'الذكاء', 'dotnet']);
    expect(t.field().value).toBe('');
    await t.type('flutter، ', false);
    expect(t.chips()).toEqual(['AI', 'الذكاء', 'dotnet', 'flutter']);
    // Already there: ignored, nothing emitted.
    await t.type('#ai,الذَّكاء,', false);
    expect(t.chips()).toEqual(['AI', 'الذكاء', 'dotnet', 'flutter']);
    expect(t.emitted).toHaveLength(2);
    // A pasted list stops at the first name that breaks a rule, which stays in the input with its message.
    await t.type('a/b, kotlin', false);
    expect(t.field().value).toBe('a/b');
    expect(t.$('[data-tag-problem]')!.getAttribute('data-rule')).toBe('charset');
  });

  it('at 5 tags the input is disabled with a hint; removing a chip enables it again', async () => {
    const t = await render(['C#', 'AI', 'dotnet', 'flutter']);
    await t.type('kotlin,', false);
    expect(t.chips()).toHaveLength(5);
    expect(t.field().disabled).toBe(true);
    expect(t.$('[data-tags-hint]')!.textContent).toContain('هذه 5 وسوم');

    t.$$('[data-tag-remove]')[0].click();
    await t.stable();
    expect(t.chips()).toEqual(['AI', 'dotnet', 'flutter', 'kotlin']);
    expect(t.field().disabled).toBe(false);
    expect(t.$('[data-tags-hint]')!.textContent).toContain('حتى 5');
  });

  it('Backspace in the empty input removes the last chip; every chip has a labelled remove button', async () => {
    const t = await render(['C#', 'AI']);
    expect(t.$$('[data-tag-remove]').map((b) => b.getAttribute('aria-label'))).toEqual(['إزالة الوسم C#', 'إزالة الوسم AI']);
    await t.key('Backspace');
    expect(t.chips()).toEqual(['C#']);
  });

  it('marks the chips the last checks or save are about, and lists why a save was refused', async () => {
    const t = await render(['C#', 'spam-links'], { flagged: ['SPAM-links'], errors: [{ code: 'tag.invalid', tag: 'spam-links' }, { code: 'article.too_many_tags', tag: null }] });
    expect(t.$$('[data-flagged]').map((c) => c.getAttribute('data-tag'))).toEqual(['spam-links']);
    expect(t.$('[data-flagged] [data-tag-remove]')!.getAttribute('aria-label')).toBe('إزالة الوسم spam-links (به مشكلة)');
    const errors = t.$$('[data-tag-error]');
    expect(errors.map((e) => e.getAttribute('data-tag-error'))).toEqual(['tag.invalid', 'article.too_many_tags']);
    expect(errors[0].textContent).toContain('#spam-links');
    expect(errors[1].textContent).toContain('الحد الأقصى 5 وسوم للمقال الواحد.');
    expect(t.field().getAttribute('aria-describedby')).toContain('-errors');
  });
});

import { completeSources, isCompleteSource } from './sources-editor';
import { MAX_TAGS, TAG_MAX_LENGTH, addTag } from './tag-input';

describe('article settings rules (the contract rejects a save that breaks them)', () => {
  it('tags (F32): cleaned, at most 30 characters, no repeats ignoring case, at most 5', () => {
    expect(addTag([], '  #dotnet  ')).toEqual(['dotnet']);
    expect(addTag(['dotnet'], 'DotNet')).toEqual(['dotnet']);
    // Too long is refused (the field says why), no longer cut to fit.
    expect(addTag([], 'x'.repeat(TAG_MAX_LENGTH))).toEqual(['x'.repeat(TAG_MAX_LENGTH)]);
    expect(addTag([], 'x'.repeat(TAG_MAX_LENGTH + 1))).toEqual([]);
    expect(addTag(['ab', 'bc', 'cd', 'de', 'ef'], 'fg')).toHaveLength(MAX_TAGS);
    expect(addTag(['ab'], '   ')).toEqual(['ab']);
    expect(addTag([], 'clean   architecture')).toEqual(['clean architecture']);
  });

  it('sources: only rows with a title and an http(s) link are saved', () => {
    const rows = [
      { id: 1, title: ' Microsoft Learn ', url: ' https://learn.microsoft.com ' },
      { id: 2, title: 'No link', url: '' },
      { id: 3, title: '', url: 'https://example.com' },
      { id: 4, title: 'Script', url: 'javascript:alert(1)' },
      { id: 5, title: 'HTTP', url: 'http://example.com/a' },
    ];
    expect(rows.map(isCompleteSource)).toEqual([true, false, false, false, true]);
    expect(completeSources(rows)).toEqual([
      { title: 'Microsoft Learn', url: 'https://learn.microsoft.com' },
      { title: 'HTTP', url: 'http://example.com/a' },
    ]);
  });
});

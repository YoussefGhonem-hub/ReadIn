import { commentDir, commentSegments, insertMention, isPlaceholder, mentionAt } from './comment-text';

const mention = (username: string) => ({ userId: `id-${username}`, username });

describe('commentSegments (F11 mentions)', () => {
  it('links only the handles the API resolved; other @words stay text', () => {
    expect(commentSegments('Thanks @karim and @nobody!', [mention('karim')])).toEqual([
      { kind: 'text', text: 'Thanks ' },
      { kind: 'mention', text: '@karim', username: 'karim' },
      { kind: 'text', text: ' and @nobody!' },
    ]);
  });

  it('finds a mention right after Arabic text ("و@writer1")', () => {
    expect(commentSegments('شكراً و@writer1 على المقال', [mention('writer1')])).toEqual([
      { kind: 'text', text: 'شكراً و' },
      { kind: 'mention', text: '@writer1', username: 'writer1' },
      { kind: 'text', text: ' على المقال' },
    ]);
  });

  it('never treats an e-mail or a handle glued to Latin text as a mention', () => {
    const resolved = [mention('karim')];
    expect(commentSegments('mail me at me@karim.dev', resolved)).toEqual([{ kind: 'text', text: 'mail me at me@karim.dev' }]);
    expect(commentSegments('x@karim', resolved)).toEqual([{ kind: 'text', text: 'x@karim' }]);
    // A longer handle that only starts with a resolved one is someone else.
    expect(commentSegments('@karimx', resolved)).toEqual([{ kind: 'text', text: '@karimx' }]);
  });

  it('matches handles case-insensitively and links every occurrence, keeping line breaks in the text', () => {
    expect(commentSegments('@Karim\nagain @karim', [mention('karim')])).toEqual([
      { kind: 'mention', text: '@Karim', username: 'karim' },
      { kind: 'text', text: '\nagain ' },
      { kind: 'mention', text: '@karim', username: 'karim' },
    ]);
  });

  it('is plain text without mentions and empty for placeholders', () => {
    expect(commentSegments('hi @karim', [])).toEqual([{ kind: 'text', text: 'hi @karim' }]);
    expect(commentSegments(null, [mention('karim')])).toEqual([]);
  });

  it('keeps markup as text (rendered with interpolation, never innerHTML)', () => {
    expect(commentSegments('<b>@karim</b>', [mention('karim')])).toEqual([
      { kind: 'text', text: '<b>' },
      { kind: 'mention', text: '@karim', username: 'karim' },
      { kind: 'text', text: '</b>' },
    ]);
  });
});

describe('mentionAt / insertMention (composer)', () => {
  it('finds the handle being typed at the caret, also after an Arabic letter', () => {
    expect(mentionAt('hello @kar', 10)).toEqual({ query: 'kar', start: 6, end: 10 });
    expect(mentionAt('و@كر', 4)).toEqual({ query: 'كر', start: 1, end: 4 });
    expect(mentionAt('@', 1)).toEqual({ query: '', start: 0, end: 1 });
  });

  it('ignores e-mails and text without an @ right before the caret', () => {
    expect(mentionAt('me@karim', 8)).toBeNull();
    expect(mentionAt('hello @karim there', 18)).toBeNull();
    expect(mentionAt('hello', 5)).toBeNull();
  });

  it('replaces the whole handle under the caret with "@username " and moves the caret after it', () => {
    const at = mentionAt('hi @ka and more', 6)!; // caret inside "@ka|"
    expect(at).toEqual({ query: 'ka', start: 3, end: 6 });
    expect(insertMention('hi @ka and more', at, 'karim')).toEqual({ text: 'hi @karim and more', caret: 10 });
    expect(insertMention('@ka', mentionAt('@ka', 3)!, 'karim')).toEqual({ text: '@karim ', caret: 7 });
  });
});

describe('isPlaceholder', () => {
  it('is a deleted comment, or a hidden one without text', () => {
    expect(isPlaceholder({ isDeleted: true, isHidden: false, body: null })).toBe(true);
    expect(isPlaceholder({ isDeleted: false, isHidden: true, body: null })).toBe(true);
    expect(isPlaceholder({ isDeleted: false, isHidden: true, body: 'mine' })).toBe(false); // you or a moderator
    expect(isPlaceholder({ isDeleted: false, isHidden: false, body: 'hi' })).toBe(false);
  });
});

describe('commentDir (SPEC §14)', () => {
  it('ignores a leading @handle, so an Arabic reply stays right to left', () => {
    expect(commentDir('@reader1 لو عايز تتعمق أكتر')).toBe('rtl');
    expect(commentDir('@reader2 it is in the repo')).toBe('ltr');
  });

  it('follows the first strong letter otherwise', () => {
    expect(commentDir('Great read، شكرًا')).toBe('ltr');
    expect(commentDir('مقال مفيد about RAG')).toBe('rtl');
  });

  it('falls back to the handles, and to nothing for empty text', () => {
    expect(commentDir('@reader1 👍')).toBe('ltr');
    expect(commentDir('')).toBeNull();
  });
});

import 'package:flutter_test/flutter_test.dart';
import 'package:readin/shared/rdoc/editing/block_editing.dart';
import 'package:readin/shared/rdoc/editing/inline_editing.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

const bold = RMark(RMarkType.bold);
const code = RMark(RMarkType.code);
const mention = RMention(userId: 'u-1', text: '@mona');
const term = RTerm(termId: 'di', text: 'DI');

void main() {
  group('replaceRange', () {
    test('typing inside a marked word keeps the mark; typing after it continues it', () {
      const nodes = [RText('Use '), RText('Scoped', marks: [bold]), RText(' here')];
      expect(InlineEditing.replaceRange(nodes, 7, 7, 'X').nodes, const [RText('Use '), RText('ScoXped', marks: [bold]), RText(' here')]);
      expect(InlineEditing.replaceRange(nodes, 10, 10, '!').nodes, const [RText('Use '), RText('Scoped!', marks: [bold]), RText(' here')]);
    });

    test('a link is not continued past its end', () {
      const link = RMark(RMarkType.link, href: 'https://a.dev');
      const nodes = [RText('docs', marks: [link])];
      expect(InlineEditing.replaceRange(nodes, 4, 4, ' x').nodes, const [RText('docs', marks: [link]), RText(' x')]);
    });

    test('deleting across nodes merges what is left', () {
      const nodes = [RText('ab'), RText('cd', marks: [bold]), RText('ef')];
      final result = InlineEditing.replaceRange(nodes, 1, 5, '');
      expect(result.nodes, const [RText('af')]);
      expect(result.caret, 1);
    });

    test('mentions, terms and hard breaks are atomic', () {
      const nodes = [RText('شكراً '), mention, RText(' و '), term, RHardBreak(), RText('!')];
      // Backspace on the last character of the mention removes it whole.
      expect(InlineEditing.replaceRange(nodes, 10, 11, '').nodes, const [RText('شكراً  و '), term, RHardBreak(), RText('!')]);
      // Typing inside a term goes after it.
      final typed = InlineEditing.replaceRange(nodes, 15, 15, 'x');
      expect(typed.nodes, const [RText('شكراً '), mention, RText(' و '), term, RText('x'), RHardBreak(), RText('!')]);
      expect(typed.caret, 17);
      // Deleting the line break.
      expect(InlineEditing.replaceRange(nodes, 16, 17, '').nodes, const [RText('شكراً '), mention, RText(' و '), term, RText('!')]);
    });

    test('diff uses the caret to place a repeated character', () {
      expect(InlineEditing.diff('aa', 'aaa', caret: 1), (start: 0, end: 0, insert: 'a'));
      expect(InlineEditing.diff('ab', 'abc'), (start: 2, end: 2, insert: 'c'));
      expect(InlineEditing.diff('abc', 'ac', caret: 1), (start: 1, end: 2, insert: ''));
    });

    test('applyTextChange types into the right node', () {
      const nodes = [RText('a', marks: [bold]), RText('a')];
      final result = InlineEditing.applyTextChange(nodes, 'aXa', caret: 2);
      expect(result.nodes, const [RText('aX', marks: [bold]), RText('a')]);
    });
  });

  group('marks', () {
    test('toggleMark adds a mark to a range, and removes it when all of it has it', () {
      const nodes = [RText('Hello world')];
      final once = InlineEditing.toggleMark(nodes, 6, 11, RMarkType.bold);
      expect(once, const [RText('Hello '), RText('world', marks: [bold])]);
      expect(InlineEditing.toggleMark(once, 6, 11, RMarkType.bold), nodes);
      // A range only partly bold becomes all bold.
      expect(InlineEditing.toggleMark(once, 0, 11, RMarkType.bold), const [RText('Hello world', marks: [bold])]);
    });

    test('marks skip atomic nodes', () {
      const nodes = [RText('a '), mention, RText(' b')];
      expect(InlineEditing.toggleMark(nodes, 0, 11, RMarkType.code), const [RText('a ', marks: [code]), mention, RText(' b', marks: [code])]);
    });

    test('setLink accepts http(s) only and replaces an existing link', () {
      const nodes = [RText('read the docs')];
      final linked = InlineEditing.setLink(nodes, 9, 13, 'https://learn.microsoft.com');
      expect(InlineEditing.linkAt(linked, 10, 10), 'https://learn.microsoft.com');
      expect(InlineEditing.setLink(nodes, 9, 13, 'javascript:alert(1)'), nodes);
      expect(InlineEditing.setLink(linked, 9, 13, null), nodes);
      expect(InlineEditing.isHttpUrl('ftp://x'), isFalse);
      expect(InlineEditing.isHttpUrl('https://x.dev/a?b=1'), isTrue);
    });
  });

  test('insertMention replaces the typed query and adds a space', () {
    const nodes = [RText('شكراً @mo')];
    final result = InlineEditing.insertMention(nodes, 6, 9, userId: 'u-1', text: '@mona');
    expect(result.nodes, const [RText('شكراً '), mention, RText(' ')]);
    expect(result.caret, 12);
  });

  test('insertHardBreak and splitAt', () {
    final broken = InlineEditing.insertHardBreak(const [RText('ab')], 1);
    expect(broken.nodes, const [RText('a'), RHardBreak(), RText('b')]);
    final (before, after) = InlineEditing.splitAt(const [RText('abc', marks: [bold]), mention], 2);
    expect(before, const [RText('ab', marks: [bold])]);
    expect(after, const [RText('c', marks: [bold]), mention]);
  });

  group('markdown shortcuts', () {
    test('block markers at the start of a paragraph', () {
      expect(MarkdownShortcuts.blockShortcut('# '), (kind: RBlockKind.heading2, marker: 2, lang: null));
      expect(MarkdownShortcuts.blockShortcut('### Title'), (kind: RBlockKind.heading3, marker: 4, lang: null));
      expect(MarkdownShortcuts.blockShortcut('- '), (kind: RBlockKind.bulletList, marker: 2, lang: null));
      expect(MarkdownShortcuts.blockShortcut('1. '), (kind: RBlockKind.orderedList, marker: 3, lang: null));
      expect(MarkdownShortcuts.blockShortcut('> '), (kind: RBlockKind.quote, marker: 2, lang: null));
      expect(MarkdownShortcuts.blockShortcut('```dart '), (kind: RBlockKind.code, marker: 8, lang: 'dart'));
      expect(MarkdownShortcuts.blockShortcut('---'), (kind: RBlockKind.divider, marker: 3, lang: null));
      expect(MarkdownShortcuts.blockShortcut('plain text'), isNull);
      expect(MarkdownShortcuts.blockShortcut('#hashtag'), isNull);
    });

    test('inline delimiters become marks once closed', () {
      final result = MarkdownShortcuts.inlineShortcut(const [RText('use **Scoped**')], 14)!;
      expect(result.nodes, const [RText('use '), RText('Scoped', marks: [bold])]);
      expect(result.caret, 10);
      expect(MarkdownShortcuts.inlineShortcut(const [RText('call `Build()`')], 14)!.nodes, const [RText('call '), RText('Build()', marks: [code])]);
      expect(MarkdownShortcuts.inlineShortcut(const [RText('a ~~b~~')], 7)!.nodes, const [RText('a '), RText('b', marks: [RMark(RMarkType.strike)])]);
      // Never across a mention.
      expect(MarkdownShortcuts.inlineShortcut(const [RText('**a '), mention, RText('**')], 13), isNull);
    });

    test('the slash menu query', () {
      expect(MarkdownShortcuts.slashQuery('/'), '');
      expect(MarkdownShortcuts.slashQuery('/cod'), 'cod');
      expect(MarkdownShortcuts.slashQuery('/a b'), isNull);
      expect(MarkdownShortcuts.slashQuery('a/'), isNull);
    });
  });
}

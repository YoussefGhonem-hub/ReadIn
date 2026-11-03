/// Builds RDoc JSON (shared/rdoc/rdoc.schema.json) from the composer's plain
/// text: paragraphs are separated by blank lines and become `paragraph`
/// blocks with `dir: "auto"`; single line breaks inside a paragraph become
/// `hardBreak` nodes. The full block editor (F05) replaces this later.
abstract final class RDocBuilder {
  /// Schema limit for one `text` node.
  static const maxTextLength = 20000;

  /// Schema limit for `blocks`.
  static const maxBlocks = 2000;

  static final _blankLine = RegExp(r'\n[ \t ]*\n');

  static List<String> paragraphsOf(String text) => text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split(_blankLine)
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  static Map<String, dynamic> fromPlainText(String text, {required String language}) {
    final paragraphs = paragraphsOf(text).take(maxBlocks).toList();
    return {
      'version': 1,
      'language': language,
      'blocks': [
        for (var i = 0; i < paragraphs.length; i++)
          {
            'id': 'p${i + 1}',
            'type': 'paragraph',
            'dir': 'auto',
            'content': _inline(paragraphs[i]),
          },
      ],
    };
  }

  static List<Map<String, dynamic>> _inline(String paragraph) {
    final nodes = <Map<String, dynamic>>[];
    final lines = paragraph.split('\n').map((l) => l.trimRight()).toList();
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) nodes.add({'type': 'hardBreak'});
      final line = lines[i];
      for (var start = 0; start < line.length; start += maxTextLength) {
        final end = start + maxTextLength < line.length ? start + maxTextLength : line.length;
        nodes.add({'type': 'text', 'text': line.substring(start, end)});
      }
    }
    return nodes;
  }
}

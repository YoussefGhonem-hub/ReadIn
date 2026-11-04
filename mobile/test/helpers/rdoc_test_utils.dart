import 'test_app.dart';

/// RDoc in a canonical form for comparing documents: `dir: "auto"` and empty `marks` are the defaults, so they are
/// left out, and neighbouring text runs with the same marks are one run (the same text, the same formatting; any
/// rich-text editor merges them).
Object? canonical(Object? json) {
  if (json is List) return _mergeRuns([for (final v in json) canonical(v)]);
  if (json is Map) {
    return {
      for (final e in json.entries)
        if (!(e.key == 'dir' && e.value == 'auto') && !(e.key == 'marks' && e.value is List && (e.value as List).isEmpty))
          e.key as String: canonical(e.value),
    };
  }
  return json;
}

List<Object?> _mergeRuns(List<Object?> items) {
  final out = <Object?>[];
  for (final item in items) {
    final last = out.isEmpty ? null : out.last;
    if (item is Map && last is Map && item['type'] == 'text' && last['type'] == 'text' && item.length == last.length) {
      final sameMarks = item['marks'] == null && last['marks'] == null ||
          (item['marks'] != null && last['marks'] != null && item['marks'].toString() == last['marks'].toString());
      if (sameMarks) {
        out[out.length - 1] = {...last, 'text': '${last['text']}${item['text']}'};
        continue;
      }
    }
    out.add(item);
  }
  return out;
}

List<Map<String, dynamic>> bidiFixtures() =>
    (readSharedJson('bidi/fixtures.json')['fixtures'] as List).cast<Map<String, dynamic>>();

/// One document per BiDi fixture: the text in every block kind that holds text, with a mention and a glossary term.
Map<String, dynamic> fixtureDocument(Map<String, dynamic> f) {
  final text = f['text'] as String;
  List<Map<String, dynamic>> inline() => [
        {'type': 'text', 'text': text},
        {'type': 'text', 'text': ' ', 'marks': []},
        {'type': 'term', 'termId': 'dependency-injection', 'text': 'Dependency Injection'},
        {'type': 'hardBreak'},
        {'type': 'mention', 'userId': '0195f3a0-0000-7000-8000-000000000001', 'text': '@youssef_dev'},
        {'type': 'text', 'text': 'link', 'marks': [{'type': 'link', 'href': 'https://learn.microsoft.com/dotnet/'}, {'type': 'bold'}]},
      ];
  final id = f['id'] as String;
  return {
    'version': 1,
    'language': 'ar-EG',
    'blocks': [
      {'id': '$id-p', 'type': 'paragraph', 'dir': 'auto', 'content': inline()},
      {'id': '$id-h', 'type': 'heading', 'level': 3, 'dir': 'rtl', 'content': inline()},
      {'id': '$id-l', 'type': 'orderedList', 'dir': 'ltr', 'items': [inline(), inline()]},
      {'id': '$id-s', 'type': 'steps', 'items': [{'title': text, 'content': inline()}]},
      {'id': '$id-q', 'type': 'quote', 'content': inline(), 'cite': text},
      {'id': '$id-c', 'type': 'callout', 'variant': 'warning', 'title': text, 'content': inline()},
      {'id': '$id-t', 'type': 'table', 'header': [inline()], 'rows': [[inline()]]},
      {'id': '$id-x', 'type': 'summary', 'content': inline()},
      {'id': '$id-i', 'type': 'image', 'src': 'https://example.com/a.png', 'alt': text, 'caption': text, 'width': 1200, 'height': 630},
    ],
  };
}


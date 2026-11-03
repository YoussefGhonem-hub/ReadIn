import 'package:equatable/equatable.dart';

import 'comment.dart';

/// A piece of a comment's text: plain, or an `@handle` the API resolved ([mention] set).
class CommentSegment extends Equatable {
  const CommentSegment(this.text, {this.mention});

  final String text;
  final CommentMention? mention;

  bool get isMention => mention != null;

  @override
  List<Object?> get props => [text, mention];
}

/// The `@word` being typed in the composer: it starts at [start] (the `@`) and [query] runs up to the caret.
class MentionQuery extends Equatable {
  const MentionQuery({required this.start, required this.end, required this.query});

  final int start;
  final int end;
  final String query;

  @override
  List<Object?> get props => [start, end, query];
}

/// Comment text rules shared with the API (`CommentText` in the backend, docs/api/contract-v1.md "Comments").
abstract final class CommentText {
  static const maxLength = 2000;

  /// The composer shows its counter in the last 200 characters.
  static const counterWithin = 200;

  /// `@username`: 3–30 of a–z 0–9 _, not right after a Latin letter, digit, `_`, `.` or `@` (an email), but fine after
  /// an Arabic letter ("و@writer1"). The same pattern as the API.
  static final _mention = RegExp(r'(?<![A-Za-z0-9_@.])@([A-Za-z0-9_]{3,30})(?![A-Za-z0-9_])');

  /// [text] with its @handles blanked out, for deciding the text's direction (SPEC §14): a leading Latin handle mustn't
  /// make "@reader1 شكرًا على المقال" a left-to-right comment.
  static String withoutMentions(String text) => text.replaceAll(_mention, ' ');

  /// [body] split into plain text and mentions. Only handles listed in [mentions] (case ignored) become mentions;
  /// every other `@word` stays plain text.
  static List<CommentSegment> segments(String body, List<CommentMention> mentions) {
    if (mentions.isEmpty) return [CommentSegment(body)];
    final byHandle = {for (final m in mentions) m.username.toLowerCase(): m};
    final segments = <CommentSegment>[];
    final plain = StringBuffer();
    var cursor = 0;
    for (final match in _mention.allMatches(body)) {
      final mention = byHandle[match.group(1)!.toLowerCase()];
      if (mention == null) continue;
      plain.write(body.substring(cursor, match.start));
      if (plain.isNotEmpty) {
        segments.add(CommentSegment(plain.toString()));
        plain.clear();
      }
      segments.add(CommentSegment(match.group(0)!, mention: mention));
      cursor = match.end;
    }
    plain.write(body.substring(cursor));
    if (plain.isNotEmpty) segments.add(CommentSegment(plain.toString()));
    return segments;
  }

  static final _queryChars = RegExp(r'^[\p{L}\p{N}_]{0,30}$', unicode: true);
  static final _beforeAt = RegExp(r'[A-Za-z0-9_@.]');

  /// The `@word` that ends at [caret] in [text], or null when the caret isn't in one. The word may be empty (just
  /// typed `@`), and may be a display name in any script ("@منى"): suggestions match names too.
  static MentionQuery? activeMention(String text, int caret) {
    if (caret < 1 || caret > text.length) return null;
    final at = text.lastIndexOf('@', caret - 1);
    if (at < 0) return null;
    final query = text.substring(at + 1, caret);
    if (!_queryChars.hasMatch(query)) return null;
    if (at > 0 && _beforeAt.hasMatch(text[at - 1])) return null;
    return MentionQuery(start: at, end: caret, query: query);
  }

  /// [text] with [query] replaced by `@username ` and where the caret goes after it.
  static (String, int) insertMention(String text, MentionQuery query, String username) {
    final inserted = '@$username ';
    final rest = text.substring(query.end);
    // Don't double the space when one already follows.
    final replacement = rest.startsWith(' ') ? inserted.trimRight() : inserted;
    final next = text.replaceRange(query.start, query.end, replacement);
    return (next, query.start + inserted.length);
  }
}

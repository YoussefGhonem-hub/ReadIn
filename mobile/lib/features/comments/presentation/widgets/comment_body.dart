import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/comment_text.dart';

/// [body] as spans for a comment of [direction]: only the handles the API resolved ([mentions]) get [mentionStyle];
/// every other `@word` stays plain. Mentions are LTR isolates and plain runs in the opposite script are isolated too
/// (SPEC §14.2), so "شكراً @mona_dev!" keeps its "!" with the Arabic text. Line breaks are kept.
List<InlineSpan> commentBodySpans(
  String body,
  List<CommentMention> mentions, {
  required TextDirection direction,
  required TextStyle mentionStyle,
}) =>
    [
      for (final segment in CommentText.segments(body, mentions))
        segment.isMention
            ? TextSpan(text: Bidi.ltrIsolate(segment.text), style: mentionStyle)
            : TextSpan(text: Bidi.isolateOppositeRuns(segment.text, direction)),
    ];

/// The direction a comment is laid out in (SPEC §14.2): its first strong character, ignoring @handles, so an Arabic
/// reply that starts with "@reader1" stays right to left. Text with no letters outside handles follows the handles.
TextDirection commentDirection(String body, {required TextDirection fallback}) =>
    Bidi.detect(CommentText.withoutMentions(body)) ?? Bidi.detect(body) ?? fallback;

/// A comment's text, laid out in its own direction ([commentDirection]). Mentions are styled; they aren't links until
/// public profiles exist (F14).
class CommentBody extends StatelessWidget {
  const CommentBody({super.key, required this.body, this.mentions = const [], this.style});

  final String body;
  final List<CommentMention> mentions;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final direction = commentDirection(body, fallback: Directionality.of(context));
    final base = style ?? context.textTheme.bodyMedium!.copyWith(color: context.colors.textPrimary);
    // Full width, so a one-line Arabic comment in the English UI (and the other way round) starts on its own side.
    return SizedBox(
      width: double.infinity,
      child: Text.rich(
        TextSpan(
          style: base,
          children: commentBodySpans(
            body,
            mentions,
            direction: direction,
            mentionStyle: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w600),
          ),
        ),
        textDirection: direction,
        textAlign: TextAlign.start,
      ),
    );
  }
}

/// The clock comments are timed against (golden tests freeze it).
abstract final class CommentClock {
  static DateTime Function() now = DateTime.now;
}

/// "now", "5 min ago", "3 hrs ago", "yesterday", "4 days ago", then the date.
String commentTimeLabel(AppLocalizations l10n, DateTime at, {required DateTime now, required String languageCode}) {
  final elapsed = now.difference(at);
  if (elapsed.inMinutes < 1) return l10n.commentsTimeNow;
  if (elapsed.inHours < 1) return l10n.commentsTimeMinutes(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.commentsTimeHours(elapsed.inHours);
  if (elapsed.inDays < 7) return l10n.commentsTimeDays(elapsed.inDays);
  return formatDate(at, languageCode);
}

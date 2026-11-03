import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:readin/core/bidi/bidi.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';
import 'package:readin/features/comments/domain/entities/comment_text.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';

void main() {
  const mona = CommentMention(userId: 'u-3', username: 'mona_dev');
  const omar = CommentMention(userId: 'u-2', username: 'omar_k');

  group('CommentText.segments: only the handles the API resolved are mentions', () {
    test('other @words stay plain text', () {
      expect(CommentText.segments('شكراً @mona_dev و @ghost!', const [mona]), const [
        CommentSegment('شكراً '),
        CommentSegment('@mona_dev', mention: mona),
        CommentSegment(' و @ghost!'),
      ]);
    });

    test('Arabic text right before @ still makes a mention ("و@writer1")', () {
      expect(CommentText.segments('و@mona_dev و@omar_k كتبوا', const [mona, omar]), const [
        CommentSegment('و'),
        CommentSegment('@mona_dev', mention: mona),
        CommentSegment(' و'),
        CommentSegment('@omar_k', mention: omar),
        CommentSegment(' كتبوا'),
      ]);
    });

    test('not after a Latin letter, digit, _ or . (emails), and not a longer word', () {
      for (final body in ['mail me: me@mona_dev', 'x1@mona_dev', 'a.@mona_dev', '@mona_devs', '@mona_dev_2']) {
        expect(CommentText.segments(body, const [mona]), [CommentSegment(body)], reason: body);
      }
    });

    test('case is ignored; the text keeps its own spelling and line breaks', () {
      expect(CommentText.segments('سطر أول\n@Mona_Dev\nسطر تالت', const [mona]), const [
        CommentSegment('سطر أول\n'),
        CommentSegment('@Mona_Dev', mention: mona),
        CommentSegment('\nسطر تالت'),
      ]);
    });

    test('no mentions: one plain segment', () {
      expect(CommentText.segments('@mona_dev hi', const []), const [CommentSegment('@mona_dev hi')]);
    });
  });

  group('commentBodySpans', () {
    const mentionStyle = TextStyle(fontWeight: FontWeight.w600);

    test('styles exactly the resolved mentions, each an LTR isolate; plain text keeps every word', () {
      final spans = commentBodySpans(
        'شكراً و@mona_dev على الشرح، و @ghost كمان',
        const [mona],
        direction: TextDirection.rtl,
        mentionStyle: mentionStyle,
      ).cast<TextSpan>();

      expect([for (final s in spans) if (s.style == mentionStyle) s.text], [Bidi.ltrIsolate('@mona_dev')]);
      final plain = [for (final s in spans) if (s.style == null) s.text!].join();
      expect(plain, startsWith('شكراً و'), reason: 'the Arabic letter before @ stays with the text');
      expect(plain, contains('@ghost'));
      expect(spans.map((s) => s.text).join().replaceAll(RegExp('[${Bidi.fsi}${Bidi.lri}${Bidi.pdi}]'), ''),
          'شكراً و@mona_dev على الشرح، و @ghost كمان');
    });
  });

  group('typing a mention', () {
    test('the @word at the caret, in any script; not inside an email or after a space', () {
      expect(CommentText.activeMention('hi @mo', 6), const MentionQuery(start: 3, end: 6, query: 'mo'));
      expect(CommentText.activeMention('hi @', 4)?.query, '');
      const arabic = 'شكراً و@من';
      expect(CommentText.activeMention(arabic, arabic.length)?.query, 'من');
      expect(CommentText.activeMention('mail a@b', 8), isNull);
      expect(CommentText.activeMention('hi @mo there', 12), isNull);
      expect(CommentText.activeMention('hi @mo there', 6)?.query, 'mo', reason: 'the caret decides');
      expect(CommentText.activeMention('', 0), isNull);
    });

    test('a suggestion replaces the word with @username and a space', () {
      const query = MentionQuery(start: 3, end: 6, query: 'mo');
      expect(CommentText.insertMention('hi @mo', query, 'mona_dev'), ('hi @mona_dev ', 13));
      expect(CommentText.insertMention('hi @mo there', query, 'mona_dev'), ('hi @mona_dev there', 13),
          reason: 'no second space');
    });
  });

  group('comment times', () {
    setUpAll(initializeDateFormatting);

    final now = DateTime.utc(2026, 11, 2, 12);

    test('now, minutes, hours, days, then the date', () {
      final en = lookupAppLocalizations(AppLocales.en);
      String at(Duration ago) => commentTimeLabel(en, now.subtract(ago), now: now, languageCode: 'en');

      expect(at(const Duration(seconds: 20)), 'now');
      expect(at(const Duration(minutes: 5)), '5 min ago');
      expect(at(const Duration(hours: 3)), '3 hrs ago');
      expect(at(const Duration(days: 1, hours: 2)), 'yesterday');
      expect(at(const Duration(days: 4)), '4 days ago');
      expect(at(const Duration(days: 30)), 'Oct 3, 2026');
    });

    test('Arabic, with Western digits', () {
      final ar = lookupAppLocalizations(AppLocales.ar);
      expect(commentTimeLabel(ar, now.subtract(const Duration(minutes: 2)), now: now, languageCode: 'ar'), 'من دقيقتين');
      expect(commentTimeLabel(ar, now.subtract(const Duration(hours: 5)), now: now, languageCode: 'ar'), 'من 5 ساعات');
    });
  });

  group('commentDirection (SPEC §14)', () {
    test('a leading @handle does not make an Arabic reply left to right', () {
      expect(commentDirection('@reader1 لو عايز تتعمق أكتر', fallback: TextDirection.ltr), TextDirection.rtl);
      expect(commentDirection('@reader2 it is in the repo', fallback: TextDirection.rtl), TextDirection.ltr);
    });

    test('otherwise the first strong letter, then the handles, then the fallback', () {
      expect(commentDirection('مقال مفيد about RAG', fallback: TextDirection.ltr), TextDirection.rtl);
      expect(commentDirection('@reader1 👍', fallback: TextDirection.rtl), TextDirection.ltr);
      expect(commentDirection('👍', fallback: TextDirection.rtl), TextDirection.rtl);
    });
  });
}

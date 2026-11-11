import 'package:equatable/equatable.dart';

/// One of the account's own du'as (F38, `PersonalDuaDto`).
class PersonalDua extends Equatable {
  const PersonalDua({
    required this.id,
    this.title,
    required this.text,
    this.repeat = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Optional, one line, ≤ 100.
  final String? title;

  /// As written, line breaks kept, 1–2,000.
  final String text;

  /// How many times it is said (1–1,000): the page counts it down.
  final int repeat;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, title, text, repeat, createdAt, updatedAt];
}

/// What a du'a is saved with: `POST /me/duas` and `PATCH /me/duas/{id}`.
class DuaDraft extends Equatable {
  const DuaDraft({this.title, required this.text, this.repeat = 1});

  final String? title;
  final String text;
  final int repeat;

  /// The API's range for [repeat].
  static const maxRepeat = 1000;

  @override
  List<Object?> get props => [title, text, repeat];
}

/// A surah of the private corner (F38): Tanzil's Uthmani text, verbatim (an app asset).
class Surah extends Equatable {
  const Surah({
    required this.number,
    required this.name,
    required this.ayat,
    required this.source,
    required this.sourceUrl,
  });

  /// 36 (Ya-Sin) or 56 (Al-Waqi'ah).
  final int number;

  /// The Arabic name: «يس», «الواقعة».
  final String name;

  /// The ayat in order. Tanzil puts the basmala before ayah 1; [opening] and [ayahText] split it off.
  final List<String> ayat;
  final String source;
  final String sourceUrl;

  /// The basmala exactly as Tanzil writes it before ayah 1 of every surah but Al-Fatiha and At-Tawbah, escaped so no
  /// editor reorders its marks (Tanzil puts the shadda before the fatha).
  static const basmala =
      '\u0628\u0650\u0633\u0652\u0645\u0650\u0020\u0671\u0644\u0644\u0651\u064E\u0647\u0650\u0020\u0671\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0640\u0670\u0646\u0650\u0020\u0671\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650';

  /// The surah's opening line (the basmala), or null when ayah 1 doesn't start with it.
  String? get opening => ayat.isNotEmpty && ayat.first.startsWith('$basmala ') ? basmala : null;

  /// Ayah [number] (1-based) as it is read under the opening line: ayah 1 without the basmala.
  String ayahText(int number) {
    final text = ayat[number - 1];
    return number == 1 && opening != null ? text.substring(basmala.length + 1) : text;
  }

  @override
  List<Object?> get props => [number, name, ayat, source, sourceUrl];
}

/// When a dhikr is said.
enum DhikrTime { morning, evening, both }

/// The morning or evening session (the page shows one).
enum AdhkarSession {
  morning,
  evening;

  bool includes(DhikrTime time) =>
      time == DhikrTime.both || (this == morning ? time == DhikrTime.morning : time == DhikrTime.evening);
}

/// One dhikr of Hisn al-Muslim's "أذكار الصباح والمساء", verbatim with its notes (an app asset).
class Dhikr extends Equatable {
  const Dhikr({required this.id, required this.text, required this.repeat, required this.time});

  /// Hisn al-Muslim's id (75–98).
  final int id;
  final String text;

  /// How many times the text says to say it (≥ 1).
  final int repeat;
  final DhikrTime time;

  @override
  List<Object?> get props => [id, text, repeat, time];
}

/// The adhkar chapter with its source.
class AdhkarBook extends Equatable {
  const AdhkarBook({required this.title, required this.items, required this.source, required this.sourceUrl});

  final String title;
  final List<Dhikr> items;
  final String source;
  final String sourceUrl;

  List<Dhikr> forSession(AdhkarSession session) => [
    for (final dhikr in items)
      if (session.includes(dhikr.time)) dhikr,
  ];

  @override
  List<Object?> get props => [title, items, source, sourceUrl];
}

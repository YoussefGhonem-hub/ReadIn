import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/devotions.dart';

/// The private corner's texts (F38), bundled in `assets/devotions/` and never typed by hand: the surahs are Tanzil's
/// Uthmani text, the adhkar Hisn al-Muslim's chapter, both copied verbatim with their sources.
@lazySingleton
class DevotionsAssets {
  DevotionsAssets() : this.withBundle(rootBundle);

  /// Test seam.
  DevotionsAssets.withBundle(this._bundle);

  final AssetBundle _bundle;

  static String surahPath(int number) => 'assets/devotions/quran-${number.toString().padLeft(3, '0')}.json';
  static const adhkarPath = 'assets/devotions/adhkar-morning-evening.json';

  Future<Surah> surah(int number) async {
    final json = jsonDecode(await _bundle.loadString(surahPath(number))) as Map<String, dynamic>;
    return Surah(
      number: json['surah'] as int,
      name: json['name'] as String,
      ayat: [for (final ayah in json['ayat'] as List<dynamic>) ayah as String],
      source: json['source'] as String,
      sourceUrl: json['sourceUrl'] as String,
    );
  }

  Future<AdhkarBook> adhkar() async {
    final json = jsonDecode(await _bundle.loadString(adhkarPath)) as Map<String, dynamic>;
    return AdhkarBook(
      title: json['title'] as String,
      source: json['source'] as String,
      sourceUrl: json['sourceUrl'] as String,
      items: [
        for (final item in (json['items'] as List<dynamic>).cast<Map<String, dynamic>>())
          Dhikr(
            id: item['id'] as int,
            text: (item['text'] as String).trim(),
            repeat: item['repeat'] as int,
            time: DhikrTime.values.byName(item['time'] as String),
          ),
      ],
    );
  }
}

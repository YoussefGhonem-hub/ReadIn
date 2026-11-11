import '../domain/entities/devotions.dart';

/// The private corner (F38), holders of `devotions.access` only (the router sends everyone else Home):
/// `/devotions`, a surah (`/devotions/surah/36`, `/devotions/surah/56`), the adhkar (`/devotions/adhkar/morning`,
/// `/devotions/adhkar/evening`) and «أدعيتي» (`/devotions/duas`).
abstract final class DevotionsRoutes {
  static const home = '/devotions';
  static const duas = '/devotions/duas';
  static const surahPrefix = '/devotions/surah';
  static const adhkarPrefix = '/devotions/adhkar';

  /// The surahs of the corner, in its order: Ya-Sin, Al-Waqi'ah.
  static const surahs = [36, 56];

  static String surah(int number) => '$surahPrefix/$number';

  static String adhkar(AdhkarSession session) => '$adhkarPrefix/${session.name}';

  /// `:number` of a surah route, when it is one of [surahs].
  static int? surahOf(String? value) => switch (int.tryParse(value ?? '')) {
    final n? when surahs.contains(n) => n,
    _ => null,
  };

  /// `:session` of an adhkar route.
  static AdhkarSession? sessionOf(String? value) => AdhkarSession.values.asNameMap()[value];

  static bool isDevotions(String path) => path == home || path.startsWith('$home/');
}

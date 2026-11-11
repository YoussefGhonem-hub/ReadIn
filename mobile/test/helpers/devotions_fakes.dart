import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/devotions/data/datasources/devotions_assets.dart';
import 'package:readin/features/devotions/domain/entities/devotions.dart';
import 'package:readin/features/devotions/domain/repositories/devotions_repository.dart';

/// [DevotionsRepository] with the real bundled texts and the du'as in memory (F38). [failNext] makes the next du'a
/// call fail with that code.
class FakeDevotionsRepository implements DevotionsRepository {
  FakeDevotionsRepository({List<PersonalDua>? duas}) : items = [...?duas];

  final List<PersonalDua> items;
  String? failNext;
  var _ids = 0;

  static final _surahs = <int, Surah>{};
  static AdhkarBook? _adhkar;

  /// Reads the bundled texts once, outside a widget test's fake clock (real I/O never finishes inside it): call it
  /// in `setUpAll`. The repository then answers at once.
  static Future<void> preload() async {
    final assets = DevotionsAssets();
    for (final number in [36, 56]) {
      _surahs[number] ??= await assets.surah(number);
    }
    _adhkar ??= await assets.adhkar();
  }

  static final _at = DateTime.utc(2026, 11, 11, 9);

  static PersonalDua dua(String id, String text, {String? title, int repeat = 1}) =>
      PersonalDua(id: id, title: title, text: text, repeat: repeat, createdAt: _at, updatedAt: _at);

  Result<T>? _failure<T>() {
    final code = failNext;
    if (code == null) return null;
    failNext = null;
    return Err(Failure(code, statusCode: code == FailureCodes.duaNotFound ? 404 : 409));
  }

  @override
  Future<Result<Surah>> surah(int number) async => Ok(_surahs[number] ?? (throw StateError('call preload() first')));

  @override
  Future<Result<AdhkarBook>> adhkar() async => Ok(_adhkar ?? (throw StateError('call preload() first')));

  @override
  Future<Result<List<PersonalDua>>> duas() async => _failure() ?? Ok([...items]);

  @override
  Future<Result<PersonalDua>> createDua(DuaDraft draft) async {
    if (_failure<PersonalDua>() case final failure?) return failure;
    final created = dua('d-new-${++_ids}', draft.text, title: draft.title, repeat: draft.repeat);
    items.add(created);
    return Ok(created);
  }

  @override
  Future<Result<PersonalDua>> updateDua(String id, DuaDraft draft) async {
    if (_failure<PersonalDua>() case final failure?) return failure;
    final updated = dua(id, draft.text, title: draft.title, repeat: draft.repeat);
    items[items.indexWhere((d) => d.id == id)] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<void>> deleteDua(String id) async {
    if (_failure<void>() case final failure?) return failure;
    items.removeWhere((d) => d.id == id);
    return const Ok(null);
  }
}

import '../../../../core/errors/result.dart';
import '../entities/devotions.dart';

/// The private corner (F38): the bundled surahs and adhkar, and the account's own du'as on the server
/// (`devotions.access`; another account's du'a is `404 dua.not_found`).
abstract interface class DevotionsRepository {
  /// Ya-Sin (36) or Al-Waqi'ah (56), from the app's assets.
  Future<Result<Surah>> surah(int number);

  /// Hisn al-Muslim's morning and evening adhkar, from the app's assets.
  Future<Result<AdhkarBook>> adhkar();

  /// `GET /me/duas`: oldest first.
  Future<Result<List<PersonalDua>>> duas();

  /// `POST /me/duas` (added last; `409 dua.limit` at 200).
  Future<Result<PersonalDua>> createDua(DuaDraft draft);

  /// `PATCH /me/duas/{id}`: replaces the title and the text.
  Future<Result<PersonalDua>> updateDua(String id, DuaDraft draft);

  /// `DELETE /me/duas/{id}`.
  Future<Result<void>> deleteDua(String id);
}

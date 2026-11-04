import '../rdoc_document.dart';
import 'block_editing.dart';

/// RDoc JSON ⇄ the editor's document: typed RDoc whose block ids are valid and unique and whose `language` is the
/// translation's language. Independent of the editing surface: an AppFlowy (or any other) surface converts this
/// typed document to its own nodes and back, and keeps the block ids, directions, mentions and terms it was given.
abstract final class RDocCodec {
  /// Parses stored content for editing. Empty or missing content gives an empty document.
  static RDocDocument decode(Map<String, dynamic>? json, {required String language}) {
    final document = json == null || json.isEmpty
        ? RDocDocument(version: 1, language: language, blocks: const [])
        : RDocDocument.fromJson(json);
    return BlockIds.ensureUnique(document.language == language ? document : document.copyWith(language: language));
  }

  /// The schema form of [document] in [language], lossless (what the local backup keeps).
  static Map<String, dynamic> encode(RDocDocument document, {required String language}) =>
      (document.language == language ? document : document.copyWith(language: language)).toJson();

  /// What autosave sends: [encode] after [RDocSanitizer.forSave] (blocks still being filled in are left out).
  static Map<String, dynamic> encodeForSave(RDocDocument document, {required String language}) =>
      encode(RDocSanitizer.forSave(document), language: language);
}

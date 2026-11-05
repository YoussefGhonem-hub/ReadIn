import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../media/domain/entities/media.dart';
import '../../../tags/domain/services/tag_names.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../entities/editor_entities.dart';

/// The publish checks (`DraftChecksDto.problems`), computed on the device between autosaves so the list follows
/// every keystroke. Same rules and codes as the API; the API's answer replaces these after each save, and only the
/// API can tell `article.content_invalid`.
abstract final class DraftChecker {
  /// [field] is the selected field (for `requiresSources`); [assets] are the attachments' uploads by id, to tell
  /// the ones still uploading or processing.
  static List<DraftProblem> problems(
    ArticleDraftDocument document, {
    Field? field,
    Map<String, MediaAsset> assets = const {},
  }) {
    final problems = <DraftProblem>[];
    if (document.fieldId == null) problems.add(const DraftProblem(DraftProblemCodes.fieldRequired));
    for (final t in document.translations) {
      final title = t.title.trim().length;
      if (title < DraftLimits.minTitle || title > DraftLimits.maxTitle) {
        problems.add(DraftProblem(DraftProblemCodes.titleLength, language: t.language));
      }
      if (!t.content.blocks.any(BlockEditing.hasText)) {
        problems.add(DraftProblem(DraftProblemCodes.contentEmpty, language: t.language));
      }
      for (final block in t.content.blocks) {
        if (block is RImage && block.src.trim().isNotEmpty && block.alt.trim().isEmpty) {
          problems.add(DraftProblem(DraftProblemCodes.imageAltRequired, language: t.language, blockId: block.id));
        }
      }
    }
    if ((field?.requiresSources ?? false) && document.sources.isEmpty) {
      problems.add(const DraftProblem(DraftProblemCodes.sourcesRequired));
    }
    for (final a in document.attachments) {
      final asset = assets[a.mediaAssetId];
      final isDocument = asset?.kind == MediaKind.document || a.title != null;
      if (!isDocument && (a.altText?.trim().isEmpty ?? true)) {
        problems.add(DraftProblem(DraftProblemCodes.attachmentAltRequired, mediaAssetId: a.mediaAssetId));
      }
      if (isDocument && (a.title?.trim().isEmpty ?? true)) {
        problems.add(DraftProblem(DraftProblemCodes.attachmentTitleRequired, mediaAssetId: a.mediaAssetId));
      }
      if (asset != null && asset.status != MediaStatus.ready) {
        problems.add(DraftProblem(DraftProblemCodes.attachmentNotReady, mediaAssetId: a.mediaAssetId));
      }
    }
    return problems;
  }
}

extension ArticleDraftDocumentSave on ArticleDraftDocument {
  /// The document autosave sends: each translation's content with the blocks still being filled in left out
  /// ([RDocSanitizer]), and the tags cleaned like the API cleans them (F32).
  ArticleDraftDocument forSave() => copyWith(
        translations: [for (final t in translations) t.copyWith(content: RDocSanitizer.forSave(t.content))],
        tags: [
          for (final tag in tags)
            if (TagNames.clean(tag) case final name when name.isNotEmpty) name,
        ],
      );
}

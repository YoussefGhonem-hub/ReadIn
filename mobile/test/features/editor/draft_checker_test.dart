import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/editor/domain/entities/editor_entities.dart';
import 'package:readin/features/editor/domain/services/draft_checker.dart';
import 'package:readin/features/editor/presentation/cubit/article_editor_cubit.dart';
import 'package:readin/features/editor/presentation/widgets/editor_widgets.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../../helpers/editor_fixtures.dart';
import '../../helpers/media_fixtures.dart';

List<String> codes(List<DraftProblem> problems) => [for (final p in problems) p.code];

void main() {
  final dotnet = editorFields.first;

  group('the publish checks on the device', () {
    test('a complete article has none', () {
      expect(DraftChecker.problems(mixedDocument(withTranslation: true), field: dotnet), isEmpty);
    });

    test('an empty new article needs a field, a title and content', () {
      final problems = DraftChecker.problems(ArticleDraftDocument.empty('ar-EG'));
      expect(problems, const [
        DraftProblem(DraftProblemCodes.fieldRequired),
        DraftProblem(DraftProblemCodes.titleLength, language: 'ar-EG'),
        DraftProblem(DraftProblemCodes.contentEmpty, language: 'ar-EG'),
      ]);
    });

    test('the title needs 5 to 150 characters, trimmed, in every version', () {
      final doc = mixedDocument(withTranslation: true);
      final short = doc.withTranslation(doc.translation('en')!.copyWith(title: '  Hi  '));
      expect(DraftChecker.problems(short, field: dotnet), const [DraftProblem(DraftProblemCodes.titleLength, language: 'en')]);
      final long = doc.withTranslation(doc.source.copyWith(title: 'x' * 151));
      expect(codes(DraftChecker.problems(long, field: dotnet)), [DraftProblemCodes.titleLength]);
    });

    test('a block with only an image, divider or embed is not content', () {
      final doc = mixedDocument().withTranslation(mixedDocument().source.copyWith(
            content: const RDocDocument(version: 1, language: 'ar-EG', blocks: [
              RImage('i', src: 'https://cdn/x.webp', alt: 'diagram'),
              RDivider('d'),
              RParagraph('p', dir: 'auto', content: [RText('   ')]),
            ]),
          ));
      expect(codes(DraftChecker.problems(doc, field: dotnet)), [DraftProblemCodes.contentEmpty]);
    });

    test('an uploaded image without alt text points at its block', () {
      final doc = mixedDocument().withTranslation(mixedDocument().source.copyWith(
            content: const RDocDocument(version: 1, language: 'ar-EG', blocks: [
              RParagraph('p', dir: 'auto', content: [RText('نص')]),
              RImage('img-1', src: 'https://cdn/x.webp', alt: ' '),
              RImage('img-2', src: '', alt: ''), // not uploaded yet: not sent, not flagged
            ]),
          ));
      expect(DraftChecker.problems(doc, field: dotnet), const [
        DraftProblem(DraftProblemCodes.imageAltRequired, language: 'ar-EG', blockId: 'img-1'),
      ]);
    });

    test('fields that require sources need one', () {
      final doc = mixedDocument().copyWith(sources: const <ArticleSource>[]);
      expect(codes(DraftChecker.problems(doc, field: dotnet)), [DraftProblemCodes.sourcesRequired]);
      expect(DraftChecker.problems(doc, field: editorFields.last), isEmpty);
    });

    test('attachments need alt text, a PDF title, and finished processing', () {
      final doc = mixedDocument().copyWith(attachments: const [
        AttachmentItem(mediaAssetId: 'a1', order: 0, altText: ''),
        AttachmentItem(mediaAssetId: 'a2', order: 1, altText: 'Swagger'),
      ]);
      const processing = MediaAsset(id: 'a2', kind: MediaKind.image, status: MediaStatus.processing);
      expect(DraftChecker.problems(doc, field: dotnet, assets: {'a1': imageAsset('a1'), 'a2': processing}), const [
        DraftProblem(DraftProblemCodes.attachmentAltRequired, mediaAssetId: 'a1'),
        DraftProblem(DraftProblemCodes.attachmentNotReady, mediaAssetId: 'a2'),
      ]);
      final pdf = mixedDocument().copyWith(attachments: const [AttachmentItem(mediaAssetId: 'doc', order: 0, title: ' ')]);
      expect(codes(DraftChecker.problems(pdf, field: dotnet)), [DraftProblemCodes.attachmentTitleRequired]);
    });
  });

  group('which checks show', () {
    ArticleEditorState state({required bool dirty, required bool fresh, DraftChecks checks = const DraftChecks()}) => ArticleEditorState(
          document: ArticleDraftDocument.empty('ar-EG'),
          activeLanguage: 'ar-EG',
          loadStatus: EditorLoadStatus.ready,
          dirty: dirty,
          checksFresh: fresh,
          checks: checks,
        );

    test("the API's while they describe the document", () {
      const server = DraftChecks(problems: [DraftProblem(DraftProblemCodes.contentInvalid, language: 'ar-EG')]);
      expect(state(dirty: false, fresh: true, checks: server).problems, server.problems);
    });

    test("the device's after an edit, keeping the API's content_invalid", () {
      const server = DraftChecks(problems: [DraftProblem(DraftProblemCodes.contentInvalid, language: 'ar-EG'), DraftProblem(DraftProblemCodes.sourcesRequired)]);
      expect(codes(state(dirty: true, fresh: true, checks: server).problems), [
        DraftProblemCodes.fieldRequired,
        DraftProblemCodes.titleLength,
        DraftProblemCodes.contentEmpty,
        DraftProblemCodes.contentInvalid,
      ]);
    });
  });

  test('every problem code has its own message and jump target', () {
    expect(problemTarget(const DraftProblem(DraftProblemCodes.titleLength, language: 'en')), ProblemTarget.title);
    expect(problemTarget(const DraftProblem(DraftProblemCodes.imageAltRequired, language: 'en', blockId: 'b')), ProblemTarget.block);
    expect(problemTarget(const DraftProblem(DraftProblemCodes.contentEmpty, language: 'en')), ProblemTarget.content);
    for (final code in [DraftProblemCodes.fieldRequired, DraftProblemCodes.sourcesRequired, DraftProblemCodes.attachmentNotReady]) {
      expect(problemTarget(DraftProblem(code)), ProblemTarget.settings);
    }
  });
}

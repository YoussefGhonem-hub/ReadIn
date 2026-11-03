import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/editor/domain/entities/article_draft.dart';
import 'package:readin/features/editor/domain/repositories/editor_repository.dart';
import 'package:readin/features/editor/domain/usecases/publish_usecases.dart';
import 'package:readin/features/editor/presentation/cubit/composer_cubit.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/taxonomy/domain/entities/field.dart';
import 'package:readin/features/taxonomy/domain/repositories/taxonomy_repository.dart';
import 'package:readin/features/taxonomy/domain/usecases/taxonomy_usecases.dart';

class MockEditorRepository extends Mock implements EditorRepository {}

class MockTaxonomyRepository extends Mock implements TaxonomyRepository {}

const software = Field(id: 'f-sw', slug: 'software', nameAr: 'برمجة', nameEn: 'Software', requiresSources: true);
const design = Field(id: 'f-design', slug: 'design', nameAr: 'تصميم', nameEn: 'Design');
const created = CreatedArticle(id: 'art-1', slug: 'di-in-dotnet');
const images = [AttachmentItem(mediaAssetId: 'a1', order: 0, altText: 'Program.cs')];

void main() {
  late MockEditorRepository editor;
  late MockTaxonomyRepository taxonomy;

  setUpAll(() {
    registerFallbackValue(const ArticleDraft(fieldId: '', language: 'en', title: '', content: {}));
  });

  setUp(() {
    editor = MockEditorRepository();
    taxonomy = MockTaxonomyRepository();
    when(() => taxonomy.getFields(refresh: any(named: 'refresh'))).thenAnswer((_) async => const Ok([software, design]));
    when(() => editor.createArticle(any())).thenAnswer((_) async => const Ok(created));
    when(() => editor.setAttachments(any(), any())).thenAnswer((_) async => const Ok(null));
    when(() => editor.publish(any())).thenAnswer((_) async => const Ok(null));
  });

  ComposerCubit build() => ComposerCubit(
        GetFields(taxonomy),
        CreateArticleDraft(editor),
        SetArticleAttachments(editor),
        PublishArticle(editor),
      );

  ComposerState ready({String fieldId = 'f-design', List<SourceDraft> sources = const []}) => ComposerState(
        fieldsLoading: false,
        fields: const [software, design],
        fieldId: fieldId,
        language: 'ar-EG',
        title: 'إزاي تختار بين Transient و Scoped',
        body: 'فقرة أولى عن الـ DI.\n\nفقرة تانية\nبسطر جديد.',
        sources: sources,
      );

  blocTest<ComposerCubit, ComposerState>(
    'starts with the preferred article language and loads the fields',
    build: build,
    act: (cubit) => cubit.start(language: 'en'),
    expect: () => [
      const ComposerState(language: 'en'),
      const ComposerState(language: 'en', fieldsLoading: false, fields: [software, design]),
    ],
  );

  test('validation: field, title length, body or attachment, sources', () {
    const empty = ComposerState(fieldsLoading: false, fields: [software, design]);
    expect(empty.blockers(hasAttachments: false), [ComposerBlocker.field, ComposerBlocker.title, ComposerBlocker.body]);
    expect(empty.copyWith(title: 'abcd').blockers(hasAttachments: true), contains(ComposerBlocker.title));
    expect(ready().blockers(hasAttachments: false), isEmpty);
    expect(ready().copyWith(body: '  \n\n ').blockers(hasAttachments: true), isEmpty, reason: 'an image post needs no text');
    expect(ready(fieldId: 'f-sw').blockers(hasAttachments: false), [ComposerBlocker.sources]);
    expect(
      ready(fieldId: 'f-sw', sources: const [SourceDraft(key: 1, title: 'Docs', url: 'learn.microsoft.com')]).blockers(hasAttachments: false),
      [ComposerBlocker.sources, ComposerBlocker.incompleteSource],
    );
    expect(
      ready(fieldId: 'f-sw', sources: const [SourceDraft(key: 1, title: 'Docs', url: 'https://learn.microsoft.com')]).blockers(hasAttachments: false),
      isEmpty,
    );
  });

  blocTest<ComposerCubit, ComposerState>(
    'publish: create → set attachments → publish, then hands back the slug',
    build: build,
    seed: ready,
    act: (cubit) => cubit.publish(attachments: images),
    expect: () => [
      ready().copyWith(publishStatus: PublishStatus.publishing),
      ready().copyWith(publishStatus: PublishStatus.success, publishedSlug: () => 'di-in-dotnet'),
    ],
    verify: (_) {
      final draft = verify(() => editor.createArticle(captureAny())).captured.single as ArticleDraft;
      expect(draft.fieldId, 'f-design');
      expect(draft.title, 'إزاي تختار بين Transient و Scoped');
      expect(draft.content['blocks'], hasLength(2));
      verifyInOrder([
        () => editor.setAttachments('art-1', images),
        () => editor.publish('art-1'),
      ]);
    },
  );

  blocTest<ComposerCubit, ComposerState>(
    'a post without attachments skips PUT /attachments',
    build: build,
    seed: ready,
    act: (cubit) => cubit.publish(attachments: const []),
    verify: (_) {
      verifyNever(() => editor.setAttachments(any(), any()));
      verify(() => editor.publish('art-1')).called(1);
    },
  );

  blocTest<ComposerCubit, ComposerState>(
    'a failed publish surfaces the code; retrying reuses the created draft',
    setUp: () {
      var calls = 0;
      when(() => editor.publish(any())).thenAnswer((_) async =>
          ++calls == 1 ? const Err(Failure(FailureCodes.articleSourcesRequired, statusCode: 400)) : const Ok(null));
    },
    build: build,
    seed: ready,
    act: (cubit) async {
      await cubit.publish(attachments: images);
      expect(cubit.state.publishFailure, const Failure(FailureCodes.articleSourcesRequired, statusCode: 400));
      await cubit.publish(attachments: images);
    },
    verify: (cubit) {
      expect(cubit.state.publishStatus, PublishStatus.success);
      verify(() => editor.createArticle(any())).called(1);
      verify(() => editor.setAttachments('art-1', images)).called(2);
    },
  );

  blocTest<ComposerCubit, ComposerState>(
    'editing after a failed step creates a fresh draft so the change is not lost',
    setUp: () {
      var calls = 0;
      when(() => editor.publish(any())).thenAnswer((_) async => ++calls == 1 ? const Err(Failure(FailureCodes.serverError)) : const Ok(null));
    },
    build: build,
    seed: ready,
    act: (cubit) async {
      await cubit.publish(attachments: const []);
      cubit.setTitle('عنوان جديد بعد التعديل');
      expect(cubit.state.publishStatus, PublishStatus.idle);
      await cubit.publish(attachments: const []);
    },
    verify: (_) => verify(() => editor.createArticle(any())).called(2),
  );

  blocTest<ComposerCubit, ComposerState>(
    'publishing is refused while the form is invalid',
    build: build,
    seed: () => ready(fieldId: 'f-sw'),
    act: (cubit) => cubit.publish(attachments: const []),
    expect: () => const <ComposerState>[],
    verify: (_) => verifyNever(() => editor.createArticle(any())),
  );

  blocTest<ComposerCubit, ComposerState>(
    'sources rows: add, edit, remove',
    build: build,
    seed: () => ready(fieldId: 'f-sw'),
    act: (cubit) {
      cubit
        ..addSource()
        ..addSource()
        ..updateSource(1, title: 'ASP.NET Core docs', url: 'https://learn.microsoft.com/aspnet/core')
        ..removeSource(2);
    },
    verify: (cubit) {
      expect(cubit.state.sources, const [
        SourceDraft(key: 1, title: 'ASP.NET Core docs', url: 'https://learn.microsoft.com/aspnet/core'),
      ]);
      expect(cubit.state.toDraft().sources, const [
        ArticleSource(title: 'ASP.NET Core docs', url: 'https://learn.microsoft.com/aspnet/core'),
      ]);
    },
  );
}

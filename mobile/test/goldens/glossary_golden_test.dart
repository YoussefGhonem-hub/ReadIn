@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/theme/theme_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/domain/repositories/article_repository.dart';
import 'package:readin/features/article/domain/usecases/get_related_articles.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/cubit/related_articles_cubit.dart';
import 'package:readin/features/article/presentation/widgets/related_articles_section.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/glossary/presentation/cubit/glossary_search_cubit.dart';
import 'package:readin/features/glossary/presentation/cubit/glossary_term_cubit.dart';
import 'package:readin/features/glossary/presentation/widgets/glossary_sheet.dart';
import 'package:readin/features/glossary/presentation/widgets/glossary_term_picker.dart';

import '../helpers/fixtures.dart';
import '../helpers/glossary_fixtures.dart';
import '../helpers/post_card_fixtures.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class MockGlossaryTermCubit extends MockCubit<GlossaryTermState> implements GlossaryTermCubit {}

class MockArticleRepository extends Mock implements ArticleRepository {}

class MockGlossarySearchCubit extends MockCubit<GlossarySearchState> implements GlossarySearchCubit {}

/// The glossary sheet and the editor's term picker (F21), and the related articles at the end of the reader (F04), in
/// ar/en × light/dark.
void main() {
  for (final variant in Variant.all) {
    testWidgets('glossary sheet ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 900));
      final cubit = MockGlossaryTermCubit();
      whenListen(
        cubit,
        const Stream<GlossaryTermState>.empty(),
        initialState: const GlossaryTermState(status: GlossaryTermStatus.ready, term: diTerm),
      );
      await tester.pumpWidget(testApp(
        Scaffold(
          // On the sheet's surface.
          body: Builder(
            builder: (context) => ColoredBox(
              color: context.colors.surfaceRaised,
              child: BlocProvider<GlossaryTermCubit>.value(
                value: cubit,
                child: const GlossaryTermView(text: 'DI', language: 'ar-EG', articleId: 'art-1'),
              ),
            ),
          ),
        ),
        variant: variant,
      ));
      await tester.pump();
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/glossary_sheet_${variant.name}.png'));
    });

    testWidgets('editor term picker ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 520));
      final cubit = MockGlossarySearchCubit();
      whenListen(
        cubit,
        const Stream<GlossarySearchState>.empty(),
        initialState: const GlossarySearchState(query: 'ioc-container', status: GlossarySearchStatus.ready, results: [iocSummary, diSummary]),
      );
      await tester.pumpWidget(testApp(
        Scaffold(
          body: Builder(
            // A Material like the bottom sheet's: the rows' ink paints on it.
            builder: (context) => Material(
              color: context.colors.surfaceRaised,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: BlocProvider<GlossarySearchCubit>.value(
                  value: cubit,
                  // A term opened again: the words are Arabic, the current term is ticked and can be removed.
                  child: const GlossaryTermPickerView(text: 'حاوية الـ IoC', termId: 'ioc-container'),
                ),
              ),
            ),
          ),
        ),
        variant: variant,
      ));
      await tester.pump();
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/editor_term_picker_${variant.name}.png'));
    });

    // Post cards since F34 (they were compact rows).
    testWidgets('related articles ${variant.name}', (tester) async {
      CommentClock.now = () => DateTime.utc(2026, 11, 2, 12);
      addTearDown(() => CommentClock.now = DateTime.now);
      usePhoneSurface(tester, size: const Size(390, 900));
      final repository = MockArticleRepository();
      when(() => repository.getRelated('art-1', language: 'ar-EG', limit: 4))
          .thenAnswer((_) async => Ok([for (var i = 2; i < 5; i++) postCard(i, cover: false, isSaved: i == 3, reactionCount: 3, reactions: const ReactionCounts(insightful: 3))]));
      final session = MockSessionCubit();
      final engagement = MockEngagementCubit();
      whenListen(session, const Stream<SessionState>.empty(), initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      whenListen(engagement, const Stream<EngagementState>.empty(), initialState: const EngagementState());
      final follows = MockFollowsCubit();
      whenListen(follows, const Stream<FollowsState>.empty(), initialState: const FollowsState());
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<EngagementCubit>.value(value: engagement),
            BlocProvider<FollowsCubit>.value(value: follows),
          ],
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                RelatedArticlesSection(
                  article: engagedCard(1),
                  cubit: () => RelatedArticlesCubit(GetRelatedArticles(repository)),
                ),
              ],
            ),
          ),
        ),
        variant: variant,
      ));
      await tester.pump();
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/related_articles_${variant.name}.png'));
    });
  }
}

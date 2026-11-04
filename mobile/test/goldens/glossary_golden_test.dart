@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/theme/theme_x.dart';
import 'package:readin/features/article/domain/repositories/article_repository.dart';
import 'package:readin/features/article/domain/usecases/get_related_articles.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/cubit/related_articles_cubit.dart';
import 'package:readin/features/article/presentation/widgets/related_articles_section.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/glossary/presentation/cubit/glossary_term_cubit.dart';
import 'package:readin/features/glossary/presentation/widgets/glossary_sheet.dart';

import '../helpers/fixtures.dart';
import '../helpers/glossary_fixtures.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class MockGlossaryTermCubit extends MockCubit<GlossaryTermState> implements GlossaryTermCubit {}

class MockArticleRepository extends Mock implements ArticleRepository {}

/// The glossary sheet (F21) and the related articles at the end of the reader (F04) in ar/en × light/dark.
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

    testWidgets('related articles ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 520));
      final repository = MockArticleRepository();
      when(() => repository.getRelated('art-1', language: 'ar-EG', limit: 4))
          .thenAnswer((_) async => Ok([for (var i = 2; i < 5; i++) engagedCard(i, isSaved: i == 3)]));
      final session = MockSessionCubit();
      final engagement = MockEngagementCubit();
      whenListen(session, const Stream<SessionState>.empty(), initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      whenListen(engagement, const Stream<EngagementState>.empty(), initialState: const EngagementState());
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<EngagementCubit>.value(value: engagement),
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

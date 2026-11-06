import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/bidi/bidi.dart';
import 'package:readin/core/l10n/formatters.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/widgets/article_card_tile.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
import 'package:readin/features/article/presentation/widgets/reader_widgets.dart';
import 'package:readin/features/follow/presentation/widgets/follow_button.dart';
import 'package:readin/features/profile/presentation/widgets/profile_link.dart';
import 'package:readin/shared/rdoc/rdoc_view.dart';
import 'package:readin/shared/widgets/author_headline.dart';
import 'package:readin/shared/widgets/badges.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/post_card_fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  testWidgets('isolates the author handle so "@" stays with it in Arabic', (tester) async {
    final article = ArticleDetails(
      card: sampleCard(0),
      availableLanguages: const ['ar-EG'],
      content: const RDocDocument(version: 1, language: 'ar-EG', blocks: []),
    );

    await tester.pumpWidget(testApp(
      SingleChildScrollView(child: ArticleHeader(article: article, titleScale: 1)),
      variant: Variant.all.first,
    ));

    expect(find.textContaining('${Bidi.ltrIsolate('@editorial')} · '), findsOneWidget);
  });

  testWidgets("the reader's author row: the writer's title on one line under the name, then @handle · date (F14)", (tester) async {
    const titled = Author(
      id: 'w-2',
      displayName: 'Omar Khaled',
      username: 'omar_k',
      headline: 'Senior Backend Engineer | .NET | Azure | Microservices and distributed systems at scale',
    );
    final card = sampleCard(1, language: 'en');
    final withTitle = ArticleCard(
      id: card.id,
      slug: card.slug,
      language: card.language,
      title: card.title,
      field: card.field,
      author: titled,
      readingTimeMinutes: card.readingTimeMinutes,
      publishedAt: card.publishedAt,
    );
    usePhoneSurface(tester, size: const Size(360, 800));
    await tester.pumpWidget(testApp(
      SingleChildScrollView(
        child: ArticleHeader(
          article: ArticleDetails(card: withTitle, availableLanguages: const ['en'], content: const RDocDocument(version: 1, language: 'en', blocks: [])),
          titleScale: 1,
        ),
      ),
      variant: const Variant(AppLocales.en, Brightness.light),
    ));

    final title = find.text(titled.headline!);
    expect(title, findsOneWidget);
    expect(tester.widget<Text>(title).maxLines, 1);
    expect(tester.widget<Text>(title).overflow, TextOverflow.ellipsis);
    final handle = find.textContaining('@omar_k');
    expect(tester.getRect(title).top, greaterThanOrEqualTo(tester.getRect(find.text('Omar Khaled')).bottom - 1));
    expect(tester.getRect(handle).top, greaterThanOrEqualTo(tester.getRect(title).bottom - 1));

    await tester.pumpWidget(testApp(
      SingleChildScrollView(
        child: ArticleHeader(
          article: ArticleDetails(card: card, availableLanguages: const ['en'], content: const RDocDocument(version: 1, language: 'en', blocks: [])),
          titleScale: 1,
        ),
      ),
      variant: const Variant(AppLocales.en, Brightness.light),
    ));
    expect(find.byType(AuthorHeadline), findsNothing);
    expect(find.text(titled.headline!), findsNothing, reason: 'no title, no line');
  });

  group('deleted author (SPEC §9.6)', () {
    const en = Variant(AppLocales.en, Brightness.light);
    const ar = Variant(AppLocales.ar, Brightness.light);

    ArticleDetails details(ArticleCard card) => ArticleDetails(
          card: card,
          availableLanguages: [card.language],
          content: RDocDocument(version: 1, language: card.language, blocks: const []),
        );

    void expectNoAuthorLeft() {
      expect(find.byType(UserAvatar), findsNothing, reason: 'no initial from a name');
      expect(find.byType(VerifiedMark), findsNothing);
      expect(find.textContaining('@'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
    }

    testWidgets('the reader byline: "Deleted user", a neutral avatar and the date; no handle or follow', (tester) async {
      final card = sampleCard(1, language: 'en', authorDeleted: true);
      await tester.pumpWidget(testApp(
        SingleChildScrollView(
          child: ArticleHeader(
            article: details(card),
            titleScale: 1,
            authorAction: const Text('Follow', key: ValueKey('author-action')),
          ),
        ),
        variant: en,
      ));

      expect(find.text('Deleted user'), findsOneWidget);
      expect(find.byType(GenericAvatar), findsOneWidget);
      expect(find.text(formatDate(card.publishedAt, 'en')), findsOneWidget, reason: 'the date stays, on its own');
      expect(find.byKey(const ValueKey('author-action')), findsNothing);
      expectNoAuthorLeft();
    });

    testWidgets('the reader byline in Arabic', (tester) async {
      await tester.pumpWidget(testApp(
        SingleChildScrollView(child: ArticleHeader(article: details(sampleCard(1, authorDeleted: true)), titleScale: 1)),
        variant: ar,
      ));

      expect(find.text('مستخدم محذوف'), findsOneWidget);
      expectNoAuthorLeft();
    });

    testWidgets('a feed card says "Deleted user" and still opens the article', (tester) async {
      var opened = 0;
      await tester.pumpWidget(testApp(
        Scaffold(body: ArticleCardTile(article: sampleCard(1, language: 'en', authorDeleted: true), onTap: () => opened++)),
        variant: en,
      ));

      expect(find.text('Deleted user'), findsOneWidget);
      expectNoAuthorLeft();
      await tester.tap(find.text('Deleted user'));
      expect(opened, 1);
    });

    // Today's article is a post card under its label since F34 (it was the hero card).
    testWidgets("today's article says it too, with the neutral avatar and no follow", (tester) async {
      await tester.pumpWidget(testApp(
        withCardStores(Scaffold(body: ListView(children: [PostCard(article: postCard(0, authorDeleted: true), label: 'مقال اليوم')]))),
        variant: ar,
      ));

      expect(find.text('مقال اليوم'), findsOneWidget);
      expect(find.text('مستخدم محذوف'), findsOneWidget);
      expect(find.byType(GenericAvatar), findsOneWidget);
      expect(find.byType(FollowButton), findsNothing);
      expect(find.byType(ProfileLink), findsNothing, reason: 'no profile to open');
      expectNoAuthorLeft();
    });
  });
}

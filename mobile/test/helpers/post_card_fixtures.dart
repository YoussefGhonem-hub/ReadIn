import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/cubit/post_cards_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import 'fixtures.dart';
import 'media_fixtures.dart';
import 'social_fakes.dart';

/// Post cards (F34) the way feeds send them: excerpts in Arabic, English and mixed text, tags, and the viewer's follow.

const arExcerpt = 'لو انت شغال بـ ASP.NET Core، أكيد شفت الـ Dependency Injection في كل حتة. الفكرة ببساطة إن الـ class '
    'مش بيعمل الحاجات اللي محتاجها بنفسه، لكنه بياخدها جاهزة من برّه. ده بيخلي الكود أسهل في الـ testing وأسهل في '
    'التغيير. في المقال ده هنشوف الـ container بيشتغل إزاي، والفرق بين Transient و Scoped و Singleton، وإمتى تستخدم كل '
    'واحد فيهم من غير ما تقع في مشاكل الـ lifetime.';

const enExcerpt = "If you work with ASP.NET Core, you've seen Dependency Injection everywhere. The idea is simple: a class "
    "doesn't build what it needs, it receives it ready-made from outside. That makes the code easier to test and easier "
    'to change. In this article we look at how the container works, the difference between Transient, Scoped and '
    'Singleton, and when to use each one without running into lifetime bugs.';

/// Arabic with English runs, punctuation and code names at the edges of the runs (SPEC §14.2).
const mixedExcerpt = 'اتعمل upgrade لـ .NET 10 والـ EF Core بقى أسرع في الـ queries (خصوصاً مع AsNoTracking()). '
    'جربت الـ benchmark على 3 مشاريع: الفرق 40% في الـ read-heavy endpoints، و C# 14 ضاف field keyword اللي '
    'بيوفر كتير من الـ boilerplate في الـ properties.';

const shortArExcerpt = 'نصيحة سريعة: استخدم AddScoped لأي service بتتعامل مع DbContext.';
const shortEnExcerpt = 'Quick tip: use AddScoped for any service that talks to a DbContext.';

const sampleCover = 'https://api.readin.test/uploads/cover-1/1600.webp';

/// A card's first three tags (F32 `TagRefDto`): a name with a symbol, an English phrase, and dots.
const sampleTagRefs = [
  TagRef(slug: 'csharp', name: 'C#'),
  TagRef(slug: 'dependency-injection', name: 'Dependency Injection'),
  TagRef(slug: 'asp-net-core', name: 'ASP.NET Core'),
];

/// A feed card: [sampleCard] with an excerpt in its language, three of five tags and a cover.
ArticleCard postCard(
  int i, {
  String language = 'ar-EG',
  String? excerpt,
  bool hasMore = true,
  bool cover = true,
  bool authorDeleted = false,
  bool isFollowingAuthor = false,
  List<TagRef> tags = sampleTagRefs,
  int tagCount = 5,
  ArticleAttachments? attachments,
  int reactionCount = 0,
  int commentCount = 0,
  ReactionCounts reactions = ReactionCounts.zero,
  ReactionType? myReaction,
  bool isSaved = false,
  Author? author,
}) {
  final base = sampleCard(i, language: language, authorDeleted: authorDeleted);
  return ArticleCard(
    id: base.id,
    slug: base.slug,
    language: language,
    title: language == 'en' ? 'What is Dependency Injection in .NET, and why does everyone talk about it?' : base.title,
    field: base.field,
    author: authorDeleted ? null : author ?? base.author,
    readingTimeMinutes: base.readingTimeMinutes,
    publishedAt: DateTime.utc(2026, 10, 30, 12),
    coverUrl: cover ? sampleCover : null,
    reactionCount: reactionCount,
    commentCount: commentCount,
    reactions: reactions,
    myReaction: myReaction,
    isSaved: isSaved,
    attachments: attachments,
    excerpt: excerpt ?? (language == 'en' ? enExcerpt : arExcerpt),
    hasMore: hasMore,
    isFollowingAuthor: isFollowingAuthor,
    tags: tags,
    tagCount: tagCount,
  );
}

/// A short article shown whole in the card: no "Read more", no media, no tags.
ArticleCard shortPostCard({String language = 'ar-EG', bool authorDeleted = false}) => postCard(
      7,
      language: language,
      excerpt: language == 'en' ? shortEnExcerpt : shortArExcerpt,
      hasMore: false,
      cover: false,
      tags: const [],
      tagCount: 0,
      authorDeleted: authorDeleted,
    );

/// Three images (F26) and mixed Arabic/English text; the viewer reacted ❤️ and saved it.
ArticleCard attachmentsPostCard({String language = 'ar-EG'}) => postCard(
      2,
      language: language,
      excerpt: language == 'en' ? enExcerpt : mixedExcerpt,
      attachments: ArticleAttachments(
        kind: AttachmentsKind.images,
        images: [for (var i = 0; i < 3; i++) sampleImage(i)],
      ),
      tags: const [TagRef(slug: 'ef-core', name: 'EF Core'), TagRef(slug: 'performance', name: 'performance')],
      tagCount: 2,
      reactions: const ReactionCounts(insightful: 9, love: 14, fire: 2),
      reactionCount: 25,
      commentCount: 6,
      myReaction: ReactionType.love,
      isSaved: true,
      isFollowingAuthor: true,
    );

/// The beginning of the article as the preview endpoint returns it: a paragraph, a list, code and a callout.
ArticlePreview samplePreview(String articleId, {String language = 'ar-EG', bool isComplete = false}) {
  final en = language == 'en';
  return ArticlePreview(
    id: articleId,
    language: language,
    isComplete: isComplete,
    content: RDocDocument.fromJson({
      'version': 1,
      'language': language,
      'blocks': [
        {
          'id': 'b1',
          'type': 'paragraph',
          'dir': 'auto',
          'content': [
            {'type': 'text', 'text': en ? 'If you work with ' : 'لو انت شغال بـ '},
            {
              'type': 'text',
              'text': 'ASP.NET Core',
              'marks': [
                {'type': 'bold'},
              ],
            },
            {'type': 'text', 'text': en ? ", you've seen " : '، أكيد شفت الـ '},
            {'type': 'term', 'termId': 'dependency-injection', 'text': 'Dependency Injection'},
            {'type': 'text', 'text': en ? ' everywhere.' : ' في كل حتة.'},
          ],
        },
        {
          'id': 'b2',
          'type': 'bulletList',
          'dir': 'auto',
          'items': [
            [
              {'type': 'text', 'text': en ? 'Transient: a new object every time' : 'Transient: object جديد كل مرة'},
            ],
            [
              {'type': 'text', 'text': en ? 'Scoped: one per request' : 'Scoped: واحد لكل request'},
            ],
          ],
        },
        {
          'id': 'b3',
          'type': 'code',
          'lang': 'csharp',
          'filename': 'Program.cs',
          'code': 'builder.Services.AddScoped<IOrderService, OrderService>();',
        },
        {
          'id': 'b4',
          'type': 'callout',
          'variant': 'tip',
          'content': [
            {'type': 'text', 'text': en ? 'Use AddScoped for anything that talks to a DbContext.' : 'استخدم AddScoped لأي service بتتعامل مع DbContext.'},
          ],
        },
      ],
    }),
  );
}

/// The app-wide stores a post card reads, as mocks holding [session] (signed in as [sampleMe] by default), no
/// engagement or follows beyond the card's own; plus [postCards] when given.
Widget withCardStores(
  Widget child, {
  SessionState session = const SessionState(status: SessionStatus.authenticated, me: sampleMe),
  EngagementCubit? engagement,
  FollowsCubit? follows,
  PostCardsCubit? postCards,
}) {
  final sessionCubit = MockSessionCubit();
  whenListen(sessionCubit, const Stream<SessionState>.empty(), initialState: session);
  final engagementCubit = MockEngagementCubit();
  whenListen(engagementCubit, const Stream<EngagementState>.empty(), initialState: const EngagementState());
  final followsCubit = MockFollowsCubit();
  whenListen(followsCubit, const Stream<FollowsState>.empty(), initialState: const FollowsState());
  return MultiBlocProvider(
    providers: [
      BlocProvider<SessionCubit>.value(value: sessionCubit),
      BlocProvider<EngagementCubit>.value(value: engagement ?? engagementCubit),
      BlocProvider<FollowsCubit>.value(value: follows ?? followsCubit),
      if (postCards != null) BlocProvider<PostCardsCubit>.value(value: postCards),
    ],
    child: child,
  );
}

/// A preview loader for [PostCardsCubit.withLoader]: answers [samplePreview], or [failure].
Future<Result<ArticlePreview>> Function(String, {required String language}) previewLoader({
  bool isComplete = false,
  Failure? failure,
  List<String>? calls,
}) =>
    (articleId, {required language}) async {
      calls?.add('$articleId/$language');
      if (failure != null) return Err(failure);
      return Ok(samplePreview(articleId, language: language, isComplete: isComplete));
    };

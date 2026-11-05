import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/mutes/domain/entities/mutes.dart';
import 'package:readin/features/mutes/domain/repositories/mutes_repository.dart';
import 'package:readin/features/mutes/domain/usecases/mute_usecases.dart';
import 'package:readin/features/mutes/presentation/cubit/mutes_cubit.dart';

import 'fixtures.dart';
import 'social_fakes.dart';

class MockMutesRepository extends Mock implements MutesRepository {}

const omarWriter = Author(id: 'u-9', displayName: 'Omar Khaled', username: 'omar_dev');
const daliaWriter = Author(id: 'u-7', displayName: 'داليا سمير', username: 'dalia');
const diTopic = FieldRef(id: 't-di', slug: 'dependency-injection', nameAr: 'Dependency Injection', nameEn: 'Dependency Injection');
const promptsTopic = FieldRef(id: 't-prompts', slug: 'prompts', nameAr: 'كتابة البرومبتات', nameEn: 'Prompt writing');

/// [sampleCard] `i` by [author], with a topic (F28 cards carry one) unless [topic] is null.
ArticleCard muteCard(
  int i, {
  Author? author = omarWriter,
  FieldRef field = dotnetField,
  FieldRef? topic = diTopic,
  bool isFieldMuted = false,
  bool isTopicMuted = false,
  bool isAuthorMuted = false,
  String language = 'ar-EG',
  String? title,
}) {
  final card = sampleCard(i, language: language);
  return ArticleCard(
    id: card.id,
    slug: card.slug,
    language: card.language,
    title: title ?? card.title,
    field: field,
    author: author,
    readingTimeMinutes: card.readingTimeMinutes,
    publishedAt: card.publishedAt,
    topic: topic,
    isAuthorMuted: isAuthorMuted,
    isFieldMuted: isFieldMuted,
    isTopicMuted: isTopicMuted,
  );
}

/// A repository whose writes all succeed, the way the API answers them.
MockMutesRepository okMutesRepository({bool followRemoved = true}) {
  final repository = MockMutesRepository();
  when(() => repository.muteUser(any())).thenAnswer(
    (_) async => Ok(UserMuteState(isMuted: true, isFollowing: false, followerCount: 41, followRemoved: followRemoved)),
  );
  when(() => repository.unmuteUser(any(), restoreFollow: any(named: 'restoreFollow'))).thenAnswer(
    (invocation) async {
      final restore = invocation.namedArguments[#restoreFollow] as bool;
      return Ok(UserMuteState(isMuted: false, isFollowing: restore, followerCount: restore ? 42 : 41));
    },
  );
  when(() => repository.setFieldMuted(any(), muted: any(named: 'muted'))).thenAnswer((invocation) async {
    final muted = invocation.namedArguments[#muted] as bool;
    return Ok(ContentMutes(fieldIds: [if (muted) invocation.positionalArguments.first as String]));
  });
  when(() => repository.setTopicMuted(any(), muted: any(named: 'muted'))).thenAnswer((invocation) async {
    final muted = invocation.namedArguments[#muted] as bool;
    return Ok(ContentMutes(topicIds: [if (muted) invocation.positionalArguments.first as String]));
  });
  when(() => repository.setShowLess(any(), showLess: any(named: 'showLess'))).thenAnswer((_) async => const Ok(null));
  when(() => repository.getMutes()).thenAnswer((_) async => const Ok(sampleMutes));
  return repository;
}

/// A real [MutesCubit] over [repository], for [session], telling [follows] about follow changes.
MutesCubit mutesCubit(MutesRepository repository, {required SessionCubit session, FollowsCubit? follows}) => MutesCubit(
      SetUserMuted(repository),
      SetContentMuted(repository),
      SetShowLess(repository),
      session,
      follows ?? FollowsCubit(SetFollowing(MockFollowRepository())),
    );

const _backend = MutedField(id: 'f-backend', slug: 'backend', nameAr: 'Backend', nameEn: 'Backend', icon: 'cog', color: 'accent');

/// Settings → Muted with a writer of each direction, a field and a topic.
const sampleMutes = Mutes(
  users: [
    UserSummary(id: 'u-9', displayName: 'Omar Khaled', username: 'omar_dev', isVerified: true),
    UserSummary(id: 'u-7', displayName: 'داليا سمير', username: 'dalia'),
  ],
  fields: [MutedField(id: 'f-ai', slug: 'ai', nameAr: 'الذكاء الاصطناعي', nameEn: 'AI', icon: 'sparkles', color: 'primary')],
  topics: [MutedTopic(id: 't-orm', slug: 'ef-core', nameAr: 'EF Core', nameEn: 'EF Core', field: _backend)],
);

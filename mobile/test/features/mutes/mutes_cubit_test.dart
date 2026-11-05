import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/domain/entities/follow.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/mutes/domain/entities/mutes.dart';
import 'package:readin/features/mutes/domain/usecases/mute_usecases.dart';
import 'package:readin/features/mutes/presentation/cubit/muted_list_cubit.dart';
import 'package:readin/features/mutes/presentation/cubit/mutes_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mute_fixtures.dart';
import '../../helpers/social_fakes.dart';

/// The viewer's mutes across screens (F28): applied at once, rolled back on refusal, tied to the follow and the
/// account; and Settings → Muted.
void main() {
  late MockMutesRepository repository;
  late MockFollowRepository followRepository;
  late FollowsCubit follows;
  late MockSessionCubit session;
  late StreamController<SessionState> sessions;
  late MutesCubit cubit;

  const signedIn = SessionState(status: SessionStatus.authenticated, me: sampleMe);
  const refused = Failure(FailureCodes.muteSystemAccount, statusCode: 400);

  setUp(() {
    repository = okMutesRepository();
    followRepository = MockFollowRepository();
    follows = FollowsCubit(SetFollowing(followRepository));
    sessions = StreamController<SessionState>.broadcast();
    session = MockSessionCubit();
    whenListen(session, sessions.stream, initialState: signedIn);
    cubit = mutesCubit(repository, session: session, follows: follows);
  });

  tearDown(() async {
    await cubit.close();
    await follows.close();
    await sessions.close();
  });

  group('writers', () {
    test('a mute applies at once; the answer ends the follow and sets the follower count', () async {
      final answer = Completer<Result<UserMuteState>>();
      when(() => repository.muteUser('u-9')).thenAnswer((_) => answer.future);
      follows.seed({'u-9': true});

      final request = cubit.muteUser('u-9');
      expect(cubit.state.isUserMuted('u-9'), isTrue, reason: 'the cards fold away before the answer');
      expect(cubit.state.isPending('user:u-9'), isTrue);

      answer.complete(const Ok(UserMuteState(isMuted: true, isFollowing: false, followerCount: 41, followRemoved: true)));
      final result = await request;

      expect(result.valueOrNull?.followRemoved, isTrue);
      expect(cubit.state.isPending('user:u-9'), isFalse);
      expect(follows.state.users['u-9'], const FollowEntry(isFollowing: false, followerCount: 41));
    });

    test('a refused mute rolls back and says why', () async {
      when(() => repository.muteUser('u-9')).thenAnswer((_) async => const Err(refused));

      final result = await cubit.muteUser('u-9');

      expect(result.failureOrNull, refused);
      expect(cubit.state.users, isEmpty);
      expect(cubit.state.isUserMuted('u-9', fallback: false), isFalse);
    });

    test('the Undo of a mute that ended a follow follows again', () async {
      await cubit.muteUser('u-9');

      await cubit.unmuteUser('u-9', restoreFollow: true);

      verify(() => repository.unmuteUser('u-9', restoreFollow: true)).called(1);
      expect(cubit.state.isUserMuted('u-9', fallback: true), isFalse);
      expect(follows.state.users['u-9'], const FollowEntry(isFollowing: true, followerCount: 42));
    });

    test('unmuting a writer loaded as muted (the banner) wins over the loaded flag', () async {
      expect(cubit.state.isUserMuted('u-9', fallback: true), isTrue);

      await cubit.unmuteUser('u-9');

      verify(() => repository.unmuteUser('u-9', restoreFollow: false)).called(1);
      expect(cubit.state.isUserMuted('u-9', fallback: true), isFalse);
    });

    test('a second tap while the first request runs is ignored', () async {
      final answer = Completer<Result<UserMuteState>>();
      when(() => repository.muteUser('u-9')).thenAnswer((_) => answer.future);

      final first = cubit.muteUser('u-9');
      final second = await cubit.muteUser('u-9');
      answer.complete(const Ok(UserMuteState(isMuted: true, isFollowing: false, followerCount: 3)));
      await first;

      expect(second.failureOrNull?.code, FailureCodes.requestCancelled);
      verify(() => repository.muteUser('u-9')).called(1);
    });

    test('following a muted writer ends the mute, as on the server', () async {
      when(() => followRepository.follow('u-9')).thenAnswer((_) async => const Ok(FollowState(isFollowing: true, followerCount: 42)));
      await cubit.muteUser('u-9');

      await follows.setFollowing('u-9', follow: true);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isUserMuted('u-9', fallback: true), isFalse);
    });

    test('following a writer muted before this session (known only from a screen\'s flag) ends the mute too', () async {
      when(() => followRepository.follow('u-9')).thenAnswer((_) async => const Ok(FollowState(isFollowing: true, followerCount: 42)));
      expect(cubit.state.isUserMuted('u-9', fallback: true), isTrue, reason: 'the profile or the reader loaded it muted');

      await follows.setFollowing('u-9', follow: true);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isUserMuted('u-9', fallback: true), isFalse);
      verifyNever(() => repository.unmuteUser(any(), restoreFollow: any(named: 'restoreFollow')));
    });

    test('an unfollow changes nothing about the mute', () async {
      when(() => followRepository.unfollow('u-9')).thenAnswer((_) async => const Ok(FollowState(isFollowing: false, followerCount: 41)));
      follows.seed({'u-9': true});

      await follows.setFollowing('u-9', follow: false);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isUserMuted('u-9', fallback: true), isTrue);
      expect(cubit.state.users, isEmpty);
    });
  });

  group('fields and topics', () {
    test('every id the answer names is muted; one it no longer names is not', () async {
      when(() => repository.setFieldMuted('f-ai', muted: true))
          .thenAnswer((_) async => const Ok(ContentMutes(fieldIds: ['f-ai', 'f-old'], topicIds: ['t-di'])));
      when(() => repository.setFieldMuted('f-ai', muted: false))
          .thenAnswer((_) async => const Ok(ContentMutes(fieldIds: ['f-old'], topicIds: ['t-di'])));

      expect(await cubit.setFieldMuted('f-ai', muted: true), isNull);
      expect(cubit.state.fields, {'f-ai': true, 'f-old': true});
      expect(cubit.state.topics, {'t-di': true});

      expect(await cubit.setFieldMuted('f-ai', muted: false), isNull);
      expect(cubit.state.isFieldMuted('f-ai', fallback: true), isFalse);
      expect(cubit.state.isFieldMuted('f-old'), isTrue);
    });

    test('a topic toggles at once and rolls back when refused', () async {
      final answer = Completer<Result<ContentMutes>>();
      when(() => repository.setTopicMuted('t-di', muted: true)).thenAnswer((_) => answer.future);

      final request = cubit.setTopicMuted('t-di', muted: true);
      expect(cubit.state.isTopicMuted('t-di'), isTrue);
      answer.complete(const Err(Failure(FailureCodes.topicNotFound, statusCode: 404)));

      expect((await request)?.code, FailureCodes.topicNotFound);
      expect(cubit.state.topics, isEmpty);
    });
  });

  group('show less', () {
    test('marks the article at once; Undo takes the mark out', () async {
      final request = cubit.showLess('art-1');
      expect(cubit.state.showLess, {'art-1'});
      expect(await request, isNull);

      expect(await cubit.undoShowLess('art-1'), isNull);
      expect(cubit.state.showLess, isEmpty);
      verifyInOrder([
        () => repository.setShowLess('art-1', showLess: true),
        () => repository.setShowLess('art-1', showLess: false),
      ]);
    });

    test('a refused mark rolls back', () async {
      when(() => repository.setShowLess('art-1', showLess: true))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.muteOwnArticle, statusCode: 400)));

      expect((await cubit.showLess('art-1'))?.code, FailureCodes.muteOwnArticle);
      expect(cubit.state.showLess, isEmpty);
    });
  });

  group('which cards a list leaves out', () {
    test('a muted writer, field or topic, or a show-less mark', () {
      final card = muteCard(1);
      expect(const MutesState().hides(card), isFalse);
      expect(const MutesState(users: {'u-9': true}).hides(card), isTrue);
      expect(const MutesState(fields: {'f-dotnet': true}).hides(card), isTrue);
      expect(const MutesState(topics: {'t-di': true}).hides(card), isTrue);
      expect(const MutesState(showLess: {'art-1'}).hides(card), isTrue);
      expect(const MutesState(topics: {'t-di': true}).hides(muteCard(1, topic: null)), isFalse);
      expect(const MutesState(users: {'u-9': true}).hides(muteCard(1, author: null)), isFalse, reason: 'a deleted author');
    });

    test('the session overrides what the card was loaded with', () {
      expect(const MutesState().hides(muteCard(1, isAuthorMuted: true)), isTrue);
      expect(const MutesState(users: {'u-9': false}).hides(muteCard(1, isAuthorMuted: true)), isFalse);
      expect(const MutesState(fields: {'f-dotnet': false}).hides(muteCard(1, isFieldMuted: true)), isFalse);
    });

    test("a field page keeps its own field and the picked topic, not the field's other muted topics", () {
      const state = MutesState(fields: {'f-dotnet': true}, topics: {'t-di': true, 't-other': true});
      expect(state.hides(muteCard(1), keepFieldId: 'f-dotnet', keepTopicId: 't-di'), isFalse);
      expect(state.hides(muteCard(1), keepFieldId: 'f-dotnet'), isTrue, reason: 'its topic is muted and not picked');
      const other = FieldRef(id: 't-other', slug: 'other', nameAr: 'تاني', nameEn: 'Other');
      expect(state.hides(muteCard(2, topic: other), keepFieldId: 'f-dotnet', keepTopicId: 't-di'), isTrue);
    });
  });

  test('signing out clears the session and drops an answer for the old account', () async {
    final answer = Completer<Result<UserMuteState>>();
    when(() => repository.muteUser('u-9')).thenAnswer((_) => answer.future);
    await cubit.showLess('art-1');
    final request = cubit.muteUser('u-9');

    sessions.add(const SessionState(status: SessionStatus.guest));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, const MutesState());

    answer.complete(const Ok(UserMuteState(isMuted: true, isFollowing: false, followerCount: 1)));
    await request;
    expect(cubit.state, const MutesState());
  });

  group('Settings → Muted', () {
    late MutedListCubit list;

    setUp(() => list = MutedListCubit(GetMutes(repository), cubit));
    tearDown(() => list.close());

    test('loads the writers, fields and topics', () async {
      await list.load();

      expect(list.state.status, MutedListStatus.ready);
      expect(list.state.mutes, sampleMutes);
    });

    test('a failed load can be retried', () async {
      when(() => repository.getMutes()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      await list.load();
      expect(list.state.status, MutedListStatus.failure);

      when(() => repository.getMutes()).thenAnswer((_) async => const Ok(Mutes()));
      await list.load();
      expect(list.state.status, MutedListStatus.ready);
      expect(list.state.mutes.isEmpty, isTrue);
    });

    test('unmuting takes the row out, everywhere; a refusal keeps it', () async {
      await list.load();

      expect(await list.unmuteUser('u-9'), isNull);
      expect(await list.unmuteField('f-ai'), isNull);
      expect(await list.unmuteTopic('t-orm'), isNull);
      expect(list.state.mutes.users.map((u) => u.id), ['u-7']);
      expect(list.state.mutes.fields, isEmpty);
      expect(list.state.mutes.topics, isEmpty);
      expect(cubit.state.isUserMuted('u-9', fallback: true), isFalse, reason: 'every screen hears of it');
      verify(() => repository.unmuteUser('u-9', restoreFollow: false)).called(1);

      when(() => repository.unmuteUser('u-7', restoreFollow: false))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      expect((await list.unmuteUser('u-7'))?.code, FailureCodes.networkOffline);
      expect(list.state.mutes.users.map((u) => u.id), ['u-7']);
    });
  });
}

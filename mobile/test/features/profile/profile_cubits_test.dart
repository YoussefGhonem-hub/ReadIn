import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/core/security/credential_rules.dart';
import 'package:readin/features/auth/domain/entities/auth_config.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/repositories/auth_repository.dart';
import 'package:readin/features/auth/domain/usecases/auth_usecases.dart';
import 'package:readin/features/auth/presentation/cubit/complete_profile_cubit.dart' show UsernameStatus;
import 'package:readin/features/auth/presentation/cubit/form_support.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/domain/entities/follow.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/media/domain/usecases/media_usecases.dart';
import 'package:readin/features/profile/domain/entities/profile.dart';
import 'package:readin/features/profile/domain/repositories/profile_repository.dart';
import 'package:readin/features/profile/domain/usecases/profile_usecases.dart';
import 'package:readin/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/follow_list_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/privacy_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:readin/features/taxonomy/domain/usecases/taxonomy_usecases.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/profile_fixtures.dart';
import '../../helpers/social_fakes.dart';

class MockGetProfile extends Mock implements GetProfile {}

class MockGetFields extends Mock implements GetFields {}

class MockCheckUsername extends Mock implements CheckUsername {}

class MockPickImages extends Mock implements PickImages {}

class MockTakePhoto extends Mock implements TakePhoto {}

class MockUploadImage extends Mock implements UploadImage {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

class MockGetFollowLists extends Mock implements GetFollowLists {}

class MockSetFollowing extends Mock implements SetFollowing {}

class MockSetPublicReadingStats extends Mock implements SetPublicReadingStats {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

const _photo = PickedMediaFile(path: 'me.jpg', name: 'me.jpg', sizeBytes: 10);
const _asset = MediaAsset(
  id: 'asset-1',
  kind: MediaKind.image,
  status: MediaStatus.ready,
  purpose: 'avatar',
  variants: [
    MediaVariant(width: 64, height: 64, url: 'https://api.test/uploads/a64.webp'),
    MediaVariant(width: 256, height: 256, url: 'https://api.test/uploads/a256.webp'),
    MediaVariant(width: 512, height: 512, url: 'https://api.test/uploads/a512.webp'),
  ],
);

void main() {
  setUpAll(() {
    registerFallbackValue(_photo);
    registerFallbackValue(const ProfileUpdate(displayName: 'x', username: 'x'));
  });

  group('ProfileCubit', () {
    late MockGetProfile getProfile;
    late MockSetFollowing setFollowing;
    late FollowsCubit follows;

    setUp(() {
      getProfile = MockGetProfile();
      setFollowing = MockSetFollowing();
      follows = FollowsCubit(setFollowing);
    });
    tearDown(() => follows.close());

    test('loads a profile and seeds the follow store with it', () async {
      when(() => getProfile('mona_dev')).thenAnswer((_) async => Ok(otherProfile));
      final cubit = ProfileCubit(getProfile, follows);

      await cubit.load('mona_dev');

      expect(cubit.state, ProfileState(status: ProfileStatus.ready, profile: otherProfile));
      expect(follows.state.users[otherProfile.id]?.isFollowing, isFalse);
      await cubit.close();
    });

    test('404 is "not found", other failures are retryable errors', () async {
      when(() => getProfile('ghost')).thenAnswer((_) async => const Err(Failure(FailureCodes.userNotFound, statusCode: 404)));
      when(() => getProfile('mona')).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      final cubit = ProfileCubit(getProfile, follows);

      await cubit.load('ghost');
      expect(cubit.state.notFound, isTrue);
      await cubit.load('mona');
      expect(cubit.state.status, ProfileStatus.failure);
      expect(cubit.state.notFound, isFalse);
      await cubit.close();
    });

    test('following them here updates the follower count with the API\'s number', () async {
      when(() => getProfile('mona_dev')).thenAnswer((_) async => Ok(otherProfile));
      when(() => setFollowing(otherProfile.id, follow: true))
          .thenAnswer((_) async => const Ok(FollowState(isFollowing: true, followerCount: 351)));
      final cubit = ProfileCubit(getProfile, follows);
      await cubit.load('mona_dev');

      await follows.setFollowing(otherProfile.id, follow: true);
      await pumpEventQueue();

      expect(cubit.state.profile!.isFollowing, isTrue);
      expect(cubit.state.profile!.stats.followers, 351);
      await cubit.close();
    });

    test('on the own profile, follows made anywhere change "following"', () async {
      when(() => getProfile('reader1')).thenAnswer((_) async => Ok(ownProfile));
      when(() => setFollowing(any(), follow: any(named: 'follow'))).thenAnswer(
        (i) async => Ok(FollowState(isFollowing: i.namedArguments[#follow] as bool, followerCount: 1)),
      );
      final cubit = ProfileCubit(getProfile, follows);
      await cubit.load('reader1');

      await follows.setFollowing('w-1', follow: true);
      await follows.setFollowing('w-2', follow: true);
      await follows.setFollowing('w-1', follow: false);
      await pumpEventQueue();

      expect(cubit.state.profile!.stats.following, ownProfile.stats.following + 1);
      await cubit.close();
    });

    test('a refresh keeps the profile on screen when it fails', () async {
      when(() => getProfile('mona_dev')).thenAnswer((_) async => Ok(otherProfile));
      final cubit = ProfileCubit(getProfile, follows);
      await cubit.load('mona_dev');
      when(() => getProfile('mona_dev')).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));

      await cubit.refresh();

      expect(cubit.state.profile, otherProfile);
      expect(cubit.state.status, ProfileStatus.ready);
      await cubit.close();
    });
  });

  group('FollowListCubit', () {
    late MockGetFollowLists lists;
    late MockFollowsCubit follows;

    setUp(() {
      lists = MockGetFollowLists();
      follows = MockFollowsCubit();
    });

    CursorPage<UserSummary> page(List<UserSummary> users, [String? next]) => CursorPage(items: users, nextCursor: next);

    test('loads the first page, seeds the follow buttons, then pages on', () async {
      when(() => lists.followers('u-mona', query: '', cursor: null)).thenAnswer((_) async => Ok(page(sampleFollowers.take(2).toList(), 'c2')));
      when(() => lists.followers('u-mona', query: '', cursor: 'c2')).thenAnswer((_) async => Ok(page(sampleFollowers.skip(2).toList())));
      final cubit = FollowListCubit(lists, follows, 'u-mona', FollowListKind.followers);

      await cubit.load();
      await cubit.loadMore();
      await cubit.loadMore(); // nothing more to load

      expect(cubit.state.items, sampleFollowers);
      expect(cubit.state.hasMore, isFalse);
      verify(() => follows.seed({'w-1': false, 'w-2': true})).called(1);
      verify(() => follows.seed({'w-3': false, 'a-1': true})).called(1);
      verify(() => lists.followers('u-mona', query: any(named: 'query'), cursor: any(named: 'cursor'))).called(2);
      await cubit.close();
    });

    testWidgets('searches once typing pauses, on the following list', (tester) async {
      when(() => lists.following('u-mona', query: any(named: 'query'), cursor: null))
          .thenAnswer((i) async => Ok(page(i.namedArguments[#query] == 'om' ? [sampleFollowers[1]] : sampleFollowers)));
      final cubit = FollowListCubit(lists, follows, 'u-mona', FollowListKind.following);
      await cubit.load();

      cubit
        ..search('o')
        ..search('om ');
      await tester.pump(FollowListCubit.searchDebounce);
      await tester.pump();

      verifyNever(() => lists.following('u-mona', query: 'o', cursor: null));
      expect(cubit.state.query, 'om');
      expect(cubit.state.items, [sampleFollowers[1]]);
      await cubit.close();
    });

    test('a failed page keeps the list and offers a retry', () async {
      when(() => lists.followers('u-mona', query: '', cursor: null)).thenAnswer((_) async => Ok(page(sampleFollowers, 'c2')));
      when(() => lists.followers('u-mona', query: '', cursor: 'c2')).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      final cubit = FollowListCubit(lists, follows, 'u-mona', FollowListKind.followers);

      await cubit.load();
      await cubit.loadMore();

      expect(cubit.state.items, sampleFollowers);
      expect(cubit.state.loadMoreFailure?.code, FailureCodes.networkOffline);
      await cubit.close();
    });
  });

  group('EditProfileCubit', () {
    late MockGetProfile getProfile;
    late MockGetFields getFields;
    late MockCheckUsername check;
    late MockPickImages pick;
    late MockTakePhoto takePhoto;
    late MockUploadImage upload;
    late MockUpdateProfile update;

    setUp(() {
      getProfile = MockGetProfile();
      getFields = MockGetFields();
      check = MockCheckUsername();
      pick = MockPickImages();
      takePhoto = MockTakePhoto();
      upload = MockUploadImage();
      update = MockUpdateProfile();
      when(() => getFields()).thenAnswer((_) async => const Ok(sampleFields));
    });

    EditProfileCubit build() => EditProfileCubit(getProfile, getFields, check, pick, takePhoto, upload, update);

    Future<EditProfileCubit> started(UserProfile profile) async {
      final cubit = build();
      await cubit.start(profile: profile, username: profile.username);
      await pumpEventQueue();
      return cubit;
    }

    Future<void> submit(EditProfileCubit cubit, {String name = 'Mona Adel', String bio = '', String github = '', String website = ''}) =>
        cubit.submit(displayName: name, bio: bio, github: github, linkedin: '', website: website);

    test('starts from the handed-over profile: its handle counts as available, its expertise is picked', () async {
      final cubit = await started(otherProfile);

      expect(cubit.state.load, EditProfileLoad.ready);
      expect(cubit.state.username, 'mona_dev');
      expect(cubit.state.usernameStatus, UsernameStatus.available);
      expect(cubit.state.expertiseIds, ['f-dotnet', 'f-db']);
      expect(cubit.state.avatar, const KeepAvatar(null));
      expect(cubit.state.fields, sampleFields);
      verifyNever(() => getProfile(any()));
      await cubit.close();
    });

    test('without a profile it loads the own one (MeDto has no expertise)', () async {
      when(() => getProfile('reader1')).thenAnswer((_) async => Ok(ownProfile));
      final cubit = build();

      await cubit.start(username: 'reader1');

      expect(cubit.state.profile, ownProfile);
      expect(cubit.state.load, EditProfileLoad.ready);
      await cubit.close();
    });

    testWidgets('checks a new username once typing pauses; the current one needs no check', (tester) async {
      when(() => check('mona_x')).thenAnswer((_) async => const Ok(UsernameAvailability(username: 'mona_x', valid: true, available: false)));
      final cubit = build();
      await cubit.start(profile: otherProfile, username: 'mona_dev');

      cubit.usernameChanged('Mona_X');
      expect(cubit.state.usernameStatus, UsernameStatus.checking);
      await tester.pump(EditProfileCubit.debounce);
      await tester.pump();
      expect(cubit.state.usernameStatus, UsernameStatus.taken);

      cubit.usernameChanged('mona_dev');
      expect(cubit.state.usernameStatus, UsernameStatus.available);
      cubit.usernameChanged('mo');
      expect(cubit.state.usernameStatus, UsernameStatus.invalid);
      verify(() => check(any())).called(1);
      await cubit.close();
    });

    test('a gallery or camera photo is uploaded as an avatar; its 256 px variant is the preview', () async {
      when(() => takePhoto()).thenAnswer((_) async => _photo);
      when(() => upload(any(), purpose: 'avatar')).thenAnswer((_) async => const Ok(_asset));
      final cubit = await started(otherProfile);
      final states = <EditProfileState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.pickAvatar(AvatarSource.camera);

      expect(states.first.uploadingAvatar, isTrue);
      expect(cubit.state.uploadingAvatar, isFalse);
      expect(cubit.state.avatar, const NewAvatar('asset-1'));
      expect(cubit.state.avatarUrl, 'https://api.test/uploads/a256.webp');
      verifyNever(() => pick(limit: any(named: 'limit')));
      await sub.cancel();
      await cubit.close();
    });

    test('a cancelled pick changes nothing; a failed upload shows under the avatar', () async {
      when(() => pick(limit: 1)).thenAnswer((_) async => const []);
      final cubit = await started(otherProfile);

      await cubit.pickAvatar(AvatarSource.gallery);
      expect(cubit.state.avatar, const KeepAvatar(null));
      verifyNever(() => upload(any(), purpose: any(named: 'purpose')));

      when(() => pick(limit: 1)).thenAnswer((_) async => const [_photo]);
      when(() => upload(any(), purpose: 'avatar')).thenAnswer((_) async => const Err(Failure(FailureCodes.mediaTooLarge)));
      await cubit.pickAvatar(AvatarSource.gallery);
      expect(cubit.state.errors[ProfileFields.avatar], FailureCodes.mediaTooLarge);
      expect(cubit.state.avatar, const KeepAvatar(null));
      await cubit.close();
    });

    test('remove clears the preview and asks the server to remove the avatar', () async {
      const withAvatar = UserProfile(id: 'u-1', displayName: 'Y', username: 'reader1', avatarUrl: 'https://api.test/a.webp', isMe: true);
      final cubit = await started(withAvatar);
      expect(cubit.state.avatar, const KeepAvatar('https://api.test/a.webp'));

      cubit.removeAvatar();

      expect(cubit.state.avatar, const RemoveAvatar());
      expect(cubit.state.avatarUrl, isNull);
      await cubit.close();
    });

    test('expertise: at most five, in the order picked', () async {
      final cubit = await started(ownProfile);
      for (final id in ['f-ai', 'f-dotnet', 'f-1', 'f-2', 'f-3', 'f-4']) {
        cubit.toggleExpertise(id);
      }
      expect(cubit.state.expertiseIds, ['f-ai', 'f-dotnet', 'f-1', 'f-2', 'f-3']);
      expect(cubit.state.expertiseFull, isTrue);

      cubit.toggleExpertise('f-dotnet');
      expect(cubit.state.expertiseIds, ['f-ai', 'f-1', 'f-2', 'f-3']);
      await cubit.close();
    });

    test('validates the name, the links (https, completed) and a taken username before saving', () async {
      final cubit = await started(otherProfile);

      await submit(cubit, name: ' M ', github: 'http://github.com/mona', website: 'ftp://mona.dev');

      expect(cubit.state.errors, {
        ProfileFields.displayName: FailureCodes.validationMinLength,
        ProfileFields.github: FailureCodes.validationUrl,
        ProfileFields.website: FailureCodes.validationUrl,
      });
      verifyNever(() => update(any()));

      await submit(cubit, name: '');
      expect(cubit.state.errors[ProfileFields.displayName], CredentialCodes.required);
      await cubit.close();
    });

    test('saves: untouched avatar and expertise are left out; bare links get https://', () async {
      when(() => update(any())).thenAnswer((_) async => const Ok(null));
      final cubit = await started(otherProfile);

      await submit(cubit, name: ' منى عادل ', bio: ' bio ', github: 'github.com/mona-dev', website: 'https://mona.dev/');

      final sent = verify(() => update(captureAny())).captured.single as ProfileUpdate;
      expect(
        sent,
        const ProfileUpdate(
          displayName: 'منى عادل',
          username: 'mona_dev',
          bio: 'bio',
          links: ProfileLinks(github: 'https://github.com/mona-dev', linkedin: '', website: 'https://mona.dev/'),
        ),
      );
      expect(sent.expertiseFieldIds, isNull);
      expect(sent.avatar, const KeepAvatar(null));
      expect(cubit.state.status, FormStatus.success);
      await cubit.close();
    });

    test('saves changed expertise (and [] when all are removed)', () async {
      when(() => update(any())).thenAnswer((_) async => const Ok(null));
      final cubit = await started(otherProfile);
      cubit
        ..toggleExpertise('f-dotnet')
        ..toggleExpertise('f-db');

      await submit(cubit);

      final sent = verify(() => update(captureAny())).captured.single as ProfileUpdate;
      expect(sent.expertiseFieldIds, isEmpty);
      await cubit.close();
    });

    test('no double submit: a second save while the first runs is ignored', () async {
      final pending = Completer<Result<void>>();
      when(() => update(any())).thenAnswer((_) => pending.future);
      final cubit = await started(otherProfile);

      unawaited(submit(cubit));
      expect(cubit.state.submitting, isTrue);
      await submit(cubit);
      pending.complete(const Ok(null));
      await pumpEventQueue();

      verify(() => update(any())).called(1);
      expect(cubit.state.status, FormStatus.success);
      await cubit.close();
    });

    test('server errors land on their fields; a taken username marks the handle', () async {
      when(() => update(any())).thenAnswer((_) async => const Err(Failure(FailureCodes.usernameTaken, statusCode: 409)));
      final cubit = await started(otherProfile);

      await submit(cubit);

      expect(cubit.state.status, FormStatus.idle);
      expect(cubit.state.errors, {ProfileFields.username: FailureCodes.usernameTaken});
      expect(cubit.state.usernameStatus, UsernameStatus.taken);
      expect(cubit.state.failure, isNull);

      when(() => update(any())).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      cubit.usernameChanged('mona_dev'); // back to the current handle
      await submit(cubit);
      expect(cubit.state.failure?.code, FailureCodes.networkOffline);
      await cubit.close();
    });

    test('a failed load is shown with a retry; the field list fails on its own', () async {
      when(() => getProfile('reader1')).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      when(() => getFields()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      final cubit = build();

      await cubit.start(username: 'reader1');
      await pumpEventQueue();

      expect(cubit.state.load, EditProfileLoad.failure);
      expect(cubit.state.fieldsStatus, EditProfileLoad.failure);
      await submit(cubit);
      verifyNever(() => update(any()));
      await cubit.close();
    });
  });

  group('PrivacyCubit', () {
    late MockSetPublicReadingStats setStats;
    late MockSessionCubit session;
    late StreamController<SessionState> sessions;

    setUp(() {
      setStats = MockSetPublicReadingStats();
      session = MockSessionCubit();
      sessions = StreamController<SessionState>.broadcast();
      whenListen(session, sessions.stream, initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    });
    tearDown(() => sessions.close());

    test('starts from MeDto.privacy and applies a change at once', () async {
      final saving = Completer<Result<void>>();
      when(() => setStats(visible: true)).thenAnswer((_) => saving.future);
      final cubit = PrivacyCubit(setStats, session);
      expect(cubit.state, const PrivacyState());

      final done = cubit.setPublicReadingStats(true);
      expect(cubit.state, const PrivacyState(publicReadingStats: true, pending: true));
      expect(await cubit.setPublicReadingStats(false), isNull); // ignored while saving
      saving.complete(const Ok(null));

      expect(await done, isNull);
      expect(cubit.state, const PrivacyState(publicReadingStats: true));
      verify(() => setStats(visible: true)).called(1);
      verifyNever(() => setStats(visible: false));
      await cubit.close();
    });

    test('rolls back when the API refuses', () async {
      when(() => setStats(visible: true)).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      final cubit = PrivacyCubit(setStats, session);

      final failure = await cubit.setPublicReadingStats(true);

      expect(failure?.code, FailureCodes.networkOffline);
      expect(cubit.state, const PrivacyState());
      await cubit.close();
    });

    test('follows the session (another device changed it)', () async {
      final cubit = PrivacyCubit(setStats, session);

      sessions.add(const SessionState(
        status: SessionStatus.authenticated,
        me: Me(id: 'u-1', displayName: 'Y', username: 'reader1', publicReadingStats: true),
      ));
      await pumpEventQueue();

      expect(cubit.state.publicReadingStats, isTrue);
      await cubit.close();
    });
  });

  group('use cases refetch GET /me after a save', () {
    late MockProfileRepository profiles;
    late MockAccountRepository accounts;

    setUp(() {
      profiles = MockProfileRepository();
      accounts = MockAccountRepository();
      when(() => accounts.getMe()).thenAnswer((_) async => const Ok(sampleMe));
    });

    test('UpdateProfile', () async {
      when(() => profiles.updateProfile(any())).thenAnswer((_) async => const Ok(null));
      expect((await UpdateProfile(profiles, accounts)(const ProfileUpdate(displayName: 'Y', username: 'reader1'))).isOk, isTrue);
      verify(() => accounts.getMe()).called(1);
    });

    test('SetPublicReadingStats, but not after a failure', () async {
      when(() => profiles.setPublicReadingStats(visible: true)).thenAnswer((_) async => const Ok(null));
      when(() => profiles.setPublicReadingStats(visible: false)).thenAnswer((_) async => const Err(Failure.unknown));
      final useCase = SetPublicReadingStats(profiles, accounts);

      await useCase(visible: true);
      await useCase(visible: false);

      verify(() => accounts.getMe()).called(1);
    });
  });
}

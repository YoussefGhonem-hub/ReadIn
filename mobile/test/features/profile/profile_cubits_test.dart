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

class MockSetPrivacy extends Mock implements SetPrivacy {}

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
    registerFallbackValue(const PrivacySettings());
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

    Future<void> submit(EditProfileCubit cubit, {String name = 'Mona Adel', String bio = '', String headline = ''}) =>
        cubit.submit(displayName: name, bio: bio, headline: headline);

    /// Adds a link of [platform] and types [url] (and [label]) into it.
    void addLink(EditProfileCubit cubit, LinkPlatform platform, String url, {String? label}) {
      cubit.addLink(platform);
      final id = cubit.state.links.last.id;
      cubit.linkUrlChanged(id, url);
      if (label != null) cubit.linkLabelChanged(id, label);
    }

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

    test('validates the name, the title and each link (the server\'s rules) before saving, errors under each field', () async {
      final cubit = await started(ownProfile);
      addLink(cubit, LinkPlatform.instagram, 'http://instagram.com/youssef'); // links[1]
      addLink(cubit, LinkPlatform.x, 'https://github.com/youssef'); // links[2]
      addLink(cubit, LinkPlatform.other, 'https://youssef.dev', label: 'x'); // links[3]
      addLink(cubit, LinkPlatform.website, ''); // links[4]
      addLink(cubit, LinkPlatform.github, 'https://user:pw@github.com/y'); // links[5]

      await submit(cubit, name: ' M ', headline: 'سطر\nتاني');

      expect(cubit.state.errors, {
        ProfileFields.displayName: FailureCodes.validationMinLength,
        ProfileFields.headline: FailureCodes.profileHeadlineInvalid,
        'links[1].url': FailureCodes.linkHttpsRequired,
        'links[2].url': FailureCodes.linkHostMismatch,
        'links[3].label': FailureCodes.linkLabelInvalid,
        'links[4].url': FailureCodes.validationRequired,
        'links[5].url': FailureCodes.linkUrlInvalid,
      });
      verifyNever(() => update(any()));

      await submit(cubit, name: '', headline: 'x' * 121);
      expect(cubit.state.errors[ProfileFields.displayName], CredentialCodes.required);
      expect(cubit.state.errors[ProfileFields.headline], FailureCodes.profileHeadlineTooLong);
      await cubit.close();
    });

    test('saves: untouched avatar, expertise and links are left out; the title is always sent', () async {
      when(() => update(any())).thenAnswer((_) async => const Ok(null));
      final cubit = await started(otherProfile);

      await submit(cubit, name: ' منى عادل ', bio: ' bio ', headline: '  Staff Engineer | .NET  ');

      final sent = verify(() => update(captureAny())).captured.single as ProfileUpdate;
      expect(
        sent,
        const ProfileUpdate(displayName: 'منى عادل', username: 'mona_dev', bio: 'bio', headline: 'Staff Engineer | .NET'),
      );
      expect(sent.links, isNull);
      expect(sent.expertiseFieldIds, isNull);
      expect(sent.avatar, const KeepAvatar(null));
      expect(cubit.state.status, FormStatus.success);
      await cubit.close();
    });

    test('links start from the profile in its order; edited, they are sent whole, in the new order', () async {
      when(() => update(any())).thenAnswer((_) async => const Ok(null));
      final cubit = await started(otherProfile);
      expect(cubit.state.links.map((l) => l.platform), [
        LinkPlatform.linkedin,
        LinkPlatform.github,
        LinkPlatform.x,
        LinkPlatform.website,
        LinkPlatform.other,
      ]);
      final ids = [for (final link in cubit.state.links) link.id];

      cubit
        ..removeLink(ids[2]) // X
        ..moveLink(ids[1], -1) // GitHub first
        ..reorderLinks(3, 0); // the Other link to the top (a drag)
      addLink(cubit, LinkPlatform.instagram, ' instagram.com/mona ');

      await submit(cubit);

      final sent = verify(() => update(captureAny())).captured.single as ProfileUpdate;
      expect(sent.links, const [
        ProfileLink(platform: LinkPlatform.other, url: 'https://mona.dev/podcast', label: 'بودكاست منى'),
        ProfileLink(platform: LinkPlatform.github, url: 'https://github.com/mona-dev'),
        ProfileLink(platform: LinkPlatform.linkedin, url: 'https://www.linkedin.com/in/mona-dev'),
        ProfileLink(platform: LinkPlatform.website, url: 'https://mona.dev/'),
        ProfileLink(platform: LinkPlatform.instagram, url: 'instagram.com/mona'),
      ]);
      await cubit.close();
    });

    test('removing every link sends [] (the server removes them all)', () async {
      when(() => update(any())).thenAnswer((_) async => const Ok(null));
      final cubit = await started(ownProfile);

      cubit.removeLink(cubit.state.links.single.id);
      await submit(cubit);

      final sent = verify(() => update(captureAny())).captured.single as ProfileUpdate;
      expect(sent.links, isEmpty);
      await cubit.close();
    });

    test('at most 8 links; one per named platform, while Other may repeat', () async {
      final cubit = await started(ownProfile); // LinkedIn already

      cubit.addLink(LinkPlatform.linkedin);
      expect(cubit.state.links, hasLength(1), reason: 'LinkedIn already has a link');
      expect(cubit.state.usedPlatforms, {LinkPlatform.linkedin});

      for (final platform in [LinkPlatform.x, LinkPlatform.other, LinkPlatform.other, LinkPlatform.github, LinkPlatform.medium]) {
        cubit.addLink(platform);
      }
      cubit
        ..addLink(LinkPlatform.other)
        ..addLink(LinkPlatform.website);
      expect(cubit.state.links, hasLength(8));
      expect(cubit.state.linksFull, isTrue);

      cubit.addLink(LinkPlatform.behance);
      expect(cubit.state.links, hasLength(8));
      expect(cubit.state.links.where((l) => l.platform == LinkPlatform.other), hasLength(3));

      // Changing a link to a platform that is taken is refused; to a free one it works and drops Other's label.
      final other = cubit.state.links.firstWhere((l) => l.platform == LinkPlatform.other);
      cubit
        ..linkLabelChanged(other.id, 'Podcast')
        ..changeLinkPlatform(other.id, LinkPlatform.x);
      expect(cubit.state.links.firstWhere((l) => l.id == other.id).platform, LinkPlatform.other);
      cubit.changeLinkPlatform(other.id, LinkPlatform.youtube);
      final changed = cubit.state.links.firstWhere((l) => l.id == other.id);
      expect((changed.platform, changed.label), (LinkPlatform.youtube, ''));
      await cubit.close();
    });

    test('a server error by index lands under that link; editing it, or moving links, clears it', () async {
      when(() => update(any())).thenAnswer((_) async => const Err(Failure(
            FailureCodes.validationFailed,
            statusCode: 400,
            fieldErrors: {
              'links[0].url': [FailureCodes.linkHostMismatch],
              'headline': [FailureCodes.profileHeadlineInvalid],
            },
          )));
      final cubit = await started(ownProfile);
      final id = cubit.state.links.single.id;
      cubit.linkUrlChanged(id, 'https://www.linkedin.com/in/youssef-h');

      await submit(cubit, headline: 'Flutter');

      expect(cubit.state.errors, {'links[0].url': FailureCodes.linkHostMismatch, ProfileFields.headline: FailureCodes.profileHeadlineInvalid});
      expect(cubit.state.failure, isNull);
      cubit.linkUrlChanged(id, 'https://www.linkedin.com/in/youssef-hassan');
      expect(cubit.state.errors.containsKey('links[0].url'), isFalse);

      await submit(cubit, headline: 'Flutter');
      expect(cubit.state.errors.containsKey('links[0].url'), isTrue);
      cubit.addLink(LinkPlatform.github);
      expect(cubit.state.errors.keys, [ProfileFields.headline]);
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
    late MockSetPrivacy setPrivacy;
    late MockSessionCubit session;
    late StreamController<SessionState> sessions;

    const following = PrivacySettings(whoCanMention: MentionPolicy.following);

    setUp(() {
      setPrivacy = MockSetPrivacy();
      session = MockSessionCubit();
      sessions = StreamController<SessionState>.broadcast();
      whenListen(session, sessions.stream, initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    });
    tearDown(() => sessions.close());

    test('starts from MeDto.privacy and applies a change at once', () async {
      final saving = Completer<Result<void>>();
      when(() => setPrivacy(const PrivacySettings(publicReadingStats: true))).thenAnswer((_) => saving.future);
      final cubit = PrivacyCubit(setPrivacy, session);
      expect(cubit.state, const PrivacyState());

      final done = cubit.setPublicReadingStats(true);
      expect(cubit.state, const PrivacyState(publicReadingStats: true, pending: true));
      expect(await cubit.setPublicReadingStats(false), isNull); // ignored while saving
      expect(await cubit.setWhoCanMention(MentionPolicy.nobody), isNull); // so is the other setting
      saving.complete(const Ok(null));

      expect(await done, isNull);
      expect(cubit.state, const PrivacyState(publicReadingStats: true));
      verify(() => setPrivacy(const PrivacySettings(publicReadingStats: true))).called(1);
      verifyNoMoreInteractions(setPrivacy);
      await cubit.close();
    });

    test('starts from whoCanMention in MeDto.privacy', () async {
      whenListen(
        session,
        sessions.stream,
        initialState: const SessionState(
          status: SessionStatus.authenticated,
          me: Me(id: 'u-1', displayName: 'Y', username: 'reader1', publicReadingStats: true, whoCanMention: MentionPolicy.nobody),
        ),
      );
      final cubit = PrivacyCubit(setPrivacy, session);

      expect(cubit.state, const PrivacyState(publicReadingStats: true, whoCanMention: MentionPolicy.nobody));
      await cubit.close();
    });

    test('who can mention me: applied at once, saved with the rest of the privacy object', () async {
      final saving = Completer<Result<void>>();
      when(() => setPrivacy(any())).thenAnswer((_) => saving.future);
      final cubit = PrivacyCubit(setPrivacy, session);

      final done = cubit.setWhoCanMention(MentionPolicy.following);
      expect(cubit.state, const PrivacyState(whoCanMention: MentionPolicy.following, pending: true));
      expect(await cubit.setWhoCanMention(MentionPolicy.nobody), isNull, reason: 'ignored while saving');
      saving.complete(const Ok(null));

      expect(await done, isNull);
      expect(cubit.state, const PrivacyState(whoCanMention: MentionPolicy.following));
      verify(() => setPrivacy(following)).called(1);
      verifyNoMoreInteractions(setPrivacy);

      expect(await cubit.setWhoCanMention(MentionPolicy.following), isNull, reason: 'nothing to do');
      verifyNoMoreInteractions(setPrivacy);

      // The reading stats switch keeps the mention setting it doesn't show.
      when(() => setPrivacy(any())).thenAnswer((_) async => const Ok(null));
      await cubit.setPublicReadingStats(true);
      verify(() => setPrivacy(const PrivacySettings(publicReadingStats: true, whoCanMention: MentionPolicy.following))).called(1);
      await cubit.close();
    });

    test('rolls back when the API refuses', () async {
      when(() => setPrivacy(any())).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      final cubit = PrivacyCubit(setPrivacy, session);

      final failure = await cubit.setPublicReadingStats(true);

      expect(failure?.code, FailureCodes.networkOffline);
      expect(cubit.state, const PrivacyState());
      await cubit.close();
    });

    test('who can mention me rolls back when the API refuses, and returns the failure to show', () async {
      final saving = Completer<Result<void>>();
      when(() => setPrivacy(any())).thenAnswer((_) => saving.future);
      final cubit = PrivacyCubit(setPrivacy, session);
      final states = <PrivacyState>[];
      final sub = cubit.stream.listen(states.add);

      final done = cubit.setWhoCanMention(MentionPolicy.nobody);
      saving.complete(const Err(Failure(FailureCodes.validationFailed)));
      final failure = await done;
      await pumpEventQueue();

      expect(failure?.code, FailureCodes.validationFailed);
      expect(states, const [
        PrivacyState(whoCanMention: MentionPolicy.nobody, pending: true),
        PrivacyState(),
      ]);
      expect(cubit.state.pending, isFalse, reason: 'the choice can be tried again');
      await sub.cancel();
      await cubit.close();
    });

    test('follows the session (another device changed it)', () async {
      final cubit = PrivacyCubit(setPrivacy, session);

      sessions.add(const SessionState(
        status: SessionStatus.authenticated,
        me: Me(id: 'u-1', displayName: 'Y', username: 'reader1', publicReadingStats: true, whoCanMention: MentionPolicy.following),
      ));
      await pumpEventQueue();

      expect(cubit.state, const PrivacyState(publicReadingStats: true, whoCanMention: MentionPolicy.following));
      await cubit.close();
    });

    test('a session update while saving does not undo the change on screen', () async {
      final saving = Completer<Result<void>>();
      when(() => setPrivacy(any())).thenAnswer((_) => saving.future);
      final cubit = PrivacyCubit(setPrivacy, session);

      final done = cubit.setWhoCanMention(MentionPolicy.nobody);
      sessions.add(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      await pumpEventQueue();
      expect(cubit.state, const PrivacyState(whoCanMention: MentionPolicy.nobody, pending: true));

      saving.complete(const Ok(null));
      await done;
      expect(cubit.state, const PrivacyState(whoCanMention: MentionPolicy.nobody));
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

    test('SetPrivacy sends the whole object, and does not refetch after a failure', () async {
      const saved = PrivacySettings(publicReadingStats: true, whoCanMention: MentionPolicy.following);
      const refused = PrivacySettings(whoCanMention: MentionPolicy.nobody);
      when(() => profiles.setPrivacy(saved)).thenAnswer((_) async => const Ok(null));
      when(() => profiles.setPrivacy(refused)).thenAnswer((_) async => const Err(Failure.unknown));
      final useCase = SetPrivacy(profiles, accounts);

      expect((await useCase(saved)).isOk, isTrue);
      expect((await useCase(refused)).failureOrNull, Failure.unknown);

      verify(() => profiles.setPrivacy(saved)).called(1);
      verify(() => profiles.setPrivacy(refused)).called(1);
      verify(() => accounts.getMe()).called(1);
    });
  });
}

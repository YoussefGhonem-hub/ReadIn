import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/auth/data/models/auth_models.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/profile/data/datasources/profile_api.dart';
import 'package:readin/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:readin/features/profile/domain/entities/profile.dart';
import 'package:readin/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:readin/features/reading/data/datasources/reading_api.dart';
import 'package:readin/features/reading/data/repositories/reading_repository_impl.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/profile_fixtures.dart';
import '../../helpers/social_fakes.dart';

/// Every F14 endpoint against the contract (docs/api/contract-v1.md "Profile (F14)"): method, path, query, body, and
/// how the answer parses.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late Dio dio;

  setUp(() {
    requests = [];
    respond = (_) => null;
    dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = ScriptedAdapter((options) {
        requests.add(options);
        final body = respond(options);
        if (body is (int, Object?)) return body;
        return (200, body);
      });
  });

  String call(int i) => '${requests[i].method} ${requests[i].uri.path.replaceFirst('/api/v1', '')}';

  ProfileRepositoryImpl repository() => ProfileRepositoryImpl(ProfileApi(dio));

  group('GET /users/{username}', () {
    test('parses ProfileDto; the handle is sent bare and lower-case', () async {
      respond = (_) => profileJson();

      final profile = (await repository().getProfile('@Mona')).valueOrNull!;

      expect(call(0), 'GET /users/mona');
      expect(profile.id, 'u-mona');
      expect(profile.displayName, 'Mona Adel');
      expect(profile.username, 'mona');
      expect(profile.isVerified, isTrue);
      expect(profile.bio, 'Backend engineer · .NET و SQL Server');
      expect(profile.links, const ProfileLinks(github: 'https://github.com/mona'));
      expect(profile.expertise.map((f) => f.slug), ['dotnet', 'databases']);
      expect(profile.expertise.first, const ExpertiseField(id: 'f-dotnet', slug: 'dotnet', name: '.NET', icon: 'code-xml', color: 'callout-info-accent'));
      expect(profile.joinedAt, DateTime.utc(2026, 1, 10, 9));
      expect(profile.stats, const ProfileStats(articles: 12, followers: 340, following: 21, totalReads: 5120));
      expect((profile.isMe, profile.isFollowing, profile.followsYou, profile.readingStatsVisible), (false, false, true, false));
      // Every variant key, the 512 one repeating the 256 one for a small upload.
      expect(profile.avatarVariants.keys, unorderedEquals([64, 128, 256, 512]));
      expect(profile.avatarUrl, 'https://api.test/uploads/avatars/mona_256.webp');
      expect(profile.avatarFor(160), 'https://api.test/uploads/avatars/mona_256.webp');
      expect(profile.avatarFor(64), 'https://api.test/uploads/avatars/mona_64.webp');
    });

    test('no avatar: null url and variants; an empty bio is no bio', () async {
      respond = (_) => {...profileJson(withAvatar: false), 'bio': '  '};

      final profile = (await repository().getProfile('mona')).valueOrNull!;

      expect(profile.avatarUrl, isNull);
      expect(profile.avatarVariants, isEmpty);
      expect(profile.avatarFor(160), isNull);
      expect(profile.bio, isNull);
    });

    test('404 user.not_found', () async {
      respond = (_) => (404, {'status': 404, 'code': 'user.not_found', 'title': 'Not found'});

      final failure = (await repository().getProfile('ghost')).failureOrNull!;

      expect(failure.code, FailureCodes.userNotFound);
      expect(failure.statusCode, 404);
    });
  });

  test('GET /users/{username}/articles pages with cursor and limit', () async {
    respond = (_) => {
          'items': [detailsJson(1)],
          'nextCursor': 'c2',
        };

    final page = (await repository().getArticles('Mona', cursor: 'c1')).valueOrNull!;

    expect(call(0), 'GET /users/mona/articles');
    expect(requests[0].queryParameters, {'cursor': 'c1', 'limit': 20});
    expect(page.items.single.id, 'art-1');
    expect(page.items.single.saveCount, 7);
    expect(page.nextCursor, 'c2');
  });

  group('PATCH /me', () {
    const base = ProfileUpdate(
      displayName: 'Mona Adel',
      username: 'mona',
      bio: '  Backend engineer  ',
      links: ProfileLinks(github: 'https://github.com/mona', website: ' '),
    );

    Future<Map<String, dynamic>> bodyOf(ProfileUpdate update) async {
      respond = (_) => (204, null);
      final result = await repository().updateProfile(update);
      expect(result.isOk, isTrue);
      expect(call(requests.length - 1), 'PATCH /me');
      return requests.last.data as Map<String, dynamic>;
    }

    test('an untouched avatar and expertise leave their keys out; links are sent with nulls', () async {
      final body = await bodyOf(base);

      expect(body, {
        'displayName': 'Mona Adel',
        'username': 'mona',
        'bio': 'Backend engineer',
        'links': {'github': 'https://github.com/mona', 'linkedin': null, 'website': null},
      });
      expect(body.containsKey('avatarAssetId'), isFalse);
      expect(body.containsKey('avatarUrl'), isFalse);
      expect(body.containsKey('expertiseFieldIds'), isFalse);
    });

    test('a new avatar sends its asset id; removing sends null', () async {
      final set = await bodyOf(const ProfileUpdate(displayName: 'M', username: 'mona', avatar: NewAvatar('asset-1')));
      final removed = await bodyOf(const ProfileUpdate(displayName: 'M', username: 'mona', avatar: RemoveAvatar()));

      expect(set['avatarAssetId'], 'asset-1');
      expect(removed.containsKey('avatarAssetId'), isTrue);
      expect(removed['avatarAssetId'], isNull);
      expect(removed.containsKey('avatarUrl'), isFalse);
    });

    test('expertise ids in order; [] clears them; an empty bio is null', () async {
      final picked = await bodyOf(const ProfileUpdate(displayName: 'M', username: 'mona', expertiseFieldIds: ['f-2', 'f-1']));
      final cleared = await bodyOf(const ProfileUpdate(displayName: 'M', username: 'mona', bio: '', expertiseFieldIds: []));

      expect(picked['expertiseFieldIds'], ['f-2', 'f-1']);
      expect(cleared['expertiseFieldIds'], isEmpty);
      expect(cleared['bio'], isNull);
    });

    test('409 user.username_taken goes to the username field', () async {
      respond = (_) => (409, {'status': 409, 'code': 'user.username_taken', 'title': 'Taken'});
      final failure = (await repository().updateProfile(base)).failureOrNull!;

      expect(failure.code, FailureCodes.usernameTaken);
      expect(EditProfileCubit.formErrorsOf(failure).fields, {ProfileFields.username: FailureCodes.usernameTaken});
    });

    test('400 profile.avatar_invalid and profile.expertise_invalid name their field in errors', () async {
      respond = (_) => (400, {
            'status': 400,
            'code': 'profile.avatar_invalid',
            'errors': {'avatarAssetId': ['profile.avatar_invalid']},
          });
      final avatar = (await repository().updateProfile(base)).failureOrNull!;
      respond = (_) => (400, {
            'status': 400,
            'code': 'profile.expertise_invalid',
            'errors': {'expertiseFieldIds': ['profile.expertise_invalid']},
          });
      final expertise = (await repository().updateProfile(base)).failureOrNull!;

      expect(avatar.fieldErrors['avatarAssetId'], [FailureCodes.profileAvatarInvalid]);
      expect(EditProfileCubit.formErrorsOf(avatar).fields, {ProfileFields.avatar: FailureCodes.profileAvatarInvalid});
      expect(EditProfileCubit.formErrorsOf(expertise).fields, {ProfileFields.expertise: FailureCodes.profileExpertiseInvalid});
    });

    test('validation errors keyed by camelCase properties land on their inputs', () async {
      respond = (_) => (400, {
            'status': 400,
            'code': 'validation.failed',
            'errors': {
              'displayName': ['validation.length'],
              'bio': ['validation.max_length'],
              'links.gitHub': ['validation.url'],
              'links.linkedIn': ['validation.url'],
              'links.website': ['validation.url'],
            },
          });
      final failure = (await repository().updateProfile(base)).failureOrNull!;
      final split = EditProfileCubit.formErrorsOf(failure);

      expect(split.fields, {
        ProfileFields.displayName: 'validation.length',
        ProfileFields.bio: FailureCodes.validationMaxLength,
        ProfileFields.github: FailureCodes.validationUrl,
        ProfileFields.linkedin: FailureCodes.validationUrl,
        ProfileFields.website: FailureCodes.validationUrl,
      });
      expect(split.general, isNull);
    });

    test('a validation error for no input on the form is shown for the whole form', () async {
      respond = (_) => (400, {'status': 400, 'code': 'validation.failed', 'errors': {'timeZone': ['validation.invalid']}});
      final failure = (await repository().updateProfile(base)).failureOrNull!;

      expect(EditProfileCubit.formErrorsOf(failure).general, failure);
    });
  });

  test('PUT /me/privacy always sends the whole privacy object', () async {
    respond = (_) => (204, null);

    final ok = await repository().setPrivacy(const PrivacySettings(publicReadingStats: true));
    await repository().setPrivacy(const PrivacySettings(whoCanMention: MentionPolicy.following));
    await repository().setPrivacy(const PrivacySettings(publicReadingStats: true, whoCanMention: MentionPolicy.nobody));

    expect(ok.isOk, isTrue);
    expect(call(0), 'PUT /me/privacy');
    expect(requests[0].data, {'publicReadingStats': true, 'whoCanMention': 'everyone'});
    expect(requests[1].data, {'publicReadingStats': false, 'whoCanMention': 'following'});
    expect(requests[2].data, {'publicReadingStats': true, 'whoCanMention': 'nobody'});
  });

  test('PUT /me/privacy: a refusal is the API failure', () async {
    respond = (_) => (400, {'status': 400, 'code': 'validation.failed', 'errors': {'whoCanMention': ['validation.invalid']}});

    final failure = (await repository().setPrivacy(const PrivacySettings(whoCanMention: MentionPolicy.nobody))).failureOrNull;

    expect(failure?.code, 'validation.failed');
  });

  test('GET /me carries privacy.publicReadingStats (default false)', () {
    final base = meModel().toJson();
    expect(MeModel.fromJson(base).toEntity().publicReadingStats, isFalse);
    expect(MeModel.fromJson({...base, 'privacy': {'publicReadingStats': true}}).toEntity().publicReadingStats, isTrue);
  });

  test('GET /me carries privacy.whoCanMention (left out, null or unknown = everyone)', () {
    final base = meModel().toJson()..remove('privacy');
    MentionPolicy policyOf(Object? privacy) =>
        MeModel.fromJson({...base, 'privacy': ?privacy}).toEntity().whoCanMention;

    expect(policyOf(null), MentionPolicy.everyone, reason: 'no privacy object at all');
    expect(policyOf({'publicReadingStats': true}), MentionPolicy.everyone, reason: 'an API from before the setting');
    expect(policyOf({'publicReadingStats': false, 'whoCanMention': null}), MentionPolicy.everyone);
    expect(policyOf({'publicReadingStats': false, 'whoCanMention': 'everyone'}), MentionPolicy.everyone);
    expect(policyOf({'publicReadingStats': false, 'whoCanMention': 'following'}), MentionPolicy.following);
    expect(policyOf({'publicReadingStats': false, 'whoCanMention': 'nobody'}), MentionPolicy.nobody);
    expect(policyOf({'publicReadingStats': false, 'whoCanMention': 'verifiedOnly'}), MentionPolicy.everyone, reason: 'a newer value');

    final me = MeModel.fromJson({...base, 'privacy': {'publicReadingStats': true, 'whoCanMention': 'following'}}).toEntity();
    expect(me.privacy, const PrivacySettings(publicReadingStats: true, whoCanMention: MentionPolicy.following));
  });

  group('public reading stats', () {
    final stats = {
      'streak': {'current': 4, 'longest': 9, 'readToday': true, 'freezeAvailable': true, 'freezePending': false, 'today': '2026-11-03'},
      'totalArticles': 40,
      'minutesRead': 300,
      'articlesThisWeek': 3,
      'minutesThisWeek': 20,
      'articlesThisMonth': 11,
      'topFields': <Object>[],
    };

    test('GET /users/{username}/stats and /stats/heatmap; /me/stats without a username', () async {
      respond = (options) => options.path.endsWith('heatmap') ? {'from': '2025-11-04', 'to': '2026-11-03', 'days': <Object>[]} : stats;
      final reading = ReadingRepositoryImpl(ReadingApi(dio));

      final theirs = (await reading.getStats(username: 'mona')).valueOrNull!;
      await reading.getHeatmap(username: 'mona');
      await reading.getStats();
      await reading.getHeatmap();

      expect([for (var i = 0; i < requests.length; i++) call(i)], [
        'GET /users/mona/stats',
        'GET /users/mona/stats/heatmap',
        'GET /me/stats',
        'GET /me/stats/heatmap',
      ]);
      expect(requests[1].queryParameters, {'days': 365});
      expect(theirs.totalArticles, 40);
      expect(theirs.streak.current, 4);
    });

    test('403 profile.stats_private', () async {
      respond = (_) => (403, {'status': 403, 'code': 'profile.stats_private', 'title': 'Private'});
      final failure = (await ReadingRepositoryImpl(ReadingApi(dio)).getStats(username: 'omar')).failureOrNull!;
      expect(failure.code, FailureCodes.profileStatsPrivate);
    });
  });
}

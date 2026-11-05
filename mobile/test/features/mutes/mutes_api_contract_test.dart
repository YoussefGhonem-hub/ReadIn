import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/failure_messages.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/comments/data/models/comment_models.dart';
import 'package:readin/features/mutes/data/datasources/mutes_api.dart';
import 'package:readin/features/mutes/data/repositories/mutes_repository_impl.dart';
import 'package:readin/features/mutes/domain/entities/mutes.dart';
import 'package:readin/features/profile/data/models/profile_models.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/social_fakes.dart';

/// Every F28 endpoint against docs/api/contract-v1.md "Mute & feedback (F28)": method, path, query, and how the answer
/// parses; the new viewer flags on cards, details, comments and profiles; and the error codes.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late MutesRepositoryImpl repository;

  setUp(() {
    requests = [];
    respond = (_) => null;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = ScriptedAdapter((options) {
        requests.add(options);
        final body = respond(options);
        if (body is (int, Object?)) return body;
        return (200, body);
      });
    repository = MutesRepositoryImpl(MutesApi(dio));
  });

  String call(int i) => '${requests[i].method} ${requests[i].uri.path.replaceFirst('/api/v1', '')}';

  test('PUT and DELETE /users/{id}/mute; restoreFollow only when it is true', () async {
    respond = (options) => {
          'isMuted': options.method == 'PUT',
          'isFollowing': options.uri.queryParameters['restoreFollow'] == 'true',
          'followerCount': 41,
          'followRemoved': options.method == 'PUT',
        };

    final muted = (await repository.muteUser('u-9')).valueOrNull!;
    await repository.unmuteUser('u-9');
    final restored = (await repository.unmuteUser('u-9', restoreFollow: true)).valueOrNull!;

    expect(call(0), 'PUT /users/u-9/mute');
    expect(call(1), 'DELETE /users/u-9/mute');
    expect(requests[1].uri.queryParameters, isEmpty);
    expect(call(2), 'DELETE /users/u-9/mute');
    expect(requests[2].uri.queryParameters, {'restoreFollow': 'true'});
    expect(muted, const UserMuteState(isMuted: true, isFollowing: false, followerCount: 41, followRemoved: true));
    expect(restored.isFollowing, isTrue);
  });

  test('PUT and DELETE /me/mutes/fields|topics/{id} answer every muted id', () async {
    respond = (_) => {'fieldIds': ['f-ai'], 'topicIds': ['t-di']};

    final field = (await repository.setFieldMuted('f-ai', muted: true)).valueOrNull!;
    await repository.setFieldMuted('f-ai', muted: false);
    await repository.setTopicMuted('t-di', muted: true);
    await repository.setTopicMuted('t-di', muted: false);

    expect([for (var i = 0; i < 4; i++) call(i)], [
      'PUT /me/mutes/fields/f-ai',
      'DELETE /me/mutes/fields/f-ai',
      'PUT /me/mutes/topics/t-di',
      'DELETE /me/mutes/topics/t-di',
    ]);
    expect(field, const ContentMutes(fieldIds: ['f-ai'], topicIds: ['t-di']));
  });

  test('GET /me/mutes: writers, fields and topics', () async {
    respond = (_) => {
          'users': [
            {
              'id': 'u-9',
              'displayName': 'Omar Khaled',
              'username': 'omar_dev',
              'avatarUrl': null,
              'isVerified': true,
              'bio': null,
              'isFollowing': false,
              'followsYou': true,
            },
          ],
          'fields': [
            {'id': 'f-ai', 'slug': 'ai', 'name': 'AI', 'nameAr': 'الذكاء الاصطناعي', 'nameEn': 'AI', 'icon': 'sparkles', 'color': 'primary'},
          ],
          'topics': [
            {
              'id': 't-orm',
              'slug': 'ef-core',
              'name': 'EF Core',
              'nameAr': 'EF Core',
              'nameEn': 'EF Core',
              'field': {'id': 'f-backend', 'slug': 'backend', 'name': 'Backend', 'nameAr': 'Backend', 'nameEn': 'Backend', 'icon': 'cog', 'color': 'accent'},
            },
          ],
        };

    final mutes = (await repository.getMutes()).valueOrNull!;

    expect(call(0), 'GET /me/mutes');
    expect(mutes.users.single.username, 'omar_dev');
    expect(mutes.users.single.followsYou, isTrue);
    expect(mutes.fields.single, const MutedField(id: 'f-ai', slug: 'ai', nameAr: 'الذكاء الاصطناعي', nameEn: 'AI', icon: 'sparkles'));
    expect(mutes.topics.single.field.color, 'accent');
    expect(mutes.topics.single.nameFor('ar'), 'EF Core');
  });

  test('PUT and DELETE /articles/{id}/show-less → 204', () async {
    respond = (_) => (204, null);

    expect((await repository.setShowLess('art-1', showLess: true)).isOk, isTrue);
    expect((await repository.setShowLess('art-1', showLess: false)).isOk, isTrue);

    expect(call(0), 'PUT /articles/art-1/show-less');
    expect(call(1), 'DELETE /articles/art-1/show-less');
  });

  test('400 mute.* and 404 come back as their codes', () async {
    respond = (_) => (400, {'status': 400, 'code': 'mute.system_account', 'title': 'x'});
    expect((await repository.muteUser('u-readin')).failureOrNull?.code, FailureCodes.muteSystemAccount);

    respond = (_) => (400, {'status': 400, 'code': 'mute.own_article', 'title': 'x'});
    expect((await repository.setShowLess('art-1', showLess: true)).failureOrNull?.code, FailureCodes.muteOwnArticle);

    respond = (_) => (404, {'status': 404, 'code': 'topic.not_found', 'title': 'x'});
    expect((await repository.setTopicMuted('t-x', muted: true)).failureOrNull?.code, FailureCodes.topicNotFound);
  });

  test('the mute codes read the same as the API says them', () async {
    final ar = await AppLocalizations.delegate.load(AppLocales.ar);
    final en = await AppLocalizations.delegate.load(AppLocales.en);
    const expected = {
      FailureCodes.muteSelf: ('مينفعش تكتم نفسك.', "You can't mute yourself."),
      FailureCodes.muteSystemAccount: ('مينفعش تكتم حساب ReadIn الرسمي.', "The official ReadIn account can't be muted."),
      FailureCodes.muteLimit: ('وصلت لأقصى عدد كتّاب تكتمهم (500).', 'You can mute at most 500 writers.'),
      FailureCodes.muteOwnArticle: ('مينفعش تعمل كده على مقالك.', "You can't do this on your own article."),
    };
    for (final MapEntry(key: code, value: (arabic, english)) in expected.entries) {
      expect(localizeErrorCode(ar, code), arabic, reason: code);
      expect(localizeErrorCode(en, code), english, reason: code);
    }
  });

  group('viewer flags on other DTOs', () {
    test('cards carry their topic and the mutes; an API without them still parses', () {
      final json = {
        ...detailsJson(1),
        'topic': {'id': 't-di', 'slug': 'di', 'nameAr': 'Dependency Injection', 'nameEn': 'Dependency Injection'},
        'isAuthorMuted': true,
        'isFieldMuted': false,
        'isTopicMuted': true,
      };

      final card = ArticleCardModel.fromJson(json).toEntity();
      expect(card.topic?.id, 't-di');
      expect((card.isAuthorMuted, card.isFieldMuted, card.isTopicMuted), (true, false, true));

      final details = ArticleDetailsModel.fromJson(json).toEntity();
      expect(details.card.topic?.id, 't-di', reason: "the reader's menu opens the same sheet");
      expect(details.card.isAuthorMuted, isTrue, reason: "the reader's banner");
      expect(details.card.isTopicMuted, isTrue);

      final old = ArticleCardModel.fromJson(detailsJson(2)).toEntity();
      expect((old.topic, old.isAuthorMuted, old.isFieldMuted, old.isTopicMuted), (null, false, false, false));
    });

    test('CommentDto.isAuthorMuted and ProfileDto.isMuted', () {
      final comment = CommentModel.fromJson({
        'id': 'c-1',
        'articleId': 'art-1',
        'body': 'hi',
        'author': {'id': 'u-9', 'displayName': 'Omar', 'username': 'omar_dev'},
        'createdAt': '2026-11-02T08:00:00Z',
        'isAuthorMuted': true,
        'replies': [
          {'id': 'c-2', 'articleId': 'art-1', 'parentId': 'c-1', 'body': 'reply', 'createdAt': '2026-11-02T09:00:00Z'},
        ],
      }).toEntity();
      expect(comment.isAuthorMuted, isTrue);
      expect(comment.replies.single.isAuthorMuted, isFalse);

      final profile = ProfileModel.fromJson({'id': 'u-9', 'displayName': 'Omar', 'username': 'omar_dev', 'isMuted': true}).toEntity();
      expect(profile.isMuted, isTrue);
      expect(ProfileModel.fromJson({'id': 'u-9', 'displayName': 'Omar', 'username': 'omar_dev'}).toEntity().isMuted, isFalse);
    });

    test('ProfileDto.isSystemAccount (the official @readin account), false when missing', () {
      final readin =
          ProfileModel.fromJson({'id': 'u-readin', 'displayName': 'ReadIn', 'username': 'readin', 'isSystemAccount': true}).toEntity();
      expect(readin.isSystemAccount, isTrue);
      expect(ProfileModel.fromJson({'id': 'u-9', 'displayName': 'Omar', 'username': 'omar_dev'}).toEntity().isSystemAccount, isFalse);
    });
  });
}

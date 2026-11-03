import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/comments/data/datasources/comments_api.dart';
import 'package:readin/features/comments/data/models/comment_models.dart';
import 'package:readin/features/comments/data/repositories/comments_repository_impl.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';

import '../../helpers/fake_auth.dart';

class MockCommentsApi extends Mock implements CommentsApi {}

/// `CommentDto` JSON the way the API sends it.
Map<String, dynamic> commentJson(String id, {String? parentId, Object? body = 'شكراً @mona_dev', bool withAuthor = true, List<Object> replies = const []}) => {
      'id': id,
      'articleId': 'a-1',
      'parentId': parentId,
      'body': body,
      'author': withAuthor ? {'id': 'u-2', 'displayName': 'Omar', 'username': 'omar_k', 'avatarUrl': null, 'isVerified': true} : null,
      'isArticleAuthor': true,
      'mentions': [
        {'userId': 'u-3', 'username': 'mona_dev'},
      ],
      'likeCount': 3,
      'likedByMe': true,
      'replyCount': replies.length,
      'isPinned': true,
      'createdAt': '2026-11-02T08:00:00Z',
      'editedAt': '2026-11-02T09:00:00Z',
      'isDeleted': false,
      'isHidden': false,
      'canEdit': true,
      'canDelete': true,
      'canPin': false,
      'canReport': false,
      'canModerate': false,
      if (replies.isNotEmpty) 'replies': replies,
    };

void main() {
  group('repository (mocked API)', () {
    late MockCommentsApi api;
    late CommentsRepositoryImpl repository;

    setUpAll(() {
      registerFallbackValue(const CommentBodyRequest(body: ''));
      registerFallbackValue(const ReportRequest(targetType: '', targetId: '', reason: ''));
      registerFallbackValue(const ModerationActionRequest(action: '', targetType: '', targetId: ''));
    });

    setUp(() {
      api = MockCommentsApi();
      repository = CommentsRepositoryImpl(api);
    });

    test('a page maps every field, its first replies and the total; the sort goes on the wire', () async {
      when(() => api.getComments('a-1', 'new', 'p1', 20)).thenAnswer(
        (_) async => CommentPageModel.fromJson({
          'items': [
            commentJson('c1', replies: [commentJson('r1', parentId: 'c1')]),
          ],
          'nextCursor': 'p2',
          'total': 9,
        }),
      );

      final page = (await repository.getComments('a-1', sort: CommentSort.newest, cursor: 'p1')).valueOrNull!;

      final c1 = page.items.single;
      expect(page.total, 9);
      expect(page.nextCursor, 'p2');
      expect(c1.author, const Author(id: 'u-2', displayName: 'Omar', username: 'omar_k', isVerified: true));
      expect(c1.mentions, const [CommentMention(userId: 'u-3', username: 'mona_dev')]);
      expect(c1.createdAt, DateTime.utc(2026, 11, 2, 8));
      expect(c1.editedAt, DateTime.utc(2026, 11, 2, 9));
      expect([c1.isArticleAuthor, c1.likedByMe, c1.isPinned, c1.canEdit, c1.canDelete], everyElement(isTrue));
      expect(c1.replies.single.parentId, 'c1');
      expect(c1.replyCount, 1);
    });

    test('placeholders and deleted accounts: null body or author', () async {
      when(() => api.getComment('c1')).thenAnswer((_) async => CommentModel.fromJson({
            ...commentJson('c1', body: null, withAuthor: false),
            'isDeleted': true,
            'mentions': <Object>[],
          }));
      when(() => api.getComment('c2')).thenAnswer((_) async => CommentModel.fromJson(commentJson('c2', withAuthor: false)));

      final deleted = (await repository.getComment('c1')).valueOrNull!;
      final orphan = (await repository.getComment('c2')).valueOrNull!;

      expect(deleted.isPlaceholder, isTrue);
      expect(deleted.isDeleted, isTrue);
      expect(orphan.author, isNull);
      expect(orphan.body, isNotNull);
    });

    test('posting a comment, a reply and an edit send the body', () async {
      final answer = CommentModel.fromJson(commentJson('c9'));
      when(() => api.postComment('a-1', const CommentBodyRequest(body: 'سلام'))).thenAnswer((_) async => answer);
      when(() => api.postReply('r1', const CommentBodyRequest(body: 'رد'))).thenAnswer((_) async => answer);
      when(() => api.editComment('c9', const CommentBodyRequest(body: 'تعديل'))).thenAnswer((_) async => answer);

      expect((await repository.postComment('a-1', 'سلام')).valueOrNull?.id, 'c9');
      expect((await repository.postReply('r1', 'رد')).isOk, isTrue);
      expect((await repository.editComment('c9', 'تعديل')).isOk, isTrue);
    });

    test('like / unlike and pin / unpin pick PUT or DELETE', () async {
      when(() => api.like('c1')).thenAnswer((_) async => const CommentLikeModel(likeCount: 4, liked: true));
      when(() => api.unlike('c1')).thenAnswer((_) async => const CommentLikeModel(likeCount: 3, liked: false));
      when(() => api.pin('c1')).thenAnswer((_) async => CommentModel.fromJson(commentJson('c1')));
      when(() => api.unpin('c1')).thenAnswer((_) async => CommentModel.fromJson({...commentJson('c1'), 'isPinned': false}));

      expect((await repository.setLiked('c1', liked: true)).valueOrNull, const CommentLike(likeCount: 4, liked: true));
      expect((await repository.setLiked('c1', liked: false)).valueOrNull, const CommentLike(likeCount: 3, liked: false));
      expect((await repository.setPinned('c1', pinned: true)).valueOrNull?.isPinned, isTrue);
      expect((await repository.setPinned('c1', pinned: false)).valueOrNull?.isPinned, isFalse);
    });

    test('reports and moderator actions target comments', () async {
      when(() => api.report(any())).thenAnswer((_) async {});
      when(() => api.moderate(any())).thenAnswer((_) async {});

      await repository.reportComment('c1', ReportReason.misinformation, details: 'مصدر غلط');
      await repository.moderateComment('c1', ModerationAction.unhide);

      verify(() => api.report(const ReportRequest(targetType: 'comment', targetId: 'c1', reason: 'misinformation', details: 'مصدر غلط')))
          .called(1);
      verify(() => api.moderate(const ModerationActionRequest(action: 'unhide', targetType: 'comment', targetId: 'c1'))).called(1);
    });

    test('mention suggestions become authors', () async {
      when(() => api.mentionSuggestions('mo', 8)).thenAnswer(
        (_) async => [const MentionCandidateModel(id: 'u-3', displayName: 'منى', username: 'mona_dev', isVerified: true)],
      );

      final users = (await repository.mentionSuggestions('mo')).valueOrNull!;

      expect(users, const [Author(id: 'u-3', displayName: 'منى', username: 'mona_dev', isVerified: true)]);
    });

    DioException problem(int status, String code) {
      final options = RequestOptions(path: '/x');
      return DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: status, data: {'status': status, 'code': code}),
      );
    }

    test('API errors become failures with their codes', () async {
      when(() => api.postComment(any(), any())).thenThrow(problem(409, 'comment.duplicate'));
      when(() => api.postReply(any(), any())).thenThrow(problem(429, 'comment.article_limit'));
      when(() => api.deleteComment(any())).thenThrow(problem(403, 'comment.not_owner'));
      when(() => api.report(any())).thenThrow(problem(400, 'report.own_content'));

      expect((await repository.postComment('a-1', 'x')).failureOrNull, const Failure(FailureCodes.commentDuplicate, statusCode: 409));
      expect((await repository.postReply('c1', 'x')).failureOrNull?.code, FailureCodes.commentArticleLimit);
      expect((await repository.deleteComment('c1')).failureOrNull?.code, FailureCodes.commentNotOwner);
      expect((await repository.reportComment('c1', ReportReason.spam)).failureOrNull?.code, FailureCodes.reportOwnContent);
    });
  });

  group('API contract (method, path, query, body)', () {
    late List<RequestOptions> requests;
    late Object? Function(RequestOptions) respond;
    late CommentsRepositoryImpl repository;

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
      repository = CommentsRepositoryImpl(CommentsApi(dio));
    });

    String call(int i) => '${requests[i].method} ${requests[i].uri.path.replaceFirst('/api/v1', '')}';

    test('reads', () async {
      respond = (options) => switch (options.uri.path) {
            final p when p.endsWith('/comments') => {'items': <Object>[], 'nextCursor': null, 'total': 0},
            final p when p.endsWith('/replies') => {'items': <Object>[], 'nextCursor': null},
            final p when p.endsWith('/mention-suggestions') => <Object>[],
            _ => commentJson('c1'),
          };

      await repository.getComments('a-1');
      await repository.getReplies('c1', cursor: 'r2', limit: 50);
      await repository.getComment('c1');
      await repository.mentionSuggestions('@mo');

      expect(call(0), 'GET /articles/a-1/comments');
      expect(requests[0].queryParameters, {'sort': 'top', 'limit': 20});
      expect(call(1), 'GET /comments/c1/replies');
      expect(requests[1].queryParameters, {'cursor': 'r2', 'limit': 50});
      expect(call(2), 'GET /comments/c1');
      expect(call(3), 'GET /users/mention-suggestions');
      expect(requests[3].queryParameters, {'q': '@mo', 'limit': 8});
    });

    test('writes', () async {
      respond = (options) => switch ((options.method, options.uri.path)) {
            (_, final p) when p.endsWith('/like') => {'likeCount': 1, 'liked': true},
            ('DELETE', final p) when p.endsWith('/c1') => (204, null),
            (_, final p) when p.endsWith('/reports') || p.endsWith('/moderation/actions') => (204, null),
            _ => commentJson('c1'),
          };

      await repository.postComment('a-1', 'سلام');
      await repository.postReply('r1', 'رد');
      await repository.editComment('c1', 'تعديل');
      await repository.deleteComment('c1');
      await repository.setLiked('c1', liked: true);
      await repository.setLiked('c1', liked: false);
      await repository.setPinned('c1', pinned: true);
      await repository.setPinned('c1', pinned: false);
      final reported = await repository.reportComment('c1', ReportReason.spam);
      final moderated = await repository.moderateComment('c1', ModerationAction.hide);

      expect([for (var i = 0; i < requests.length; i++) call(i)], [
        'POST /articles/a-1/comments',
        'POST /comments/r1/replies',
        'PATCH /comments/c1',
        'DELETE /comments/c1',
        'PUT /comments/c1/like',
        'DELETE /comments/c1/like',
        'POST /comments/c1/pin',
        'DELETE /comments/c1/pin',
        'POST /reports',
        'POST /moderation/actions',
      ]);
      expect(requests[0].data, {'body': 'سلام'});
      expect(requests[2].data, {'body': 'تعديل'});
      expect(requests[8].data, {'targetType': 'comment', 'targetId': 'c1', 'reason': 'spam'}, reason: 'no details: left out');
      expect(requests[9].data, {'action': 'hide', 'targetType': 'comment', 'targetId': 'c1'});
      expect(reported.isOk, isTrue);
      expect(moderated.isOk, isTrue);
    });
  });
}

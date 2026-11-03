import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';
import 'package:readin/features/comments/domain/repositories/comments_repository.dart';
import 'package:readin/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:readin/features/comments/presentation/cubit/mention_suggestions_cubit.dart';

import 'social_fakes.dart';

class MockCommentsRepository extends Mock implements CommentsRepository {}

class MockCommentsCubit extends MockCubit<CommentsState> implements CommentsCubit {}

class MockMentionSuggestionsCubit extends MockCubit<List<Author>> implements MentionSuggestionsCubit {}

/// "Now" for comment times in tests and goldens: 2026-11-02 12:00 UTC.
final commentsNow = DateTime.utc(2026, 11, 2, 12);

const omar = Author(id: 'w-2', displayName: 'Omar Khaled', username: 'omar_k');
const mona = Author(id: 'w-1', displayName: 'منى عبد الله', username: 'mona_dev', isVerified: true);
const sara = Author(id: 'w-3', displayName: 'سارة (.NET)', username: 'sara_net');

/// The signed-in viewer of the tests (`sampleMe`).
const viewer = Author(id: 'u-1', displayName: 'Youssef Hassan', username: 'reader1');

Comment comment(
  String id, {
  String? parentId,
  String? body = 'تعليق',
  Author? author = omar,
  int minutesAgo = 30,
  int likeCount = 0,
  bool likedByMe = false,
  int replyCount = 0,
  bool isPinned = false,
  bool isArticleAuthor = false,
  bool edited = false,
  bool isDeleted = false,
  bool isHidden = false,
  bool own = false,
  bool canPin = false,
  bool canModerate = false,
  List<CommentMention> mentions = const [],
  List<Comment> replies = const [],
}) =>
    Comment(
      id: id,
      articleId: 'art-1',
      parentId: parentId,
      body: body,
      author: author,
      isArticleAuthor: isArticleAuthor,
      mentions: mentions,
      likeCount: likeCount,
      likedByMe: likedByMe,
      replyCount: replyCount,
      isPinned: isPinned,
      createdAt: commentsNow.subtract(Duration(minutes: minutesAgo)),
      editedAt: edited ? commentsNow.subtract(const Duration(minutes: 5)) : null,
      isDeleted: isDeleted,
      isHidden: isHidden,
      canEdit: own,
      canDelete: own,
      canPin: canPin,
      canReport: !own && body != null,
      canModerate: canModerate,
      replies: replies,
    );

/// A placeholder, as the API sends it: no text, no author, no actions.
Comment placeholder(String id, {bool deleted = true, int replyCount = 0, List<Comment> replies = const []}) => Comment(
      id: id,
      articleId: 'art-1',
      createdAt: commentsNow.subtract(const Duration(hours: 5)),
      isDeleted: deleted,
      isHidden: !deleted,
      replyCount: replyCount,
      replies: replies,
    );

/// Silences [MockRealtimeService.commentEvents] for tests that don't use live events.
void stubNoCommentEvents(MockRealtimeService realtime) =>
    when(() => realtime.commentEvents(any())).thenAnswer((_) => const Stream.empty());

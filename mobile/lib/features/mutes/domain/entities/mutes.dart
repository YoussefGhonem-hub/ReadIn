import 'package:equatable/equatable.dart';

import '../../../follow/domain/entities/follow.dart';

export '../../../follow/domain/entities/follow.dart' show UserSummary;

/// `UserMuteStateDto` (F28): a writer's mute and the viewer's follow of them after `PUT` / `DELETE /users/{id}/mute`.
class UserMuteState extends Equatable {
  const UserMuteState({required this.isMuted, required this.isFollowing, required this.followerCount, this.followRemoved = false});

  final bool isMuted;

  /// A mute always ends the viewer's follow; an Undo with `restoreFollow=true` follows again.
  final bool isFollowing;

  /// The writer's followers after the change.
  final int followerCount;

  /// This mute ended the viewer's follow, so its Undo follows the writer again. Always false after an unmute.
  final bool followRemoved;

  @override
  List<Object?> get props => [isMuted, isFollowing, followerCount, followRemoved];
}

/// `ContentMutesDto` (F28): every field and topic the viewer muted, after a change.
class ContentMutes extends Equatable {
  const ContentMutes({this.fieldIds = const [], this.topicIds = const []});

  final List<String> fieldIds;
  final List<String> topicIds;

  @override
  List<Object?> get props => [fieldIds, topicIds];
}

/// `MutedFieldDto`: a muted field in Settings → Muted. [icon] is a Lucide name, [color] a design token.
class MutedField extends Equatable {
  const MutedField({
    required this.id,
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    this.icon = 'book-open',
    this.color = 'primary',
  });

  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String icon;
  final String color;

  String nameFor(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  @override
  List<Object?> get props => [id, slug, nameAr, nameEn, icon, color];
}

/// `MutedTopicDto`: a muted topic and the field it belongs to.
class MutedTopic extends Equatable {
  const MutedTopic({required this.id, required this.slug, required this.nameAr, required this.nameEn, required this.field});

  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;
  final MutedField field;

  String nameFor(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  @override
  List<Object?> get props => [id, slug, nameAr, nameEn, field];
}

/// `MutesDto` (`GET /me/mutes`): Settings → Muted (F18, F28), each list newest mute first.
class Mutes extends Equatable {
  const Mutes({this.users = const [], this.fields = const [], this.topics = const []});

  final List<UserSummary> users;
  final List<MutedField> fields;
  final List<MutedTopic> topics;

  bool get isEmpty => users.isEmpty && fields.isEmpty && topics.isEmpty;

  Mutes copyWith({List<UserSummary>? users, List<MutedField>? fields, List<MutedTopic>? topics}) =>
      Mutes(users: users ?? this.users, fields: fields ?? this.fields, topics: topics ?? this.topics);

  @override
  List<Object?> get props => [users, fields, topics];
}

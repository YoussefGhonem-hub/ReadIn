import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/mutes.dart';
import '../repositories/mutes_repository.dart';

/// Mutes or unmutes a writer (F28). [restoreFollow] (unmute only) follows them again: the Undo of a mute that ended a
/// follow.
@injectable
class SetUserMuted {
  const SetUserMuted(this._repository);

  final MutesRepository _repository;

  Future<Result<UserMuteState>> call(String userId, {required bool muted, bool restoreFollow = false}) =>
      muted ? _repository.muteUser(userId) : _repository.unmuteUser(userId, restoreFollow: restoreFollow);
}

/// Mutes or unmutes a field or a topic (the "كتم المواضيع" sheet, Settings → Muted).
@injectable
class SetContentMuted {
  const SetContentMuted(this._repository);

  final MutesRepository _repository;

  Future<Result<ContentMutes>> field(String fieldId, {required bool muted}) => _repository.setFieldMuted(fieldId, muted: muted);

  Future<Result<ContentMutes>> topic(String topicId, {required bool muted}) => _repository.setTopicMuted(topicId, muted: muted);
}

/// "قلّل من النوع ده" on an article, and its Undo.
@injectable
class SetShowLess {
  const SetShowLess(this._repository);

  final MutesRepository _repository;

  Future<Result<void>> call(String articleId, {required bool showLess}) => _repository.setShowLess(articleId, showLess: showLess);
}

/// Settings → Muted: the writers, fields and topics the viewer muted.
@injectable
class GetMutes {
  const GetMutes(this._repository);

  final MutesRepository _repository;

  Future<Result<Mutes>> call() => _repository.getMutes();
}

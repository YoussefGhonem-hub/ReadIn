import '../domain/entities/moderation.dart';

/// Where moderation lives in the app (F22): Settings → Moderation (`/moderation`, with the queue tabs and the log) and
/// one case (`/moderation/{targetType}/{targetId}`).
abstract final class ModerationRoutes {
  static const home = '/moderation';

  static String caseOf(ModerationTargetRef target) => '$home/${target.type.name}/${Uri.encodeComponent(target.id)}';
}

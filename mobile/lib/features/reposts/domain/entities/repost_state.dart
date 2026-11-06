import 'package:equatable/equatable.dart';

/// `RepostStateDto` (F29): an article's reposts right after the viewer's change, and the viewer's caption.
class RepostState extends Equatable {
  const RepostState({required this.repostCount, required this.isReposted, this.caption});

  final int repostCount;
  final bool isReposted;

  /// The viewer's thoughts on their repost (plain text, ≤ [maxCaptionLength]); null when it has none or they haven't
  /// reposted.
  final String? caption;

  /// At most this many characters (UTF-16 code units, as the API counts them) after trimming.
  static const maxCaptionLength = 500;

  /// [text] as the API stores it: `\r\n` becomes `\n`, then trimmed. Its length is what [maxCaptionLength] limits.
  static String normalizeCaption(String text) => text.replaceAll('\r\n', '\n').trim();

  @override
  List<Object?> get props => [repostCount, isReposted, caption];
}

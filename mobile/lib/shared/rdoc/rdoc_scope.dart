import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/tokens.g.dart';
import 'rdoc_document.dart';

typedef RDocLinkHandler = void Function(String href);
typedef RDocTermHandler = void Function(RTerm term);
typedef RDocMentionHandler = void Function(RMention mention);

/// Rendering configuration for an RDoc tree: article base direction, reader
/// font size (S/M/L/XL) and interaction callbacks.
class RDocScope extends InheritedWidget {
  const RDocScope({
    super.key,
    required super.child,
    required this.baseDirection,
    this.bodyFontSize = ReadInArticleFontScale.m,
    this.onLinkTap,
    this.onTermTap,
    this.onMentionTap,
    this.unlinkedMentionIds = const {},
  });

  /// Fallback direction for `dir: auto` blocks without strong characters:
  /// RTL for `ar-EG` articles, LTR for `en`.
  final TextDirection baseDirection;
  final double bodyFontSize;
  final RDocLinkHandler? onLinkTap;
  final RDocTermHandler? onTermTap;
  final RDocMentionHandler? onMentionTap;

  /// People the reader is blocked with (F36, `ArticleDetailsDto.unlinkedMentionIds`): their mentions read as plain
  /// text, with no link.
  final Set<String> unlinkedMentionIds;

  static TextDirection directionForLanguage(String language) =>
      language.startsWith('ar') ? TextDirection.rtl : TextDirection.ltr;

  /// Scale relative to the default body size, applied to headings and code.
  double get scale => bodyFontSize / ReadInArticleFontScale.m;

  static RDocScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RDocScope>();
    assert(scope != null, 'RDoc widgets must be placed under an RDocScope');
    return scope!;
  }

  @override
  bool updateShouldNotify(RDocScope old) =>
      old.baseDirection != baseDirection ||
      old.bodyFontSize != bodyFontSize ||
      old.onLinkTap != onLinkTap ||
      old.onTermTap != onTermTap ||
      old.onMentionTap != onMentionTap ||
      !setEquals(old.unlinkedMentionIds, unlinkedMentionIds);
}

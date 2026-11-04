import 'package:flutter/material.dart';

import '../../../../core/config/app_links.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/platform/share_service.dart';
import '../../domain/entities/article.dart';

/// The reader's share button (SPEC F24): shares the article's web address in the version being read,
/// `https://{domain}/{ar|en}/a/{slug}` ([AppLinks.article]). It opens the app where it is installed (App Links,
/// Universal Links) and the web everywhere else. Disabled until the article has loaded.
class ArticleShareButton extends StatelessWidget {
  const ArticleShareButton({super.key, required this.article});

  final ArticleCard? article;

  @override
  Widget build(BuildContext context) {
    final a = article;
    return IconButton(
      tooltip: context.l10n.share,
      icon: const Icon(Icons.ios_share_rounded),
      onPressed: a == null ? null : () => share(context, a),
    );
  }

  /// Opens the share sheet for [article], anchored on [context]'s widget (the post card's "Share" too, F34).
  static Future<void> share(BuildContext context, ArticleCard article) => _share(article, _originOf(context));

  static Future<void> _share(ArticleCard article, Rect? origin) async {
    try {
      await getIt<ShareService>().shareLink(
        AppLinks.article(article.slug, language: article.language),
        subject: article.title,
        origin: origin,
      );
    } on Object {
      // The share sheet is best effort: nothing to tell the reader when it doesn't open.
    }
  }

  /// Anchors the share popover on iPad.
  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
  }
}

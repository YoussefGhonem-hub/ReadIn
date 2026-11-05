import 'package:equatable/equatable.dart';

/// A tag on a card or in the reader (`TagRefDto`, F32): shown as `#name`, it opens the tag page of [slug].
class TagRef extends Equatable {
  const TagRef({required this.slug, required this.name});

  /// The tag page's key; the API makes it, clients never build one from a name. Empty for a tag that has no page
  /// (yet): a new name in the editor's preview, or an offline copy saved before tags had pages.
  final String slug;

  /// The first spelling anyone used, e.g. `C#`, `.NET`, `الذكاء الاصطناعي`.
  final String name;

  /// Tapping it opens the tag page.
  bool get hasPage => slug.isNotEmpty;

  @override
  List<Object?> get props => [slug, name];
}

/// `TagDto`: an editor suggestion (`GET /tags?q=`) and the tag page's header (`GET /tags/{slug}`). Never a hidden tag.
class ArticleTag extends Equatable {
  const ArticleTag({required this.slug, required this.name, this.articleCount = 0});

  final String slug;
  final String name;

  /// Published articles readers can see; 0 → the tag page's empty state.
  final int articleCount;

  TagRef get ref => TagRef(slug: slug, name: name);

  @override
  List<Object?> get props => [slug, name, articleCount];
}

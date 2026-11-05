import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/entities/tag.dart';
import '../tag_routes.dart';

/// A tag as `#name` (F32), on post cards and in the reader: a link that opens its tag page. A tag without a page (a
/// new name in the editor's preview, an offline copy saved before tag pages) is the same chip without the link.
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.tag});

  final TagRef tag;

  /// Chips and "+N" are this tall at least, so a finger finds them.
  static const minHeight = 32.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // A name in the other script is isolated with its "#": "#EF Core" stays as it is in an Arabic list.
    final label = _ChipLabel('#${tag.name}');
    if (!tag.hasPage) return _ChipFrame(child: label);

    void open() => unawaited(GoRouter.maybeOf(context)?.push<void>(TagRoutes.of(tag.slug)));
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReadInRadius.chip));
    return Semantics(
      link: true,
      label: '#${tag.name}',
      hint: context.l10n.tagOpenHint,
      onTap: open,
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceVariant,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('tag-link-${tag.slug}'),
          onTap: open,
          customBorder: shape,
          child: _ChipPadding(child: label),
        ),
      ),
    );
  }
}

/// "+N" after a post card's tags: the tags the card doesn't show (plain, it opens nothing).
class TagMoreChip extends StatelessWidget {
  const TagMoreChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
        label: context.l10n.postMoreTags(count),
        excludeSemantics: true,
        child: _ChipFrame(child: _ChipLabel(Bidi.ltrIsolate('+$count'))),
      );
}

/// Tags one after another, wrapping: [TagChip]s, then "+[more]" when the list shows only some of them.
class TagChipsWrap extends StatelessWidget {
  const TagChipsWrap({super.key, required this.tags, this.more = 0});

  final List<TagRef> tags;
  final int more;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: ReadInSpace.s2,
        runSpacing: ReadInSpace.s2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final tag in tags) TagChip(tag: tag),
          if (more > 0) TagMoreChip(count: more),
        ],
      );
}

class _ChipFrame extends StatelessWidget {
  const _ChipFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: context.colors.surfaceVariant, borderRadius: BorderRadius.circular(ReadInRadius.chip)),
        child: _ChipPadding(child: child),
      );
}

class _ChipPadding extends StatelessWidget {
  const _ChipPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: TagChip.minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: 6),
          child: Center(widthFactor: 1, child: child),
        ),
      );
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        Bidi.isolateOppositeRuns(text, Directionality.of(context)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary, fontWeight: FontWeight.w600),
      );
}

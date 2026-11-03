import 'package:flutter/material.dart';

import '../../../core/bidi/bidi.dart';
import '../../../core/l10n/l10n_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens.g.dart';
import '../../widgets/app_network_image.dart';
import '../rdoc_document.dart';
import '../rdoc_scope.dart';
import '../rdoc_text.dart';
import 'text_blocks.dart';

class RImageView extends StatelessWidget {
  const RImageView(this.block, {super.key});

  final RImage block;

  @override
  Widget build(BuildContext context) {
    final src = context.isDark && (block.darkSrc?.isNotEmpty ?? false) ? block.darkSrc! : block.src;
    final ratio = block.width != null && block.height != null ? block.width! / block.height! : 16 / 9;
    final caption = block.caption;
    final dir = Bidi.resolve('auto', caption ?? block.alt, fallback: RDocScope.of(context).baseDirection);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNetworkImage(
          url: src,
          semanticLabel: block.alt,
          aspectRatio: ratio,
          borderRadius: BorderRadius.circular(ReadInRadius.md),
          errorLabel: context.l10n.imageUnavailable,
        ),
        if (caption != null && caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: ReadInSpace.s2),
            child: Text(
              Bidi.isolateOppositeRuns(caption, dir),
              textDirection: dir,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class RTableView extends StatelessWidget {
  const RTableView(this.block, {super.key});

  final RTable block;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dir = resolveBlockDir(context, block.dir, block.header.expand((c) => c).toList());
    final style = rdocBodyStyle(context, dir, factor: 0.85).copyWith(height: 1.5);
    final columns = block.header.length;

    TableRow row(List<List<RInline>> cells, {bool header = false}) => TableRow(
          decoration: BoxDecoration(color: header ? colors.surfaceVariant : null),
          children: [
            for (var c = 0; c < columns; c++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: ReadInSpace.s2),
                child: RDocText(
                  c < cells.length ? cells[c] : const [],
                  style: header ? style.copyWith(fontWeight: FontWeight.w600) : style,
                  direction: dir,
                ),
              ),
          ],
        );

    return Directionality(
      textDirection: dir,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - ReadInSpace.s5 * 2),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(ReadInRadius.md),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.symmetric(inside: BorderSide(color: colors.border)),
              children: [
                row(block.header, header: true),
                for (final r in block.rows) row(r),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class REmbedView extends StatelessWidget {
  const REmbedView(this.block, {super.key});

  final REmbed block;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scope = RDocScope.of(context);
    final (icon, name) = switch (block.provider) {
      'youtube' => (Icons.play_circle_outline, 'YouTube'),
      'github-gist' => (Icons.code, 'GitHub Gist'),
      _ => (Icons.link, block.provider),
    };
    return Material(
      color: colors.surfaceVariant,
      borderRadius: BorderRadius.circular(ReadInRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(ReadInRadius.md),
        onTap: scope.onLinkTap == null ? null : () => scope.onLinkTap!(block.url),
        child: Padding(
          padding: const EdgeInsets.all(ReadInSpace.s4),
          child: Row(
            children: [
              Icon(icon, color: colors.primary, size: 32),
              const SizedBox(width: ReadInSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.embedOpen(name), style: context.textTheme.titleSmall),
                    Text(
                      block.url,
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, color: colors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

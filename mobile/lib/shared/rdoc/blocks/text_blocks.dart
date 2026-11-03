import 'package:flutter/material.dart';

import '../../../core/bidi/bidi.dart';
import '../../../core/l10n/l10n_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens.g.dart';
import '../rdoc_document.dart';
import '../rdoc_scope.dart';
import '../rdoc_text.dart';

/// Article body style for a block: 17–18px / 1.8 (SPEC §15.3), scaled by the
/// reader's font size, with the font chosen by the block's script.
TextStyle rdocBodyStyle(BuildContext context, TextDirection dir, {double factor = 1}) {
  final scope = RDocScope.of(context);
  final rtl = dir == TextDirection.rtl;
  return TextStyle(
    fontFamily: rtl ? ReadInFonts.arabic : ReadInFonts.latin,
    fontFamilyFallback: [rtl ? ReadInFonts.latin : ReadInFonts.arabic],
    fontSize: scope.bodyFontSize * factor,
    height: ReadInType.bodyHeight,
    color: context.colors.textPrimary,
  );
}

TextDirection resolveBlockDir(BuildContext context, String dir, List<RInline> content) =>
    Bidi.resolve(dir, plainTextOf(content), fallback: RDocScope.of(context).baseDirection);

class RParagraphView extends StatelessWidget {
  const RParagraphView(this.block, {super.key});

  final RParagraph block;

  @override
  Widget build(BuildContext context) {
    final dir = resolveBlockDir(context, block.dir, block.content);
    return Directionality(
      textDirection: dir,
      child: RDocText(block.content, style: rdocBodyStyle(context, dir), direction: dir),
    );
  }
}

class RHeadingView extends StatelessWidget {
  const RHeadingView(this.block, {super.key});

  final RHeading block;

  @override
  Widget build(BuildContext context) {
    final dir = resolveBlockDir(context, block.dir, block.content);
    final scale = RDocScope.of(context).scale;
    final size = (block.level == 2 ? ReadInType.h3Size : ReadInType.uiLgSize + 3) * scale;
    final style = rdocBodyStyle(context, dir).copyWith(fontSize: size, height: 1.4, fontWeight: FontWeight.w600);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: ReadInSpace.s3),
        child: Directionality(textDirection: dir, child: RDocText(block.content, style: style, direction: dir)),
      ),
    );
  }
}

class RListView extends StatelessWidget {
  const RListView(this.block, {super.key});

  final RList block;

  @override
  Widget build(BuildContext context) {
    final first = block.items.isEmpty ? const <RInline>[] : block.items.first;
    final dir = resolveBlockDir(context, block.dir, first);
    final style = rdocBodyStyle(context, dir);
    return Directionality(
      textDirection: dir,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < block.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: ReadInSpace.s1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      block.ordered ? '${i + 1}.' : '•',
                      style: style.copyWith(color: context.colors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: RDocText(block.items[i], style: style, direction: dir)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class RStepsView extends StatelessWidget {
  const RStepsView(this.block, {super.key});

  final RSteps block;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = block.items.isEmpty ? '' : block.items.first.title;
    final dir = Bidi.resolve(block.dir, title, fallback: RDocScope.of(context).baseDirection);
    final style = rdocBodyStyle(context, dir);
    return Directionality(
      textDirection: dir,
      child: Column(
        children: [
          for (var i = 0; i < block.items.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
                        child: Text(
                          '${i + 1}',
                          style: context.textTheme.labelLarge?.copyWith(color: colors.onPrimaryContainer),
                        ),
                      ),
                      if (i < block.items.length - 1)
                        Expanded(child: Container(width: 2, color: colors.primaryContainer)),
                    ],
                  ),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: ReadInSpace.s4, top: ReadInSpace.s1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Bidi.isolateOppositeRuns(block.items[i].title, dir),
                            style: style.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                          ),
                          if (block.items[i].content.isNotEmpty)
                            RDocText(block.items[i].content, style: style, direction: dir),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class RQuoteView extends StatelessWidget {
  const RQuoteView(this.block, {super.key});

  final RQuote block;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dir = resolveBlockDir(context, block.dir, block.content);
    final style = rdocBodyStyle(context, dir, factor: 1.05).copyWith(fontStyle: FontStyle.italic);
    return Directionality(
      textDirection: dir,
      child: Container(
        padding: const EdgeInsetsDirectional.only(start: ReadInSpace.s4),
        decoration: BoxDecoration(
          border: BorderDirectional(start: BorderSide(color: colors.primary, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RDocText(block.content, style: style, direction: dir),
            if (block.cite != null && block.cite!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: ReadInSpace.s1),
                child: Text('— ${Bidi.isolateOppositeRuns(block.cite!, dir)}', style: context.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class RCalloutView extends StatelessWidget {
  const RCalloutView(this.block, {super.key});

  final RCallout block;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, accent, icon) = switch (block.variant) {
      RCalloutVariant.tip => (colors.calloutTip, colors.calloutTipAccent, Icons.lightbulb_outline),
      RCalloutVariant.info => (colors.calloutInfo, colors.calloutInfoAccent, Icons.info_outline),
      RCalloutVariant.warning => (colors.calloutWarning, colors.calloutWarningAccent, Icons.warning_amber_rounded),
      RCalloutVariant.danger => (colors.calloutDanger, colors.calloutDangerAccent, Icons.dangerous_outlined),
    };
    final dir = Bidi.resolve(
      block.dir,
      '${block.title ?? ''}${plainTextOf(block.content)}',
      fallback: RDocScope.of(context).baseDirection,
    );
    final style = rdocBodyStyle(context, dir, factor: 0.94);
    return Directionality(
      textDirection: dir,
      child: Container(
        padding: const EdgeInsets.all(ReadInSpace.s4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ReadInRadius.md),
          border: BorderDirectional(start: BorderSide(color: accent, width: 4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 4), child: Icon(icon, color: accent, size: 22)),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (block.title != null && block.title!.isNotEmpty)
                    Text(
                      Bidi.isolateOppositeRuns(block.title!, dir),
                      style: style.copyWith(fontWeight: FontWeight.w700, height: 1.5),
                    ),
                  RDocText(block.content, style: style, direction: dir),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// TL;DR box (SPEC §11 F04).
class RSummaryView extends StatelessWidget {
  const RSummaryView(this.block, {super.key});

  final RSummary block;

  @override
  Widget build(BuildContext context) {
    final dir = resolveBlockDir(context, block.dir, block.content);
    return SummaryBox(
      direction: dir,
      child: RDocText(block.content, style: rdocBodyStyle(context, dir, factor: 0.94), direction: dir),
    );
  }
}

/// Shared TL;DR container, also used for the article's plain-text `summary`.
class SummaryBox extends StatelessWidget {
  const SummaryBox({super.key, required this.child, required this.direction});

  final Widget child;
  final TextDirection direction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ReadInSpace.s4),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(ReadInRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.tldr,
            style: context.textTheme.labelMedium?.copyWith(color: colors.onPrimaryContainer, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: ReadInSpace.s1),
          Directionality(textDirection: direction, child: child),
        ],
      ),
    );
  }
}

class RDividerView extends StatelessWidget {
  const RDividerView({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
        child: Divider(color: context.colors.border, indent: 48, endIndent: 48),
      );
}

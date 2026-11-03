import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/platform/share_service.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_logo.dart';

/// Celebrates a streak milestone (7, 30, 100, 365 days; F08) with a card the user can share as an image.
Future<void> showMilestoneSheet(BuildContext context, int days) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MilestoneSheet(days: days),
    );

/// Localized title and body for a milestone; other lengths get generic copy.
(String, String) milestoneCopy(AppLocalizations l10n, int days) => switch (days) {
      7 => (l10n.readingMilestoneWeekTitle, l10n.readingMilestoneWeekBody),
      30 => (l10n.readingMilestoneMonthTitle, l10n.readingMilestoneMonthBody),
      100 => (l10n.readingMilestoneHundredTitle, l10n.readingMilestoneHundredBody),
      365 => (l10n.readingMilestoneYearTitle, l10n.readingMilestoneYearBody),
      _ => (l10n.readingMilestoneTitle(days), l10n.readingMilestoneBody),
    };

class MilestoneSheet extends StatefulWidget {
  const MilestoneSheet({super.key, required this.days});

  final int days;

  @override
  State<MilestoneSheet> createState() => _MilestoneSheetState();
}

class _MilestoneSheetState extends State<MilestoneSheet> {
  final _cardKey = GlobalKey();
  bool _sharing = false;
  bool _failed = false;

  /// Renders the card to a PNG in the temp folder and opens the share sheet. [origin] anchors the popover on iPad.
  Future<void> _share(Rect? origin) async {
    if (_sharing) return;
    setState(() {
      _sharing = true;
      _failed = false;
    });
    try {
      final boundary = _cardKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return;
      final fileName = 'readin-streak-${widget.days}.png';
      final path = await _writePng(boundary, fileName);
      await getIt<ShareService>().shareFile(path, mimeType: 'image/png', fileName: fileName, origin: origin);
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  static Future<String> _writePng(RenderRepaintBoundary boundary, String fileName) async {
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw const FormatException('PNG encoding failed');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return file.path;
    } finally {
      image.dispose();
    }
  }

  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (title, body) = milestoneCopy(l10n, widget.days);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, textAlign: TextAlign.center, style: context.textTheme.headlineSmall),
          const SizedBox(height: ReadInSpace.s2),
          Text(body, textAlign: TextAlign.center, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: ReadInSpace.s5),
          FittedBox(
            // Shrinks the preview on narrow phones; the clip and border are for the preview only: the shared PNG is
            // the full rectangle at its own size.
            fit: BoxFit.scaleDown,
            child: Container(
              foregroundDecoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(ReadInRadius.card),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ReadInRadius.card),
                child: RepaintBoundary(key: _cardKey, child: MilestoneShareCard(days: widget.days)),
              ),
            ),
          ),
          const SizedBox(height: ReadInSpace.s5),
          if (_failed) ...[
            Text(
              l10n.readingShareFailed,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(color: colors.error),
            ),
            const SizedBox(height: ReadInSpace.s2),
          ],
          Builder(
            builder: (buttonContext) => FilledButton.icon(
              onPressed: _sharing ? null : () => _share(_originOf(buttonContext)),
              icon: _sharing
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.ios_share_rounded),
              label: Text(l10n.share),
            ),
          ),
          const SizedBox(height: ReadInSpace.s2),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.readingKeepReading)),
        ],
      ),
    );
  }
}

/// The shareable milestone card (F08, SPEC §15.5 rule 8): follows the light/dark theme, 4:5, with the ReadIn wordmark,
/// the streak and localized copy. It is exported as an image, so its layout is fixed and ignores text scaling.
class MilestoneShareCard extends StatelessWidget {
  const MilestoneShareCard({super.key, required this.days});

  static const size = Size(300, 375);

  final int days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final (title, _) = milestoneCopy(l10n, days);
    return Semantics(
      label: l10n.readingShareCardSemantics(days),
      excludeSemantics: true,
      child: MediaQuery.withNoTextScaling(
        child: SizedBox.fromSize(
          size: size,
          child: ColoredBox(
            color: colors.surface,
            child: Stack(
              children: [
                PositionedDirectional(
                  end: -70,
                  top: -70,
                  child: _Disc(size: 210, color: colors.primaryContainer),
                ),
                PositionedDirectional(
                  start: -50,
                  bottom: -60,
                  child: _Disc(size: 150, color: colors.accentContainer),
                ),
                Padding(
                  padding: const EdgeInsets.all(ReadInSpace.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppLogo(size: 24),
                      const Spacer(),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(color: colors.accentContainer, shape: BoxShape.circle),
                              child: Icon(Icons.local_fire_department_rounded, size: 40, color: colors.accent),
                            ),
                            const SizedBox(height: ReadInSpace.s2),
                            Text(
                              '$days',
                              textDirection: TextDirection.ltr,
                              style: context.textTheme.displaySmall?.copyWith(
                                fontFamily: ReadInFonts.latin,
                                fontSize: 72,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              l10n.readingDaysInARow(days),
                              style: context.textTheme.titleMedium?.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(title, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(l10n.tagline, style: context.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

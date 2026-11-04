import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../profile/presentation/widgets/profile_header.dart' show ProfileBioText;
import '../../domain/entities/moderation.dart';
import '../cubit/moderation_notices_cubit.dart';
import 'moderation_labels.dart';

/// A moderation notice (F22): "You received a warning…" or "Your article “…” was hidden", with the moderator's note.
/// Only "Got it" closes it; true then.
Future<bool> showModerationNoticeDialog(BuildContext context, ModerationNotice notice) async {
  final acknowledged = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ModerationNoticeDialog(notice: notice),
  );
  return acknowledged ?? false;
}

class ModerationNoticeDialog extends StatelessWidget {
  const ModerationNoticeDialog({super.key, required this.notice});

  final ModerationNotice notice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final warning = notice.kind == ModerationNoticeKind.warning;
    final title = warning
        ? l10n.noticeWarningTitle
        // The title keeps its own direction inside the sentence.
        : l10n.noticeArticleHiddenTitle(embedContent(notice.article?.title ?? ''));
    final note = notice.note;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: Icon(
          warning ? Icons.report_gmailerrorred_rounded : Icons.visibility_off_outlined,
          color: warning ? colors.calloutWarningAccent : colors.textSecondary,
        ),
        title: Text(title, textAlign: TextAlign.center),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              warning ? l10n.noticeWarningBody : l10n.noticeArticleHiddenBody,
              style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
            if (note != null && note.trim().isNotEmpty) ...[
              const SizedBox(height: ReadInSpace.s4),
              Container(
                padding: const EdgeInsets.all(ReadInSpace.s3),
                decoration: BoxDecoration(
                  color: colors.calloutWarning,
                  borderRadius: BorderRadius.circular(ReadInRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.noticeNoteLabel, style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary)),
                    const SizedBox(height: ReadInSpace.s1),
                    ProfileBioText(note, style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary)),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.noticeAcknowledge)),
        ],
      ),
    );
  }
}

/// Shows the signed-in user's moderation notices one after the other over whatever screen is open, and acknowledges
/// each on "Got it" (F22). Sits above the app's navigator ([navigatorKey]); waits while [canShow] says no (the splash)
/// and tries again when [changes] fires.
class ModerationNoticesHost extends StatefulWidget {
  const ModerationNoticesHost({super.key, required this.navigatorKey, required this.child, this.canShow, this.changes});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  final bool Function()? canShow;
  final Listenable? changes;

  @override
  State<ModerationNoticesHost> createState() => _ModerationNoticesHostState();
}

class _ModerationNoticesHostState extends State<ModerationNoticesHost> {
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    widget.changes?.addListener(_schedule);
    _schedule();
  }

  @override
  void didUpdateWidget(ModerationNoticesHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.changes != widget.changes) {
      oldWidget.changes?.removeListener(_schedule);
      widget.changes?.addListener(_schedule);
    }
  }

  @override
  void dispose() {
    widget.changes?.removeListener(_schedule);
    super.dispose();
  }

  /// After the next frame, so a route change in progress settles first. Asks for that frame: notices can arrive while
  /// the app is idle.
  void _schedule() {
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => unawaited(_showNext()))
      ..ensureVisualUpdate();
  }

  Future<void> _showNext() async {
    if (!mounted || _showing) return;
    final cubit = context.read<ModerationNoticesCubit>();
    final notice = cubit.state.firstOrNull;
    final navigator = widget.navigatorKey.currentContext;
    if (notice == null || navigator == null || !(widget.canShow?.call() ?? true)) return;
    _showing = true;
    final acknowledged = await showModerationNoticeDialog(navigator, notice);
    _showing = false;
    if (!mounted) return;
    // Closed some other way (the screen under it went away): it shows again on the next change.
    if (acknowledged) await cubit.acknowledge(notice.id);
  }

  @override
  Widget build(BuildContext context) => BlocListener<ModerationNoticesCubit, List<ModerationNotice>>(
        listener: (_, _) => _schedule(),
        child: widget.child,
      );
}

import 'package:flutter/material.dart';

import '../../core/errors/failure.dart';
import '../../core/l10n/failure_messages.dart';
import '../../core/l10n/l10n_x.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens.g.dart';

/// Error state with a translated message and retry (Definition of Done: every
/// screen has empty, loading and error states).
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry, this.compact = false});

  final Failure failure;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final offline = failure.code == FailureCodes.networkOffline;
    return _MessageView(
      icon: offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      title: l10n.errorTitle,
      body: localizeFailure(l10n, failure),
      compact: compact,
      action: onRetry == null ? null : OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, this.body, this.icon = Icons.auto_stories_outlined, this.action});

  final String title;
  final String? body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _MessageView(icon: icon, title: title, body: body, action: action);
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.title, this.body, this.action, this.compact = false});

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? ReadInSpace.s4 : ReadInSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(ReadInSpace.s4),
              decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, size: compact ? 24 : 32, color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: ReadInSpace.s4),
            Text(title, style: context.textTheme.titleMedium, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: ReadInSpace.s2),
              Text(body!, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: ReadInSpace.s5), action!],
          ],
        ),
      ),
    );
  }
}

/// Static placeholder block for skeleton loading. No shimmer animation, so it
/// respects "reduce motion" by default (SPEC §26).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = ReadInRadius.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: context.colors.surfaceVariant, borderRadius: BorderRadius.circular(radius)),
      );
}

class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key, this.icon = Icons.construction_rounded});

  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      EmptyView(icon: icon, title: context.l10n.comingSoonTitle, body: context.l10n.comingSoonBody);
}

/// Full page wrapper for features that are not built yet.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, this.icon = Icons.construction_rounded, this.showBack = false});

  final String title;
  final IconData icon;
  final bool showBack;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), automaticallyImplyLeading: showBack),
        body: ComingSoonView(icon: icon),
      );
}

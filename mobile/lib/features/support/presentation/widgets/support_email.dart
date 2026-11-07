import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/config/app_links.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../domain/entities/support.dart';
import '../cubit/support_cubits.dart';

/// The support email to show: `Support:Email` from `GET /support/config` (F35), else the built-in address while it
/// loads, fails, or is not set.
String supportEmailOf(SupportConfig? config) => config?.email ?? SupportContact.email;

/// Provides a [SupportConfigCubit] (loaded) to [child] when DI is set up; just [child] otherwise (tests).
class SupportConfigScope extends StatelessWidget {
  const SupportConfigScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<SupportConfigCubit>()) return child;
    return BlocProvider(create: (_) => getIt<SupportConfigCubit>()..load(), child: child);
  }
}

/// The support email in large type, LTR, with Email and Copy (F35: the help page, the suspension screen's appeal).
class SupportEmailCard extends StatelessWidget {
  const SupportEmailCard({super.key, this.body});

  /// What the email is for; "Email us" by default.
  final String? body;

  @override
  Widget build(BuildContext context) => SupportConfigScope(child: _EmailCard(body: body));
}

class _EmailCard extends StatelessWidget {
  const _EmailCard({this.body});

  final String? body;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final email = supportEmailOf(context.select((SupportConfigCubit? c) => c?.state));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(body ?? l10n.supportEmailBody, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
        const SizedBox(height: ReadInSpace.s3),
        SelectableText(
          email,
          key: const ValueKey('support-email-address'),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium?.copyWith(fontFamily: ReadInFonts.latin),
        ),
        const SizedBox(height: ReadInSpace.s3),
        FilledButton.icon(
          icon: const Icon(Icons.mail_outline_rounded),
          label: Text(l10n.supportEmailAction),
          onPressed: () => unawaited(launchUrl(Uri(scheme: 'mailto', path: email))),
        ),
        const SizedBox(height: ReadInSpace.s2),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy_rounded),
          label: Text(l10n.copyEmail),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: email));
            if (context.mounted) showActionMessage(context, l10n.copied);
          },
        ),
      ],
    );
  }
}

/// The support email in a sheet, from the help page's app bar.
Future<void> showSupportEmailSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(sheetContext.l10n.supportEmailUs, style: sheetContext.textTheme.titleLarge)),
            const SizedBox(height: ReadInSpace.s3),
            const SupportEmailCard(),
          ],
        ),
      ),
    );

/// The email line for the suspension screen (F35): suspended members can't sign in, so the appeal goes by email.
class SupportAppealNote extends StatelessWidget {
  const SupportAppealNote({super.key});

  @override
  Widget build(BuildContext context) => const SupportConfigScope(child: Builder(builder: _build));

  static Widget _build(BuildContext context) {
    final email = supportEmailOf(context.select((SupportConfigCubit? c) => c?.state));
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${context.l10n.supportAppealLine} '),
          TextSpan(text: Bidi.ltrIsolate(email), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      key: const ValueKey('support-appeal-note'),
      style: context.textTheme.bodySmall?.copyWith(color: context.colors.textPrimary),
    );
  }
}

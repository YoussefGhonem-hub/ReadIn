import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/phone/phone_numbers.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../support/presentation/cubit/support_cubits.dart' show SupportConfigCubit;
import '../../../support/presentation/widgets/support_email.dart';

/// Translated text for a form error code, or null.
String? errorText(BuildContext context, String? code) => code == null ? null : localizeErrorCode(context.l10n, code);

/// Shared layout of the auth and account screens: optional logo, title, subtitle, content, footer. Content is capped
/// at a phone-like width on tablets. One white (`surface`) page, the bar too and with no line under it: a form, not
/// blocks on the canvas.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
    this.header,
    this.showLogo = false,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;

  /// Above the title (e.g. the sign-up step indicator).
  final Widget? header;
  final bool showLogo;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          actions: actions,
          shape: const Border(),
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s6),
                children: [
                  if (showLogo) ...[
                    const Align(alignment: AlignmentDirectional.centerStart, child: AppLogo()),
                    const SizedBox(height: ReadInSpace.s5),
                  ],
                  if (header != null) ...[header!, const SizedBox(height: ReadInSpace.s4)],
                  Semantics(header: true, child: Text(title, style: context.textTheme.headlineMedium)),
                  if (subtitle != null) ...[
                    const SizedBox(height: ReadInSpace.s2),
                    Text(subtitle!, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
                  ],
                  const SizedBox(height: ReadInSpace.s5),
                  ...children,
                  if (footer != null) ...[const SizedBox(height: ReadInSpace.s5), footer!],
                ],
              ),
            ),
          ),
        ),
      );
}

/// The main button of a form: disabled with a spinner while submitting, so a double tap can't submit twice.
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.submitting,
    required this.onPressed,
    this.destructive = false,
    this.progressLabel,
  });

  final String label;
  final bool submitting;
  final VoidCallback? onPressed;

  /// Red, for an action that can't be undone (delete account); it stays red with its spinner while submitting.
  final bool destructive;

  /// Announced to screen readers once submitting starts (a live region); otherwise the button reads "label, Loading…".
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      enabled: !submitting && onPressed != null,
      liveRegion: progressLabel != null && submitting,
      label: submitting ? progressLabel ?? '$label, ${context.l10n.loading}' : null,
      excludeSemantics: submitting,
      child: FilledButton(
        style: destructive
            ? FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                disabledBackgroundColor: submitting ? colors.error : null,
                disabledForegroundColor: submitting ? colors.onError : null,
              )
            : null,
        onPressed: submitting ? null : onPressed,
        child: submitting
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: destructive ? colors.onError : null),
              )
            : Text(label),
      ),
    );
  }
}

/// "أو" between the phone sign in and other ways to sign in (Google / Apple, SPEC v1.1).
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3),
            child: Text(context.l10n.orDivider, style: context.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary)),
          ),
          const Expanded(child: Divider()),
        ],
      );
}

enum BannerTone { error, warning, success, info }

/// A message above a form: an error from the server, or a success such as "password changed".
class FormBanner extends StatelessWidget {
  const FormBanner({super.key, required this.message, this.tone = BannerTone.error, this.action});

  final String message;
  final BannerTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, accent, icon) = switch (tone) {
      BannerTone.error => (colors.calloutDanger, colors.error, Icons.error_outline_rounded),
      BannerTone.warning => (colors.calloutWarning, colors.calloutWarningAccent, Icons.warning_amber_rounded),
      BannerTone.success => (colors.calloutTip, colors.success, Icons.check_circle_outline_rounded),
      BannerTone.info => (colors.calloutInfo, colors.calloutInfoAccent, Icons.info_outline_rounded),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(ReadInSpace.s4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(ReadInRadius.md)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary)),
                  if (action != null) ...[const SizedBox(height: ReadInSpace.s1), action!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [FormBanner] for a failed call; suspended accounts and disabled recovery get a "contact support" action.
class FailureBanner extends StatelessWidget {
  const FailureBanner({super.key, required this.failure, this.action});

  final Failure failure;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final suspended = failure.code == FailureCodes.userSuspended;
    final needsSupport = suspended || failure.code == FailureCodes.authRecoveryDisabled;
    final contact = TextButton(
      onPressed: () => showContactSupportSheet(context, appeal: suspended),
      child: Text(context.l10n.contactSupport),
    );
    return FormBanner(
      message: localizeFailure(context.l10n, failure),
      action: action ??
          (!needsSupport
              ? null
              // A suspended member can't sign in to send a ticket: the support email is right here for an appeal (F35).
              : suspended
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SupportAppealNote(), contact])
                  : contact),
    );
  }
}

/// "خطوة 1 من 3" with a progress bar.
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.stepOf(current, total), style: context.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: ReadInSpace.s2),
          ExcludeSemantics(
            child: LinearProgressIndicator(
              value: current / total,
              minHeight: 4,
              borderRadius: BorderRadius.circular(ReadInRadius.chip),
            ),
          ),
        ],
      );
}

/// Step 3 of sign up, and before changing the number (SPEC §9.2): the number large and LTR with the warning. True =
/// confirmed, false = edit, null = dismissed.
Future<bool?> showConfirmNumberDialog(BuildContext context, {required String phoneE164, required String confirmLabel}) {
  final l10n = context.l10n;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.confirmNumberTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s4, horizontal: ReadInSpace.s3),
            decoration: BoxDecoration(
              color: dialogContext.colors.primaryContainer,
              borderRadius: BorderRadius.circular(ReadInRadius.md),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                PhoneNumbers.formatE164(phoneE164),
                textDirection: TextDirection.ltr,
                style: dialogContext.textTheme.headlineSmall?.copyWith(
                  fontFamily: ReadInFonts.latin,
                  fontWeight: FontWeight.w700,
                  color: dialogContext.colors.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: ReadInSpace.s4),
          Text(l10n.confirmNumberWarning, style: dialogContext.textTheme.bodyMedium),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.edit)),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(confirmLabel)),
      ],
    ),
  );
}

/// "نسيت الـ PIN كمان؟" (SPEC §9.1): only an Admin can reset the password, through support. [appeal]: a suspended
/// member appeals by email (F35).
Future<void> showContactSupportSheet(BuildContext context, {bool appeal = false}) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => ContactSupportSheet(appeal: appeal),
    );

class ContactSupportSheet extends StatelessWidget {
  const ContactSupportSheet({super.key, this.appeal = false});

  /// A suspension's appeal instead of a password reset (F35).
  final bool appeal;

  @override
  Widget build(BuildContext context) => SupportConfigScope(child: Builder(builder: _build));

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    // `Support:Email` from `GET /support/config` (F35), else the built-in address.
    final email = supportEmailOf(context.select((SupportConfigCubit? c) => c?.state));
    return Padding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.supportTitle, style: context.textTheme.titleLarge)),
          const SizedBox(height: ReadInSpace.s3),
          Text(
            appeal ? l10n.supportAppealBody : l10n.supportBody,
            style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: ReadInSpace.s4),
          SelectableText(
            email,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(fontFamily: ReadInFonts.latin),
          ),
          const SizedBox(height: ReadInSpace.s4),
          FilledButton.icon(
            icon: const Icon(Icons.mail_outline_rounded),
            label: Text(l10n.supportEmailAction),
            onPressed: () => launchUrl(Uri(scheme: 'mailto', path: email)),
          ),
          const SizedBox(height: ReadInSpace.s2),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded),
            label: Text(l10n.copyEmail),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: email));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copied)));
              }
            },
          ),
        ],
      ),
    );
  }
}

/// A sign-out action for the mandatory screens, so nobody is trapped on them.
class SignOutAction extends StatelessWidget {
  const SignOutAction({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(onPressed: onPressed, child: Text(context.l10n.signOut));
}

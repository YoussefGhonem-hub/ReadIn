import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/google_logo.dart';
import '../../domain/entities/external_credential.dart';
import '../cubit/external_sign_in_cubit.dart';
import '../pages/link_external_account_page.dart';
import 'auth_widgets.dart';

extension ExternalProviderName on ExternalProvider {
  /// Brand names stay in Latin script in both languages.
  String get label => switch (this) {
        ExternalProvider.google => 'Google',
        ExternalProvider.apple => 'Apple',
      };
}

/// The provider's mark: the four-colour Google "G" or the Apple logo.
class ExternalProviderIcon extends StatelessWidget {
  const ExternalProviderIcon(this.provider, {super.key, this.size = 20, this.color});

  final ExternalProvider provider;
  final double size;

  /// The Apple logo's colour (the Google mark keeps its own).
  final Color? color;

  @override
  Widget build(BuildContext context) => switch (provider) {
        ExternalProvider.google => GoogleLogo(size: size),
        ExternalProvider.apple => Icon(Icons.apple, size: size + 2, color: color),
      };
}

/// "كمّل بـ Google" (outlined, with the G mark) and "كمّل بـ Apple" (black, white in dark mode, as Apple's guidelines
/// ask). [busy] shows a spinner instead of the mark; [label] replaces "Continue with …" (e.g. "Confirm with Apple").
class ExternalProviderButton extends StatelessWidget {
  const ExternalProviderButton({super.key, required this.provider, required this.onPressed, this.busy = false, this.label});

  final ExternalProvider provider;
  final VoidCallback? onPressed;
  final bool busy;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = this.label ??
        switch (provider) {
          ExternalProvider.google => l10n.continueWithGoogle,
          ExternalProvider.apple => l10n.continueWithApple,
        };
    final dark = Theme.of(context).brightness == Brightness.dark;
    final appleBackground = dark ? Colors.white : Colors.black;
    final appleForeground = dark ? Colors.black : Colors.white;
    Widget icon(Color? color) => busy
        ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color))
        : ExternalProviderIcon(provider, color: color);

    return Semantics(
      button: true,
      label: busy ? '$label, ${l10n.loading}' : null,
      excludeSemantics: busy,
      child: switch (provider) {
        ExternalProvider.google => OutlinedButton.icon(
            onPressed: busy ? null : onPressed,
            icon: icon(null),
            label: Text(label),
          ),
        ExternalProvider.apple => FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: appleBackground,
              foregroundColor: appleForeground,
              disabledBackgroundColor: appleBackground.withValues(alpha: 0.5),
              disabledForegroundColor: appleForeground.withValues(alpha: 0.8),
            ),
            onPressed: busy ? null : onPressed,
            icon: icon(appleForeground),
            label: Text(label),
          ),
      },
    );
  }
}

/// The provider's mark alone in a small round button (Sign in): Google outlined, Apple black (white in dark mode). The
/// full "Continue with …" is its tooltip and its name for screen readers.
class ExternalProviderIconButton extends StatelessWidget {
  const ExternalProviderIconButton({super.key, required this.provider, required this.onPressed, this.busy = false});

  static const double size = 48;

  final ExternalProvider provider;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final label = switch (provider) {
      ExternalProvider.google => l10n.continueWithGoogle,
      ExternalProvider.apple => l10n.continueWithApple,
    };
    final apple = context.isDark ? Colors.white : Colors.black;
    final (background, foreground, side) = switch (provider) {
      ExternalProvider.google => (colors.surface, colors.textPrimary, BorderSide(color: colors.border)),
      ExternalProvider.apple => (apple, context.isDark ? Colors.black : Colors.white, BorderSide.none),
    };
    return IconButton(
      tooltip: busy ? '$label, ${l10n.loading}' : label,
      onPressed: busy ? null : onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(size),
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: busy ? 1 : 0.5),
        side: side,
        shape: const CircleBorder(),
      ),
      icon: busy
          ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: foreground))
          : ExternalProviderIcon(provider, size: 22, color: foreground),
    );
  }
}

/// The Google / Apple buttons of Welcome and Sign in (SPEC §9.2), and the "not linked yet" choice that follows a new
/// identity. Needs an [ExternalSignInCubit] above it.
class ExternalSignInButtons extends StatelessWidget {
  const ExternalSignInButtons({super.key, this.beforeStart, this.compact = false});

  /// Runs before a provider's sheet opens (Welcome marks itself as seen).
  final Future<void> Function()? beforeStart;

  /// Only the marks, in small round buttons side by side (Sign in, where the showcase needs the room).
  final bool compact;

  Future<void> _start(BuildContext context, ExternalProvider provider) async {
    final cubit = context.read<ExternalSignInCubit>();
    await beforeStart?.call();
    await cubit.start(provider);
  }

  Future<void> _askHowToContinue(BuildContext context) async {
    final cubit = context.read<ExternalSignInCubit>();
    final navigator = Navigator.of(context);
    final choice = await showExternalNotLinkedSheet(context);
    switch (choice) {
      case NotLinkedChoice.createAccount:
        await cubit.createAccount();
      case NotLinkedChoice.linkExisting:
        await navigator.push(MaterialPageRoute<void>(
          builder: (_) => BlocProvider.value(value: cubit, child: const LinkExternalAccountView()),
        ));
      case null:
        cubit.dismissNotLinked();
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ExternalSignInCubit, ExternalSignInState>(
        listenWhen: (a, b) => a.notLinked == null && b.notLinked != null,
        listener: (context, _) => _askHowToContinue(context),
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final (index, provider) in state.providers.indexed) ...[
                    if (index > 0) const SizedBox(width: ReadInSpace.s4),
                    ExternalProviderIconButton(
                      provider: provider,
                      busy: state.busy == provider,
                      onPressed: state.submitting ? null : () => _start(context, provider),
                    ),
                  ],
                ],
              )
            else
              for (final (index, provider) in state.providers.indexed) ...[
              if (index > 0) const SizedBox(height: ReadInSpace.s3),
              ExternalProviderButton(
                provider: provider,
                busy: state.busy == provider,
                onPressed: state.submitting ? null : () => _start(context, provider),
              ),
            ],
            if (state.failure case final failure?) ...[
              const SizedBox(height: ReadInSpace.s3),
              FailureBanner(failure: failure),
            ],
          ],
        ),
      );
}

enum NotLinkedChoice { createAccount, linkExisting }

/// `auth.external_not_linked` (SPEC §9.2): create a new account, or link the identity to an existing phone account.
Future<NotLinkedChoice?> showExternalNotLinkedSheet(BuildContext context) => showModalBottomSheet<NotLinkedChoice>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const ExternalNotLinkedSheet(),
    );

class ExternalNotLinkedSheet extends StatelessWidget {
  const ExternalNotLinkedSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.externalNotLinkedTitle, style: context.textTheme.titleLarge)),
          const SizedBox(height: ReadInSpace.s3),
          Text(l10n.externalNotLinkedBody, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: ReadInSpace.s5),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(NotLinkedChoice.createAccount),
            child: Text(l10n.externalCreateAccount),
          ),
          const SizedBox(height: ReadInSpace.s3),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(NotLinkedChoice.linkExisting),
            child: Text(l10n.externalLinkExisting),
          ),
        ],
      ),
    );
  }
}

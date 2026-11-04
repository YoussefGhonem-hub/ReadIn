import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/config/app_links.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/utils/link_opener.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/inputs/password_field.dart';
import '../../domain/entities/external_credential.dart';
import '../cubit/delete_account_cubit.dart';
import '../session/session_cubit.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/external_sign_in.dart';
import 'sign_in_page.dart';

class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => getIt<DeleteAccountCubit>()..load(context.read<SessionCubit>().state.me),
        child: const DeleteAccountView(),
      );
}

/// Delete account (SPEC F01, App Store 5.1.1(v)), immediate and final: what is deleted and what is kept, then "confirm
/// it's you", "I understand" and a last dialog. Once deleted, this device has forgotten the account and Sign in says so.
class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({super.key});

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// Sends the deletion. Once the account is gone the session has ended and the router is already leaving this screen,
  /// so the router is captured first: Sign in then says the account was deleted.
  Future<void> _delete(Future<bool> Function(DeleteAccountCubit cubit) attempt) async {
    final router = GoRouter.of(context);
    if (await attempt(context.read<DeleteAccountCubit>())) {
      router.go('/auth/sign-in', extra: const SignInArgs(accountDeleted: true));
    }
  }

  Future<void> _askOnce() async {
    final cubit = context.read<DeleteAccountCubit>();
    final confirmed = await showDeleteAccountDialog(context);
    if (!mounted) return;
    if (confirmed ?? false) {
      await _delete((cubit) => cubit.confirm());
    } else {
      cubit.cancelConfirmation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
      listenWhen: (a, b) => (!a.confirming && b.confirming) || (!a.sessionEnded && b.sessionEnded),
      listener: (context, state) {
        if (state.sessionEnded) {
          context.read<SessionCubit>().signOut(); // the session had already ended: the router leaves for Sign in
        } else if (state.confirming) {
          _askOnce();
        }
      },
      builder: (context, state) => PopScope(
        // Nothing leaves while it's being deleted; from "confirm it's you", back shows what happens again.
        canPop: state.step == DeleteAccountStep.review && !state.busy,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.read<DeleteAccountCubit>().back();
        },
        child: switch (state.step) {
          DeleteAccountStep.review => DeleteAccountReview(onContinue: context.read<DeleteAccountCubit>().proceed),
          DeleteAccountStep.confirm => _confirmStep(context, state),
        },
      ),
    );
  }

  Widget _confirmStep(BuildContext context, DeleteAccountState state) {
    final l10n = context.l10n;
    final cubit = context.read<DeleteAccountCubit>();
    final confirmedWith = state.confirmedWith;
    return AuthScaffold(
      title: l10n.confirmItsYou,
      subtitle: state.hasPassword ? l10n.deleteAccountPasswordBody : l10n.deleteAccountProviderBody,
      children: [
        if (state.failure case final failure?) ...[
          DeletionFailureBanner(failure: failure, onRetry: state.canRetry ? () => _delete((cubit) => cubit.retry()) : null),
          const SizedBox(height: ReadInSpace.s4),
        ],
        if (confirmedWith != null)
          ConfirmedWithBanner(provider: confirmedWith)
        else ...[
          if (state.hasPassword)
            PasswordField(
              controller: _password,
              enabled: !state.busy,
              textInputAction: TextInputAction.done,
              errorText: errorText(context, state.passwordError),
            ),
          if (state.providers.isNotEmpty) ...[
            if (state.hasPassword) ...[
              const SizedBox(height: ReadInSpace.s5),
              const OrDivider(),
              const SizedBox(height: ReadInSpace.s4),
            ],
            for (final (index, provider) in state.providers.indexed) ...[
              if (index > 0) const SizedBox(height: ReadInSpace.s3),
              ExternalProviderButton(
                provider: provider,
                label: switch (provider) {
                  ExternalProvider.google => l10n.confirmWithGoogle,
                  ExternalProvider.apple => l10n.confirmWithApple,
                },
                busy: state.busyProvider == provider,
                onPressed: state.busy ? null : () => cubit.confirmWith(provider),
              ),
            ],
          ] else if (!state.hasPassword && state.failure == null)
            // An Apple-only account on a device without Sign in with Apple (Android).
            const DeletionFailureBanner(failure: Failure(FailureCodes.authAppleUnavailable)),
        ],
        const SizedBox(height: ReadInSpace.s4),
        CheckboxListTile(
          value: state.understood,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l10n.deleteAccountConfirm),
          onChanged: state.busy ? null : (value) => cubit.setUnderstood(value ?? false),
        ),
        const SizedBox(height: ReadInSpace.s4),
        SubmitButton(
          label: l10n.deleteAccountButton,
          destructive: true,
          progressLabel: l10n.deletingAccount,
          submitting: state.submitting,
          onPressed: state.canDelete ? () => cubit.review(password: _password.text) : null,
        ),
      ],
    );
  }
}

/// Step 1, "what happens": what is deleted right away, what is kept and why, and that it can't be undone.
class DeleteAccountReview extends StatelessWidget {
  const DeleteAccountReview({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return AuthScaffold(
      title: l10n.deleteAccountTitle,
      children: [
        _DeletionNote(text: l10n.deleteAccountLead),
        const SizedBox(height: ReadInSpace.s6),
        _FactList(
          heading: l10n.deleteAccountDeletedHeading,
          icon: Icons.delete_outline_rounded,
          iconColor: colors.error,
          facts: [
            l10n.deleteAccountDeletedProfile,
            l10n.deleteAccountDeletedContact,
            l10n.deleteAccountDeletedSignIns,
            l10n.deleteAccountDeletedDrafts,
            l10n.deleteAccountDeletedActivity,
            l10n.deleteAccountDeletedDevices,
            l10n.deleteAccountDeletedSecurityLog,
          ],
        ),
        const SizedBox(height: ReadInSpace.s6),
        _FactList(
          heading: l10n.deleteAccountKeptHeading,
          icon: Icons.inventory_2_outlined,
          iconColor: colors.textSecondary,
          facts: [
            l10n.deleteAccountKeptPublished,
            l10n.deleteAccountKeptRecord,
            l10n.deleteAccountKeptBackups,
            l10n.deleteAccountKeptReviews,
          ],
        ),
        const SizedBox(height: ReadInSpace.s5),
        BidiText(l10n.deleteAccountAfter, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
        const SizedBox(height: ReadInSpace.s6),
        FilledButton(onPressed: onContinue, child: Text(l10n.continueAction)),
        const SizedBox(height: ReadInSpace.s2),
        const Center(child: DeleteByEmailButton()),
      ],
    );
  }
}

/// "This permanently deletes your ReadIn account…" in a danger callout.
class _DeletionNote extends StatelessWidget {
  const _DeletionNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(ReadInSpace.s4),
      decoration: BoxDecoration(color: colors.calloutDanger, borderRadius: BorderRadius.circular(ReadInRadius.md)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(Icons.warning_amber_rounded, color: colors.calloutDangerAccent, size: 22)),
          const SizedBox(width: ReadInSpace.s3),
          Expanded(
            child: BidiText(
              text,
              style: context.textTheme.bodyLarge?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// A heading and its facts, one per row, each after [icon].
class _FactList extends StatelessWidget {
  const _FactList({required this.heading, required this.icon, required this.iconColor, required this.facts});

  final String heading;
  final IconData icon;
  final Color iconColor;
  final List<String> facts;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(heading, style: context.textTheme.titleMedium)),
          for (final fact in facts)
            Padding(
              padding: const EdgeInsets.only(top: ReadInSpace.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: Icon(icon, color: iconColor, size: 20)),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(child: BidiText(fact, style: context.textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      );
}

/// "Delete by email instead": the public page with the email route, in the app's language.
class DeleteByEmailButton extends StatelessWidget {
  const DeleteByEmailButton({super.key});

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => openExternalLink(AppLinks.accountDeletion(Localizations.localeOf(context).languageCode)),
        child: Text(context.l10n.deleteAccountByEmail),
      );
}

/// "Confirmed with Google / Apple" once the provider's sheet answered.
class ConfirmedWithBanner extends StatelessWidget {
  const ConfirmedWithBanner({super.key, required this.provider});

  final ExternalProvider provider;

  @override
  Widget build(BuildContext context) => FormBanner(
        tone: BannerTone.success,
        message: switch (provider) {
          ExternalProvider.google => context.l10n.confirmedWithGoogle,
          ExternalProvider.apple => context.l10n.confirmedWithApple,
        },
      );
}

/// Why the account wasn't deleted, with Retry when sending it again can work, or the email route when Apple is needed
/// and this device can't show it.
class DeletionFailureBanner extends StatelessWidget {
  const DeletionFailureBanner({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = failure.code == FailureCodes.networkOffline ? l10n.deleteAccountOffline : localizeFailure(l10n, failure);
    return FormBanner(
      // Mixed Arabic / Latin ("ReadIn", "PDF"): isolated like BidiText.
      message: Bidi.isolateOppositeRuns(message, Directionality.of(context)),
      action: switch (onRetry) {
        final retry? => TextButton(onPressed: retry, child: Text(l10n.retry)),
        null when failure.code == FailureCodes.authAppleUnavailable => const DeleteByEmailButton(),
        null => null,
      },
    );
  }
}

/// "Delete your account forever?" with a red "Delete forever" and Cancel, which has the focus. True = delete.
Future<bool?> showDeleteAccountDialog(BuildContext context) {
  final l10n = context.l10n;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.colors;
      return AlertDialog(
        title: Text(l10n.deleteAccountDialogTitle),
        content: Text(l10n.deleteAccountDialogBody),
        actions: [
          TextButton(autofocus: true, onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteAccountDialogConfirm),
          ),
        ],
      );
    },
  );
}

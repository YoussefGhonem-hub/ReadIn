import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/inputs/password_field.dart';
import '../../../auth/domain/entities/external_credential.dart';
import '../../../auth/domain/entities/me.dart';
import '../../../auth/presentation/cubit/linked_accounts_cubit.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/external_sign_in.dart';

/// Settings → Account → "الحسابات المربوطة" (F18): Google and Apple with the linked email, "اربط" and "فك الربط".
/// Hidden when the server offers neither and none is linked. Needs a [LinkedAccountsCubit] above it.
class LinkedAccountsSection extends StatelessWidget {
  const LinkedAccountsSection({super.key});

  Future<void> _onChange(BuildContext context, LinkedAccountsState state) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<LinkedAccountsCubit>();
    if (state.awaitingPassword case final provider?) {
      final password = await showDialog<String>(
        context: context,
        builder: (_) => _ConfirmPasswordDialog(body: l10n.linkWithPasswordBody(provider.label)),
      );
      await cubit.confirmWithPassword(password);
    } else if (state.failure case final failure?) {
      messenger.showSnackBar(SnackBar(content: Text(localizeFailure(l10n, failure))));
    } else if (state.change case final change?) {
      final label = change.provider.label;
      messenger.showSnackBar(
        SnackBar(content: Text(change.linked ? l10n.providerLinked(label) : l10n.providerUnlinked(label))),
      );
    }
  }

  Future<void> _unlink(BuildContext context, ExternalProvider provider) async {
    final l10n = context.l10n;
    final cubit = context.read<LinkedAccountsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unlinkTitle(provider.label)),
        content: Text(l10n.unlinkBody(provider.label)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.unlinkConfirm)),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.unlink(provider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = context.select((SessionCubit c) => c.state.me);
    return BlocConsumer<LinkedAccountsCubit, LinkedAccountsState>(
      listenWhen: (a, b) =>
          (b.awaitingPassword != null && a.awaitingPassword == null) ||
          (b.failure != null && a.failure != b.failure) ||
          (b.change != null && a.change != b.change),
      listener: _onChange,
      builder: (context, state) {
        if (me == null) return const SizedBox.shrink();
        final rows = [
          for (final provider in ExternalProvider.values)
            if (state.providers.contains(provider) || me.externalLogin(provider) != null) provider,
        ];
        if (rows.isEmpty) return const SizedBox.shrink();
        final idle = state.busy == null && state.awaitingPassword == null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
              child: Semantics(header: true, child: Text(l10n.linkedAccounts, style: context.textTheme.titleSmall)),
            ),
            for (final provider in rows) ...[
              if (provider != rows.first) const Divider(),
              _LinkedAccountTile(
                provider: provider,
                login: me.externalLogin(provider),
                busy: state.busy == provider,
                onLink: idle && state.providers.contains(provider)
                    ? () => context.read<LinkedAccountsCubit>().link(provider, me)
                    : null,
                onUnlink: idle ? () => _unlink(context, provider) : null,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LinkedAccountTile extends StatelessWidget {
  const _LinkedAccountTile({
    required this.provider,
    required this.login,
    required this.busy,
    required this.onLink,
    required this.onUnlink,
  });

  final ExternalProvider provider;
  final ExternalLogin? login;
  final bool busy;
  final VoidCallback? onLink;
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final login = this.login;
    final email = login?.email;
    final subtitleStyle = context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox.square(
        dimension: 24,
        child: Center(child: ExternalProviderIcon(provider, color: colors.textPrimary)),
      ),
      title: Text(provider.label),
      subtitle: login == null
          ? Text(l10n.notLinked, style: subtitleStyle)
          : email == null
              ? null
              : Text(email, textDirection: TextDirection.ltr, style: subtitleStyle),
      trailing: busy
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : login != null
              ? TextButton(onPressed: onUnlink, child: Text(l10n.unlinkAction))
              : TextButton(onPressed: onLink, child: Text(l10n.linkAction)),
    );
  }
}

/// "أكد إنه انت": the password before linking a provider. Pops the password, or null when cancelled.
class _ConfirmPasswordDialog extends StatefulWidget {
  const _ConfirmPasswordDialog({required this.body});

  final String body;

  @override
  State<_ConfirmPasswordDialog> createState() => _ConfirmPasswordDialogState();
}

class _ConfirmPasswordDialogState extends State<_ConfirmPasswordDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_password.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.confirmItsYou),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.body),
          const SizedBox(height: ReadInSpace.s4),
          PasswordField(
            controller: _password,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: _confirm,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: _confirm, child: Text(l10n.confirmAction)),
      ],
    );
  }
}

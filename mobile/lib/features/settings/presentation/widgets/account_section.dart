import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/phone/phone_numbers.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../auth/presentation/session/session_cubit.dart';

/// Settings → Account (F18): the phone number (owner only) and "change number", password, PIN, sign out, sign out
/// of all devices and delete account.
class AccountSection extends StatefulWidget {
  const AccountSection({super.key});

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  bool _signingOut = false;
  bool _signingOutEverywhere = false;

  bool get _busy => _signingOut || _signingOutEverywhere;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    await context.read<SessionCubit>().signOut();
    if (mounted) setState(() => _signingOut = false);
  }

  Future<void> _signOutEverywhere() async {
    final l10n = context.l10n;
    final session = context.read<SessionCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOutEverywhere),
        content: Text(l10n.signOutEverywhereBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.signOutEverywhere)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _signingOutEverywhere = true);
    final failure = await session.signOutEverywhere();
    if (!mounted) return;
    setState(() => _signingOutEverywhere = false);
    messenger.showSnackBar(SnackBar(content: Text(failure == null ? l10n.signedOutEverywhere : localizeFailure(l10n, failure))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final phone = context.select((SessionCubit c) => c.state.me?.phoneNumber);

    Widget progress() => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.phone_iphone_rounded),
          title: Text(l10n.phoneNumberLabel),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (phone != null)
                Text(
                  PhoneNumbers.formatE164(phone),
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
                ),
              Text(l10n.phoneVisibleToYou, style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondary)),
            ],
          ),
          trailing: TextButton(
            onPressed: _busy ? null : () => context.push('/account/phone'),
            child: Text(l10n.changePhone),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.password_rounded),
          title: Text(l10n.changePassword),
          trailing: const Icon(Icons.chevron_right_rounded),
          enabled: !_busy,
          onTap: () => context.push('/account/password'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.pin_outlined),
          title: Text(l10n.changePin),
          trailing: const Icon(Icons.chevron_right_rounded),
          enabled: !_busy,
          onTap: () => context.push('/account/recovery-pin'),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout_rounded),
          title: Text(l10n.signOut),
          trailing: _signingOut ? progress() : null,
          enabled: !_busy,
          onTap: _signOut,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.devices_other_rounded),
          title: Text(l10n.signOutEverywhere),
          trailing: _signingOutEverywhere ? progress() : null,
          enabled: !_busy,
          onTap: _signOutEverywhere,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.delete_outline_rounded, color: colors.error),
          title: Text(l10n.deleteAccount, style: TextStyle(color: colors.error)),
          enabled: !_busy,
          onTap: () => context.push('/account/delete'),
        ),
      ],
    );
  }
}

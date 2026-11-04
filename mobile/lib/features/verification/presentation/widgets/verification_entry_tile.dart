import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../cubit/verification_cubit.dart';
import '../pages/verification_page.dart';

/// Settings → "Writer verification" (F19), signed in only: my status, and the page. The status is read again when
/// the page closes.
class VerificationEntryTile extends StatelessWidget {
  const VerificationEntryTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final state = context.watch<VerificationCubit>().state;
    final verifiedInSession = context.select((SessionCubit c) => c.state.me?.isVerified ?? false);
    final screen = state.screen;
    final verified = screen == VerificationScreen.approved || (screen == null && verifiedInSession);
    final subtitle = switch (screen) {
      VerificationScreen.approved => l10n.verificationStatusVerified,
      VerificationScreen.pending => l10n.verificationStatusPending,
      VerificationScreen.rejected => l10n.verificationStatusRejected,
      _ when verified => l10n.verificationStatusVerified,
      _ => l10n.verificationEntryHint,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(verified ? Icons.verified_rounded : Icons.verified_outlined, color: verified ? colors.success : null),
      title: Row(
        children: [
          Flexible(child: Text(l10n.verificationTitle)),
          if (verified) ...[const SizedBox(width: 6), const VerifiedMark(size: 16)],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: screen == VerificationScreen.rejected ? TextStyle(color: colors.calloutWarningAccent) : null,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () async {
        final cubit = context.read<VerificationCubit>();
        await context.push<void>(VerificationPage.path);
        if (!cubit.isClosed) unawaited(cubit.load());
      },
    );
  }
}

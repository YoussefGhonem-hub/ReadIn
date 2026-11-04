import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../auth/domain/entities/me.dart';
import '../../../profile/presentation/cubit/privacy_cubit.dart';
import 'preference_tiles.dart';

/// Settings → Privacy: "Who can mention me" (F18): everyone, people I follow, or nobody. Someone who may not mention
/// you can still type your `@username`, but it stays plain text and you aren't told. Applied at once and rolled back,
/// with the reason, when the API refuses it. Needs a [PrivacyCubit] above it.
class WhoCanMentionSelector extends StatelessWidget {
  const WhoCanMentionSelector({super.key});

  Future<void> _set(BuildContext context, MentionPolicy policy) async {
    final failure = await context.read<PrivacyCubit>().setWhoCanMention(policy);
    if (context.mounted) showActionFailure(context, failure);
  }

  static String label(AppLocalizations l10n, MentionPolicy policy) => switch (policy) {
        MentionPolicy.everyone => l10n.profileWhoCanMentionEveryone,
        MentionPolicy.following => l10n.profileWhoCanMentionFollowing,
        MentionPolicy.nobody => l10n.profileWhoCanMentionNobody,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<PrivacyCubit>().state;
    return PreferenceSection(
      title: l10n.profileWhoCanMention,
      child: RadioGroup<MentionPolicy>(
        groupValue: state.whoCanMention,
        onChanged: (policy) {
          if (policy != null) unawaited(_set(context, policy));
        },
        child: Column(
          children: [
            for (final policy in MentionPolicy.values)
              RadioListTile<MentionPolicy>(
                key: ValueKey('who-can-mention-${policy.wire}'),
                value: policy,
                title: Text(label(l10n, policy)),
                contentPadding: EdgeInsets.zero,
                // While saving, the choice shows the new value and ignores taps (no double submit).
                enabled: !state.pending,
              ),
          ],
        ),
      ),
    );
  }
}

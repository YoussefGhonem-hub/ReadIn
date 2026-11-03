import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n_x.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens.g.dart';

/// Soft prompt shown when a guest tries to interact (F01).
Future<void> showSignInPrompt(BuildContext context) {
  final l10n = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.signInPromptTitle, style: sheetContext.textTheme.titleLarge),
            const SizedBox(height: ReadInSpace.s2),
            Text(l10n.signInPromptBody, style: sheetContext.textTheme.bodyMedium?.copyWith(color: sheetContext.colors.textSecondary)),
            const SizedBox(height: ReadInSpace.s5),
            FilledButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push('/auth/sign-up');
              },
              child: Text(l10n.signUp),
            ),
            const SizedBox(height: ReadInSpace.s2),
            OutlinedButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push('/auth/sign-in');
              },
              child: Text(l10n.signIn),
            ),
          ],
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../../core/errors/failure.dart';
import '../../core/l10n/failure_messages.dart';
import '../../core/l10n/l10n_x.dart';

/// A short, translated message for an action that failed and was rolled back. Nothing for a cancelled request.
void showActionFailure(BuildContext context, Failure? failure) {
  if (failure == null || failure.code == FailureCodes.requestCancelled || !context.mounted) return;
  showActionMessage(context, localizeActionFailure(context.l10n, failure));
}

void showActionMessage(BuildContext context, String message, {SnackBarAction? action}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

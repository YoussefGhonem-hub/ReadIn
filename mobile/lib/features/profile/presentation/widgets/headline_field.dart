import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../domain/entities/profile_link.dart';

/// "المسمى" / "Title" (F14): optional, one line (line breaks and tabs can't be typed), mixed text in its own direction,
/// at most 120 characters with a counter in the last 20. Also on Complete profile.
class HeadlineField extends StatelessWidget {
  const HeadlineField({super.key, required this.controller, this.enabled = true, this.error, this.onChanged, this.textInputAction});

  final TextEditingController controller;
  final bool enabled;

  /// Already localized.
  final String? error;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  static const fieldKey = ValueKey('profile-headline-field');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BidiTextField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      maxLength: HeadlineRules.maxLength,
      counterWithin: HeadlineRules.counterWithin,
      maxLines: 1,
      textInputAction: textInputAction ?? TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\r\n\t\u2028\u2029]'))],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: l10n.profileHeadlineLabel,
        hintText: l10n.profileHeadlineHint,
        helperText: l10n.profileHeadlineHelper,
        prefixIcon: const Icon(Icons.badge_outlined),
        errorText: error,
        errorMaxLines: 2,
      ),
    );
  }
}

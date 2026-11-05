import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';

/// The comment box's emoji picker (F11), in place of the keyboard: the emoji go into [controller] at the caret, as
/// ordinary text. Themed with the app's tokens in light and dark; it follows the UI direction. Recently used emoji
/// come first (kept on the device by the package).
class CommentEmojiPicker extends StatelessWidget {
  const CommentEmojiPicker({super.key, required this.controller, this.height = defaultHeight});

  final TextEditingController controller;
  final double height;

  static const defaultHeight = 280.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    return Semantics(
      container: true,
      label: l10n.commentBoxEmoji,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.border))),
        child: EmojiPicker(
          textEditingController: controller,
          config: Config(
            height: height,
            // Search keywords exist in English here; Arabic falls back to them.
            locale: Localizations.localeOf(context),
            emojiTextStyle: const TextStyle(fontFamilyFallback: emojiFontFallback),
            customBackspaceIcon: Icon(Icons.backspace_outlined, color: colors.textSecondary),
            customSearchIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
            emojiViewConfig: EmojiViewConfig(
              columns: 8,
              emojiSizeMax: 28,
              backgroundColor: colors.surface,
              noRecents: Text(
                l10n.commentBoxEmojiNoRecents,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
            ),
            categoryViewConfig: CategoryViewConfig(
              backgroundColor: colors.surface,
              indicatorColor: colors.primary,
              iconColor: colors.textSecondary,
              iconColorSelected: colors.primary,
              backspaceColor: colors.textSecondary,
              dividerColor: colors.border,
            ),
            bottomActionBarConfig: BottomActionBarConfig(
              backgroundColor: colors.surface,
              buttonColor: colors.surface,
              buttonIconColor: colors.textSecondary,
            ),
            searchViewConfig: SearchViewConfig(
              backgroundColor: colors.surface,
              buttonIconColor: colors.textSecondary,
              hintText: l10n.commentBoxEmojiSearch,
              hintTextStyle: text.bodyMedium?.copyWith(color: colors.textSecondary),
              inputTextStyle: text.bodyMedium,
            ),
            skinToneConfig: SkinToneConfig(dialogBackgroundColor: colors.surfaceRaised, indicatorColor: colors.textSecondary),
          ),
        ),
      ),
    );
  }
}

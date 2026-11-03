import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n_x.dart';
import '../../../core/security/credential_rules.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens.g.dart';

/// Recovery PIN input (SPEC §9.4): [length] boxes (from `GET /auth/config`), always LTR, numeric keyboard, masked
/// with a show/hide toggle, paste support and Arabic-Indic/Persian digits converted. One real text field sits on top
/// of the boxes, so the keyboard, paste and screen readers behave like any text field.
class PinInput extends StatefulWidget {
  const PinInput({
    super.key,
    required this.controller,
    required this.label,
    this.length = RecoveryPinRules.defaultLength,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
  });

  final TextEditingController controller;
  final String label;
  final int length;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  /// Called when the last digit is entered.
  final ValueChanged<String>? onCompleted;

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  FocusNode? _ownFocus;
  bool _obscure = true;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(PinInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    widget.controller.removeListener(_rebuild);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  /// The real text field draws nothing (the theme's filled, outlined fields would show through): the boxes are the UI.
  static const _invisible = InputDecoration(
    filled: false,
    isCollapsed: true,
    counterText: '',
    contentPadding: EdgeInsets.zero,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
  );

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final pin = widget.controller.text;
    final hasError = widget.errorText != null;
    final active = _focus.hasFocus ? (pin.length < widget.length ? pin.length : widget.length - 1) : -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(widget.label, style: context.textTheme.labelLarge?.copyWith(color: colors.textSecondary)),
        ),
        const SizedBox(height: ReadInSpace.s2),
        Row(
          children: [
            Flexible(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Stack(
                  children: [
                    ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < widget.length; i++) ...[
                            if (i > 0) const SizedBox(width: ReadInSpace.s2),
                            _PinBox(
                              digit: i < pin.length ? (_obscure ? '•' : pin[i]) : '',
                              active: i == active,
                              error: hasError,
                              enabled: widget.enabled,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: Semantics(
                        label: l10n.pinSemantics(widget.label, pin.length, widget.length),
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focus,
                          autofocus: widget.autofocus,
                          enabled: widget.enabled,
                          obscureText: _obscure,
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr,
                          showCursor: false,
                          enableSuggestions: false,
                          autocorrect: false,
                          maxLength: widget.length,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          inputFormatters: [PinInputFormatter(widget.length)],
                          onChanged: _onChanged,
                          style: const TextStyle(color: Colors.transparent, fontSize: 1),
                          decoration: _invisible,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: _obscure ? l10n.showPin : l10n.hidePin,
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ],
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: ReadInSpace.s1),
          Text(widget.errorText!, style: context.textTheme.labelSmall?.copyWith(color: colors.error)),
        ],
      ],
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({required this.digit, required this.active, required this.error, required this.enabled});

  final String digit;
  final bool active;
  final bool error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor = error ? colors.error : (active ? colors.focusRing : colors.border);
    return AnimatedContainer(
      duration: ReadInMotion.fast,
      width: 52,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(ReadInRadius.md),
        border: Border.all(color: borderColor, width: active || error ? 2 : 1),
      ),
      child: Text(
        digit,
        style: context.textTheme.titleLarge?.copyWith(
          fontFamily: ReadInFonts.latin,
          color: enabled ? colors.textPrimary : colors.textSecondary,
        ),
      ),
    );
  }
}

/// Converts Arabic-Indic and Persian digits, keeps digits only and at most [length] of them (typing and paste).
class PinInputFormatter extends TextInputFormatter {
  PinInputFormatter(this.length);

  final int length;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = digitsOnly(newValue.text);
    if (digits.length > length) digits = digits.substring(0, length);
    return TextEditingValue(text: digits, selection: TextSelection.collapsed(offset: digits.length));
  }
}

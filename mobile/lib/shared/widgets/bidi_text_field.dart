import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/bidi/bidi.dart';

/// [TextField] whose direction follows its content (`dir="auto"`, SPEC §14.2):
/// the first strong character decides, so an English title typed in the
/// Arabic UI is laid out LTR and vice versa. Empty fields follow the UI.
class BidiTextField extends StatefulWidget {
  const BidiTextField({
    super.key,
    required this.controller,
    this.decoration = const InputDecoration(),
    this.onChanged,
    this.maxLength,
    this.counterWithin,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.style,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

  /// With [maxLength]: show the character counter only when this close to the limit (long limits such as 5000
  /// would otherwise show a permanent "0/5000"). Null keeps the standard always-on counter.
  final int? counterWithin;

  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final TextStyle? style;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<BidiTextField> createState() => _BidiTextFieldState();
}

class _BidiTextFieldState extends State<BidiTextField> {
  TextDirection? _direction;

  @override
  void initState() {
    super.initState();
    _direction = Bidi.detect(widget.controller.text);
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(BidiTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
      _onText();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() {
    final direction = Bidi.detect(widget.controller.text);
    if (direction != _direction) setState(() => _direction = direction);
  }

  Widget? _nearLimitCounter(BuildContext context, {required int currentLength, required bool isFocused, required int? maxLength}) =>
      maxLength != null && currentLength >= maxLength - widget.counterWithin!
          ? Text('$currentLength/$maxLength', textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.bodySmall)
          : null;

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        decoration: widget.decoration,
        onChanged: widget.onChanged,
        maxLength: widget.maxLength,
        buildCounter: widget.counterWithin == null ? null : _nearLimitCounter,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType ?? (widget.maxLines == 1 ? TextInputType.text : TextInputType.multiline),
        textInputAction: widget.textInputAction,
        enabled: widget.enabled,
        style: widget.style,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        textDirection: _direction ?? Directionality.of(context),
      );
}

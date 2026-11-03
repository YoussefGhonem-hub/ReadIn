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

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        decoration: widget.decoration,
        onChanged: widget.onChanged,
        maxLength: widget.maxLength,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n_x.dart';
import '../../../core/phone/countries.dart';
import '../../../core/phone/phone_numbers.dart';
import '../../../core/security/credential_rules.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens.g.dart';
import 'country_flag.dart';
import 'country_picker.dart';

/// The phone field's state: the country and what was typed. [e164] is the number the API receives (SPEC §9.4).
class PhoneFieldController extends ChangeNotifier {
  PhoneFieldController({String? iso2, String? e164})
      : _iso2 = Countries.byIso2(iso2)?.iso2 ?? Countries.defaultIso2 {
    text.addListener(notifyListeners);
    if (e164 != null && e164.isNotEmpty) setE164(e164);
  }

  final TextEditingController text = TextEditingController();
  String _iso2;

  Country get country => Countries.byIso2(_iso2) ?? Countries.fallback;

  set country(Country value) {
    if (value.iso2 == _iso2) return;
    _iso2 = value.iso2;
    if (!PhoneNumbers.looksInternational(text.text)) {
      _setText(PhoneNumbers.formatNational(PhoneNumbers.normalizeNational(text.text, _iso2), _iso2));
    }
    notifyListeners();
  }

  bool get isEmpty => digitsOnly(text.text).isEmpty;

  /// E.164 when the input is a valid mobile number, otherwise null.
  String? get e164 {
    final value = text.text;
    if (PhoneNumbers.looksInternational(value)) {
      final parts = PhoneNumbers.parseInternational(value);
      return parts == null ? null : PhoneNumbers.toE164(parts.national, parts.iso2);
    }
    return PhoneNumbers.toE164(digitsOnly(value), _iso2);
  }

  /// Shows a stored number (pre-filled sign in, forgot password).
  void setE164(String e164) {
    final parts = PhoneNumbers.split(e164);
    if (parts == null || Countries.byIso2(parts.iso2) == null) {
      _setText(e164);
      return;
    }
    _iso2 = parts.iso2;
    _setText(PhoneNumbers.formatNational(parts.national, parts.iso2));
    notifyListeners();
  }

  void _setText(String value) =>
      text.value = TextEditingValue(text: value, selection: TextSelection.collapsed(offset: value.length));

  /// Runs on every edit: converts digits, follows pasted international numbers to their country, strips the trunk
  /// prefix and formats as you type, keeping the caret after the same digit.
  TextEditingValue format(TextEditingValue oldValue, TextEditingValue newValue) {
    var raw = toAsciiDigits(newValue.text);
    var caret = newValue.selection.isValid ? newValue.selection.extentOffset.clamp(0, raw.length) : raw.length;

    if (PhoneNumbers.looksInternational(raw)) {
      final parts = PhoneNumbers.parseInternational(raw);
      if (parts != null && Countries.byIso2(parts.iso2) != null && PhoneNumbers.toE164(parts.national, parts.iso2) != null) {
        _iso2 = parts.iso2; // the text change that follows notifies listeners
        final formatted = PhoneNumbers.formatNational(parts.national, parts.iso2);
        return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
      }
      // Still typing "+…": keep it as it is until it becomes a valid number.
      final trimmed = raw.trimLeft();
      final kept = trimmed.startsWith('+') ? '+${digitsOnly(trimmed)}' : digitsOnly(trimmed);
      return TextEditingValue(text: kept, selection: TextSelection.collapsed(offset: kept.length));
    }

    // Backspace over a separator removes the digit before it, otherwise formatting would put it straight back.
    final oldDigits = digitsOnly(oldValue.text);
    if (raw.length < oldValue.text.length && digitsOnly(raw) == oldDigits && caret > 0) {
      final before = digitsOnly(raw.substring(0, caret));
      if (before.isNotEmpty) {
        final cut = _offsetAfterDigits(raw, before.length) - 1;
        raw = raw.substring(0, cut) + raw.substring(cut + 1);
        caret = cut;
      }
    }

    final allDigits = digitsOnly(raw);
    final national = PhoneNumbers.normalizeNational(raw, _iso2);
    final stripped = allDigits.startsWith(national) ? 0 : allDigits.indexOf(national).clamp(0, allDigits.length);
    final digitsBeforeCaret = (digitsOnly(raw.substring(0, caret.clamp(0, raw.length))).length - stripped).clamp(0, national.length);
    final formatted = PhoneNumbers.formatNational(national, _iso2);
    final offset = digitsBeforeCaret >= national.length ? formatted.length : _offsetAfterDigits(formatted, digitsBeforeCaret);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: offset));
  }

  static int _offsetAfterDigits(String text, int count) {
    if (count <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < text.length; i++) {
      final c = text.codeUnitAt(i);
      if (c >= 0x30 && c <= 0x39 && ++seen == count) return i + 1;
    }
    return text.length;
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  _PhoneInputFormatter(this._controller);

  final PhoneFieldController _controller;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      _controller.format(oldValue, newValue);
}

/// Phone field + country picker (SPEC §9.4): always LTR (country code on the left of the number), the label follows
/// the UI language. Errors are shown from [errorText]; the form decides when.
class PhoneField extends StatefulWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.label,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
  });

  final PhoneFieldController controller;
  final String? label;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;
  final VoidCallback? onChanged;

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late _PhoneInputFormatter _formatter = _PhoneInputFormatter(widget.controller);
  late String _iso2 = widget.controller.country.iso2;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(PhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
      _formatter = _PhoneInputFormatter(widget.controller);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final iso2 = widget.controller.country.iso2;
    if (iso2 != _iso2) setState(() => _iso2 = iso2);
    widget.onChanged?.call();
  }

  Future<void> _pickCountry() async {
    final picked = await showCountryPicker(context, selected: widget.controller.country);
    if (picked != null) widget.controller.country = picked;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final country = widget.controller.country;
    final example = PhoneNumbers.formatNational(PhoneNumbers.normalizeNational(country.exampleNational, country.iso2), country.iso2);
    return Row(
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CountryButton(country: country, hasError: widget.errorText != null, onTap: widget.enabled ? _pickCountry : null),
        const SizedBox(width: ReadInSpace.s2),
        Expanded(
          child: TextField(
            controller: widget.controller.text,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            textInputAction: widget.textInputAction,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [_formatter],
            onSubmitted: (_) => widget.onSubmitted?.call(),
            decoration: InputDecoration(
              labelText: widget.label ?? l10n.phoneLabel,
              hintText: example,
              hintTextDirection: TextDirection.ltr,
              errorText: widget.errorText,
              errorMaxLines: 3,
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryButton extends StatelessWidget {
  const _CountryButton({required this.country, required this.hasError, required this.onTap});

  final Country country;
  final bool hasError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final radius = BorderRadius.circular(ReadInRadius.md);
    return Semantics(
      button: true,
      label: context.l10n.countryButtonSemantics(country.name(lang), country.dialCode),
      excludeSemantics: true,
      child: Material(
        // On `surface`, like the text inputs beside it.
        color: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: hasError ? colors.error : colors.border)),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                children: [
                  CountryFlagIcon(country.iso2),
                  const SizedBox(width: ReadInSpace.s2),
                  Text(
                    '+${country.dialCode}',
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.bodyLarge?.copyWith(fontFamily: ReadInFonts.latin),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: colors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

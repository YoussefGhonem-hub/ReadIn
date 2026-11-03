import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_x.dart';
import '../../../core/security/credential_rules.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens.g.dart';

/// Password field (SPEC §9.4): show/hide toggle, always LTR, password-manager autofill hints.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label,
    this.errorText,
    this.isNew = false,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? label;
  final String? errorText;

  /// A password being chosen: `newPassword` autofill, so password managers offer to generate and save it.
  final bool isNew;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.visiblePassword,
      textDirection: TextDirection.ltr,
      textInputAction: widget.textInputAction,
      autofillHints: [widget.isNew ? AutofillHints.newPassword : AutofillHints.password],
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: widget.label ?? l10n.password,
        errorText: widget.errorText,
        errorMaxLines: 3,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

/// Strength bar + label under a new password. Advisory only: the rules decide what's accepted.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password, this.policy = const PasswordPolicy()});

  final String password;
  final PasswordPolicy policy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final strength = PasswordRules.strength(password, policy: policy);
    final (filled, color, label) = switch (strength) {
      PasswordStrength.empty => (0, colors.border, ''),
      PasswordStrength.weak => (1, colors.error, l10n.strengthWeak),
      PasswordStrength.fair => (2, colors.accent, l10n.strengthFair),
      PasswordStrength.good => (3, colors.primary, l10n.strengthGood),
      PasswordStrength.strong => (4, colors.success, l10n.strengthStrong),
    };
    return Semantics(
      label: strength == PasswordStrength.empty ? null : l10n.passwordStrength(label),
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: ReadInMotion.fast,
                height: 4,
                decoration: BoxDecoration(
                  color: i < filled ? color : colors.border,
                  borderRadius: BorderRadius.circular(ReadInRadius.chip),
                ),
              ),
            ),
            if (i < 3) const SizedBox(width: ReadInSpace.s1),
          ],
          const SizedBox(width: ReadInSpace.s3),
          SizedBox(
            width: 64,
            child: Text(label, style: context.textTheme.labelSmall?.copyWith(color: color), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

/// The live rules checklist (8+ characters, a letter, a digit), from `GET /auth/config`.
class PasswordRulesChecklist extends StatelessWidget {
  const PasswordRulesChecklist({super.key, required this.password, this.policy = const PasswordPolicy()});

  final String password;
  final PasswordPolicy policy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rules = [
      (l10n.ruleMinLength(policy.minLength), password.length >= policy.minLength),
      if (policy.requireLetter) (l10n.ruleLetter, PasswordRules.hasLetter(password)),
      if (policy.requireDigit) (l10n.ruleDigit, PasswordRules.hasDigit(password)),
    ];
    return Wrap(
      spacing: ReadInSpace.s4,
      runSpacing: ReadInSpace.s1,
      children: [for (final (label, met) in rules) _RuleChip(label: label, met: met)],
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final color = met ? colors.success : colors.textSecondary;
    return Semantics(
      label: '$label: ${met ? l10n.ruleMet : l10n.ruleNotMet}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: color),
          const SizedBox(width: ReadInSpace.s1),
          Text(label, style: context.textTheme.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// A new password with its strength meter and rules checklist, plus the confirmation field.
class NewPasswordFields extends StatelessWidget {
  const NewPasswordFields({
    super.key,
    required this.password,
    required this.confirm,
    this.policy = const PasswordPolicy(),
    this.passwordLabel,
    this.passwordError,
    this.confirmError,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController password;
  final TextEditingController confirm;
  final PasswordPolicy policy;
  final String? passwordLabel;
  final String? passwordError;
  final String? confirmError;
  final bool enabled;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PasswordField(controller: password, label: passwordLabel, errorText: passwordError, isNew: true, enabled: enabled),
        const SizedBox(height: ReadInSpace.s2),
        ListenableBuilder(
          listenable: password,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordStrengthMeter(password: password.text, policy: policy),
              const SizedBox(height: ReadInSpace.s2),
              PasswordRulesChecklist(password: password.text, policy: policy),
            ],
          ),
        ),
        const SizedBox(height: ReadInSpace.s4),
        PasswordField(
          controller: confirm,
          label: l10n.confirmPasswordLabel,
          errorText: confirmError,
          isNew: true,
          enabled: enabled,
          textInputAction: TextInputAction.done,
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }
}

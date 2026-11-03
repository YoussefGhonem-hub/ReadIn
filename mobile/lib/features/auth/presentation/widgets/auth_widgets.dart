import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_logo.dart';

/// Shared layout for auth screens: logo, title, form, footer.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.children, this.footer});

  final String title;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s6),
            children: [
              const Align(alignment: AlignmentDirectional.centerStart, child: AppLogo()),
              const SizedBox(height: ReadInSpace.s5),
              Text(title, style: context.textTheme.headlineMedium),
              const SizedBox(height: ReadInSpace.s5),
              ...children,
              if (footer != null) ...[const SizedBox(height: ReadInSpace.s5), footer!],
            ],
          ),
        ),
      );
}

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textDirection: TextDirection.ltr,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.alternate_email_rounded)),
      validator: (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) return l10n.fieldRequired;
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return l10n.invalidEmail;
        return null;
      },
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.controller, this.isNew = false, this.onSubmitted});

  final TextEditingController controller;

  /// New passwords must be ≥ 8 characters.
  final bool isNew;
  final VoidCallback? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textDirection: TextDirection.ltr,
      autofillHints: [widget.isNew ? AutofillHints.newPassword : AutofillHints.password],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: l10n.password,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (v) {
        final value = v ?? '';
        if (value.isEmpty) return l10n.fieldRequired;
        if (widget.isNew && value.length < 8) return l10n.passwordTooShort;
        return null;
      },
    );
  }
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key, required this.label, required this.submitting, required this.onPressed});

  final String label;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: submitting ? null : onPressed,
        child: submitting
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
            : Text(label),
      );
}

/// Google / Apple buttons — disabled until provider setup lands (F01).
class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3),
            child: Text(l10n.socialSignInSoon, style: context.textTheme.labelSmall),
          ),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: ReadInSpace.s3),
        OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.g_mobiledata_rounded), label: Text(l10n.continueWithGoogle)),
        const SizedBox(height: ReadInSpace.s2),
        OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.apple), label: Text(l10n.continueWithApple)),
      ],
    );
  }
}

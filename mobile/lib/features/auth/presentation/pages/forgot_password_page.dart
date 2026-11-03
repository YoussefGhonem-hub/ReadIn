import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/inputs/password_field.dart';
import '../../../../shared/widgets/inputs/phone_field.dart';
import '../../../../shared/widgets/inputs/pin_input.dart';
import '../cubit/forgot_password_cubit.dart';
import '../cubit/form_support.dart';
import '../widgets/auth_widgets.dart';
import 'sign_in_page.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key, this.phone});

  /// Pre-filled from Sign in.
  final String? phone;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<ForgotPasswordCubit>()..loadConfig(),
        child: ForgotPasswordView(phone: phone),
      );
}

/// Forgot password (SPEC §9.2): 1. phone + recovery PIN → 2. new password → back to Sign in with the number filled in.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key, this.phone});

  final String? phone;

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final _phone = PhoneFieldController(iso2: initialPhoneCountry(), e164: widget.phone);
  final _pin = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    for (final c in [_pin, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  ForgotPasswordCubit get _cubit => context.read<ForgotPasswordCubit>();

  void _verify() => _cubit.submitVerification(phoneE164: _phone.e164, phoneEmpty: _phone.isEmpty, pin: _pin.text);

  void _save() => _cubit.submitNewPassword(password: _password.text, confirmPassword: _confirm.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      listenWhen: (a, b) => a.step != b.step,
      listener: (context, state) {
        if (state.step == ForgotStep.done) {
          // Back to the Sign in screen that opened this one, with the number and the "password changed" banner.
          if (context.canPop()) {
            context.pop(state.phone);
          } else {
            context.go('/auth/sign-in', extra: SignInArgs(phone: state.phone, passwordReset: true));
          }
        } else if (state.step == ForgotStep.verify) {
          _pin.clear(); // expired reset: the PIN is asked again
        }
      },
      builder: (context, state) {
        final onPassword = state.step != ForgotStep.verify;
        final busy = state.submitting;
        return PopScope(
          canPop: state.step != ForgotStep.newPassword, // back from step 2 returns to step 1
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _cubit.restart();
          },
          child: AuthScaffold(
            header: StepHeader(current: onPassword ? 2 : 1, total: 2),
            title: onPassword ? l10n.forgotStep2Title : l10n.forgotTitle,
            subtitle: onPassword ? l10n.forgotStep2Body : l10n.forgotStep1Body,
            leading: onPassword ? BackButton(onPressed: _cubit.restart) : null,
            children: [
              if (state.failure case final failure?) ...[
                FailureBanner(failure: failure),
                const SizedBox(height: ReadInSpace.s4),
              ],
              if (!onPassword) ...[
                PhoneField(controller: _phone, enabled: !busy, errorText: errorText(context, state.errors[Fields.phone])),
                const SizedBox(height: ReadInSpace.s5),
                PinInput(
                  controller: _pin,
                  label: l10n.pinLabel,
                  length: state.config.pinLength,
                  enabled: !busy,
                  errorText: errorText(context, state.errors[Fields.pin]),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(onPressed: () => showContactSupportSheet(context), child: Text(l10n.forgotPin)),
                ),
                const SizedBox(height: ReadInSpace.s4),
                SubmitButton(label: l10n.continueAction, submitting: busy, onPressed: _verify),
              ] else ...[
                AutofillGroup(
                  child: NewPasswordFields(
                    password: _password,
                    confirm: _confirm,
                    policy: state.config.password,
                    passwordLabel: l10n.newPasswordLabel,
                    enabled: !busy,
                    passwordError: errorText(context, state.errors[Fields.password]),
                    confirmError: errorText(context, state.errors[Fields.confirmPassword]),
                    onSubmitted: _save,
                  ),
                ),
                const SizedBox(height: ReadInSpace.s5),
                SubmitButton(label: l10n.save, submitting: busy, onPressed: _save),
              ],
            ],
          ),
        );
      },
    );
  }
}

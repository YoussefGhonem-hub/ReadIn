import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/inputs/password_field.dart';
import '../../../../shared/widgets/inputs/phone_field.dart';
import '../../../../shared/widgets/inputs/pin_input.dart';
import '../../../legal/presentation/widgets/legal_links.dart';
import '../cubit/form_support.dart';
import '../cubit/sign_up_cubit.dart';
import '../widgets/auth_widgets.dart';
import 'sign_in_page.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<SignUpCubit>()..loadConfig(),
        child: const SignUpView(),
      );
}

/// Create account, "خطوة 1 من 3" (SPEC §9.2): phone + password → recovery PIN → confirm the number.
class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  late final _phone = PhoneFieldController(iso2: initialPhoneCountry());
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _pin = TextEditingController();
  final _confirmPin = TextEditingController();

  /// «أوافق على شروط الاستخدام وقواعد المجتمع» (F37): sign up goes on only once it is ticked.
  bool _agreed = false;

  @override
  void dispose() {
    for (final c in [_password, _confirmPassword, _pin, _confirmPin]) {
      c.dispose();
    }
    _phone.dispose();
    super.dispose();
  }

  SignUpCubit get _cubit => context.read<SignUpCubit>();

  void _submitCredentials() => _cubit.submitCredentials(
        phoneE164: _phone.e164,
        phoneEmpty: _phone.isEmpty,
        password: _password.text,
        confirmPassword: _confirmPassword.text,
        acceptedTerms: _agreed,
      );

  void _submitPin() => _cubit.submitPin(pin: _pin.text, confirmPin: _confirmPin.text);

  Future<void> _confirmNumber(String phone) async {
    final cubit = _cubit;
    final answer = await showConfirmNumberDialog(context, phoneE164: phone, confirmLabel: context.l10n.confirmNumberYes);
    switch (answer) {
      case true:
        await cubit.register();
      case false:
        cubit.editNumber();
      case null:
        cubit.cancelConfirmation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SignUpCubit, SignUpState>(
      listenWhen: (a, b) => (!a.confirming && b.confirming) || (a.status != b.status && b.status == FormStatus.success),
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          TextInput.finishAutofillContext(); // the router continues to Complete profile
        } else if (state.confirming && state.phone != null) {
          _confirmNumber(state.phone!);
        }
      },
      builder: (context, state) {
        final onPin = state.step == SignUpStep.pin;
        return PopScope(
          canPop: !onPin,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _cubit.back();
          },
          child: AuthScaffold(
            header: StepHeader(current: onPin ? 2 : 1, total: 3),
            title: onPin ? l10n.pinStepTitle : l10n.signUpHeading,
            subtitle: onPin ? l10n.pinStepBody : l10n.signUpCredentialsBody,
            leading: onPin ? BackButton(onPressed: _cubit.back) : null,
            footer: onPin
                ? null
                : Center(
                    child: TextButton(
                      onPressed: () => context.pushReplacement('/auth/sign-in'),
                      child: Text(l10n.welcomeSignIn),
                    ),
                  ),
            children: [
              if (state.failure case final failure?) ...[
                FailureBanner(failure: failure),
                const SizedBox(height: ReadInSpace.s4),
              ],
              if (onPin) ..._pinStep(context, state) else ..._credentialsStep(context, state),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _credentialsStep(BuildContext context, SignUpState state) {
    final l10n = context.l10n;
    final busy = state.submitting;
    return [
      AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PhoneField(controller: _phone, enabled: !busy, errorText: errorText(context, state.errors[Fields.phone])),
            if (state.phoneTaken)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  icon: const Icon(Icons.login_rounded),
                  label: Text(l10n.signIn),
                  onPressed: () => context.pushReplacement('/auth/sign-in', extra: SignInArgs(phone: state.phone ?? _phone.e164)),
                ),
              ),
            const SizedBox(height: ReadInSpace.s4),
            NewPasswordFields(
              password: _password,
              confirm: _confirmPassword,
              policy: state.config.password,
              enabled: !busy,
              passwordError: errorText(context, state.errors[Fields.password]),
              confirmError: errorText(context, state.errors[Fields.confirmPassword]),
              onSubmitted: _submitCredentials,
            ),
          ],
        ),
      ),
      const SizedBox(height: ReadInSpace.s3),
      TermsAgreement(
        value: _agreed,
        enabled: !busy,
        errorText: _agreed ? null : errorText(context, state.errors[Fields.terms]),
        onChanged: (on) => setState(() => _agreed = on),
      ),
      const SizedBox(height: ReadInSpace.s4),
      SubmitButton(label: l10n.next, submitting: busy, onPressed: _submitCredentials),
    ];
  }

  List<Widget> _pinStep(BuildContext context, SignUpState state) {
    final l10n = context.l10n;
    final busy = state.submitting;
    return [
      PinInput(
        controller: _pin,
        label: l10n.pinLabel,
        length: state.config.pinLength,
        enabled: !busy,
        errorText: errorText(context, state.errors[Fields.pin]),
        onChanged: _cubit.pinChanged,
      ),
      const SizedBox(height: ReadInSpace.s5),
      PinInput(
        controller: _confirmPin,
        label: l10n.confirmPinLabel,
        length: state.config.pinLength,
        enabled: !busy,
        errorText: errorText(context, state.errors[Fields.confirmPin]),
      ),
      const SizedBox(height: ReadInSpace.s6),
      SubmitButton(label: l10n.continueAction, submitting: busy, onPressed: _submitPin),
    ];
  }
}

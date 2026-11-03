import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/phone/countries.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/inputs/password_field.dart';
import '../../../../shared/widgets/inputs/phone_field.dart';
import '../cubit/form_support.dart';
import '../cubit/sign_in_cubit.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/dev_login_panel.dart';

/// Arguments of the Sign in route: the number to pre-fill and whether a password was just reset.
class SignInArgs {
  const SignInArgs({this.phone, this.passwordReset = false});

  final String? phone;
  final bool passwordReset;
}

/// The phone field's first country (last used → device region → Egypt).
String? initialPhoneCountry() => getIt.isRegistered<PhoneCountryMemory>() ? getIt<PhoneCountryMemory>().initial() : null;

class SignInPage extends StatelessWidget {
  const SignInPage({super.key, this.args = const SignInArgs()});

  final SignInArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<SignInCubit>(),
        child: SignInView(args: args, showDevLogin: !kReleaseMode && DevLogin.available),
      );
}

/// Sign in (SPEC §9.2): phone, password, "forgot password", one generic error for a wrong number or password.
class SignInView extends StatefulWidget {
  const SignInView({super.key, this.args = const SignInArgs(), this.showDevLogin = false, this.alternatives = const []});

  final SignInArgs args;
  final bool showDevLogin;

  /// Other ways to sign in (e.g. Google / Apple buttons), shown under the phone sign in after an "أو" divider.
  final List<Widget> alternatives;

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  late final _phone = PhoneFieldController(iso2: initialPhoneCountry(), e164: widget.args.phone);
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  late bool _passwordReset = widget.args.passwordReset;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() => context.read<SignInCubit>().submit(
        phoneE164: _phone.e164,
        phoneEmpty: _phone.isEmpty,
        password: _password.text,
      );

  /// Forgot password returns the number it reset; the banner then says to sign in with the new password.
  Future<void> _forgotPassword() async {
    final phone = await context.push<String>('/auth/forgot-password', extra: _phone.e164);
    if (phone == null || !mounted) return;
    _phone.setE164(phone);
    _password.clear();
    setState(() => _passwordReset = true);
    _passwordFocus.requestFocus();
  }

  Future<void> _openDevLogin() async {
    if (kReleaseMode) return; // constant: release builds drop the dev panel (SPEC §18.3)
    final user = await showDevLoginSheet(context);
    if (user == null || !mounted) return;
    _phone.setE164(user.phone);
    if (DevLogin.demoPassword.isNotEmpty) {
      _password.text = DevLogin.demoPassword;
      _submit();
    } else {
      _password.clear();
      _passwordFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SignInCubit, SignInState>(
      listenWhen: (a, b) => a.status != b.status && b.status == FormStatus.success,
      listener: (_, _) => TextInput.finishAutofillContext(), // offer to save the password; the router moves on
      builder: (context, state) {
        final busy = state.submitting;
        return AuthScaffold(
          showLogo: true,
          title: l10n.signInTitle,
          subtitle: l10n.signInSubtitle,
          footer: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.noAccount, style: context.textTheme.bodyMedium),
              TextButton(onPressed: () => context.pushReplacement('/auth/sign-up'), child: Text(l10n.createAccountLink)),
            ],
          ),
          children: [
            if (_passwordReset && state.failure == null) ...[
              FormBanner(message: l10n.passwordResetBanner, tone: BannerTone.success),
              const SizedBox(height: ReadInSpace.s4),
            ],
            if (state.failure case final failure?) ...[
              FailureBanner(failure: failure),
              const SizedBox(height: ReadInSpace.s4),
            ],
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PhoneField(
                    controller: _phone,
                    enabled: !busy,
                    errorText: errorText(context, state.errors[Fields.phone]),
                    onSubmitted: _passwordFocus.requestFocus,
                  ),
                  const SizedBox(height: ReadInSpace.s4),
                  PasswordField(
                    controller: _password,
                    focusNode: _passwordFocus,
                    enabled: !busy,
                    errorText: errorText(context, state.errors[Fields.password]),
                    textInputAction: TextInputAction.done,
                    onSubmitted: _submit,
                  ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: busy ? null : _forgotPassword,
                child: Text(l10n.forgotPassword),
              ),
            ),
            const SizedBox(height: ReadInSpace.s2),
            // The sign-in actions: the phone sign in first, then any alternatives under "أو".
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SubmitButton(label: l10n.signIn, submitting: busy, onPressed: _submit),
                if (widget.alternatives.isNotEmpty) ...[
                  const SizedBox(height: ReadInSpace.s5),
                  const OrDivider(),
                  const SizedBox(height: ReadInSpace.s4),
                  ...widget.alternatives,
                ],
              ],
            ),
            if (!kReleaseMode && widget.showDevLogin) ...[
              const SizedBox(height: ReadInSpace.s4),
              OutlinedButton.icon(
                icon: Icon(Icons.developer_mode_rounded, color: context.colors.textSecondary),
                label: Text(l10n.devLoginOpen),
                onPressed: busy ? null : _openDevLogin,
              ),
            ],
          ],
        );
      },
    );
  }
}

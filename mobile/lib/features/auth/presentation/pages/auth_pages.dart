import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../cubit/auth_form_cubit.dart';
import '../widgets/auth_widgets.dart';

void _showFailure(BuildContext context, AuthFormState state) {
  if (state.status == AuthFormStatus.failure && state.failure != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizeFailure(context.l10n, state.failure!))));
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => getIt<AuthFormCubit>(),
      child: BlocConsumer<AuthFormCubit, AuthFormState>(
        listener: (context, state) {
          _showFailure(context, state);
          if (state.status == AuthFormStatus.success) context.go('/home');
        },
        builder: (context, state) {
          void submit() {
            if (_form.currentState!.validate()) {
              context.read<AuthFormCubit>().signIn(email: _email.text, password: _password.text);
            }
          }

          return AuthScaffold(
            title: l10n.signInTitle,
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.noAccount, style: context.textTheme.bodyMedium),
                TextButton(onPressed: () => context.pushReplacement('/auth/sign-up'), child: Text(l10n.signUp)),
              ],
            ),
            children: [
              Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EmailField(controller: _email),
                      const SizedBox(height: ReadInSpace.s3),
                      PasswordField(controller: _password, onSubmitted: submit),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(onPressed: () => context.push('/auth/forgot-password'), child: Text(l10n.forgotPassword)),
                      ),
                      const SizedBox(height: ReadInSpace.s2),
                      SubmitButton(label: l10n.signIn, submitting: state.submitting, onPressed: submit),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ReadInSpace.s5),
              const SocialSignInButtons(),
            ],
          );
        },
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => getIt<AuthFormCubit>(),
      child: BlocConsumer<AuthFormCubit, AuthFormState>(
        listener: (context, state) {
          _showFailure(context, state);
          if (state.status == AuthFormStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.verifyEmailSent(_email.text.trim()))));
            context.go('/onboarding');
          }
        },
        builder: (context, state) {
          void submit() {
            if (_form.currentState!.validate()) {
              context
                  .read<AuthFormCubit>()
                  .signUp(displayName: _name.text, email: _email.text, password: _password.text);
            }
          }

          return AuthScaffold(
            title: l10n.signUpTitle,
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.alreadyHaveAccount, style: context.textTheme.bodyMedium),
                TextButton(onPressed: () => context.pushReplacement('/auth/sign-in'), child: Text(l10n.signIn)),
              ],
            ),
            children: [
              Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(labelText: l10n.displayName, prefixIcon: const Icon(Icons.person_outline_rounded)),
                        validator: (v) => (v?.trim().length ?? 0) < 2 ? l10n.nameTooShort : null,
                      ),
                      const SizedBox(height: ReadInSpace.s3),
                      EmailField(controller: _email),
                      const SizedBox(height: ReadInSpace.s3),
                      PasswordField(controller: _password, isNew: true, onSubmitted: submit),
                      const SizedBox(height: ReadInSpace.s5),
                      SubmitButton(label: l10n.signUp, submitting: state.submitting, onPressed: submit),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ReadInSpace.s5),
              const SocialSignInButtons(),
            ],
          );
        },
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => getIt<AuthFormCubit>(),
      child: BlocConsumer<AuthFormCubit, AuthFormState>(
        listener: _showFailure,
        builder: (context, state) => AuthScaffold(
          title: l10n.resetPassword,
          children: [
            Text(l10n.resetPasswordBody, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
            const SizedBox(height: ReadInSpace.s5),
            if (state.status == AuthFormStatus.success)
              Container(
                padding: const EdgeInsets.all(ReadInSpace.s4),
                decoration: BoxDecoration(
                  color: context.colors.calloutTip,
                  borderRadius: BorderRadius.circular(ReadInRadius.md),
                ),
                child: Row(children: [
                  Icon(Icons.mark_email_read_outlined, color: context.colors.success),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(child: Text(l10n.resetPasswordSent)),
                ]),
              )
            else
              Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EmailField(controller: _email),
                    const SizedBox(height: ReadInSpace.s5),
                    SubmitButton(
                      label: l10n.sendResetLink,
                      submitting: state.submitting,
                      onPressed: () {
                        if (_form.currentState!.validate()) context.read<AuthFormCubit>().sendReset(_email.text);
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

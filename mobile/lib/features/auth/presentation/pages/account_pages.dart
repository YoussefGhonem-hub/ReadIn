import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/inputs/password_field.dart';
import '../../../../shared/widgets/inputs/phone_field.dart';
import '../../../../shared/widgets/inputs/pin_input.dart';
import '../../domain/entities/external_credential.dart';
import '../../domain/entities/me.dart';
import '../cubit/account_security_cubits.dart';
import '../cubit/form_support.dart';
import '../session/session_cubit.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/external_sign_in.dart';
import 'sign_in_page.dart';

/// Pops a settings screen with a confirmation once its form succeeded.
void _popWithMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  if (context.canPop()) context.pop();
}

bool _succeeded(AccountFormState a, AccountFormState b) => a.status != b.status && b.status == FormStatus.success;

/// The provider a Google / Apple-only account confirms with: the first linked one.
String _linkedProviderLabel(Me me) =>
    (me.externalLogins.map((login) => login.kind).nonNulls.firstOrNull ?? ExternalProvider.google).label;

// ── Set recovery PIN (mandatory) ─────────────────────────────────────

class SetRecoveryPinPage extends StatelessWidget {
  const SetRecoveryPinPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<SetRecoveryPinCubit>()..loadConfig(),
        child: const SetRecoveryPinView(),
      );
}

/// Shown while `mustSetRecoveryPin` (SPEC §9.2); it can't be skipped, only signed out of.
class SetRecoveryPinView extends StatefulWidget {
  const SetRecoveryPinView({super.key});

  @override
  State<SetRecoveryPinView> createState() => _SetRecoveryPinViewState();
}

class _SetRecoveryPinViewState extends State<SetRecoveryPinView> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? get _phone => context.read<SessionCubit>().state.me?.phoneNumber;

  void _submit() => context.read<SetRecoveryPinCubit>().submit(pin: _pin.text, confirmPin: _confirm.text, phoneE164: _phone);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<SetRecoveryPinCubit, AccountFormState>(
      builder: (context, state) {
        final busy = state.submitting;
        return PopScope(
          canPop: false,
          child: AuthScaffold(
            automaticallyImplyLeading: false,
            actions: [SignOutAction(onPressed: context.read<SessionCubit>().signOut)],
            title: l10n.setPinTitle,
            subtitle: l10n.setPinBody,
            children: [
              if (state.failure case final failure?) ...[
                FailureBanner(failure: failure),
                const SizedBox(height: ReadInSpace.s4),
              ],
              PinInput(
                controller: _pin,
                label: l10n.pinLabel,
                length: state.config.pinLength,
                enabled: !busy,
                errorText: errorText(context, state.errors[Fields.pin]),
                onChanged: (pin) => context.read<SetRecoveryPinCubit>().pinChanged(pin, phoneE164: _phone),
              ),
              const SizedBox(height: ReadInSpace.s5),
              PinInput(
                controller: _confirm,
                label: l10n.confirmPinLabel,
                length: state.config.pinLength,
                enabled: !busy,
                errorText: errorText(context, state.errors[Fields.confirmPin]),
              ),
              const SizedBox(height: ReadInSpace.s6),
              SubmitButton(label: l10n.save, submitting: busy, onPressed: _submit),
            ],
          ),
        );
      },
    );
  }
}

// ── Change password (Settings, and mandatory after an Admin reset) ───

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<ChangePasswordCubit>()..loadConfig(),
        child: ChangePasswordView(mandatory: context.read<SessionCubit>().state.me?.mustChangePassword ?? false),
      );
}

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key, this.mandatory = false});

  /// `mustChangePassword`: no way back, only forward or sign out.
  final bool mandatory;

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_current, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() => context.read<ChangePasswordCubit>().submit(
        currentPassword: _current.text,
        newPassword: _password.text,
        confirmPassword: _confirm.text,
        phoneE164: context.read<SessionCubit>().state.me?.phoneNumber,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ChangePasswordCubit, AccountFormState>(
      listenWhen: _succeeded,
      listener: (context, _) {
        TextInput.finishAutofillContext();
        // Mandatory: on to the next guard (set PIN, complete profile…) or home. From Settings: back with a confirmation.
        if (widget.mandatory) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
          context.go('/home');
        } else {
          _popWithMessage(context, l10n.passwordChanged);
        }
      },
      builder: (context, state) {
        final busy = state.submitting;
        return PopScope(
          canPop: !widget.mandatory,
          child: AuthScaffold(
            automaticallyImplyLeading: !widget.mandatory,
            actions: widget.mandatory ? [SignOutAction(onPressed: context.read<SessionCubit>().signOut)] : null,
            title: l10n.changePasswordTitle,
            subtitle: widget.mandatory ? l10n.mustChangePasswordBody : l10n.changePasswordBody,
            children: [
              if (state.failure case final failure?) ...[
                FailureBanner(failure: failure),
                const SizedBox(height: ReadInSpace.s4),
              ],
              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PasswordField(
                      controller: _current,
                      label: l10n.currentPasswordLabel,
                      enabled: !busy,
                      errorText: errorText(context, state.errors[Fields.currentPassword]),
                    ),
                    const SizedBox(height: ReadInSpace.s4),
                    NewPasswordFields(
                      password: _password,
                      confirm: _confirm,
                      policy: state.config.password,
                      passwordLabel: l10n.newPasswordLabel,
                      enabled: !busy,
                      passwordError: errorText(context, state.errors[Fields.password]),
                      confirmError: errorText(context, state.errors[Fields.confirmPassword]),
                      onSubmitted: _submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ReadInSpace.s5),
              SubmitButton(label: l10n.save, submitting: busy, onPressed: _submit),
            ],
          ),
        );
      },
    );
  }
}

// ── Change recovery PIN (Settings) ───────────────────────────────────

class ChangeRecoveryPinPage extends StatelessWidget {
  const ChangeRecoveryPinPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<ChangeRecoveryPinCubit>()..loadConfig(),
        child: const ChangeRecoveryPinView(),
      );
}

class ChangeRecoveryPinView extends StatefulWidget {
  const ChangeRecoveryPinView({super.key});

  @override
  State<ChangeRecoveryPinView> createState() => _ChangeRecoveryPinViewState();
}

class _ChangeRecoveryPinViewState extends State<ChangeRecoveryPinView> {
  final _password = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_password, _pin, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _phone => context.read<SessionCubit>().state.me?.phoneNumber;

  void _submit() => context.read<ChangeRecoveryPinCubit>().submit(
        currentPassword: _password.text,
        pin: _pin.text,
        confirmPin: _confirm.text,
        phoneE164: _phone,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ChangeRecoveryPinCubit, AccountFormState>(
      listenWhen: _succeeded,
      listener: (context, _) => _popWithMessage(context, l10n.pinChanged),
      builder: (context, state) {
        final busy = state.submitting;
        return AuthScaffold(
          title: l10n.changePinTitle,
          subtitle: l10n.changePinBody,
          children: [
            if (state.failure case final failure?) ...[
              FailureBanner(failure: failure),
              const SizedBox(height: ReadInSpace.s4),
            ],
            PasswordField(
              controller: _password,
              label: l10n.currentPasswordLabel,
              enabled: !busy,
              errorText: errorText(context, state.errors[Fields.currentPassword]),
            ),
            const SizedBox(height: ReadInSpace.s5),
            PinInput(
              controller: _pin,
              label: l10n.newPinLabel,
              length: state.config.pinLength,
              enabled: !busy,
              errorText: errorText(context, state.errors[Fields.pin]),
              onChanged: (pin) => context.read<ChangeRecoveryPinCubit>().pinChanged(pin, phoneE164: _phone),
            ),
            const SizedBox(height: ReadInSpace.s5),
            PinInput(
              controller: _confirm,
              label: l10n.confirmPinLabel,
              length: state.config.pinLength,
              enabled: !busy,
              errorText: errorText(context, state.errors[Fields.confirmPin]),
            ),
            const SizedBox(height: ReadInSpace.s6),
            SubmitButton(label: l10n.save, submitting: busy, onPressed: _submit),
          ],
        );
      },
    );
  }
}

// ── Change number (Settings) ─────────────────────────────────────────

class ChangePhonePage extends StatelessWidget {
  const ChangePhonePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<ChangePhoneCubit>(),
        child: const ChangePhoneView(),
      );
}

class ChangePhoneView extends StatefulWidget {
  const ChangePhoneView({super.key});

  @override
  State<ChangePhoneView> createState() => _ChangePhoneViewState();
}

class _ChangePhoneViewState extends State<ChangePhoneView> {
  late final _phone = PhoneFieldController(iso2: initialPhoneCountry());
  final _password = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _review() => context.read<ChangePhoneCubit>().review(
        phoneE164: _phone.e164,
        phoneEmpty: _phone.isEmpty,
        currentPassword: _password.text,
        currentPhone: context.read<SessionCubit>().state.me?.phoneNumber,
      );

  Future<void> _confirm() async {
    final cubit = context.read<ChangePhoneCubit>();
    final phone = _phone.e164;
    if (phone == null) return cubit.cancelConfirmation();
    final answer = await showConfirmNumberDialog(context, phoneE164: phone, confirmLabel: context.l10n.confirmNumberChangeYes);
    if (answer ?? false) {
      await cubit.confirm();
    } else {
      cubit.cancelConfirmation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ChangePhoneCubit, AccountFormState>(
      listenWhen: (a, b) => (!a.confirming && b.confirming) || _succeeded(a, b),
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          _popWithMessage(context, l10n.phoneChanged);
        } else if (state.confirming) {
          _confirm();
        }
      },
      builder: (context, state) {
        final busy = state.submitting;
        return AuthScaffold(
          title: l10n.changePhoneTitle,
          subtitle: l10n.changePhoneBody,
          children: [
            if (state.failure case final failure?) ...[
              FailureBanner(failure: failure),
              const SizedBox(height: ReadInSpace.s4),
            ],
            PhoneField(
              controller: _phone,
              label: l10n.newPhoneLabel,
              enabled: !busy,
              errorText: errorText(context, state.errors[Fields.phone]),
            ),
            const SizedBox(height: ReadInSpace.s4),
            PasswordField(
              controller: _password,
              label: l10n.currentPasswordLabel,
              enabled: !busy,
              textInputAction: TextInputAction.done,
              errorText: errorText(context, state.errors[Fields.currentPassword]),
              onSubmitted: _review,
            ),
            const SizedBox(height: ReadInSpace.s6),
            SubmitButton(label: l10n.continueAction, submitting: busy, onPressed: _review),
          ],
        );
      },
    );
  }
}

// ── Add phone + password (Settings, Google / Apple-only accounts) ─────

class AddPhoneSignInPage extends StatelessWidget {
  const AddPhoneSignInPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<AddPhoneSignInCubit>()..loadConfig(),
        child: const AddPhoneSignInView(),
      );
}

/// "ضيف رقم تليفون وكلمة سر" (F18): number, password and recovery PIN, the confirm-number dialog, then a linked provider
/// confirms it's the owner.
class AddPhoneSignInView extends StatefulWidget {
  const AddPhoneSignInView({super.key});

  @override
  State<AddPhoneSignInView> createState() => _AddPhoneSignInViewState();
}

class _AddPhoneSignInViewState extends State<AddPhoneSignInView> {
  late final _phone = PhoneFieldController(iso2: initialPhoneCountry());
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _pin = TextEditingController();
  final _confirmPin = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    for (final c in [_password, _confirmPassword, _pin, _confirmPin]) {
      c.dispose();
    }
    super.dispose();
  }

  void _review() => context.read<AddPhoneSignInCubit>().review(
        phoneE164: _phone.e164,
        phoneEmpty: _phone.isEmpty,
        password: _password.text,
        confirmPassword: _confirmPassword.text,
        pin: _pin.text,
        confirmPin: _confirmPin.text,
      );

  Future<void> _confirm() async {
    final cubit = context.read<AddPhoneSignInCubit>();
    final me = context.read<SessionCubit>().state.me;
    final phone = _phone.e164;
    if (phone == null || me == null) return cubit.cancelConfirmation();
    final answer = await showConfirmNumberDialog(context, phoneE164: phone, confirmLabel: context.l10n.confirmNumberAddYes);
    if (answer ?? false) {
      await cubit.confirm(me);
    } else {
      cubit.cancelConfirmation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = context.select((SessionCubit c) => c.state.me);
    return BlocConsumer<AddPhoneSignInCubit, AccountFormState>(
      listenWhen: (a, b) => (!a.confirming && b.confirming) || _succeeded(a, b),
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          TextInput.finishAutofillContext();
          _popWithMessage(context, l10n.phoneSignInAdded);
        } else if (state.confirming) {
          _confirm();
        }
      },
      builder: (context, state) {
        final busy = state.submitting;
        return AuthScaffold(
          title: l10n.addPhoneSignIn,
          subtitle: l10n.addPhoneSignInBody(me == null ? ExternalProvider.google.label : _linkedProviderLabel(me)),
          children: [
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
                  ),
                  const SizedBox(height: ReadInSpace.s4),
                  NewPasswordFields(
                    password: _password,
                    confirm: _confirmPassword,
                    policy: state.config.password,
                    enabled: !busy,
                    passwordError: errorText(context, state.errors[Fields.password]),
                    confirmError: errorText(context, state.errors[Fields.confirmPassword]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ReadInSpace.s5),
            PinInput(
              controller: _pin,
              label: l10n.pinLabel,
              length: state.config.pinLength,
              enabled: !busy,
              errorText: errorText(context, state.errors[Fields.pin]),
              onChanged: (pin) => context
                  .read<AddPhoneSignInCubit>()
                  .pinChanged(pin, phoneE164: _phone.e164, password: _password.text),
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
            SubmitButton(label: l10n.continueAction, submitting: busy, onPressed: _review),
          ],
        );
      },
    );
  }
}

// ── Delete account (Settings) ────────────────────────────────────────

class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<DeleteAccountCubit>(),
        child: const DeleteAccountView(),
      );
}

class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({super.key});

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  final _password = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() => context.read<DeleteAccountCubit>().submit(
        password: _password.text,
        confirmed: _confirmed,
        me: context.read<SessionCubit>().state.me,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final me = context.select((SessionCubit c) => c.state.me);
    // Accounts without a password confirm with a linked Google / Apple account instead (F18).
    final confirmWith = me == null || me.hasPassword ? null : _linkedProviderLabel(me);
    return BlocConsumer<DeleteAccountCubit, AccountFormState>(
      listenWhen: _succeeded,
      // The session has ended; the router leaves this screen.
      listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.accountDeleted))),
      builder: (context, state) {
        final busy = state.submitting;
        return AuthScaffold(
          title: l10n.deleteAccount,
          children: [
            FormBanner(message: l10n.deleteAccountBody, tone: BannerTone.warning),
            const SizedBox(height: ReadInSpace.s5),
            if (state.failure case final failure?) ...[
              FailureBanner(failure: failure),
              const SizedBox(height: ReadInSpace.s4),
            ],
            if (confirmWith != null)
              FormBanner(message: l10n.deleteAccountWithProvider(confirmWith), tone: BannerTone.info)
            else
              PasswordField(
                controller: _password,
                enabled: !busy,
                textInputAction: TextInputAction.done,
                errorText: errorText(context, state.errors[Fields.password]),
              ),
            const SizedBox(height: ReadInSpace.s3),
            CheckboxListTile(
              value: _confirmed,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.deleteAccountConfirm),
              onChanged: busy ? null : (value) => setState(() => _confirmed = value ?? false),
            ),
            const SizedBox(height: ReadInSpace.s4),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
              onPressed: !_confirmed || busy ? null : _submit,
              child: busy
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.onError))
                  : Text(l10n.deleteAccountButton),
            ),
          ],
        );
      },
    );
  }
}

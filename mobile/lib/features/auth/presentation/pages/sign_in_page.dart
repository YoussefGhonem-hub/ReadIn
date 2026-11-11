import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/phone/countries.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/inputs/password_field.dart';
import '../../../../shared/widgets/inputs/phone_field.dart';
import '../cubit/external_sign_in_cubit.dart';
import '../cubit/form_support.dart';
import '../cubit/sign_in_cubit.dart';
import '../widgets/auth_showcase.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/dev_login_panel.dart';
import '../widgets/external_sign_in.dart';
import '../widgets/leave_when_signed_in.dart';

/// Arguments of the Sign in route: the number to pre-fill, whether a password was just reset, whether the account was
/// just deleted on this device, and why the session ended when the app sent the user here (a suspended account, F22).
class SignInArgs {
  const SignInArgs({this.phone, this.passwordReset = false, this.accountDeleted = false, this.endedBy});

  final String? phone;
  final bool passwordReset;
  final bool accountDeleted;

  /// Shown as the form's banner until the first attempt (`user.suspended` says until when).
  final Failure? endedBy;
}

/// The phone field's first country (last used → device region → Egypt).
String? initialPhoneCountry() => getIt.isRegistered<PhoneCountryMemory>() ? getIt<PhoneCountryMemory>().initial() : null;

class SignInPage extends StatelessWidget {
  const SignInPage({super.key, this.args = const SignInArgs()});

  final SignInArgs args;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<SignInCubit>()),
          BlocProvider(create: (_) => getIt<ExternalSignInCubit>()..load()),
        ],
        child: LeaveWhenSignedIn(
          child: BlocSelector<ExternalSignInCubit, ExternalSignInState, bool>(
            selector: (state) => state.providers.isNotEmpty,
            builder: (_, hasProviders) => SignInView(
              args: args,
              showDevLogin: !kReleaseMode && DevLogin.available,
              alternatives: [if (hasProviders) const ExternalSignInButtons(compact: true)],
            ),
          ),
        ),
      );
}

/// Sign in (SPEC §9.2): phone, password, "forgot password", one generic error for a wrong number or password. It looks
/// and moves like the web login: the brand showcase on top ([AuthShowcaseHeader]), the form on a rounded sheet over it,
/// rising piece by piece; an error shakes once and the button shines once ([AuthMotion]).
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
  late Failure? _endedBy = widget.args.endedBy;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_endedBy != null) setState(() => _endedBy = null);
    context.read<SignInCubit>().submit(
          phoneE164: _phone.e164,
          phoneEmpty: _phone.isEmpty,
          password: _password.text,
        );
  }

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
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        // Once the header has scrolled away, the status bar is over the sheet.
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: context.isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: Theme.of(context).brightness,
        ),
        child: AuthMotionScope(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthShowcaseHeader(),
                // The form's sheet, its rounded top over the header's green.
                Transform.translate(
                  offset: const Offset(0, -AuthShowcaseHeader.sheetOverlap),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AuthShowcaseHeader.sheetOverlap)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s5, ReadInSpace.s5, ReadInSpace.s2),
                            child: _form(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The text links (forgot password, create account): no extra height around them, so the whole screen fits.
  static final _compactLink = TextButton.styleFrom(minimumSize: const Size(48, 40), visualDensity: VisualDensity.compact);

  Widget _form(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return BlocConsumer<SignInCubit, SignInState>(
      listenWhen: (a, b) => a.status != b.status && b.status == FormStatus.success,
      listener: (_, _) => TextInput.finishAutofillContext(), // offer to save the password; the router moves on
      builder: (context, state) {
        final busy = state.submitting;
        // The form rises piece by piece, 60 ms apart, as on the web. The keys keep each piece's state when a banner
        // comes or goes above it.
        var order = 0;
        Widget rise(String key, Widget child) => AuthRise(key: ValueKey(key), delay: 0.06 * ++order, child: child);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            rise('title', Semantics(header: true, child: Text(l10n.signInTitle, style: context.textTheme.headlineMedium))),
            const SizedBox(height: ReadInSpace.s2),
            rise(
              'subtitle',
              Text(l10n.signInSubtitle, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
            ),
            const SizedBox(height: ReadInSpace.s4),
            // Read from the arguments (not kept): Delete account replaces this route's arguments once it's done.
            if (widget.args.accountDeleted && !_passwordReset && state.failure == null) ...[
              rise('deleted', FormBanner(message: l10n.accountDeleted, tone: BannerTone.success)),
              const SizedBox(height: ReadInSpace.s4),
            ],
            if (_passwordReset && state.failure == null) ...[
              rise('reset', FormBanner(message: l10n.passwordResetBanner, tone: BannerTone.success)),
              const SizedBox(height: ReadInSpace.s4),
            ],
            if (state.failure ?? _endedBy case final failure?) ...[
              rise('failure', AuthShake(trigger: failure, child: FailureBanner(failure: failure))),
              const SizedBox(height: ReadInSpace.s4),
            ],
            rise(
              'fields',
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
            ),
            rise(
              'forgot',
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(style: _compactLink, onPressed: busy ? null : _forgotPassword, child: Text(l10n.forgotPassword)),
              ),
            ),
            const SizedBox(height: ReadInSpace.s1),
            // The sign-in actions: the phone sign in first, then any alternatives under "أو".
            rise(
              'actions',
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthButtonMotion(child: SubmitButton(label: l10n.signIn, submitting: busy, onPressed: _submit)),
                  if (widget.alternatives.isNotEmpty) ...[
                    const SizedBox(height: ReadInSpace.s4),
                    const OrDivider(),
                    const SizedBox(height: ReadInSpace.s3),
                    ...widget.alternatives,
                  ],
                ],
              ),
            ),
            if (!kReleaseMode && widget.showDevLogin) ...[
              const SizedBox(height: ReadInSpace.s4),
              rise(
                'dev',
                OutlinedButton.icon(
                  icon: Icon(Icons.developer_mode_rounded, color: colors.textSecondary),
                  label: Text(l10n.devLoginOpen),
                  onPressed: busy ? null : _openDevLogin,
                ),
              ),
            ],
            const SizedBox(height: ReadInSpace.s2),
            rise(
              'footer',
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l10n.noAccount, style: context.textTheme.bodyMedium),
                  TextButton(
                    style: _compactLink,
                    onPressed: () => context.pushReplacement('/auth/sign-up'),
                    child: Text(l10n.createAccountLink),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

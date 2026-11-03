import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/inputs/password_field.dart';
import '../../../../shared/widgets/inputs/phone_field.dart';
import '../../domain/entities/external_credential.dart';
import '../cubit/external_sign_in_cubit.dart';
import '../cubit/form_support.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/external_sign_in.dart';
import 'sign_in_page.dart';

/// "عندي حساب برقم تليفون" (SPEC §9.2): the phone sign in links the Google / Apple identity waiting in
/// [ExternalSignInCubit] and signs in; the router then leaves this screen.
class LinkExternalAccountView extends StatefulWidget {
  const LinkExternalAccountView({super.key});

  @override
  State<LinkExternalAccountView> createState() => _LinkExternalAccountViewState();
}

class _LinkExternalAccountViewState extends State<LinkExternalAccountView> {
  late final _phone = PhoneFieldController(iso2: initialPhoneCountry());
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() => context.read<ExternalSignInCubit>().link(
        phoneE164: _phone.e164,
        phoneEmpty: _phone.isEmpty,
        password: _password.text,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ExternalSignInCubit, ExternalSignInState>(
      listenWhen: (a, b) => a.status != b.status && b.status == FormStatus.success,
      listener: (_, _) => TextInput.finishAutofillContext(),
      builder: (context, state) {
        final busy = state.submitting;
        final provider = state.notLinked?.provider ?? ExternalProvider.google;
        return AuthScaffold(
          title: l10n.linkAccountTitle,
          subtitle: l10n.linkAccountBody(provider.label),
          children: [
            if (state.linkFailure case final failure?) ...[
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
                    errorText: errorText(context, state.linkErrors[Fields.phone]),
                    onSubmitted: _passwordFocus.requestFocus,
                  ),
                  const SizedBox(height: ReadInSpace.s4),
                  PasswordField(
                    controller: _password,
                    focusNode: _passwordFocus,
                    enabled: !busy,
                    errorText: errorText(context, state.linkErrors[Fields.password]),
                    textInputAction: TextInputAction.done,
                    onSubmitted: _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: ReadInSpace.s5),
            SubmitButton(label: l10n.linkAccountButton, submitting: busy, onPressed: _submit),
          ],
        );
      },
    );
  }
}

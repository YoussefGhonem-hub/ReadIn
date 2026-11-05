import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../profile/presentation/widgets/headline_field.dart';
import '../cubit/complete_profile_cubit.dart';
import '../cubit/form_support.dart';
import '../session/session_cubit.dart';
import '../widgets/auth_widgets.dart';

class CompleteProfilePage extends StatelessWidget {
  const CompleteProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.read<SessionCubit>().state.me;
    return BlocProvider(
      create: (_) => getIt<CompleteProfileCubit>()..start(me),
      child: const CompleteProfileView(),
    );
  }
}

/// Complete profile after sign up (SPEC §9.2): display name, a unique `@username` with a live availability check and
/// an optional avatar. Then onboarding.
class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _headline;

  @override
  void initState() {
    super.initState();
    final me = context.read<SessionCubit>().state.me;
    _name = TextEditingController(text: CompleteProfileCubit.initialDisplayName(me));
    _username = TextEditingController(text: CompleteProfileCubit.initialUsername(me));
    _headline = TextEditingController(text: me?.headline ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _headline.dispose();
    super.dispose();
  }

  void _submit() => context.read<CompleteProfileCubit>().submit(displayName: _name.text, headline: _headline.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
      builder: (context, state) {
        final cubit = context.read<CompleteProfileCubit>();
        final busy = state.submitting;
        return AuthScaffold(
          automaticallyImplyLeading: false,
          actions: [SignOutAction(onPressed: context.read<SessionCubit>().signOut)],
          title: l10n.completeProfileTitle,
          subtitle: l10n.completeProfileBody,
          children: [
            if (state.failure case final failure?) ...[
              FailureBanner(failure: failure),
              const SizedBox(height: ReadInSpace.s4),
            ],
            _AvatarPicker(state: state, displayName: _name),
            const SizedBox(height: ReadInSpace.s5),
            BidiTextField(
              controller: _name,
              enabled: !busy,
              maxLength: 60,
              counterWithin: 10,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.displayName,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                errorText: errorText(context, state.errors[Fields.displayName]),
              ),
            ),
            const SizedBox(height: ReadInSpace.s4),
            TextField(
              controller: _username,
              enabled: !busy,
              textDirection: TextDirection.ltr,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword, // no autocorrect, no capitals
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (_, value) => value.copyWith(text: value.text.toLowerCase().replaceAll(RegExp('[^a-z0-9_]'), '')),
                ),
                LengthLimitingTextInputFormatter(30),
              ],
              onChanged: cubit.usernameChanged,
              decoration: InputDecoration(
                labelText: l10n.usernameLabel,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                suffixIcon: _UsernameStatusIcon(status: state.usernameStatus),
                helperText: _usernameHelper(context, state),
                errorText: errorText(context, state.errors[Fields.username] ?? _usernameError(state.usernameStatus)),
              ),
            ),
            const SizedBox(height: ReadInSpace.s4),
            // The optional title (F14), as in Edit profile.
            HeadlineField(
              controller: _headline,
              enabled: !busy,
              textInputAction: TextInputAction.done,
              error: errorText(context, state.errors[CompleteProfileCubit.headlineField]),
            ),
            const SizedBox(height: ReadInSpace.s6),
            SubmitButton(label: l10n.saveAndContinue, submitting: busy || state.uploadingAvatar, onPressed: _submit),
          ],
        );
      },
    );
  }

  static String? _usernameError(UsernameStatus status) => switch (status) {
        UsernameStatus.invalid => FailureCodes.usernameInvalid,
        UsernameStatus.taken => FailureCodes.usernameTaken,
        _ => null,
      };

  static String _usernameHelper(BuildContext context, CompleteProfileState state) => switch (state.usernameStatus) {
        UsernameStatus.checking => context.l10n.usernameChecking,
        UsernameStatus.available => context.l10n.usernameAvailable(state.username),
        _ => context.l10n.usernameHint,
      };
}

class _UsernameStatusIcon extends StatelessWidget {
  const _UsernameStatusIcon({required this.status});

  final UsernameStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return switch (status) {
      UsernameStatus.checking => const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      UsernameStatus.available => Icon(Icons.check_circle_rounded, color: colors.success),
      UsernameStatus.taken || UsernameStatus.invalid => Icon(Icons.error_outline_rounded, color: colors.error),
      UsernameStatus.idle => const SizedBox.shrink(),
    };
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.state, required this.displayName});

  final CompleteProfileState state;
  final TextEditingController displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CompleteProfileCubit>();
    final busy = state.submitting || state.uploadingAvatar;
    final hasPhoto = state.avatarUrl != null;
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ListenableBuilder(
              listenable: displayName,
              builder: (_, _) => UserAvatar(name: displayName.text, url: state.avatarUrl, size: 72),
            ),
            if (state.uploadingAvatar)
              Semantics(
                label: l10n.photoUploading,
                child: const SizedBox(width: 72, height: 72, child: CircularProgressIndicator(strokeWidth: 3)),
              ),
          ],
        ),
        const SizedBox(width: ReadInSpace.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(hasPhoto ? l10n.changePhoto : l10n.addPhoto),
                onPressed: busy ? null : cubit.pickAvatar,
              ),
              if (hasPhoto)
                TextButton(onPressed: busy ? null : cubit.removeAvatar, child: Text(l10n.removePhoto))
              else
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: ReadInSpace.s2, top: ReadInSpace.s1),
                  child: Text(l10n.optional, style: context.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

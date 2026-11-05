import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../../shared/widgets/field_style.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/presentation/cubit/complete_profile_cubit.dart' show UsernameStatus;
import '../../../auth/presentation/cubit/form_support.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart';
import '../../domain/entities/profile.dart';
import '../cubit/edit_profile_cubit.dart';
import '../widgets/headline_field.dart';
import '../widgets/profile_links_editor.dart';

/// `/profile/edit` (F14). The profile screen hands over the loaded [profile]; otherwise the own profile is loaded.
/// Pops `true` once saved.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key, this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final me = context.select((SessionCubit c) => c.state.me);
    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.editProfile)),
        body: EmptyView(icon: Icons.person_outline_rounded, title: context.l10n.profileGuestTitle, body: context.l10n.profileGuestBody),
      );
    }
    return BlocProvider(
      create: (_) => getIt<EditProfileCubit>()..start(profile: profile?.isMe == true ? profile : null, username: me.username),
      child: const EditProfileView(),
    );
  }
}

/// The edit form once its [EditProfileCubit] is provided.
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _headline = TextEditingController();
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _fill(context.read<EditProfileCubit>().state);
  }

  /// The form starts from the loaded profile, once.
  void _fill(EditProfileState state) {
    final profile = state.profile;
    if (_filled || state.load != EditProfileLoad.ready || profile == null) return;
    _filled = true;
    _name.text = profile.displayName;
    _username.text = profile.username;
    _bio.text = profile.bio ?? '';
    _headline.text = profile.headline ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _username, _bio, _headline]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() => context.read<EditProfileCubit>().submit(displayName: _name.text, bio: _bio.text, headline: _headline.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<EditProfileCubit, EditProfileState>(
      listenWhen: (a, b) => a.load != b.load || a.status != b.status,
      listener: (context, state) {
        _fill(state);
        if (state.status == FormStatus.success) Navigator.of(context).pop(true);
      },
      builder: (context, state) {
        final Widget body = switch (state.load) {
          EditProfileLoad.loading => const Center(child: CircularProgressIndicator()),
          EditProfileLoad.failure => ErrorView(
              failure: state.loadFailure!,
              onRetry: () => context.read<EditProfileCubit>().reload(context.read<SessionCubit>().state.me?.username ?? ''),
            ),
          EditProfileLoad.ready => _Form(state: state, view: this),
        };
        return Scaffold(
          appBar: AppBar(title: Text(l10n.editProfile)),
          body: body,
          bottomNavigationBar: state.load != EditProfileLoad.ready
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s3, ReadInSpace.s5, ReadInSpace.s3),
                    decoration: BoxDecoration(
                      color: context.colors.bg,
                      border: Border(top: BorderSide(color: context.colors.border)),
                    ),
                    child: SubmitButton(
                      label: l10n.save,
                      submitting: state.submitting,
                      // Saving waits for a photo still uploading (no double submit either way).
                      onPressed: state.uploadingAvatar ? null : _submit,
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state, required this.view});

  final EditProfileState state;
  final _EditProfileViewState view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<EditProfileCubit>();
    final busy = state.submitting;
    String? error(String field) => errorText(context, state.errors[field]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, ReadInSpace.s6),
      children: [
        if (state.failure case final failure?) ...[
          FailureBanner(failure: failure),
          const SizedBox(height: ReadInSpace.s4),
        ],
        _AvatarEditor(state: state, displayName: view._name),
        const SizedBox(height: ReadInSpace.s5),
        BidiTextField(
          controller: view._name,
          enabled: !busy,
          maxLength: ProfileLimits.displayNameMax,
          counterWithin: 10,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => cubit.edited(ProfileFields.displayName),
          decoration: InputDecoration(
            labelText: l10n.displayName,
            prefixIcon: const Icon(Icons.person_outline_rounded),
            errorText: error(ProfileFields.displayName),
          ),
        ),
        const SizedBox(height: ReadInSpace.s4),
        TextField(
          controller: view._username,
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
            helperText: switch (state.usernameStatus) {
              UsernameStatus.checking => l10n.usernameChecking,
              UsernameStatus.available when state.username != state.profile?.username => l10n.usernameAvailable(state.username),
              _ => l10n.usernameHint,
            },
            errorText: errorText(
              context,
              state.errors[ProfileFields.username] ??
                  switch (state.usernameStatus) {
                    UsernameStatus.invalid => FailureCodes.usernameInvalid,
                    UsernameStatus.taken => FailureCodes.usernameTaken,
                    _ => null,
                  },
            ),
          ),
        ),
        const SizedBox(height: ReadInSpace.s4),
        HeadlineField(
          controller: view._headline,
          enabled: !busy,
          error: error(ProfileFields.headline),
          onChanged: (_) => cubit.edited(ProfileFields.headline),
        ),
        const SizedBox(height: ReadInSpace.s4),
        BidiTextField(
          controller: view._bio,
          enabled: !busy,
          maxLength: ProfileLimits.bioMax,
          minLines: 3,
          maxLines: 6,
          onChanged: (_) => cubit.edited(ProfileFields.bio),
          decoration: InputDecoration(
            labelText: l10n.profileBioLabel,
            hintText: l10n.profileBioHint,
            alignLabelWithHint: true,
            errorText: error(ProfileFields.bio),
          ),
        ),
        const SizedBox(height: ReadInSpace.s5),
        ProfileLinksEditor(state: state),
        const SizedBox(height: ReadInSpace.s5),
        _ExpertisePicker(state: state),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Semantics(header: true, child: Text(text, style: context.textTheme.titleSmall))),
          ?trailing,
        ],
      );
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

/// The avatar preview with "change" (gallery or camera) and "remove".
class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({required this.state, required this.displayName});

  final EditProfileState state;
  final TextEditingController displayName;

  static const size = 96.0;

  Future<void> _choose(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<EditProfileCubit>();
    final source = await showModalBottomSheet<AvatarSource>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.profilePhotoGallery),
              onTap: () => Navigator.pop(context, AvatarSource.gallery),
            ),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.profilePhotoCamera),
              onTap: () => Navigator.pop(context, AvatarSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) await cubit.pickAvatar(source);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<EditProfileCubit>();
    final busy = state.busy;
    final hasPhoto = state.avatarUrl != null;
    final avatarError = state.errors[ProfileFields.avatar];
    return Column(
      children: [
        Semantics(
          image: true,
          label: state.uploadingAvatar ? l10n.photoUploading : l10n.profilePhotoPreview,
          excludeSemantics: true,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListenableBuilder(
                  listenable: displayName,
                  builder: (_, _) => UserAvatar(name: displayName.text, url: state.avatarUrl, size: size),
                ),
                if (state.uploadingAvatar) ...[
                  Container(decoration: BoxDecoration(shape: BoxShape.circle, color: colors.scrim.withValues(alpha: 0.35))),
                  const SizedBox(width: size, height: size, child: CircularProgressIndicator(strokeWidth: 3)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: ReadInSpace.s2),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: ReadInSpace.s2,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(hasPhoto ? l10n.changePhoto : l10n.addPhoto),
              onPressed: busy ? null : () => _choose(context),
            ),
            if (hasPhoto)
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: colors.error),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(l10n.removePhoto),
                onPressed: busy ? null : cubit.removeAvatar,
              ),
          ],
        ),
        if (avatarError != null)
          Semantics(
            liveRegion: true,
            child: Text(
              errorText(context, avatarError)!,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ),
      ],
    );
  }
}

/// Up to five fields of expertise from `/fields`, in the order picked.
class _ExpertisePicker extends StatelessWidget {
  const _ExpertisePicker({required this.state});

  final EditProfileState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<EditProfileCubit>();
    final lang = Localizations.localeOf(context).languageCode;
    final error = state.errors[ProfileFields.expertise];

    final Widget chips = switch (state.fieldsStatus) {
      EditProfileLoad.loading => const Wrap(
          spacing: ReadInSpace.s2,
          runSpacing: ReadInSpace.s2,
          children: [
            SkeletonBox(width: 90, height: 36, radius: ReadInRadius.chip),
            SkeletonBox(width: 120, height: 36, radius: ReadInRadius.chip),
            SkeletonBox(width: 70, height: 36, radius: ReadInRadius.chip),
          ],
        ),
      EditProfileLoad.failure => ErrorView(
          failure: const Failure(FailureCodes.serverError),
          compact: true,
          onRetry: cubit.loadFields,
        ),
      EditProfileLoad.ready => Wrap(
          spacing: ReadInSpace.s2,
          runSpacing: ReadInSpace.s2,
          children: [
            for (final field in state.fields)
              Builder(builder: (context) {
                final selected = state.expertiseIds.contains(field.id);
                final enabled = !state.submitting && (selected || !state.expertiseFull);
                return FilterChip(
                  avatar: Icon(FieldStyle.icon(field.icon), size: 16, color: selected ? colors.onPrimaryContainer : colors.textSecondary),
                  label: BidiText(field.nameFor(lang)),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: enabled ? (_) => cubit.toggleExpertise(field.id) : null,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                );
              }),
          ],
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          l10n.profileExpertise,
          trailing: Semantics(
            label: l10n.profileExpertiseCountSemantics(state.expertiseIds.length, ProfileLimits.maxExpertise),
            excludeSemantics: true,
            child: Text(
              '${state.expertiseIds.length}/${ProfileLimits.maxExpertise}',
              textDirection: TextDirection.ltr,
              style: context.textTheme.labelMedium?.copyWith(color: state.expertiseFull ? colors.primary : colors.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: ReadInSpace.s1),
        Text(
          state.expertiseFull ? l10n.profileExpertiseFull : l10n.profileExpertiseHint,
          style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: ReadInSpace.s3),
        chips,
        if (error != null) ...[
          const SizedBox(height: ReadInSpace.s2),
          Text(errorText(context, error)!, style: context.textTheme.bodySmall?.copyWith(color: colors.error)),
        ],
      ],
    );
  }
}

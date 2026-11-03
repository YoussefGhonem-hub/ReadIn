import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/security/credential_rules.dart';
import '../../../auth/domain/usecases/auth_usecases.dart';
import '../../../auth/presentation/cubit/complete_profile_cubit.dart' show CompleteProfileCubit, UsernameStatus;
import '../../../auth/presentation/cubit/form_support.dart';
import '../../../media/domain/entities/media.dart';
import '../../../media/domain/usecases/media_usecases.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../../../taxonomy/domain/usecases/taxonomy_usecases.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/profile_usecases.dart';

/// Inputs of the edit profile form; server errors are mapped onto them.
abstract final class ProfileFields {
  static const displayName = 'displayName';
  static const username = 'username';
  static const bio = 'bio';
  static const github = 'github';
  static const linkedin = 'linkedin';
  static const website = 'website';
  static const avatar = 'avatar';
  static const expertise = 'expertise';
}

enum AvatarSource { gallery, camera }

enum EditProfileLoad { loading, ready, failure }

class EditProfileState extends Equatable {
  const EditProfileState({
    this.load = EditProfileLoad.loading,
    this.profile,
    this.loadFailure,
    this.username = '',
    this.usernameStatus = UsernameStatus.idle,
    this.avatarUrl,
    this.avatar = const KeepAvatar(null),
    this.uploadingAvatar = false,
    this.fields = const [],
    this.fieldsStatus = EditProfileLoad.loading,
    this.expertiseIds = const [],
    this.status = FormStatus.idle,
    this.errors = const {},
    this.failure,
  });

  final EditProfileLoad load;

  /// The profile as loaded; the form starts from it.
  final UserProfile? profile;
  final Failure? loadFailure;

  /// The handle the availability applies to.
  final String username;
  final UsernameStatus usernameStatus;

  /// The preview: the current avatar, the 256 px variant of a new upload, or null (initials).
  final String? avatarUrl;
  final AvatarChange avatar;
  final bool uploadingAvatar;

  /// Every field, for the expertise picker (`GET /fields`).
  final List<Field> fields;
  final EditProfileLoad fieldsStatus;

  /// Chosen fields of expertise, in order, at most [ProfileLimits.maxExpertise].
  final List<String> expertiseIds;

  final FormStatus status;

  /// Field ([ProfileFields]) → error code.
  final Map<String, String> errors;

  /// An error for the whole form.
  final Failure? failure;

  bool get submitting => status == FormStatus.submitting;
  bool get busy => submitting || uploadingAvatar;
  bool get expertiseFull => expertiseIds.length >= ProfileLimits.maxExpertise;

  EditProfileState copyWith({
    EditProfileLoad? load,
    UserProfile? profile,
    Failure? Function()? loadFailure,
    String? username,
    UsernameStatus? usernameStatus,
    String? Function()? avatarUrl,
    AvatarChange? avatar,
    bool? uploadingAvatar,
    List<Field>? fields,
    EditProfileLoad? fieldsStatus,
    List<String>? expertiseIds,
    FormStatus? status,
    Map<String, String>? errors,
    Failure? Function()? failure,
  }) =>
      EditProfileState(
        load: load ?? this.load,
        profile: profile ?? this.profile,
        loadFailure: loadFailure != null ? loadFailure() : this.loadFailure,
        username: username ?? this.username,
        usernameStatus: usernameStatus ?? this.usernameStatus,
        avatarUrl: avatarUrl != null ? avatarUrl() : this.avatarUrl,
        avatar: avatar ?? this.avatar,
        uploadingAvatar: uploadingAvatar ?? this.uploadingAvatar,
        fields: fields ?? this.fields,
        fieldsStatus: fieldsStatus ?? this.fieldsStatus,
        expertiseIds: expertiseIds ?? this.expertiseIds,
        status: status ?? this.status,
        errors: errors ?? this.errors,
        failure: failure != null ? failure() : this.failure,
      );

  @override
  List<Object?> get props => [
        load,
        profile,
        loadFailure,
        username,
        usernameStatus,
        avatarUrl,
        avatar,
        uploadingAvatar,
        fields,
        fieldsStatus,
        expertiseIds,
        status,
        errors,
        failure,
      ];
}

/// Edit profile (F14): name, `@username` with the live availability check, bio, links, up to 5 fields of expertise
/// and the avatar (gallery or camera, uploaded with `purpose=avatar`). Saving is `PATCH /me`; its errors land on the
/// fields they belong to.
@injectable
class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit(
    this._getProfile,
    this._getFields,
    this._checkUsername,
    this._pickImages,
    this._takePhoto,
    this._upload,
    this._update,
  ) : super(const EditProfileState());

  final GetProfile _getProfile;
  final GetFields _getFields;
  final CheckUsername _checkUsername;
  final PickImages _pickImages;
  final TakePhoto _takePhoto;
  final UploadImage _upload;
  final UpdateProfile _update;
  Timer? _debounce;

  static const debounce = CompleteProfileCubit.debounce;
  static final usernamePattern = CompleteProfileCubit.usernamePattern;

  /// Starts from [profile] when the profile screen hands it over, else loads the viewer's own ([username]).
  Future<void> start({UserProfile? profile, required String username}) async {
    unawaited(loadFields());
    if (profile != null) return _begin(profile);
    await reload(username);
  }

  Future<void> reload(String username) async {
    emit(state.copyWith(load: EditProfileLoad.loading, loadFailure: () => null));
    final result = await _getProfile(username);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(load: EditProfileLoad.failure, loadFailure: () => failure)),
      _begin,
    );
  }

  void _begin(UserProfile profile) => emit(state.copyWith(
        load: EditProfileLoad.ready,
        profile: profile,
        username: profile.username,
        usernameStatus: UsernameStatus.available, // your own handle counts as available
        avatarUrl: () => profile.avatarUrl,
        avatar: KeepAvatar(profile.avatarUrl),
        expertiseIds: [for (final field in profile.expertise.take(ProfileLimits.maxExpertise)) field.id],
      ));

  Future<void> loadFields() async {
    emit(state.copyWith(fieldsStatus: EditProfileLoad.loading));
    final result = await _getFields();
    if (isClosed) return;
    result.fold(
      (_) => emit(state.copyWith(fieldsStatus: EditProfileLoad.failure)),
      (fields) => emit(state.copyWith(fieldsStatus: EditProfileLoad.ready, fields: fields)),
    );
  }

  /// Live availability, debounced; stale answers are ignored. The current handle needs no check.
  void usernameChanged(String value) {
    _debounce?.cancel();
    final username = value.trim().toLowerCase();
    final errors = {...state.errors}..remove(ProfileFields.username);
    UsernameStatus status;
    if (username.isEmpty) {
      status = UsernameStatus.idle;
    } else if (!usernamePattern.hasMatch(username)) {
      status = UsernameStatus.invalid;
    } else if (username == state.profile?.username.toLowerCase()) {
      status = UsernameStatus.available;
    } else {
      status = UsernameStatus.checking;
      _debounce = Timer(debounce, () => _check(username));
    }
    emit(state.copyWith(username: username, usernameStatus: status, errors: errors));
  }

  Future<void> _check(String username) async {
    final result = await _checkUsername(username);
    if (isClosed || state.username != username) return;
    result.fold(
      (_) => emit(state.copyWith(usernameStatus: UsernameStatus.idle)), // the server checks again on save
      (availability) => emit(state.copyWith(
        usernameStatus: !availability.valid
            ? UsernameStatus.invalid
            : (availability.available ? UsernameStatus.available : UsernameStatus.taken),
      )),
    );
  }

  /// One photo from the gallery or the camera, compressed and uploaded as an avatar (square variants
  /// 64/128/256/512); the 256 px variant is the preview.
  Future<void> pickAvatar(AvatarSource source) async {
    if (state.busy) return;
    final PickedMediaFile? file = switch (source) {
      AvatarSource.gallery => (await _pickImages(limit: 1)).firstOrNull,
      AvatarSource.camera => await _takePhoto(),
    };
    if (file == null || isClosed) return;
    final errors = {...state.errors}..remove(ProfileFields.avatar);
    emit(state.copyWith(uploadingAvatar: true, errors: errors));
    final result = await _upload(file, purpose: 'avatar');
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(uploadingAvatar: false, errors: {...state.errors, ProfileFields.avatar: failure.code})),
      (asset) => emit(state.copyWith(
        uploadingAvatar: false,
        avatar: NewAvatar(asset.id),
        avatarUrl: () => previewOf(asset) ?? state.avatarUrl,
      )),
    );
  }

  void removeAvatar() {
    if (state.busy) return;
    emit(state.copyWith(
      avatar: const RemoveAvatar(),
      avatarUrl: () => null,
      errors: {...state.errors}..remove(ProfileFields.avatar),
    ));
  }

  /// The 256 px rendition of an uploaded avatar (or the closest one).
  static String? previewOf(MediaAsset asset) => CompleteProfileCubit.avatarUrlOf(asset);

  /// Adds or removes a field of expertise; a sixth one is refused.
  void toggleExpertise(String fieldId) {
    if (state.submitting) return;
    final ids = [...state.expertiseIds];
    if (!ids.remove(fieldId)) {
      if (state.expertiseFull) return;
      ids.add(fieldId);
    }
    emit(state.copyWith(expertiseIds: ids, errors: {...state.errors}..remove(ProfileFields.expertise)));
  }

  /// Clears a field's server error once it is edited.
  void edited(String field) {
    if (state.errors.containsKey(field)) emit(state.copyWith(errors: {...state.errors}..remove(field)));
  }

  /// `github.com/mona` → `https://github.com/mona`; empty stays empty.
  static String normalizeLink(String value) {
    final link = value.trim();
    if (link.isEmpty || link.contains('://')) return link;
    return 'https://$link';
  }

  static bool isHttpsUrl(String value) {
    if (value.length > ProfileLimits.linkMax) return false;
    final uri = Uri.tryParse(value);
    return uri != null && uri.isAbsolute && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  bool get _expertiseChanged {
    final before = [for (final field in state.profile?.expertise ?? const <ExpertiseField>[]) field.id];
    final now = state.expertiseIds;
    return before.length != now.length || [for (var i = 0; i < now.length; i++) before[i] != now[i]].any((d) => d);
  }

  static String? _linkError(String link) => link.isEmpty || isHttpsUrl(link) ? null : FailureCodes.validationUrl;

  Future<void> submit({
    required String displayName,
    required String bio,
    required String github,
    required String linkedin,
    required String website,
  }) async {
    if (state.busy || state.load != EditProfileLoad.ready) return;
    final name = displayName.trim();
    final links = (github: normalizeLink(github), linkedin: normalizeLink(linkedin), website: normalizeLink(website));
    final errors = Validate.collect({
      ProfileFields.displayName: name.isEmpty
          ? CredentialCodes.required
          : name.length < ProfileLimits.displayNameMin
              ? FailureCodes.validationMinLength
              : (name.length > ProfileLimits.displayNameMax ? FailureCodes.validationMaxLength : null),
      ProfileFields.username: state.username.isEmpty
          ? CredentialCodes.required
          : switch (state.usernameStatus) {
              UsernameStatus.invalid => FailureCodes.usernameInvalid,
              UsernameStatus.taken => FailureCodes.usernameTaken,
              _ => null,
            },
      ProfileFields.bio: bio.trim().length > ProfileLimits.bioMax ? FailureCodes.validationMaxLength : null,
      ProfileFields.github: _linkError(links.github),
      ProfileFields.linkedin: _linkError(links.linkedin),
      ProfileFields.website: _linkError(links.website),
    });
    if (errors.isNotEmpty) return emit(state.copyWith(errors: errors, failure: () => null));

    emit(state.copyWith(status: FormStatus.submitting, errors: const {}, failure: () => null));
    final result = await _update(ProfileUpdate(
      displayName: name,
      username: state.username,
      bio: bio.trim(),
      links: ProfileLinks(github: links.github, linkedin: links.linkedin, website: links.website),
      avatar: state.avatar,
      // Left out when untouched (unchanged on the server); `[]` clears them.
      expertiseFieldIds: _expertiseChanged ? state.expertiseIds : null,
    ));
    if (isClosed) return;
    if (result.failureOrNull case final failure?) {
      final split = formErrorsOf(failure);
      return emit(state.copyWith(
        status: FormStatus.idle,
        errors: split.fields,
        failure: () => split.general,
        usernameStatus: split.fields[ProfileFields.username] == FailureCodes.usernameTaken ? UsernameStatus.taken : null,
      ));
    }
    emit(state.copyWith(status: FormStatus.success));
  }

  /// `PATCH /me` codes that belong to one input.
  static const _codeFields = {
    FailureCodes.usernameTaken: ProfileFields.username,
    FailureCodes.usernameInvalid: ProfileFields.username,
    FailureCodes.profileAvatarInvalid: ProfileFields.avatar,
    FailureCodes.profileExpertiseInvalid: ProfileFields.expertise,
  };

  /// Request properties (camelCase, lower-cased here: `links.gitHub` → `links.github`) → inputs.
  static const _propertyFields = {
    'displayname': ProfileFields.displayName,
    'username': ProfileFields.username,
    'bio': ProfileFields.bio,
    'links.github': ProfileFields.github,
    'links.linkedin': ProfileFields.linkedin,
    'links.website': ProfileFields.website,
    'avatarassetid': ProfileFields.avatar,
    'avatarurl': ProfileFields.avatar,
    'expertisefieldids': ProfileFields.expertise,
  };

  /// Splits a failed save: known codes and validation errors go to their input; anything else (or a validation error
  /// for no input on this form) is shown for the whole form.
  static FormErrors formErrorsOf(Failure failure) {
    if (_codeFields[failure.code] case final field?) return (fields: {field: failure.code}, general: null);
    if (failure.fieldErrors.isEmpty) return (fields: const {}, general: failure);
    final fields = <String, String>{};
    var unmatched = false;
    for (final MapEntry(:key, :value) in failure.fieldErrors.entries) {
      if (value.isEmpty) continue;
      final property = key.toLowerCase().replaceAll(RegExp(r'\[\d+\]$'), '');
      final field = _propertyFields[property];
      if (field == null) {
        unmatched = true;
      } else {
        fields[field] ??= value.first;
      }
    }
    return (fields: fields, general: fields.isEmpty || unmatched ? failure : null);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/security/credential_rules.dart';
import '../../../media/domain/entities/media.dart';
import '../../../media/domain/usecases/media_usecases.dart';
import '../../../profile/domain/entities/profile_link.dart' show HeadlineRules;
import '../../domain/entities/me.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'form_support.dart';

enum UsernameStatus { idle, checking, available, taken, invalid }

class CompleteProfileState extends Equatable {
  const CompleteProfileState({
    this.username = '',
    this.usernameStatus = UsernameStatus.idle,
    this.avatarUrl,
    this.uploadingAvatar = false,
    this.status = FormStatus.idle,
    this.errors = const {},
    this.failure,
  });

  /// The handle the availability applies to.
  final String username;
  final UsernameStatus usernameStatus;
  final String? avatarUrl;
  final bool uploadingAvatar;
  final FormStatus status;
  final Map<String, String> errors;
  final Failure? failure;

  bool get submitting => status == FormStatus.submitting;

  CompleteProfileState copyWith({
    String? username,
    UsernameStatus? usernameStatus,
    String? Function()? avatarUrl,
    bool? uploadingAvatar,
    FormStatus? status,
    Map<String, String>? errors,
    Failure? Function()? failure,
  }) =>
      CompleteProfileState(
        username: username ?? this.username,
        usernameStatus: usernameStatus ?? this.usernameStatus,
        avatarUrl: avatarUrl != null ? avatarUrl() : this.avatarUrl,
        uploadingAvatar: uploadingAvatar ?? this.uploadingAvatar,
        status: status ?? this.status,
        errors: errors ?? this.errors,
        failure: failure != null ? failure() : this.failure,
      );

  @override
  List<Object?> get props => [username, usernameStatus, avatarUrl, uploadingAvatar, status, errors, failure];
}

/// Complete profile after sign up (SPEC §9.2): display name, a unique `@username` checked live, an optional avatar and
/// an optional title (F14).
@injectable
class CompleteProfileCubit extends Cubit<CompleteProfileState> {
  CompleteProfileCubit(this._complete, this._check, this._pickImages, this._upload) : super(const CompleteProfileState());

  final CompleteProfile _complete;
  final CheckUsername _check;
  final PickImages _pickImages;
  final UploadImage _upload;
  Timer? _debounce;

  static const debounce = Duration(milliseconds: 400);
  static final usernamePattern = RegExp(r'^[a-z0-9_]{3,30}$');

  /// Sign up gives every account a placeholder handle (`reader_` + 10 characters); it isn't offered back.
  static final _placeholder = RegExp(r'^reader_[a-z0-9]{10}$');

  static String initialUsername(Me? me) => me == null || _placeholder.hasMatch(me.username) ? '' : me.username;

  static String initialDisplayName(Me? me) =>
      me == null || me.displayName == me.username || _placeholder.hasMatch(me.displayName) ? '' : me.displayName;

  void start(Me? me) {
    emit(state.copyWith(avatarUrl: () => me?.avatarUrl));
    final username = initialUsername(me);
    if (username.isNotEmpty) usernameChanged(username);
  }

  /// Live availability, debounced (~400 ms); stale answers are ignored.
  void usernameChanged(String value) {
    _debounce?.cancel();
    final username = value.trim().toLowerCase();
    final errors = {...state.errors}..remove(Fields.username);
    if (username.isEmpty) {
      return emit(state.copyWith(username: username, usernameStatus: UsernameStatus.idle, errors: errors));
    }
    if (!usernamePattern.hasMatch(username)) {
      return emit(state.copyWith(username: username, usernameStatus: UsernameStatus.invalid, errors: errors));
    }
    emit(state.copyWith(username: username, usernameStatus: UsernameStatus.checking, errors: errors));
    _debounce = Timer(debounce, () => _checkUsername(username));
  }

  Future<void> _checkUsername(String username) async {
    final result = await _check(username);
    if (isClosed || state.username != username) return;
    result.fold(
      (_) => emit(state.copyWith(usernameStatus: UsernameStatus.idle)), // the server checks again on submit
      (availability) => emit(state.copyWith(
        usernameStatus: !availability.valid
            ? UsernameStatus.invalid
            : (availability.available ? UsernameStatus.available : UsernameStatus.taken),
      )),
    );
  }

  /// Picks one photo and uploads it as an avatar (`POST /uploads/images`, purpose `avatar`, compressed first).
  Future<void> pickAvatar() async {
    if (state.uploadingAvatar || state.submitting) return;
    final files = await _pickImages(limit: 1);
    if (files.isEmpty || isClosed) return;
    emit(state.copyWith(uploadingAvatar: true, failure: () => null));
    final result = await _upload(files.first, purpose: 'avatar');
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(uploadingAvatar: false, failure: () => failure)),
      (asset) => emit(state.copyWith(uploadingAvatar: false, avatarUrl: () => avatarUrlOf(asset))),
    );
  }

  void removeAvatar() => emit(state.copyWith(avatarUrl: () => null));

  /// The 256 px rendition (or the closest) of an uploaded avatar.
  static String? avatarUrlOf(MediaAsset asset) {
    final variants = [...asset.variants]..sort((a, b) => a.width.compareTo(b.width));
    if (variants.isEmpty) return null;
    return (variants.where((v) => v.width >= 256).firstOrNull ?? variants.last).url;
  }

  /// The optional title's input (F14); the API's key for its errors too.
  static const headlineField = 'headline';

  Future<void> submit({required String displayName, String headline = ''}) async {
    if (state.submitting || state.uploadingAvatar) return;
    final name = displayName.trim();
    final username = state.username;
    final errors = Validate.collect({
      headlineField: HeadlineRules.problem(headline),
      Fields.displayName: name.isEmpty
          ? CredentialCodes.required
          : (name.length < 2 ? FailureCodes.validationMinLength : (name.length > 60 ? FailureCodes.validationMaxLength : null)),
      Fields.username: username.isEmpty
          ? CredentialCodes.required
          : switch (state.usernameStatus) {
              UsernameStatus.invalid => FailureCodes.usernameInvalid,
              UsernameStatus.taken => FailureCodes.usernameTaken,
              _ => null,
            },
    });
    if (errors.isNotEmpty) return emit(state.copyWith(errors: errors, failure: () => null));

    emit(state.copyWith(status: FormStatus.submitting, errors: const {}, failure: () => null));
    final result = await _complete(
      displayName: name,
      username: username,
      avatarUrl: state.avatarUrl,
      headline: HeadlineRules.normalize(headline),
    );
    if (isClosed) return;
    if (result.failureOrNull case final failure?) {
      final split = failure.toFormErrors(codeFields: const {FailureCodes.usernameTaken: Fields.username});
      return emit(state.copyWith(
        status: FormStatus.idle,
        errors: split.fields,
        failure: () => split.general,
        usernameStatus: split.fields[Fields.username] == FailureCodes.usernameTaken ? UsernameStatus.taken : null,
      ));
    }
    emit(state.copyWith(status: FormStatus.success));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

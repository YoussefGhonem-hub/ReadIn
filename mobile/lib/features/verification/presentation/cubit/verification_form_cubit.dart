import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/security/credential_rules.dart';
import '../../../auth/presentation/cubit/form_support.dart';
import '../../../media/domain/entities/media.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../../../taxonomy/domain/usecases/taxonomy_usecases.dart';
import '../../domain/entities/verification.dart';
import '../../domain/usecases/verification_usecases.dart';
import 'verification_cubit.dart' show VerificationLoad;

/// Inputs of the verification form, named like the request's parts; server errors are mapped onto them.
abstract final class VerificationFormFields {
  static const field = 'fieldId';
  static const jobTitle = 'jobTitle';
  static const proofUrl = 'proofUrl';

  /// The proof file, and "add a link or a file" for both proofs.
  static const proof = 'proof';
  static const note = 'note';
}

class VerificationFormState extends Equatable {
  const VerificationFormState({
    this.fields = const [],
    this.fieldsStatus = VerificationLoad.loading,
    this.fieldId,
    this.proof,
    this.picking = false,
    this.status = FormStatus.idle,
    this.errors = const {},
    this.failure,
    this.created,
  });

  /// Every enabled field (`GET /fields`), for the picker.
  final List<Field> fields;
  final VerificationLoad fieldsStatus;
  final String? fieldId;

  /// The proof file, checked on the device (type and size) when it was picked.
  final PickedMediaFile? proof;

  /// The document picker is open.
  final bool picking;
  final FormStatus status;

  /// Input ([VerificationFormFields]) → error code.
  final Map<String, String> errors;

  /// An error for the whole form.
  final Failure? failure;

  /// The request once it was sent.
  final VerificationRequest? created;

  bool get submitting => status == FormStatus.submitting;

  VerificationFormState copyWith({
    List<Field>? fields,
    VerificationLoad? fieldsStatus,
    String? Function()? fieldId,
    PickedMediaFile? Function()? proof,
    bool? picking,
    FormStatus? status,
    Map<String, String>? errors,
    Failure? Function()? failure,
    VerificationRequest? Function()? created,
  }) =>
      VerificationFormState(
        fields: fields ?? this.fields,
        fieldsStatus: fieldsStatus ?? this.fieldsStatus,
        fieldId: fieldId != null ? fieldId() : this.fieldId,
        proof: proof != null ? proof() : this.proof,
        picking: picking ?? this.picking,
        status: status ?? this.status,
        errors: errors ?? this.errors,
        failure: failure != null ? failure() : this.failure,
        created: created != null ? created() : this.created,
      );

  @override
  List<Object?> get props => [fields, fieldsStatus, fieldId, proof, picking, status, errors, failure, created];
}

/// The verification request form (F19): field, job title (2–100), a proof link (`https://`) and/or a proof file (PDF,
/// JPEG, PNG or WebP up to 10 MB, checked when picked), and an optional note (up to 500). Checked here first, then sent
/// as `multipart/form-data`; the server's errors land on the inputs they belong to.
@injectable
class VerificationFormCubit extends Cubit<VerificationFormState> {
  VerificationFormCubit(this._getFields, this._pickProof, this._submit) : super(const VerificationFormState());

  final GetFields _getFields;
  final PickVerificationProof _pickProof;
  final SubmitVerificationRequest _submit;

  Future<void> loadFields() async {
    emit(state.copyWith(fieldsStatus: VerificationLoad.loading));
    final result = await _getFields();
    if (isClosed) return;
    result.fold(
      (_) => emit(state.copyWith(fieldsStatus: VerificationLoad.failure)),
      (fields) => emit(state.copyWith(fieldsStatus: VerificationLoad.ready, fields: fields)),
    );
  }

  /// A fresh form, with [fieldId] chosen (the request it starts from). The fields stay loaded.
  void begin({String? fieldId}) => emit(VerificationFormState(
        fields: state.fields,
        fieldsStatus: state.fieldsStatus,
        fieldId: fieldId,
      ));

  void selectField(String? fieldId) {
    if (state.submitting) return;
    emit(state.copyWith(fieldId: () => fieldId, errors: _without(VerificationFormFields.field)));
  }

  /// Opens the document picker; a file that isn't an accepted proof is refused with `verification.proof_invalid`.
  Future<void> pickProof() async {
    if (state.submitting || state.picking) return;
    emit(state.copyWith(picking: true));
    final result = await _pickProof();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(picking: false, errors: {...state.errors, VerificationFormFields.proof: failure.code})),
      (file) => emit(file == null
          ? state.copyWith(picking: false)
          : state.copyWith(picking: false, proof: () => file, errors: _without(VerificationFormFields.proof))),
    );
  }

  void removeProof() {
    if (state.submitting) return;
    emit(state.copyWith(proof: () => null, errors: _without(VerificationFormFields.proof)));
  }

  /// Clears an input's error once it is edited. A proof link also answers "add a link or a file".
  void edited(String field) {
    final errors = _without(field);
    if (field == VerificationFormFields.proofUrl && errors[VerificationFormFields.proof] == FailureCodes.verificationProofRequired) {
      errors.remove(VerificationFormFields.proof);
    }
    if (errors.length != state.errors.length) emit(state.copyWith(errors: errors));
  }

  /// The form-level error was shown elsewhere (e.g. the page reloaded because a request is already pending).
  void dismissFailure() {
    if (state.failure != null) emit(state.copyWith(failure: () => null));
  }

  Map<String, String> _without(String field) => {...state.errors}..remove(field);

  /// `linkedin.com/in/mona` → `https://linkedin.com/in/mona`; empty stays empty, another scheme stays as typed.
  static String normalizeUrl(String value) {
    final url = value.trim();
    if (url.isEmpty || url.contains('://')) return url;
    return 'https://$url';
  }

  static bool isHttpsUrl(String value) {
    if (value.length > VerificationLimits.proofUrlMax || value.contains(RegExp(r'\s'))) return false;
    final uri = Uri.tryParse(value);
    return uri != null && uri.isAbsolute && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  Future<void> submit({required String jobTitle, required String proofUrl, required String note}) async {
    if (state.submitting || state.picking) return;
    final title = jobTitle.trim();
    final url = normalizeUrl(proofUrl);
    final text = note.trim();
    final errors = Validate.collect({
      VerificationFormFields.field: state.fieldId == null ? CredentialCodes.required : null,
      VerificationFormFields.jobTitle: title.isEmpty
          ? CredentialCodes.required
          : title.length < VerificationLimits.jobTitleMin
              ? FailureCodes.validationMinLength
              : (title.length > VerificationLimits.jobTitleMax ? FailureCodes.validationMaxLength : null),
      VerificationFormFields.proofUrl: url.isEmpty || isHttpsUrl(url) ? null : FailureCodes.validationUrl,
      VerificationFormFields.proof: url.isEmpty && state.proof == null ? FailureCodes.verificationProofRequired : null,
      VerificationFormFields.note: text.length > VerificationLimits.noteMax ? FailureCodes.validationMaxLength : null,
    });
    if (errors.isNotEmpty) return emit(state.copyWith(errors: errors, failure: () => null));

    emit(state.copyWith(status: FormStatus.submitting, errors: const {}, failure: () => null));
    final result = await _submit(VerificationSubmission(
      fieldId: state.fieldId!,
      jobTitle: title,
      proofUrl: url.isEmpty ? null : url,
      note: text.isEmpty ? null : text,
      proof: state.proof,
    ));
    if (isClosed) return;
    result.fold(
      (failure) {
        final split = formErrorsOf(failure);
        emit(state.copyWith(status: FormStatus.idle, errors: split.fields, failure: () => split.general));
      },
      (request) => emit(state.copyWith(status: FormStatus.success, created: () => request)),
    );
  }

  /// Codes that belong to one input.
  static const _codeFields = {
    FailureCodes.verificationFieldInvalid: VerificationFormFields.field,
    FailureCodes.verificationProofInvalid: VerificationFormFields.proof,
    FailureCodes.verificationProofRequired: VerificationFormFields.proof,
  };

  /// Request parts, lower-cased → inputs.
  static const _partFields = {
    'fieldid': VerificationFormFields.field,
    'jobtitle': VerificationFormFields.jobTitle,
    'proofurl': VerificationFormFields.proofUrl,
    'proof': VerificationFormFields.proof,
    'note': VerificationFormFields.note,
  };

  /// Splits a failed request: known codes and validation errors go to their input; anything else (already pending,
  /// already verified, suspended, offline…) is shown for the whole form.
  static FormErrors formErrorsOf(Failure failure) {
    if (_codeFields[failure.code] case final field?) return (fields: {field: failure.code}, general: null);
    if (failure.fieldErrors.isEmpty) return (fields: const {}, general: failure);
    final fields = <String, String>{};
    var unmatched = false;
    for (final MapEntry(:key, :value) in failure.fieldErrors.entries) {
      if (value.isEmpty) continue;
      final field = _partFields[key.toLowerCase()];
      if (field == null) {
        unmatched = true;
      } else {
        fields[field] ??= value.first;
      }
    }
    return (fields: fields, general: fields.isEmpty || unmatched ? failure : null);
  }
}

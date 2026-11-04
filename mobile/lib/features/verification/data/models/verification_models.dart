import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/verification.dart';

part 'verification_models.freezed.dart';
part 'verification_models.g.dart';

/// `MyVerificationRequestDto.field`.
@freezed
abstract class VerificationFieldModel with _$VerificationFieldModel {
  const VerificationFieldModel._();

  const factory VerificationFieldModel({
    required String id,
    @Default('') String slug,
    @Default('') String name,
  }) = _VerificationFieldModel;

  factory VerificationFieldModel.fromJson(Map<String, dynamic> json) => _$VerificationFieldModelFromJson(json);

  VerificationField toEntity() => VerificationField(id: id, slug: slug, name: name);
}

/// `MyVerificationRequestDto` (F19).
@freezed
abstract class MyVerificationRequestModel with _$MyVerificationRequestModel {
  const MyVerificationRequestModel._();

  const factory MyVerificationRequestModel({
    required String id,
    required String status,
    required VerificationFieldModel field,
    @Default('') String jobTitle,
    String? proofUrl,
    String? proofFileName,
    String? note,
    required DateTime submittedAt,
    DateTime? decidedAt,
    String? rejectionReason,
  }) = _MyVerificationRequestModel;

  factory MyVerificationRequestModel.fromJson(Map<String, dynamic> json) => _$MyVerificationRequestModelFromJson(json);

  VerificationRequest toEntity() => VerificationRequest(
        id: id,
        status: VerificationRequestStatus.fromWire(status),
        field: field.toEntity(),
        jobTitle: jobTitle,
        proofUrl: _text(proofUrl),
        proofFileName: _text(proofFileName),
        note: _text(note),
        submittedAt: submittedAt,
        decidedAt: decidedAt,
        rejectionReason: _text(rejectionReason),
      );

  static String? _text(String? value) => value == null || value.trim().isEmpty ? null : value;
}

/// `VerificationStatusDto` (`GET /me/verification`).
@freezed
abstract class VerificationStatusModel with _$VerificationStatusModel {
  const VerificationStatusModel._();

  const factory VerificationStatusModel({
    @Default(false) bool isVerified,
    @Default(false) bool canRequest,
    MyVerificationRequestModel? request,
  }) = _VerificationStatusModel;

  factory VerificationStatusModel.fromJson(Map<String, dynamic> json) => _$VerificationStatusModelFromJson(json);

  VerificationStatus toEntity() =>
      VerificationStatus(isVerified: isVerified, canRequest: canRequest, request: request?.toEntity());
}

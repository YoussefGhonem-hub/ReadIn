// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerificationFieldModel _$VerificationFieldModelFromJson(
  Map<String, dynamic> json,
) => _VerificationFieldModel(
  id: json['id'] as String,
  slug: json['slug'] as String? ?? '',
  name: json['name'] as String? ?? '',
);

Map<String, dynamic> _$VerificationFieldModelToJson(
  _VerificationFieldModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'name': instance.name,
};

_MyVerificationRequestModel _$MyVerificationRequestModelFromJson(
  Map<String, dynamic> json,
) => _MyVerificationRequestModel(
  id: json['id'] as String,
  status: json['status'] as String,
  field: VerificationFieldModel.fromJson(json['field'] as Map<String, dynamic>),
  jobTitle: json['jobTitle'] as String? ?? '',
  proofUrl: json['proofUrl'] as String?,
  proofFileName: json['proofFileName'] as String?,
  note: json['note'] as String?,
  submittedAt: DateTime.parse(json['submittedAt'] as String),
  decidedAt: json['decidedAt'] == null
      ? null
      : DateTime.parse(json['decidedAt'] as String),
  rejectionReason: json['rejectionReason'] as String?,
);

Map<String, dynamic> _$MyVerificationRequestModelToJson(
  _MyVerificationRequestModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'field': instance.field.toJson(),
  'jobTitle': instance.jobTitle,
  'proofUrl': ?instance.proofUrl,
  'proofFileName': ?instance.proofFileName,
  'note': ?instance.note,
  'submittedAt': instance.submittedAt.toIso8601String(),
  'decidedAt': ?instance.decidedAt?.toIso8601String(),
  'rejectionReason': ?instance.rejectionReason,
};

_VerificationStatusModel _$VerificationStatusModelFromJson(
  Map<String, dynamic> json,
) => _VerificationStatusModel(
  isVerified: json['isVerified'] as bool? ?? false,
  canRequest: json['canRequest'] as bool? ?? false,
  request: json['request'] == null
      ? null
      : MyVerificationRequestModel.fromJson(
          json['request'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$VerificationStatusModelToJson(
  _VerificationStatusModel instance,
) => <String, dynamic>{
  'isVerified': instance.isVerified,
  'canRequest': instance.canRequest,
  'request': ?instance.request?.toJson(),
};

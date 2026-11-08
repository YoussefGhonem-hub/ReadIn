// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LegalModel _$LegalModelFromJson(Map<String, dynamic> json) => _LegalModel(
  termsVersion: json['termsVersion'] as String,
  effectiveAt: json['effectiveAt'] == null
      ? null
      : DateTime.parse(json['effectiveAt'] as String),
  summary: json['summary'] == null
      ? const LegalSummaryModel()
      : LegalSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
  pages: json['pages'] == null
      ? null
      : LegalPagesModel.fromJson(json['pages'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LegalModelToJson(_LegalModel instance) =>
    <String, dynamic>{
      'termsVersion': instance.termsVersion,
      'effectiveAt': ?instance.effectiveAt?.toIso8601String(),
      'summary': instance.summary.toJson(),
      'pages': ?instance.pages?.toJson(),
    };

_LegalSummaryModel _$LegalSummaryModelFromJson(Map<String, dynamic> json) =>
    _LegalSummaryModel(ar: json['ar'] as String?, en: json['en'] as String?);

Map<String, dynamic> _$LegalSummaryModelToJson(_LegalSummaryModel instance) =>
    <String, dynamic>{'ar': ?instance.ar, 'en': ?instance.en};

_LegalPagesModel _$LegalPagesModelFromJson(Map<String, dynamic> json) =>
    _LegalPagesModel(
      terms: json['terms'] as String? ?? '/terms',
      communityGuidelines:
          json['communityGuidelines'] as String? ?? '/community-guidelines',
      privacy: json['privacy'] as String? ?? '/privacy',
    );

Map<String, dynamic> _$LegalPagesModelToJson(_LegalPagesModel instance) =>
    <String, dynamic>{
      'terms': instance.terms,
      'communityGuidelines': instance.communityGuidelines,
      'privacy': instance.privacy,
    };

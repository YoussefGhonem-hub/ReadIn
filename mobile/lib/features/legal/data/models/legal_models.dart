import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/legal.dart';

part 'legal_models.freezed.dart';
part 'legal_models.g.dart';

/// `LegalDto` (F37).
@freezed
abstract class LegalModel with _$LegalModel {
  const LegalModel._();

  const factory LegalModel({
    required String termsVersion,
    DateTime? effectiveAt,
    @Default(LegalSummaryModel()) LegalSummaryModel summary,
    LegalPagesModel? pages,
  }) = _LegalModel;

  factory LegalModel.fromJson(Map<String, dynamic> json) => _$LegalModelFromJson(json);

  LegalInfo toEntity() => LegalInfo(
        termsVersion: termsVersion,
        effectiveAt: effectiveAt,
        summaryAr: _text(summary.ar),
        summaryEn: _text(summary.en),
        pages: pages?.toEntity() ?? LegalPages.defaults,
      );

  static String? _text(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
}

@freezed
abstract class LegalSummaryModel with _$LegalSummaryModel {
  const factory LegalSummaryModel({String? ar, String? en}) = _LegalSummaryModel;

  factory LegalSummaryModel.fromJson(Map<String, dynamic> json) => _$LegalSummaryModelFromJson(json);
}

@freezed
abstract class LegalPagesModel with _$LegalPagesModel {
  const LegalPagesModel._();

  const factory LegalPagesModel({
    @Default('/terms') String terms,
    @Default('/community-guidelines') String communityGuidelines,
    @Default('/privacy') String privacy,
  }) = _LegalPagesModel;

  factory LegalPagesModel.fromJson(Map<String, dynamic> json) => _$LegalPagesModelFromJson(json);

  LegalPages toEntity() => LegalPages(terms: terms, communityGuidelines: communityGuidelines, privacy: privacy);
}

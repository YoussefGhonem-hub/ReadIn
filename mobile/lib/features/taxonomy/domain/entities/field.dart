import 'package:equatable/equatable.dart';

/// A knowledge field (Software → .NET, AI, …), SPEC §1.4.
class Field extends Equatable {
  const Field({
    required this.id,
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    this.icon = 'book-open',
    this.isSensitive = false,
    this.requiresSources = false,
    this.topicCount = 0,
  });

  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;

  /// Lucide icon name from the API (mapped to a Material icon on mobile).
  final String icon;
  final bool isSensitive;

  /// Publishing needs at least one source (Software, Medicine, Health; SPEC F05).
  final bool requiresSources;
  final int topicCount;

  String nameFor(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  @override
  List<Object?> get props => [id, slug, nameAr, nameEn, icon, isSensitive, requiresSources, topicCount];
}

class Topic extends Equatable {
  const Topic({required this.id, required this.fieldId, required this.slug, required this.nameAr, required this.nameEn});

  final String id;
  final String fieldId;
  final String slug;
  final String nameAr;
  final String nameEn;

  String nameFor(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  @override
  List<Object?> get props => [id, fieldId, slug, nameAr, nameEn];
}

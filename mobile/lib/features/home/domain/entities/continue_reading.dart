import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';

/// An unfinished article the viewer was reading (`ContinueReadingDto`, F03): the Home "Continue reading" card.
class ContinueReading extends Equatable {
  const ContinueReading({required this.article, required this.percent, required this.language, required this.updatedAt});

  /// In the language the viewer was reading.
  final ArticleCard article;

  /// 5–100: how far they scrolled.
  final int percent;

  /// The version they were reading: `ar-EG` or `en`.
  final String language;

  /// Their last progress report.
  final DateTime updatedAt;

  /// 0–1 for a progress bar.
  double get fraction => (percent / 100).clamp(0, 1).toDouble();

  @override
  List<Object?> get props => [article, percent, language, updatedAt];
}

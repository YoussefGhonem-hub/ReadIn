import 'package:equatable/equatable.dart';

/// `LegalDto` (`GET /legal`, F37): the Terms version in effect, when it took effect, what changed, and the web pages.
class LegalInfo extends Equatable {
  const LegalInfo({
    required this.termsVersion,
    this.effectiveAt,
    this.summaryAr,
    this.summaryEn,
    this.pages = LegalPages.defaults,
  });

  final String termsVersion;
  final DateTime? effectiveAt;

  /// What changed, in each language; null → the screen's generic text.
  final String? summaryAr;
  final String? summaryEn;
  final LegalPages pages;

  String? summaryFor(String languageCode) => languageCode == 'ar' ? summaryAr : summaryEn;

  @override
  List<Object?> get props => [termsVersion, effectiveAt, summaryAr, summaryEn, pages];
}

/// The legal pages' paths on the web (bilingual, server-rendered), which the app opens in the in-app browser.
class LegalPages extends Equatable {
  const LegalPages({required this.terms, required this.communityGuidelines, required this.privacy});

  static const defaults = LegalPages(terms: '/terms', communityGuidelines: '/community-guidelines', privacy: '/privacy');

  final String terms;
  final String communityGuidelines;
  final String privacy;

  @override
  List<Object?> get props => [terms, communityGuidelines, privacy];
}

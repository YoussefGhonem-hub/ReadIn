import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_links.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/utils/link_opener.dart';
import '../../domain/entities/legal.dart';

/// The legal pages (F37), on the web and opened in the in-app browser in the UI language.
enum LegalPage {
  terms,
  communityGuidelines,
  privacy;

  String pathIn(LegalPages pages) => switch (this) {
        terms => pages.terms,
        communityGuidelines => pages.communityGuidelines,
        privacy => pages.privacy,
      };
}

/// Opens [page] in the in-app browser.
Future<void> openLegalPage(BuildContext context, LegalPage page, {LegalPages pages = LegalPages.defaults}) =>
    openInAppBrowser(AppLinks.legalPage(page.pathIn(pages), language: context.l10n.localeName));

/// Settings → Legal (F18, F37): Terms of Use, Community Guidelines and the Privacy Policy, for everyone.
class LegalLinkTiles extends StatelessWidget {
  const LegalLinkTiles({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget tile(LegalPage page, IconData icon, String title) => ListTile(
          key: ValueKey('legal-${page.name}'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.open_in_new_rounded, size: 20),
          onTap: () => unawaited(openLegalPage(context, page)),
        );
    return Column(
      children: [
        tile(LegalPage.terms, Icons.gavel_rounded, l10n.legalTerms),
        const Divider(height: 1),
        tile(LegalPage.communityGuidelines, Icons.groups_outlined, l10n.legalGuidelines),
        const Divider(height: 1),
        tile(LegalPage.privacy, Icons.privacy_tip_outlined, l10n.legalPrivacy),
      ],
    );
  }
}

/// «أوافق على شروط الاستخدام وقواعد المجتمع» with both names as links (F37): sign up and a new Google / Apple account
/// need it ticked. [errorText] shows under it (`auth.terms_required`).
class TermsAgreement extends StatefulWidget {
  const TermsAgreement({super.key, required this.value, required this.onChanged, this.errorText, this.enabled = true});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  State<TermsAgreement> createState() => _TermsAgreementState();
}

class _TermsAgreementState extends State<TermsAgreement> {
  late final _terms = TapGestureRecognizer()..onTap = () => unawaited(openLegalPage(context, LegalPage.terms));
  late final _guidelines = TapGestureRecognizer()
    ..onTap = () => unawaited(openLegalPage(context, LegalPage.communityGuidelines));

  @override
  void dispose() {
    _terms.dispose();
    _guidelines.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final link = TextStyle(color: colors.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline);
    final error = widget.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                key: const ValueKey('terms-agree'),
                value: widget.value,
                isError: error != null,
                onChanged: widget.enabled ? (on) => widget.onChanged(on ?? false) : null,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text.rich(
                    TextSpan(
                      style: context.textTheme.bodyMedium,
                      children: [
                        TextSpan(text: l10n.termsAgreeLead),
                        TextSpan(text: l10n.legalTerms, style: link, recognizer: _terms),
                        TextSpan(text: l10n.termsAgreeAnd),
                        TextSpan(text: l10n.legalGuidelines, style: link, recognizer: _guidelines),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 48, top: ReadInSpace.s1),
            child: Text(error, style: context.textTheme.bodySmall?.copyWith(color: colors.error)),
          ),
      ],
    );
  }
}

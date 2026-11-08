import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/app/router.dart';
import 'package:readin/core/config/app_links.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/admin/presentation/admin_routes.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/auth/domain/repositories/auth_repository.dart';
import 'package:readin/features/auth/domain/usecases/auth_usecases.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/auth/presentation/widgets/external_sign_in.dart';
import 'package:readin/features/legal/domain/entities/legal.dart';
import 'package:readin/features/legal/domain/repositories/legal_repository.dart';
import 'package:readin/features/legal/domain/usecases/legal_usecases.dart';
import 'package:readin/features/legal/presentation/cubit/accept_terms_cubit.dart';
import 'package:readin/features/legal/presentation/pages/accept_terms_page.dart';
import 'package:readin/features/legal/presentation/widgets/legal_links.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';
import 'package:readin/shared/rdoc/rdoc_scope.dart';
import 'package:readin/shared/rdoc/rdoc_text.dart';
import 'package:readin/shared/utils/link_opener.dart';

import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class _MockLegalRepository extends Mock implements LegalRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

const _en = Variant(AppLocales.en, Brightness.light);

const _legal = LegalInfo(termsVersion: '2026-11-08', summaryAr: 'أضفنا قواعد المجتمع.', summaryEn: 'We added the Community Guidelines.');

/// F37's terms: the blocking terms screen and where it sits among the guards, the legal pages (the in-app browser),
/// the checkbox of a new Google / Apple account, and F36's unlinked mentions in the reader.
void main() {
  late AppLocalizations l10n;
  late List<String> opened;
  final realOpener = openInAppBrowser;

  setUpAll(() async => l10n = await AppLocalizations.delegate.load(AppLocales.en));

  setUp(() {
    opened = [];
    openInAppBrowser = (url) async {
      opened.add(url);
      return true;
    };
  });

  tearDown(() => openInAppBrowser = realOpener);

  Me me({String? termsVersion, bool mustAccept = true, List<String> permissions = const []}) => Me(
        id: 'u-1',
        displayName: 'Mona',
        username: 'mona',
        onboardingCompleted: true,
        termsVersion: termsVersion,
        mustAcceptTerms: mustAccept,
        permissions: permissions,
      );

  group('the blocking terms screen', () {
    late _MockLegalRepository legal;
    late _MockAccountRepository accounts;
    late MockSessionCubit session;

    setUp(() {
      legal = _MockLegalRepository();
      accounts = _MockAccountRepository();
      when(() => legal.getLegal()).thenAnswer((_) async => const Ok(_legal));
      when(() => accounts.acceptTerms()).thenAnswer((_) async => Ok(me(termsVersion: '2026-11-08', mustAccept: false)));
    });

    Future<AcceptTermsCubit> pump(WidgetTester tester, {String? termsVersion}) async {
      usePhoneSurface(tester, size: const Size(390, 1000));
      session = MockSessionCubit()..hold(SessionState(status: SessionStatus.authenticated, me: me(termsVersion: termsVersion)));
      when(() => session.signOut()).thenAnswer((_) async {});
      // The page's BlocProvider owns it and closes it.
      final cubit = AcceptTermsCubit(GetLegal(legal), AcceptTerms(accounts));
      await tester.pumpWidget(testApp(
        BlocProvider<SessionCubit>.value(value: session, child: AcceptTermsPage(cubit: cubit)),
        variant: _en,
      ));
      await tester.pumpAndSettle();
      return cubit;
    }

    testWidgets('a newer version: what changed, the three pages, I agree; no way back', (tester) async {
      await pump(tester, termsVersion: '2026-01-01');
      expect(find.text(l10n.termsGateTitleUpdated), findsOneWidget);
      expect(find.text('We added the Community Guidelines.'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);

      await tester.tap(find.byKey(const ValueKey('terms-open-terms')));
      await tester.tap(find.byKey(const ValueKey('terms-open-communityGuidelines')));
      await tester.tap(find.byKey(const ValueKey('terms-open-privacy')));
      expect(opened, [
        '${AppLinks.webOrigin}/terms?lang=en',
        '${AppLinks.webOrigin}/community-guidelines?lang=en',
        '${AppLinks.webOrigin}/privacy?lang=en',
      ]);

      await tester.tap(find.text(l10n.termsGateAgree));
      await tester.pumpAndSettle();
      verify(() => accounts.acceptTerms()).called(1);
    });

    testWidgets('never accepted: the first-time title; a refusal says why; Sign out declines', (tester) async {
      when(() => accounts.acceptTerms()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      await pump(tester);
      expect(find.text(l10n.termsGateTitleFirst), findsOneWidget);

      await tester.tap(find.text(l10n.termsGateAgree));
      await tester.pumpAndSettle();
      expect(find.text(l10n.errOffline), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('terms-sign-out')));
      verify(() => session.signOut()).called(1);
      expect(find.byKey(const ValueKey('terms-delete-account')), findsOneWidget);
    });

    testWidgets('without GET /legal the screen still works, in generic words', (tester) async {
      when(() => legal.getLegal()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      await pump(tester, termsVersion: '2026-01-01');
      expect(find.byKey(const ValueKey('terms-summary')), findsNothing);
      expect(find.text(l10n.termsGateBody), findsOneWidget);
      expect(find.text(l10n.termsGateAgree), findsOneWidget);
    });
  });

  group('the guards (SPEC §9.2)', () {
    String? redirect(String location, Me account) => resolveRedirect(
          uri: Uri.parse(location),
          session: SessionState(status: SessionStatus.authenticated, me: account),
          settings: const AppSettings(welcomeSeen: true),
        );

    test('the terms screen comes after the password and PIN, before the profile; nothing else opens', () {
      expect(redirect('/home', me()), AcceptTermsPage.path);
      expect(redirect('/a/di-dotnet', me()), AcceptTermsPage.path);
      expect(redirect(AcceptTermsPage.path, me()), isNull);
      expect(redirect('/splash', me()), AcceptTermsPage.path);
    });

    test('declining offers deleting the account, over the terms screen', () {
      expect(redirect(AppRoutes.deleteAccount, me()), isNull);
    });

    test('once accepted, the terms screen leads home (the admin to the dashboard)', () {
      expect(redirect(AcceptTermsPage.path, me(termsVersion: '2026-11-08', mustAccept: false)), AppRoutes.home);
      expect(
        redirect(AcceptTermsPage.path, me(termsVersion: '2026-11-08', mustAccept: false, permissions: [Permissions.adminAccess])),
        AdminRoutes.consoleDashboard,
      );
    });

    test('guests never see it', () {
      expect(
        resolveRedirect(
          uri: Uri.parse(AcceptTermsPage.path),
          session: const SessionState(status: SessionStatus.guest),
          settings: const AppSettings(welcomeSeen: true),
        ),
        AppRoutes.home,
      );
    });
  });

  group('the legal pages', () {
    testWidgets('Settings → Legal: Terms of Use, Community Guidelines, Privacy Policy in the in-app browser', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(const Scaffold(body: LegalLinkTiles()), variant: const Variant(AppLocales.ar, Brightness.light)));
      final ar = await AppLocalizations.delegate.load(AppLocales.ar);
      expect(find.text(ar.legalTerms), findsOneWidget);
      expect(find.text(ar.legalGuidelines), findsOneWidget);
      expect(find.text(ar.legalPrivacy), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('legal-terms')));
      await tester.tap(find.byKey(const ValueKey('legal-privacy')));
      expect(opened, ['${AppLinks.webOrigin}/terms?lang=ar', '${AppLinks.webOrigin}/privacy?lang=ar']);
    });

    test('a page path becomes a link of the web origin in the UI language', () {
      expect(AppLinks.legalPage('/community-guidelines', language: 'en'), '${AppLinks.webOrigin}/community-guidelines?lang=en');
      expect(AppLinks.legalPage('terms', language: 'ar'), '${AppLinks.webOrigin}/terms?lang=ar');
    });

    testWidgets('a new Google / Apple account: Create stays off until the Terms box is ticked; the names are links', (tester) async {
      usePhoneSurface(tester);
      NotLinkedChoice? choice;
      await tester.pumpWidget(testApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => choice = await showExternalNotLinkedSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
        variant: _en,
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final create = find.byKey(const ValueKey('external-create-account'));
      expect(tester.widget<FilledButton>(create).onPressed, isNull);

      final rich = tester.widget<RichText>(
        find.descendant(of: find.byType(TermsAgreement), matching: find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Terms of Use'))),
      );
      final links = <InlineSpan>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.recognizer != null) links.add(span);
        return true;
      });
      expect(links, hasLength(2), reason: 'Terms of Use and Community Guidelines open their pages');
      ((links.first as TextSpan).recognizer! as TapGestureRecognizer).onTap!();
      expect(opened, ['${AppLinks.webOrigin}/terms?lang=en']);

      await tester.tap(find.byKey(const ValueKey('terms-agree')));
      await tester.pump();
      expect(tester.widget<FilledButton>(create).onPressed, isNotNull);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(choice, NotLinkedChoice.createAccount);
    });
  });

  group('mentions of people the reader is blocked with (F36)', () {
    testWidgets('read as plain text, with no link; the others stay links', (tester) async {
      final tapped = <String>[];
      const nodes = <RInline>[RMention(userId: 'u-9', text: '@omar'), RText(' and '), RMention(userId: 'u-2', text: '@mona')];
      await tester.pumpWidget(testApp(
        Scaffold(
          body: RDocScope(
            baseDirection: TextDirection.ltr,
            onMentionTap: (mention) => tapped.add(mention.userId),
            unlinkedMentionIds: const {'u-9'},
            child: const RDocText(nodes, style: TextStyle(), direction: TextDirection.ltr),
          ),
        ),
        variant: _en,
      ));
      final rich = tester.widget<RichText>(find.byType(RichText).first);
      final spans = <TextSpan>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });
      final omar = spans.firstWhere((s) => s.text!.contains('@omar'));
      final mona = spans.firstWhere((s) => s.text!.contains('@mona'));
      expect(omar.recognizer, isNull);
      expect(mona.recognizer, isNotNull);
    });
  });
}

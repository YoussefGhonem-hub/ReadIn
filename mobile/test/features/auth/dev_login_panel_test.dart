import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/auth/presentation/widgets/dev_login_panel.dart';
import 'package:readin/shared/widgets/badges.dart';

import '../../helpers/test_app.dart';

/// The demo sign-in panel (SPEC §18.3) after the roles change (SPEC §10): every account is a Member or the
/// SuperAdmin, and the verified writers are Members with the Verified badge.
void main() {
  group('the demo accounts', () {
    test('no demo admin or moderator: one SuperAdmin, everyone else a Member', () {
      final phones = DevLogin.users.map((user) => user.phone).toList();
      expect(phones, isNot(contains('+12025550102')));
      expect(phones, isNot(contains('+12025550103')));
      expect(phones.toSet(), hasLength(phones.length));
      expect(phones, hasLength(17));

      expect(DevLogin.users.where((user) => user.role == 'SuperAdmin').map((user) => user.phone), ['+12025550101']);
      for (final user in DevLogin.users) {
        expect(user.role, anyOf('SuperAdmin', 'Member'), reason: user.phone);
      }
    });

    test('the suspended account is a Member marked suspended, not a role of its own', () {
      expect(DevLogin.users.where((user) => user.suspended).map((user) => (user.phone, user.name, user.role)), [
        ('+12025550120', 'Suspended User', 'Member'),
      ]);
    });

    test('the verified writers are Members with the badge, and nobody else has it', () {
      expect(DevLogin.users.where((user) => user.verified).map((user) => (user.phone, user.name, user.role)), [
        ('+12025550104', '.NET Writer', 'Member'),
        ('+12025550105', 'AI Writer', 'Member'),
      ]);
    });

    test('the "Verified Writer" demo account (+12025550106) is gone (no demo articles, pre-production step)', () {
      expect(DevLogin.users.map((user) => user.phone), isNot(contains('+12025550106')));
      expect(DevLogin.users.map((user) => user.name), isNot(contains('Verified Writer')));
    });
  });

  for (final variant in Variant.all) {
    testWidgets('the sheet shows "Member" with the badge and its label, never an old role (${variant.name})', (tester) async {
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      SeedUser? picked;
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(onPressed: () async => picked = await showDevLoginSheet(context), child: const Text('open')),
            ),
          ),
        ),
        variant: variant,
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('+1 202-555-0101 · SuperAdmin'), findsOneWidget);
      for (final phone in ['0104', '0105']) {
        expect(find.textContaining('+1 202-555-$phone · Member'), findsOneWidget, reason: phone);
      }
      expect(find.byType(VerifiedMark), findsNWidgets(2));
      expect(find.text(l10n.verifiedWriter), findsNWidgets(2));
      expect(find.textContaining('+1 202-555-0106'), findsNothing);
      expect(find.textContaining('+1 202-555-0107 · Member'), findsOneWidget);
      for (final gone in ['Admin User', 'Moderator User', 'VerifiedWriter', 'Verified Writer', '· Admin', '· Moderator']) {
        expect(find.textContaining(gone), findsNothing, reason: gone);
      }

      await tester.tap(find.text('.NET Writer'));
      await tester.pumpAndSettle();
      expect(picked?.phone, '+12025550104');
      expect(picked?.verified, isTrue);
    });

    testWidgets('the suspended account reads "Member · suspended" in the sheet\'s language (${variant.name})', (tester) async {
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(onPressed: () => showDevLoginSheet(context), child: const Text('open')),
            ),
          ),
        ),
        variant: variant,
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The last row of the list.
      await tester.dragUntilVisible(find.text('Suspended User'), find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.textContaining('+1 202-555-0120 · Member · ${l10n.devLoginSuspended}'), findsOneWidget);
      expect(find.textContaining('(suspended)'), findsNothing);
    });
  }
}

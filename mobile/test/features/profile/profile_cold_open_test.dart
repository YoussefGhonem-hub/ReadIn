import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/profile/presentation/pages/profile_page.dart';

import '../../helpers/path_fakes.dart' show pumpRouted;
import '../../helpers/profile_fakes.dart';
import '../../helpers/profile_fixtures.dart';
import '../../helpers/test_app.dart';

/// A profile (`/u/{username}`, F14) opened with no page under it (a link, or Back from a category page that a link
/// opened) has a back button that goes Home, like the reader and the tag page; opened from the app it keeps the usual
/// back button, and the Profile tab has none.
void main() {
  testWidgets('opened from a link with no page under it, back goes Home', (tester) async {
    final opened = <String>[];
    await pumpRouted(tester, const ProfileView(), opened: opened, providers: profileScreen(otherProfile));
    await tester.pump();

    final home = find.byKey(ProfileView.homeKey);
    expect(home, findsOneWidget);
    expect(tester.widget<IconButton>(home).tooltip, const DefaultMaterialLocalizations().backButtonTooltip,
        reason: 'a labelled button, like the usual back button');
    await tester.tap(home);
    await tester.pumpAndSettle();
    expect(opened, ['/home']);
  });

  for (final variant in [const Variant(AppLocales.ar, Brightness.light), const Variant(AppLocales.en, Brightness.dark)]) {
    testWidgets('opened from the app, the usual back button goes back ${variant.name}', (tester) async {
      usePhoneSurface(tester);
      final providers = [...appStores(), ...profileScreen(otherProfile)];
      await tester.pumpWidget(testApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => provided(providers, const ProfileView()))),
            child: const Text('open profile'),
          ),
        ),
        variant: variant,
      ));
      await tester.tap(find.text('open profile'));
      await tester.pumpAndSettle();

      expect(find.byKey(ProfileView.homeKey), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('open profile'), findsOneWidget);
    });
  }

  testWidgets('the Profile tab has no back button', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(testApp(provided([...appStores(), ...profileScreen(ownProfile)], const ProfileView(isTab: true))));
    await tester.pump();
    expect(find.byKey(ProfileView.homeKey), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });
}

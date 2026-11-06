@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/app/main_nav_bar.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/theme_x.dart';
import 'package:readin/core/theme/tokens.g.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/home/presentation/widgets/more_sheet.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';

import '../helpers/profile_fakes.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

/// A moderator who writes and isn't verified yet: every screen of the More sheet shows.
const _me = Me(
  id: 'u-1',
  displayName: 'Youssef Hassan',
  username: 'reader1',
  onboardingCompleted: true,
  permissions: [Permissions.articlesCreate, Permissions.moderationManage],
);

/// The bottom bar in ar/light and en/dark (SPEC §27), icons only, with Home open (the ring round the mark) and with
/// Saved open, over the end of a page so the mark is seen rising over it; and the More sheet it opens, signed in and
/// as a guest.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Variant variant, {
    required int branch,
    Size size = const Size(390, 220),
    Me? me = _me,
  }) async {
    usePhoneSurface(tester, size: size);
    final session = MockSessionCubit()
      ..hold(
        me == null
            ? const SessionState(status: SessionStatus.guest)
            : SessionState(status: SessionStatus.authenticated, me: me),
      );
    final settings = MockSettingsCubit()
      ..hold(
        AppSettings(
          uiLanguage: variant.locale.languageCode,
          theme: variant.brightness == Brightness.dark ? ThemePreference.dark : ThemePreference.light,
        ),
      );
    final unread = MockUnreadBadgeCubit()..hold(3);
    await tester.pumpWidget(
      testApp(
        provided(
          [BlocProvider<SessionCubit>.value(value: session), BlocProvider<SettingsCubit>.value(value: settings)],
          Builder(
            builder: (context) => Scaffold(
              body: const _PageEnd(),
              bottomNavigationBar: MainNavBar(
                currentIndex: branch,
                onSelect: (_) {},
                onMore: () => showMoreSheet(context, unread: unread),
              ),
            ),
          ),
        ),
        variant: variant,
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final variant in Variant.golden) {
    for (final (name, branch) in [('home', 0), ('saved', 3)]) {
      testWidgets('main nav bar, $name open, ${variant.name}', (tester) async {
        await pump(tester, variant, branch: branch);
        await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/main_nav_bar_${name}_${variant.name}.png'));
      });
    }

    for (final (name, me) in [('more_sheet', _me), ('more_sheet_guest', null)]) {
      testWidgets('$name ${variant.name}', (tester) async {
        await pump(tester, variant, branch: 0, size: const Size(390, 844), me: me);
        await tester.tap(find.byTooltip(lookupAppLocalizations(variant.locale).navMore));
        await tester.pumpAndSettle();
        expect(find.byType(MoreSheet), findsOneWidget);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${name}_${variant.name}.png'));
      });
    }
  }
}

/// The last card of a feed on the grey canvas.
class _PageEnd extends StatelessWidget {
  const _PageEnd();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.bg,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 110,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 12, width: 220, decoration: _bar(colors)),
              const SizedBox(height: 10),
              Container(height: 12, width: 300, decoration: _bar(colors)),
              const SizedBox(height: 10),
              Container(height: 12, width: 160, decoration: _bar(colors)),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _bar(ReadInColors colors) =>
      BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(ReadInRadius.sm));
}

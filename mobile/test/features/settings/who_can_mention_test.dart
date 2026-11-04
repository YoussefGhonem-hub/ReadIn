import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/cubit/linked_accounts_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/profile/domain/usecases/profile_usecases.dart';
import 'package:readin/features/profile/presentation/cubit/privacy_cubit.dart';
import 'package:readin/features/profile/presentation/widgets/public_reading_stats_switch.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/features/settings/presentation/pages/settings_page.dart';
import 'package:readin/features/settings/presentation/widgets/who_can_mention_selector.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockSetPrivacy extends Mock implements SetPrivacy {}

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockLinkedAccountsCubit extends MockCubit<LinkedAccountsState> implements LinkedAccountsCubit {}

/// Settings → Privacy → "Who can mention me" (F18): three choices, saved at once with the whole privacy object, rolled
/// back with the translated reason when refused, signed in only.
void main() {
  late MockSetPrivacy setPrivacy;
  late MockSessionCubit session;

  setUpAll(() {
    registerFallbackValue(const PrivacySettings());
    registerFallbackValue(MentionPolicy.everyone);
  });

  setUp(() {
    setPrivacy = MockSetPrivacy();
    session = MockSessionCubit()..hold(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
  });

  RadioListTile<MentionPolicy> radio(WidgetTester tester, MentionPolicy policy) =>
      tester.widget<RadioListTile<MentionPolicy>>(find.byKey(ValueKey('who-can-mention-${policy.wire}')));

  MentionPolicy? selected(WidgetTester tester) =>
      tester.widget<RadioGroup<MentionPolicy>>(find.byType(RadioGroup<MentionPolicy>)).groupValue;

  /// The whole Settings page, as the session has it (or as a guest), over a real [PrivacyCubit].
  Future<PrivacyCubit> pumpSettings(WidgetTester tester, Variant variant, {bool guest = false}) async {
    if (guest) session.hold(const SessionState(status: SessionStatus.guest));
    final privacy = PrivacyCubit(setPrivacy, session);
    addTearDown(privacy.close);
    usePhoneSurface(tester, size: const Size(390, 900));
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<SessionCubit>.value(value: session),
        BlocProvider<SettingsCubit>.value(value: MockSettingsCubit()..hold(const AppSettings())),
        BlocProvider<LinkedAccountsCubit>.value(value: MockLinkedAccountsCubit()..hold(const LinkedAccountsState())),
        BlocProvider<PrivacyCubit>.value(value: privacy),
      ],
      child: testApp(const SettingsView(), variant: variant),
    ));
    await tester.pumpAndSettle();
    return privacy;
  }

  for (final variant in Variant.all) {
    testWidgets('the Privacy card has the reading stats switch and who can mention me ${variant.name}', (tester) async {
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      await pumpSettings(tester, variant);
      await tester.scrollUntilVisible(find.text(l10n.profileWhoCanMentionNobody), 200);
      await tester.pumpAndSettle();

      final card = find.ancestor(of: find.text(l10n.profilePrivacy), matching: find.byType(Card));
      expect(find.descendant(of: card, matching: find.byType(PublicReadingStatsSwitch)), findsOneWidget);
      expect(find.descendant(of: card, matching: find.byType(WhoCanMentionSelector)), findsOneWidget);
      expect(find.text(l10n.profileWhoCanMention), findsOneWidget);
      for (final policy in MentionPolicy.values) {
        expect(find.text(WhoCanMentionSelector.label(l10n, policy)), findsOneWidget);
        expect(radio(tester, policy).enabled, isTrue);
      }
      expect(selected(tester), MentionPolicy.everyone, reason: 'the default');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a choice is shown at once, ignores taps while saving, and stays once saved ${variant.name}', (tester) async {
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      final saving = Completer<Result<void>>();
      when(() => setPrivacy(any())).thenAnswer((_) => saving.future);
      final privacy = await pumpSettings(tester, variant);
      await tester.scrollUntilVisible(find.text(l10n.profileWhoCanMentionNobody), 200);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.profileWhoCanMentionFollowing));
      await tester.pump();
      expect(selected(tester), MentionPolicy.following);
      for (final policy in MentionPolicy.values) {
        expect(radio(tester, policy).enabled, isFalse, reason: 'saving');
      }
      await tester.tap(find.text(l10n.profileWhoCanMentionNobody), warnIfMissed: false);
      await tester.pump();

      saving.complete(const Ok(null));
      await tester.pumpAndSettle();
      expect(selected(tester), MentionPolicy.following);
      expect(radio(tester, MentionPolicy.nobody).enabled, isTrue);
      expect(privacy.state, const PrivacyState(whoCanMention: MentionPolicy.following));
      // The whole privacy object, once: the tap while saving was ignored.
      verify(() => setPrivacy(const PrivacySettings(whoCanMention: MentionPolicy.following))).called(1);
      verifyNoMoreInteractions(setPrivacy);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a refused choice goes back and says why, translated ${variant.name}', (tester) async {
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      when(() => setPrivacy(any())).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      session.hold(const SessionState(
        status: SessionStatus.authenticated,
        me: Me(id: 'u-1', displayName: 'Y', username: 'reader1', whoCanMention: MentionPolicy.following),
      ));
      await pumpSettings(tester, variant);
      await tester.scrollUntilVisible(find.text(l10n.profileWhoCanMentionNobody), 200);
      await tester.pumpAndSettle();
      expect(selected(tester), MentionPolicy.following, reason: 'from MeDto.privacy');

      await tester.tap(find.text(l10n.profileWhoCanMentionNobody));
      await tester.pumpAndSettle();

      verify(() => setPrivacy(const PrivacySettings(whoCanMention: MentionPolicy.nobody))).called(1);
      expect(selected(tester), MentionPolicy.following, reason: 'rolled back');
      expect(find.text(l10n.errOffline), findsOneWidget);
      expect(radio(tester, MentionPolicy.nobody).enabled, isTrue, reason: 'it can be tried again');
    });

    testWidgets('guests have no privacy settings ${variant.name}', (tester) async {
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      await pumpSettings(tester, variant, guest: true);
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.text(l10n.profilePrivacy), findsNothing);
      expect(find.byType(WhoCanMentionSelector), findsNothing);
    });
  }

  testWidgets('the selector alone, while a change saves: the new value shows and nothing can be picked', (tester) async {
    final privacy = MockPrivacyCubit()..hold(const PrivacyState(whoCanMention: MentionPolicy.nobody, pending: true));
    await tester.pumpWidget(testApp(
      BlocProvider<PrivacyCubit>.value(value: privacy, child: const Scaffold(body: WhoCanMentionSelector())),
      variant: const Variant(AppLocales.en, Brightness.light),
    ));
    await tester.pump();

    expect(selected(tester), MentionPolicy.nobody);
    await tester.tap(find.text('Everyone'), warnIfMissed: false);
    await tester.pump();
    verifyNever(() => privacy.setWhoCanMention(any()));
  });
}

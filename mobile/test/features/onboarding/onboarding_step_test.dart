import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/notifications/presentation/cubit/notification_settings_cubit.dart';
import 'package:readin/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:readin/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/features/taxonomy/domain/entities/field.dart';

import '../../helpers/fixtures.dart' show sampleMe;
import '../../helpers/social_fakes.dart' show MockSessionCubit;
import '../../helpers/test_app.dart';

class MockOnboardingCubit extends MockCubit<OnboardingState> implements OnboardingCubit {}

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockNotificationSettingsCubit extends MockCubit<NotificationSettingsState> implements NotificationSettingsCubit {}

/// Onboarding's step count (F02): the welcome step is the Welcome screen before sign up, so the screen opens on
/// "Step 1 of 2" (interests) and ends on "Step 2 of 2" (preferences), with its progress bar to match.
void main() {
  const fields = [
    Field(id: 'f1', slug: 'software', nameAr: 'البرمجيات', nameEn: 'Software'),
    Field(id: 'f2', slug: 'medicine', nameAr: 'الطب', nameEn: 'Medicine'),
  ];

  Future<void> pumpStep(WidgetTester tester, OnboardingStep step, Variant variant) async {
    usePhoneSurface(tester);
    final onboarding = MockOnboardingCubit();
    final settings = MockSettingsCubit();
    final notifications = MockNotificationSettingsCubit();
    final session = MockSessionCubit();
    whenListen(onboarding, const Stream<OnboardingState>.empty(), initialState: OnboardingState(step: step, fields: fields));
    whenListen(settings, const Stream<AppSettings>.empty(), initialState: const AppSettings());
    whenListen(notifications, const Stream<NotificationSettingsState>.empty(), initialState: const NotificationSettingsState());
    whenListen(session, const Stream<SessionState>.empty(), initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<OnboardingCubit>.value(value: onboarding),
          BlocProvider<SettingsCubit>.value(value: settings),
          BlocProvider<NotificationSettingsCubit>.value(value: notifications),
          BlocProvider<SessionCubit>.value(value: session),
        ],
        child: const OnboardingView(),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  double progress(WidgetTester tester) => tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value!;

  for (final variant in Variant.all) {
    final en = variant.locale == AppLocales.en;

    testWidgets('the first step is step 1 of 2 ${variant.name}', (tester) async {
      await pumpStep(tester, OnboardingStep.interests, variant);
      expect(find.text(en ? 'Step 1 of 2' : 'الخطوة 1 من 2'), findsOneWidget);
      expect(progress(tester), 0.5);
    });

    testWidgets('the last step is step 2 of 2 ${variant.name}', (tester) async {
      await pumpStep(tester, OnboardingStep.preferences, variant);
      expect(find.text(en ? 'Step 2 of 2' : 'الخطوة 2 من 2'), findsOneWidget);
      expect(progress(tester), 1);
    });
  }
}

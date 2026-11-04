import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/formatters.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/cubit/linked_accounts_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/profile/presentation/cubit/privacy_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/features/settings/presentation/pages/settings_page.dart';
import 'package:readin/features/taxonomy/domain/usecases/taxonomy_usecases.dart';
import 'package:readin/features/verification/domain/entities/verification.dart';
import 'package:readin/features/verification/domain/usecases/verification_usecases.dart';
import 'package:readin/features/verification/presentation/cubit/verification_cubit.dart';
import 'package:readin/features/verification/presentation/cubit/verification_form_cubit.dart';
import 'package:readin/features/verification/presentation/pages/verification_page.dart';
import 'package:readin/features/verification/presentation/widgets/verification_entry_tile.dart';
import 'package:readin/features/verification/presentation/widgets/verification_form.dart';
import 'package:readin/features/verification/presentation/widgets/verification_status_views.dart';

import '../../helpers/editor_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';
import '../../helpers/verification_fixtures.dart';

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockLinkedAccountsCubit extends MockCubit<LinkedAccountsState> implements LinkedAccountsCubit {}

const offline = Failure(FailureCodes.networkOffline);
const _en = Variant(AppLocales.en, Brightness.light);

/// Settings → Writer verification (F19): every state of the page, the form and its checks, withdrawing, requesting
/// again, and the Settings row.
void main() {
  late FakeVerificationRepository repository;
  late FakeProofFilePicker picker;
  late MockSessionCubit session;

  setUp(() {
    repository = FakeVerificationRepository();
    picker = FakeProofFilePicker();
    session = MockSessionCubit()..hold(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    when(session.refresh).thenAnswer((_) async {});
  });

  VerificationCubit statusCubit() =>
      VerificationCubit(GetVerificationStatus(repository), WithdrawVerificationRequest(repository), session);

  VerificationFormCubit formCubit() =>
      VerificationFormCubit(GetFields(FakeTaxonomyRepository()), PickVerificationProof(picker), SubmitVerificationRequest(repository));

  /// The page over real cubits and the fake repository, tall enough that nothing scrolls.
  Future<void> pumpPage(WidgetTester tester, {Variant variant = _en, VerificationStatus? status}) async {
    if (status != null) repository.status = status;
    final cubit = statusCubit();
    final form = formCubit();
    addTearDown(cubit.close);
    addTearDown(form.close);
    unawaited(cubit.load());
    unawaited(form.loadFields());
    usePhoneSurface(tester, size: const Size(390, 1500));
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<VerificationCubit>.value(value: cubit),
          BlocProvider<VerificationFormCubit>.value(value: form),
          BlocProvider<SessionCubit>.value(value: session),
        ],
        child: const VerificationView(),
      ),
      variant: variant,
    ));
    await tester.pumpAndSettle();
  }

  String date(AppLocalizations l10n, DateTime at) => formatDate(at, l10n.localeName);

  Future<void> chooseField(WidgetTester tester, String name) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  for (final variant in Variant.all) {
    testWidgets('the form: field, job title, link and file, then pending with its date and Withdraw ${variant.name}', (tester) async {
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      final ai = editorFields.singleWhere((f) => f.id == 'f-ai').nameFor(variant.locale.languageCode);
      picker.next = pdfProof;
      await pumpPage(tester, variant: variant);

      expect(find.text(l10n.verificationIntro), findsOneWidget);
      expect(find.text(l10n.verificationProofPrivate), findsOneWidget);
      expect(find.text(l10n.verificationProofFileHint), findsOneWidget);
      expect(find.byType(VerificationPendingView), findsNothing);

      await chooseField(tester, ai);
      await tester.enterText(find.byKey(VerificationForm.jobTitleKey), 'Senior Backend Engineer');
      await tester.enterText(find.byKey(VerificationForm.proofUrlKey), 'github.com/youssef');
      await tester.tap(find.byKey(VerificationForm.attachKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('.pdf'), findsOneWidget);
      expect(find.text(l10n.fileSizeMb('2.4')), findsOneWidget);
      await tester.enterText(find.byKey(VerificationForm.noteKey), 'بكتب عن الـ .NET من 2019');
      await tester.tap(find.byKey(VerificationForm.submitKey));
      await tester.pumpAndSettle();

      expect(repository.submissions.single, const VerificationSubmission(
        fieldId: 'f-ai',
        jobTitle: 'Senior Backend Engineer',
        proofUrl: 'https://github.com/youssef',
        note: 'بكتب عن الـ .NET من 2019',
        proof: pdfProof,
      ));
      expect(find.byType(VerificationPendingView), findsOneWidget);
      expect(find.text(l10n.verificationPendingTitle), findsOneWidget);
      expect(find.text(l10n.verificationSubmittedOn(date(l10n, verificationSubmittedAt))), findsOneWidget);
      expect(find.textContaining('https://github.com/youssef'), findsOneWidget);
      expect(find.text(l10n.verificationWithdraw), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pending: Withdraw asks first, then the form starts from the request ${variant.name}', (tester) async {
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      await pumpPage(tester, variant: variant, status: pendingStatus);
      expect(find.textContaining(verifiedField.name), findsOneWidget);
      expect(find.textContaining(pendingRequest.jobTitle), findsOneWidget);
      expect(find.textContaining(proofLink), findsOneWidget);
      expect(find.textContaining('.pdf'), findsOneWidget);

      await tester.tap(find.byKey(VerificationPendingView.withdrawKey));
      await tester.pumpAndSettle();
      expect(find.text(l10n.verificationWithdrawTitle), findsOneWidget);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(repository.calls, ['status'], reason: 'nothing without a confirmation');

      await tester.tap(find.byKey(VerificationPendingView.withdrawKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('verification-withdraw-confirm')));
      await tester.pumpAndSettle();
      expect(repository.calls, ['status', 'withdraw']);
      expect(find.text(l10n.verificationWithdrawn), findsOneWidget);
      expect(find.byType(VerificationForm), findsOneWidget);
      final jobTitle = find.descendant(of: find.byKey(VerificationForm.jobTitleKey), matching: find.byType(EditableText));
      expect(tester.widget<EditableText>(jobTitle).controller.text, pendingRequest.jobTitle);
      expect(tester.widget<DropdownButtonFormField<String>>(find.byType(DropdownButtonFormField<String>)).initialValue, verifiedField.id,
          reason: 'the field is chosen again');
      expect(find.text(l10n.cancel), findsNothing, reason: 'nothing to go back to');
      expect(tester.takeException(), isNull);
    });

    testWidgets('rejected: the reason, then "Request again" fills the form; Cancel goes back ${variant.name}', (tester) async {
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      await pumpPage(tester, variant: variant, status: rejectedStatus);
      expect(find.text(l10n.verificationRejectedTitle), findsOneWidget);
      expect(find.text(l10n.verificationRejectedReason), findsOneWidget);
      expect(find.textContaining('مش بيفتح'), findsOneWidget);
      expect(find.text(l10n.verificationRejectedOn(date(l10n, verificationDecidedAt))), findsOneWidget);
      expect(
        tester.widget<Directionality>(find.ancestor(of: find.textContaining('مش بيفتح'), matching: find.byType(Directionality)).first).textDirection,
        TextDirection.rtl,
        reason: 'the reason keeps its own direction in either UI',
      );

      await tester.tap(find.text(l10n.verificationRequestAgain));
      await tester.pumpAndSettle();
      expect(find.byType(VerificationForm), findsOneWidget);
      final proofUrl = find.descendant(of: find.byKey(VerificationForm.proofUrlKey), matching: find.byType(EditableText));
      expect(tester.widget<EditableText>(proofUrl).controller.text, proofLink);

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(find.byType(VerificationRejectedView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('approved, loading, a failed load with retry, and no request allowed ${variant.name}', (tester) async {
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      await pumpPage(tester, variant: variant, status: approvedStatus);
      expect(find.text(l10n.verificationApprovedTitle), findsOneWidget);
      expect(find.text(l10n.verificationApprovedOn(date(l10n, verificationDecidedAt))), findsOneWidget);
      expect(find.byType(VerificationForm), findsNothing);
      verify(session.refresh).called(1);

      repository.statusFailure = offline;
      await pumpPage(tester, variant: variant);
      expect(find.text(l10n.errOffline), findsOneWidget);
      repository
        ..statusFailure = null
        ..status = VerificationStatus(request: rejectedRequest);
      await tester.tap(find.text(l10n.retry));
      await tester.pumpAndSettle();
      expect(find.text(l10n.verificationRejectedTitle), findsOneWidget);
      expect(find.text(l10n.verificationRequestAgain), findsNothing, reason: 'suspended: no request allowed');

      repository.status = const VerificationStatus();
      await pumpPage(tester, variant: variant);
      expect(find.text(l10n.verificationUnavailableTitle), findsOneWidget);

      final loading = MockVerificationCubit()..hold(const VerificationState());
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<VerificationCubit>.value(value: loading),
            BlocProvider<VerificationFormCubit>.value(value: MockVerificationFormCubit()..hold(const VerificationFormState())),
          ],
          child: const VerificationView(),
        ),
        variant: variant,
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the checks: required inputs, an https link, at least one proof', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(VerificationForm.submitKey));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsNWidgets(2));
    expect(find.text('Add a link or a file as proof.'), findsOneWidget);
    expect(find.text('Attach a file').hitTestable(), findsOneWidget);

    await tester.enterText(find.byKey(VerificationForm.proofUrlKey), 'http://linkedin.com/in/me');
    await tester.pump();
    expect(find.text('Add a link or a file as proof.'), findsNothing, reason: 'a link answers it');
    await tester.enterText(find.byKey(VerificationForm.jobTitleKey), 'X');
    await tester.tap(find.byKey(VerificationForm.submitKey));
    await tester.pumpAndSettle();
    expect(find.text('Too short.'), findsOneWidget);
    expect(find.text('Enter a full link that starts with https://'), findsOneWidget);
    expect(repository.submissions, isEmpty);
  });

  testWidgets('a file that is not a proof is refused when picked; a chosen one can be removed', (tester) async {
    await pumpPage(tester);
    picker.next = const PickedMediaFile(path: '/t/cv.docx', name: 'cv.docx', sizeBytes: 1000);
    await tester.tap(find.byKey(VerificationForm.attachKey));
    await tester.pumpAndSettle();
    expect(find.text('The proof file must be a PDF, JPEG, PNG or WebP of 10 MB or less.'), findsOneWidget);
    expect(find.text('cv.docx'), findsNothing);

    picker.next = const PickedMediaFile(path: '/t/card.png', name: 'card.png', sizeBytes: 320 * 1024);
    await tester.tap(find.byKey(VerificationForm.attachKey));
    await tester.pumpAndSettle();
    expect(find.text('card.png'), findsOneWidget);
    expect(find.text('320 KB'), findsOneWidget);
    expect(find.byKey(VerificationForm.attachKey), findsNothing);

    await tester.tap(find.byKey(VerificationForm.removeFileKey));
    await tester.pumpAndSettle();
    expect(find.text('card.png'), findsNothing);
    expect(find.byKey(VerificationForm.attachKey), findsOneWidget);
  });

  testWidgets('server errors: on the input, or for the whole form', (tester) async {
    await pumpPage(tester);
    await chooseField(tester, 'AI');
    await tester.enterText(find.byKey(VerificationForm.jobTitleKey), 'ML Engineer');
    await tester.enterText(find.byKey(VerificationForm.proofUrlKey), 'https://github.com/mona');

    repository.submitFailure = const Failure(FailureCodes.verificationFieldInvalid, statusCode: 400);
    await tester.tap(find.byKey(VerificationForm.submitKey));
    await tester.pumpAndSettle();
    expect(find.text('Pick a field from the list.'), findsOneWidget);

    repository.submitFailure = offline;
    await tester.tap(find.byKey(VerificationForm.submitKey));
    await tester.pumpAndSettle();
    expect(find.text('Pick a field from the list.'), findsNothing);
    expect(find.text("You're offline. Check your connection."), findsOneWidget);
  });

  testWidgets('a request already pending (sent from another device) reloads the page and says so', (tester) async {
    await pumpPage(tester);
    await chooseField(tester, 'AI');
    await tester.enterText(find.byKey(VerificationForm.jobTitleKey), 'ML Engineer');
    await tester.enterText(find.byKey(VerificationForm.proofUrlKey), 'https://github.com/mona');
    repository
      ..submitFailure = const Failure(FailureCodes.verificationAlreadyPending, statusCode: 409)
      ..status = pendingStatus;
    await tester.tap(find.byKey(VerificationForm.submitKey));
    await tester.pumpAndSettle();
    expect(find.text('You already have a request under review.'), findsOneWidget);
    expect(find.byType(VerificationPendingView), findsOneWidget);
    expect(repository.calls, ['status', 'submit', 'status']);
  });

  group('Settings', () {
    Future<GoRouter> pumpSettings(WidgetTester tester, {Me? me = sampleMe, required VerificationCubit cubit}) async {
      usePhoneSurface(tester, size: const Size(390, 2400));
      session.hold(me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me));
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/settings', builder: (_, _) => const SettingsView()),
          GoRoute(path: VerificationPage.path, builder: (_, _) => const Scaffold(body: Text('verification page'))),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<SettingsCubit>.value(value: MockSettingsCubit()..hold(const AppSettings())),
          BlocProvider<LinkedAccountsCubit>.value(value: MockLinkedAccountsCubit()..hold(const LinkedAccountsState())),
          BlocProvider<PrivacyCubit>.value(value: MockPrivacyCubit()..hold(const PrivacyState())),
          BlocProvider<VerificationCubit>.value(value: cubit),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(AppLocales.en),
          locale: AppLocales.en,
          supportedLocales: AppLocales.supported,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ));
      await tester.pumpAndSettle();
      return router;
    }

    String subtitle(WidgetTester tester) => (tester.widget<ListTile>(find.byType(VerificationEntryTile).evaluate().isEmpty
            ? find.byType(ListTile)
            : find.descendant(of: find.byType(VerificationEntryTile), matching: find.byType(ListTile)))
        .subtitle! as Text)
        .data!;

    testWidgets('signed in: the Writer verification row shows the status and opens the page; the status is read again after', (tester) async {
      repository.status = rejectedStatus;
      final cubit = statusCubit();
      addTearDown(cubit.close);
      unawaited(cubit.load());
      final router = await pumpSettings(tester, cubit: cubit);

      expect(find.text('Writing'), findsOneWidget, reason: 'the card');
      expect(find.text('Writer verification'), findsOneWidget, reason: 'its row');
      expect(subtitle(tester), 'Not approved, open it to see why');

      repository.status = pendingStatus;
      await tester.tap(find.byType(VerificationEntryTile));
      await tester.pumpAndSettle();
      expect(find.text('verification page'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(repository.calls, ['status', 'status']);
      expect(subtitle(tester), 'Your request is under review');
    });

    testWidgets('every status of the row', (tester) async {
      final cases = {
        const VerificationState(): 'Get the verified writer badge',
        VerificationState(load: VerificationLoad.ready, status: approvedStatus): "You're a verified writer",
        const VerificationState(load: VerificationLoad.ready, status: VerificationStatus.none): 'Get the verified writer badge',
        const VerificationState(load: VerificationLoad.failure, failure: offline): 'Get the verified writer badge',
      };
      for (final MapEntry(key: state, value: text) in cases.entries) {
        await pumpSettings(tester, cubit: MockVerificationCubit()..hold(state));
        expect(subtitle(tester), text, reason: '$state');
      }

      // Before the status is read, the session's badge says verified.
      await pumpSettings(
        tester,
        me: const Me(id: 'u-1', displayName: 'Y', username: 'y', isVerified: true, onboardingCompleted: true),
        cubit: MockVerificationCubit()..hold(const VerificationState()),
      );
      expect(subtitle(tester), "You're a verified writer");
    });

    testWidgets('guests have no Writer verification row', (tester) async {
      final cubit = MockVerificationCubit()..hold(const VerificationState());
      await pumpSettings(tester, me: null, cubit: cubit);
      expect(find.byType(VerificationEntryTile), findsNothing);
      expect(find.text('Writer verification'), findsNothing);
    });
  });
}

import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/phone/countries.dart';
import 'package:readin/core/push/devices_api.dart';
import 'package:readin/core/push/push_platform.dart';
import 'package:readin/core/push/push_read_receipts.dart';
import 'package:readin/core/push/push_service.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/auth/data/datasources/account_api.dart';
import 'package:readin/features/auth/data/datasources/account_device_data.dart';
import 'package:readin/features/auth/data/datasources/auth_api.dart';
import 'package:readin/features/auth/data/datasources/auth_session_store.dart';
import 'package:readin/features/auth/data/datasources/google_sign_in_data_source.dart';
import 'package:readin/features/auth/data/models/auth_models.dart';
import 'package:readin/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:readin/features/auth/domain/entities/external_credential.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/usecases/auth_usecases.dart';
import 'package:readin/features/auth/presentation/cubit/delete_account_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:readin/features/auth/presentation/pages/delete_account_page.dart';
import 'package:readin/features/auth/presentation/pages/sign_in_page.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_app.dart';

class MockDeleteAccount extends Mock implements DeleteAccount {}

class MockConfirmWithLinkedProvider extends Mock implements ConfirmWithLinkedProvider {}

class MockSessionCubit extends MockCubit<SessionState> implements SessionCubit {}

class MockSignInCubit extends MockCubit<SignInState> implements SignInCubit {}

class MockAccountApi extends Mock implements AccountApi {}

class MockAuthApi extends Mock implements AuthApi {}

class MockPushPlatform extends Mock implements PushPlatform {}

class MockDevicesApi extends Mock implements DevicesApi {}

class MockPushReadReceipts extends Mock implements PushReadReceipts {}

class MockGoogleSignIn extends Mock implements GoogleSignInDataSource {}

/// An account created with Apple, on a device without Sign in with Apple (Android).
const appleOnly = Me(
  id: 'u-a',
  displayName: 'Mona',
  username: 'mona',
  hasPassword: false,
  hasRecoveryPin: false,
  externalLogins: [ExternalLogin(provider: 'apple')],
);

void main() {
  late MockConfirmWithLinkedProvider confirmWith;
  late MockSessionCubit sessionCubit;
  late MockSignInCubit signIn;

  setUpAll(() {
    registerFallbackValue(sampleMe);
    registerFallbackValue(ExternalProvider.google);
    registerFallbackValue(const DeleteAccountRequest());
  });

  setUp(() {
    confirmWith = MockConfirmWithLinkedProvider();
    when(() => confirmWith.providersFor(any())).thenReturn(const []);
    when(() => confirmWith.supports(any())).thenReturn(false);
    sessionCubit = MockSessionCubit();
    whenListen(sessionCubit, const Stream<SessionState>.empty(),
        initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    when(() => sessionCubit.signOut()).thenAnswer((_) async {});
    signIn = MockSignInCubit();
    whenListen(signIn, const Stream<SignInState>.empty(), initialState: const SignInState());
  });

  /// Settings → Delete account, with Sign in where the flow ends.
  Future<void> pumpFlow(WidgetTester tester, DeleteAccount delete, {Me me = sampleMe}) async {
    usePhoneSurface(tester);
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, _) => Scaffold(
            body: TextButton(onPressed: () => context.push('/account/delete'), child: const Text('settings')),
          ),
        ),
        GoRoute(
          path: '/account/delete',
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<SessionCubit>.value(value: sessionCubit),
              BlocProvider(create: (_) => DeleteAccountCubit(delete, confirmWith)..load(me)),
            ],
            child: const DeleteAccountView(),
          ),
        ),
        GoRoute(
          path: '/auth/sign-in',
          builder: (_, state) => BlocProvider<SignInCubit>.value(
            value: signIn,
            child: SignInView(args: state.extra is SignInArgs ? state.extra! as SignInArgs : const SignInArgs()),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(AppLocales.en),
      locale: AppLocales.en,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('settings'));
    await tester.pumpAndSettle();
  }

  /// The screens are lazy lists: scroll until [finder] is built and on screen.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await scrollTo(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  FilledButton deleteButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Delete my account'));

  /// Continue → password → "I understand" → the red button.
  Future<void> confirmWithPassword(WidgetTester tester) async {
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Continue'));
    expect(find.text("Confirm it's you"), findsOneWidget);
    expect(deleteButton(tester).onPressed, isNull, reason: 'disabled until "I understand" is ticked');
    await tester.enterText(find.byType(TextField), 'secret-1');
    await tapVisible(tester, find.text('I understand, delete my account'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Delete my account'));
  }

  group('what happens (SPEC §9.6)', () {
    /// The whole statement on one tall screen, so every fact is built.
    Future<void> pumpReview(WidgetTester tester, Variant variant) async {
      usePhoneSurface(tester, size: const Size(390, 3000));
      await tester.pumpWidget(testApp(DeleteAccountReview(onContinue: () {}), variant: variant));
    }

    double top(WidgetTester tester, String text) => tester.getTopLeft(find.textContaining(text)).dy;

    testWidgets('drafts and uploads go; published articles stay up under "Deleted user", first of what we keep',
        (tester) async {
      await pumpReview(tester, const Variant(AppLocales.en, Brightness.light));

      expect(
        find.text(
          "Your drafts and any article that isn't published, with their images and PDFs, and every other photo or file "
          'you uploaded',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Your articles and drafts'), findsNothing);
      const kept = 'Your published articles and comments stay up under “Deleted user”';
      expect(find.textContaining(kept), findsOneWidget);
      expect(find.textContaining('To take an article down, delete it before you delete your account.'), findsOneWidget);
      expect(top(tester, 'What we keep, and why'), lessThan(top(tester, kept)));
      expect(top(tester, kept), lessThan(top(tester, 'A record that this account was deleted')));
    });

    testWidgets('the same in Arabic', (tester) async {
      await pumpReview(tester, const Variant(AppLocales.ar, Brightness.light));

      // textContaining: "PDF" is isolated inside the Arabic sentences.
      expect(find.textContaining('المسودات وأي مقال غير منشور'), findsOneWidget);
      expect(find.textContaining('وأي صورة أو ملف آخر رفعته'), findsOneWidget);
      expect(find.textContaining('مقالاتك والمسودات'), findsNothing);
      const kept = 'تبقى مقالاتك المنشورة وتعليقاتك ظاهرةً باسم «مستخدم محذوف»';
      expect(find.textContaining(kept), findsOneWidget);
      expect(find.textContaining('إذا أردت إزالة مقال، فاحذفه قبل حذف حسابك.'), findsOneWidget);
      expect(top(tester, kept), lessThan(top(tester, 'سجلّ بحذف هذا الحساب')));
    });
  });

  testWidgets('success forgets the account on this device (session, push token…) and Sign in says so', (tester) async {
    // The real use case and repository: only the API, the platform and the provider SDKs are fakes.
    final accountApi = MockAccountApi();
    when(() => accountApi.deleteAccount(any())).thenAnswer((_) async {});
    final secure = FakeSecureStore();
    final store = AuthSessionStore(MockAuthApi(), secure);
    await store.save(session('a1', 'r1'));
    final platform = MockPushPlatform();
    when(() => platform.isSupported).thenReturn(true);
    when(() => platform.deleteToken()).thenAnswer((_) async {});
    final google = MockGoogleSignIn();
    when(() => google.signOut()).thenAnswer((_) async {});
    final countries = PhoneCountryMemory(InMemoryKeyValueStore());
    await countries.remember('US');
    var imageClears = 0;
    final device = AccountDeviceData(
      PushService(platform, MockDevicesApi(), MockPushReadReceipts()),
      google,
      countries,
      clearImages: () async => imageClears++,
      temporaryDirectory: () async => throw const FileSystemException('covered by account_device_data_test'),
    );
    final delete = DeleteAccount(AccountRepositoryImpl(accountApi, store, device));

    await pumpFlow(tester, delete);
    expect(find.text('Delete your account'), findsOneWidget);
    expect(find.text('This permanently deletes your ReadIn account. You can\'t undo it, and we can\'t restore it.'),
        findsOneWidget);
    expect(find.text('We delete right away'), findsOneWidget);
    await scrollTo(tester, find.text('What we keep, and why'));
    await scrollTo(tester, find.text('Delete by email instead'));

    await confirmWithPassword(tester);
    expect(find.text('Delete your account forever?'), findsOneWidget);
    expect(find.text("This can't be undone."), findsOneWidget);
    final cancel = find.ancestor(of: find.text('Cancel'), matching: find.byType(TextButton));
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(find.descendant(of: cancel, matching: find.byWidget(focused.widget)), findsOneWidget,
        reason: 'the final dialog focuses Cancel');

    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();

    expect(verify(() => accountApi.deleteAccount(captureAny())).captured.single.toJson(), {'password': 'secret-1'});
    verify(() => platform.deleteToken()).called(1);
    verify(() => google.signOut()).called(1);
    expect(imageClears, 1);
    expect(countries.initial(deviceRegion: 'EG'), 'EG');
    expect(secure.values, isEmpty);
    expect(await store.accessToken(), isNull);
    expect(find.byType(SignInView), findsOneWidget);
    expect(find.text('Your account was deleted.'), findsOneWidget);
  });

  testWidgets('cancelling the final dialog deletes nothing', (tester) async {
    final delete = MockDeleteAccount();
    await pumpFlow(tester, delete);
    await confirmWithPassword(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text("Confirm it's you"), findsOneWidget);
    verifyZeroInteractions(delete);
  });

  testWidgets('offline: a clear error with Retry; only Retry sends it again', (tester) async {
    final delete = MockDeleteAccount();
    final answers = [const Err<void>(Failure(FailureCodes.networkOffline)), const Ok<void>(null)];
    when(() => delete(password: 'secret-1')).thenAnswer((_) async => answers.removeAt(0));
    await pumpFlow(tester, delete);
    await confirmWithPassword(tester);
    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();

    expect(find.text("You're offline. Connect to the internet to delete your account."), findsOneWidget);
    expect(find.text('Your account was deleted.'), findsNothing);
    await tester.pump(const Duration(minutes: 1));
    verify(() => delete(password: 'secret-1')).called(1);

    await tapVisible(tester, find.widgetWithText(TextButton, 'Try again'));

    verify(() => delete(password: 'secret-1')).called(1);
    expect(find.text('Your account was deleted.'), findsOneWidget);
  });

  testWidgets('503: nothing was deleted, with Retry', (tester) async {
    final delete = MockDeleteAccount();
    when(() => delete(password: 'secret-1'))
        .thenAnswer((_) async => const Err(Failure(FailureCodes.accountDeletionUnavailable, statusCode: 503)));
    await pumpFlow(tester, delete);
    await confirmWithPassword(tester);
    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();

    expect(
      find.text("We couldn't finish deleting your account, so nothing was deleted. Try again in a few minutes."),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);
    expect(find.text("Confirm it's you"), findsOneWidget);
    expect(deleteButton(tester).onPressed, isNotNull);
  });

  testWidgets('a wrong password stays on the confirm step', (tester) async {
    final delete = MockDeleteAccount();
    when(() => delete(password: 'secret-1'))
        .thenAnswer((_) async => const Err(Failure(FailureCodes.authWrongPassword, statusCode: 400)));
    await pumpFlow(tester, delete);
    await confirmWithPassword(tester);
    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();

    expect(find.text('The current password is incorrect.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Try again'), findsNothing);
  });

  testWidgets('the session had already ended: sign out to Sign in', (tester) async {
    final delete = MockDeleteAccount();
    when(() => delete(password: 'secret-1'))
        .thenAnswer((_) async => const Err(Failure(FailureCodes.authUnauthorized, statusCode: 401)));
    await pumpFlow(tester, delete);
    await confirmWithPassword(tester);
    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();

    verify(() => sessionCubit.signOut()).called(1);
  });

  testWidgets('an Apple account on a device without Sign in with Apple points to the iPhone app or email', (tester) async {
    await pumpFlow(tester, MockDeleteAccount(), me: appleOnly);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Continue'));

    expect(
      find.text('This account is linked to Apple. Confirm with Apple from the ReadIn iPhone app, or email us to delete it.'),
      findsOneWidget,
    );
    expect(find.text('Delete by email instead'), findsOneWidget);
    await tapVisible(tester, find.text('I understand, delete my account'));
    expect(deleteButton(tester).onPressed, isNull);
  });

  testWidgets('a Google account confirms with Google before the red button works', (tester) async {
    final delete = MockDeleteAccount();
    when(() => confirmWith.providersFor(any())).thenReturn(const [ExternalProvider.google]);
    when(() => confirmWith.using(ExternalProvider.google)).thenAnswer(
        (_) async => const Ok(ExternalCredential(provider: ExternalProvider.google, idToken: 'google-id-token')));
    await pumpFlow(
      tester,
      delete,
      me: const Me(
        id: 'u-g',
        displayName: 'Mona',
        username: 'mona',
        hasPassword: false,
        externalLogins: [ExternalLogin(provider: 'google')],
      ),
    );
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Continue'));
    await tapVisible(tester, find.text('I understand, delete my account'));
    expect(find.byType(TextField), findsNothing);
    expect(deleteButton(tester).onPressed, isNull);

    await tapVisible(tester, find.text('Confirm with Google'));

    expect(find.text('Confirmed with Google'), findsOneWidget);
    expect(deleteButton(tester).onPressed, isNotNull);
  });
}

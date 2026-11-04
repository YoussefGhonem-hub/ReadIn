import 'package:flutter_test/flutter_test.dart';
import 'package:readin/app/router.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';

import '../helpers/fixtures.dart';

SessionState signedIn(Me me) => SessionState(status: SessionStatus.authenticated, me: me);

Me account({
  bool mustChangePassword = false,
  bool mustSetRecoveryPin = false,
  bool isProfileComplete = true,
  bool onboardingCompleted = true,
}) =>
    Me(
      id: 'u',
      displayName: 'New',
      username: 'new',
      phoneNumber: '+201001234567',
      mustChangePassword: mustChangePassword,
      mustSetRecoveryPin: mustSetRecoveryPin,
      isProfileComplete: isProfileComplete,
      onboardingCompleted: onboardingCompleted,
    );

void main() {
  const guest = SessionState(status: SessionStatus.guest);
  const seen = AppSettings(welcomeSeen: true);
  const fresh = AppSettings();
  const onboarded = SessionState(status: SessionStatus.authenticated, me: sampleMe);

  String? redirect(String location, SessionState session, [AppSettings settings = seen]) =>
      resolveRedirect(uri: Uri.parse(location), session: session, settings: settings);

  test('waits on the splash while the session is restored, remembering the target', () {
    expect(redirect('/a/di-in-dotnet', const SessionState()), '/splash?from=%2Fa%2Fdi-in-dotnet');
    expect(redirect('/splash?from=/home', const SessionState()), isNull);
  });

  test('leaves the splash for the remembered target once resolved', () {
    expect(redirect('/splash?from=%2Fa%2Fdi-in-dotnet', guest), '/a/di-in-dotnet');
    expect(redirect('/splash', onboarded), '/home');
  });

  group('guests', () {
    test('first-time guests see Welcome, except on article deep links and sign-in screens', () {
      expect(redirect('/home', guest, fresh), AppRoutes.welcome);
      expect(redirect('/welcome', guest, fresh), isNull);
      expect(redirect('/a/di-in-dotnet', guest, fresh), isNull);
      expect(redirect('/auth/sign-in', guest, fresh), isNull);
      expect(redirect('/auth/forgot-password', guest, fresh), isNull);
      // A shared profile link (F14) opens too.
      expect(redirect('/u/mona', guest, fresh), isNull);
      expect(redirect('/u/mona/followers', guest, fresh), isNull);
    });

    test('can browse and read once Welcome was seen', () {
      expect(redirect('/home', guest), isNull);
      expect(redirect('/explore', guest), isNull);
      expect(redirect('/a/di-in-dotnet', guest), isNull);
      expect(redirect('/settings', guest), isNull);
    });

    test('account screens and onboarding need an account', () {
      expect(redirect(AppRoutes.changePassword, guest), AppRoutes.home);
      expect(redirect(AppRoutes.setRecoveryPin, guest), AppRoutes.home);
      expect(redirect(AppRoutes.onboarding, guest), AppRoutes.home);
      expect(redirect(AppRoutes.onboarding, guest, fresh), AppRoutes.welcome);
      expect(redirect(AppRoutes.editProfile, guest), AppRoutes.home);
      expect(redirect(AppRoutes.editProfile, onboarded), isNull);
      expect(redirect(AppRoutes.user('@mona'), onboarded), isNull);
      expect(AppRoutes.user('@mona'), '/u/mona');
    });

    test('a session that ends on Delete account leads to Sign in (deleted, or already ended elsewhere)', () {
      expect(redirect(AppRoutes.deleteAccount, guest), AppRoutes.signIn);
      expect(redirect(AppRoutes.deleteAccount, guest, fresh), AppRoutes.signIn);
      expect(redirect(AppRoutes.signIn, guest, fresh), isNull);
    });

    test('a session that ended (refresh rejected) is a guest', () {
      const ended = SessionState(status: SessionStatus.guest, failure: Failure('auth.refresh_invalid', statusCode: 401));
      expect(redirect('/home', ended), isNull);
    });
  });

  group('account guards (SPEC §9.2 order)', () {
    test('must change password comes first', () {
      final session = signedIn(account(mustChangePassword: true, mustSetRecoveryPin: true, isProfileComplete: false, onboardingCompleted: false));
      expect(session.gate, AccountGate.changePassword);
      expect(redirect('/home', session), AppRoutes.changePassword);
      expect(redirect('/a/di-in-dotnet', session), AppRoutes.changePassword);
      expect(redirect(AppRoutes.changePassword, session), isNull);
      expect(redirect('/splash?from=%2Fhome', session), AppRoutes.changePassword);
    });

    test('then the recovery PIN, which cannot be skipped', () {
      final session = signedIn(account(mustSetRecoveryPin: true, isProfileComplete: false, onboardingCompleted: false));
      expect(session.gate, AccountGate.setRecoveryPin);
      expect(redirect('/home', session), AppRoutes.setRecoveryPin);
      expect(redirect(AppRoutes.settings, session), AppRoutes.setRecoveryPin);
      expect(redirect(AppRoutes.setRecoveryPin, session), isNull);
    });

    test('then complete profile', () {
      final session = signedIn(account(isProfileComplete: false, onboardingCompleted: false));
      expect(session.gate, AccountGate.completeProfile);
      expect(redirect('/auth/sign-in', session), AppRoutes.completeProfile);
      expect(redirect(AppRoutes.completeProfile, session), isNull);
    });

    test('then onboarding', () {
      final session = signedIn(account(onboardingCompleted: false));
      expect(session.gate, AccountGate.onboarding);
      expect(redirect('/home', session), AppRoutes.onboarding);
      expect(redirect(AppRoutes.onboarding, session), isNull);
    });

    test('then the requested page', () {
      expect(onboarded.gate, isNull);
      expect(redirect('/profile', onboarded), isNull);
      expect(redirect('/a/di-in-dotnet', onboarded), isNull);
      expect(redirect(AppRoutes.changePassword, onboarded), isNull); // from Settings
      expect(redirect(AppRoutes.changeRecoveryPin, onboarded), isNull);
    });

    test('sign-in screens and finished mandatory screens lead home', () {
      expect(redirect('/auth/sign-in', onboarded), AppRoutes.home);
      expect(redirect('/auth/sign-up', onboarded), AppRoutes.home);
      expect(redirect('/welcome', onboarded), AppRoutes.home);
      expect(redirect(AppRoutes.setRecoveryPin, onboarded), AppRoutes.home);
      expect(redirect(AppRoutes.completeProfile, onboarded), AppRoutes.home);
    });

    test('a stored session that could not be restored offline keeps browsing', () {
      const offline = SessionState(status: SessionStatus.authenticated, failure: Failure('network.offline'));
      expect(offline.gate, isNull);
      expect(redirect('/home', offline), isNull);
      expect(redirect('/auth/sign-in', offline), AppRoutes.home);
    });
  });
}

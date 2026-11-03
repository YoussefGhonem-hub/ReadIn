import 'package:flutter_test/flutter_test.dart';
import 'package:readin/app/router.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';

import '../helpers/fixtures.dart';

void main() {
  const guest = SessionState(status: SessionStatus.guest);
  const seen = AppSettings(welcomeSeen: true);
  const fresh = AppSettings();
  const onboarded = SessionState(status: SessionStatus.authenticated, me: sampleMe);
  const newAccount = SessionState(
    status: SessionStatus.authenticated,
    me: Me(id: 'u', email: 'n@readin.test', displayName: 'New', username: 'new'),
  );

  String? redirect(String location, SessionState session, AppSettings settings) =>
      resolveRedirect(uri: Uri.parse(location), session: session, settings: settings);

  test('waits on the splash while the session is unknown, remembering the target', () {
    expect(redirect('/a/di-in-dotnet', const SessionState(), seen), '/splash?from=%2Fa%2Fdi-in-dotnet');
    expect(redirect('/splash?from=/home', const SessionState(), seen), isNull);
  });

  test('leaves the splash for the remembered target once resolved', () {
    expect(redirect('/splash?from=%2Fa%2Fdi-in-dotnet', guest, seen), '/a/di-in-dotnet');
    expect(redirect('/splash', onboarded, seen), '/home');
  });

  test('first-time guests see the welcome step, except on article deep links', () {
    expect(redirect('/home', guest, fresh), '/onboarding');
    expect(redirect('/a/di-in-dotnet', guest, fresh), isNull);
    expect(redirect('/auth/sign-in', guest, fresh), isNull);
    expect(redirect('/home', guest, seen), isNull);
  });

  test('new accounts must finish onboarding', () {
    expect(redirect('/home', newAccount, seen), '/onboarding');
    expect(redirect('/onboarding', newAccount, seen), isNull);
  });

  test('signed-in users skip auth screens', () {
    expect(redirect('/auth/sign-in', onboarded, seen), '/home');
    expect(redirect('/profile', onboarded, seen), isNull);
  });
}

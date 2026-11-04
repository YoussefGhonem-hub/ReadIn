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
import 'package:readin/features/auth/domain/repositories/auth_repository.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/onboarding/domain/repositories/interests_repository.dart';
import 'package:readin/features/onboarding/domain/usecases/set_interest.dart';
import 'package:readin/features/settings/presentation/cubit/interests_cubit.dart';
import 'package:readin/features/settings/presentation/pages/interests_page.dart';
import 'package:readin/features/taxonomy/domain/entities/field.dart';
import 'package:readin/features/taxonomy/domain/usecases/taxonomy_usecases.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockGetFields extends Mock implements GetFields {}

class MockGetTopics extends Mock implements GetTopics {}

class MockSetInterest extends Mock implements SetInterest {}

class MockInterestsRepository extends Mock implements InterestsRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

const _topics = [
  Topic(id: 't-di', fieldId: 'f-dotnet', slug: 'di', nameAr: 'Dependency Injection', nameEn: 'Dependency Injection'),
  Topic(id: 't-ef', fieldId: 'f-dotnet', slug: 'ef-core', nameAr: 'EF Core', nameEn: 'EF Core'),
];

Me reader({List<String> fields = const ['f-dotnet', 'f-ai'], List<String> topics = const ['t-di']}) =>
    Me(id: 'u-1', displayName: 'Reader', username: 'reader1', onboardingCompleted: true, interestFieldIds: fields, interestTopicIds: topics);

/// Settings → Your interests (F02, F12): each chip saved on its own, at once, with at least 3 interests kept.
void main() {
  late MockGetFields getFields;
  late MockGetTopics getTopics;
  late MockSetInterest setInterest;
  late MockSessionCubit session;
  late StreamController<SessionState> sessions;

  setUpAll(() => registerFallbackValue(InterestKind.field));

  setUp(() {
    getFields = MockGetFields();
    getTopics = MockGetTopics();
    setInterest = MockSetInterest();
    sessions = StreamController<SessionState>.broadcast();
    session = MockSessionCubit();
    whenListen(session, sessions.stream, initialState: SessionState(status: SessionStatus.authenticated, me: reader()));
    when(() => getFields(refresh: any(named: 'refresh'))).thenAnswer((_) async => const Ok(sampleFields));
    when(() => getTopics(any())).thenAnswer((_) async => const Ok(<Topic>[]));
    when(() => getTopics('dotnet')).thenAnswer((_) async => const Ok(_topics));
    when(() => setInterest(any(), any(), followed: any(named: 'followed'))).thenAnswer((_) async => const Ok(null));
  });

  tearDown(() => sessions.close());

  InterestsCubit build() => InterestsCubit(getFields, getTopics, setInterest, session);

  test("starts from the session's interests and loads the followed fields' topics", () async {
    final cubit = build();
    expect(cubit.state.fieldIds, {'f-dotnet', 'f-ai'});
    expect(cubit.state.topicIds, {'t-di'});

    await cubit.load();
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.fields, sampleFields);
    expect(cubit.state.topics['f-dotnet'], _topics);
    verifyNever(() => getTopics('frontend'));
  });

  test('following a field shows at once, saves it, then lists its topics', () async {
    final cubit = build();
    await cubit.load();
    final saving = Completer<Result<void>>();
    when(() => setInterest(InterestKind.field, 'f-frontend', followed: true)).thenAnswer((_) => saving.future);

    final done = cubit.toggleField(sampleFields[2]);
    expect(cubit.state.fieldIds, contains('f-frontend'));
    expect(cubit.state.pending, {'f-frontend'});
    saving.complete(const Ok(null));

    expect(await done, isNull);
    expect(cubit.state.pending, isEmpty);
    expect(cubit.state.fieldIds, contains('f-frontend'));
    verify(() => getTopics('frontend')).called(1);
  });

  test('a refused change goes back and says why', () async {
    const offline = Failure(FailureCodes.networkOffline);
    when(() => setInterest(InterestKind.topic, 't-ef', followed: true)).thenAnswer((_) async => const Err(offline));
    final cubit = build();
    await cubit.load();

    expect(await cubit.toggleTopic(_topics[1]), offline);
    expect(cubit.state.topicIds, {'t-di'});
    expect(cubit.state.pending, isEmpty);
  });

  test('the last 3 interests stay: unfollowing one more is refused without asking the API', () async {
    final cubit = build();
    await cubit.load();

    final failure = await cubit.toggleTopic(_topics[0]);
    expect(failure?.code, FailureCodes.interestsMinThree);
    expect(cubit.state.topicIds, {'t-di'});
    verifyNever(() => setInterest(any(), any(), followed: any(named: 'followed')));
  });

  test("an API refusal of the minimum goes back too (another device's change)", () async {
    when(() => setInterest(InterestKind.field, 'f-ai', followed: false))
        .thenAnswer((_) async => const Err(Failure(FailureCodes.interestsMinThree, statusCode: 400)));
    whenListen(
      session,
      sessions.stream,
      initialState: SessionState(status: SessionStatus.authenticated, me: reader(topics: ['t-di', 't-ef'])),
    );
    final cubit = build();
    await cubit.load();

    expect((await cubit.toggleField(sampleFields[1]))?.code, FailureCodes.interestsMinThree);
    expect(cubit.state.fieldIds, {'f-dotnet', 'f-ai'});
  });

  test('follows the session while nothing is being saved', () async {
    final cubit = build();
    sessions.add(SessionState(status: SessionStatus.authenticated, me: reader(fields: ['f-mobile'], topics: ['t-ef', 't-di'])));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.fieldIds, {'f-mobile'});
    expect(cubit.state.topicIds, {'t-ef', 't-di'});
    await cubit.close();
  });

  test('a followed topic whose field is not followed still gets its chips', () async {
    whenListen(
      session,
      sessions.stream,
      initialState: SessionState(status: SessionStatus.authenticated, me: reader(fields: ['f-ai', 'f-mobile'], topics: ['t-di'])),
    );
    final cubit = build();
    await cubit.load();
    expect(cubit.state.topics['f-dotnet'], _topics);
    expect(cubit.state.showsTopicsOf(sampleFields[0]), isTrue);
    expect(cubit.state.showsTopicsOf(sampleFields[2]), isFalse);
  });

  group('SetInterest', () {
    test('saves one interest, then reads /me again so the session follows', () async {
      final repository = MockInterestsRepository();
      final accounts = MockAccountRepository();
      when(() => repository.setInterest(InterestKind.topic, 't-di', followed: false)).thenAnswer((_) async => const Ok(null));
      when(accounts.getMe).thenAnswer((_) async => Ok(reader()));

      expect((await SetInterest(repository, accounts)(InterestKind.topic, 't-di', followed: false)).isOk, isTrue);
      verify(accounts.getMe).called(1);
    });

    test('a refusal reads nothing', () async {
      final repository = MockInterestsRepository();
      final accounts = MockAccountRepository();
      when(() => repository.setInterest(any(), any(), followed: any(named: 'followed')))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.interestsMinThree)));

      await SetInterest(repository, accounts)(InterestKind.field, 'f-ai', followed: false);
      verifyNever(accounts.getMe);
    });
  });

  group('the page', () {
    Future<InterestsCubit> pumpPage(WidgetTester tester, Variant variant) async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(BlocProvider<InterestsCubit>.value(value: cubit, child: const InterestsView()), variant: variant));
      await tester.pump();
      return cubit;
    }

    for (final variant in Variant.all) {
      testWidgets('the fields, the followed fields\' topics, and the count ${variant.name}', (tester) async {
        final l10n = await AppLocalizations.delegate.load(variant.locale);
        await pumpPage(tester, variant);
        expect(find.text(l10n.settingsInterests), findsOneWidget);
        expect(find.text(l10n.interestsSelected(3)), findsOneWidget);
        expect(find.byType(FilterChip), findsNWidgets(sampleFields.length + _topics.length));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('unfollowing below 3 says "Keep at least 3 interests"', (tester) async {
      await pumpPage(tester, const Variant(AppLocales.en, Brightness.light));
      await tester.tap(find.text('Dependency Injection'));
      await tester.pump();
      expect(find.text('Keep at least 3 interests'), findsOneWidget);
    });

    testWidgets('a field tapped is followed at once', (tester) async {
      final cubit = await pumpPage(tester, const Variant(AppLocales.en, Brightness.light));
      await tester.tap(find.text('Frontend'));
      await tester.pump();
      expect(cubit.state.fieldIds, contains('f-frontend'));
      verify(() => setInterest(InterestKind.field, 'f-frontend', followed: true)).called(1);
    });
  });
}

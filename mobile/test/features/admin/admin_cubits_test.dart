import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/features/admin/domain/entities/admin_content.dart';
import 'package:readin/features/admin/domain/entities/admin_dashboard.dart';
import 'package:readin/features/admin/domain/entities/admin_user.dart';
import 'package:readin/features/admin/domain/entities/admin_verification.dart';
import 'package:readin/features/admin/domain/entities/paged_list.dart';
import 'package:readin/features/admin/domain/usecases/admin_usecases.dart';
import 'package:readin/features/admin/presentation/cubit/admin_article_cubit.dart';
import 'package:readin/features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:readin/features/admin/presentation/cubit/admin_list_cubit.dart';
import 'package:readin/features/admin/presentation/cubit/admin_lists.dart';
import 'package:readin/features/admin/presentation/cubit/admin_summary_cubit.dart';
import 'package:readin/features/admin/presentation/cubit/admin_user_cubit.dart';
import 'package:readin/features/admin/presentation/cubit/verification_review_cubits.dart';
import 'package:readin/features/verification/domain/entities/verification.dart';

import '../../helpers/admin_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAdminRepository repository;

  const offline = Failure(FailureCodes.networkOffline);

  setUpAll(() {
    registerFallbackValue(AdminPeriod.today);
    registerFallbackValue(const AdminUserQuery());
    registerFallbackValue(const AdminArticleQuery());
    registerFallbackValue(VerificationRequestStatus.pending);
    registerFallbackValue(const AdminCommentQuery());
  });

  setUp(() => repository = MockAdminRepository());

  group('AdminSummaryCubit (the console badge)', () {
    test('loads when watched, every 60 seconds while watched, and stops when the last watcher goes', () {
      fakeAsync((async) {
        var calls = 0;
        when(() => repository.summary()).thenAnswer((_) async => Ok(AdminSummary(openReports: ++calls, total: calls)));
        final cubit = AdminSummaryCubit(GetAdminSummary(repository));

        cubit
          ..watch()
          ..watch();
        async.flushMicrotasks();
        expect(calls, 2, reason: 'each entry that appears asks once');
        expect(cubit.state?.total, 2);

        async.elapse(AdminSummaryCubit.interval);
        expect(calls, 3, reason: 'one timer for all watchers');

        cubit.unwatch();
        async.elapse(AdminSummaryCubit.interval);
        expect(calls, 4, reason: 'still one watcher');

        cubit.unwatch();
        async.elapse(AdminSummaryCubit.interval * 3);
        expect(calls, 4, reason: 'nobody shows it: no more polling');
        expect(cubit.isWatched, isFalse);
        cubit.close();
      });
    });

    test('a failed load keeps the last numbers; refresh only reloads when something shows them', () async {
      when(() => repository.summary()).thenAnswer((_) async => const Ok(AdminSummary(openTickets: 2, total: 2)));
      final cubit = AdminSummaryCubit(GetAdminSummary(repository));

      await cubit.refresh();
      verifyNever(() => repository.summary());

      await cubit.load();
      when(() => repository.summary()).thenAnswer((_) async => const Err(offline));
      await cubit.refresh();

      expect(cubit.state, const AdminSummary(openTickets: 2, total: 2));
      verify(() => repository.summary()).called(2);
      await cubit.close();
    });

    test('the app coming back reloads it while watched', () async {
      when(() => repository.summary()).thenAnswer((_) async => const Ok(AdminSummary(total: 1)));
      final cubit = AdminSummaryCubit(GetAdminSummary(repository))..watch();
      await Future<void>.delayed(Duration.zero);

      cubit.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      verify(() => repository.summary()).called(2);
      cubit.unwatch();
      cubit.didChangeAppLifecycleState(AppLifecycleState.resumed);
      verifyNever(() => repository.summary());
      await cubit.close();
    });
  });

  group('AdminDashboardCubit', () {
    AdminDashboard dashboard(AdminPeriod period) =>
        AdminDashboard(period: period, fromDate: '2026-11-07', toDate: '2026-11-07', generatedAt: adminNow);

    blocTest<AdminDashboardCubit, AdminDashboardState>(
      'today first; another period keeps the numbers on screen while it loads',
      setUp: () => when(() => repository.dashboard(any())).thenAnswer((i) async => Ok(dashboard(i.positionalArguments.first as AdminPeriod))),
      build: () => AdminDashboardCubit(GetAdminDashboard(repository)),
      act: (cubit) async {
        await cubit.load();
        await cubit.setPeriod(AdminPeriod.days30);
      },
      expect: () => [
        const AdminDashboardState(),
        AdminDashboardState(status: AdminDashboardStatus.ready, dashboard: dashboard(AdminPeriod.today)),
        // setPeriod and load both ask for the same loading state: emitted once.
        AdminDashboardState(period: AdminPeriod.days30, dashboard: dashboard(AdminPeriod.today)),
        AdminDashboardState(period: AdminPeriod.days30, status: AdminDashboardStatus.ready, dashboard: dashboard(AdminPeriod.days30)),
      ],
      verify: (_) {
        verify(() => repository.dashboard(AdminPeriod.today)).called(1);
        verify(() => repository.dashboard(AdminPeriod.days30)).called(1);
      },
    );

    blocTest<AdminDashboardCubit, AdminDashboardState>(
      'a failure is shown with a retry',
      setUp: () => when(() => repository.dashboard(any())).thenAnswer((_) async => const Err(offline)),
      build: () => AdminDashboardCubit(GetAdminDashboard(repository)),
      act: (cubit) => cubit.load(),
      expect: () => [
        const AdminDashboardState(),
        const AdminDashboardState(status: AdminDashboardStatus.failure, failure: offline),
      ],
    );
  });

  group('AdminUsersCubit (an offset-paged console list)', () {
    PagedList<AdminUserRow> page(int number, List<String> ids, {int totalPages = 2}) => PagedList(
          items: [for (final id in ids) userRow(id: id)],
          page: number,
          totalCount: 3,
          totalPages: totalPages,
        );

    test('the first page, then the next one as the list scrolls; a row seen twice is kept once', () async {
      when(() => repository.users(any(), page: 1, pageSize: 50)).thenAnswer((_) async => Ok(page(1, ['a', 'b'])));
      when(() => repository.users(any(), page: 2, pageSize: 50)).thenAnswer((_) async => Ok(page(2, ['b', 'c'])));
      final cubit = AdminUsersCubit(GetAdminUsers(repository));

      await cubit.load();
      expect(cubit.state.hasMore, isTrue);
      await cubit.loadMore();

      expect([for (final u in cubit.state.items) u.id], ['a', 'b', 'c']);
      expect(cubit.state.hasMore, isFalse);
      await cubit.loadMore();
      verify(() => repository.users(any(), page: 2, pageSize: 50)).called(1);
      await cubit.close();
    });

    test('a new query starts again from page 1; a failed later page offers to try again', () async {
      when(() => repository.users(any(), page: 1, pageSize: 50)).thenAnswer((_) async => Ok(page(1, ['a'])));
      when(() => repository.users(any(), page: 2, pageSize: 50)).thenAnswer((_) async => const Err(offline));
      final cubit = AdminUsersCubit(GetAdminUsers(repository));

      await cubit.load();
      await cubit.loadMore();
      expect(cubit.state.moreFailure, offline);
      expect(cubit.state.items, hasLength(1));

      const query = AdminUserQuery(q: 'crypto', hasReports: true);
      await cubit.setQuery(query);

      verify(() => repository.users(query, page: 1, pageSize: 50)).called(1);
      expect(cubit.state.query, query);
      expect(cubit.state.status, AdminListStatus.ready);
      await cubit.close();
    });

    test('a first page that fails shows the failure; a reload that fails keeps the rows', () async {
      when(() => repository.users(any(), page: 1, pageSize: 50)).thenAnswer((_) async => const Err(offline));
      final cubit = AdminUsersCubit(GetAdminUsers(repository));

      await cubit.load();
      expect(cubit.state.status, AdminListStatus.failure);

      when(() => repository.users(any(), page: 1, pageSize: 50)).thenAnswer((_) async => Ok(page(1, ['a'])));
      await cubit.load();
      when(() => repository.users(any(), page: 1, pageSize: 50)).thenAnswer((_) async => const Err(offline));
      final failure = await cubit.refresh();

      expect(failure, offline);
      expect(cubit.state.items, hasLength(1));
      await cubit.close();
    });
  });

  test('AdminCommentsCubit: a hidden row is replaced in place, a deleted one leaves', () async {
    final comment = AdminCommentRow(
      id: 'c-1',
      body: 'Spam',
      article: const AdminCommentArticle(id: 'a-1', slug: 'rag', title: 'RAG'),
      createdAt: adminNow,
    );
    when(() => repository.comments(any(), page: 1, pageSize: 50))
        .thenAnswer((_) async => Ok(PagedList(items: [comment], totalCount: 1, totalPages: 1)));
    final cubit = AdminCommentsCubit(GetAdminComments(repository));
    await cubit.load();

    cubit.replace(comment.copyWith(hiddenAt: () => adminNow));
    expect(cubit.state.items.single.isHidden, isTrue);
    cubit.remove('c-1');
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.totalCount, 0);
    await cubit.close();
  });

  group("AdminUserCubit (a user's page)", () {
    final user = AdminUser(row: userRow(), actions: const AdminUserActions(canRevealPhone: true, canResetPassword: true));

    setUp(() => when(() => repository.user('w-9')).thenAnswer((_) async => Ok(user)));

    test('reveals the phone number and keeps it on the page', () async {
      when(() => repository.revealPhone('w-9')).thenAnswer((_) async => const Ok('+201001234567'));
      final cubit = AdminUserCubit(GetAdminUser(repository), AdminUserCommands(repository), 'w-9');
      await cubit.load();

      final failure = await cubit.revealPhone();

      expect(failure, isNull);
      expect(cubit.state.phone, '+201001234567');
      expect(cubit.state.busy, isNull);
      await cubit.close();
    });

    test('resets the password: the temporary one comes back once; the page is read again', () async {
      when(() => repository.resetPassword('w-9')).thenAnswer((_) async => const Ok('Tmp-1234'));
      final cubit = AdminUserCubit(GetAdminUser(repository), AdminUserCommands(repository), 'w-9');
      await cubit.load();

      final result = await cubit.resetPassword();

      expect(result.password, 'Tmp-1234');
      expect(result.failure, isNull);
      verify(() => repository.user('w-9')).called(2);
      await cubit.close();
    });

    test('a badge already removed by someone else reads the page again', () async {
      when(() => repository.removeBadge('w-9')).thenAnswer((_) async => const Err(Failure(FailureCodes.verificationNotVerified)));
      final cubit = AdminUserCubit(GetAdminUser(repository), AdminUserCommands(repository), 'w-9');
      await cubit.load();

      final failure = await cubit.removeBadge();

      expect(failure?.code, FailureCodes.verificationNotVerified);
      verify(() => repository.user('w-9')).called(2);
      await cubit.close();
    });

    test('one command at a time', () async {
      when(() => repository.logoutAll('w-9')).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Ok(null);
      });
      final cubit = AdminUserCubit(GetAdminUser(repository), AdminUserCommands(repository), 'w-9');
      await cubit.load();

      final first = cubit.logoutAll();
      final second = await cubit.logoutAll();

      expect(second?.code, FailureCodes.requestCancelled);
      expect(await first, isNull);
      verify(() => repository.logoutAll('w-9')).called(1);
      await cubit.close();
    });
  });

  group('AdminArticleCubit', () {
    test('features the article and reads it again', () async {
      var featured = false;
      when(() => repository.article('art-7')).thenAnswer((_) async => Ok(adminArticle(featuredAt: featured ? adminNow : null)));
      when(() => repository.setFeatured('art-7', featured: true)).thenAnswer((_) async {
        featured = true;
        return const Ok(null);
      });
      final cubit = AdminArticleCubit(GetAdminArticle(repository), SetArticleFeatured(repository), 'art-7');
      await cubit.load();
      expect(cubit.state.article!.isFeatured, isFalse);

      final failure = await cubit.setFeatured(true);

      expect(failure, isNull);
      expect(cubit.state.article!.isFeatured, isTrue);
      expect(cubit.state.featuring, isFalse);
      await cubit.close();
    });

    test('a refusal leaves it as it was', () async {
      when(() => repository.article('art-7')).thenAnswer((_) async => Ok(adminArticle(hiddenAt: adminNow)));
      when(() => repository.setFeatured('art-7', featured: true))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.articleNotFound)));
      final cubit = AdminArticleCubit(GetAdminArticle(repository), SetArticleFeatured(repository), 'art-7');
      await cubit.load();

      final failure = await cubit.setFeatured(true);

      expect(failure?.code, FailureCodes.articleNotFound);
      expect(cubit.state.article!.isFeatured, isFalse);
      await cubit.close();
    });
  });

  group('verification review', () {
    AdminVerificationRequest request(VerificationRequestStatus status) => AdminVerificationRequest(
          id: 'v-1',
          status: status,
          user: const AdminVerificationUser(id: 'w-1', displayName: 'Mona', username: 'mona_dev'),
          field: const VerificationField(id: 'f-1', slug: 'software', name: 'Software'),
          jobTitle: 'Engineer',
          submittedAt: adminNow,
        );

    test('the queue pages with its cursor', () async {
      when(() => repository.verificationRequests(VerificationRequestStatus.pending, cursor: null, limit: 20))
          .thenAnswer((_) async => Ok(CursorPage(items: [request(VerificationRequestStatus.pending)], nextCursor: 'n')));
      when(() => repository.verificationRequests(VerificationRequestStatus.pending, cursor: 'n', limit: 20))
          .thenAnswer((_) async => const Ok(CursorPage(items: <AdminVerificationRequest>[])));
      final cubit = VerificationQueueCubit(GetVerificationQueue(repository), VerificationRequestStatus.pending);

      await cubit.load();
      await cubit.loadMore();

      expect(cubit.state.items, hasLength(1));
      expect(cubit.state.hasMore, isFalse);
      await cubit.close();
    });

    test('approve reads the request again; already decided too', () async {
      var status = VerificationRequestStatus.pending;
      when(() => repository.verificationRequest('v-1')).thenAnswer((_) async => Ok(request(status)));
      when(() => repository.approve('v-1')).thenAnswer((_) async {
        status = VerificationRequestStatus.approved;
        return const Ok(null);
      });
      final cubit = VerificationRequestCubit(VerificationReview(repository), 'v-1');
      await cubit.load();

      expect(await cubit.approve(), isNull);
      expect(cubit.state.request!.status, VerificationRequestStatus.approved);
      expect(cubit.state.busy, isNull);

      when(() => repository.reject('v-1', any())).thenAnswer((_) async => const Err(Failure(FailureCodes.verificationAlreadyDecided)));
      final failure = await cubit.reject('  Not enough  ');

      expect(failure?.code, FailureCodes.verificationAlreadyDecided);
      verify(() => repository.reject('v-1', 'Not enough')).called(1);
      verify(() => repository.verificationRequest('v-1')).called(3);
      await cubit.close();
    });

    test('the proof file comes back as bytes', () async {
      when(() => repository.verificationRequest('v-1')).thenAnswer((_) async => Ok(request(VerificationRequestStatus.pending)));
      when(() => repository.proof('v-1')).thenAnswer((_) async => Ok(Uint8List.fromList([1, 2])));
      final cubit = VerificationRequestCubit(VerificationReview(repository), 'v-1');
      await cubit.load();

      final result = await cubit.proof();

      expect(result.bytes, [1, 2]);
      expect(cubit.state.busy, isNull);
      await cubit.close();
    });
  });
}

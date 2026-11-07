import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/features/admin/domain/entities/admin_content.dart';
import 'package:readin/features/admin/domain/entities/admin_dashboard.dart';
import 'package:readin/features/admin/domain/entities/admin_user.dart';
import 'package:readin/features/admin/domain/repositories/admin_repository.dart';
import 'package:readin/features/admin/presentation/cubit/admin_summary_cubit.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/support/domain/entities/support.dart';
import 'package:readin/features/support/domain/repositories/support_repository.dart';

import 'moderation_fakes.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

class MockSupportRepository extends Mock implements SupportRepository {}

class MockAdminSummaryCubit extends MockCubit<AdminSummary?> implements AdminSummaryCubit {}

/// Every permission of the SuperAdmin after F23 and F35 (SPEC §10.2).
const adminPermissions = [
  ...superAdminPermissions,
  Permissions.adminAccess,
  Permissions.usersRead,
  Permissions.supportCreate,
  Permissions.supportManage,
  'notifications.broadcast',
  'audit.read',
];

/// The SuperAdmin with the console (F23). [without] drops permissions, as a later staff role might.
Me adminMe({Set<String> without = const {}}) => Me(
      id: 'u-super',
      phoneNumber: '+12025550101',
      displayName: 'Super Admin',
      username: 'superadmin',
      onboardingCompleted: true,
      roles: const ['SuperAdmin'],
      permissions: [for (final p in adminPermissions) if (!without.contains(p)) p],
    );

/// A Member after F35: can send tickets, nothing of the console.
const supportMemberMe = Me(
  id: 'u-110',
  phoneNumber: '+12025550110',
  displayName: 'Youssef Hassan',
  username: 'reader1',
  onboardingCompleted: true,
  roles: ['Member'],
  permissions: [...memberPermissions, Permissions.supportCreate],
);

final adminNow = DateTime.utc(2026, 11, 7, 12);

AdminUserRow userRow({
  String id = 'w-9',
  String name = 'Free Crypto Deals',
  String username = 'crypto_deals',
  bool suspended = false,
  int openReports = 0,
}) =>
    AdminUserRow(
      id: id,
      displayName: name,
      username: username,
      joinedAt: DateTime.utc(2026, 10, 1),
      lastSeenAt: DateTime.utc(2026, 11, 7, 9),
      signInMethods: const [SignInMethod.phone],
      phoneMasked: '+20***1234',
      suspended: suspended,
      openReports: openReports,
    );

const ticketMember = Author(id: 'u-110', displayName: 'Youssef Hassan', username: 'reader1');

SupportTicketSummary ticketSummary({
  String id = 't-1',
  int number = 12,
  SupportStatus status = SupportStatus.open,
  bool canReopen = false,
}) =>
    SupportTicketSummary(
      id: id,
      number: number,
      category: SupportCategory.appProblem,
      subject: 'التطبيق بيقفل لما أفتح PDF',
      status: status,
      createdAt: DateTime.utc(2026, 11, 6, 10),
      updatedAt: DateTime.utc(2026, 11, 7, 9),
      lastMessage: SupportLastMessage(fromSupport: status == SupportStatus.answered, excerpt: 'Hello', createdAt: DateTime.utc(2026, 11, 7, 9)),
      closedAt: status == SupportStatus.closed ? DateTime.utc(2026, 11, 7) : null,
      canReopen: canReopen,
    );

SupportTicket ticketOf(SupportTicketSummary summary) => SupportTicket(
      summary: summary,
      device: const SupportDevice(platform: 'android', osVersion: 'Android 15', appVersion: '1.2.0+57', language: 'ar', screen: '/settings'),
      messages: [
        SupportMessage(id: 'm-1', fromSupport: false, body: 'لما أفتح ملف PDF التطبيق بيقفل.', createdAt: DateTime.utc(2026, 11, 6, 10)),
        if (summary.status != SupportStatus.open)
          SupportMessage(id: 'm-2', fromSupport: true, body: 'Thanks, we are on it.', createdAt: DateTime.utc(2026, 11, 7, 9)),
      ],
    );

AdminTicketRow adminTicketRow({String id = 't-1', SupportStatus status = SupportStatus.open}) => AdminTicketRow(
      id: id,
      number: 12,
      category: SupportCategory.appProblem,
      subject: 'The app closes when I open a PDF',
      status: status,
      user: ticketMember,
      createdAt: DateTime.utc(2026, 11, 6, 10),
      waitingSince: status == SupportStatus.open ? DateTime.utc(2026, 11, 6, 10) : null,
      lastMessage: SupportLastMessage(fromSupport: false, excerpt: 'It closes', createdAt: DateTime.utc(2026, 11, 6, 10)),
    );

AdminTicket adminTicket({SupportStatus status = SupportStatus.open}) => AdminTicket(
      row: adminTicketRow(status: status),
      member: AdminTicketMember(joinedAt: DateTime.utc(2026, 9, 1), signInMethods: const ['phone'], ticketCount: 2),
      device: const SupportDevice(platform: 'ios', osVersion: 'iOS 18.1', appVersion: '1.2.0+57', language: 'en'),
      messages: [
        SupportMessage(id: 'm-1', fromSupport: false, body: 'It closes', createdAt: DateTime.utc(2026, 11, 6, 10)),
        SupportMessage(
          id: 'm-2',
          fromSupport: true,
          isInternalNote: true,
          body: 'Crash in the PDF viewer, see logs',
          createdAt: DateTime.utc(2026, 11, 6, 11),
        ),
      ],
      reportsAgainst: 0,
    );

AdminArticleRow adminArticle({DateTime? featuredAt, DateTime? hiddenAt}) => AdminArticleRow(
      id: 'art-7',
      slug: 'di-dotnet-10',
      title: 'Dependency Injection في .NET 10',
      language: 'ar-EG',
      field: const FieldRef(id: 'f-1', slug: 'software', nameAr: 'البرمجيات', nameEn: 'Software'),
      publishedAt: DateTime.utc(2026, 11, 1),
      author: modAuthorAr,
      readCount: 120,
      featuredAt: featuredAt,
      hiddenAt: hiddenAt,
    );

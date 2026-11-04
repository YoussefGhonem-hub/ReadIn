import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/verification/domain/entities/verification.dart';
import 'package:readin/features/verification/domain/repositories/verification_repository.dart';
import 'package:readin/features/verification/presentation/cubit/verification_cubit.dart';
import 'package:readin/features/verification/presentation/cubit/verification_form_cubit.dart';

import 'profile_fakes.dart';

/// Writer verification (F19) fixtures: a request sent on 2 Nov 2026 and decided on 3 Nov 2026.
final verificationSubmittedAt = DateTime(2026, 11, 2, 11, 30);
final verificationDecidedAt = DateTime(2026, 11, 3, 16);

const verifiedField = VerificationField(id: 'f-dotnet', slug: 'dotnet', name: '.NET');

const proofLink = 'https://www.linkedin.com/in/youssef-hassan';
const rejectionReason =
    'لينك الـ LinkedIn مش بيفتح، ومحتاجين شهادة أو كارنيه النقابة يوضّح المسمّى الوظيفي (Backend Engineer).';

VerificationRequest verificationRequest({
  String id = 'vr-1',
  VerificationRequestStatus status = VerificationRequestStatus.pending,
  VerificationField field = verifiedField,
  String jobTitle = 'Senior Backend Engineer',
  String? proofUrl = proofLink,
  String? proofFileName = 'كارنيه النقابة.pdf',
  String? note = 'بكتب عن الـ backend والـ Clean Architecture من 2019.',
  DateTime? decidedAt,
  String? reason,
}) =>
    VerificationRequest(
      id: id,
      status: status,
      field: field,
      jobTitle: jobTitle,
      proofUrl: proofUrl,
      proofFileName: proofFileName,
      note: note,
      submittedAt: verificationSubmittedAt,
      decidedAt: decidedAt,
      rejectionReason: reason,
    );

final pendingRequest = verificationRequest();

/// Decided: the file is gone, the link and the reason stay.
final rejectedRequest = verificationRequest(
  status: VerificationRequestStatus.rejected,
  proofFileName: null,
  decidedAt: verificationDecidedAt,
  reason: rejectionReason,
);

final approvedRequest =
    verificationRequest(status: VerificationRequestStatus.approved, proofFileName: null, decidedAt: verificationDecidedAt);

final pendingStatus = VerificationStatus(request: pendingRequest);
final rejectedStatus = VerificationStatus(canRequest: true, request: rejectedRequest);
final approvedStatus = VerificationStatus(isVerified: true, request: approvedRequest);

/// A 2.4 MB syndicate card, accepted as a proof.
const pdfProof = PickedMediaFile(path: '/tmp/card.pdf', name: 'كارنيه النقابة.pdf', sizeBytes: 2516582);

/// [VerificationRepository] over a [status]; a sent request becomes the pending one.
class FakeVerificationRepository implements VerificationRepository {
  FakeVerificationRepository({VerificationStatus? status}) : status = status ?? VerificationStatus.none;

  VerificationStatus status;
  Failure? statusFailure;
  Failure? submitFailure;
  Failure? withdrawFailure;
  final calls = <String>[];
  final submissions = <VerificationSubmission>[];

  @override
  Future<Result<VerificationStatus>> getStatus() async {
    calls.add('status');
    return statusFailure == null ? Ok(status) : Err(statusFailure!);
  }

  @override
  Future<Result<VerificationRequest>> submit(VerificationSubmission submission) async {
    calls.add('submit');
    submissions.add(submission);
    if (submitFailure case final failure?) return Err(failure);
    final request = verificationRequest(
      id: 'vr-${submissions.length + 1}',
      jobTitle: submission.jobTitle,
      proofUrl: submission.proofUrl,
      proofFileName: submission.proof?.name,
      note: submission.note,
    );
    status = VerificationStatus(request: request);
    return Ok(request);
  }

  @override
  Future<Result<void>> withdraw() async {
    calls.add('withdraw');
    if (withdrawFailure case final failure?) return Err(failure);
    status = VerificationStatus.none;
    return const Ok(null);
  }
}

/// The document picker: returns [next] (null = cancelled).
class FakeProofFilePicker implements ProofFilePicker {
  PickedMediaFile? next;
  int picks = 0;

  @override
  Future<PickedMediaFile?> pick() async {
    picks++;
    return next;
  }
}

class MockVerificationCubit extends MockCubit<VerificationState> implements VerificationCubit {}

class MockVerificationFormCubit extends MockCubit<VerificationFormState> implements VerificationFormCubit {}

/// What Settings' signed-in-only Writer verification row reads (F19): a status that stays [state].
BlocProvider<VerificationCubit> verificationEntryProvider([VerificationState state = const VerificationState()]) =>
    BlocProvider<VerificationCubit>.value(value: MockVerificationCubit()..hold(state));

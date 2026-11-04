import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/security/credential_rules.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/cubit/form_support.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/taxonomy/domain/usecases/taxonomy_usecases.dart';
import 'package:readin/features/verification/domain/entities/verification.dart';
import 'package:readin/features/verification/domain/usecases/verification_usecases.dart';
import 'package:readin/features/verification/presentation/cubit/verification_cubit.dart';
import 'package:readin/features/verification/presentation/cubit/verification_form_cubit.dart';

import '../../helpers/editor_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/verification_fixtures.dart';

const offline = Failure(FailureCodes.networkOffline);

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

  VerificationFormCubit formCubit() => VerificationFormCubit(
        GetFields(FakeTaxonomyRepository()),
        PickVerificationProof(picker),
        SubmitVerificationRequest(repository),
      );

  group('VerificationCubit', () {
    test('loads the status: nothing requested yet shows the form', () async {
      final cubit = statusCubit();
      expect(cubit.state.load, VerificationLoad.loading);
      await cubit.load();
      expect(cubit.state.load, VerificationLoad.ready);
      expect(cubit.state.status, VerificationStatus.none);
      expect(cubit.state.screen, VerificationScreen.form);
      expect(cubit.state.draft, isNull);
      verifyNever(session.refresh);
    });

    test('a failed load says why and can be retried', () async {
      repository.statusFailure = offline;
      final cubit = statusCubit();
      await cubit.load();
      expect(cubit.state, const VerificationState(load: VerificationLoad.failure, failure: offline));
      expect(cubit.state.screen, isNull);

      repository.statusFailure = null;
      final states = <VerificationLoad>[];
      final sub = cubit.stream.listen((s) => states.add(s.load));
      await cubit.load();
      await pumpEventQueue();
      await sub.cancel();
      expect(states, [VerificationLoad.loading, VerificationLoad.ready]);
    });

    test('the screen of every status', () async {
      final cases = {
        approvedStatus: VerificationScreen.approved,
        // Verified without a request (the role was given another way).
        const VerificationStatus(isVerified: true): VerificationScreen.approved,
        pendingStatus: VerificationScreen.pending,
        rejectedStatus: VerificationScreen.rejected,
        // Approved once, the role taken away since: a new request.
        VerificationStatus(canRequest: true, request: approvedRequest): VerificationScreen.form,
        // Suspended: no request allowed.
        const VerificationStatus(): VerificationScreen.unavailable,
        VerificationStatus(request: rejectedRequest): VerificationScreen.rejected,
      };
      for (final MapEntry(key: status, value: screen) in cases.entries) {
        repository.status = status;
        final cubit = statusCubit();
        await cubit.load();
        expect(cubit.state.screen, screen, reason: '$status');
      }
    });

    test('"Request again" shows the form starting from the rejected request; Cancel goes back', () async {
      repository.status = rejectedStatus;
      final cubit = statusCubit();
      await cubit.load();
      cubit.requestAgain();
      expect(cubit.state.screen, VerificationScreen.form);
      expect(cubit.state.requestingAgain, isTrue);
      expect(cubit.state.draft, rejectedRequest);

      cubit.cancelRequestAgain();
      expect(cubit.state.screen, VerificationScreen.rejected);
      expect(cubit.state.draft, isNull);
    });

    test('"Request again" does nothing when no request is allowed (suspended)', () async {
      repository.status = VerificationStatus(request: rejectedRequest);
      final cubit = statusCubit();
      await cubit.load();
      cubit.requestAgain();
      expect(cubit.state.screen, VerificationScreen.rejected);
    });

    test('a sent request is pending', () async {
      final cubit = statusCubit();
      await cubit.load();
      cubit.submitted(pendingRequest);
      expect(cubit.state.screen, VerificationScreen.pending);
      expect(cubit.state.status!.canRequest, isFalse);
    });

    test('withdrawing the pending request shows the form, starting from it', () async {
      repository.status = pendingStatus;
      final cubit = statusCubit();
      await cubit.load();
      final withdrawing = <bool>[];
      final sub = cubit.stream.listen((s) => withdrawing.add(s.withdrawing));
      final failure = await cubit.withdraw();
      await pumpEventQueue();
      await sub.cancel();

      expect(failure, isNull);
      expect(withdrawing, [true, false]);
      expect(repository.calls, ['status', 'withdraw']);
      expect(cubit.state.screen, VerificationScreen.form);
      expect(cubit.state.status, VerificationStatus.none);
      expect(cubit.state.draft, pendingRequest);
    });

    test('a failed withdrawal keeps the request and returns why', () async {
      repository
        ..status = pendingStatus
        ..withdrawFailure = offline;
      final cubit = statusCubit();
      await cubit.load();
      expect(await cubit.withdraw(), offline);
      expect(cubit.state.screen, VerificationScreen.pending);
      expect(cubit.state.withdrawing, isFalse);
    });

    test('a request decided meanwhile (404 verification.not_found) is shown as it is now', () async {
      repository.status = pendingStatus;
      final cubit = statusCubit();
      await cubit.load();
      repository
        ..withdrawFailure = const Failure(FailureCodes.verificationNotFound, statusCode: 404)
        ..status = rejectedStatus;
      expect((await cubit.withdraw())?.code, FailureCodes.verificationNotFound);
      expect(repository.calls, ['status', 'withdraw', 'status']);
      expect(cubit.state.screen, VerificationScreen.rejected);
    });

    test('nothing to withdraw without a pending request', () async {
      repository.status = rejectedStatus;
      final cubit = statusCubit();
      await cubit.load();
      expect(await cubit.withdraw(), isNull);
      expect(repository.calls, ['status']);
    });

    test('an approval the session does not know yet reads me again, so the badge shows', () async {
      repository.status = approvedStatus;
      await statusCubit().load();
      verify(session.refresh).called(1);

      session.hold(const SessionState(status: SessionStatus.authenticated, me: Me(id: 'u-1', displayName: 'Y', username: 'y', isVerified: true)));
      await statusCubit().load();
      verifyNever(session.refresh);

      // The badge was taken away: me follows too.
      repository.status = VerificationStatus.none;
      await statusCubit().load();
      verify(session.refresh).called(1);
    });
  });

  group('VerificationFormCubit', () {
    test('loads the fields', () async {
      final cubit = formCubit();
      await cubit.loadFields();
      expect(cubit.state.fieldsStatus, VerificationLoad.ready);
      expect(cubit.state.fields, editorFields);
    });

    test('checks every input before sending anything', () async {
      final cubit = formCubit();
      await cubit.loadFields();
      await cubit.submit(jobTitle: '  ', proofUrl: '', note: '');
      expect(cubit.state.errors, {
        VerificationFormFields.field: CredentialCodes.required,
        VerificationFormFields.jobTitle: CredentialCodes.required,
        VerificationFormFields.proof: FailureCodes.verificationProofRequired,
      });
      expect(repository.calls, isEmpty);

      cubit.selectField(editorFields.first.id);
      expect(cubit.state.errors.containsKey(VerificationFormFields.field), isFalse, reason: 'cleared once chosen');
      await cubit.submit(jobTitle: 'A', proofUrl: 'http://linkedin.com/in/x', note: 'n' * 501);
      expect(cubit.state.errors, {
        VerificationFormFields.jobTitle: FailureCodes.validationMinLength,
        VerificationFormFields.proofUrl: FailureCodes.validationUrl,
        VerificationFormFields.note: FailureCodes.validationMaxLength,
      });

      await cubit.submit(jobTitle: 'x' * 101, proofUrl: 'https://github.com/mona/${'a' * 500}', note: '');
      expect(cubit.state.errors, {
        VerificationFormFields.jobTitle: FailureCodes.validationMaxLength,
        VerificationFormFields.proofUrl: FailureCodes.validationUrl,
      });
      await cubit.submit(jobTitle: 'Engineer', proofUrl: 'https://exa mple.com', note: '');
      expect(cubit.state.errors, {VerificationFormFields.proofUrl: FailureCodes.validationUrl});
      expect(repository.calls, isEmpty);
    });

    test('sends the trimmed values, a link without its scheme as https, and leaves out what is empty', () async {
      final cubit = formCubit();
      await cubit.loadFields();
      cubit.selectField('f-dotnet');
      await cubit.submit(jobTitle: '  Senior Backend Engineer ', proofUrl: ' linkedin.com/in/youssef ', note: '   ');

      expect(repository.submissions.single, const VerificationSubmission(
        fieldId: 'f-dotnet',
        jobTitle: 'Senior Backend Engineer',
        proofUrl: 'https://linkedin.com/in/youssef',
      ));
      expect(cubit.state.status, FormStatus.success);
      expect(cubit.state.created?.jobTitle, 'Senior Backend Engineer');
      expect(cubit.state.created?.isPending, isTrue);
    });

    test('a file alone is enough proof', () async {
      picker.next = pdfProof;
      final cubit = formCubit();
      await cubit.loadFields();
      cubit.selectField('f-dotnet');
      await cubit.pickProof();
      expect(cubit.state.proof, pdfProof);
      await cubit.submit(jobTitle: 'Engineer', proofUrl: '', note: 'Syndicate member');
      expect(repository.submissions.single.proof, pdfProof);
      expect(repository.submissions.single.proofUrl, isNull);
      expect(repository.submissions.single.note, 'Syndicate member');
    });

    test('a picked file is checked on the device: PDF, JPEG, PNG or WebP up to 10 MB', () async {
      final cubit = formCubit();
      for (final file in [
        const PickedMediaFile(path: '/t/cv.docx', name: 'cv.docx', sizeBytes: 1000),
        const PickedMediaFile(path: '/t/card.png', name: 'card.png', sizeBytes: 10 * 1024 * 1024 + 1),
        const PickedMediaFile(path: '/t/card', name: 'card', sizeBytes: 10),
      ]) {
        picker.next = file;
        await cubit.pickProof();
        expect(cubit.state.proof, isNull, reason: file.name);
        expect(cubit.state.errors, {VerificationFormFields.proof: FailureCodes.verificationProofInvalid}, reason: file.name);
      }
      for (final name in ['card.PDF', 'card.jpg', 'card.jpeg', 'card.png', 'card.webp']) {
        picker.next = PickedMediaFile(path: '/t/$name', name: name, sizeBytes: 10 * 1024 * 1024);
        await cubit.pickProof();
        expect(cubit.state.proof?.name, name);
        expect(cubit.state.errors, isEmpty, reason: name);
      }

      // Cancelled: nothing changes. Removed: gone.
      picker.next = null;
      await cubit.pickProof();
      expect(cubit.state.proof?.name, 'card.webp');
      expect(cubit.state.picking, isFalse);
      cubit.removeProof();
      expect(cubit.state.proof, isNull);
      expect(picker.picks, 9);
    });

    test('the server errors land on their inputs; the rest is for the whole form', () async {
      final cubit = formCubit();
      await cubit.loadFields();
      cubit.selectField('f-dotnet');
      Future<VerificationFormState> sendWith(Failure failure) async {
        repository.submitFailure = failure;
        await cubit.submit(jobTitle: 'Engineer', proofUrl: 'https://github.com/x', note: '');
        return cubit.state;
      }

      var state = await sendWith(const Failure(FailureCodes.verificationFieldInvalid, statusCode: 400));
      expect(state.errors, {VerificationFormFields.field: FailureCodes.verificationFieldInvalid});
      expect((state.failure, state.status), (null, FormStatus.idle));

      state = await sendWith(const Failure(FailureCodes.verificationProofInvalid, statusCode: 400));
      expect(state.errors, {VerificationFormFields.proof: FailureCodes.verificationProofInvalid});

      state = await sendWith(const Failure(FailureCodes.validationFailed, statusCode: 400, fieldErrors: {
        'JobTitle': ['validation.max_length'],
        'proofUrl': ['validation.url'],
        'note': ['validation.max_length'],
        'fieldId': ['validation.required'],
      }));
      expect(state.errors, {
        VerificationFormFields.jobTitle: 'validation.max_length',
        VerificationFormFields.proofUrl: 'validation.url',
        VerificationFormFields.note: 'validation.max_length',
        VerificationFormFields.field: 'validation.required',
      });
      expect(state.failure, isNull);

      const unmatched = Failure(FailureCodes.validationFailed, statusCode: 400, fieldErrors: {'other': ['validation.invalid']});
      state = await sendWith(unmatched);
      expect(state.errors, isEmpty);
      expect(state.failure, unmatched);

      for (final failure in [
        const Failure(FailureCodes.verificationAlreadyPending, statusCode: 409),
        const Failure(FailureCodes.verificationAlreadyVerified, statusCode: 409),
        const Failure(FailureCodes.userSuspended, statusCode: 403),
        offline,
      ]) {
        state = await sendWith(failure);
        expect(state.errors, isEmpty);
        expect((state.failure, state.status), (failure, FormStatus.idle));
      }

      cubit.dismissFailure();
      expect(cubit.state.failure, isNull);
    });

    test('editing an input clears its error; a link also answers "add a link or a file"', () async {
      final cubit = formCubit();
      await cubit.submit(jobTitle: '', proofUrl: '', note: '');
      cubit.edited(VerificationFormFields.jobTitle);
      expect(cubit.state.errors.keys, [VerificationFormFields.field, VerificationFormFields.proof]);
      cubit.edited(VerificationFormFields.proofUrl);
      expect(cubit.state.errors.keys, [VerificationFormFields.field]);
    });

    test('begin starts a fresh form from a request, keeping the loaded fields', () async {
      picker.next = pdfProof;
      final cubit = formCubit();
      await cubit.loadFields();
      await cubit.pickProof();
      await cubit.submit(jobTitle: '', proofUrl: '', note: '');

      cubit.begin(fieldId: 'f-ai');
      expect(cubit.state, const VerificationFormState(fields: editorFields, fieldsStatus: VerificationLoad.ready, fieldId: 'f-ai'));
    });
  });

  group('use cases', () {
    test('a request without proof, or with a file that is not a proof, is refused without a request', () async {
      final submit = SubmitVerificationRequest(repository);
      expect((await submit(const VerificationSubmission(fieldId: 'f', jobTitle: 'Engineer'))).failureOrNull,
          SubmitVerificationRequest.proofRequired);
      expect(
        (await submit(const VerificationSubmission(
          fieldId: 'f',
          jobTitle: 'Engineer',
          proof: PickedMediaFile(path: '/t/a.gif', name: 'a.gif', sizeBytes: 10),
        )))
            .failureOrNull,
        SubmitVerificationRequest.proofInvalid,
      );
      expect(repository.calls, isEmpty);
    });

    test('a proof of unknown size is left to the server', () {
      expect(isAcceptedProof(const PickedMediaFile(path: '/t/a.pdf', name: 'a.pdf')), isTrue);
      expect(fileExtensionOf('a.'), '');
      expect(fileExtensionOf('archive.tar.GZ'), 'gz');
    });
  });
}

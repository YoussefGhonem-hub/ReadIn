@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/security/credential_rules.dart';
import 'package:readin/features/verification/domain/entities/verification.dart';
import 'package:readin/features/verification/presentation/cubit/verification_cubit.dart';
import 'package:readin/features/verification/presentation/cubit/verification_form_cubit.dart';
import 'package:readin/features/verification/presentation/pages/verification_page.dart';

import '../helpers/editor_fixtures.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/test_app.dart';
import '../helpers/verification_fixtures.dart';

/// Settings → Writer verification (F19), in ar/light and en/dark (the other two variants build and lay out too).
void main() {
  Future<void> pumpView(
    WidgetTester tester,
    Variant variant, {
    required VerificationState state,
    VerificationFormState form = const VerificationFormState(),
    double height = 1100,
  }) async {
    usePhoneSurface(tester, size: Size(390, height));
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<VerificationCubit>.value(value: MockVerificationCubit()..hold(state)),
          BlocProvider<VerificationFormCubit>.value(value: MockVerificationFormCubit()..hold(form)),
        ],
        child: const VerificationView(),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  // The form after a request was withdrawn: it starts from that request (job title, link, note), with a field and a
  // syndicate card chosen.
  final filledForm = VerificationState(
    load: VerificationLoad.ready,
    status: VerificationStatus.none,
    draft: verificationRequest(jobTitle: 'Senior Backend Engineer', proofUrl: proofLink),
  );
  const formWithFile = VerificationFormState(
    fields: editorFields,
    fieldsStatus: VerificationLoad.ready,
    fieldId: 'f-ai',
    proof: pdfProof,
  );

  for (final variant in Variant.all) {
    testWidgets('verification form ${variant.name}', (tester) async {
      await pumpView(tester, variant, state: filledForm, form: formWithFile, height: 1180);
      await expectLater(find.byType(VerificationView), matchesVariantGolden(variant, 'goldens/verification_form_${variant.name}.png'));
    });

    // Sent empty: the field and job title are required, and a link or a file is needed as proof.
    testWidgets('verification form errors ${variant.name}', (tester) async {
      await pumpView(
        tester,
        variant,
        state: const VerificationState(load: VerificationLoad.ready, status: VerificationStatus.none),
        form: const VerificationFormState(
          fields: editorFields,
          fieldsStatus: VerificationLoad.ready,
          errors: {
            VerificationFormFields.field: CredentialCodes.required,
            VerificationFormFields.jobTitle: CredentialCodes.required,
            VerificationFormFields.proof: FailureCodes.verificationProofRequired,
          },
        ),
        height: 1180,
      );
      await expectLater(
        find.byType(VerificationView),
        matchesVariantGolden(variant, 'goldens/verification_form_errors_${variant.name}.png'),
      );
    });

    testWidgets('verification pending ${variant.name}', (tester) async {
      await pumpView(tester, variant, state: VerificationState(load: VerificationLoad.ready, status: pendingStatus), height: 1000);
      await expectLater(find.byType(VerificationView), matchesVariantGolden(variant, 'goldens/verification_pending_${variant.name}.png'));
    });

    // Decided: the reviewer's reason (Arabic, in its own direction in either UI), what was sent (the file is gone),
    // and "Request again".
    testWidgets('verification rejected ${variant.name}', (tester) async {
      await pumpView(tester, variant, state: VerificationState(load: VerificationLoad.ready, status: rejectedStatus), height: 1000);
      await expectLater(find.byType(VerificationView), matchesVariantGolden(variant, 'goldens/verification_rejected_${variant.name}.png'));
    });
  }
}

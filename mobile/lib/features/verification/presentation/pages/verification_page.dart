import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/presentation/cubit/form_support.dart';
import '../cubit/verification_cubit.dart';
import '../cubit/verification_form_cubit.dart';
import '../widgets/verification_form.dart';
import '../widgets/verification_status_views.dart';

/// Settings → Writer verification (F19), signed in only; `readin://verification` (a verification result) opens it.
class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});

  static const path = '/settings/verification';

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<VerificationCubit>()..load()),
          // The fields load with the page (`GET /fields` is cached for the session), ready when the form shows.
          BlocProvider(create: (_) => getIt<VerificationFormCubit>()..loadFields()),
        ],
        child: const VerificationView(),
      );
}

/// The status (approved, pending with "Withdraw", rejected with the reason and "Request again") or the request form,
/// once a [VerificationCubit] and a [VerificationFormCubit] are provided.
class VerificationView extends StatelessWidget {
  const VerificationView({super.key});

  /// A request is pending or I'm verified already: the page was stale, show what is true now.
  static const _staleCodes = {FailureCodes.verificationAlreadyPending, FailureCodes.verificationAlreadyVerified};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<VerificationFormCubit, VerificationFormState>(
      listenWhen: (a, b) => a.status != b.status || a.failure != b.failure,
      listener: (context, form) {
        if (form.status == FormStatus.success && form.created != null) {
          context.read<VerificationCubit>().submitted(form.created!);
        } else if (form.failure case final failure? when _staleCodes.contains(failure.code)) {
          showActionFailure(context, failure);
          context.read<VerificationFormCubit>().dismissFailure();
          unawaited(context.read<VerificationCubit>().load());
        }
      },
      // A form page: white under the white bar, its inputs and the request card framed by their borders.
      child: Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(title: Text(l10n.verificationTitle)),
        body: BlocBuilder<VerificationCubit, VerificationState>(
          builder: (context, state) => switch (state.load) {
            VerificationLoad.loading => const Center(child: CircularProgressIndicator()),
            VerificationLoad.failure => ErrorView(failure: state.failure!, onRetry: () => unawaited(context.read<VerificationCubit>().load())),
            VerificationLoad.ready => switch (state.screen!) {
                VerificationScreen.approved => VerificationApprovedView(status: state.status!),
                VerificationScreen.pending => VerificationPendingView(request: state.status!.request!, withdrawing: state.withdrawing),
                VerificationScreen.rejected =>
                  VerificationRejectedView(request: state.status!.request!, canRequest: state.status!.canRequest),
                VerificationScreen.form => VerificationForm(
                    // A new form for each start: "Request again" and a withdrawn request fill it.
                    key: ValueKey('verification-form-${state.draft?.id}'),
                    draft: state.draft,
                    onCancel: state.requestingAgain ? () => context.read<VerificationCubit>().cancelRequestAgain() : null,
                  ),
                VerificationScreen.unavailable => EmptyView(
                    icon: Icons.block_rounded,
                    title: l10n.verificationUnavailableTitle,
                    body: l10n.verificationUnavailableBody,
                  ),
              },
          },
        ),
      ),
    );
  }
}

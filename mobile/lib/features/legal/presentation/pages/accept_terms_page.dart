import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart';
import '../../domain/entities/legal.dart';
import '../cubit/accept_terms_cubit.dart';
import '../widgets/legal_links.dart';

/// The blocking terms screen (F37, SPEC §9.2 after the password and PIN guards): an account that hasn't accepted the
/// Terms version in effect reads what changed and the pages, then «موافق» / "I agree". Declining offers sign out or
/// delete account. There is no way past it otherwise (no Back).
class AcceptTermsPage extends StatelessWidget {
  const AcceptTermsPage({super.key, this.cubit});

  static const path = '/account/terms';

  /// Test seam; the app takes the cubit from DI.
  final AcceptTermsCubit? cubit;

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => (cubit ?? getIt<AcceptTermsCubit>())..load(), child: const AcceptTermsView());
}

class AcceptTermsView extends StatelessWidget {
  const AcceptTermsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final firstTime = context.select((SessionCubit c) => c.state.me?.termsVersion == null);
    return PopScope(
      canPop: false,
      child: BlocBuilder<AcceptTermsCubit, AcceptTermsState>(
        builder: (context, state) {
          final cubit = context.read<AcceptTermsCubit>();
          final summary = state.legal?.summaryFor(l10n.localeName);
          final pages = state.legal?.pages;
          Widget page(LegalPage legal, IconData icon, String label) => OutlinedButton.icon(
                key: ValueKey('terms-open-${legal.name}'),
                onPressed: () => unawaited(openLegalPage(context, legal, pages: pages ?? LegalPages.defaults)),
                icon: Icon(icon, size: 18),
                label: Text(label),
              );
          return AuthScaffold(
            automaticallyImplyLeading: false,
            title: firstTime ? l10n.termsGateTitleFirst : l10n.termsGateTitleUpdated,
            subtitle: l10n.termsGateBody,
            children: [
              if (summary != null) ...[
                Container(
                  key: const ValueKey('terms-summary'),
                  padding: const EdgeInsets.all(ReadInSpace.s3),
                  decoration: BoxDecoration(
                    color: colors.calloutInfo,
                    borderRadius: BorderRadius.circular(ReadInRadius.md),
                    border: BorderDirectional(start: BorderSide(color: colors.calloutInfoAccent, width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.termsGateChanges, style: context.textTheme.titleSmall),
                      const SizedBox(height: ReadInSpace.s1),
                      Text(summary, style: context.textTheme.bodyMedium?.copyWith(height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: ReadInSpace.s4),
              ],
              page(LegalPage.terms, Icons.gavel_rounded, l10n.legalTerms),
              const SizedBox(height: ReadInSpace.s2),
              page(LegalPage.communityGuidelines, Icons.groups_outlined, l10n.legalGuidelines),
              const SizedBox(height: ReadInSpace.s2),
              page(LegalPage.privacy, Icons.privacy_tip_outlined, l10n.legalPrivacy),
              const SizedBox(height: ReadInSpace.s5),
              if (state.failure case final failure?) ...[
                FailureBanner(failure: failure),
                const SizedBox(height: ReadInSpace.s3),
              ],
              SubmitButton(
                label: l10n.termsGateAgree,
                submitting: state.accepting,
                onPressed: () => unawaited(cubit.accept()),
              ),
              const SizedBox(height: ReadInSpace.s3),
              TextButton(
                key: const ValueKey('terms-sign-out'),
                onPressed: state.accepting ? null : () => unawaited(context.read<SessionCubit>().signOut()),
                child: Text(l10n.signOut),
              ),
              TextButton(
                key: const ValueKey('terms-delete-account'),
                style: TextButton.styleFrom(foregroundColor: colors.error),
                onPressed: state.accepting ? null : () => unawaited(context.push<void>('/account/delete')),
                child: Text(l10n.termsGateDeleteAccount),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/support.dart';
import '../../domain/entities/support_failures.dart';
import '../cubit/support_cubits.dart';
import '../support_routes.dart';
import '../widgets/support_email.dart';
import '../widgets/support_widgets.dart';

/// A new support ticket (`/settings/support/new`, F35): a category, a subject (5–120), a message (10–2000) and up to 3
/// screenshots; the app adds the device details. The ticket opens once sent.
class NewTicketPage extends StatelessWidget {
  const NewTicketPage({super.key, this.from, this.cubit});

  /// The route the ticket came from.
  final String? from;

  /// Test seam; the app takes the cubit from DI.
  final NewTicketCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final allowed = context.select((SessionCubit c) => c.state.me?.canContactSupport ?? false);
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.supportNewTicket)),
        body: const Padding(padding: EdgeInsets.all(PageBlock.gutter), child: SupportEmailCard()),
      );
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => cubit ?? getIt<NewTicketCubit>()),
        if (getIt.isRegistered<SupportConfigCubit>()) BlocProvider(create: (_) => getIt<SupportConfigCubit>()..load()),
      ],
      child: NewTicketView(from: from),
    );
  }
}

class NewTicketView extends StatefulWidget {
  const NewTicketView({super.key, this.from});

  final String? from;

  @override
  State<NewTicketView> createState() => _NewTicketViewState();
}

class _NewTicketViewState extends State<NewTicketView> {
  final _subject = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<NewTicketCubit>();
    FocusScope.of(context).unfocus();
    final failure = await cubit.submit(screen: widget.from);
    if (!mounted || failure != null) return;
    final ticket = cubit.state.created;
    if (ticket == null) return;
    // The new ticket replaces the form, so Back leads to the list.
    context.pushReplacement(SupportRoutes.ticket(ticket.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<NewTicketCubit>();
    final categories = context.select((SupportConfigCubit? c) => c?.state?.categories) ?? SupportCategory.values;
    return BlocBuilder<NewTicketCubit, NewTicketState>(
      builder: (context, state) {
        final errors = state.showErrors;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.supportNewTicket)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: ReadInSpace.s6),
            children: [
              if (state.failure case final failure? when failure.code != FailureCodes.validationFailed || state.isValid)
                PageBlock(
                  margin: const EdgeInsets.only(top: PageBlock.gap),
                  padding: const EdgeInsets.all(PageBlock.gutter),
                  child: _FailureNote(failure: failure),
                ),
              PageBlock(
                margin: const EdgeInsets.only(top: PageBlock.gap),
                padding: const EdgeInsets.all(PageBlock.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.supportCategoryLabel, style: context.textTheme.labelLarge),
                    const SizedBox(height: ReadInSpace.s2),
                    Wrap(
                      spacing: ReadInSpace.s2,
                      runSpacing: ReadInSpace.s2,
                      children: [
                        for (final category in categories)
                          ChoiceChip(
                            key: ValueKey('support-category-${category.wire}'),
                            label: Text(l10n.supportCategory(category)),
                            selected: state.category == category,
                            showCheckmark: false,
                            onSelected: state.sending ? null : (_) => cubit.setCategory(category),
                          ),
                      ],
                    ),
                    if (errors && !state.categoryValid)
                      Padding(
                        padding: const EdgeInsets.only(top: ReadInSpace.s1),
                        child: Text(l10n.supportCategoryRequired, style: context.textTheme.bodySmall?.copyWith(color: colors.error)),
                      ),
                    const SizedBox(height: ReadInSpace.s4),
                    BidiTextField(
                      key: const ValueKey('support-subject'),
                      controller: _subject,
                      enabled: !state.sending,
                      maxLength: SupportLimits.subjectMax,
                      counterWithin: 20,
                      onChanged: cubit.setSubject,
                      decoration: InputDecoration(
                        labelText: l10n.supportSubject,
                        errorText: errors && !state.subjectValid ? l10n.supportSubjectError : null,
                      ),
                    ),
                    const SizedBox(height: ReadInSpace.s3),
                    BidiTextField(
                      key: const ValueKey('support-message'),
                      controller: _message,
                      enabled: !state.sending,
                      minLines: 5,
                      maxLines: 12,
                      maxLength: SupportLimits.messageMax,
                      counterWithin: 200,
                      onChanged: cubit.setMessage,
                      decoration: InputDecoration(
                        labelText: l10n.supportMessage,
                        alignLabelWithHint: true,
                        helperText: l10n.supportMessageHint,
                        errorText: errors && !state.messageValid ? l10n.supportMessageError : null,
                      ),
                    ),
                    const SizedBox(height: ReadInSpace.s4),
                    Text(l10n.supportScreenshots, style: context.textTheme.labelLarge),
                    const SizedBox(height: ReadInSpace.s1),
                    Text(l10n.supportScreenshotsHint, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                    const SizedBox(height: ReadInSpace.s2),
                    ScreenshotPickerRow(
                      files: state.screenshots,
                      enabled: !state.sending,
                      onAdd: () => unawaited(cubit.pickScreenshots()),
                      onRemove: cubit.removeScreenshot,
                    ),
                    const SizedBox(height: ReadInSpace.s4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: colors.textSecondary),
                        const SizedBox(width: ReadInSpace.s2),
                        Expanded(
                          child: Text(l10n.supportDeviceNote, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: ReadInSpace.s4),
                    FilledButton(
                      key: const ValueKey('support-send'),
                      onPressed: state.sending ? null : () => unawaited(_submit()),
                      child: state.sending
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                const SizedBox(width: ReadInSpace.s2),
                                Text(l10n.supportSending),
                              ],
                            )
                          : Text(l10n.supportSend),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Why the ticket wasn't sent: the ticket limit says which one (5 a day or 10 open), anything else its message.
class _FailureNote extends StatelessWidget {
  const _FailureNote({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final message = switch (failure) {
      SupportLimitFailure(limit: SupportLimitKind.daily) => l10n.errSupportLimitDaily,
      SupportLimitFailure(limit: SupportLimitKind.open) => l10n.errSupportLimitOpen,
      _ => localizeActionFailure(l10n, failure),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('support-failure'),
        padding: const EdgeInsets.all(ReadInSpace.s3),
        decoration: BoxDecoration(
          color: colors.calloutDanger,
          borderRadius: BorderRadius.circular(ReadInRadius.md),
          border: BorderDirectional(start: BorderSide(color: colors.calloutDangerAccent, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.calloutDangerAccent),
            const SizedBox(width: ReadInSpace.s2),
            Expanded(child: Text(message, style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary))),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart';
import '../../../media/presentation/widgets/attachment_bar.dart' show formatFileSize;
import '../../domain/entities/verification.dart';
import '../cubit/verification_cubit.dart' show VerificationLoad;
import '../cubit/verification_form_cubit.dart';

/// The verification request form (F19): field, job title, proof (a link, a file, or both) and an optional note. It
/// starts from [draft] (a rejected request sent again, or one just withdrawn), without its file.
class VerificationForm extends StatefulWidget {
  const VerificationForm({super.key, this.draft, this.onCancel});

  final VerificationRequest? draft;

  /// Back to the rejected request; null hides "Cancel".
  final VoidCallback? onCancel;

  static const submitKey = ValueKey('verification-submit');
  static const fieldKey = ValueKey('verification-field');
  static const jobTitleKey = ValueKey('verification-job-title');
  static const proofUrlKey = ValueKey('verification-proof-url');
  static const noteKey = ValueKey('verification-note');
  static const attachKey = ValueKey('verification-attach');
  static const removeFileKey = ValueKey('verification-remove-file');

  @override
  State<VerificationForm> createState() => _VerificationFormState();
}

class _VerificationFormState extends State<VerificationForm> {
  late final TextEditingController _jobTitle;
  late final TextEditingController _proofUrl;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _jobTitle = TextEditingController(text: draft?.jobTitle ?? '');
    _proofUrl = TextEditingController(text: draft?.proofUrl ?? '');
    _note = TextEditingController(text: draft?.note ?? '');
    context.read<VerificationFormCubit>().begin(fieldId: draft?.field.id);
  }

  @override
  void dispose() {
    for (final c in [_jobTitle, _proofUrl, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    unawaited(context.read<VerificationFormCubit>().submit(jobTitle: _jobTitle.text, proofUrl: _proofUrl.text, note: _note.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<VerificationFormCubit>();
    return BlocBuilder<VerificationFormCubit, VerificationFormState>(
      builder: (context, state) {
        final busy = state.submitting;
        String? error(String field) => errorText(context, state.errors[field]);
        return ListView(
          padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, ReadInSpace.s6),
          children: [
            Text(l10n.verificationIntro, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary, height: 1.6)),
            const SizedBox(height: ReadInSpace.s5),
            if (state.failure case final failure?) ...[
              FailureBanner(failure: failure),
              const SizedBox(height: ReadInSpace.s4),
            ],
            _FieldPicker(state: state, enabled: !busy),
            const SizedBox(height: ReadInSpace.s4),
            BidiTextField(
              key: VerificationForm.jobTitleKey,
              controller: _jobTitle,
              enabled: !busy,
              maxLength: VerificationLimits.jobTitleMax,
              counterWithin: 20,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => cubit.edited(VerificationFormFields.jobTitle),
              decoration: InputDecoration(
                labelText: l10n.verificationJobTitleLabel,
                hintText: l10n.verificationJobTitleHint,
                prefixIcon: const Icon(Icons.work_outline_rounded),
                errorText: error(VerificationFormFields.jobTitle),
              ),
            ),
            const SizedBox(height: ReadInSpace.s5),
            Semantics(header: true, child: Text(l10n.verificationProofTitle, style: context.textTheme.titleSmall)),
            const SizedBox(height: ReadInSpace.s1),
            Text(l10n.verificationProofHint, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
            const SizedBox(height: ReadInSpace.s3),
            TextField(
              key: VerificationForm.proofUrlKey,
              controller: _proofUrl,
              enabled: !busy,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(VerificationLimits.proofUrlMax)],
              onChanged: (_) => cubit.edited(VerificationFormFields.proofUrl),
              decoration: InputDecoration(
                labelText: l10n.verificationProofUrlLabel,
                hintText: 'https://linkedin.com/in/…',
                hintTextDirection: TextDirection.ltr,
                prefixIcon: const Icon(Icons.link_rounded),
                errorText: error(VerificationFormFields.proofUrl),
              ),
            ),
            const SizedBox(height: ReadInSpace.s3),
            _ProofFile(state: state, enabled: !busy),
            const SizedBox(height: ReadInSpace.s4),
            BidiTextField(
              key: VerificationForm.noteKey,
              controller: _note,
              enabled: !busy,
              maxLength: VerificationLimits.noteMax,
              counterWithin: 100,
              minLines: 3,
              maxLines: 6,
              onChanged: (_) => cubit.edited(VerificationFormFields.note),
              decoration: InputDecoration(
                labelText: l10n.verificationNoteLabel,
                hintText: l10n.verificationNoteHint,
                alignLabelWithHint: true,
                errorText: error(VerificationFormFields.note),
              ),
            ),
            const SizedBox(height: ReadInSpace.s5),
            SubmitButton(
              key: VerificationForm.submitKey,
              label: l10n.verificationSubmit,
              progressLabel: l10n.verificationSubmitting,
              submitting: busy,
              onPressed: state.picking ? null : _submit,
            ),
            if (widget.onCancel case final cancel?) ...[
              const SizedBox(height: ReadInSpace.s2),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: busy ? null : cancel,
                child: Text(l10n.cancel),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The field, from `GET /fields` in the UI language; a failed load can be retried.
class _FieldPicker extends StatelessWidget {
  const _FieldPicker({required this.state, required this.enabled});

  final VerificationFormState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<VerificationFormCubit>();
    final lang = Localizations.localeOf(context).languageCode;
    final fieldId = state.fields.any((f) => f.id == state.fieldId) ? state.fieldId : null;
    final loading = state.fieldsStatus == VerificationLoad.loading;
    final failed = state.fieldsStatus == VerificationLoad.failure;
    return DropdownButtonFormField<String>(
      key: ValueKey('${VerificationForm.fieldKey.value}-${state.fields.length}-$fieldId'),
      initialValue: fieldId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.verificationFieldLabel,
        hintText: l10n.verificationFieldHint,
        prefixIcon: const Icon(Icons.category_outlined),
        suffixIcon: loading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : failed
                ? IconButton(
                    tooltip: l10n.retry,
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => unawaited(cubit.loadFields()),
                  )
                : null,
        helperText: failed ? l10n.verificationFieldsFailed : null,
        errorText: errorText(context, state.errors[VerificationFormFields.field]),
      ),
      items: [
        for (final f in state.fields)
          DropdownMenuItem(value: f.id, child: BidiText(f.nameFor(lang), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: enabled && state.fields.isNotEmpty ? cubit.selectField : null,
    );
  }
}

/// "Attach a file" (PDF, JPEG, PNG or WebP up to 10 MB), or the chosen file with "Remove"; then who sees it.
class _ProofFile extends StatelessWidget {
  const _ProofFile({required this.state, required this.enabled});

  final VerificationFormState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<VerificationFormCubit>();
    final file = state.proof;
    final proofError = state.errors[VerificationFormFields.proof];
    final secondary = context.textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (file == null)
          OutlinedButton.icon(
            key: VerificationForm.attachKey,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: proofError == null ? null : BorderSide(color: colors.error),
            ),
            icon: state.picking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.attach_file_rounded, size: 20),
            label: Text(l10n.verificationProofFileAdd),
            onPressed: enabled && !state.picking ? () => unawaited(cubit.pickProof()) : null,
          )
        else
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s3, ReadInSpace.s2, ReadInSpace.s1, ReadInSpace.s2),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(ReadInRadius.md),
              border: Border.all(color: proofError == null ? colors.border : colors.error),
            ),
            child: Row(
              children: [
                Icon(
                  fileExtensionOf(file.name) == 'pdf' ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                  color: colors.primary,
                ),
                const SizedBox(width: ReadInSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BidiText(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodyMedium),
                      if (file.sizeBytes case final size?) Text(formatFileSize(l10n, size), style: secondary),
                    ],
                  ),
                ),
                IconButton(
                  key: VerificationForm.removeFileKey,
                  tooltip: l10n.verificationProofFileRemove,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: enabled ? cubit.removeProof : null,
                ),
              ],
            ),
          ),
        const SizedBox(height: ReadInSpace.s2),
        if (proofError != null)
          Semantics(
            liveRegion: true,
            child: Text(errorText(context, proofError)!, style: context.textTheme.bodySmall?.copyWith(color: colors.error)),
          )
        else
          Text(l10n.verificationProofFileHint, style: secondary),
        const SizedBox(height: ReadInSpace.s2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.lock_outline_rounded, size: 16, color: colors.textSecondary),
            ),
            const SizedBox(width: ReadInSpace.s2),
            Expanded(child: Text(l10n.verificationProofPrivate, style: secondary)),
          ],
        ),
      ],
    );
  }
}

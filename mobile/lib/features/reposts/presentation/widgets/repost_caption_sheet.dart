import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/domain/entities/article.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../domain/entities/repost_state.dart';

/// What a submitted caption sheet saved.
enum RepostCaptionResult {
  /// A new repost: "أعدت نشر المقال." / "You reposted this article.".
  reposted,

  /// The caption of an existing repost: "اتحفظ رأيك." / "Your thoughts were saved.".
  saved,
}

/// "Repost with your thoughts" ([editing] false) or "Edit your thoughts" ([editing] true, prefilled from
/// `GET /articles/{id}/repost`), F29. Rides above the keyboard. Once saved, a message confirms it (as on the web) and
/// the result says what was saved; null when the sheet was closed without saving.
Future<RepostCaptionResult?> showRepostCaptionSheet(
  BuildContext context, {
  required ArticleCard article,
  required bool editing,
}) async {
  final engagement = context.read<EngagementCubit>();
  final result = await showModalBottomSheet<RepostCaptionResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => BlocProvider.value(
      value: engagement,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: RepostCaptionSheet(article: article, editing: editing),
      ),
    ),
  );
  if (result != null && context.mounted) {
    final l10n = context.l10n;
    showActionMessage(context, result == RepostCaptionResult.saved ? l10n.repostCaptionSaved : l10n.repostCaptionReposted);
  }
  return result;
}

/// The caption dialog: the title, a compact preview of the article (its author and title), the caption field with
/// "n/500" (red over the limit, which also disables the button), then "Repost" (or "Save" when editing) and "Cancel".
/// It waits for the API and stays open with the error shown when the API refuses (e.g. `repost.caption_too_long`,
/// `repost.own_article`). Needs an [EngagementCubit] above it; pops a [RepostCaptionResult] once saved.
class RepostCaptionSheet extends StatefulWidget {
  const RepostCaptionSheet({super.key, required this.article, required this.editing});

  final ArticleCard article;
  final bool editing;

  @override
  State<RepostCaptionSheet> createState() => _RepostCaptionSheetState();
}

class _RepostCaptionSheetState extends State<RepostCaptionSheet> {
  final _caption = TextEditingController();
  final _focus = FocusNode(debugLabel: 'repost-caption');

  /// Editing: the viewer's caption is loading, or failed to load.
  late bool _loading = widget.editing;
  Failure? _loadFailure;

  /// The viewer's repost exists: "Save" instead of "Repost" (the prefill can find that it was undone meanwhile).
  late bool _editing = widget.editing;

  bool _sending = false;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _caption.addListener(_onText);
    if (widget.editing) {
      unawaited(_load());
    } else {
      _focusField();
    }
  }

  @override
  void dispose() {
    _caption
      ..removeListener(_onText)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onText() => setState(() {});

  void _focusField() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailure = null;
    });
    final result = await context.read<EngagementCubit>().loadRepost(widget.article);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _loadFailure = failure;
      }),
      (repost) {
        _caption.text = repost.caption ?? '';
        setState(() {
          _loading = false;
          _editing = repost.isReposted;
        });
        _focusField();
      },
    );
  }

  Future<void> _submit() async {
    final caption = RepostState.normalizeCaption(_caption.text);
    setState(() {
      _sending = true;
      _failure = null;
    });
    final failure = await context.read<EngagementCubit>().repostWithCaption(widget.article, caption);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(_editing ? RepostCaptionResult.saved : RepostCaptionResult.reposted);
      return;
    }
    setState(() {
      _sending = false;
      _failure = failure.code == FailureCodes.requestCancelled ? null : failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final length = RepostState.normalizeCaption(_caption.text).length;
    final over = length > RepostState.maxCaptionLength;
    final busy = context.select((EngagementCubit c) => c.state.of(widget.article).reposting);
    final ready = !_loading && _loadFailure == null;
    final failure = _failure;
    final error = over ? l10n.errRepostCaptionTooLong : (failure == null ? null : localizeActionFailure(l10n, failure));

    final Widget field = switch ((_loading, _loadFailure)) {
      (true, _) => const Padding(
          padding: EdgeInsets.symmetric(vertical: ReadInSpace.s5),
          child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
        ),
      (_, final loadFailure?) => ErrorView(failure: loadFailure, compact: true, onRetry: () => unawaited(_load())),
      _ => BidiTextField(
          controller: _caption,
          focusNode: _focus,
          enabled: !_sending,
          minLines: 4,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: l10n.repostCaptionHint,
            errorText: error,
            errorMaxLines: 3,
            counter: Text(
              '$length/${RepostState.maxCaptionLength}',
              key: const ValueKey('repost-caption-counter'),
              textDirection: TextDirection.ltr,
              style: context.textTheme.bodySmall?.copyWith(
                color: over ? colors.error : colors.textSecondary,
                fontWeight: over ? FontWeight.w600 : null,
              ),
            ),
          ),
        ),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.repostCaptionTitle, style: context.textTheme.titleLarge)),
          const SizedBox(height: ReadInSpace.s3),
          RepostArticlePreview(article: widget.article),
          const SizedBox(height: ReadInSpace.s4),
          field,
          const SizedBox(height: ReadInSpace.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: ReadInSpace.s2),
              FilledButton(
                key: const ValueKey('repost-caption-submit'),
                onPressed: ready && !over && !_sending && !busy ? () => unawaited(_submit()) : null,
                style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                child: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_editing ? l10n.save : l10n.repostCaptionSubmit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The article being reposted, compact: the author's avatar and name, then the title on up to two lines.
class RepostArticlePreview extends StatelessWidget {
  const RepostArticlePreview({super.key, required this.article});

  final ArticleCard article;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final author = article.author;
    final titleDir = Bidi.detect(article.title) ?? Directionality.of(context);
    return Container(
      padding: const EdgeInsets.all(ReadInSpace.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(ReadInRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (author == null)
                const GenericAvatar(size: 24)
              else
                UserAvatar(name: author.displayName, url: author.avatarUrl, size: 24),
              const SizedBox(width: ReadInSpace.s2),
              Flexible(
                child: BidiText(
                  author?.displayName ?? context.l10n.deletedUser,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: author == null ? colors.textSecondary : colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (author?.isVerified ?? false) ...[const SizedBox(width: 4), const VerifiedMark()],
            ],
          ),
          const SizedBox(height: ReadInSpace.s2),
          Text(
            Bidi.isolateOppositeRuns(article.title, titleDir),
            textDirection: titleDir,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleSmall?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

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
import '../../../../shared/widgets/sign_in_prompt.dart';
import '../../../article/domain/entities/article.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/comment_text.dart';
import '../cubit/comments_cubit.dart';
import '../cubit/mention_suggestions_cubit.dart';

/// The composer pinned under the comments (F11): a multi-line field whose direction follows its text, a counter in the
/// last 200 of 2000 characters, @mention suggestions while typing `@handle`, and the reply / edit bar. A new comment
/// leaves the field at once (it shows as pending in the list) and comes back if the API refuses it.
class CommentComposer extends StatefulWidget {
  const CommentComposer({super.key, this.initialText = ''});

  /// For golden tests.
  final String initialText;

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  // The unsent text from the last time the sheet was open comes back (F34).
  late final _controller =
      TextEditingController(text: widget.initialText.isNotEmpty ? widget.initialText : context.read<CommentsCubit>().draft);
  final _focus = FocusNode();
  MentionQuery? _mention;
  String? _prefill;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final cubit = context.read<CommentsCubit>();
    // An edit's text is the comment's, and a reply's "@handle " alone isn't written yet: neither is an unsent comment.
    if (!(cubit.state.target?.isEdit ?? false)) cubit.saveDraft(_controller.text == _prefill ? '' : _controller.text);
    final selection = _controller.selection;
    final mention = selection.isCollapsed ? CommentText.activeMention(_controller.text, selection.baseOffset) : null;
    if (mention != _mention) {
      _mention = mention;
      context.read<MentionSuggestionsCubit>().search(mention?.query);
    }
    setState(() {}); // the send button follows the text
  }

  void _pickMention(Author user) {
    final mention = _mention;
    if (mention == null) return;
    final (text, caret) = CommentText.insertMention(_controller.text, mention, user.username);
    _controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: caret));
    context.read<MentionSuggestionsCubit>().clear();
  }

  void _onTarget(ComposerTarget? target) {
    if (target == null) return;
    final myId = context.read<SessionCubit>().state.me?.id;
    if (target.isEdit) {
      _setText(target.comment.body ?? '');
    } else {
      // Replying to a reply mentions its author (the API joins the thread either way).
      final author = target.comment.author;
      final mention = target.comment.isReply && author != null && author.id != myId ? '@${author.username} ' : '';
      final replace = _controller.text.isEmpty || _controller.text == _prefill;
      _prefill = mention;
      if (replace) _setText(mention);
    }
    _focus.requestFocus();
  }

  void _setText(String text) =>
      _controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

  void _cancelTarget() {
    final target = context.read<CommentsCubit>().state.target;
    if (target != null && (target.isEdit || _controller.text == _prefill)) _controller.clear();
    _prefill = null;
    context.read<CommentsCubit>().clearTarget();
  }

  Future<void> _send() async {
    final cubit = context.read<CommentsCubit>();
    final me = context.read<SessionCubit>().state.me;
    final text = _controller.text;
    if (me == null || text.trim().isEmpty) return;
    final editing = cubit.state.target?.isEdit ?? false;
    if (!editing) {
      _controller.clear();
      _prefill = null;
    }
    context.read<MentionSuggestionsCubit>().clear();
    final author = Author(id: me.id, displayName: me.displayName, username: me.username, avatarUrl: me.avatarUrl, isVerified: me.isVerified);
    final failure = await cubit.submit(text, author: author);
    if (!mounted) return;
    if (failure == null) {
      if (editing) _controller.clear();
      return;
    }
    // The restored reply target may have put its `@handle ` back first: the whole text replaces it.
    if (!editing && (_controller.text.isEmpty || _controller.text == _prefill)) _setText(text);
    _showFailure(failure);
  }

  void _showFailure(Failure failure) {
    if (failure.code == FailureCodes.requestCancelled) return;
    showActionMessage(context, localizeCommentFailure(context.l10n, failure));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (target, sending) = context.select((CommentsCubit c) => (c.state.target, c.state.sending));
    final suggestions = context.watch<MentionSuggestionsCubit>().state;
    final canSend = _controller.text.trim().isNotEmpty && !sending;
    return BlocListener<CommentsCubit, CommentsState>(
      listenWhen: (a, b) => a.target != b.target,
      listener: (_, state) => _onTarget(state.target),
      child: Material(
        color: colors.surface,
        shape: Border(top: BorderSide(color: colors.border)),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_mention != null && suggestions.isNotEmpty) MentionSuggestionList(users: suggestions, onPick: _pickMention),
              if (target != null) _TargetBar(target: target, onCancel: _cancelTarget),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s4, ReadInSpace.s2, ReadInSpace.s2, ReadInSpace.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: BidiTextField(
                        controller: _controller,
                        focusNode: _focus,
                        directionOf: CommentText.withoutMentions,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: CommentText.maxLength,
                        counterWithin: CommentText.counterWithin,
                        enabled: !sending,
                        decoration: InputDecoration(
                          hintText: target == null || target.isEdit ? l10n.commentsComposerHint : l10n.commentsReplyHint,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4, vertical: ReadInSpace.s3),
                        ),
                      ),
                    ),
                    const SizedBox(width: ReadInSpace.s1),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: sending
                          ? const SizedBox(
                              width: 48,
                              height: 48,
                              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                            )
                          : IconButton.filled(
                              tooltip: target?.isEdit ?? false ? l10n.save : l10n.commentsSend,
                              onPressed: canSend ? _send : null,
                              icon: Icon(target?.isEdit ?? false ? Icons.check_rounded : Icons.send_rounded, size: 20),
                              style: IconButton.styleFrom(
                                disabledBackgroundColor: colors.surfaceVariant,
                                disabledForegroundColor: colors.textSecondary,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Replying to Omar ✕" / "Editing your comment ✕" above the field.
class _TargetBar extends StatelessWidget {
  const _TargetBar({required this.target, required this.onCancel});

  final ComposerTarget target;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final name = target.comment.author?.displayName ?? l10n.commentsDeletedUser;
    final text = target.isEdit ? l10n.commentsEditing : l10n.commentsReplyingTo(Bidi.isolateOppositeRuns(name, Directionality.of(context)));
    return Material(
      color: colors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: ReadInSpace.s4),
        child: Row(
          children: [
            Icon(target.isEdit ? Icons.edit_outlined : Icons.reply_rounded, size: 16, color: colors.textSecondary),
            const SizedBox(width: ReadInSpace.s2),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ),
            IconButton(
              tooltip: l10n.cancel,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}

/// The people matching the `@word` being typed, above the field. A tap inserts `@username `.
class MentionSuggestionList extends StatelessWidget {
  const MentionSuggestionList({super.key, required this.users, required this.onPick});

  final List<Author> users;
  final ValueChanged<Author> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: context.l10n.commentsMentionSuggestions,
      container: true,
      child: Material(
        color: colors.surfaceRaised,
        shape: Border(bottom: BorderSide(color: colors.border)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];
              return ListTile(
                dense: true,
                minTileHeight: 48,
                onTap: () => onPick(user),
                leading: UserAvatar(name: user.displayName, url: user.avatarUrl, size: 32),
                title: Row(
                  children: [
                    Flexible(child: BidiText(user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (user.isVerified) ...[const SizedBox(width: 4), const VerifiedMark(size: 12)],
                  ],
                ),
                subtitle: Text(Bidi.ltrIsolate('@${user.username}'), style: context.textTheme.bodySmall),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// What guests see instead of the composer: an invitation to sign in (the soft prompt, F01).
class CommentGuestPrompt extends StatelessWidget {
  const CommentGuestPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.border))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4, vertical: ReadInSpace.s3),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 20, color: colors.textSecondary),
              const SizedBox(width: ReadInSpace.s3),
              Expanded(child: Text(l10n.commentsGuestPrompt, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary))),
              const SizedBox(width: ReadInSpace.s2),
              FilledButton(onPressed: () => showSignInPrompt(context), child: Text(l10n.signIn)),
            ],
          ),
        ),
      ),
    );
  }
}

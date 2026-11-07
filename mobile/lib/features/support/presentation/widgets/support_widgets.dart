import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../admin/presentation/widgets/admin_widgets.dart' show AdminRow, adminDateTime, adminTime;
import '../../../media/domain/entities/media.dart';
import '../../../profile/presentation/widgets/profile_header.dart' show ProfileBioText, UsernameText;
import '../../domain/entities/support.dart';
import '../cubit/support_cubits.dart';

/// ar/en text for the support enums (F35).
extension SupportLabels on AppLocalizations {
  String supportCategory(SupportCategory? category) => switch (category) {
        SupportCategory.appProblem => supportCategoryAppProblem,
        SupportCategory.account => supportCategoryAccount,
        SupportCategory.content => supportCategoryContent,
        SupportCategory.verification => supportCategoryVerification,
        SupportCategory.suggestion => supportCategorySuggestion,
        SupportCategory.other || null => supportCategoryOther,
      };

  String supportStatus(SupportStatus status) => switch (status) {
        SupportStatus.open => supportStatusOpen,
        SupportStatus.answered => supportStatusAnswered,
        SupportStatus.closed => supportStatusClosed,
      };
}

/// "#12", always left to right.
String ticketNumber(int number) => Bidi.ltrIsolate('#$number');

/// Open (waiting for support) / Answered (waiting for you) / Closed.
class SupportStatusTag extends StatelessWidget {
  const SupportStatusTag({super.key, required this.status});

  final SupportStatus status;

  @override
  Widget build(BuildContext context) => InfoTag(
        label: context.l10n.supportStatus(status),
        tone: switch (status) {
          SupportStatus.open => InfoTagTone.primary,
          SupportStatus.answered => InfoTagTone.success,
          SupportStatus.closed => InfoTagTone.neutral,
        },
      );
}

/// A row of My tickets: "#12 · category", the subject, the last message and when.
class SupportTicketTile extends StatelessWidget {
  const SupportTicketTile({super.key, required this.ticket, this.onTap});

  final SupportTicketSummary ticket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final secondary = context.textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final last = ticket.lastMessage;
    return AdminRow(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${ticketNumber(ticket.number)} · ${l10n.supportCategory(ticket.category)}', style: secondary),
              ),
              SupportStatusTag(status: ticket.status),
            ],
          ),
          const SizedBox(height: ReadInSpace.s1),
          ProfileBioText(ticket.subject, maxLines: 2, style: context.textTheme.titleSmall),
          if (last.excerpt.isNotEmpty) ...[
            const SizedBox(height: 2),
            ProfileBioText(
              '${last.fromSupport ? l10n.supportTeam : l10n.supportYou}: ${last.excerpt}',
              maxLines: 2,
              style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: 2),
          Text(adminTime(context, ticket.updatedAt), style: secondary),
        ],
      ),
    );
  }
}

/// A row of the console's queue: the member, "#12 · category", the subject, how long it has waited, the last message.
class AdminTicketTile extends StatelessWidget {
  const AdminTicketTile({super.key, required this.ticket, this.compact = false, this.onTap});

  final AdminTicketRow ticket;

  /// In a user's page: without the member.
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final secondary = context.textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final last = ticket.lastMessage;
    final waiting = ticket.waitingSince;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          Row(
            children: [
              ExcludeSemantics(child: UserAvatar(name: ticket.user.displayName, url: ticket.user.avatarUrl, size: 24)),
              const SizedBox(width: ReadInSpace.s2),
              Flexible(child: BidiText(ticket.user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.labelLarge)),
              const SizedBox(width: ReadInSpace.s1),
              Flexible(child: UsernameText(ticket.user.username, style: secondary)),
            ],
          ),
          const SizedBox(height: ReadInSpace.s1),
        ],
        Row(
          children: [
            Expanded(child: Text('${ticketNumber(ticket.number)} · ${l10n.supportCategory(ticket.category)}', style: secondary)),
            SupportStatusTag(status: ticket.status),
          ],
        ),
        const SizedBox(height: 2),
        ProfileBioText(ticket.subject, maxLines: 2, style: context.textTheme.titleSmall),
        if (last.excerpt.isNotEmpty) ...[
          const SizedBox(height: 2),
          ProfileBioText(
            '${last.isInternalNote ? l10n.supportInternalNote : last.fromSupport ? l10n.supportTeam : l10n.supportMember}: ${last.excerpt}',
            maxLines: 2,
            style: secondary,
          ),
        ],
        const SizedBox(height: 2),
        Text(
          waiting != null ? l10n.supportWaiting(adminTime(context, waiting)) : adminTime(context, last.createdAt),
          style: secondary?.copyWith(color: waiting != null ? colors.error : null),
        ),
      ],
    );
    if (compact) {
      return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2), child: content));
    }
    return AdminRow(onTap: onTap, child: content);
  }
}

/// A message of the conversation: the member's at the end side, support's at the start, internal notes in the warning
/// color with "Internal note". The text keeps its own direction; screenshots open full screen.
class SupportMessageBubble extends StatelessWidget {
  const SupportMessageBubble({super.key, required this.message, this.adminView = false});

  final SupportMessage message;

  /// The console: authors are named, notes are shown.
  final bool adminView;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final mine = adminView ? message.fromSupport : !message.fromSupport;
    final note = message.isInternalNote;
    final (background, border) = note
        ? (colors.calloutWarning, colors.calloutWarningAccent)
        : mine
            ? (colors.primaryContainer, colors.primaryContainer)
            : (colors.surface, colors.border);
    final who = note
        ? l10n.supportInternalNote
        : adminView
            ? (message.author?.displayName ?? (message.fromSupport ? l10n.supportTeam : l10n.supportMember))
            : (message.fromSupport ? l10n.supportTeam : l10n.supportYou);
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
        child: Container(
          key: ValueKey('support-message-${message.id}'),
          margin: const EdgeInsets.symmetric(vertical: ReadInSpace.s1),
          padding: const EdgeInsets.all(ReadInSpace.s3),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(ReadInRadius.md),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (note) ...[Icon(Icons.lock_outline_rounded, size: 14, color: colors.calloutWarningAccent), const SizedBox(width: 4)],
                  if (!note && message.fromSupport) ...[
                    Icon(Icons.support_agent_rounded, size: 14, color: colors.textSecondary),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      Bidi.isolateOppositeRuns(who, Directionality.of(context)),
                      style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: ReadInSpace.s2),
                  Text(adminTime(context, message.createdAt), style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondary)),
                ],
              ),
              const SizedBox(height: ReadInSpace.s1),
              ProfileBioText(message.body, style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary, height: 1.5)),
              if (message.attachments.isNotEmpty) ...[
                const SizedBox(height: ReadInSpace.s2),
                Wrap(
                  spacing: ReadInSpace.s2,
                  runSpacing: ReadInSpace.s2,
                  children: [for (final attachment in message.attachments) SupportAttachmentThumb(attachment: attachment)],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A screenshot of a ticket, read with the session through [SupportAttachmentCache]; a tap shows it full screen.
class SupportAttachmentThumb extends StatelessWidget {
  const SupportAttachmentThumb({super.key, required this.attachment, this.size = 88, this.cache});

  final SupportAttachment attachment;
  final double size;

  /// Test seam; the app's cache otherwise.
  final SupportAttachmentCache? cache;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final source = cache ?? (getIt.isRegistered<SupportAttachmentCache>() ? getIt<SupportAttachmentCache>() : null);
    final radius = BorderRadius.circular(ReadInRadius.sm);
    Widget frame(Widget child) => ClipRRect(
          borderRadius: radius,
          child: Container(width: size, height: size, color: colors.surfaceVariant, alignment: Alignment.center, child: child),
        );
    if (source == null) return frame(Icon(Icons.image_outlined, color: colors.textSecondary));
    return FutureBuilder<Result<Uint8List>>(
      future: source.get(attachment.id),
      builder: (context, snapshot) {
        final bytes = snapshot.data?.valueOrNull;
        if (snapshot.connectionState != ConnectionState.done) {
          return frame(const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (bytes == null || bytes.isEmpty) {
          return Tooltip(
            message: context.l10n.supportImageFailed,
            child: frame(Icon(Icons.broken_image_outlined, color: colors.textSecondary)),
          );
        }
        return Semantics(
          button: true,
          label: context.l10n.supportOpenImage,
          child: InkWell(
            borderRadius: radius,
            onTap: () => unawaited(_showFull(context, bytes)),
            child: frame(Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true)),
          ),
        );
      },
    );
  }

  static Future<void> _showFull(BuildContext context, Uint8List bytes) => showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(child: InteractiveViewer(child: Center(child: Image.memory(bytes)))),
              PositionedDirectional(
                top: ReadInSpace.s2,
                end: ReadInSpace.s2,
                child: SafeArea(
                  child: IconButton(
                    tooltip: context.l10n.close,
                    color: Colors.white,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// The screenshots picked for a new ticket or a reply, each with Remove, and "Add a screenshot" while fewer than 3.
class ScreenshotPickerRow extends StatelessWidget {
  const ScreenshotPickerRow({super.key, required this.files, required this.onAdd, required this.onRemove, this.enabled = true});

  final List<PickedMediaFile> files;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Wrap(
      spacing: ReadInSpace.s2,
      runSpacing: ReadInSpace.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < files.length; i++)
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(ReadInRadius.sm),
                child: Container(
                  width: 64,
                  height: 64,
                  color: colors.surfaceVariant,
                  child: files[i].path.isEmpty
                      ? Icon(Icons.image_outlined, color: colors.textSecondary)
                      : Image.file(
                          File(files[i].path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(Icons.image_outlined, color: colors.textSecondary),
                        ),
                ),
              ),
              PositionedDirectional(
                top: -10,
                end: -10,
                child: IconButton(
                  key: ValueKey('screenshot-remove-$i'),
                  tooltip: l10n.supportRemoveScreenshot,
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(backgroundColor: colors.surface, foregroundColor: colors.textPrimary),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: enabled ? () => onRemove(i) : null,
                ),
              ),
            ],
          ),
        if (files.length < SupportLimits.maxScreenshots)
          OutlinedButton.icon(
            key: const ValueKey('screenshot-add'),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(l10n.supportAddScreenshot(files.length, SupportLimits.maxScreenshots)),
            onPressed: enabled ? onAdd : null,
          ),
      ],
    );
  }
}

/// The message box under a conversation: the text (1–2000), optional screenshots ([screenshots] null hides them, e.g.
/// support's replies are text only), and Send.
class SupportComposer extends StatefulWidget {
  const SupportComposer({
    super.key,
    required this.hint,
    required this.sendLabel,
    required this.onSend,
    this.busy = false,
    this.pickScreenshots,
    this.leading,
  });

  final String hint;
  final String sendLabel;
  final bool busy;

  /// Sends; true clears the box.
  final Future<bool> Function(String text, List<PickedMediaFile> screenshots) onSend;

  /// Picks images (up to the [int] given); null: no screenshots.
  final Future<List<PickedMediaFile>> Function(int limit)? pickScreenshots;

  /// Above the box, e.g. the reply / note switch of the console.
  final Widget? leading;

  @override
  State<SupportComposer> createState() => _SupportComposerState();
}

class _SupportComposerState extends State<SupportComposer> {
  final _text = TextEditingController();
  var _files = <PickedMediaFile>[];

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || widget.busy) return;
    if (await widget.onSend(text, _files) && mounted) {
      _text.clear();
      setState(() => _files = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pick = widget.pickScreenshots;
    final canSend = _text.text.trim().isNotEmpty && !widget.busy;
    return Material(
      color: colors.surface,
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s3, ReadInSpace.s2, ReadInSpace.s3, ReadInSpace.s2),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?widget.leading,
              if (pick != null && _files.isNotEmpty) ...[
                ScreenshotPickerRow(
                  files: _files,
                  enabled: !widget.busy,
                  onAdd: () => unawaited(_add(pick)),
                  onRemove: (i) => setState(() => _files = [..._files]..removeAt(i)),
                ),
                const SizedBox(height: ReadInSpace.s2),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (pick != null && _files.length < SupportLimits.maxScreenshots)
                    IconButton(
                      key: const ValueKey('composer-attach'),
                      tooltip: context.l10n.supportAttach,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      onPressed: widget.busy ? null : () => unawaited(_add(pick)),
                    ),
                  Expanded(
                    child: BidiTextField(
                      key: const ValueKey('composer-text'),
                      controller: _text,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: SupportLimits.messageMax,
                      counterWithin: 200,
                      decoration: InputDecoration(hintText: widget.hint, isDense: true),
                    ),
                  ),
                  const SizedBox(width: ReadInSpace.s2),
                  widget.busy
                      ? const Padding(
                          padding: EdgeInsets.all(ReadInSpace.s3),
                          child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton.filled(
                          key: const ValueKey('composer-send'),
                          tooltip: widget.sendLabel,
                          icon: const Icon(Icons.send_rounded),
                          onPressed: canSend ? () => unawaited(_send()) : null,
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _add(Future<List<PickedMediaFile>> Function(int limit) pick) async {
    final picked = await pick(SupportLimits.maxScreenshots - _files.length);
    if (!mounted || picked.isEmpty) return;
    setState(() => _files = [..._files, ...picked].take(SupportLimits.maxScreenshots).toList());
  }
}

/// The device details the app added to a ticket.
class SupportDeviceCard extends StatelessWidget {
  const SupportDeviceCard({super.key, required this.device, required this.createdAt});

  final SupportDevice device;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    Widget row(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(child: Text(label, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary))),
                Flexible(child: Text(value, textDirection: TextDirection.ltr, style: context.textTheme.bodySmall)),
              ],
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(l10n.supportDevicePlatform, device.platform),
        row(l10n.supportDeviceOs, device.osVersion),
        row(l10n.supportDeviceApp, device.appVersion),
        row(l10n.supportDeviceLanguage, device.language),
        row(l10n.supportDeviceScreen, device.screen),
        row(l10n.supportDeviceSent, adminDateTime(context, createdAt)),
      ],
    );
  }
}

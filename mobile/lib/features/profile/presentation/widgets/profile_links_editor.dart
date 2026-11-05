import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart' show errorText;
import '../../domain/entities/profile_link.dart';
import '../cubit/edit_profile_cubit.dart';
import 'platform_icon.dart';

/// "روابط" / "Links" in Edit profile (F14): up to 8 links in the member's order. "+ إضافة رابط" picks a platform,
/// then the link (and a name for Other); each link can change platform, move (drag the handle, or Move up / Move down
/// in its menu, which screen readers reach too) and be removed. Each error shows under its own field. Needs an
/// [EditProfileCubit] above.
class ProfileLinksEditor extends StatelessWidget {
  const ProfileLinksEditor({super.key, required this.state});

  final EditProfileState state;

  static const addKey = ValueKey('profile-links-add');

  static Key tileKey(int id) => ValueKey('profile-link-draft-$id');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<EditProfileCubit>();
    final links = state.links;
    final full = state.linksFull;
    final listError = state.errors[ProfileFields.links];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Semantics(header: true, child: Text(l10n.profileLinksSection, style: context.textTheme.titleSmall))),
            Semantics(
              label: l10n.profileLinksCountSemantics(links.length, ProfileLinkRules.maxLinks),
              excludeSemantics: true,
              child: Text(
                '${links.length}/${ProfileLinkRules.maxLinks}',
                textDirection: TextDirection.ltr,
                style: context.textTheme.labelMedium?.copyWith(color: full ? colors.primary : colors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: ReadInSpace.s1),
        Text(
          full ? l10n.profileLinksFull : l10n.profileLinksHint,
          style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        if (listError != null) ...[
          const SizedBox(height: ReadInSpace.s2),
          Semantics(
            liveRegion: true,
            child: Text(errorText(context, listError)!, style: context.textTheme.bodySmall?.copyWith(color: colors.error)),
          ),
        ],
        if (links.isNotEmpty) ...[
          const SizedBox(height: ReadInSpace.s3),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: links.length,
            onReorderItem: cubit.reorderLinks,
            proxyDecorator: (child, _, _) => Material(color: Colors.transparent, elevation: 4, child: child),
            itemBuilder: (context, i) => Padding(
              key: tileKey(links[i].id),
              padding: const EdgeInsets.only(bottom: ReadInSpace.s3),
              child: _LinkTile(draft: links[i], index: i, count: links.length, state: state),
            ),
          ),
        ] else
          const SizedBox(height: ReadInSpace.s2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: addKey,
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: full || state.submitting
                ? null
                : () async {
                    final platform = await pickLinkPlatform(context, used: state.usedPlatforms);
                    if (platform != null) cubit.addLink(platform);
                  },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(l10n.profileLinkAdd),
          ),
        ),
      ],
    );
  }
}

/// The platform picker: the 14 platforms with their icons; a named platform that already has a link ([used], except
/// [current]) is shown but can't be picked. Null when dismissed.
Future<LinkPlatform?> pickLinkPlatform(BuildContext context, {required Set<LinkPlatform> used, LinkPlatform? current}) {
  final l10n = context.l10n;
  return showModalBottomSheet<LinkPlatform>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s2),
            child: Semantics(header: true, child: Text(l10n.profileLinkPickPlatform, style: context.textTheme.titleMedium)),
          ),
          for (final platform in LinkPlatform.values)
            Builder(builder: (context) {
              final taken = platform != current && platform != LinkPlatform.other && used.contains(platform);
              return ListTile(
                key: ValueKey('link-platform-${platform.wire}'),
                minTileHeight: 56,
                enabled: !taken,
                selected: platform == current,
                leading: PlatformIcon(platform, color: taken ? context.colors.textSecondary : context.colors.textPrimary),
                title: Text(linkPlatformName(l10n, platform)),
                subtitle: taken ? Text(l10n.profileLinkPlatformAdded) : null,
                trailing: platform == current ? Icon(Icons.check_rounded, color: context.colors.primary) : null,
                onTap: () => Navigator.of(context).pop(platform),
              );
            }),
        ],
      ),
    ),
  );
}

enum _LinkAction { up, down, remove }

/// One link: drag handle, its platform (tap to change it), "⋯" (move up / down, remove), the address and, for Other,
/// its name.
class _LinkTile extends StatefulWidget {
  const _LinkTile({required this.draft, required this.index, required this.count, required this.state});

  final LinkDraft draft;
  final int index;
  final int count;
  final EditProfileState state;

  @override
  State<_LinkTile> createState() => _LinkTileState();
}

class _LinkTileState extends State<_LinkTile> {
  late final _url = TextEditingController(text: widget.draft.url);
  late final _label = TextEditingController(text: widget.draft.label);

  @override
  void dispose() {
    _url.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _changePlatform() async {
    final cubit = context.read<EditProfileCubit>();
    final platform = await pickLinkPlatform(context, used: widget.state.usedPlatforms, current: widget.draft.platform);
    if (platform != null) cubit.changeLinkPlatform(widget.draft.id, platform);
  }

  /// `instagram.com/…`, or `https://…` for any site.
  static String _hint(LinkPlatform platform) => platform.hosts.isEmpty ? 'https://…' : '${platform.hosts.first}/…';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<EditProfileCubit>();
    final draft = widget.draft;
    final i = widget.index;
    final busy = widget.state.submitting;
    final errors = widget.state.errors;
    final name = linkPlatformName(l10n, draft.platform);
    final platformError = errors[ProfileFields.linkField(i, 'platform')];

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s1, ReadInSpace.s1, ReadInSpace.s1, ReadInSpace.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ReadInRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Dragging is for pointers; the "⋯" menu moves a link for everyone else.
              ExcludeSemantics(
                child: ReorderableDragStartListener(
                  index: i,
                  enabled: !busy,
                  child: SizedBox.square(
                    dimension: 48,
                    child: Icon(Icons.drag_indicator_rounded, color: colors.textSecondary),
                  ),
                ),
              ),
              Expanded(
                // Its own node: the list item around it would otherwise merge it with the address field.
                child: Semantics(
                  container: true,
                  button: true,
                  label: '$name, ${l10n.profileLinkChangePlatform}',
                  excludeSemantics: true,
                  child: InkWell(
                    key: ValueKey('profile-link-platform-${draft.id}'),
                    onTap: busy ? null : _changePlatform,
                    borderRadius: BorderRadius.circular(ReadInRadius.sm),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: [
                          PlatformIcon(draft.platform, size: 20, color: colors.textPrimary),
                          const SizedBox(width: ReadInSpace.s2),
                          Flexible(
                            child: Text(name, style: context.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: ReadInSpace.s1),
                          Icon(Icons.expand_more_rounded, size: 20, color: colors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              PopupMenuButton<_LinkAction>(
                key: ValueKey('profile-link-menu-${draft.id}'),
                tooltip: l10n.profileLinkOptions(name),
                enabled: !busy,
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (action) => switch (action) {
                  _LinkAction.up => cubit.moveLink(draft.id, -1),
                  _LinkAction.down => cubit.moveLink(draft.id, 1),
                  _LinkAction.remove => cubit.removeLink(draft.id),
                },
                itemBuilder: (_) => [
                  if (i > 0)
                    PopupMenuItem(
                      value: _LinkAction.up,
                      child: ListTile(leading: const Icon(Icons.arrow_upward_rounded), title: Text(l10n.profileLinkMoveUp)),
                    ),
                  if (i < widget.count - 1)
                    PopupMenuItem(
                      value: _LinkAction.down,
                      child: ListTile(leading: const Icon(Icons.arrow_downward_rounded), title: Text(l10n.profileLinkMoveDown)),
                    ),
                  PopupMenuItem(
                    value: _LinkAction.remove,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded, color: colors.error),
                      title: Text(l10n.profileLinkRemove, style: TextStyle(color: colors.error)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: ReadInSpace.s3, end: ReadInSpace.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (platformError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: ReadInSpace.s2),
                    child: Text(errorText(context, platformError)!, style: context.textTheme.bodySmall?.copyWith(color: colors.error)),
                  ),
                // Each field its own node too (the list item would merge them).
                Semantics(
                  container: true,
                  child: TextField(
                    key: ValueKey('profile-link-url-${draft.id}'),
                    controller: _url,
                    enabled: !busy,
                    // Addresses are left to right in both languages.
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'[\r\n\t]')),
                      LengthLimitingTextInputFormatter(ProfileLinkRules.maxUrlLength),
                    ],
                    onChanged: (value) => cubit.linkUrlChanged(draft.id, value),
                    decoration: InputDecoration(
                      labelText: l10n.profileLinkUrl,
                      hintText: _hint(draft.platform),
                      hintTextDirection: TextDirection.ltr,
                      errorText: errorText(context, errors[ProfileFields.linkField(i, 'url')]),
                      errorMaxLines: 2,
                    ),
                  ),
                ),
                if (draft.platform == LinkPlatform.other) ...[
                  const SizedBox(height: ReadInSpace.s3),
                  Semantics(
                    container: true,
                    child: BidiTextField(
                      key: ValueKey('profile-link-label-${draft.id}'),
                      controller: _label,
                      enabled: !busy,
                      maxLength: ProfileLinkRules.maxLabelLength,
                      counterWithin: 10,
                      maxLines: 1,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\r\n\t]'))],
                      onChanged: (value) => cubit.linkLabelChanged(draft.id, value),
                      decoration: InputDecoration(
                        labelText: l10n.profileLinkLabel,
                        hintText: Bidi.isolateOppositeRuns(l10n.profileLinkLabelHint, Directionality.of(context)),
                        errorText: errorText(context, errors[ProfileFields.linkField(i, 'label')]),
                        errorMaxLines: 2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

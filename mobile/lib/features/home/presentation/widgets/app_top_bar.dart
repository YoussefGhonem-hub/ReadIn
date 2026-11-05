import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../../notifications/presentation/cubit/unread_badge_cubit.dart';
import '../../../search/presentation/widgets/search_entry_bar.dart';
import '../../../settings/presentation/widgets/theme_toggle_button.dart';
import 'me_sheet.dart';

/// The top bar of the main tabs (Home, Explore, Saved): the viewer's avatar, which opens "Me" (the ReadIn mark for
/// guests), the search pill (F16), the light / dark toggle and the notifications bell (F17). [bottom] goes under it,
/// e.g. Saved's tabs.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.bottom});

  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) => AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: ReadInSpace.s2,
        title: const Row(
          children: [
            MeButton(),
            SizedBox(width: ReadInSpace.s2),
            Expanded(child: SearchEntryBar(pill: true)),
          ],
        ),
        actions: const [ThemeToggleButton(), NotificationsBell(), SizedBox(width: ReadInSpace.s1)],
        bottom: bottom,
      );
}

/// The avatar (36) that opens the Me sheet; guests see the ReadIn mark, which opens Sign in and Appearance.
class MeButton extends StatelessWidget {
  const MeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.select((SessionCubit c) => c.state.isAuthenticated ? c.state.me : null);
    final label = context.l10n.meMenu;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          key: const ValueKey('me-button'),
          onTap: () => unawaited(showMeSheet(context)),
          customBorder: me == null ? const StadiumBorder() : const CircleBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: me == null ? ReadInSpace.s1 : 6),
              child: Center(
                widthFactor: 1,
                child: me == null ? const AppLogo(size: 20) : UserAvatar(name: me.displayName, url: me.avatarUrl, size: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bell with the unread count (F17, F27). The count comes from the app's [UnreadBadgeCubit], which the tab shell
/// provides (and refreshes when the app comes back); without one, as on a screen pumped alone, the bell shows no
/// count. Guests get the sign-in prompt.
class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unread = context.select((UnreadBadgeCubit? c) => c?.state ?? 0);
    const bell = Icon(Icons.notifications_none_rounded);
    return IconButton(
      key: const ValueKey('notifications-bell'),
      tooltip: unread > 0 ? l10n.notificationsUnread(unread) : l10n.notifications,
      onPressed: () {
        if (requireAccount(context)) unawaited(context.push<void>('/notifications'));
      },
      // No badge at 0.
      icon: unread > 0 ? Badge(label: Text(unread > 9 ? '9+' : '$unread'), child: bell) : bell,
    );
  }
}

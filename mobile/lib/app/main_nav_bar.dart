import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/l10n/l10n_x.dart';
import '../core/theme/theme_x.dart';
import '../core/theme/tokens.g.dart';
import '../shared/widgets/readin_mark.dart';

/// The main tabs' bottom bar, icons only: Explore · Write · (ReadIn mark) · Saved · More.
///
/// Home has no tab of its own: the ReadIn mark is the Home button. It rises out of a soft, curved notch in the middle
/// of the bar, and an amber ring goes round it while Home is open. The open tab's icon is filled, in the brand green,
/// with a short amber tick on the bar's top edge (amber, like the "ر" of the mark, says "you are here"). Each icon
/// still has its name for screen readers, and shows it on a long press. More opens the More sheet; it counts as open
/// on the Profile tab, which is reached from there. The page above keeps its full height: the mark is drawn over its
/// last few pixels.
class MainNavBar extends StatelessWidget {
  const MainNavBar({super.key, required this.currentIndex, required this.onSelect, required this.onMore});

  /// The branch that is open: 0 Home, 1 Explore, 2 Write, 3 Saved, 4 Profile.
  final int currentIndex;

  /// The mark or a tab was pressed, with its branch.
  final ValueChanged<int> onSelect;

  /// More was pressed.
  final VoidCallback onMore;

  static const int homeBranch = 0;

  /// The Profile branch: no icon of its own, it opens from the More sheet.
  static const int profileBranch = 4;

  /// The bar's own height, above the system's bottom inset.
  static const double barHeight = ReadInLayout.bottomNavHeight;

  /// The ReadIn mark's diameter.
  static const double markSize = 56;

  /// How far the mark's center sits below the bar's top edge.
  static const double _markDrop = 4;

  /// How far the mark rises above the bar's top edge.
  static const double rise = markSize / 2 - _markDrop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inset = MediaQuery.paddingOf(context).bottom;
    Widget tab(
      IconData icon,
      IconData selectedIcon,
      String label, {
      required bool selected,
      required VoidCallback onTap,
    }) => Expanded(
      child: _Tab(icon: icon, selectedIcon: selectedIcon, label: label, selected: selected, onTap: onTap),
    );
    Widget branch(int index, IconData icon, IconData selectedIcon, String label) =>
        tab(icon, selectedIcon, label, selected: currentIndex == index, onTap: () => onSelect(index));
    return _Rise(
      rise: rise,
      child: SizedBox(
        height: rise + barHeight + inset,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: _BarBackground(top: rise)),
            Positioned(
              top: rise,
              left: 0,
              right: 0,
              height: barHeight,
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    branch(1, Icons.explore_outlined, Icons.explore, l10n.navExplore),
                    branch(2, Icons.draw_outlined, Icons.draw, l10n.navWrite),
                    const SizedBox(width: _BarShape.notchWidth),
                    branch(3, Icons.bookmarks_outlined, Icons.bookmarks, l10n.navSaved),
                    tab(
                      Icons.grid_view_outlined,
                      Icons.grid_view_rounded,
                      l10n.navMore,
                      selected: currentIndex == profileBranch,
                      onTap: onMore,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: _HomeMark(
                label: l10n.navHome,
                selected: currentIndex == homeBranch,
                onTap: () => onSelect(homeBranch),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The admin's bottom bar (holders of `admin.access`, F23), in the members' bar's style: Tickets · Users · (the ReadIn
/// mark, the Dashboard) · Notifications · More. Nothing to write here: the admin writes from the app as a reader sees
/// it. A tab whose permission is missing isn't shown ([tickets], [users]) and the mark stays in the middle. Tickets
/// carries the open tickets and Notifications the unread count, as red badges (screen readers hear the count in the
/// name); More opens the console's More sheet.
class AdminNavBar extends StatelessWidget {
  const AdminNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onMore,
    this.tickets = true,
    this.users = true,
    this.openTickets = 0,
    this.unread = 0,
  });

  /// The branch that is open: 5 Dashboard, 6 Tickets, 7 Users, 8 Notifications.
  final int currentIndex;

  /// The mark or a tab was pressed, with its branch.
  final ValueChanged<int> onSelect;

  /// More was pressed.
  final VoidCallback onMore;

  /// Show Tickets (`support.manage`).
  final bool tickets;

  /// Show Users (`users.read`).
  final bool users;

  /// The badge on Tickets.
  final int openTickets;

  /// The badge on Notifications.
  final int unread;

  static const int dashboardBranch = 5;
  static const int ticketsBranch = 6;
  static const int usersBranch = 7;
  static const int notificationsBranch = 8;

  /// Whether [branch] is one of this bar's (the main shell shows this bar on them).
  static bool isConsoleBranch(int branch) => branch >= dashboardBranch;

  static String? _count(int value) => value <= 0 ? null : (value > 9 ? '9+' : '$value');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inset = MediaQuery.paddingOf(context).bottom;
    Widget tab(int? index, IconData icon, IconData selectedIcon, String label, {String? badge, VoidCallback? onTap}) =>
        Expanded(
          child: _Tab(
            icon: icon,
            selectedIcon: selectedIcon,
            label: label,
            selected: index != null && currentIndex == index,
            onTap: onTap ?? () => onSelect(index!),
            badge: badge,
          ),
        );
    // Each side takes half of the room beside the notch, so a hidden tab never moves the mark.
    Widget side(List<Widget> tabs) => Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: tabs));
    return _Rise(
      rise: MainNavBar.rise,
      child: SizedBox(
        height: MainNavBar.rise + MainNavBar.barHeight + inset,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: _BarBackground(top: MainNavBar.rise)),
            Positioned(
              top: MainNavBar.rise,
              left: 0,
              right: 0,
              height: MainNavBar.barHeight,
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    side([
                      if (tickets)
                        tab(
                          ticketsBranch,
                          Icons.support_agent_outlined,
                          Icons.support_agent,
                          openTickets > 0 ? l10n.adminNavTicketsOpen('$openTickets') : l10n.adminSectionTickets,
                          badge: _count(openTickets),
                        ),
                      if (users) tab(usersBranch, Icons.people_alt_outlined, Icons.people_alt, l10n.adminSectionUsers),
                    ]),
                    const SizedBox(width: _BarShape.notchWidth),
                    side([
                      tab(
                        notificationsBranch,
                        Icons.notifications_none_rounded,
                        Icons.notifications_rounded,
                        unread > 0 ? l10n.notificationsUnread(unread) : l10n.notifications,
                        badge: _count(unread),
                      ),
                      tab(null, Icons.grid_view_outlined, Icons.grid_view_rounded, l10n.navMore, onTap: onMore),
                    ]),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: _HomeMark(
                label: l10n.adminNavDashboard,
                selected: currentIndex == dashboardBranch,
                onTap: () => onSelect(dashboardBranch),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The geometry of the bar's top edge: flat, with a round notch around the mark whose shoulders curve smoothly into it.
abstract final class _BarShape {
  /// The notch's radius: the mark's, plus a gap.
  static const double notchRadius = MainNavBar.markSize / 2 + 7;

  /// The radius of the curves that join the flat edge and the notch.
  static const double shoulder = 12;

  /// From the mark's center to where a shoulder leaves the flat edge.
  static final double _reach = math.sqrt(
    math.pow(notchRadius + shoulder, 2) - math.pow(MainNavBar._markDrop - shoulder, 2),
  );

  /// The width the notch takes out of the bar (the room between the Write and Saved tabs).
  static const double notchWidth = 92;

  /// The bar's outline, its top edge at [top]; [extend] pushes its sides and bottom past [size] (for the border).
  static Path outline(Size size, double top, {double extend = 0}) {
    final cx = size.width / 2;
    final center = Offset(cx, top + MainNavBar._markDrop);
    final leftShoulder = Offset(cx - _reach, top + shoulder);
    final rightShoulder = Offset(cx + _reach, top + shoulder);
    Offset onNotch(Offset shoulderCenter) =>
        center + (shoulderCenter - center) * (notchRadius / (notchRadius + shoulder));
    return Path()
      ..moveTo(-extend, top)
      ..lineTo(cx - _reach, top)
      ..arcToPoint(onNotch(leftShoulder), radius: const Radius.circular(shoulder))
      ..arcToPoint(onNotch(rightShoulder), radius: const Radius.circular(notchRadius), clockwise: false)
      ..arcToPoint(Offset(cx + _reach, top), radius: const Radius.circular(shoulder))
      ..lineTo(size.width + extend, top)
      ..lineTo(size.width + extend, size.height + extend)
      ..lineTo(-extend, size.height + extend)
      ..close();
  }
}

/// The bar: the surface color with a hairline along its top edge and a soft shadow above it.
class _BarBackground extends StatelessWidget {
  const _BarBackground({required this.top});

  final double top;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomPaint(
      painter: _BarPainter(
        top: top,
        fill: colors.surface,
        border: colors.border,
        shadow: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.06),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({required this.top, required this.fill, required this.border, required this.shadow});

  final double top;
  final Color fill;
  final Color border;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _BarShape.outline(size, top);
    canvas
      ..drawPath(
        shape.shift(const Offset(0, -2)),
        Paint()
          ..color = shadow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..drawPath(shape, Paint()..color = fill)
      ..drawPath(
        _BarShape.outline(size, top, extend: 2),
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  /// The drawing takes no taps: beside the mark the page shows through and stays tappable, and the tabs and the mark
  /// take their own.
  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.top != top || old.fill != fill || old.border != border || old.shadow != shadow;
}

/// A tab: an icon alone (its name is for screen readers and a long press). The open one is filled, in green, a little
/// larger, with an amber tick on the bar's top edge.
class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// A count on the icon ("9+" past 9); none when null.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          containedInkWell: false,
          highlightShape: BoxShape.circle,
          radius: 28,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                child: AnimatedContainer(
                  duration: ReadInMotion.base,
                  curve: Curves.easeOutCubic,
                  width: selected ? 22 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                ),
              ),
              Center(
                child: AnimatedScale(
                  scale: selected ? 1.08 : 1,
                  duration: ReadInMotion.base,
                  curve: Curves.easeOutBack,
                  child: AnimatedSwitcher(
                    duration: ReadInMotion.base,
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      selected ? selectedIcon : icon,
                      key: ValueKey(selected),
                      size: 26,
                      color: selected ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ),
              ),
              // A count (the admin's bar): the app's red badge at the icon's top end; its number is in [label].
              if (badge case final text?)
                Center(
                  child: IgnorePointer(
                    child: Badge(
                      label: ExcludeSemantics(child: Text(text)),
                      backgroundColor: colors.error,
                      textColor: colors.onError,
                      child: const SizedBox.square(dimension: 26),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home: the ReadIn mark as a round button with a green glow, which gives a little when pressed. An amber ring goes
/// round it while Home is open.
class _HomeMark extends StatefulWidget {
  const _HomeMark({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_HomeMark> createState() => _HomeMarkState();
}

class _HomeMarkState extends State<_HomeMark> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const size = MainNavBar.markSize;
    return Semantics(
      container: true,
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: ReadInMotion.fast,
        curve: Curves.easeOut,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The ring: in the gap between the mark and the notch.
              Positioned(
                left: -4,
                top: -4,
                right: -4,
                bottom: -4,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: widget.selected ? 1 : 0,
                    duration: ReadInMotion.base,
                    child: AnimatedScale(
                      scale: widget.selected ? 1 : 0.85,
                      duration: ReadInMotion.slow,
                      curve: Curves.easeOutBack,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.accent, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: context.isDark ? 0.45 : 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  type: MaterialType.circle,
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: Ink(
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: ReadInMark.gradient),
                    child: InkWell(
                      onTap: widget.onTap,
                      onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
                      splashColor: Colors.white24,
                      highlightColor: Colors.white10,
                      child: const CustomPaint(size: Size.square(size), painter: ReadInMarkPainter(background: false)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays its child out [rise] taller than itself and draws it that much higher: the Scaffold gives the page all the
/// room above the bar, and the mark rises over the page's last pixels. Taps on the risen part still reach the child.
class _Rise extends SingleChildRenderObjectWidget {
  const _Rise({required this.rise, required super.child});

  final double rise;

  @override
  _RenderRise createRenderObject(BuildContext context) => _RenderRise(rise);

  @override
  void updateRenderObject(BuildContext context, _RenderRise renderObject) => renderObject.rise = rise;
}

class _RenderRise extends RenderShiftedBox {
  _RenderRise(this._rise) : super(null);

  double _rise;
  set rise(double value) {
    if (value == _rise) return;
    _rise = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(BoxConstraints(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth), parentUsesSize: true);
    (child.parentData! as BoxParentData).offset = Offset(0, -_rise);
    size = constraints.constrain(Size(child.size.width, math.max(0, child.size.height - _rise)));
  }

  /// The risen part is outside this box: ask the child about every point, not only those inside the box.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

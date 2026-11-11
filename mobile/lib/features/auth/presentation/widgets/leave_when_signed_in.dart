import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../admin/presentation/admin_routes.dart';
import '../../domain/entities/permissions.dart';
import '../session/session_cubit.dart';

/// Leaves Sign in or Sign up once the session starts, when the router doesn't.
///
/// Guests open these screens with `context.push` (Home's and Settings' Sign in, the sign-in prompt, a profile…).
/// go_router's top-level redirect reads the location under a pushed screen, so the rule that leads signed-in users away
/// from the sign-in screens never sees them: signing in worked, and the screen stayed open with nothing happening.
///
/// One frame after the session starts: if the redirect moved the app (a gate such as onboarding or the terms, or a
/// sign-in screen that was the whole stack), this screen is gone and nothing more happens. Otherwise it closes, with
/// anything opened over it (linking a Google or Apple account), and the reader is back where they were, signed in.
/// Admins go to the console's dashboard, where signing in takes them (F23).
class LeaveWhenSignedIn extends StatelessWidget {
  const LeaveWhenSignedIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<SessionCubit, SessionState>(
        listenWhen: (before, after) => !before.isAuthenticated && after.isAuthenticated,
        listener: (context, session) =>
            WidgetsBinding.instance.addPostFrameCallback((_) => _leave(context, admin: session.me?.isAdmin ?? false)),
        child: child,
      );

  static void _leave(BuildContext context, {required bool admin}) {
    if (!context.mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return; // the redirect already moved on
    Navigator.of(context).popUntil((other) => other == route);
    final router = GoRouter.of(context);
    if (admin) {
      router.go(AdminRoutes.consoleDashboard);
    } else if (router.canPop()) {
      router.pop();
    }
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import 'session_cubit.dart';

/// Calls [onSuspended] when the server ends the session of a suspended account (F22): the stored session is refused
/// on start, or any call is refused with `403 user.suspended`. The app opens Sign in with the reason, which says until
/// when.
class SuspendedSessionListener extends StatelessWidget {
  const SuspendedSessionListener({super.key, required this.onSuspended, required this.child});

  final ValueChanged<Failure> onSuspended;
  final Widget child;

  /// The session just ended with a `user.suspended` failure.
  static bool endedBySuspension(SessionState previous, SessionState current) =>
      current.status == SessionStatus.guest &&
      current.failure?.code == FailureCodes.userSuspended &&
      (previous.status != SessionStatus.guest || previous.failure != current.failure);

  @override
  Widget build(BuildContext context) => BlocListener<SessionCubit, SessionState>(
        listenWhen: endedBySuspension,
        listener: (_, state) => onSuspended(state.failure!),
        child: child,
      );
}

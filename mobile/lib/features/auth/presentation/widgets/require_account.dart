import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/sign_in_prompt.dart';
import '../session/session_cubit.dart';

/// True for a signed-in user; a guest gets the soft sign-in prompt instead (F01: reacting, saving and following
/// need an account).
bool requireAccount(BuildContext context) {
  if (context.read<SessionCubit>().state.isAuthenticated) return true;
  unawaited(showSignInPrompt(context));
  return false;
}

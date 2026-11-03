import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/entities/profile.dart';

/// Where profiles live in the app (F14): `/u/{username}`, its follower lists, and the edit screen.
abstract final class ProfileRoutes {
  static const edit = '/profile/edit';

  static String of(String username) => '/u/${Uri.encodeComponent(_bare(username))}';

  static String followers(String username) => '${of(username)}/followers';

  static String following(String username) => '${of(username)}/following';

  static String _bare(String username) => username.startsWith('@') ? username.substring(1) : username;
}

/// Opens [username]'s profile on top of the current screen.
void openProfile(BuildContext context, String username) => context.push(ProfileRoutes.of(username));

/// Opens the follower ([following] false) or following list; [profile] saves loading it again.
void openFollowList(BuildContext context, UserProfile profile, {required bool following}) => context.push(
      following ? ProfileRoutes.following(profile.username) : ProfileRoutes.followers(profile.username),
      extra: profile,
    );

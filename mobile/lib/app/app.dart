import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../core/l10n/l10n_x.dart';
import '../core/theme/app_theme.dart';
import '../features/article/presentation/cubit/engagement_cubit.dart';
import '../features/auth/presentation/session/session_cubit.dart';
import '../features/follow/presentation/cubit/follows_cubit.dart';
import '../features/reading/presentation/cubit/streak_cubit.dart';
import '../features/saved/presentation/cubit/collections_cubit.dart';
import '../features/settings/domain/entities/app_settings.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import 'router.dart';

/// App-wide stores of the viewer's reactions, saves, follows and collections, shared by every screen (F10, F12, F13).
class SocialStores {
  const SocialStores({required this.engagement, required this.follows, required this.collections});

  final EngagementCubit engagement;
  final FollowsCubit follows;
  final CollectionsCubit collections;
}

class ReadInApp extends StatefulWidget {
  const ReadInApp({super.key, required this.session, required this.settings, required this.social, this.pushOpens});

  final SessionCubit session;
  final SettingsCubit settings;
  final SocialStores social;

  /// Routes to open for tapped push notifications (SPEC §21.1).
  final Stream<String>? pushOpens;

  @override
  State<ReadInApp> createState() => _ReadInAppState();
}

class _ReadInAppState extends State<ReadInApp> {
  late final GoRouter _router = buildRouter(session: widget.session, settings: widget.settings);
  StreamSubscription<String>? _pushOpens;

  @override
  void initState() {
    super.initState();
    // Pushed on top of the current screen; the router's redirect waits for the session first.
    _pushOpens = widget.pushOpens?.listen((path) => unawaited(_router.push<void>(path)));
  }

  @override
  void dispose() {
    unawaited(_pushOpens?.cancel());
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.session),
        BlocProvider.value(value: widget.settings),
        BlocProvider.value(value: getIt<StreakCubit>()), // follows the session itself (F08)
        BlocProvider.value(value: widget.social.engagement),
        BlocProvider.value(value: widget.social.follows),
        BlocProvider.value(value: widget.social.collections),
      ],
      child: BlocListener<SessionCubit, SessionState>(
        listenWhen: (a, b) => a.me != b.me,
        listener: (context, state) => context.read<SettingsCubit>().onSessionChanged(state.me),
        child: BlocBuilder<SettingsCubit, AppSettings>(
          builder: (context, settings) {
            final cubit = context.read<SettingsCubit>();
            final locale = cubit.locale;
            return MaterialApp.router(
              title: 'ReadIn',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(locale),
              darkTheme: AppTheme.dark(locale),
              themeMode: cubit.themeMode,
              locale: locale,
              supportedLocales: AppLocales.supported,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n_x.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/session/session_cubit.dart';
import '../features/settings/domain/entities/app_settings.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import 'router.dart';

class ReadInApp extends StatefulWidget {
  const ReadInApp({super.key, required this.session, required this.settings});

  final SessionCubit session;
  final SettingsCubit settings;

  @override
  State<ReadInApp> createState() => _ReadInAppState();
}

class _ReadInAppState extends State<ReadInApp> {
  late final GoRouter _router = buildRouter(session: widget.session, settings: widget.settings);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.session),
        BlocProvider.value(value: widget.settings),
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

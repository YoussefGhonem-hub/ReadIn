import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/paths/domain/repositories/paths_repository.dart';
import 'package:readin/features/paths/presentation/cubit/article_path_cubit.dart';

import 'fixtures.dart';
import 'profile_fakes.dart';
import 'test_app.dart';

class MockPathsRepository extends Mock implements PathsRepository {}

class MockArticlePathCubit extends MockCubit<ArticlePathState> implements ArticlePathCubit {}

/// The reader's "Next in path" block for screens that don't test it: the article is in no path, so it renders
/// nothing. Register with `getIt.registerFactory<ArticlePathCubit>(noPathCubit)`.
ArticlePathCubit noPathCubit() {
  final cubit = MockArticlePathCubit();
  whenListen(cubit, const Stream<ArticlePathState>.empty(), initialState: const ArticlePathState(status: ArticlePathStatus.none));
  when(() => cubit.load(any())).thenAnswer((_) async {});
  return cubit;
}

/// Pumps [child] under the app stores (signed in as [me], or a guest) and [providers], at `/` of a
/// [routedTestApp]; every location pushed from it lands in [opened]. Returns the router, to pop back.
Future<GoRouter> pumpRouted(
  WidgetTester tester,
  Widget child, {
  required List<String> opened,
  Me? me = sampleMe,
  List<BlocProvider> providers = const [],
  Size size = const Size(390, 1400),
}) async {
  usePhoneSurface(tester, size: size);
  final (app, router) = routedTestApp(provided([...appStores(me: me), ...providers], child), opened: opened);
  await tester.pumpWidget(app);
  await tester.pump();
  return router;
}

/// [home] at `/` of a [GoRouter]; every other location opens a stub page and is added to [opened] (e.g.
/// `/a/article-2?lang=en`, `/paths/aspnet-core-basics`). Returns the router to pop back.
(Widget, GoRouter) routedTestApp(
  Widget home, {
  required List<String> opened,
  Variant variant = const Variant(AppLocales.en, Brightness.light),
}) {
  Widget stub(GoRouterState state) => _Opened(location: state.uri.toString(), opened: opened);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(path: '/:first', builder: (_, state) => stub(state)),
      GoRoute(path: '/:first/:second', builder: (_, state) => stub(state)),
      GoRoute(path: '/:first/:second/:third', builder: (_, state) => stub(state)),
    ],
  );
  final app = MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(variant.locale),
    darkTheme: AppTheme.dark(variant.locale),
    themeMode: variant.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    locale: variant.locale,
    supportedLocales: AppLocales.supported,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    routerConfig: router,
  );
  return (app, router);
}

class _Opened extends StatefulWidget {
  const _Opened({required this.location, required this.opened});

  final String location;
  final List<String> opened;

  @override
  State<_Opened> createState() => _OpenedState();
}

class _OpenedState extends State<_Opened> {
  @override
  void initState() {
    super.initState();
    widget.opened.add(widget.location);
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(), body: Text('opened ${widget.location}'));
}

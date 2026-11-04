@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/tokens.g.dart';
import 'package:readin/features/paths/domain/entities/learning_path.dart';
import 'package:readin/features/paths/presentation/cubit/path_details_cubit.dart';
import 'package:readin/features/paths/presentation/cubit/path_list_cubit.dart';
import 'package:readin/features/paths/presentation/pages/path_page.dart';
import 'package:readin/features/paths/presentation/pages/paths_page.dart';
import 'package:readin/features/paths/presentation/widgets/next_in_path.dart';
import 'package:readin/features/profile/presentation/pages/profile_page.dart';

import '../helpers/fixtures.dart';
import '../helpers/path_fixtures.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/profile_fixtures.dart';
import '../helpers/test_app.dart';

class MockAllPathsCubit extends MockCubit<PathListState> implements AllPathsCubit {}

class MockMyPathsCubit extends MockCubit<PathListState> implements MyPathsCubit {}

class MockUserPathsCubit extends MockCubit<PathListState> implements UserPathsCubit {}

class MockPathDetailsCubit extends MockCubit<PathDetailsState> implements PathDetailsCubit {}

/// Learning paths (F09) in ar/en × light/dark (SPEC §8.2): the paths list, a path page, the reader's "Next in path"
/// block, and a profile's Paths tab. Path titles come in the UI language, as the API sends them.
void main() {
  bool isEn(Variant variant) => variant.locale.languageCode == 'en';
  String languageOf(Variant variant) => isEn(variant) ? 'en' : 'ar-EG';

  List<LearningPath> pathsFor(Variant variant) {
    final en = isEn(variant);
    return [
      samplePath(
        title: en ? 'ASP.NET Core basics' : 'أساسيات ASP.NET Core',
        description: en ? 'From dependency injection to shipping a full API.' : 'من أول Dependency Injection لحد ما تنشر API كامل.',
        readCount: 2,
        enrolled: true,
      ),
      samplePath(
        id: 'p-2',
        slug: 'ai-agents-101',
        title: en ? 'AI agents from scratch' : 'AI Agents من الصفر',
        description: en ? 'Build an agent that uses tools and remembers context.' : 'إزاي تبني agent بيستخدم tools ويفتكر السياق.',
        field: aiField,
        total: 5,
        readCount: 5,
        completed: true,
      ),
      samplePath(id: 'p-3', slug: 'ef-core-performance', title: en ? 'Fast EF Core' : 'EF Core بسرعة', description: null, total: 3, readCount: 0),
    ];
  }

  Future<void> pump(WidgetTester tester, Variant variant, List<BlocProvider> providers, Widget child, {double height = 844}) async {
    usePhoneSurface(tester, size: Size(390, height));
    await tester.pumpWidget(testApp(provided(providers, child), variant: variant));
    await tester.pump();
  }

  tearDown(() => getIt.reset());

  for (final variant in Variant.all) {
    testWidgets('paths list ${variant.name}', (tester) async {
      final all = MockAllPathsCubit()..hold(PathListState(status: PathListStatus.ready, items: pathsFor(variant)));
      final mine = MockMyPathsCubit()..hold(const PathListState());
      await pump(
        tester,
        variant,
        [...appStores(), BlocProvider<AllPathsCubit>.value(value: all), BlocProvider<MyPathsCubit>.value(value: mine)],
        const PathsView(),
      );
      await expectLater(find.byType(PathsView), matchesVariantGolden(variant, 'goldens/paths_list_${variant.name}.png'));
    });

    testWidgets('path page ${variant.name}', (tester) async {
      final details = samplePathDetails(readCount: 2, enrolled: true, language: languageOf(variant)).withPath(pathsFor(variant).first);
      final cubit = MockPathDetailsCubit()..hold(PathDetailsState(status: PathDetailsStatus.ready, details: details));
      await pump(tester, variant, [...appStores(), BlocProvider<PathDetailsCubit>.value(value: cubit)], const PathView(), height: 1240);
      await expectLater(find.byType(PathView), matchesVariantGolden(variant, 'goldens/path_page_${variant.name}.png'));
    });

    testWidgets('next in path ${variant.name}', (tester) async {
      final language = languageOf(variant);
      final path = pathsFor(variant).first;
      final middle = ArticlePath(
        path: path.withoutEnrollment(),
        position: 2,
        total: 4,
        next: sampleCard(3, language: language),
      );
      final last = ArticlePath(
        path: samplePath(title: path.title, readCount: 4, completed: true),
        position: 4,
        total: 4,
      );
      await pump(
        tester,
        variant,
        appStores(),
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(ReadInSpace.s5),
            children: [
              NextInPathCard(articlePath: middle, onJoin: () {}, onOpenPath: () {}, onOpenNext: (_) {}),
              const SizedBox(height: ReadInSpace.s5),
              NextInPathCard(articlePath: last, onJoin: () {}, onOpenPath: () {}, onOpenNext: (_) {}),
            ],
          ),
        ),
      );
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/path_next_in_path_${variant.name}.png'));
    });

    testWidgets('profile paths ${variant.name}', (tester) async {
      final paths = MockUserPathsCubit()..hold(PathListState(status: PathListStatus.ready, items: pathsFor(variant).take(2).toList()));
      when(paths.load).thenAnswer((_) async {});
      getIt.registerFactoryParam<UserPathsCubit, String, dynamic>((_, _) => paths);

      await pump(tester, variant, [...appStores(), ...profileScreen(otherProfile)], const ProfileView(), height: 1100);
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      await tester.tap(find.text(l10n.profileTabPaths));
      await tester.pumpAndSettle();

      await expectLater(find.byType(ProfileView), matchesVariantGolden(variant, 'goldens/profile_paths_${variant.name}.png'));
    });
  }
}

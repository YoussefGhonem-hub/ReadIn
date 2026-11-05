import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/paths/domain/usecases/path_usecases.dart';
import 'package:readin/features/paths/presentation/cubit/path_list_cubit.dart';
import 'package:readin/features/profile/domain/entities/profile.dart';
import 'package:readin/features/profile/presentation/pages/profile_page.dart';

import '../../helpers/path_fakes.dart';
import '../../helpers/path_fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/profile_fixtures.dart';

/// The profile's Paths tab (F09, F14): the paths a reader joined, when their reading stats are visible.
void main() {
  late MockPathsRepository repository;
  late List<String> opened;

  setUp(() {
    repository = MockPathsRepository();
    opened = [];
    getIt.registerFactoryParam<UserPathsCubit, String, dynamic>((username, _) => UserPathsCubit(GetUserPaths(repository), username));
  });

  tearDown(() => getIt.unregister<UserPathsCubit>());

  Future<void> pumpPathsTab(WidgetTester tester, UserProfile profile) async {
    await pumpRouted(tester, ProfileView(isTab: profile.isMe), opened: opened, providers: profileScreen(profile));
    // The tab bar scrolls: with Reposts (F29) the Paths tab can start off screen.
    await tester.ensureVisible(find.text('Paths'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paths'));
    await tester.pumpAndSettle();
  }

  testWidgets('hidden reading stats: the private state, and no request', (tester) async {
    await pumpPathsTab(tester, const UserProfile(id: 'u-9', displayName: 'Omar Khaled', username: 'omar_k'));

    expect(find.text('Learning paths are private'), findsOneWidget);
    verifyNever(() => repository.getUserPaths(any()));
  });

  testWidgets("someone's visible paths, with progress and badges; a card opens its path", (tester) async {
    when(() => repository.getUserPaths('mona_dev')).thenAnswer((_) async => Ok(samplePaths().take(2).toList()));
    await pumpPathsTab(tester, otherProfile);

    expect(find.textContaining('AI Agents'), findsOneWidget);
    expect(find.text('2/4'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Explore learning paths'), findsNothing);

    await tester.tap(find.textContaining('AI Agents'));
    await tester.pumpAndSettle();
    expect(opened, ['/paths/ai-agents-101']);
  });

  testWidgets('the own profile with no path yet offers all paths', (tester) async {
    when(() => repository.getUserPaths('reader1')).thenAnswer((_) async => const Ok([]));
    await pumpPathsTab(tester, ownProfile);

    expect(find.text('No paths yet'), findsOneWidget);
    await tester.tap(find.text('Explore learning paths'));
    await tester.pumpAndSettle();
    expect(opened, ['/paths']);
  });
}

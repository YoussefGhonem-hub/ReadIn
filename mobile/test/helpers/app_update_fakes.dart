import 'package:bloc_test/bloc_test.dart';
import 'package:readin/features/app_update/data/datasources/installed_app_source.dart';
import 'package:readin/features/app_update/domain/entities/update_policy.dart';
import 'package:readin/features/app_update/presentation/cubit/app_update_cubit.dart';

class MockAppUpdateCubit extends MockCubit<AppUpdateState> implements AppUpdateCubit {}

const androidApp = InstalledApp(platform: AppPlatform.android, version: '1.1.0', buildNumber: '7', packageName: 'app.readin');
const iosApp = InstalledApp(platform: AppPlatform.ios, version: '1.1.0', buildNumber: '7', packageName: 'app.readin');

const playStoreUrl = 'https://play.google.com/store/apps/details?id=app.readin';
const appStoreUrl = 'https://apps.apple.com/app/id6740000000';

/// [InstalledAppSource] that reports [app] (null: not a phone).
class FakeInstalledApp implements InstalledAppSource {
  FakeInstalledApp([this.app = androidApp]);

  InstalledApp? app;

  @override
  Future<InstalledApp?> read() async => app;
}

/// The store launcher: records what "Update now" opened.
class FakeStoreLauncher {
  final opened = <Uri>[];

  Future<bool> call(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

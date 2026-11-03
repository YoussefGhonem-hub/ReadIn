import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

@injectable
class LoadSettings {
  const LoadSettings(this._repository);

  final SettingsRepository _repository;

  AppSettings call() => _repository.load();
}

@injectable
class SaveSettings {
  const SaveSettings(this._repository);

  final SettingsRepository _repository;

  Future<void> call(AppSettings settings) => _repository.save(settings);
}

@injectable
class SyncPreferences {
  const SyncPreferences(this._repository);

  final SettingsRepository _repository;

  Future<Result<void>> call(AppSettings settings) => _repository.pushPreferences(settings);
}

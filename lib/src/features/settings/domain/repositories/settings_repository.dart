// lib/src/features/settings/domain/repositories/settings_repository.dart

abstract class SettingsRepository {
  Future<String> getApiUrl();
  Future<void> saveApiUrl(String url);
}
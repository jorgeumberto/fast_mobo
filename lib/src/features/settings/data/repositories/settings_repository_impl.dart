// lib/src/features/settings/data/repositories/settings_repository_impl.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/settings_repository.dart';

const CACHED_API_URL = 'CACHED_API_URL';
const DEFAULT_API_URL = 'https://api.example.com';

class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences sharedPreferences;

  SettingsRepositoryImpl({required this.sharedPreferences});

  @override
  Future<String> getApiUrl() {
    final url = sharedPreferences.getString(CACHED_API_URL);
    return Future.value(url ?? DEFAULT_API_URL);
  }

  @override
  Future<void> saveApiUrl(String url) {
    return sharedPreferences.setString(CACHED_API_URL, url);
  }
}
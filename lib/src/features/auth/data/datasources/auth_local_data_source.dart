// lib/src/features/auth/data/datasources/auth_local_data_source.dart

// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSessionToken(String token);
  Future<String?> getSessionToken();
  Future<void> clearSession();
}

const CACHED_SESSION_TOKEN = 'CACHED_SESSION_TOKEN';

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> saveSessionToken(String token) {
    return sharedPreferences.setString(CACHED_SESSION_TOKEN, token);
  }
  
  @override
  Future<String?> getSessionToken() {
    final token = sharedPreferences.getString(CACHED_SESSION_TOKEN);
    return Future.value(token);
  }

  @override
  Future<void> clearSession() {
    return sharedPreferences.remove(CACHED_SESSION_TOKEN);
  }
}
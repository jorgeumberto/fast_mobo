import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _apiUrlKey = 'api_url';
 
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // Agora o getter pode retornar uma String ou null.
  String? get apiUrl {
    return _prefs.getString(_apiUrlKey);
  }

  Future<void> setApiUrl(String url) async {
    await _prefs.setString(_apiUrlKey, url);
  }
}
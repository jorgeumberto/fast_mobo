import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'models/Usuario.dart';

class ApiService {
  static Future<String> login(String email, String password) async {
    final uri = Uri.parse('$apiBase/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      // Ajuste a chave do token conforme sua API (ex.: data['token'] ou data['access_token'])
      final token = data['token'] ?? data['access_token'];
      if (token is String && token.isNotEmpty) {
        final sp = await SharedPreferences.getInstance();
        await sp.setString('auth_token', token);
        return token;
      }
      throw Exception('Token ausente na resposta.');
    } else {
      String msg = 'Falha no login (${res.statusCode})';
      try {
        final data = jsonDecode(res.body);
        if (data is Map && data['message'] is String) {
          msg = data['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static Future<Usuario> getMe() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('Token não encontrado. Faça login novamente.');
    }
    final uri = Uri.parse('$apiBase/me');
    final res = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      return Usuario.fromJson(data);
    } else {
      throw Exception('Falha ao obter usuário (${res.statusCode})');
    }
  }

  static Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      try {
        final uri = Uri.parse('$apiBase/logout');
        await http.post(uri, headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });
      } catch (_) {}
    }
    await sp.remove('auth_token');
  }
}

// lib/src/features/auth/data/datasources/auth_remote_data_source.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<User> login({required String email, required String password});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final SettingsRepository settingsRepository;

  AuthRemoteDataSourceImpl({required this.client, required this.settingsRepository});

  @override
  Future<User> login({required String email, required String password}) async {
    final apiUrl = await settingsRepository.getApiUrl();
    final loginUrl = Uri.parse('$apiUrl/login'); 

    final response = await client.post(
      loginUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final token = responseBody['token']; 
      
      // CORREÇÃO: Removido o 'const'
      return User(id: '1', name: 'Usuário da API', email: email);

    } else {
      throw Exception('Falha no login: ${response.body}');
    }
  }
}
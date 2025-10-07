import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/services/settings_service.dart'; // Importe
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final SettingsService settingsService;

  AuthRemoteDataSourceImpl({required this.client, required this.settingsService});

  @override
  Future<UserModel> login({required String email, required String password}) async {
    // Busca a URL dinamicamente do serviço de configuração
    // Busca a URL dinamicamente
    final String? baseUrl = settingsService.apiUrl;
    final String loginUrl = '$baseUrl/login'; // Concatena com a rota específica

    final response = await client.post(
      // ... o resto da função continua igual
      Uri.parse(loginUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      // Adiciona a URL ao erro para facilitar a depuração
      throw Exception('Falha no login: ${response.statusCode} na URL $loginUrl');
    }
  }

}
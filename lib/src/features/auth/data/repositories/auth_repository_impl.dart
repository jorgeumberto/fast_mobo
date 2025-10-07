// lib/src/features/auth/data/repositories/auth_repository_impl.dart

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart'; // IMPORTE O REMOTE DATASOURCE

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource; // ADICIONE A DEPENDÊNCIA

  // ATUALIZE O CONSTRUTOR
  AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<bool> hasActiveSession() async {
    final token = await localDataSource.getSessionToken();
    return token != null;
  }

  @override
  Future<User> login({required String email, required String password}) async {
    // AGORA CHAMA O DATASOURCE REMOTO
    final user = await remoteDataSource.login(email: email, password: password);
    
    // Se o login remoto for bem-sucedido, precisamos obter o token e salvá-lo.
    // A lógica do token precisa ser melhorada. Por enquanto, vamos salvar um token fixo.
    // O ideal é o remoteDataSource retornar o token junto com o usuário.
    await localDataSource.saveSessionToken('token-vindo-da-api'); // Simulação
    
    return user;
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearSession();
  }
}
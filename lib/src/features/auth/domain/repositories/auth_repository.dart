// lib/src/features/auth/domain/repositories/auth_repository.dart

import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<void> logout();
  Future<bool> hasActiveSession(); // ADICIONE ESTA LINHA
}
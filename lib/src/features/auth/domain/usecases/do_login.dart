// lib/src/features/auth/domain/usecases/do_login.dart

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

export 'do_login.dart'; // Esta linha continua aqui

class DoLogin implements Usecase<User, Params> { // Esta linha agora funciona
  final AuthRepository repository;

  DoLogin(this.repository);

  @override
  Future<User> call(Params params) async {
    // Adicionei um pequeno delay para simular uma chamada de rede real
    await Future.delayed(const Duration(seconds: 1)); 
    return await repository.login(email: params.email, password: params.password);
  }
}

class Params extends Equatable {
  final String email;
  final String password;

  const Params({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
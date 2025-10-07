// lib/src/features/auth/presentation/bloc/auth_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {} // Estado inicial, antes da verificação

class AuthLoading extends AuthState {}

// Usuário logado com sucesso (após pressionar o botão)
class AuthSuccess extends AuthState {
  final User user;

  const AuthSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure({required this.error});

  @override
  List<Object> get props => [error];
}

// Estado para quando o app inicia e o usuário JÁ ESTÁ autenticado
class AuthAuthenticated extends AuthState {
    final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

// Estado para quando o app inicia e o usuário NÃO ESTÁ autenticado
class AuthUnauthenticated extends AuthState {}
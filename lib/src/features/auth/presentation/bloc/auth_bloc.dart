// lib/src/features/auth/presentation/bloc/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/no_params.dart';
import '../../domain/entities/user.dart'; // Importe a entidade User
import '../../domain/usecases/check_auth_status.dart';
import '../../domain/usecases/do_login.dart';
import '../../domain/usecases/do_logout.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final DoLogin doLogin;
  final DoLogout doLogout;
  final CheckAuthStatus checkAuthStatus;

  AuthBloc({
    required this.doLogin,
    required this.doLogout,
    required this.checkAuthStatus,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<LogoutButtonPressed>(_onLogoutButtonPressed);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      final hasSession = await checkAuthStatus(NoParams());
      if (hasSession) {
        // Se temos uma sessão, consideramos o usuário autenticado.
        // Em um app real, você usaria o token para buscar os dados atualizados do usuário.
        const user = User(id: '1', name: 'Usuário Teste', email: 'teste@email.com');
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await doLogin(Params(email: event.email, password: event.password));
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onLogoutButtonPressed(
    LogoutButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await doLogout(NoParams());
    emit(AuthUnauthenticated());
  }
}
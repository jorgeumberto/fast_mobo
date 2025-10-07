// lib/src/features/auth/domain/usecases/check_auth_status.dart

import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/no_params.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatus implements Usecase<bool, NoParams> {
  final AuthRepository repository;

  CheckAuthStatus(this.repository);

  @override
  Future<bool> call(NoParams params) async {
    return await repository.hasActiveSession(); // LÓGICA CORRIGIDA
  }
}
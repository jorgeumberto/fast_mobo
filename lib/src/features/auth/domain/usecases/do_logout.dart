// lib/src/features/auth/domain/usecases/do_logout.dart

import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/no_params.dart'; // ADICIONE ESTA LINHA
import '../repositories/auth_repository.dart';

class DoLogout implements Usecase<void, NoParams> { // Esta linha agora funcionará
  final AuthRepository repository;

  DoLogout(this.repository);

  @override
  Future<void> call(NoParams params) async {
    return await repository.logout();
  }
}
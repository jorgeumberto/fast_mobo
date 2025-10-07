// lib/src/core/usecase/usecase.dart

// Esta é a interface base para todos os usecases no aplicativo.
// Define um contrato que força cada usecase a ter um método 'call'.
// Type: O tipo de retorno do usecase (ex: um objeto User, uma lista de Posts, etc.)
// Params: O tipo dos parâmetros que o usecase precisa para executar.
abstract class Usecase<Type, Params> {
  Future<Type> call(Params params);
}
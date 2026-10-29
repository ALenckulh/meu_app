import 'package:meu_app/shared/models/professor.dart';

/// Erro de autenticação com mensagem pronta para mostrar ao usuário.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Professor? get currentUser;

  /// Retorna `null` quando e-mail/senha estão errados.
  /// Lança [AuthFailure] para outros problemas (sem rede, muitas tentativas...).
  Future<Professor?> login(String email, String senha);

  /// Cria a conta. Lança [AuthFailure] se não for possível.
  Future<Professor> register({
    required String nome,
    required String email,
    required String senha,
  });

  Future<void> logout();
}

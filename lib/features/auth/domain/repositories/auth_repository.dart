import 'package:meu_app/shared/models/professor.dart';

abstract class AuthRepository {
  Professor? get currentUser;
  Future<Professor?> login(String email, String senha);
  Future<Professor> register({
    required String nome,
    required String email,
    required String senha,
  });
  Future<void> logout();
}

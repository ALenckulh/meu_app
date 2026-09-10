import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_app/shared/models/professor.dart';
import 'package:uuid/uuid.dart';

/// N1 mock. // N2: Firebase Auth + Firestore.
class AuthMockRepository implements AuthRepository {
  AuthMockRepository(this._store);

  final AppMockStore _store;
  final Uuid _uuid = const Uuid();

  @override
  Professor? get currentUser => _store.sessaoAtual;

  @override
  Future<Professor?> login(String email, String senha) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      final Professor professor = _store.professores.firstWhere(
        (Professor p) => p.email == email && p.senha == senha,
      );
      _store.sessaoAtual = professor;
      return professor;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Professor> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final Professor professor = Professor(
      id: _uuid.v4(),
      nome: nome,
      email: email,
      senha: senha,
    );
    _store.professores.add(professor);
    return professor;
  }

  @override
  Future<void> logout() async {
    _store.sessaoAtual = null;
  }
}

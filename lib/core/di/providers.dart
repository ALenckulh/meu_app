import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/features/alunos/data/repositories/aluno_mock_repository.dart';
import 'package:meu_app/features/alunos/domain/repositories/aluno_repository.dart';
import 'package:meu_app/features/auth/data/repositories/auth_firebase_repository.dart';
import 'package:meu_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_app/features/correcao/data/repositories/correcao_mock_repository.dart';
import 'package:meu_app/features/correcao/domain/repositories/correcao_repository.dart';
import 'package:meu_app/features/provas/data/repositories/prova_firestore_repository.dart';
import 'package:meu_app/features/provas/domain/repositories/prova_repository.dart';
import 'package:meu_app/features/questoes/data/repositories/questao_firestore_repository.dart';
import 'package:meu_app/features/questoes/domain/repositories/questao_repository.dart';
import 'package:meu_app/features/turmas/data/repositories/turma_mock_repository.dart';
import 'package:meu_app/features/turmas/domain/repositories/turma_repository.dart';
import 'package:meu_app/shared/models/professor.dart';

final appMockStoreProvider = Provider<AppMockStore>((Ref ref) {
  return AppMockStore.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  return AuthFirebaseRepository();
});

final turmaRepositoryProvider = Provider<TurmaRepository>((Ref ref) {
  return TurmaMockRepository(ref.watch(appMockStoreProvider));
});

final alunoRepositoryProvider = Provider<AlunoRepository>((Ref ref) {
  return AlunoMockRepository(ref.watch(appMockStoreProvider));
});

final questaoRepositoryProvider = Provider<QuestaoRepository>((Ref ref) {
  return QuestaoFirestoreRepository(
    professorId: () => ref.read(authSessionProvider)?.id,
  );
});

final provaRepositoryProvider = Provider<ProvaRepository>((Ref ref) {
  return ProvaFirestoreRepository(
    professorId: () => ref.read(authSessionProvider)?.id,
  );
});

final correcaoRepositoryProvider = Provider<CorrecaoRepository>((Ref ref) {
  return CorrecaoMockRepository(ref.watch(appMockStoreProvider));
});

class AuthSessionNotifier extends Notifier<Professor?> {
  @override
  Professor? build() {
    return ref.watch(authRepositoryProvider).currentUser;
  }

  Future<bool> login(String email, String senha) async {
    final Professor? user =
        await ref.read(authRepositoryProvider).login(email, senha);
    state = user;
    if (user != null) {
      // Força as listas a recarregarem com os dados do professor logado.
      ref.read(listVersionProvider.notifier).bump();
    }
    return user != null;
  }

  Future<void> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    await ref.read(authRepositoryProvider).register(
          nome: nome,
          email: email,
          senha: senha,
        );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = null;
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, Professor?>(AuthSessionNotifier.new);

/// Contador genérico para forçar refresh de listas após CRUD.
class ListVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final listVersionProvider =
    NotifierProvider<ListVersionNotifier, int>(ListVersionNotifier.new);

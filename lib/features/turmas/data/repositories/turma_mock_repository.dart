import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/features/turmas/domain/repositories/turma_repository.dart';
import 'package:meu_app/shared/models/turma.dart';
import 'package:uuid/uuid.dart';

class TurmaMockRepository implements TurmaRepository {
  TurmaMockRepository(this._store);

  final AppMockStore _store;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Turma>> listByProfessor(String professorId) async {
    return _store.turmas
        .where((Turma t) => t.professorId == professorId)
        .toList();
  }

  @override
  Future<Turma?> getById(String id) async {
    try {
      return _store.turmas.firstWhere((Turma t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Turma> create(Turma turma) async {
    final Turma created = turma.copyWith(id: _uuid.v4());
    _store.turmas.add(created);
    return created;
  }

  @override
  Future<Turma> update(Turma turma) async {
    final int index = _store.turmas.indexWhere((Turma t) => t.id == turma.id);
    if (index >= 0) {
      _store.turmas[index] = turma;
    }
    return turma;
  }

  @override
  Future<void> delete(String id) async {
    _store.turmas.removeWhere((Turma t) => t.id == id);
    _store.alunos.removeWhere((a) => a.turmaId == id);
  }
}

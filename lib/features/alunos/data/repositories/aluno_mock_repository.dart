import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/features/alunos/domain/repositories/aluno_repository.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:uuid/uuid.dart';

class AlunoMockRepository implements AlunoRepository {
  AlunoMockRepository(this._store);

  final AppMockStore _store;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Aluno>> listByTurma(String turmaId) async {
    return _store.alunos.where((Aluno a) => a.turmaId == turmaId).toList();
  }

  @override
  Future<Aluno?> getById(String id) async {
    try {
      return _store.alunos.firstWhere((Aluno a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Aluno> create(Aluno aluno) async {
    final Aluno created = aluno.copyWith(id: _uuid.v4());
    _store.alunos.add(created);
    return created;
  }

  @override
  Future<Aluno> update(Aluno aluno) async {
    final int index = _store.alunos.indexWhere((Aluno a) => a.id == aluno.id);
    if (index >= 0) {
      _store.alunos[index] = aluno;
    }
    return aluno;
  }

  @override
  Future<void> delete(String id) async {
    _store.alunos.removeWhere((Aluno a) => a.id == id);
  }

  @override
  Future<List<Aluno>> importMock(String turmaId) async {
    // N2: ler CSV/planilha real.
    final List<Aluno> imported = <Aluno>[
      Aluno(
        id: _uuid.v4(),
        turmaId: turmaId,
        nome: 'Aluno Importado 1',
        matricula: 'IMP001',
      ),
      Aluno(
        id: _uuid.v4(),
        turmaId: turmaId,
        nome: 'Aluno Importado 2',
        matricula: 'IMP002',
      ),
      Aluno(
        id: _uuid.v4(),
        turmaId: turmaId,
        nome: 'Aluno Importado 3',
        matricula: 'IMP003',
      ),
    ];
    _store.alunos.addAll(imported);
    return imported;
  }
}

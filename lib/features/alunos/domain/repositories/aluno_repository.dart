import 'package:meu_app/shared/models/aluno.dart';

abstract class AlunoRepository {
  Future<List<Aluno>> listByTurma(String turmaId);
  Future<Aluno?> getById(String id);
  Future<Aluno> create(Aluno aluno);
  Future<Aluno> update(Aluno aluno);
  Future<void> delete(String id);
  Future<List<Aluno>> importMock(String turmaId);
}

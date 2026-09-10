import 'package:meu_app/shared/models/turma.dart';

abstract class TurmaRepository {
  Future<List<Turma>> listByProfessor(String professorId);
  Future<Turma?> getById(String id);
  Future<Turma> create(Turma turma);
  Future<Turma> update(Turma turma);
  Future<void> delete(String id);
}

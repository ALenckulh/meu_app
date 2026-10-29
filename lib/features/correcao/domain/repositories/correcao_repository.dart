import 'package:meu_app/shared/models/correcao.dart';

abstract class CorrecaoRepository {
  Future<List<Correcao>> listAll();
  Future<Correcao?> getById(String id);
  Future<Correcao?> getByAluno(String alunoId);

  /// Persiste correção com respostas informadas (pós-QR / entrada manual).
  Future<Correcao> corrigir({
    required String variacaoId,
    required String alunoId,
    required String professorId,
    required List<int> respostas,
  });
}

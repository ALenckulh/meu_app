import 'package:meu_app/shared/models/correcao.dart';

abstract class CorrecaoRepository {
  Future<List<Correcao>> listAll();
  Future<Correcao?> getById(String id);

  /// Correção da folha (variação) — uma por aluno em cada prova.
  Future<Correcao?> getByVariacao(String variacaoId);

  /// Persiste correção com respostas informadas (pós-QR / entrada manual).
  Future<Correcao> corrigir({
    required String variacaoId,
    required String alunoId,
    required String professorId,
    required List<int> respostas,
  });
}

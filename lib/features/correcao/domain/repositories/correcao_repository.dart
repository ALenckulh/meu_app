import 'package:meu_app/shared/models/correcao.dart';

abstract class CorrecaoRepository {
  Future<List<Correcao>> listAll();
  Future<Correcao?> getByAluno(String alunoId);
  Future<Correcao> simularLeitura({
    required String variacaoId,
    required String alunoId,
  });
}

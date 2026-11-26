import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

abstract class ProvaRepository {
  Future<List<Prova>> listAll();
  Future<Prova?> getById(String id);
  Future<Prova> create(Prova prova);
  Future<Prova> update(Prova prova);
  Future<void> delete(String id);
  Future<List<VariacaoDeProva>> listVariacoes(String provaId);
  Future<VariacaoDeProva?> getVariacaoById(String id);

  /// Apaga todas as variações da prova (folhas impressas deixam de valer).
  Future<void> deleteVariacoes(String provaId);

  /// Gera a variação do aluno, substituindo a anterior dele nesta prova.
  Future<VariacaoDeProva> gerarVariacao({
    required String provaId,
    required String alunoId,
    required bool embaralharQuestoes,
    required bool embaralharAlternativas,
  });

  /// Variação na ordem original (sem embaralhar) para corrigir um aluno pela
  /// folha geral. Reaproveita a do aluno se ela já estiver na ordem original;
  /// senão gera uma nova, que substitui a folha individual dele.
  Future<VariacaoDeProva> variacaoFolhaGeral({
    required String provaId,
    required String alunoId,
  });
}

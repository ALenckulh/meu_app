import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

abstract class ProvaRepository {
  Future<List<Prova>> listAll();
  Future<Prova?> getById(String id);
  Future<Prova> create(Prova prova);
  Future<Prova> update(Prova prova);
  Future<void> delete(String id);
  Future<List<VariacaoDeProva>> listVariacoes(String provaId);
  Future<VariacaoDeProva> gerarVariacao({
    required String provaId,
    required String alunoId,
    required bool embaralharQuestoes,
    required bool embaralharAlternativas,
  });
}
